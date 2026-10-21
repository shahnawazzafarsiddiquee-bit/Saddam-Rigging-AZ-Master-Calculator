import 'dart:math' as math;

enum CheckStatus { acceptable, reviewRequired, notAcceptable, incomplete }

enum ValueSource {
  mathematical,
  manufacturer,
  standard,
  companyRule,
  projectRule,
  userInput,
}

enum AngleConvention { horizontal, vertical }

/// Canonical internal units: kg, m, N, Pa and m/s. A successful numerical
/// check is never a lifting authorization.
class CalculationResult {
  final Map<String, double> inputs;
  final Map<String, double> values;
  final Map<String, String> units;
  final String method;
  final String source;
  final ValueSource sourceType;
  final List<String> assumptions;
  final List<String> warnings;
  final CheckStatus status;
  const CalculationResult({
    required this.inputs,
    required this.values,
    required this.units,
    required this.method,
    required this.source,
    this.sourceType = ValueSource.mathematical,
    this.assumptions = const [],
    this.warnings = const [],
    this.status = CheckStatus.reviewRequired,
  });

  bool get requiresHumanApproval => true;
  String get statusLabel => switch (status) {
    CheckStatus.acceptable => 'ACCEPTABLE - CALCULATION ONLY',
    CheckStatus.reviewRequired => 'REVIEW REQUIRED',
    CheckStatus.notAcceptable => 'NOT ACCEPTABLE',
    CheckStatus.incomplete => 'INCOMPLETE - VERIFICATION REQUIRED',
  };
  Map<String, Object?> toJson() => {
    'inputs': inputs,
    'values': values,
    'units': units,
    'method': method,
    'source': source,
    'sourceType': sourceType.name,
    'assumptions': assumptions,
    'warnings': warnings,
    'status': status.name,
    'requiresHumanApproval': requiresHumanApproval,
  };
}

class MassPoint {
  final double kg, x, y, z;
  const MassPoint(this.kg, this.x, this.y, [this.z = 0]);
}

class CalculationEngine {
  static const gravity = 9.80665;
  static void finite(
    double value,
    String name, {
    double? minimum,
    bool positive = false,
  }) {
    if (!value.isFinite ||
        (minimum != null && value < minimum) ||
        (positive && value <= 0)) {
      throw ArgumentError(
        '$name must be finite${positive
            ? ' and greater than zero'
            : minimum == null
            ? ''
            : ' and at least $minimum'}.',
      );
    }
  }

  static double _checked(double value) {
    if (!value.isFinite)
      throw ArgumentError(
        'Calculation is outside the supported numeric range.',
      );
    return value;
  }

  static double grossLoadKg(double payloadKg, Iterable<double> accessoryKg) {
    finite(payloadKg, 'Payload', positive: true);
    var total = payloadKg;
    for (final mass in accessoryKg) {
      finite(mass, 'Accessory mass', minimum: 0);
      total = _checked(total + mass);
    }
    return total;
  }

  static CalculationResult sling({
    required double loadKg,
    required int effectiveLegs,
    required double angleDegrees,
    AngleConvention convention = AngleConvention.horizontal,
    double? selectedWllKg,
    String ratingSource = '',
    bool ratingVerified = false,
  }) {
    finite(loadKg, 'Load', positive: true);
    finite(angleDegrees, 'Angle');
    if (effectiveLegs < 1 || effectiveLegs > 4)
      throw ArgumentError('Effective legs must be 1 to 4.');
    final horizontal = convention == AngleConvention.horizontal
        ? angleDegrees
        : 90 - angleDegrees;
    if (horizontal <= 0 || horizontal > 90)
      throw ArgumentError('Horizontal angle must be > 0 and <= 90 degrees.');
    final factor = _checked(1 / math.sin(horizontal * math.pi / 180));
    final tensionN = _checked(loadKg * gravity / effectiveLegs * factor);
    final values = <String, double>{
      'verticalLoadPerLegN': loadKg * gravity / effectiveLegs,
      'tensionN': tensionN,
      'requiredWllKg': tensionN / gravity,
      'angleFactor': factor,
      'horizontalDegrees': horizontal,
    };
    var status = CheckStatus.incomplete;
    if (selectedWllKg != null) {
      finite(selectedWllKg, 'Selected configuration WLL', positive: true);
      final utilization = _checked(tensionN / gravity / selectedWllKg * 100);
      values['utilizationPercent'] = utilization;
      status = utilization > 100
          ? CheckStatus.notAcceptable
          : ratingSource.trim().isEmpty || !ratingVerified
          ? CheckStatus.incomplete
          : horizontal < 30
          ? CheckStatus.reviewRequired
          : CheckStatus.acceptable;
    }
    return CalculationResult(
      inputs: {
        'loadKg': loadKg,
        'effectiveLegs': effectiveLegs.toDouble(),
        'angleDegrees': angleDegrees,
        if (selectedWllKg != null) 'selectedWllKg': selectedWllKg,
      },
      values: values,
      units: {
        'loadKg': 'kg',
        'tensionN': 'N',
        'verticalLoadPerLegN': 'N',
        'requiredWllKg': 'kg',
        'horizontalDegrees': 'deg',
        'utilizationPercent': '%',
      },
      method: 'T = mass × g / (effective supporting legs × sin(angle from horizontal))',
      source: ratingSource.trim().isEmpty
          ? 'Mathematical equilibrium; configuration WLL unverified'
          : ratingSource,
      assumptions: const [
        'Symmetric equal load sharing; no dynamic or unequal-CG factor.',
        'Effective supporting legs must be established for the actual arrangement.',
        'Selected WLL must already include verified hitch, angle and environmental derating.',
      ],
      warnings: [
        if (horizontal < 30)
          'Very low sling angle: competent-person review required.',
        if (selectedWllKg == null || ratingSource.trim().isEmpty)
          'VERIFY TAG / CERTIFICATE AND CONFIGURATION WLL',
        'This calculation does not approve the lift.',
      ],
      status: status,
    );
  }

  /// The configuration factor is entered from the actual manufacturer's chart,
  /// referenced to the marked straight WLL of one sling. It already includes
  /// hitch, installed legs and angle: never apply the angle factor twice.
  static CalculationResult syntheticSling({
    required double loadKg,
    required double markedWllKg,
    required double configurationFactor,
    required int effectiveLegs,
    required double angleDegrees,
    AngleConvention convention = AngleConvention.horizontal,
    required String configurationSource,
    bool tagAndConfigurationVerified = false,
    bool environmentAndGeometryVerified = false,
    bool sharpEdge = false,
    bool suitableProtectionVerified = false,
    bool damageFound = false,
  }) {
    finite(markedWllKg, 'Marked straight WLL', positive: true);
    finite(configurationFactor, 'Manufacturer configuration factor', positive: true);
    final geometry = sling(loadKg: loadKg, effectiveLegs: effectiveLegs,
        angleDegrees: angleDegrees, convention: convention);
    final capacityKg = _checked(markedWllKg * configurationFactor);
    final requiredMarkedWllKg = _checked(loadKg / configurationFactor);
    final utilization = _checked(loadKg / capacityKg * 100);
    final blocked = damageFound || (sharpEdge && !suitableProtectionVerified);
    final verified = tagAndConfigurationVerified &&
        configurationSource.trim().isNotEmpty && environmentAndGeometryVerified;
    return CalculationResult(
      inputs: {...geometry.inputs, 'markedWllKg': markedWllKg,
        'configurationFactor': configurationFactor},
      values: {...geometry.values, 'configurationCapacityKg': capacityKg,
        'requiredMarkedWllKg': requiredMarkedWllKg,
        'utilizationPercent': utilization},
      units: {...geometry.units, 'markedWllKg': 'kg',
        'configurationCapacityKg': 'kg', 'requiredMarkedWllKg': 'kg'},
      method: 'Assembly capacity = marked straight WLL × manufacturer configuration factor; utilization = load / assembly capacity × 100. Leg tension is a separate symmetric geometry estimate.',
      source: configurationSource.trim().isEmpty
          ? 'Manufacturer configuration source missing' : configurationSource,
      sourceType: ValueSource.manufacturer,
      assumptions: const [
        'Entered factor applies to the complete selected arrangement, actual angle, material and sling model; it is not inferred from colour.',
        'No second angle or leg multiplier is applied to the assembly rating.',
        'Leg tension assumes verified symmetric equal sharing and known effective legs; unequal CG needs a separate engineered distribution.',
      ],
      warnings: [
        if (!verified) 'VERIFY TAG / CERTIFICATE, manufacturer chart revision, environment and actual geometry.',
        if (damageFound) 'REJECT / HOLD: damage or missing identification recorded. Remove from use for inspection.',
        if (sharpEdge && !suitableProtectionVerified) 'Sharp edge: suitable manufacturer-approved protection must be verified before use.',
        if (geometry.values['horizontalDegrees']! < 30) 'Very low sling angle: competent-person review required.',
        'Body colour and inspection-period colour are separate records; neither proves WLL.',
        'This calculation does not approve a lift or replace a formal equipment inspection.',
      ],
      status: blocked || utilization > 100 ? CheckStatus.notAcceptable
          : !verified ? CheckStatus.incomplete
          : geometry.values['horizontalDegrees']! < 30
          ? CheckStatus.reviewRequired : CheckStatus.acceptable,
    );
  }

  static CalculationResult craneUtilization({
    required double grossKg,
    required double capacityKg,
    required String chartSource,
    bool configurationVerified = false,
  }) {
    finite(grossKg, 'Gross hook load', positive: true);
    finite(capacityKg, 'Capacity', positive: true);
    final u = _checked(grossKg / capacityKg * 100);
    return CalculationResult(
      inputs: {'grossKg': grossKg, 'capacityKg': capacityKg},
      values: {'utilizationPercent': u},
      units: {'grossKg': 'kg', 'capacityKg': 'kg', 'utilizationPercent': '%'},
      method: 'Gross hook load / applicable chart capacity × 100',
      source: chartSource,
      sourceType: ValueSource.manufacturer,
      assumptions: const [
        'Gross load includes payload, hook block and every rigging accessory.',
        'Use the most limiting verified pick, maximum and set configuration.',
      ],
      warnings: const [
        'Manufacturer chart deductions and configuration require verification.',
        'Competent-person confirmation and lift authorization remain required.',
      ],
      status: u > 100
          ? CheckStatus.notAcceptable
          : chartSource.trim().isEmpty || !configurationVerified
          ? CheckStatus.incomplete
          : CheckStatus.acceptable,
    );
  }

  static CalculationResult hardware({
    required double loadN,
    required double wllKg,
    required double manufacturerFactor,
    required String source,
    bool verified = false,
  }) {
    finite(loadN, 'Hardware load', positive: true);
    finite(wllKg, 'Marked WLL', positive: true);
    finite(manufacturerFactor, 'Manufacturer derating factor', positive: true);
    if (manufacturerFactor > 1)
      throw ArgumentError('Derating factor must not exceed 1.');
    final capacityN = _checked(wllKg * gravity * manufacturerFactor);
    final u = _checked(loadN / capacityN * 100);
    return CalculationResult(
      inputs: {
        'loadN': loadN,
        'wllKg': wllKg,
        'manufacturerFactor': manufacturerFactor,
      },
      values: {'capacityN': capacityN, 'utilizationPercent': u},
      units: {
        'loadN': 'N',
        'wllKg': 'kg',
        'capacityN': 'N',
        'utilizationPercent': '%',
      },
      method:
          'Capacity = marked WLL × g × verified manufacturer derating factor',
      source: source,
      sourceType: ValueSource.manufacturer,
      warnings: const [
        'Use the actual manufacturer table for side loading and configuration. No generic angle derating is assumed.',
        'Hardware fit, pin type, inspection and certificate require separate verification.',
      ],
      status: u > 100
          ? CheckStatus.notAcceptable
          : source.trim().isEmpty || !verified
          ? CheckStatus.incomplete
          : CheckStatus.acceptable,
    );
  }

  static CalculationResult tandem({
    required double loadKg,
    required double spanM,
    required double cgFromLeftM,
    required double accessoryAKg,
    required double accessoryBKg,
    required double dynamicFactor,
    double? capacityAKg,
    double? capacityBKg,
    String sourceA = '',
    String sourceB = '',
    String factorSource = '',
    bool configurationsVerified = false,
  }) {
    finite(accessoryAKg, 'Crane A accessories', minimum: 0);
    finite(accessoryBKg, 'Crane B accessories', minimum: 0);
    finite(dynamicFactor, 'Dynamic factor', minimum: 1);
    if (cgFromLeftM <= 0 || cgFromLeftM >= spanM)
      throw ArgumentError('Tandem CG must be strictly between supports.');
    final share = twoPointShare(
      loadKg: loadKg,
      spanM: spanM,
      cgFromLeftM: cgFromLeftM,
    );
    final grossA = _checked(
      (share.values['leftKg']! + accessoryAKg) * dynamicFactor,
    );
    final grossB = _checked(
      (share.values['rightKg']! + accessoryBKg) * dynamicFactor,
    );
    final values = <String, double>{
      'sharedAKg': share.values['leftKg']!,
      'sharedBKg': share.values['rightKg']!,
      'grossAKg': grossA,
      'grossBKg': grossB,
    };
    var status = CheckStatus.incomplete;
    if (capacityAKg != null)
      finite(capacityAKg, 'Crane A capacity', positive: true);
    if (capacityBKg != null)
      finite(capacityBKg, 'Crane B capacity', positive: true);
    if (capacityAKg != null && capacityBKg != null) {
      finite(capacityAKg, 'Crane A capacity', positive: true);
      finite(capacityBKg, 'Crane B capacity', positive: true);
      values['utilizationAPercent'] = _checked(grossA / capacityAKg * 100);
      values['utilizationBPercent'] = _checked(grossB / capacityBKg * 100);
      status =
          values['utilizationAPercent']! > 100 ||
              values['utilizationBPercent']! > 100
          ? CheckStatus.notAcceptable
          : !configurationsVerified ||
                [sourceA, sourceB, factorSource].any((s) => s.trim().isEmpty)
          ? CheckStatus.incomplete
          : CheckStatus.reviewRequired;
    }
    return CalculationResult(
      inputs: {
        'loadKg': loadKg,
        'spanM': spanM,
        'cgFromLeftM': cgFromLeftM,
        'accessoryAKg': accessoryAKg,
        'accessoryBKg': accessoryBKg,
        'dynamicFactor': dynamicFactor,
        if (capacityAKg != null) 'capacityAKg': capacityAKg,
        if (capacityBKg != null) 'capacityBKg': capacityBKg,
      },
      values: values,
      units: {
        'loadKg': 'kg',
        'spanM': 'm',
        'cgFromLeftM': 'm',
        'accessoryAKg': 'kg',
        'accessoryBKg': 'kg',
        'capacityAKg': 'kg',
        'capacityBKg': 'kg',
        'sharedAKg': 'kg',
        'sharedBKg': 'kg',
        'grossAKg': 'kg',
        'grossBKg': 'kg',
        'utilizationAPercent': '%',
        'utilizationBPercent': '%',
      },
      method: 'Static CG reaction sharing; each gross load = (shared payload + own accessories) × entered dynamic factor',
      source:
          'Crane A: $sourceA; Crane B: $sourceB; dynamic factor: $factorSource',
      assumptions: const [
        'Rigid static two-point load. No simulation of load transfer during movement.',
        'Each capacity must cover its own most limiting verified lift radius/configuration.',
      ],
      warnings: const [
        'Tandem lifts require an engineered plan, synchronization and authorized supervision.',
      ],
      status: status,
    );
  }

  static CalculationResult twoPointShare({
    required double loadKg,
    required double spanM,
    required double cgFromLeftM,
  }) {
    finite(loadKg, 'Load', positive: true);
    finite(spanM, 'Span', positive: true);
    finite(cgFromLeftM, 'CG');
    if (cgFromLeftM < 0 || cgFromLeftM > spanM)
      throw ArgumentError('CG must lie between supports.');
    return CalculationResult(
      inputs: {'loadKg': loadKg, 'spanM': spanM, 'cgFromLeftM': cgFromLeftM},
      values: {
        'leftKg': _checked(loadKg * (1 - cgFromLeftM / spanM)),
        'rightKg': _checked(loadKg * cgFromLeftM / spanM),
      },
      units: {
        'loadKg': 'kg',
        'spanM': 'm',
        'cgFromLeftM': 'm',
        'leftKg': 'kg',
        'rightKg': 'kg',
      },
      method: 'Rleft = W × (span - CG)/span; Rright = W × CG/span',
      source: 'Static force and moment equilibrium',
      assumptions: const [
        'Two vertical reactions, rigid load and verified CG; no dynamics.',
      ],
      warnings: const [
        'Do not use this model for indeterminate three/four-point arrangements without engineering analysis.',
      ],
    );
  }

  static CalculationResult centerOfMass(List<MassPoint> points) {
    if (points.isEmpty)
      throw ArgumentError('At least one mass point is required.');
    var mass = 0.0, x = 0.0, y = 0.0, z = 0.0;
    for (final point in points) {
      finite(point.kg, 'Mass', minimum: 0);
      finite(point.x, 'X');
      finite(point.y, 'Y');
      finite(point.z, 'Z');
      mass = _checked(mass + point.kg);
      x = _checked(x + point.kg * point.x);
      y = _checked(y + point.kg * point.y);
      z = _checked(z + point.kg * point.z);
    }
    finite(mass, 'Total mass', positive: true);
    return CalculationResult(
      inputs: {
        for (var i = 0; i < points.length; i++) ...{
          'mass${i + 1}Kg': points[i].kg,
          'x${i + 1}M': points[i].x,
          'y${i + 1}M': points[i].y,
          'z${i + 1}M': points[i].z,
        },
      },
      values: {'massKg': mass, 'xM': x / mass, 'yM': y / mass, 'zM': z / mass},
      units: {'massKg': 'kg', 'xM': 'm', 'yM': 'm', 'zM': 'm'},
      method: 'CG = sum(mass × coordinate) / total mass',
      source: 'Weighted mass coordinates',
      assumptions: const ['All coordinates share the same datum.'],
      warnings: const [
        'CG coordinates alone do not establish lifting-point load distribution.',
      ],
    );
  }

  static double radiusM(
    double craneX,
    double craneY,
    double loadX,
    double loadY,
  ) {
    for (final v in [craneX, craneY, loadX, loadY]) {
      finite(v, 'Site coordinate');
    }
    final dx = loadX - craneX, dy = loadY - craneY;
    return _checked(math.sqrt(dx * dx + dy * dy));
  }

  static double boomRadiusM({
    required double boomM,
    required double angleDegrees,
    double pivotOffsetM = 0,
    double hookOffsetM = 0,
  }) {
    finite(boomM, 'Boom length', positive: true);
    finite(angleDegrees, 'Boom angle');
    finite(pivotOffsetM, 'Pivot offset');
    finite(hookOffsetM, 'Hook offset');
    if (angleDegrees < 0 || angleDegrees > 90)
      throw ArgumentError('Boom angle must be 0 to 90 degrees.');
    final radius = _checked(
      boomM * math.cos(angleDegrees * math.pi / 180) +
          pivotOffsetM -
          hookOffsetM,
    );
    if (radius < 0) throw ArgumentError('Geometry produces a negative radius.');
    return radius.abs() < 1e-12 ? 0 : radius;
  }

  static CalculationResult ground({
    required double reactionN,
    required double lengthM,
    required double widthM,
    double? allowablePa,
    String groundSource = '',
    String reactionSource = '',
    bool sourcesVerified = false,
  }) {
    finite(reactionN, 'Outrigger reaction', positive: true);
    finite(lengthM, 'Mat length', positive: true);
    finite(widthM, 'Mat width', positive: true);
    final area = _checked(lengthM * widthM);
    finite(area, 'Provided area', positive: true);
    final pressure = _checked(reactionN / area);
    final values = <String, double>{
      'providedAreaM2': area,
      'pressurePa': pressure,
    };
    var status = CheckStatus.incomplete;
    if (allowablePa != null) {
      finite(allowablePa, 'Allowable ground pressure', positive: true);
      values['requiredAreaM2'] = _checked(reactionN / allowablePa);
      values['utilizationPercent'] = _checked(pressure / allowablePa * 100);
      status = pressure > allowablePa
          ? CheckStatus.notAcceptable
          : groundSource.trim().isEmpty ||
                reactionSource.trim().isEmpty ||
                !sourcesVerified
          ? CheckStatus.incomplete
          : CheckStatus.acceptable;
    }
    return CalculationResult(
      inputs: {
        'reactionN': reactionN,
        'lengthM': lengthM,
        'widthM': widthM,
        if (allowablePa != null) 'allowablePa': allowablePa,
      },
      values: values,
      units: {
        'reactionN': 'N',
        'lengthM': 'm',
        'widthM': 'm',
        'allowablePa': 'Pa',
        'providedAreaM2': 'm²',
        'requiredAreaM2': 'm²',
        'pressurePa': 'Pa',
        'utilizationPercent': '%',
      },
      method: 'Pressure = reaction / effective bearing area; required area = reaction / allowable pressure',
      source: 'Ground: $groundSource; reaction: $reactionSource',
      sourceType: ValueSource.userInput,
      assumptions: const [
        'Uniform effective bearing over the entered area; no structural mat or ground engineering approval.',
      ],
      warnings: const [
        'Verify maximum outrigger reaction for the actual crane configuration.',
        'Mat stiffness, thickness, bending, ground voids and local bearing require separate verification.',
        'Ground bearing capacity must never be inferred from GPS.',
      ],
      status: status,
    );
  }
}

class UnitConversion {
  static const groups = <String, Map<String, double>>{
    'Length': {'mm': 0.001, 'cm': 0.01, 'm': 1, 'inch': 0.0254, 'ft': 0.3048},
    'Mass': {
      'kg': 1,
      't (metric)': 1000,
      'lb': 0.45359237,
      'short ton (US)': 907.18474,
      'long ton (UK)': 1016.0469088,
    },
    'Force': {'N': 1, 'kN': 1000, 'lbf': 4.4482216152605},
    'Pressure': {'Pa': 1, 'kPa': 1000, 'psi': 6894.757293168},
    'Wind speed': {'m/s': 1, 'km/h': 1 / 3.6, 'mph': 0.44704},
  };
  static double convert(double value, String from, String to) {
    CalculationEngine.finite(value, 'Value');
    for (final units in groups.values) {
      if (units.containsKey(from) && units.containsKey(to)) {
        return CalculationEngine._checked(value * units[from]! / units[to]!);
      }
    }
    throw ArgumentError(
      'Unknown units or incompatible dimensions: $from -> $to',
    );
  }
}
