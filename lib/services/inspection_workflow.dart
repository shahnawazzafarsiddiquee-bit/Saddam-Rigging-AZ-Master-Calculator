import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../models/equipment_model.dart';
import 'backup_service.dart';
import 'environment_repository.dart';

/// Checklist prompts, not manufacturer acceptance/retirement limits.
class InspectionRules {
  static const checklists = <String, List<String>>{
    'Web sling': [
      'Identification tag and WLL legible',
      'No cuts, tears, holes or snags',
      'No abrasion, fraying or worn edges',
      'Stitching intact',
      'No burns, melting or heat damage',
      'No chemical attack or discolouration',
      'No knots or unauthorized repairs',
      'No UV damage',
      'Hardware undamaged',
      'Certificate and manufacturer criteria verified',
    ],
    'Round sling': [
      'Identification tag and WLL legible',
      'Cover has no cuts or abrasion',
      'Core not exposed',
      'No heat or chemical damage',
      'No knots or unauthorized repairs',
      'Certificate and manufacturer criteria verified',
    ],
    'Wire rope sling': [
      'Identification tag and WLL legible',
      'Broken wires assessed against approved manufacturer criteria',
      'No bird cage, kink or crushing',
      'No corrosion or heat damage',
      'Diameter measured against approved criteria',
      'Ferrule, eye and thimble acceptable',
      'Certificate and manufacturer criteria verified',
    ],
    'Chain sling': [
      'Grade, diameter and WLL verified',
      'No stretched, worn, cracked or twisted links',
      'Master link and connectors acceptable',
      'Hooks and latches acceptable',
      'No heat or chemical damage',
      'Length and leg arrangement verified',
      'Certificate and manufacturer criteria verified',
    ],
    'Shackle': [
      'Body free from cracks and deformation',
      'Correct matching pin installed',
      'Threads and pin seating acceptable',
      'Wear and corrosion within manufacturer criteria',
      'WLL and identification legible',
      'No evidence of unauthorized side loading',
      'Certificate verified',
    ],
    'Hook': [
      'Opening measured against manufacturer criteria',
      'Twist and wear within manufacturer criteria',
      'No cracks or deformation',
      'Safety latch functional',
      'Swivel functional where fitted',
      'Identification and certificate verified',
    ],
    'Master link': [
      'No excessive wear or stretch',
      'No distortion or cracks',
      'No heat damage or corrosion',
      'WLL marking legible',
      'Certificate and manufacturer criteria verified',
    ],
    'Spreader beam': [
      'Asset ID and WLL legible',
      'Drawing and self-weight verified',
      'Structure and welds inspected to approved procedure',
      'Lifting points and hardware acceptable',
      'MTR and test certificate verified',
      'Inspection certificate current',
    ],
    'Lifting beam': [
      'Asset ID and WLL legible',
      'Drawing and self-weight verified',
      'Structure and welds inspected to approved procedure',
      'Lifting points and hardware acceptable',
      'MTR and test certificate verified',
      'Inspection certificate current',
    ],
    'Chain block': [
      'ID and WLL legible',
      'Load chain and hand chain acceptable',
      'Hooks and latches acceptable',
      'Brake and operating function verified',
      'No deformation or unauthorized repairs',
      'Certificate and manufacturer criteria verified',
    ],
    'Crane pre-use': [
      'Tires and brakes checked',
      'Outriggers set to approved configuration',
      'Pads, mats and ground verified',
      'Boom and hydraulics checked',
      'Hoist wire rope checked',
      'Hook and latch checked',
      'LMI functional',
      'Anti-two-block functional',
      'Lights, horn and alarms functional',
      'Fire extinguisher available',
      'Correct load chart and configuration verified',
      'Wind within documented manufacturer/project limits',
      'Exclusion area and power-line controls verified',
    ],
    // Preserve the old selectable category without losing its records.
    'Shackle / Hook': [
      'Body, pin and threads acceptable',
      'Correct pin fitted and secured',
      'Hook opening, twist and wear assessed',
      'Latch and swivel functional',
      'Identification and certificate verified',
    ],
  };

  static String result(String kind, Map<int, int> answers, String naReason) {
    final items = checklists[kind];
    if (items == null) throw const FormatException('Unknown checklist.');
    if (answers.keys.any((i) => i < 0 || i >= items.length) ||
        answers.values.any((v) => v < 0 || v > 2)) {
      throw const FormatException('Invalid checklist response.');
    }
    if (answers.values.contains(1)) return 'REJECT';
    if (answers.length != items.length ||
        !answers.values.contains(0) ||
        (answers.values.contains(2) && naReason.trim().isEmpty))
      return 'HOLD';
    return 'PASS';
  }
}

class InspectionWorkflow {
  static Future<int> save({
    required String assetId,
    required String kind,
    required String inspector,
    required String project,
    required String procedure,
    required Map<int, int> answers,
    required String naReason,
    required String notes,
    required bool attested,
    required List<Uint8List> photos,
    Map<String, Object?>? environment,
  }) => BackupService.withDatabases(
    (db) => saveTo(
      db,
      assetId: assetId,
      kind: kind,
      inspector: inspector,
      project: project,
      procedure: procedure,
      answers: answers,
      naReason: naReason,
      notes: notes,
      attested: attested,
      photos: photos,
      environment: environment,
    ),
  );

  static Future<int> saveTo(
    Database db, {
    required String assetId,
    required String kind,
    required String inspector,
    required String project,
    required String procedure,
    required Map<int, int> answers,
    required String naReason,
    required String notes,
    required bool attested,
    required List<Uint8List> photos,
    Map<String, Object?>? environment,
    DateTime? now,
  }) async {
    if ([assetId, inspector, project, procedure].any((s) => s.trim().isEmpty) ||
        !attested) {
      throw const FormatException(
        'Asset ID, inspector, project, procedure and inspector attestation are required.',
      );
    }
    if (photos.length > 4 ||
        photos.any((p) => p.isEmpty || p.length > 10 * 1024 * 1024)) {
      throw const FormatException(
        'Use up to four non-empty photos, each below 10 MB.',
      );
    }
    final result = InspectionRules.result(kind, answers, naReason);
    for (final schema in ['main', 'pro2']) {
      final mode = await db.rawQuery('PRAGMA $schema.journal_mode');
      if (!{
        'delete',
        'truncate',
        'persist',
      }.contains('${mode.single.values.single}'.toLowerCase())) {
        throw StateError(
          'Inspection requires rollback journaling; no records changed.',
        );
      }
    }
    final timestamp = (now ?? DateTime.now()).toUtc().toIso8601String();
    return db.transaction((tx) async {
      final attachedEnvironment = await EnvironmentRepository.resolveAttachment(
        tx,
        environment,
        project,
      );
      final rows = await tx.query(
        'Equipment',
        where: 'equipmentId = ?',
        whereArgs: [assetId.trim()],
      );
      if (rows.length != 1)
        throw StateError('Register one unique equipment ID before inspection.');
      final asset = EquipmentModel.fromMap(rows.single);
      final metadata = {
        'version': 1,
        'project': project.trim(),
        'procedure': procedure.trim(),
        'naReason': naReason.trim(),
        'notes': notes.trim(),
        'timestamp': timestamp,
        'attestation': {
          'name': inspector.trim(),
          'role': 'Inspector',
          'time': timestamp,
          'method': 'Offline typed attestation; identity not authenticated',
        },
        'equipmentRowId': asset.id,
        'environment': attachedEnvironment,
      };
      final lines = <String>[
        for (var i = 0; i < InspectionRules.checklists[kind]!.length; i++)
          '${answers[i] == 0
              ? 'OK'
              : answers[i] == 1
              ? 'FAIL'
              : answers[i] == 2
              ? 'NA'
              : 'PENDING'}|${InspectionRules.checklists[kind]![i]}',
        'META|${jsonEncode(metadata)}',
      ];
      final id = await tx.rawInsert(
        'INSERT INTO pro2.inspections (dt,kind,item,inspector,result,details) VALUES (?,?,?,?,?,?)',
        [
          timestamp.substring(0, 10),
          kind,
          assetId.trim(),
          inspector.trim(),
          result,
          lines.join('\n'),
        ],
      );
      for (final p in photos) {
        await tx.rawInsert(
          'INSERT INTO pro2.photos (insp_id,data) VALUES (?,?)',
          [id, p],
        );
      }
      var status = asset.status;
      if (result == 'REJECT' &&
          !{
            'destroyed',
            'scrapped',
            'scrap',
            'scrap pending',
          }.contains(status.toLowerCase()))
        status = 'Quarantined';
      if (result == 'HOLD' && !asset.isRestricted) status = 'Hold';
      // Passing an inspection must never silently release previously held gear.
      await tx.update(
        'Equipment',
        {'status': status, 'inspectionDate': timestamp.substring(0, 10)},
        where: 'id = ?',
        whereArgs: [asset.id],
      );
      await tx.insert('SafetyRecords', {
        'recordType': 'Equipment Audit',
        'title': assetId.trim(),
        'detailsJson': jsonEncode({
          'event': 'inspection',
          'inspectionId': id,
          'result': result,
          'previousStatus': asset.status,
          'status': status,
          'actor': inspector.trim(),
          'metadata': metadata,
        }),
        'createdAt': timestamp,
      });
      return id;
    });
  }

  static Map<String, dynamic>? metadata(String details) {
    for (final line in details.split('\n')) {
      if (line.startsWith('META|')) {
        try {
          final value = jsonDecode(line.substring(5));
          if (value is Map<String, dynamic>) return value;
        } catch (_) {}
      }
    }
    return null;
  }
}
