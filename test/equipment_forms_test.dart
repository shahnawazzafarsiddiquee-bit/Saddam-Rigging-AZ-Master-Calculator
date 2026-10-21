import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:saddam_rigging_az_master_calculator/app/theme.dart';
import 'package:saddam_rigging_az_master_calculator/screens/equipment.dart';
import 'package:saddam_rigging_az_master_calculator/screens/lift_plan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactorySqflitePlugin;
  WidgetController.hitTestWarningShouldBeFatal = true;
  const channel = MethodChannel('com.tekartik.sqflite');
  var writes = 0;
  var records = <Map<String, Object?>>[];
  setUp(() {
    writes = 0;
    records = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getDatabasesPath':
              return '/tmp/rigsafe_equipment_form_tests';
            case 'openDatabase':
              return {'id': 1};
            case 'query':
              final sql = (call.arguments as Map)['sql'] as String;
              if (sql.toLowerCase().contains('pragma user_version'))
                return [
                  {'user_version': 1},
                ];
              if (sql.contains('Equipment')) return records;
              return <Map<String, Object?>>[];
            case 'batch':
              return <Object?>[];
            case 'insert':
              writes++;
              return 99;
            case 'update':
              writes++;
              return 1;
            default:
              return null;
          }
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  Future<void> page(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(432, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(theme: AppTheme.darkTheme, home: home));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String label, String text) async {
    final finder = find.widgetWithText(TextField, label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.enterText(finder, text);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
  }

  testWidgets(
    'nullable released equipment opens its QR detail without green active status',
    (tester) async {
      records = [
        {
          'id': 42,
          'equipmentId': 'OLD-NULL-42',
          'type': 'Web Sling',
          'wll': 2.0,
          'status': 'Active',
          'serialNumber': null,
          'manufacturer': null,
          'inspectionDate': null,
          'expiryDate': null,
        },
      ];
      await page(tester, const EquipmentScreen());
      expect(find.text('DATE UNVERIFIED'), findsOneWidget);
      await tester.tap(find.text('OLD-NULL-42'));
      await tester.pumpAndSettle();
      expect(
        find.text('REGISTRATION CURRENT - VERIFY CERTIFICATE'),
        findsNothing,
      );
      expect(find.text('EXPIRED / DATE UNVERIFIED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('equipment form blocks NaN WLL before any database insert', (
    tester,
  ) async {
    await page(tester, const EquipmentScreen());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await enter(tester, 'Equipment ID', 'TEST-INVALID');
    await enter(tester, 'WLL (t)', 'NaN');
    final save = find.text('SAVE');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('WLL must be finite and greater than zero.'),
      findsOneWidget,
    );
    expect(writes, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'restricted legacy equipment cannot be returned to Active from edit form',
    (tester) async {
      records = [
        {
          'id': 42,
          'equipmentId': 'HOLD-42',
          'type': 'Web Sling',
          'wll': 2.0,
          'status': 'Quarantined',
          'serialNumber': 'S-42',
          'manufacturer': 'TEST',
          'inspectionDate': '2026-01-01',
          'expiryDate': '2099-01-01',
        },
      ];
      await page(tester, const EquipmentScreen());
      await tester.longPress(find.text('HOLD-42'));
      await tester.pumpAndSettle();
      final status = find.widgetWithText(
        DropdownButtonFormField<String>,
        'Status',
      );
      await tester.ensureVisible(status);
      await tester.pumpAndSettle();
      await tester.tap(status);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Active').last);
      await tester.pumpAndSettle();
      final save = find.text('SAVE');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Restricted equipment needs an authorized release workflow. Keep it on hold.',
        ),
        findsOneWidget,
      );
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lift plan blocks missing, zero, negative and non-finite weight',
    (tester) async {
      await page(tester, const LiftPlanScreen());
      await enter(tester, 'Project Name', 'TEST project');
      for (final text in ['', '0', '-1', 'NaN', 'Infinity']) {
        await enter(tester, 'Load Weight (t)', text);
        final button = find.text('SAVE & GENERATE PDF');
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(
          find.text('Load weight must be finite and greater than zero.'),
          findsWidgets,
        );
      }
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
