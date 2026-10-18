import 'dart:math' as math;

import 'calculation_engine.dart';

/// Plan coordinates are metres in one surveyed local horizontal datum.
/// Image coordinates are pixels in the original, undistorted plan image.
class PlanPoint {
  final double x, y;
  const PlanPoint(this.x, this.y);
  List<double> toJson() => [x, y];
}

class RadiusPlanning {
  static double distance(PlanPoint a, PlanPoint b) =>
      CalculationEngine.radiusM(a.x, a.y, b.x, b.y);

  static double drawingRadius({
    required PlanPoint scaleStart,
    required PlanPoint scaleEnd,
    required double scaleMetres,
    required PlanPoint crane,
    required PlanPoint load,
  }) {
    CalculationEngine.finite(scaleMetres, 'Scale distance', positive: true);
    final pixels = distance(scaleStart, scaleEnd);
    if (pixels < 1)
      throw ArgumentError(
        'Scale points must be at least one image pixel apart.',
      );
    final result = distance(crane, load) / pixels * scaleMetres;
    CalculationEngine.finite(result, 'Drawing radius', positive: true);
    return result;
  }

  static Map<String, double> heightGeometry({
    required double radiusM,
    required double pivotOffsetM,
    required double tipHeightM,
    required double pivotHeightM,
  }) {
    for (final v in [radiusM, pivotOffsetM, tipHeightM, pivotHeightM]) {
      CalculationEngine.finite(v, 'Geometry');
    }
    final x = radiusM - pivotOffsetM, y = tipHeightM - pivotHeightM;
    if (radiusM <= 0 || x <= 0 || y <= 0)
      throw ArgumentError(
        'Positive horizontal reach and height above pivot required.',
      );
    final length = math.sqrt(x * x + y * y);
    CalculationEngine.finite(length, 'Boom length', positive: true);
    return {
      'boomM': length,
      'angleDegrees': math.atan2(y, x) * 180 / math.pi,
      'tipHeightM': tipHeightM,
    };
  }

  static Map<String, Object?> record({
    required String method,
    required String source,
    required Map<String, Object?> inputs,
    required double pickM,
    required double setM,
    required double maximumM,
    double? verifiedPickM,
    double? verifiedSetM,
    double? verifiedMaximumM,
    String verifiedBy = '',
    DateTime? verifiedAt,
  }) {
    if (![
      'Manual',
      'Site geometry',
      'Scaled drawing',
      'Boom geometry',
    ].contains(method))
      throw ArgumentError('Unknown radius method.');
    if (source.trim().isEmpty)
      throw ArgumentError(
        'Survey, drawing or geometry source/reference required.',
      );
    for (final v in [pickM, setM, maximumM]) {
      CalculationEngine.finite(v, 'Radius', positive: true);
    }
    if (maximumM < math.max(pickM, setM))
      throw ArgumentError(
        'Maximum radius must cover pick, set and the entire lift path.',
      );
    final anyVerification =
        verifiedPickM != null ||
        verifiedSetM != null ||
        verifiedMaximumM != null ||
        verifiedBy.trim().isNotEmpty ||
        verifiedAt != null;
    if (anyVerification) {
      if (verifiedPickM == null ||
          verifiedSetM == null ||
          verifiedMaximumM == null ||
          verifiedBy.trim().isEmpty ||
          verifiedAt == null)
        throw ArgumentError(
          'All three verified radii, verifier and verification time required.',
        );
      for (final v in [verifiedPickM, verifiedSetM, verifiedMaximumM]) {
        CalculationEngine.finite(v, 'Verified radius', positive: true);
      }
      if (verifiedMaximumM < math.max(verifiedPickM, verifiedSetM))
        throw ArgumentError(
          'Verified maximum must cover verified pick/set and lift path.',
        );
    }
    return {
      'version': 1,
      'method': method,
      'sourceType': 'USER INPUT',
      'source': source.trim(),
      'inputs': inputs,
      'calculated': {'pickM': pickM, 'setM': setM, 'maximumM': maximumM},
      'verified': anyVerification
          ? {
              'pickM': verifiedPickM,
              'setM': verifiedSetM,
              'maximumM': verifiedMaximumM,
              'by': verifiedBy.trim(),
              'at': verifiedAt!.toUtc().toIso8601String(),
            }
          : null,
      'status': anyVerification
          ? 'FIELD VERIFICATION RECORDED - COMPETENT PERSON REVIEW REQUIRED'
          : 'RADIUS REQUIRES FIELD VERIFICATION',
      'warning': 'Phone GPS is insufficient for safety-critical radius. Check all required crane configurations; maximum radius alone does not prove the limiting capacity.',
      'approvalGranted': false,
    };
  }
}
