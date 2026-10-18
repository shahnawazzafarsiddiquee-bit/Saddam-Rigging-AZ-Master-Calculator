import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saddam_rigging_az_master_calculator/services/radius_planning.dart';
import 'package:saddam_rigging_az_master_calculator/services/calculation_engine.dart';
import 'package:saddam_rigging_az_master_calculator/screens/smart_radius.dart';

void main() {
  Map<String, Object?> record({
    double maximum = 5,
    double? vp,
    double? vs,
    double? vm,
    String who = '',
    DateTime? at,
  }) => RadiusPlanning.record(
    method: 'Manual',
    source: 'Survey R1',
    inputs: {},
    pickM: 3,
    setM: 4,
    maximumM: maximum,
    verifiedPickM: vp,
    verifiedSetM: vs,
    verifiedMaximumM: vm,
    verifiedBy: who,
    verifiedAt: at,
  );
  test(
    'surveyed site geometry supports translated and negative local coordinates',
    () {
      expect(
        RadiusPlanning.distance(const PlanPoint(-2, -1), const PlanPoint(1, 3)),
        5,
      );
      expect(
        () => RadiusPlanning.distance(
          const PlanPoint(double.infinity, 0),
          const PlanPoint(1, 3),
        ),
        throwsArgumentError,
      );
    },
  );
  test('drawing scale is independent of uniform image resizing', () {
    double radius(double scale) => RadiusPlanning.drawingRadius(
      scaleStart: const PlanPoint(0, 0),
      scaleEnd: PlanPoint(100 * scale, 0),
      scaleMetres: 10,
      crane: PlanPoint(20 * scale, 30 * scale),
      load: PlanPoint(50 * scale, 70 * scale),
    );
    expect(radius(1), 5);
    expect(radius(2), 5);
    expect(
      () => RadiusPlanning.drawingRadius(
        scaleStart: const PlanPoint(1, 1),
        scaleEnd: const PlanPoint(1, 1),
        scaleMetres: 10,
        crane: const PlanPoint(0, 0),
        load: const PlanPoint(2, 3),
      ),
      throwsArgumentError,
    );
  });
  test('full path radius may not be below either endpoint', () {
    expect(() => record(maximum: 3), throwsArgumentError);
    expect(() => record(maximum: double.nan), throwsArgumentError);
    expect(record()['verified'], isNull);
    expect(record()['status'], 'RADIUS REQUIRES FIELD VERIFICATION');
  });
  test('verification is complete, independent and never approval', () {
    expect(() => record(vp: 3), throwsArgumentError);
    expect(
      () =>
          record(vp: 3, vs: 5, vm: 4, who: 'Inspector', at: DateTime.utc(2026)),
      throwsArgumentError,
    );
    final r = record(
      vp: 3.2,
      vs: 4.4,
      vm: 5.5,
      who: 'Inspector',
      at: DateTime.utc(2026),
    );
    expect((r['verified'] as Map)['maximumM'], 5.5);
    expect((r['calculated'] as Map)['maximumM'], 5);
    expect(r['approvalGranted'], false);
  });
  test('height geometry retains original reach calculation without arbitrary crane angle limits', () {
    final g = RadiusPlanning.heightGeometry(
      radiusM: 4,
      pivotOffsetM: 1,
      tipHeightM: 6,
      pivotHeightM: 2,
    );
    expect(g['boomM'], 5);
    expect(g['angleDegrees'], closeTo(53.130102, 0.00001));
    expect(
      () => RadiusPlanning.heightGeometry(
        radiusM: 1,
        pivotOffsetM: 2,
        tipHeightM: 6,
        pivotHeightM: 2,
      ),
      throwsArgumentError,
    );
  });
  test('boom radius uses verified offsets and valid angle convention', () {
    expect(
      CalculationEngine.boomRadiusM(
        boomM: 10,
        angleDegrees: 60,
        pivotOffsetM: 1,
        hookOffsetM: 0.5,
      ),
      closeTo(5.5, 1e-10),
    );
    expect(CalculationEngine.boomRadiusM(boomM: 10, angleDegrees: 90), 0);
    expect(
      () => CalculationEngine.boomRadiusM(boomM: 10, angleDegrees: -1),
      throwsArgumentError,
    );
  });
  testWidgets('manual radius workflow invalidates result when inputs change', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CraneBoomScreen()));
    Future<void> enter(String label, String value) async {
      final finder = find.widgetWithText(TextField, label);
      await tester.ensureVisible(finder);
      await tester.enterText(finder, value);
      await tester.pump();
    }

    await enter('Source / drawing revision / datum', 'Survey R1');
    await enter('Pick radius (m)', '3');
    await enter('Set radius (m)', '4');
    await enter('Maximum entire-path radius (m)', '5');
    final button = find.widgetWithText(ElevatedButton, 'Calculate');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('pickM: 3.000 m'), findsOneWidget);
    expect(find.text('Save radius record'), findsOneWidget);
    await enter('Pick radius (m)', '-1');
    expect(find.text('Save radius record'), findsNothing);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Save radius record'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
