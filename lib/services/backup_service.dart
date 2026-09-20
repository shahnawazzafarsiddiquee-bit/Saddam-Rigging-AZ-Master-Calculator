import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../database/sqlite_helper.dart';

/// Exports every table to a single JSON backup file, and can restore from
/// one. This is a fully offline, local-file backup — nothing is uploaded
/// anywhere, matching the app's offline-first design.
class BackupService {
  static const _tables = [
    'Equipment',
    'Inspection',
    'Calculations',
    'LiftPlans',
    'SafetyRecords',
    'Reports',
  ];

  static Future<File> exportBackup() async {
    final db = SqliteHelper.instance;
    final Map<String, dynamic> data = {};
    for (final table in _tables) {
      data[table] = await db.queryAll(table);
    }

    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${backupDir.path}/saddam_rigging_backup_$timestamp.json');
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  /// Restores a backup JSON file, wiping current data first.
  static Future<void> importBackup(File file) async {
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content) as Map<String, dynamic>;
    final db = SqliteHelper.instance;

    await db.resetDatabase();

    for (final table in _tables) {
      final rows = data[table];
      if (rows is List) {
        for (final row in rows) {
          if (row is Map<String, dynamic>) {
            final copy = Map<String, dynamic>.from(row);
            copy.remove('id'); // let autoincrement re-assign IDs on restore
            await db.insert(table, copy);
          }
        }
      }
    }
  }
}
