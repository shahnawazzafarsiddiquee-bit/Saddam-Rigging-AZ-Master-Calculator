import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:saddam_rigging_az_master_calculator/main.dart';
import 'package:saddam_rigging_az_master_calculator/database/sqlite_helper.dart';
import 'package:saddam_rigging_az_master_calculator/screens/pro2_db.dart';
import 'package:saddam_rigging_az_master_calculator/services/backup_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native Android backup round-trip, rejection and rollback', (tester) async {
    await tester.pumpWidget(const SaddamRiggingApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final db = await SqliteHelper.instance.database;
    await db.insert('Equipment', {
      'id': 987654321, 'equipmentId': 'TEST-NATIVE-ONLY', 'type': 'Web Sling',
      'wll': 2.5, 'status': 'Quarantined', 'expiryDate': '2099-01-01',
    });
    final inspection = await Pro2Db.addInspection({
      'dt': '2026-10-18', 'kind': 'Web Sling', 'item': 'TEST-NATIVE-ONLY',
      'result': 'HOLD', 'details': 'Disposable emulator fixture',
    });
    await Pro2Db.addPhoto(inspection, Uint8List.fromList([0, 127, 255, 7]));
    Future<Map<String, dynamic>> snapshot() async =>
        jsonDecode(await (await BackupService.exportBackup()).readAsString()) as Map<String, dynamic>;
    final original = await snapshot();
    final originalFile = await BackupService.exportBackup();
    await db.rawUpdate('UPDATE Equipment SET wll=9 WHERE id=987654321');
    await BackupService.importBackup(originalFile);
    expect((await snapshot())['databases'], original['databases']);
    final dir = await getApplicationDocumentsDirectory();
    final badFile = File('${dir.path}/native_invalid_backup.json');
    await badFile.writeAsString('{"format":"invalid","version":999}');
    await expectLater(BackupService.importBackup(badFile), throwsFormatException);
    expect((await snapshot())['databases'], original['databases']);
    await db.rawUpdate('UPDATE Equipment SET wll=7 WHERE id=987654321');
    final current = await snapshot();
    final dbDir = await getDatabasesPath();
    await db.execute('ATTACH DATABASE ? AS runtime_pro2', ['$dbDir/rigging_pro2.db']);
    await db.execute("CREATE TRIGGER runtime_pro2.reject_native_restore BEFORE INSERT ON inspections BEGIN SELECT RAISE(ABORT, 'injected native failure'); END");
    await db.execute('DETACH DATABASE runtime_pro2');
    try {
      await expectLater(BackupService.importBackup(originalFile), throwsA(isA<DatabaseException>()));
      expect((await snapshot())['databases'], current['databases']);
    } finally {
      await db.execute('ATTACH DATABASE ? AS runtime_pro2', ['$dbDir/rigging_pro2.db']);
      await db.execute('DROP TRIGGER runtime_pro2.reject_native_restore');
      await db.execute('DETACH DATABASE runtime_pro2');
    }
    final recovery = Directory('${dir.path}/backups').listSync().whereType<File>()
        .where((file) => file.path.contains('before_restore_'));
    expect(recovery, isNotEmpty);
  });
}
