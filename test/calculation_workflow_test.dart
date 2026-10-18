import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saddam_rigging_az_master_calculator/app/theme.dart';
import 'package:saddam_rigging_az_master_calculator/calculators/sling_angle.dart';
import 'package:saddam_rigging_az_master_calculator/calculators/shackle.dart';
import 'package:saddam_rigging_az_master_calculator/calculators/wll.dart';
import 'package:saddam_rigging_az_master_calculator/screens/crane_planning.dart';
import 'package:saddam_rigging_az_master_calculator/screens/rigging_advanced.dart';
import 'package:saddam_rigging_az_master_calculator/screens/rigging_pro2.dart';
import 'package:saddam_rigging_az_master_calculator/calculators/wire_rope.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  Future<void> open(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(432, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: screen),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String label, String value) async {
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> calculate(WidgetTester tester) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final button = find.widgetWithText(ElevatedButton, 'CALCULATE');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets(
    '90-degree sling requires WLL verification and detects overload after editing',
    (tester) async {
      await open(tester, const SlingAngleCalculator());
      await enter(tester, 'Load Weight (t)', '10');
      await enter(tester, 'Sling Angle (horizontal, deg)', '90');
      await calculate(tester);
      expect(find.text('INCOMPLETE - VERIFICATION REQUIRED'), findsOneWidget);
      expect(find.text('5.000 t'), findsWidgets);
      expect(find.text('SAFE'), findsNothing);
      await enter(tester, 'Selected Configuration WLL per Leg (t)', '5');
      await enter(
        tester,
        'Tag / certificate / derating source & revision',
        'Tag S-1, verified vertical configuration',
      );
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(checkbox);
      await tester.pump();
      await calculate(tester);
      expect(find.text('ACCEPTABLE - CALCULATION ONLY'), findsOneWidget);
      await enter(tester, 'Load Weight (t)', '10.1');
      expect(find.text('ACCEPTABLE - CALCULATION ONLY'), findsNothing);
      await calculate(tester);
      expect(find.text('NOT ACCEPTABLE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'reference crane data never claims a verified capacity pass and rejects unmatched radius',
    (tester) async {
      await open(tester, const CranePlanningScreen());
      await enter(tester, 'Working Radius (m)', '3');
      await enter(tester, 'Payload Weight (t)', '1');
      await enter(
        tester,
        'All Rigging / Accessories Weight (t, enter 0 if none)',
        '0',
      );
      await enter(tester, 'Hook Block Weight (t, enter 0 if none)', '0');
      await calculate(tester);
      expect(find.text('INCOMPLETE - VERIFICATION REQUIRED'), findsOneWidget);
      expect(find.text('SAFE'), findsNothing);
      await enter(tester, 'Working Radius (m)', '1000');
      await calculate(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('INCOMPLETE - VERIFICATION REQUIRED'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('shackle catalogue cannot recommend a smaller maximum size', (
    tester,
  ) async {
    await open(tester, const ShackleCalculator());
    await enter(tester, 'Load per Sling Arrangement (t)', '200');
    await calculate(tester);
    expect(find.text('NO LISTED SIZE MEETS DEMAND'), findsOneWidget);
    expect(find.text('150.00 t WLL'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('non-finite WLL input is rejected before a result is shown', (
    tester,
  ) async {
    await open(tester, const WllCalculator());
    await enter(tester, 'Minimum Breaking Load / MBL (t)', 'NaN');
    await calculate(tester);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(SafetyStatusBanner), findsNothing);
  });
  testWidgets(
    'wire-rope numeric overflow is rejected instead of producing infinite WLL',
    (tester) async {
      await open(tester, const WireRopeCalculator());
      await enter(tester, 'Rope Diameter (mm)', '1e200');
      await calculate(tester);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(SafetyStatusBanner), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'a calm wind input does not receive an invented universal approval',
    (tester) async {
      await open(tester, const WindCheckScreen());
      await enter(tester, 'Wind speed', '0');
      final button = find.widgetWithText(ElevatedButton, 'Check');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('INCOMPLETE - approved manufacturer/project wind'),
        findsOneWidget,
      );
      expect(find.textContaining('lifting theek'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'voice wind command requires an approved source rather than a fixed wind rule',
    (tester) async {
      await open(tester, const VoiceScreen());
      await tester.enterText(find.byType(TextField), 'wind 5');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Chalao'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('INCOMPLETE. Approved crane/project wind'),
        findsOneWidget,
      );
      expect(find.textContaining('normal, lifting'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
