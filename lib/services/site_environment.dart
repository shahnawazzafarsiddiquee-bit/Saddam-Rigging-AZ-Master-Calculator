import 'calculation_engine.dart';

enum WindSource { ble, weather, manual }

class WindReading {
  final double speedMps, gustMps, directionDegrees;
  final DateTime observedAt;
  final WindSource source;
  final String sourceReference;
  final bool connected;
  const WindReading({
    required this.speedMps,
    required this.gustMps,
    required this.directionDegrees,
    required this.observedAt,
    required this.source,
    required this.sourceReference,
    this.connected = true,
  });
  void validate() {
    CalculationEngine.finite(speedMps, 'Wind speed', minimum: 0);
    CalculationEngine.finite(gustMps, 'Gust speed', minimum: 0);
    CalculationEngine.finite(directionDegrees, 'Wind direction', minimum: 0);
    if (directionDegrees >= 360)
      throw ArgumentError('Direction must be 0 to less than 360 degrees.');
    if (gustMps < speedMps)
      throw ArgumentError(
        'Peak gust for the same observation interval cannot be below mean wind.',
      );
    if (sourceReference.trim().isEmpty)
      throw ArgumentError(
        'Instrument / weather / field reading source required.',
      );
  }

  bool currentAt(DateTime now, Duration maxAge) {
    try {
      validate();
    } catch (_) {
      return false;
    }
    final age = now.difference(observedAt);
    return maxAge > Duration.zero &&
        age >= Duration.zero &&
        age <= maxAge &&
        (source != WindSource.ble || connected);
  }

  Map<String, Object?> toJson() => {
    'speedMps': speedMps,
    'gustMps': gustMps,
    'directionDegrees': directionDegrees,
    'observedAt': observedAt.toUtc().toIso8601String(),
    'source': source.name.toUpperCase(),
    'sourceReference': sourceReference,
    'connected': connected,
  };
}

/// Integrations must provide measured values, units and timestamps. A provider
/// cannot grant lifting authorization. Device-specific BLE adapters and an
/// approved weather provider must be configured before they are enabled.
abstract interface class WindProvider {
  WindSource get source;
  Stream<WindReading> get readings;
  Future<void> connect();
  Future<void> disconnect();
}

class WindLimits {
  final double stopMps, stopGustMps;
  final double? warningMps, warningGustMps;
  final Duration maxAge;
  final String source, approvedBy;
  const WindLimits({
    required this.stopMps,
    required this.stopGustMps,
    this.warningMps,
    this.warningGustMps,
    required this.maxAge,
    required this.source,
    required this.approvedBy,
  });
  void validate() {
    for (final v in [stopMps, stopGustMps]) {
      CalculationEngine.finite(v, 'Stop limit', positive: true);
    }
    if (maxAge <= Duration.zero ||
        source.trim().isEmpty ||
        approvedBy.trim().isEmpty)
      throw ArgumentError(
        'Approved limit source, approver and maximum reading age required.',
      );
    if (warningMps != null) {
      CalculationEngine.finite(warningMps!, 'Warning wind', minimum: 0);
      if (warningMps! >= stopMps)
        throw ArgumentError('Warning wind must be below stop wind.');
    }
    if (warningGustMps != null) {
      CalculationEngine.finite(warningGustMps!, 'Warning gust', minimum: 0);
      if (warningGustMps! >= stopGustMps)
        throw ArgumentError('Warning gust must be below stop gust.');
    }
  }

  Map<String, Object?> toJson() => {
    'stopMps': stopMps,
    'stopGustMps': stopGustMps,
    'warningMps': warningMps,
    'warningGustMps': warningGustMps,
    'maxAgeSeconds': maxAge.inSeconds,
    'source': source,
    'approvedBy': approvedBy,
    'sourceType': 'MANUFACTURER / COMPANY / PROJECT DOCUMENT - USER ENTERED',
  };
}

class WindAssessment {
  final String status, explanation;
  const WindAssessment(this.status, this.explanation);
  Map<String, Object?> toJson() => {
    'status': status,
    'explanation': explanation,
    'approvalGranted': false,
  };
}

class WindRules {
  static WindReading? preferred(
    Iterable<WindReading> readings,
    DateTime now,
    Duration maxAge,
  ) {
    final valid = readings.where((r) => r.currentAt(now, maxAge)).toList()
      ..sort((a, b) {
        final priority = a.source.index.compareTo(b.source.index);
        return priority == 0 ? b.observedAt.compareTo(a.observedAt) : priority;
      });
    return valid.isEmpty ? null : valid.first;
  }

  static WindAssessment assess(
    WindReading? reading,
    WindLimits? limits,
    DateTime now,
  ) {
    if (reading == null || limits == null)
      return const WindAssessment(
        'INCOMPLETE - VERIFICATION REQUIRED',
        'Approved wind/gust limits and a current reading are required. There is no universal crane wind limit.',
      );
    try {
      limits.validate();
      reading.validate();
    } catch (e) {
      return WindAssessment('INCOMPLETE - VERIFICATION REQUIRED', '$e');
    }
    // An observed exceedance remains a stop/review even if the reading is stale.
    if (reading.speedMps >= limits.stopMps ||
        reading.gustMps >= limits.stopGustMps)
      return const WindAssessment(
        'STOP / REVIEW',
        'Entered wind or gust is at/above the documented stop limit. Obtain a current field reading and authorized review.',
      );
    if (!reading.currentAt(now, limits.maxAge))
      return const WindAssessment(
        'INCOMPLETE - VERIFICATION REQUIRED',
        'Reading is stale, future-dated or the BLE instrument is disconnected.',
      );
    if ((limits.warningMps != null && reading.speedMps >= limits.warningMps!) ||
        (limits.warningGustMps != null &&
            reading.gustMps >= limits.warningGustMps!))
      return const WindAssessment(
        'WARNING',
        'Entered wind or gust reached a documented warning threshold.',
      );
    if (reading.source == WindSource.weather)
      return const WindAssessment(
        'REVIEW REQUIRED',
        'Weather-service estimate is below entered limits but is not a field wind measurement at the crane.',
      );
    return const WindAssessment(
      'NORMAL - WIND CHECK ONLY',
      'Current entered reading is below the documented limits. This does not approve a lift.',
    );
  }
}

class SiteEnvironmentSnapshot {
  final String site, weather, connectivity;
  final DateTime capturedAt;
  final int utcOffsetMinutes;
  final double? latitude, longitude, temperatureC, humidityPercent;
  final String locationSource;
  final Map<String, Object?>? locationEvidence;
  final WindReading? wind;
  final WindLimits? limits;
  const SiteEnvironmentSnapshot({
    required this.site,
    required this.capturedAt,
    required this.utcOffsetMinutes,
    this.weather = '',
    this.connectivity = 'UNKNOWN',
    this.latitude,
    this.longitude,
    this.temperatureC,
    this.humidityPercent,
    this.locationSource = 'NOT CAPTURED',
    this.locationEvidence,
    this.wind,
    this.limits,
  });
  void validate() {
    if (site.trim().isEmpty) throw ArgumentError('Project / site is required.');
    if ((latitude == null) != (longitude == null))
      throw ArgumentError('Enter both coordinates or leave both blank.');
    if (latitude != null) {
      CalculationEngine.finite(latitude!, 'Latitude');
      CalculationEngine.finite(longitude!, 'Longitude');
      if (latitude!.abs() > 90 || longitude!.abs() > 180)
        throw ArgumentError('Invalid latitude/longitude.');
    }
    if (temperatureC != null) {
      CalculationEngine.finite(temperatureC!, 'Temperature');
      if (temperatureC! < -273.15)
        throw ArgumentError('Temperature below absolute zero.');
    }
    if (humidityPercent != null) {
      CalculationEngine.finite(humidityPercent!, 'Humidity', minimum: 0);
      if (humidityPercent! > 100)
        throw ArgumentError('Humidity must be 0 to 100%.');
    }
    wind?.validate();
    limits?.validate();
  }

  Map<String, Object?> toJson() {
    validate();
    return {
      'version': 1,
      'site': site.trim(),
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'utcOffsetMinutes': utcOffsetMinutes,
      'weather': weather,
      'connectivity': connectivity,
      'latitude': latitude,
      'longitude': longitude,
      'locationSource': locationSource,
      'locationEvidence': locationEvidence,
      'temperatureC': temperatureC,
      'humidityPercent': humidityPercent,
      'wind': wind?.toJson(),
      'limits': limits?.toJson(),
      'windAssessment': WindRules.assess(wind, limits, capturedAt).toJson(),
      'approvalGranted': false,
    };
  }
}
