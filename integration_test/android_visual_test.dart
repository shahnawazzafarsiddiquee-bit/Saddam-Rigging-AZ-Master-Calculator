import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saddam_rigging_az_master_calculator/main.dart';
import 'package:saddam_rigging_az_master_calculator/app/theme.dart';
import 'package:saddam_rigging_az_master_calculator/database/sqlite_helper.dart';
import 'package:saddam_rigging_az_master_calculator/screens/equipment.dart';
import 'package:saddam_rigging_az_master_calculator/screens/synthetic_sling.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('render real dashboard, legacy equipment and synthetic screen', (
    tester,
  ) async {
    await tester.pumpWidget(const SaddamRiggingApp());
    await tester.pumpAndSettle();
    expect(find.text('SADDAM RIGGING A-Z'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final bytes = await binding.takeScreenshot(name);
      expect(bytes.length, greaterThan(1000));
    }

    await capture('verified-dashboard');
    final db = await SqliteHelper.instance.database;
    await db.insert('Equipment', {
      'id': 987654322,
      'equipmentId': 'TEST-VISUAL-QUARANTINE',
      'type': 'Web Sling',
      'wll': 2.0,
      'status': 'Quarantined',
      'serialNumber': null,
      'manufacturer': null,
      'inspectionDate': null,
      'expiryDate': null,
    });
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const EquipmentScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('TEST-VISUAL-QUARANTINE'), findsOneWidget);
    expect(find.text('Quarantined'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture('verified-equipment');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const SyntheticSlingScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Actual tag and arrangement'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();
    expect(find.text('SLING OK'), findsNothing);
    expect(tester.takeException(), isNull);
    await capture('verified-synthetic');
  });
}
