import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:saddam_rigging_az_master_calculator/services/inspection_workflow.dart';
import 'package:saddam_rigging_az_master_calculator/services/lift_equipment_service.dart';

import 'backup_preservation_test.dart' show releasedSchemas;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late Database db;
  final now = DateTime(2026, 10, 18);
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('inspection_workflow_');
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
    await db.insert('Equipment', {
      'id': 42,
      'equipmentId': 'SLING-42',
      'type': 'Web sling',
      'serialNumber': 'S42',
      'manufacturer': 'Maker',
      'wll': 2.0,
      'inspectionDate': '2026-10-01',
      'expiryDate': '2027-10-01',
      'status': 'Active',
    });
    await db.rawInsert(
      "INSERT INTO pro.certs(name,kind,ident,expiry) VALUES ('Certificate','Rigging','SLING-42','2027-10-01')",
    );
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  Future<int> inspect(
    Map<int, int> answers, {
    String na = '',
    List<Uint8List>? photos,
  }) => InspectionWorkflow.saveTo(
    db,
    assetId: 'SLING-42',
    kind: 'Web sling',
    inspector: 'Inspector A',
    project: 'Project A',
    procedure: 'Approved procedure rev 2',
    answers: answers,
    naReason: na,
    notes: 'Quoted "note"\nsecond line',
    attested: true,
    photos: photos ?? [],
    now: now,
  );
  final complete = {
    for (var i = 0; i < InspectionRules.checklists['Web sling']!.length; i++)
      i: 0,
  };
  final lift = {'projectName': 'P', 'loadWeight': 1.0};

  test(
    'failed inspection atomically quarantines with photos, metadata and audit',
    () async {
      final id = await inspect(
        {...complete, 0: 1},
        photos: [
          Uint8List.fromList([1, 2, 3]),
        ],
      );
      expect((await db.query('Equipment')).single['status'], 'Quarantined');
      final rows = await db.rawQuery('SELECT * FROM pro2.inspections');
      expect(rows.single['result'], 'REJECT');
      expect(
        InspectionWorkflow.metadata(rows.single['details'] as String)!['notes'],
        'Quoted "note"\nsecond line',
      );
      expect(
        (await db.rawQuery('SELECT * FROM pro2.photos')).single['insp_id'],
        id,
      );
      expect(
        (await db.query('SafetyRecords')).single['recordType'],
        'Equipment Audit',
      );
    },
  );
  test('incomplete or all NA never passes', () async {
    expect(InspectionRules.result('Web sling', {}, ''), 'HOLD');
    expect(
      InspectionRules.result('Web sling', {
        for (final k in complete.keys) k: 2,
      }, 'Not applicable'),
      'HOLD',
    );
    expect(
      InspectionRules.result('Web sling', {...complete, 0: 2}, ''),
      'HOLD',
    );
    expect(
      InspectionRules.result('Web sling', {
        ...complete,
        0: 2,
      }, 'Documented reason'),
      'PASS',
    );
    await inspect({});
    expect((await db.query('Equipment')).single['status'], 'Hold');
  });
  test('PASS preserves quarantine and prior inspection evidence', () async {
    await inspect({...complete, 0: 1});
    await inspect(complete);
    expect((await db.query('Equipment')).single['status'], 'Quarantined');
    expect((await db.rawQuery('SELECT * FROM pro2.inspections')).length, 2);
  });
  test(
    'late audit failure rolls back quarantine, inspection and photos',
    () async {
      await db.execute(
        "CREATE TRIGGER fail_audit BEFORE INSERT ON SafetyRecords BEGIN SELECT RAISE(ABORT,'injected'); END",
      );
      await expectLater(
        inspect(
          {...complete, 0: 1},
          photos: [
            Uint8List.fromList([1]),
          ],
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect((await db.query('Equipment')).single['status'], 'Active');
      expect(await db.rawQuery('SELECT * FROM pro2.inspections'), isEmpty);
      expect(await db.rawQuery('SELECT * FROM pro2.photos'), isEmpty);
    },
  );
  test(
    'unknown asset, invalid answers and empty identity cannot create record',
    () async {
      expect(
        () => InspectionRules.result('Web sling', {-1: 0}, ''),
        throwsFormatException,
      );
      await db.delete('Equipment');
      await expectLater(inspect(complete), throwsStateError);
      expect(await db.rawQuery('SELECT * FROM pro2.inspections'), isEmpty);
    },
  );
  test('lift rechecks quarantine at save after earlier eligibility', () async {
    await inspect({...complete, 0: 1});
    await expectLater(
      LiftEquipmentService.saveTo(db, lift, {42}, now: now),
      throwsStateError,
    );
    expect(await db.query('LiftPlans'), isEmpty);
  });
  test(
    'lift blocks missing or expired certificates and unknown asset',
    () async {
      await db.execute('DELETE FROM pro.certs');
      await expectLater(
        LiftEquipmentService.saveTo(db, lift, {42}, now: now),
        throwsStateError,
      );
      await expectLater(
        LiftEquipmentService.saveTo(db, lift, {43}, now: now),
        throwsStateError,
      );
      await db.rawInsert(
        "INSERT INTO pro.certs(name,kind,ident,expiry) VALUES ('C','Rigging','SLING-42','2026-10-17')",
      );
      await expectLater(
        LiftEquipmentService.saveTo(db, lift, {42}, now: now),
        throwsStateError,
      );
    },
  );
  test(
    'eligible lift stores immutable asset snapshot with same transaction',
    () async {
      final id = await LiftEquipmentService.saveTo(db, lift, {42}, now: now);
      expect(id, greaterThan(0));
      final record = (await db.query('SafetyRecords')).single;
      expect(record['detailsJson'], contains('SLING-42'));
      expect(record['detailsJson'], contains('DRAFT'));
      await db.execute(
        "CREATE TRIGGER fail_snapshot BEFORE INSERT ON SafetyRecords BEGIN SELECT RAISE(ABORT,'injected'); END",
      );
      await expectLater(
        LiftEquipmentService.saveTo(db, lift, {42}, now: now),
        throwsA(isA<DatabaseException>()),
      );
      expect((await db.query('LiftPlans')).length, 1);
    },
  );
}
