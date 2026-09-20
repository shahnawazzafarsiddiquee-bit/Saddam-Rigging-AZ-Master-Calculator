import 'package:flutter/material.dart';
import '../app/theme.dart';

/// CRANE PLANNING MODULE
/// Utilization % = Load / Rated Capacity at Radius x 100
/// A small built-in crane load-chart database is included so the user can
/// pick a crane/boom and let the app estimate rated capacity at a given
/// radius by linear interpolation between chart points.
class CranePlanningScreen extends StatefulWidget {
  const CranePlanningScreen({super.key});

  @override
  State<CranePlanningScreen> createState() => _CranePlanningScreenState();
}

class _CraneModel {
  final String name;
  final double boomLength; // m
  // radius (m) -> rated capacity (t) — simplified representative load chart
  final Map<double, double> chart;
  const _CraneModel(this.name, this.boomLength, this.chart);
}

final List<_CraneModel> _craneDatabase = [
  _CraneModel('Mobile Crane 50t', 30, {3: 50, 6: 28, 9: 18, 12: 12, 15: 8, 20: 5}),
  _CraneModel('Mobile Crane 100t', 40, {4: 100, 8: 55, 12: 35, 16: 24, 20: 17, 25: 11}),
  _CraneModel('Crawler Crane 250t', 55, {6: 250, 10: 160, 15: 100, 20: 68, 25: 48, 30: 34}),
  _CraneModel('All-Terrain Crane 500t', 70, {8: 500, 12: 340, 18: 210, 24: 140, 30: 95, 36: 65}),
];

class _CranePlanningScreenState extends State<CranePlanningScreen> {
  _CraneModel _crane = _craneDatabase.first;
  final _radiusCtrl = TextEditingController();
  final _loadCtrl = TextEditingController();

  double? _ratedCapacity;
  double? _utilization;
  bool? _safe;

  double _interpolate(Map<double, double> chart, double radius) {
    final radii = chart.keys.toList()..sort();
    if (radius <= radii.first) return chart[radii.first]!;
    if (radius >= radii.last) return chart[radii.last]!;

    for (int i = 0; i < radii.length - 1; i++) {
      final r1 = radii[i];
      final r2 = radii[i + 1];
      if (radius >= r1 && radius <= r2) {
        final c1 = chart[r1]!;
        final c2 = chart[r2]!;
        final t = (radius - r1) / (r2 - r1);
        return c1 + t * (c2 - c1);
      }
    }
    return chart[radii.last]!;
  }

  void _calculate() {
    final radius = double.tryParse(_radiusCtrl.text);
    final load = double.tryParse(_loadCtrl.text);

    if (radius == null || radius <= 0 || load == null || load <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid radius and load weight.')),
      );
      return;
    }

    final rated = _interpolate(_crane.chart, radius);
    final utilization = (load / rated) * 100;

    setState(() {
      _ratedCapacity = rated;
      _utilization = utilization;
      // Industry good practice: keep utilization at or below 75-85% of chart capacity.
      _safe = utilization <= 85;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crane Planning')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<_CraneModel>(
              value: _crane,
              decoration: const InputDecoration(labelText: 'Crane (from database)'),
              dropdownColor: const Color(0xFF2A2E33),
              items: _craneDatabase
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _crane = v ?? _crane),
            ),
            const SizedBox(height: 8),
            Text('Boom Length: ${_crane.boomLength.toStringAsFixed(0)} m',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: _radiusCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Working Radius (m)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total Load Weight incl. rigging (t)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE')),
            if (_ratedCapacity != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'Rated Capacity at Radius', value: '${_ratedCapacity!.toStringAsFixed(2)} t'),
                      ResultRow(label: 'Utilization', value: '${_utilization!.toStringAsFixed(1)} %'),
                      const SizedBox(height: 12),
                      SafetyStatusBanner(isSafe: _safe ?? false),
                      const SizedBox(height: 8),
                      const Text(
                        'This uses a simplified representative load chart for planning only. Always use the crane manufacturer\'s certified load chart for the actual lift.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
