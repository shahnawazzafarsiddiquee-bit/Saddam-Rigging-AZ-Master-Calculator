import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'backup_service.dart';

class GroundRepository {
  static Future<Map<String, Object?>> save(Map<String, Object?> data) =>
      BackupService.withDatabases((db) => saveTo(db, data));
  static Future<Map<String, Object?>> saveTo(
    DatabaseExecutor db,
    Map<String, Object?> data,
  ) async {
    if ('${data['project'] ?? ''}'.trim().isEmpty)
      throw ArgumentError('Project required to save a ground record.');
    final id = await db.insert('SafetyRecords', {
      'recordType': 'Ground Bearing',
      'title': data['project'],
      'detailsJson': jsonEncode(data),
      'createdAt': data['createdAt'],
    });
    return {'recordId': id, ...data};
  }

  static Future<List<Map<String, Object?>>> history() =>
      BackupService.withDatabases((db) async {
        final rows = await db.query(
          'SafetyRecords',
          where: 'recordType = ?',
          whereArgs: ['Ground Bearing'],
          orderBy: 'id DESC',
        );
        return [
          for (final r in rows)
            {
              'recordId': r['id'],
              ...jsonDecode(r['detailsJson'] as String) as Map<String, dynamic>,
            },
        ];
      });
  static Future<Map<String, Object?>?> resolveAttachment(
    DatabaseExecutor db,
    Map<String, Object?>? selected,
    String project,
  ) async {
    if (selected == null) return null;
    final id = selected['recordId'];
    if (id is! int || id <= 0) throw StateError('Invalid ground attachment.');
    final rows = await db.query(
      'SafetyRecords',
      where: 'id = ? AND recordType = ?',
      whereArgs: [id, 'Ground Bearing'],
    );
    if (rows.length != 1)
      throw StateError('Ground record missing; create a new calculation.');
    final data = jsonDecode(
      rows.single['detailsJson'] as String,
    ) as Map<String, dynamic>;
    if (data['project'] != project.trim() ||
        data['createdAt'] != selected['createdAt'])
      throw StateError('Ground project or revision does not match.');
    return {'recordId': id, ...data};
  }

  static String summary(Map<String, Object?>? data) {
    if (data == null)
      return 'Ground record not attached - verification required.';
    final result = data['result'] as Map, values = result['values'] as Map;
    return 'Ground #${data['recordId']}; ${data['project']}; ${data['crane']}; ${data['configuration']}; ${data['quadrant']}; '
        '${data['reactionKind']}: ${data['reactionSource']}; ground ${data['groundSource']}, revision ${data['revision']}, approved by ${data['approvedBy']}; '
        'pressure ${values['pressurePa']} Pa; provided area ${values['providedAreaM2']} m2; required area ${values['requiredAreaM2']} m2; utilization ${values['utilizationPercent']}%; '
        '${result['status']}; ${data['createdAt']}. Bearing calculation only; structural mat and ground verification remain required. No lifting authorization.';
  }
}
