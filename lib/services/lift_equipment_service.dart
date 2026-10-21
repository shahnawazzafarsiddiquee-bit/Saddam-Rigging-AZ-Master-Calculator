import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/equipment_model.dart';
import 'backup_service.dart';
import 'environment_repository.dart';
import 'ground_repository.dart';

class LiftEquipmentService {
  static String? blockedReason(
    EquipmentModel asset,
    List<Map<String, Object?>> certificates,
    DateTime now,
  ) {
    if (asset.isRestricted) return asset.status;
    if (!asset.registrationCurrentAt(now))
      return 'Registration / inspection expired or incomplete';
    final today = DateTime(now.year, now.month, now.day);
    final valid = certificates.any((c) {
      final expiry = EquipmentModel.validDate('${c['expiry'] ?? ''}');
      return '${c['ident'] ?? ''}'.trim() == asset.equipmentId &&
          expiry != null &&
          !expiry.isBefore(today);
    });
    return valid
        ? null
        : 'Missing / expired certificate linked to equipment ID';
  }

  static Future<List<EquipmentModel>> eligible() =>
      BackupService.withDatabases((db) async {
        final assets = await db.query('Equipment', orderBy: 'equipmentId');
        final certs = await db.rawQuery('SELECT * FROM pro.certs');
        final now = DateTime.now();
        return assets
            .map(EquipmentModel.fromMap)
            .where((a) => blockedReason(a, certs, now) == null)
            .toList();
      });

  static Future<int> save(
    Map<String, Object?> row,
    Set<int> equipmentIds, {
    Map<String, Object?>? environment,
    Map<String, Object?>? ground,
  }) => BackupService.withDatabases(
    (db) =>
        saveTo(db, row, equipmentIds, environment: environment, ground: ground),
  );

  static Future<int> saveTo(
    Database db,
    Map<String, Object?> row,
    Set<int> equipmentIds, {
    DateTime? now,
    Map<String, Object?>? environment,
    Map<String, Object?>? ground,
  }) async {
    final time = now ?? DateTime.now();
    final weight = row['loadWeight'];
    if (weight is! num ||
        !weight.isFinite ||
        weight <= 0 ||
        '${row['projectName'] ?? ''}'.trim().isEmpty) {
      throw const FormatException(
        'Project and positive finite load weight required.',
      );
    }
    return db.transaction((tx) async {
      final attachedEnvironment = await EnvironmentRepository.resolveAttachment(
        tx,
        environment,
        '${row['projectName']}',
      );
      final attachedGround = await GroundRepository.resolveAttachment(
        tx,
        ground,
        '${row['projectName']}',
      );
      final certs = await tx.rawQuery('SELECT * FROM pro.certs');
      final snapshots = <Map<String, Object?>>[];
      for (final id in equipmentIds) {
        final found = await tx.query(
          'Equipment',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (found.length != 1)
          throw StateError('Equipment $id no longer exists.');
        final asset = EquipmentModel.fromMap(found.single);
        final reason = blockedReason(asset, certs, time);
        if (reason != null) throw StateError('${asset.equipmentId}: $reason');
        snapshots.add(found.single);
      }
      final liftId = await tx.insert('LiftPlans', row);
      await tx.insert('SafetyRecords', {
        'recordType': 'Lift Equipment',
        'title': 'LP-$liftId',
        'detailsJson': jsonEncode({
          'version': 1,
          'liftId': liftId,
          'equipment': snapshots,
          'environment': attachedEnvironment,
          'ground': attachedGround,
          'status': 'DRAFT - COMPETENT PERSON REVIEW REQUIRED',
          'certificateDocumentVerificationRequired': true,
        }),
        'createdAt': time.toUtc().toIso8601String(),
      });
      return liftId;
    });
  }
}
