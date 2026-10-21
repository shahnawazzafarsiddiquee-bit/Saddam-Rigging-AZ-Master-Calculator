import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:saddam_rigging_az_master_calculator/services/site_environment.dart';
import 'package:saddam_rigging_az_master_calculator/services/environment_repository.dart';
import 'package:saddam_rigging_az_master_calculator/services/lift_equipment_service.dart';

import 'backup_preservation_test.dart' show releasedSchemas;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 18, 12);
  WindReading reading({
    double speed = 5,
    double gust = 7,
    WindSource source = WindSource.manual,
    DateTime? at,
    bool connected = true,
  }) => WindReading(
    speedMps: speed,
    gustMps: gust,
    directionDegrees: 90,
    observedAt: at ?? now,
    source: source,
    sourceReference: 'Instrument calibration R1',
    connected: connected,
  );
  const limits = WindLimits(
    stopMps: 10,
    stopGustMps: 12,
    warningMps: 8,
    warningGustMps: 10,
    maxAge: Duration(minutes: 2),
    source: 'Manufacturer chart rev1; project P',
    approvedBy: 'Project engineer',
  );
  test('missing wind or approved limits never returns normal', () {
    expect(
      WindRules.assess(reading(), null, now).status,
      startsWith('INCOMPLETE'),
    );
    expect(
      WindRules.assess(null, limits, now).status,
      startsWith('INCOMPLETE'),
    );
  });
  test('documented warning and exact stop thresholds are enforced', () {
    expect(
      WindRules.assess(reading(), limits, now).status,
      startsWith('NORMAL'),
    );
    expect(
      WindRules.assess(reading(speed: 8, gust: 9), limits, now).status,
      'WARNING',
    );
    expect(
      WindRules.assess(reading(speed: 10, gust: 11), limits, now).status,
      'STOP / REVIEW',
    );
    expect(
      WindRules.assess(reading(gust: 12), limits, now).status,
      'STOP / REVIEW',
    );
    expect(
      WindRules.assess(reading(), limits, now).toJson()['approvalGranted'],
      false,
    );
  });
  test('stale, future and disconnected BLE do not pass', () {
    expect(
      WindRules.assess(
        reading(at: now.subtract(const Duration(minutes: 3))),
        limits,
        now,
      ).status,
      startsWith('INCOMPLETE'),
    );
    expect(
      WindRules.assess(
        reading(at: now.add(const Duration(seconds: 1))),
        limits,
        now,
      ).status,
      startsWith('INCOMPLETE'),
    );
    expect(
      WindRules.assess(
        reading(source: WindSource.ble, connected: false),
        limits,
        now,
      ).status,
      startsWith('INCOMPLETE'),
    );
    expect(
      WindRules.assess(
        reading(
          speed: 10,
          gust: 15,
          at: now.subtract(const Duration(minutes: 3)),
        ),
        limits,
        now,
      ).status,
      'STOP / REVIEW',
    );
  });
  test('priority BLE then weather then manual rejects stale provider data', () {
    final ble = reading(source: WindSource.ble),
        weather = reading(source: WindSource.weather),
        manual = reading();
    expect(
      WindRules.preferred([manual, weather, ble], now, limits.maxAge),
      same(ble),
    );
    expect(
      WindRules.preferred(
        [reading(source: WindSource.ble, connected: false), manual, weather],
        now,
        limits.maxAge,
      ),
      same(weather),
    );
    expect(
      WindRules.preferred(
        [
          reading(
            source: WindSource.weather,
            at: now.subtract(const Duration(hours: 1)),
          ),
          manual,
        ],
        now,
        limits.maxAge,
      ),
      same(manual),
    );
    expect(WindRules.assess(weather, limits, now).status, 'REVIEW REQUIRED');
  });
  test('invalid wind and inconsistent warning limits rejected', () {
    expect(() => reading(speed: -1).validate(), throwsArgumentError);
    expect(() => reading(speed: 10, gust: 5).validate(), throwsArgumentError);
    expect(
      () => reading(speed: double.infinity).validate(),
      throwsArgumentError,
    );
    expect(
      () => const WindLimits(
        stopMps: 10,
        stopGustMps: 12,
        warningMps: 11,
        maxAge: Duration(minutes: 2),
        source: 'R1',
        approvedBy: 'E',
      ).validate(),
      throwsArgumentError,
    );
  });
  test(
    'snapshot works offline without GPS and retains timezone and unknown data',
    () {
      final data = SiteEnvironmentSnapshot(
        site: 'P',
        capturedAt: now,
        utcOffsetMinutes: 180,
        connectivity: 'OFFLINE',
      ).toJson();
      expect(data['latitude'], isNull);
      expect(data['wind'], isNull);
      expect(data['utcOffsetMinutes'], 180);
      expect(
        (data['windAssessment'] as Map)['status'],
        startsWith('INCOMPLETE'),
      );
      expect(
        () => SiteEnvironmentSnapshot(
          site: 'P',
          capturedAt: now,
          utcOffsetMinutes: 180,
          latitude: 25,
        ).toJson(),
        throwsArgumentError,
      );
      expect(
        () => SiteEnvironmentSnapshot(
          site: 'P',
          capturedAt: now,
          utcOffsetMinutes: 180,
          humidityPercent: 101,
        ).toJson(),
        throwsArgumentError,
      );
    },
  );
  test('platform unavailable falls back to UNKNOWN connectivity', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          EnvironmentRepository.channel,
          (call) async => throw PlatformException(code: 'unavailable'),
        );
    expect(await EnvironmentRepository.connectivity(), 'UNKNOWN');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(EnvironmentRepository.channel, null);
  });
  group('snapshot attachment transactions', () {
    sqfliteFfiInit();
    late Directory dir;
    late Database db;
    late Map<String, Object?> saved;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('environment_attachment_');
      db = await databaseFactoryFfi.openDatabase('${dir.path}/main.db');
      for (final schema in ['pro', 'pro2']) {
        await db.execute('ATTACH DATABASE ? AS $schema', [
          '${dir.path}/$schema.db',
        ]);
      }
      for (final schema in releasedSchemas.entries) {
        for (final sql in schema.value) {
          await db.execute(
            sql.replaceFirst('CREATE TABLE ', 'CREATE TABLE ${schema.key}.'),
          );
        }
      }
      final snapshot = SiteEnvironmentSnapshot(
        site: 'P',
        capturedAt: now,
        utcOffsetMinutes: 180,
        wind: reading(),
        limits: limits,
      ).toJson();
      final id = await db.insert('SafetyRecords', {
        'recordType': 'Site Environment',
        'title': 'P',
        'detailsJson': jsonEncode(snapshot),
        'createdAt': now.toIso8601String(),
      });
      saved = {'recordId': id, ...snapshot};
    });
    tearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
    test('lift stores frozen snapshot and rejects another project or changed record', () async {
      await LiftEquipmentService.saveTo(
        db,
        {'projectName': 'P', 'loadWeight': 1.0},
        {},
        environment: saved,
        now: now,
      );
      final row = (await db.query(
        'SafetyRecords',
        where: 'recordType = ?',
        whereArgs: ['Lift Equipment'],
      )).single;
      final stored =
          (jsonDecode(row['detailsJson'] as String) as Map)['environment']
              as Map;
      expect(stored['capturedAt'], saved['capturedAt']);
      expect(stored['wind'], saved['wind']);
      await expectLater(
        LiftEquipmentService.saveTo(
          db,
          {'projectName': 'Other', 'loadWeight': 1.0},
          {},
          environment: saved,
        ),
        throwsStateError,
      );
      await expectLater(
        LiftEquipmentService.saveTo(
          db,
          {'projectName': 'P', 'loadWeight': 1.0},
          {},
          environment: {...saved, 'capturedAt': 'changed'},
        ),
        throwsStateError,
      );
      expect(await db.query('LiftPlans'), hasLength(1));
    });
    test(
      'missing attachment blocks write without overwriting old records',
      () async {
        await expectLater(
          EnvironmentRepository.resolveAttachment(db, {
            ...saved,
            'recordId': 999,
          }, 'P'),
          throwsStateError,
        );
        expect(await db.query('SafetyRecords'), hasLength(1));
        expect(
          await EnvironmentRepository.resolveAttachment(db, null, 'P'),
          isNull,
        );
      },
    );
  });
}
