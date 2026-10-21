import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../database/sqlite_helper.dart';
import '../screens/rigging_pro_db.dart';
import '../screens/pro2_db.dart';

/// Versioned, offline database backups. PDF paths are preserved; external PDF
/// files are not embedded. Inspection photo blobs ARE included.
class DatabaseBackup {
  static const format = 'saddam-rigging-database-backup';
  static const tables = <String, List<String>>{
    'main': [
      'Equipment',
      'Inspection',
      'Calculations',
      'LiftPlans',
      'SafetyRecords',
      'Reports',
    ],
    'pro': ['chart', 'certs'],
    'pro2': ['lifts', 'inspections', 'photos', 'favs'],
  };

  static Future<Map<String, dynamic>> capture(Database db) async {
    return db.transaction((txn) async {
      final databases = <String, dynamic>{};
      for (final entry in tables.entries) {
        final data = <String, dynamic>{};
        for (final table in entry.value) {
          final rows = await txn.rawQuery(
            'SELECT * FROM ${entry.key}."$table"',
          );
          data[table] = rows
              .map(
                (row) => row.map(
                  (key, value) => MapEntry(
                    key,
                    value is Uint8List
                        ? {'base64': base64Encode(value)}
                        : value,
                  ),
                ),
              )
              .toList();
        }
        databases[entry.key] = data;
      }
      return {
        'format': format,
        'version': 2,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'databases': databases,
        'limitations': [
          'External report PDF files are not embedded; keep the original PDFs separately.',
        ],
      };
    });
  }

  /// Validate all tables before any delete. Older six-table backups restore
  /// only main; neither Pro database is cleared by a legacy restore.
  static Future<Map<String, Map<String, List<Map<String, Object?>>>>> validate(
    Database db,
    Object? decoded,
  ) async {
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup must be a JSON object.');
    }
    final Map<String, dynamic> databases;
    if (decoded.containsKey('format')) {
      if (decoded['format'] != format ||
          decoded['version'] != 2 ||
          decoded['databases'] is! Map<String, dynamic>) {
        throw const FormatException('Unsupported backup format/version.');
      }
      databases = Map<String, dynamic>.from(decoded['databases'] as Map);
      if (databases.length != tables.length ||
          !tables.keys.every(databases.containsKey)) {
        throw const FormatException(
          'Full backup must contain all three databases.',
        );
      }
    } else {
      databases = {'main': decoded};
    }
    final result = <String, Map<String, List<Map<String, Object?>>>>{};
    for (final dbEntry in databases.entries) {
      final schema = dbEntry.key;
      final content = dbEntry.value;
      final expected = tables[schema];
      if (expected == null ||
          content is! Map ||
          content.length != expected.length ||
          !expected.every(content.containsKey)) {
        throw FormatException('Missing or unexpected tables in $schema.');
      }
      final data = <String, List<Map<String, Object?>>>{};
      for (final table in expected) {
        final rawRows = content[table];
        if (rawRows is! List)
          throw FormatException('Invalid rows: $schema.$table');
        final columns = await db.rawQuery(
          'PRAGMA $schema.table_info("$table")',
        );
        final names = columns.map((c) => c['name'] as String).toSet();
        if (names.isEmpty)
          throw FormatException('Missing database table $schema.$table');
        final primaryKey =
            columns.firstWhere((c) => c['pk'] == 1)['name'] as String;
        final seen = <Object?>{};
        final rows = <Map<String, Object?>>[];
        for (final raw in rawRows) {
          if (raw is! Map || raw.keys.any((k) => !names.contains(k))) {
            throw FormatException('Invalid columns in $schema.$table');
          }
          final row = <String, Object?>{};
          for (final column in columns) {
            final name = column['name'] as String;
            var value = raw[name];
            final type = (column['type'] as String).toUpperCase();
            if (type == 'BLOB' &&
                value is Map &&
                value.length == 1 &&
                value['base64'] is String) {
              value = base64Decode(value['base64'] as String);
            }
            final required = column['notnull'] == 1 || column['pk'] == 1;
            if (value == null && required)
              throw FormatException('Missing $schema.$table.$name');
            if (value != null) {
              final valid = switch (type) {
                'INTEGER' => value is int,
                'REAL' => value is num && value.isFinite,
                'TEXT' => value is String,
                'BLOB' => value is Uint8List,
                _ => false,
              };
              if (!valid) throw FormatException('Invalid $schema.$table.$name');
            }
            row[name] = value;
          }
          if (!seen.add(row[primaryKey]))
            throw FormatException('Duplicate ID in $schema.$table');
          if (row[primaryKey] is int && (row[primaryKey] as int) <= 0) {
            throw FormatException('Invalid ID in $schema.$table');
          }
          rows.add(row);
        }
        data[table] = rows;
      }
      result[schema] = data;
    }
    final pro2 = result['pro2'];
    if (pro2 != null) {
      final ids = pro2['inspections']!.map((r) => r['id']).toSet();
      if (pro2['photos']!.any((r) => !ids.contains(r['insp_id']))) {
        throw const FormatException('Photo references a missing inspection.');
      }
    }
    return result;
  }

  static Future<void> restore(Database db, Object? decoded) async {
    final data = await validate(db, decoded);
    // SQLite cannot guarantee crash-atomic multi-file commits under WAL.
    // Refuse before deleting anything instead of silently weakening recovery.
    if (data.length > 1) {
      for (final schema in data.keys) {
        final mode = await db.rawQuery('PRAGMA $schema.journal_mode');
        if (!{
          'delete',
          'truncate',
          'persist',
        }.contains(mode.single.values.single.toString().toLowerCase())) {
          throw StateError(
            'Full restore requires rollback-journal databases. No records were changed.',
          );
        }
      }
    }
    await db.transaction((txn) async {
      for (final database in data.entries) {
        for (final table in database.value.keys.toList().reversed) {
          await txn.execute('DELETE FROM ${database.key}."$table"');
        }
        for (final table in database.value.entries) {
          for (final row in table.value) {
            final columns = row.keys.map((k) => '"$k"').join(',');
            final placeholders = List.filled(row.length, '?').join(',');
            await txn.rawInsert(
              'INSERT INTO ${database.key}."${table.key}" ($columns) VALUES ($placeholders)',
              row.values.toList(),
            );
          }
        }
      }
    });
  }
}

class BackupService {
  static bool _busy = false;

  /// Serialize attached-database workflows with backup/restore so aliases and
  /// multi-file transactions cannot race. Existing database owners stay intact.
  static Future<T> withDatabases<T>(Future<T> Function(Database) action) =>
      _connected(action);

  static Future<T> _connected<T>(Future<T> Function(Database) action) async {
    if (_busy) throw StateError('A backup or restore is already running.');
    _busy = true;
    Database? db;
    final attached = <String>[];
    try {
      // Use existing owners to initialize the existing files, preserving schemas.
      await ProDb.cranes();
      await Pro2Db.lifts();
      db = await SqliteHelper.instance.database;
      final dir = await getDatabasesPath();
      await db.execute('ATTACH DATABASE ? AS pro', [
        p.join(dir, 'rigging_pro.db'),
      ]);
      attached.add('pro');
      await db.execute('ATTACH DATABASE ? AS pro2', [
        p.join(dir, 'rigging_pro2.db'),
      ]);
      attached.add('pro2');
      return await action(db);
    } finally {
      try {
        for (final schema in attached.reversed) {
          await db!.execute('DETACH DATABASE $schema');
        }
      } finally {
        _busy = false;
      }
    }
  }

  static Future<File> _write(
    Map<String, dynamic> snapshot,
    String prefix,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    await backupDir.create(recursive: true);
    final name = '${prefix}_${DateTime.now().microsecondsSinceEpoch}.json';
    final file = File(p.join(backupDir.path, name));
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(snapshot), flush: true);
    return temp.rename(file.path);
  }

  static Future<File> exportBackup() => _connected(
    (db) async =>
        _write(await DatabaseBackup.capture(db), 'saddam_rigging_backup'),
  );

  /// User confirms replacement in Settings. A full recovery snapshot is saved
  /// before restoring, and all selected tables are restored in one transaction.
  static Future<void> importBackup(File file) async {
    final decoded = jsonDecode(await file.readAsString());
    await _connected((db) async {
      await DatabaseBackup.validate(db, decoded);
      await _write(await DatabaseBackup.capture(db), 'before_restore');
      await DatabaseBackup.restore(db, decoded);
    });
  }
}
