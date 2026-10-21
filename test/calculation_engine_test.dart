import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:saddam_rigging_az_master_calculator/services/calculation_engine.dart';

void main() {
  test('gross load includes each accessory and rejects invalid weights', () {
    expect(
      CalculationEngine.grossLoadKg(10000, [500, 100, 40, 300, 150, 20]),
      11110,
    );
    for (final bad in [-1.0, double.nan, double.infinity]) {
      expect(
        () => CalculationEngine.grossLoadKg(bad, [0]),
        throwsArgumentError,
      );
      expect(
        () => CalculationEngine.grossLoadKg(100, [bad]),
        throwsArgumentError,
      );
    }
    expect(() => CalculationEngine.grossLoadKg(0, []), throwsArgumentError);
  });
  for (final angle in [30.0, 45.0, 60.0, 90.0]) {
    test('sling equilibrium and conventions at $angle degrees', () {
      final a = CalculationEngine.sling(
        loadKg: 10000,
        effectiveLegs: 2,
        angleDegrees: angle,
      );
      final b = CalculationEngine.sling(
        loadKg: 10000,
        effectiveLegs: 2,
        angleDegrees: 90 - angle,
        convention: AngleConvention.vertical,
      );
      final expected =
          10000 *
          CalculationEngine.gravity /
          (2 * math.sin(angle * math.pi / 180));
      expect(a.values['tensionN'], closeTo(expected, 1e-7));
      expect(a.values['tensionN'], closeTo(b.values['tensionN']!, 1e-7));
      expect(a.status, CheckStatus.incomplete);
      expect(a.requiresHumanApproval, isTrue);
    });
  }
  test('singular, negative and non-finite sling inputs are rejected', () {
    for (final a in [0.0, -1.0, 91.0, double.nan, double.infinity]) {
      expect(
        () => CalculationEngine.sling(
          loadKg: 100,
          effectiveLegs: 2,
          angleDegrees: a,
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => CalculationEngine.sling(
        loadKg: 100,
        effectiveLegs: 0,
        angleDegrees: 60,
      ),
      throwsArgumentError,
    );
    expect(
      () => CalculationEngine.sling(
        loadKg: 100,
        effectiveLegs: 2,
        angleDegrees: 60,
        selectedWllKg: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => CalculationEngine.sling(
        loadKg: -100,
        effectiveLegs: 2,
        angleDegrees: 60,
      ),
      throwsArgumentError,
    );
    final low = CalculationEngine.sling(
      loadKg: 100,
      effectiveLegs: 2,
      angleDegrees: 0.01,
    );
    expect(low.values['requiredWllKg']!, greaterThan(100000));
    expect(low.warnings, isNotEmpty);
  });
  test('sling capacity never passes with missing verification and detects overload', () {
    final incomplete = CalculationEngine.sling(
      loadKg: 100,
      effectiveLegs: 2,
      angleDegrees: 90,
      selectedWllKg: 100,
      ratingSource: 'Tag A',
    );
    expect(incomplete.status, CheckStatus.incomplete);
    final equal = CalculationEngine.sling(
      loadKg: 100,
      effectiveLegs: 2,
      angleDegrees: 90,
      selectedWllKg: 50,
      ratingSource: 'Tag A, configuration 1',
      ratingVerified: true,
    );
    expect(equal.values['utilizationPercent'], closeTo(100, 1e-10));
    expect(equal.status, CheckStatus.acceptable);
    final over = CalculationEngine.sling(
      loadKg: 101,
      effectiveLegs: 2,
      angleDegrees: 90,
      selectedWllKg: 50,
      ratingSource: 'Tag A',
      ratingVerified: true,
    );
    expect(over.status, CheckStatus.notAcceptable);
  });
  test('crane uses gross load; missing chart configuration cannot pass', () {
    for (final mass in [999.0, 1000.0, 1001.0]) {
      final result = CalculationEngine.craneUtilization(
        grossKg: mass,
        capacityKg: 1000,
        chartSource: 'Manufacturer chart rev 2, page 4',
        configurationVerified: true,
      );
      expect(result.values['utilizationPercent'], closeTo(mass / 10, 1e-10));
      expect(
        result.status,
        mass > 1000 ? CheckStatus.notAcceptable : CheckStatus.acceptable,
      );
      expect(result.requiresHumanApproval, isTrue);
    }
    expect(
      CalculationEngine.craneUtilization(
        grossKg: 500,
        capacityKg: 1000,
        chartSource: '',
      ).status,
      CheckStatus.incomplete,
    );
    expect(
      () => CalculationEngine.craneUtilization(
        grossKg: 100,
        capacityKg: 0,
        chartSource: '',
      ),
      throwsArgumentError,
    );
  });
  test('shackle/hardware uses supplied manufacturer derating only', () {
    final overload = CalculationEngine.hardware(
      loadN: 5000,
      wllKg: 1000,
      manufacturerFactor: 0.5,
      source: 'Manufacturer table rev 2',
      verified: true,
    );
    expect(overload.status, CheckStatus.notAcceptable);
    expect(overload.values['capacityN'], closeTo(4903.325, 1e-8));
    expect(
      CalculationEngine.hardware(
        loadN: 100,
        wllKg: 1000,
        manufacturerFactor: 1,
        source: '',
      ).status,
      CheckStatus.incomplete,
    );
    expect(
      () => CalculationEngine.hardware(
        loadN: 100,
        wllKg: 1000,
        manufacturerFactor: 1.1,
        source: '',
      ),
      throwsArgumentError,
    );
  });
  test(
    'tandem uses unequal CG, individual rigging and separate capacities',
    () {
      final r = CalculationEngine.tandem(
        loadKg: 10000,
        spanM: 10,
        cgFromLeftM: 2,
        accessoryAKg: 500,
        accessoryBKg: 100,
        dynamicFactor: 1.1,
        capacityAKg: 10000,
        capacityBKg: 4000,
        sourceA: 'Chart A',
        sourceB: 'Chart B',
        factorSource: 'Approved engineering factor',
        configurationsVerified: true,
      );
      expect(r.values['grossAKg'], closeTo(9350, 1e-8));
      expect(r.values['grossBKg'], closeTo(2310, 1e-8));
      expect(r.values['utilizationAPercent'], closeTo(93.5, 1e-8));
      expect(r.values['utilizationBPercent'], closeTo(57.75, 1e-8));
      expect(r.status, CheckStatus.reviewRequired);
      expect(r.requiresHumanApproval, isTrue);
    },
  );
  test('two-point reactions conserve weight and moments with offset CG', () {
    for (final cg in [0.0, 2.0, 5.0, 10.0]) {
      final r = CalculationEngine.twoPointShare(
        loadKg: 1000,
        spanM: 10,
        cgFromLeftM: cg,
      ).values;
      expect(r['leftKg']! + r['rightKg']!, closeTo(1000, 1e-10));
      expect(r['rightKg']! * 10, closeTo(1000 * cg, 1e-10));
    }
    expect(
      () => CalculationEngine.twoPointShare(
        loadKg: 1000,
        spanM: 10,
        cgFromLeftM: 11,
      ),
      throwsArgumentError,
    );
  });
  test('3D CG uses all mass points and permits negative datum coordinates', () {
    final r = CalculationEngine.centerOfMass([
      const MassPoint(100, -2, 0, 1),
      const MassPoint(300, 2, 4, 3),
    ]);
    expect(r.values, {'massKg': 400, 'xM': 1, 'yM': 3, 'zM': 2.5});
    expect(r.inputs['mass2Kg'], 300);
    expect(
      () => CalculationEngine.centerOfMass([const MassPoint(0, 0, 0)]),
      throwsArgumentError,
    );
    expect(
      () => CalculationEngine.centerOfMass([const MassPoint(-1, 0, 0)]),
      throwsArgumentError,
    );
  });
  test(
    'radius and boom geometry use metre coordinates without GPS assumptions',
    () {
      expect(CalculationEngine.radiusM(0, 0, 3, 4), 5);
      expect(CalculationEngine.radiusM(-1, -2, -1, -2), 0);
      expect(
        CalculationEngine.boomRadiusM(
          boomM: 20,
          angleDegrees: 60,
          pivotOffsetM: 1,
          hookOffsetM: 0.5,
        ),
        closeTo(10.5, 1e-10),
      );
      expect(CalculationEngine.boomRadiusM(boomM: 20, angleDegrees: 90), 0);
      expect(
        () => CalculationEngine.boomRadiusM(boomM: 20, angleDegrees: 91),
        throwsArgumentError,
      );
      expect(
        () => CalculationEngine.radiusM(0, double.nan, 1, 1),
        throwsArgumentError,
      );
    },
  );
  test(
    'ground pressure and required area use verified reaction and soil inputs',
    () {
      final r = CalculationEngine.ground(
        reactionN: 200000,
        lengthM: 2,
        widthM: 2,
        allowablePa: 100000,
        groundSource: 'Geotechnical report G1 rev 3',
        reactionSource: 'Manufacturer reaction sheet R1',
        sourcesVerified: true,
      );
      expect(r.values['pressurePa'], 50000);
      expect(r.values['requiredAreaM2'], 2);
      expect(r.values['providedAreaM2'], 4);
      expect(r.values['utilizationPercent'], 50);
      expect(r.status, CheckStatus.acceptable);
      expect(
        CalculationEngine.ground(
          reactionN: 200000,
          lengthM: 2,
          widthM: 2,
          allowablePa: 100000,
        ).status,
        CheckStatus.incomplete,
      );
      expect(
        CalculationEngine.ground(
          reactionN: 200000,
          lengthM: 1,
          widthM: 1,
          allowablePa: 100000,
        ).status,
        CheckStatus.notAcceptable,
      );
      expect(
        () =>
            CalculationEngine.ground(reactionN: 200000, lengthM: 0, widthM: 1),
        throwsArgumentError,
      );
    },
  );
  test('units round-trip in each dimension and distinguish imperial tons', () {
    for (final group in UnitConversion.groups.values) {
      for (final a in group.keys) {
        for (final b in group.keys) {
          expect(
            UnitConversion.convert(UnitConversion.convert(123.456, a, b), b, a),
            closeTo(123.456, 1e-8),
          );
        }
      }
    }
    expect(UnitConversion.convert(1, 'short ton (US)', 'kg'), 907.18474);
    expect(UnitConversion.convert(1, 'long ton (UK)', 'kg'), 1016.0469088);
    expect(UnitConversion.convert(36, 'km/h', 'm/s'), 10);
    expect(() => UnitConversion.convert(1, 'm', 'kg'), throwsArgumentError);
    expect(
      () => UnitConversion.convert(1, 'unknown', 'm'),
      throwsArgumentError,
    );
    expect(
      () => UnitConversion.convert(double.nan, 'm', 'ft'),
      throwsArgumentError,
    );
  });
}
