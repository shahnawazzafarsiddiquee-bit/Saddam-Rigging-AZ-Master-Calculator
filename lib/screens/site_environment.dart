import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/site_environment.dart';
import '../services/environment_repository.dart';
import '../services/calculation_engine.dart';

class WindCheckScreen extends StatefulWidget {
  final bool returnSnapshot;
  final String projectHint;
  const WindCheckScreen({
    super.key,
    this.returnSnapshot = false,
    this.projectHint = '',
  });
  @override
  State<WindCheckScreen> createState() => _WindCheckScreenState();
}

class _WindCheckScreenState extends State<WindCheckScreen> {
  final fields = <String, TextEditingController>{};
  String message = '',
      connectivity = 'UNKNOWN',
      locationSource = 'NOT CAPTURED';
  Map<String, Object?>? locationEvidence;
  WindAssessment? assessment;
  String forceText = '';
  bool busy = false;
  TextEditingController c(String name) =>
      fields.putIfAbsent(name, TextEditingController.new);
  @override
  void initState() {
    super.initState();
    c('Project / site').text = widget.projectHint;
    c('Reading timestamp (ISO 8601 with timezone)').text = DateTime.now()
        .toUtc()
        .toIso8601String();
    refreshConnectivity();
  }

  Future<void> refreshConnectivity() async {
    final value = await EnvironmentRepository.connectivity();
    if (mounted) setState(() => connectivity = value);
  }

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  double? optional(String name) {
    if (c(name).text.trim().isEmpty) return null;
    final value = double.tryParse(c(name).text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite)
      throw ArgumentError('$name requires a finite number.');
    return value;
  }

  double number(String name) =>
      optional(name) ?? (throw ArgumentError('$name is required.'));
  Widget field(String name, {String? suffix, bool text = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c(name),
      keyboardType: text
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true, signed: true),
      onChanged: (_) => setState(() {
        assessment = null;
        forceText = '';
        message = '';
        if (name == 'Latitude' || name == 'Longitude') {
          locationSource = 'MANUAL';
          locationEvidence = null;
        }
      }),
      decoration: InputDecoration(
        labelText: name,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  WindReading? reading() {
    if ([
      'Wind speed',
      'Wind gust',
      'Direction',
    ].every((n) => c(n).text.trim().isEmpty))
      return null;
    final stampText = c('Reading timestamp (ISO 8601 with timezone)').text
        .trim();
    if (!RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(stampText))
      throw ArgumentError(
        'Timestamp requires Z or an explicit timezone offset.',
      );
    final stamp = DateTime.tryParse(stampText);
    if (stamp == null) throw ArgumentError('Invalid reading timestamp.');
    final r = WindReading(
      speedMps: number('Wind speed') / 3.6,
      gustMps: number('Wind gust') / 3.6,
      directionDegrees: number('Direction'),
      observedAt: stamp,
      source: WindSource.manual,
      sourceReference: c('Instrument / field reading reference').text,
    );
    r.validate();
    return r;
  }

  WindLimits? limits() {
    const names = [
      'Stop wind',
      'Stop gust',
      'Warning wind (optional)',
      'Warning gust (optional)',
      'Maximum reading age',
      'Limits document / revision / configuration',
      'Limits approved by',
    ];
    if (names.every((n) => c(n).text.trim().isEmpty)) return null;
    final age = number('Maximum reading age');
    if (age <= 0 || age > 100000)
      throw ArgumentError('Enter a positive maximum reading age in minutes.');
    final l = WindLimits(
      stopMps: number('Stop wind') / 3.6,
      stopGustMps: number('Stop gust') / 3.6,
      warningMps: optional('Warning wind (optional)') == null
          ? null
          : number('Warning wind (optional)') / 3.6,
      warningGustMps: optional('Warning gust (optional)') == null
          ? null
          : number('Warning gust (optional)') / 3.6,
      maxAge: Duration(seconds: (age * 60).round()),
      source: c('Limits document / revision / configuration').text,
      approvedBy: c('Limits approved by').text,
    );
    l.validate();
    return l;
  }

  void check() {
    try {
      final r = reading();
      final l = limits();
      var force = '';
      if (c('Projected load area').text.trim().isNotEmpty) {
        if (r == null)
          throw ArgumentError('Wind reading is required for force estimate.');
        final area = number('Projected load area'),
            mass = number('Load weight') * 1000,
            drag = number('Verified drag factor'),
            density = number('Air density');
        for (final x in [area, mass, drag, density]) {
          CalculationEngine.finite(x, 'Wind force input', positive: true);
        }
        final forceN = 0.5 * density * r.speedMps * r.speedMps * drag * area;
        CalculationEngine.finite(forceN, 'Wind force', minimum: 0);
        force =
            'Estimated force = 0.5 × density × speed² × Cd × area: ${forceN.toStringAsFixed(2)} N\nStatic idealized deflection: ${(math.atan(forceN / (mass * CalculationEngine.gravity)) * 180 / math.pi).toStringAsFixed(2)} degrees. No dynamic/gust/crane response is inferred.';
      }
      setState(() {
        assessment = WindRules.assess(r, l, DateTime.now());
        forceText = force;
        message = '';
      });
    } catch (e) {
      setState(() {
        assessment = null;
        forceText = '';
        message =
            'INCOMPLETE - approved manufacturer/project wind and gust limits, valid readings and sources are required. $e';
      });
    }
  }

  Future<void> location() async {
    setState(() => busy = true);
    try {
      final value = await EnvironmentRepository.captureLocation();
      if (!mounted) return;
      setState(() {
        c('Latitude').text = '${value['latitude']}';
        c('Longitude').text = '${value['longitude']}';
        locationSource = 'DEVICE ${value['provider']}';
        locationEvidence = value;
        message =
            'Location captured. Accuracy: ${value['accuracyM'] ?? 'unknown'} m. Not suitable for crane radius.';
      });
    } catch (e) {
      if (mounted) setState(() => message = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final now = DateTime.now();
      final snapshot = SiteEnvironmentSnapshot(
        site: c('Project / site').text,
        capturedAt: now,
        utcOffsetMinutes: now.timeZoneOffset.inMinutes,
        weather: c('Observed weather').text,
        connectivity: connectivity,
        latitude: optional('Latitude'),
        longitude: optional('Longitude'),
        locationSource: locationSource,
        locationEvidence: locationEvidence,
        temperatureC: optional('Temperature'),
        humidityPercent: optional('Humidity'),
        wind: reading(),
        limits: limits(),
      );
      final saved = await EnvironmentRepository.save(snapshot);
      if (!mounted) return;
      if (widget.returnSnapshot) {
        Navigator.pop(context, saved);
        return;
      }
      setState(() {
        assessment = WindRules.assess(snapshot.wind, snapshot.limits, now);
        message = 'Saved environment #${saved['recordId']} offline.';
      });
    } catch (e) {
      if (mounted) setState(() => message = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> history() async {
    try {
      final rows = await EnvironmentRepository.history();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Environment history'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (rows.isEmpty) const Text('No saved environment records.'),
                for (final row in rows)
                  ExpansionTile(
                    title: Text('#${row['recordId']} ${row['site']}'),
                    subtitle: Text('${row['capturedAt']}'),
                    children: [
                      SelectableText(
                        const JsonEncoder.withIndent('  ').convert(row),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => message = 'Could not load history: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Wind & Site Environment'),
      actions: [
        IconButton(
          onPressed: history,
          icon: const Icon(Icons.history),
          tooltip: 'Environment history',
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Source: MANUAL\nNo universal crane wind limit. Enter the limits applicable to the manufacturer, crane configuration and project.',
            ),
            const SizedBox(height: 12),
            field('Wind speed', suffix: 'km/h'),
            field('Wind gust', suffix: 'km/h'),
            field('Direction', suffix: 'degrees'),
            field('Instrument / field reading reference', text: true),
            field('Reading timestamp (ISO 8601 with timezone)', text: true),
            TextButton(
              onPressed: () => setState(() {
                c('Reading timestamp (ISO 8601 with timezone)')
                    .text = DateTime.now()
                    .toUtc()
                    .toIso8601String();
                assessment = null;
              }),
              child: const Text('Record reading time now'),
            ),
            ExpansionTile(
              title: const Text('Documented wind limits'),
              children: [
                field('Stop wind', suffix: 'km/h'),
                field('Stop gust', suffix: 'km/h'),
                field('Warning wind (optional)', suffix: 'km/h'),
                field('Warning gust (optional)', suffix: 'km/h'),
                field('Maximum reading age', suffix: 'minutes'),
                field('Limits document / revision / configuration', text: true),
                field('Limits approved by', text: true),
              ],
            ),
            ElevatedButton(
              onPressed: busy ? null : check,
              child: const Text('Check'),
            ),
            if (message.isNotEmpty)
              Padding(padding: const EdgeInsets.all(12), child: Text(message)),
            if (assessment != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment!.status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: assessment!.status.startsWith('STOP')
                              ? AppColors.danger
                              : assessment!.status.startsWith('NORMAL')
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                      Text(assessment!.explanation),
                      const Text(
                        'Point-in-time check only; this screen does not monitor live wind. Press Check again before use.',
                      ),
                      const Text(
                        'Decision support only. Authorized personnel must approve the lift.',
                      ),
                    ],
                  ),
                ),
              ),
            ExpansionTile(
              title: const Text('Wind force estimate (optional)'),
              children: [
                field('Projected load area', suffix: 'm²'),
                field('Load weight', suffix: 't'),
                field('Verified drag factor'),
                field('Air density', suffix: 'kg/m³'),
                const Text(
                  'Use applicable measured/engineering inputs. No default drag factor or air density is assumed.',
                ),
                if (forceText.isNotEmpty) Text(forceText),
              ],
            ),
            const Divider(),
            field('Project / site', text: true),
            field('Observed weather', text: true),
            field('Temperature', suffix: '°C'),
            field('Humidity', suffix: '%'),
            Text('Connectivity: $connectivity'),
            TextButton(
              onPressed: refreshConnectivity,
              child: const Text('Refresh connectivity'),
            ),
            const Text(
              'Location is optional and stays on this device. It is not used to calculate crane radius or soil bearing capacity.',
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : location,
              icon: const Icon(Icons.my_location),
              label: const Text('Capture optional device location'),
            ),
            field('Latitude'),
            field('Longitude'),
            Text('Location source: $locationSource'),
            const Text(
              'BLE and approved weather integrations are not configured in this build. Manual entry always remains available.',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: busy ? null : save,
              icon: const Icon(Icons.save),
              label: Text(busy ? 'Working...' : 'Save environment snapshot'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Explicit attachment freezes the selected snapshot instead of silently using
/// a later global reading or the environment from another project.
class EnvironmentAttachment extends StatelessWidget {
  final Map<String, Object?>? value;
  final String project;
  final ValueChanged<Map<String, Object?>?> onChanged;
  const EnvironmentAttachment({
    super.key,
    required this.value,
    required this.onChanged,
    this.project = '',
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Site environment attachment'),
          Text(
            value == null
                ? 'No snapshot attached. Verification required.'
                : '#${value!['recordId']} ${value!['site']}\nCaptured ${value!['capturedAt']}\nHistorical evidence; recheck current wind before lifting.',
          ),
          OutlinedButton(
            onPressed: () async {
              final snapshot = await Navigator.push<Map<String, Object?>>(
                context,
                MaterialPageRoute(
                  builder: (_) => WindCheckScreen(
                    returnSnapshot: true,
                    projectHint: project,
                  ),
                ),
              );
              if (snapshot != null) onChanged(snapshot);
            },
            child: const Text('Capture and attach environment'),
          ),
          if (value != null)
            TextButton(
              onPressed: () => onChanged(null),
              child: const Text('Remove attachment from this draft'),
            ),
        ],
      ),
    ),
  );
}
