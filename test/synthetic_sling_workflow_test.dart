import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saddam_rigging_az_master_calculator/app/theme.dart';
import 'package:saddam_rigging_az_master_calculator/screens/synthetic_sling.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  Future<void> setup(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(432, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const SyntheticSlingScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final scrollable = find.byType(Scrollable).first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      finder,
      400,
      scrollable: scrollable,
      maxScrolls: 60,
    );
    await tester.pumpAndSettle();
  }

  Future<void> input(WidgetTester tester, String label, String text) async {
    final field = find.widgetWithText(TextField, label);
    await reveal(tester, field);
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  testWidgets('blank synthetic screen never reports SLING OK', (tester) async {
    await setup(tester);
    expect(find.text('SLING OK'), findsNothing);
    await reveal(tester, find.text('INCOMPLETE - VERIFICATION REQUIRED'));
    expect(find.text('INCOMPLETE - VERIFICATION REQUIRED'), findsOneWidget);
    await reveal(
      tester,
      find.text('Observed sling BODY colour (identification only)'),
    );
    expect(
      find.text('Observed sling BODY colour (identification only)'),
      findsOneWidget,
    );
    await reveal(
      tester,
      find.text('Inspection PERIOD colour (separate record)'),
    );
    expect(
      find.text('Inspection PERIOD colour (separate record)'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('actual tag check and edited inputs require fresh confirmation', (
    tester,
  ) async {
    await setup(tester);
    final entries = <String, String>{
      'Load weight': '2',
      'Marked straight WLL from tag': '2',
      'Serial / tag ID': 'TEST-SLING-01',
      'Manufacturer': 'TEST maker',
      'Model / product reference': 'TEST model',
      'Sling length': '4',
      'Manufacturer assembly configuration factor': '1',
      'Manufacturer chart / certificate, page and revision':
          'TEST chart p1 Rev A',
      'CG / effective-leg load-sharing verification':
          'TEST symmetric verified geometry',
      'Environment / edge / temperature approval source':
          'TEST procedure Rev A',
    };
    for (final e in entries.entries) {
      await input(tester, e.key, e.value);
    }
    for (final label in [
      'Tag and factor verified for this exact arrangement',
      'Environment, temperature and CG / equal sharing verified',
    ]) {
      final box = find.widgetWithText(CheckboxListTile, label);
      await reveal(tester, box);
      await tester.tap(box, warnIfMissed: true);
      await tester.pumpAndSettle();
    }
    final button = find.text('Check actual sling configuration');
    await reveal(tester, button);
    await tester.tap(button, warnIfMissed: true);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('ACCEPTABLE - CALCULATION ONLY'));
    expect(find.text('ACCEPTABLE - CALCULATION ONLY'), findsOneWidget);
    await reveal(tester, find.text('100.00 %'));
    expect(find.text('100.00 %'), findsOneWidget);
    await input(tester, 'Load weight', '3');
    expect(find.text('ACCEPTABLE - CALCULATION ONLY'), findsNothing);
    await reveal(tester, find.text('INCOMPLETE - VERIFICATION REQUIRED'));
    expect(find.text('INCOMPLETE - VERIFICATION REQUIRED'), findsOneWidget);
    await reveal(
      tester,
      find.widgetWithText(
        CheckboxListTile,
        'Tag and factor verified for this exact arrangement',
      ),
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(
              CheckboxListTile,
              'Tag and factor verified for this exact arrangement',
            ),
          )
          .value,
      isFalse,
    );
    await reveal(tester, button);
    await tester.tap(button, warnIfMissed: true);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('NOT ACCEPTABLE'));
    expect(find.text('NOT ACCEPTABLE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
