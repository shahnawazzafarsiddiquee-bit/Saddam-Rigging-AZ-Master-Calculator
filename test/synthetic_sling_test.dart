import 'package:flutter_test/flutter_test.dart';
import 'package:saddam_rigging_az_master_calculator/services/calculation_engine.dart';

void main() {
  CalculationResult check({
    double load = 2000,
    double wll = 2000,
    double factor = 1,
    double angle = 60,
    int legs = 2,
    bool verified = true,
    bool environment = true,
    bool damage = false,
    bool sharp = false,
    bool protection = false,
    String source = 'TEST manufacturer configuration chart Rev A',
  }) => CalculationEngine.syntheticSling(
    loadKg: load,
    markedWllKg: wll,
    configurationFactor: factor,
    effectiveLegs: legs,
    angleDegrees: angle,
    configurationSource: source,
    tagAndConfigurationVerified: verified,
    environmentAndGeometryVerified: environment,
    damageFound: damage,
    sharpEdge: sharp,
    suitableProtectionVerified: protection,
  );

  test('manufacturer assembly factor includes legs and angle exactly once', () {
    final r = check(factor: 1.4);
    expect(r.values['configurationCapacityKg'], 2800);
    expect(r.values['utilizationPercent'], closeTo(71.428571, 0.00001));
    expect(
      r.values['tensionN']! / CalculationEngine.gravity,
      closeTo(1154.70054, 0.0001),
    );
    expect(r.values['requiredMarkedWllKg'], closeTo(1428.571429, 0.00001));
    expect(r.requiresHumanApproval, isTrue);
  });
  test('capacity equality and overload are distinguished', () {
    expect(check().status, CheckStatus.acceptable);
    expect(check(load: 2000.01).status, CheckStatus.notAcceptable);
  });
  test('no tag, source or environment verification means incomplete', () {
    expect(check(verified: false).status, CheckStatus.incomplete);
    expect(check(source: '').status, CheckStatus.incomplete);
    expect(check(environment: false).status, CheckStatus.incomplete);
  });
  test('damage and unprotected edges block even a low load', () {
    expect(check(load: 100, damage: true).status, CheckStatus.notAcceptable);
    expect(check(load: 100, sharp: true).status, CheckStatus.notAcceptable);
    expect(
      check(load: 100, sharp: true, protection: true).status,
      CheckStatus.acceptable,
    );
  });
  test('invalid inputs never silently become zero; low angles need review', () {
    for (final bad in [0.0, -1.0, double.nan, double.infinity]) {
      expect(() => check(wll: bad), throwsArgumentError);
      expect(() => check(factor: bad), throwsArgumentError);
      expect(() => check(load: bad), throwsArgumentError);
    }
    expect(() => check(angle: 0), throwsArgumentError);
    expect(() => check(angle: 91), throwsArgumentError);
    expect(check(angle: 10).status, CheckStatus.reviewRequired);
    expect(() => check(wll: 1e308, factor: 1e308), throwsArgumentError);
  });
  test('vertical convention is equivalent without doubling the rating', () {
    final vertical = CalculationEngine.syntheticSling(
      loadKg: 2000,
      markedWllKg: 2000,
      configurationFactor: 1.4,
      effectiveLegs: 2,
      angleDegrees: 30,
      convention: AngleConvention.vertical,
      configurationSource: 'TEST chart',
    );
    expect(
      vertical.values['tensionN'],
      closeTo(check().values['tensionN']!, 1e-8),
    );
    expect(vertical.values['configurationCapacityKg'], 2800);
  });
}
