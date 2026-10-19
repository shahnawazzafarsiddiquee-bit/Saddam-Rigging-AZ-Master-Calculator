import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:saddam_rigging_az_master_calculator/services/ground_planning.dart';
import 'package:saddam_rigging_az_master_calculator/services/ground_repository.dart';
import 'package:saddam_rigging_az_master_calculator/services/lift_equipment_service.dart';
import 'package:saddam_rigging_az_master_calculator/services/pdf_service.dart';
import 'package:saddam_rigging_az_master_calculator/screens/ground_bearing.dart';

import 'backup_preservation_test.dart' show releasedSchemas;

Map<String, Object?> sample({
  String kind = 'MANUFACTURER',
  bool verified = true,
  double reaction = 400000,
  double? padLength = 0.5,
  double? thickness = 0.1,
  double? craneMass,
  double? payloadMass,
  double? grossMass,
  int quantity = 1,
  Map<String, String> overrides = const {},
}) => GroundPlanning.record(
  context: {
    'project': 'P',
    'crane': 'C1',
    'configuration': 'Full outriggers R1',
    'quadrant': 'Rear',
    'reactionKind': kind,
    'reactionSource': 'Manufacturer reaction table page 4',
    'groundSource': 'Geo report',
    'revision': 'R1',
    'approvedBy': 'Engineer',
    'matType': 'Steel M1',
    ...overrides,
  },
  reactionN: reaction,
  lengthM: 2,
  widthM: 2,
  allowablePa: 100000,
  padLengthM: padLength,
  padWidthM: 0.5,
  thicknessM: thickness,
  quantity: quantity,
  craneMassKg: craneMass,
  payloadMassKg: payloadMass,
  grossHookMassKg: grossMass,
  verified: verified,
  now: DateTime.utc(2026, 10, 19),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('ground equality and overload use maximum supplied reaction', () {
    final r = sample()['result'] as Map, v = r['values'] as Map;
    expect(v['pressurePa'], 100000);
    expect(v['requiredAreaM2'], 4);
    expect(v['utilizationPercent'], 100);
    expect(r['status'], 'acceptable');
    expect(sample()['approvalGranted'], false);
    expect(
      (sample(reaction: 400001)['result'] as Map)['status'],
      'notAcceptable',
    );
  });
  test('missing source, verification or mat details cannot pass', () {
    for (final r in [
      sample(verified: false),
      sample(overrides: {'groundSource': ''}),
      sample(padLength: null),
      sample(thickness: null),
    ]) {
      expect((r['result'] as Map)['status'], 'incomplete');
    }
  });
  test('estimated reaction stays review even below allowable pressure', () {
    expect(
      (sample(kind: 'ENGINEERING ESTIMATE')['result'] as Map)['status'],
      'reviewRequired',
    );
    expect(
      (sample(kind: 'ENGINEERING ESTIMATE', reaction: 500000)['result']
          as Map)['status'],
      'notAcceptable',
    );
    expect(() => sample(kind: 'GPS GUESS'), throwsArgumentError);
  });
  test('invalid pad, thickness, quantity and nonfinite reactions rejected', () {
    expect(() => sample(padLength: 3), throwsArgumentError);
    expect(() => sample(padLength: 0), throwsArgumentError);
    expect(() => sample(thickness: -1), throwsArgumentError);
    expect(() => sample(quantity: 0), throwsArgumentError);
    expect(() => sample(reaction: double.infinity), throwsArgumentError);
  });
  test('mat inventory count never inflates the single-outrigger area', () {
    final one = sample(), four = sample(quantity: 4);
    expect((one['result'] as Map)['values'], (four['result'] as Map)['values']);
    expect(four['quantity'], 4);
    expect(four['reactionSource'], 'Manufacturer reaction table page 4');
  });
  test('reference load metadata does not double-count outrigger reaction', () {
    final r = sample(craneMass: 50000, payloadMass: 10000, grossMass: 11000);
    expect(r['grossHookMassKg'], 11000);
    expect(
      (r['result'] as Map)['values'],
      (sample()['result'] as Map)['values'],
    );
    expect(
      () => sample(payloadMass: 10000, grossMass: 9000),
      throwsArgumentError,
    );
    expect(() => sample(craneMass: -1), throwsArgumentError);
  });
  testWidgets(
    'legacy bearing check permits missing allowable pressure and invalidates edits',
    (tester) async {
      tester.view.physicalSize = const Size(432, 960);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: GroundBearingScreen()));
      Future<void> enter(String label, String value) async {
        final f = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await tester.ensureVisible(f);
        await tester.pumpAndSettle();
        await tester.enterText(f, value);
      }

      await enter('Maximum outrigger reaction from verified source', '40');
      await enter('Effective bearing length', '2');
      await enter('Effective bearing width', '2');

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final button = find.widgetWithText(ElevatedButton, 'Calculate');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('Pressure: 98.07'), findsOneWidget);
      expect(find.text('INCOMPLETE - VERIFICATION REQUIRED'), findsOneWidget);
      await enter('Effective bearing width', '3');
      await tester.pump();
      expect(find.textContaining('Pressure:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test('calculation PDF spans pages for detailed source records', () async {
    final dir = await Directory.systemTemp.createTemp('ground_pdf_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => dir.path);
    try {
      final file = await PdfService.generateCalculationPdf(
        calculatorName: 'Ground Bearing',
        inputs: {
          for (var i = 0; i < 40; i++) 'Source $i': 'Approved source, revision R1, configuration details and field verification record.',
        },
        results: {'Pressure': '100000 Pa'},
        verdict: 'REVIEW REQUIRED - no lifting authorization',
      );
      final data = await file.readAsBytes();
      expect(ascii.decode(data.take(5).toList()), '%PDF-');
      expect(data.length, greaterThan(1000));
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      await dir.delete(recursive: true);
    }
  });
  group('ground attachment transactions', () {
    sqfliteFfiInit();
    late Directory dir;
    late Database db;
    late Map<String, Object?> saved;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('ground_attachment_');
      db = await databaseFactoryFfi.openDatabase('${dir.path}/main.db');
      for (final name in ['pro', 'pro2']) {
        await db.execute('ATTACH DATABASE ? AS $name', [
          '${dir.path}/$name.db',
        ]);
      }
      for (final schema in releasedSchemas.entries) {
        for (final sql in schema.value) {
          await db.execute(
            sql.replaceFirst('CREATE TABLE ', 'CREATE TABLE ${schema.key}.'),
          );
        }
      }
      saved = await GroundRepository.saveTo(db, sample());
    });
    tearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
    test(
      'lift retains frozen ground evidence and rejects mismatched project',
      () async {
        await LiftEquipmentService.saveTo(
          db,
          {'projectName': 'P', 'loadWeight': 1.0},
          {},
          ground: saved,
        );
        final rows = await db.query(
          'SafetyRecords',
          where: 'recordType = ?',
          whereArgs: ['Lift Equipment'],
        );
        expect(
          (jsonDecode(rows.single['detailsJson'] as String) as Map)['ground'],
          saved,
        );
        await expectLater(
          LiftEquipmentService.saveTo(
            db,
            {'projectName': 'Other', 'loadWeight': 1.0},
            {},
            ground: saved,
          ),
          throwsStateError,
        );
        expect(await db.query('LiftPlans'), hasLength(1));
      },
    );
    test(
      'missing or changed ground record blocks save without touching history',
      () async {
        for (final bad in [
          {...saved, 'recordId': 999},
          {...saved, 'createdAt': 'changed'},
        ]) {
          await expectLater(
            LiftEquipmentService.saveTo(
              db,
              {'projectName': 'P', 'loadWeight': 1.0},
              {},
              ground: bad,
            ),
            throwsStateError,
          );
        }
        expect(await db.query('LiftPlans'), isEmpty);
        expect(await db.query('SafetyRecords'), hasLength(1));
      },
    );
  });
}
