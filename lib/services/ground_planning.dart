import 'calculation_engine.dart';

/// A single outrigger footprint; mat inventory quantity never increases area.
class GroundPlanning {
  static Map<String, Object?> record({
    required Map<String, String> context,
    required double reactionN,
    required double lengthM,
    required double widthM,
    required double allowablePa,
    required double? padLengthM,
    required double? padWidthM,
    required double? thicknessM,
    required int quantity,
    required bool verified,
    required DateTime now,
  }) {
    for (final e in {
      'Pad length': padLengthM,
      'Pad width': padWidthM,
      'Mat thickness': thicknessM,
    }.entries) {
      if (e.value != null)
        CalculationEngine.finite(e.value!, e.key, positive: true);
    }
    if (quantity < 1)
      throw ArgumentError('Mat quantity must be a positive integer.');
    if ((padLengthM != null && padLengthM > lengthM) ||
        (padWidthM != null && padWidthM > widthM))
      throw ArgumentError(
        'Pad must fit the entered effective footprint in the shown orientation.',
      );
    final kind = context['reactionKind'];
    if (!['MANUFACTURER', 'ENGINEERING ESTIMATE'].contains(kind))
      throw ArgumentError('Reaction source type required.');
    final complete = [
      'project',
      'crane',
      'configuration',
      'quadrant',
      'reactionSource',
      'groundSource',
      'revision',
      'approvedBy',
      'matType',
    ].every((k) => (context[k] ?? '').trim().isNotEmpty);
    final base = CalculationEngine.ground(
      reactionN: reactionN,
      lengthM: lengthM,
      widthM: widthM,
      allowablePa: allowablePa,
      groundSource:
          '${context['groundSource']}; revision ${context['revision']}; approved by ${context['approvedBy']}',
      reactionSource:
          '$kind: ${context['reactionSource']}; ${context['crane']}; ${context['configuration']}; ${context['quadrant']}',
      sourcesVerified:
          verified &&
          complete &&
          padLengthM != null &&
          padWidthM != null &&
          thicknessM != null,
    );
    final status =
        base.status == CheckStatus.acceptable && kind == 'ENGINEERING ESTIMATE'
        ? CheckStatus.reviewRequired
        : base.status;
    final result = CalculationResult(
      inputs: base.inputs,
      values: base.values,
      units: base.units,
      method: base.method,
      source: base.source,
      sourceType: base.sourceType,
      assumptions: base.assumptions,
      warnings: [
        ...base.warnings,
        'Mat quantity is inventory only; it does not multiply this bearing area.',
        if (kind == 'ENGINEERING ESTIMATE') 'Engineering estimate requires engineering review; it is not manufacturer reaction data.',
      ],
      status: status,
    );
    return {
      'version': 1,
      ...context.map((k, v) => MapEntry(k, v.trim())),
      'padLengthM': padLengthM,
      'padWidthM': padWidthM,
      'thicknessM': thicknessM,
      'quantity': quantity,
      'sourcesVerified': verified,
      'createdAt': now.toUtc().toIso8601String(),
      'result': result.toJson(),
      'approvalGranted': false,
    };
  }
}
