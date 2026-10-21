import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:permission_handler/permission_handler.dart';

import 'site_environment.dart';
import 'backup_service.dart';

class EnvironmentRepository {
  static const channel = MethodChannel('com.saddam.rigging/site_environment');
  static Future<String> connectivity() async {
    try {
      return await channel.invokeMethod<String>('connectivity') ?? 'UNKNOWN';
    } catch (_) {
      return 'UNKNOWN';
    }
  }

  static Future<Map<String, Object?>> captureLocation() async {
    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted)
      throw StateError(
        'Location permission not granted. Manual entry remains available.',
      );
    final value = await channel
        .invokeMapMethod<String, Object?>('location')
        .timeout(const Duration(seconds: 20));
    if (value == null) throw StateError('GPS unavailable. Use manual entry.');
    return value;
  }

  static Future<Map<String, Object?>> save(
    SiteEnvironmentSnapshot snapshot,
  ) async {
    final data = snapshot.toJson();
    final id = await BackupService.withDatabases(
      (db) => db.insert('SafetyRecords', {
        'recordType': 'Site Environment',
        'title': snapshot.site,
        'detailsJson': jsonEncode(data),
        'createdAt': snapshot.capturedAt.toUtc().toIso8601String(),
      }),
    );
    return {'recordId': id, ...data};
  }

  static Future<Map<String, Object?>?> resolveAttachment(
    DatabaseExecutor db,
    Map<String, Object?>? selected,
    String project,
  ) async {
    if (selected == null) return null;
    final id = selected['recordId'];
    if (id is! int || id <= 0)
      throw StateError('Invalid environment attachment.');
    final rows = await db.query(
      'SafetyRecords',
      where: 'id = ? AND recordType = ?',
      whereArgs: [id, 'Site Environment'],
    );
    if (rows.length != 1)
      throw StateError(
        'Environment record no longer exists. Capture a new snapshot.',
      );
    final data = jsonDecode(
      rows.single['detailsJson'] as String,
    ) as Map<String, dynamic>;
    if (data['site'] != project.trim())
      throw StateError('Environment project/site must match this record.');
    if (data['capturedAt'] != selected['capturedAt'])
      throw StateError(
        'Environment attachment changed. Capture a new snapshot.',
      );
    return {'recordId': id, ...data};
  }

  static String summary(Map<String, Object?>? data) {
    if (data == null)
      return 'Environment not attached - verification required.';
    final wind = data['wind'] as Map?;
    return 'Environment #${data['recordId']}; ${data['site']}; captured ${data['capturedAt']}; '
        'weather ${data['weather']}; temperature ${data['temperatureC'] ?? 'unknown'} C; humidity ${data['humidityPercent'] ?? 'unknown'}%; '
        'wind ${wind?['speedMps'] ?? 'unknown'} m/s; gust ${wind?['gustMps'] ?? 'unknown'} m/s; direction ${wind?['directionDegrees'] ?? 'unknown'} deg; '
        'reading ${wind?['observedAt'] ?? 'unknown'}; source ${wind?['source'] ?? 'unknown'} ${wind?['sourceReference'] ?? ''}. '
        'Historical snapshot only; recheck current field conditions. No lifting authorization.';
  }

  static Future<List<Map<String, Object?>>> history() =>
      BackupService.withDatabases((db) async {
        final rows = await db.query(
          'SafetyRecords',
          where: 'recordType = ?',
          whereArgs: ['Site Environment'],
          orderBy: 'id DESC',
        );
        return [
          for (final row in rows)
            {
              'recordId': row['id'],
              ...jsonDecode(row['detailsJson'] as String)
                  as Map<String, dynamic>,
            },
        ];
      });
}
