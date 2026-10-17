import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:saddam_rigging_az_master_calculator/services/backup_service.dart';

// Frozen schema fixture from released commit 9a1965f; do not replace it with
// new production migrations. It proves old rows remain usable.
const releasedSchemas = <String, List<String>>{
  'main': [
    '''CREATE TABLE Equipment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipmentId TEXT NOT NULL,
        type TEXT NOT NULL,
        serialNumber TEXT,
        manufacturer TEXT,
        wll REAL NOT NULL,
        inspectionDate TEXT,
        expiryDate TEXT,
        status TEXT NOT NULL
      )''',
    '''CREATE TABLE Inspection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipmentId TEXT NOT NULL,
        inspectorName TEXT,
        inspectionDate TEXT,
        result TEXT,
        remarks TEXT
      )''',
    '''CREATE TABLE Calculations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        calculatorType TEXT NOT NULL,
        inputJson TEXT NOT NULL,
        resultJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )''',
    '''CREATE TABLE LiftPlans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectName TEXT NOT NULL,
        client TEXT,
        location TEXT,
        date TEXT,
        loadDescription TEXT,
        loadWeight REAL,
        craneDetails TEXT,
        riggingArrangement TEXT,
        liftingSequence TEXT,
        personnel TEXT,
        safetyRequirements TEXT
      )''',
    '''CREATE TABLE SafetyRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recordType TEXT NOT NULL,
        title TEXT NOT NULL,
        detailsJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )''',
    '''CREATE TABLE Reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reportType TEXT NOT NULL,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )''',
  ],
  'pro': [
    '''CREATE TABLE chart (id INTEGER PRIMARY KEY AUTOINCREMENT, crane TEXT NOT NULL, boom REAL NOT NULL, radius REAL NOT NULL, capacity REAL NOT NULL, note TEXT)''',
    '''CREATE TABLE certs (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, kind TEXT NOT NULL, ident TEXT, expiry TEXT NOT NULL)''',
  ],
  'pro2': [
    '''CREATE TABLE lifts (id INTEGER PRIMARY KEY AUTOINCREMENT, dt TEXT NOT NULL, project TEXT, descr TEXT, weight REAL, crane TEXT, boom REAL, radius REAL, util REAL, result TEXT, notes TEXT)''',
    '''CREATE TABLE inspections (id INTEGER PRIMARY KEY AUTOINCREMENT, dt TEXT NOT NULL, kind TEXT NOT NULL, item TEXT, inspector TEXT, result TEXT NOT NULL, details TEXT)''',
    '''CREATE TABLE photos (id INTEGER PRIMARY KEY AUTOINCREMENT, insp_id INTEGER NOT NULL, data BLOB NOT NULL)''',
    '''CREATE TABLE favs (title TEXT PRIMARY KEY)''',
  ],
};

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late Database db;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rigsafe_backup_test_');
    db = await databaseFactoryFfi.openDatabase('${directory.path}/main.db');
    for (final schema in ['pro', 'pro2']) {
      await db.execute('ATTACH DATABASE ? AS $schema', ['${directory.path}/$schema.db']);
    }
    for (final schema in releasedSchemas.entries) {
      await db.execute('PRAGMA ${schema.key}.journal_mode=DELETE');
      await db.execute('PRAGMA ${schema.key}.user_version=1');
      for (final sql in schema.value) {
        await db.execute(sql.replaceFirst('CREATE TABLE ', 'CREATE TABLE ${schema.key}.'));
      }
    }
    for (final group in DatabaseBackup.tables.entries) {
      for (final table in group.value) {
        final columns = await db.rawQuery('PRAGMA ${group.key}.table_info("$table")');
        final row = <String, Object?>{};
        for (final c in columns) {
          final name = c['name'] as String;
          row[name] = switch (c['type']) {
            'INTEGER' => 42,
            'REAL' => 2.5,
            'BLOB' => Uint8List.fromList([0, 127, 255, 7]),
            _ => 'old-$table-$name',
          };
        }
        if (table == 'photos') row['id'] = 97;
        await db.rawInsert('INSERT INTO ${group.key}."$table" (${row.keys.join(',')}) VALUES (${List.filled(row.length, '?').join(',')})',row.values.toList());
      }
    }
  });
  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  Future<Map<String,dynamic>> snapshot() async =>
      jsonDecode(jsonEncode(await DatabaseBackup.capture(db))) as Map<String,dynamic>;

  test('round-trip all 12 released tables, original IDs and photo bytes', () async {
    final backup = await snapshot();
    await db.rawUpdate('UPDATE main.Equipment SET wll=99');
    await db.rawDelete('DELETE FROM pro.certs');
    await db.rawDelete('DELETE FROM pro2.photos');
    await DatabaseBackup.restore(db, backup);
    expect((await snapshot())['databases'], backup['databases']);
    final photo = (await db.rawQuery('SELECT * FROM pro2.photos')).single;
    expect(photo['id'], 97);
    expect(photo['insp_id'], 42);
    expect(photo['data'], [0,127,255,7]);
    for (final schema in ['main','pro','pro2']) {
      expect((await db.rawQuery('PRAGMA $schema.user_version')).single.values.single, 1);
    }
  });

  test('legacy restore leaves both Pro databases untouched', () async {
    final before = await snapshot();
    final legacy = before['databases']['main'];
    await db.rawUpdate('UPDATE main.Equipment SET wll=8');
    await DatabaseBackup.restore(db, legacy);
    expect((await snapshot())['databases'], before['databases']);
  });

  test('malformed and partial backups never delete current records', () async {
    final before = await snapshot();
    final invalid = <Object?>[null, [], {}, {'format': DatabaseBackup.format, 'version':999}];
    final partial = await snapshot();
    (partial['databases']['main'] as Map).remove('Equipment');
    invalid.add(partial);
    final missingDatabase = await snapshot();
    (missingDatabase['databases'] as Map).remove('pro');
    invalid.add(missingDatabase);
    for (final value in invalid) {
      await expectLater(DatabaseBackup.restore(db,value), throwsFormatException);
      expect((await snapshot())['databases'],before['databases']);
    }
  });

  test('bad column, type, blob, duplicate ID and dangling photo are rejected', () async {
    final before = await snapshot();
    for (final kind in ['column','type','blob','duplicate','reference']) {
      final bad = await snapshot();
      final databases = bad['databases'];
      if (kind == 'column') databases['main']['Equipment'][0]['unexpected'] = 'x';
      if (kind == 'type') databases['main']['Equipment'][0]['wll'] = 'not a number';
      if (kind == 'blob') databases['pro2']['photos'][0]['data'] = {'base64':'%not-base64'};
      if (kind == 'duplicate') databases['main']['Equipment'].add(databases['main']['Equipment'][0]);
      if (kind == 'reference') databases['pro2']['photos'][0]['insp_id'] = 999;
      await expectLater(DatabaseBackup.restore(db,bad),throwsFormatException);
      expect((await snapshot())['databases'],before['databases']);
    }
  });

  test('late insertion error rolls back every attached database', () async {
    final oldBackup = await snapshot();
    await db.rawUpdate('UPDATE main.Equipment SET wll=55');
    await db.rawUpdate("UPDATE pro.certs SET name='newer record'");
    final current = await snapshot();
    await db.execute("CREATE TRIGGER pro2.reject_restore BEFORE INSERT ON inspections BEGIN SELECT RAISE(ABORT, 'injected insert failure'); END");
    await expectLater(DatabaseBackup.restore(db,oldBackup), throwsA(isA<DatabaseException>()));
    expect((await snapshot())['databases'],current['databases']);
  });

  test('WAL full restore is blocked before any record changes', () async {
    final before = await snapshot();
    await db.rawQuery('PRAGMA pro.journal_mode=WAL');
    await expectLater(DatabaseBackup.restore(db,before),throwsStateError);
    expect((await snapshot())['databases'],before['databases']);
  });
}
