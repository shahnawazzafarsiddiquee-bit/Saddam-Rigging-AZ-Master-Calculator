import 'package:flutter/material.dart';
import '../app/theme.dart';

/// CRANE PLANNING MODULE
///
/// Utilization % = Load / Rated Capacity at Radius x 100
///
/// A large built-in crane load-chart database (mobile, all-terrain and
/// crawler cranes from major manufacturers) is included so the user can
/// pick Manufacturer -> Model and let the app estimate rated capacity at a
/// given radius by linear interpolation between chart points — no need to
/// search anywhere else on site.
///
/// Chart keys are plain integers (radius in metres) rather than doubles,
/// because Dart's constant evaluator requires map keys to have "primitive
/// equality" and double does not qualify — using int keys keeps this whole
/// database a compile-time const, which is faster and safer.
///
/// IMPORTANT: these charts are representative/approximate values for
/// planning purposes only. Always verify the actual lift against the
/// crane manufacturer's certified load chart for that specific unit,
/// configuration and counterweight before lifting.
class CranePlanningScreen extends StatefulWidget {
  const CranePlanningScreen({super.key});

  @override
  State<CranePlanningScreen> createState() => _CranePlanningScreenState();
}

class _CraneModel {
  final String name;
  final int maxBoomLength; // m
  final int mainBoomCapacity; // t, rated capacity at shortest chart radius
  // radius (m, int) -> rated capacity (t, double) on main boom, no jib, full outriggers.
  final Map<int, double> chart;
  const _CraneModel(this.name, this.maxBoomLength, this.mainBoomCapacity, this.chart);
}

class _CraneManufacturer {
  final String name;
  final List<_CraneModel> models;
  const _CraneManufacturer(this.name, this.models);
}

// ---------------------------------------------------------------------------
// BUILT-IN CRANE LOAD CHART DATABASE
// ---------------------------------------------------------------------------
const List<_CraneManufacturer> _craneDatabase = [
  _CraneManufacturer('Liebherr', [
    _CraneModel('LTM 1030-2.1 (35t)', 30, 35, {3: 35.0, 6: 18.0, 9: 11.0, 12: 7.5, 16: 5.0, 20: 3.2}),
    _CraneModel('LTM 1050-3.1 (50t)', 36, 50, {3: 50.0, 6: 26.0, 9: 16.0, 12: 11.0, 16: 7.5, 20: 5.2, 26: 3.2}),
    _CraneModel('LTM 1070-4.2 (70t)', 42, 70, {3: 70.0, 6: 40.0, 9: 26.0, 12: 18.0, 16: 12.5, 20: 9.0, 26: 6.0}),
    _CraneModel('LTM 1090-4.2 (90t)', 50, 90, {4: 90.0, 8: 48.0, 12: 30.0, 16: 21.0, 20: 15.0, 26: 10.0, 32: 6.5}),
    _CraneModel('LTM 1130-5.1 (130t)', 60, 130, {4: 130.0, 8: 78.0, 12: 52.0, 16: 37.0, 20: 27.0, 26: 18.0, 32: 12.5, 40: 8.0}),
    _CraneModel('LTM 1200-5.1 (200t)', 64, 200, {5: 200.0, 10: 110.0, 15: 68.0, 20: 46.0, 25: 33.0, 30: 24.0, 40: 14.0, 50: 8.5}),
    _CraneModel('LTM 1300-6.2 (300t)', 72, 300, {6: 300.0, 10: 190.0, 15: 120.0, 20: 82.0, 25: 60.0, 30: 45.0, 40: 27.0, 50: 17.0}),
    _CraneModel('LTM 1500-8.1 (500t)', 84, 500, {6: 500.0, 10: 320.0, 15: 210.0, 20: 150.0, 25: 112.0, 30: 86.0, 40: 54.0, 50: 35.0, 60: 22.0}),
    _CraneModel('LR 1300 Crawler (300t)', 84, 300, {6: 300.0, 10: 195.0, 15: 125.0, 20: 88.0, 25: 65.0, 30: 49.0, 40: 30.0, 50: 19.0}),
    _CraneModel('LR 1750 Crawler (750t)', 96, 750, {8: 750.0, 14: 460.0, 20: 300.0, 26: 210.0, 32: 155.0, 40: 105.0, 50: 68.0, 60: 44.0}),
  ]),
  _CraneManufacturer('Tadano', [
    _CraneModel('GR-250N Rough Terrain (25t)', 33, 25, {3: 25.0, 6: 13.0, 9: 8.0, 12: 5.5, 16: 3.6, 20: 2.3}),
    _CraneModel('GR-550EX Rough Terrain (55t)', 38, 55, {3: 55.0, 6: 30.0, 9: 19.0, 12: 13.0, 16: 8.8, 20: 6.0}),
    _CraneModel('ATF 70G-4 (70t)', 41, 70, {3: 70.0, 6: 39.0, 9: 25.0, 12: 17.0, 16: 11.5, 20: 8.0, 26: 5.2}),
    _CraneModel('ATF 90G-4 (90t)', 48, 90, {4: 90.0, 8: 47.0, 12: 29.0, 16: 20.0, 20: 14.0, 26: 9.0, 32: 5.8}),
    _CraneModel('ATF 130G-5 (130t)', 55, 130, {4: 130.0, 8: 76.0, 12: 50.0, 16: 35.0, 20: 25.0, 26: 17.0, 32: 11.5, 40: 7.2}),
    _CraneModel('ATF 220G-5 (220t)', 65, 220, {5: 220.0, 10: 118.0, 15: 74.0, 20: 50.0, 25: 36.0, 30: 26.0, 40: 15.5, 50: 9.5}),
    _CraneModel('AC 5.220-1 (220t)', 65, 220, {5: 220.0, 10: 116.0, 15: 72.0, 20: 49.0, 25: 35.0, 30: 25.5, 40: 15.0, 50: 9.0}),
    _CraneModel('GT-550E Truck Crane (55t)', 38, 55, {3: 55.0, 6: 29.0, 9: 18.5, 12: 12.5, 16: 8.4, 20: 5.7}),
  ]),
  _CraneManufacturer('Grove (Manitowoc)', [
    _CraneModel('RT540E Rough Terrain (40t)', 32, 40, {3: 40.0, 6: 21.0, 9: 13.5, 12: 9.0, 16: 6.0, 20: 3.9}),
    _CraneModel('GMK3050-2 (50t)', 36, 50, {3: 50.0, 6: 27.0, 9: 16.5, 12: 11.5, 16: 7.7, 20: 5.3}),
    _CraneModel('GMK4100L-1 (100t)', 52, 100, {4: 100.0, 8: 53.0, 12: 33.0, 16: 23.0, 20: 16.5, 26: 10.8, 32: 7.0}),
    _CraneModel('GMK5150L (150t)', 60, 150, {4: 150.0, 8: 88.0, 12: 58.0, 16: 41.0, 20: 30.0, 26: 20.0, 32: 13.5, 40: 8.5}),
    _CraneModel('GMK5220 (220t)', 64, 220, {5: 220.0, 10: 119.0, 15: 75.0, 20: 51.0, 25: 37.0, 30: 27.0, 40: 16.0, 50: 9.8}),
    _CraneModel('GMK6300L-1 (300t)', 72, 300, {6: 300.0, 10: 192.0, 15: 122.0, 20: 84.0, 25: 62.0, 30: 46.0, 40: 28.0, 50: 17.5}),
    _CraneModel('GMK7550 (550t)', 82, 550, {6: 550.0, 10: 350.0, 15: 232.0, 20: 165.0, 25: 123.0, 30: 94.0, 40: 59.0, 50: 38.0, 60: 24.0}),
  ]),
  _CraneManufacturer('Terex', [
    _CraneModel('RT 90 Rough Terrain (90t)', 39, 90, {3: 90.0, 6: 49.0, 9: 32.0, 12: 22.0, 16: 15.0, 20: 10.5}),
    _CraneModel('AC 40-1 City (40t)', 31, 40, {3: 40.0, 6: 22.0, 9: 14.0, 12: 9.5, 16: 6.3, 20: 4.2}),
    _CraneModel('AC 100-4L (100t)', 50, 100, {4: 100.0, 8: 54.0, 12: 34.0, 16: 24.0, 20: 17.0, 26: 11.0, 32: 7.1}),
    _CraneModel('AC 250-5 (250t)', 68, 250, {5: 250.0, 10: 134.0, 15: 84.0, 20: 57.0, 25: 41.0, 30: 30.0, 40: 17.5, 50: 10.8}),
    _CraneModel('CC 2800-1 Crawler (600t)', 100, 600, {8: 600.0, 14: 368.0, 20: 240.0, 26: 168.0, 32: 124.0, 40: 84.0, 50: 55.0, 60: 35.0}),
  ]),
  _CraneManufacturer('XCMG', [
    _CraneModel('QY25K5 (25t)', 33, 25, {3: 25.0, 6: 13.2, 9: 8.2, 12: 5.6, 16: 3.7, 20: 2.4}),
    _CraneModel('QY50KA (50t)', 40, 50, {3: 50.0, 6: 26.5, 9: 16.0, 12: 11.0, 16: 7.4, 20: 5.0}),
    _CraneModel('QY100K (100t)', 48, 100, {4: 100.0, 8: 52.0, 12: 32.5, 16: 22.5, 20: 16.0, 26: 10.4, 32: 6.7}),
    _CraneModel('XCA220 (220t)', 64, 220, {5: 220.0, 10: 117.0, 15: 73.0, 20: 49.5, 25: 35.5, 30: 25.8, 40: 15.2, 50: 9.3}),
    _CraneModel('XCA1600 Crawler (160t)', 66, 160, {5: 160.0, 10: 92.0, 15: 60.0, 20: 42.0, 25: 30.5, 30: 22.0, 40: 13.0}),
  ]),
  _CraneManufacturer('Sany', [
    _CraneModel('STC250 Truck Crane (25t)', 34, 25, {3: 25.0, 6: 13.0, 9: 8.0, 12: 5.5, 16: 3.6, 20: 2.3}),
    _CraneModel('SAC2500 All-Terrain (250t)', 68, 250, {5: 250.0, 10: 135.0, 15: 85.0, 20: 58.0, 25: 42.0, 30: 31.0, 40: 18.0, 50: 11.0}),
    _CraneModel('SCC4000A Crawler (400t)', 96, 400, {8: 400.0, 14: 246.0, 20: 160.0, 26: 112.0, 32: 83.0, 40: 56.0, 50: 36.0, 60: 23.0}),
  ]),
  _CraneManufacturer('Kobelco', [
    _CraneModel('CK1000G Crawler (100t)', 60, 100, {4: 100.0, 8: 62.0, 12: 41.0, 16: 29.0, 20: 21.0, 26: 14.0, 32: 9.5}),
    _CraneModel('CKE2500-2 Crawler (250t)', 70, 250, {5: 250.0, 10: 136.0, 15: 86.0, 20: 59.0, 25: 43.0, 30: 31.5, 40: 18.5, 50: 11.4}),
    _CraneModel('SL6000 Crawler (600t)', 100, 600, {8: 600.0, 14: 370.0, 20: 242.0, 26: 170.0, 32: 126.0, 40: 85.0, 50: 56.0, 60: 36.0}),
  ]),
];

class _CranePlanningScreenState extends State<CranePlanningScreen> {
  late _CraneManufacturer _manufacturer;
  late _CraneModel _crane;
  final TextEditingController _radiusCtrl = TextEditingController();
  final TextEditingController _loadCtrl = TextEditingController();

  double? _ratedCapacity;
  double? _utilization;
  bool? _safe;

  @override
  void initState() {
    super.initState();
    _manufacturer = _craneDatabase.first;
    _crane = _manufacturer.models.first;
  }

  @override
  void dispose() {
    _radiusCtrl.dispose();
    _loadCtrl.dispose();
    super.dispose();
  }

  /// Linear interpolation between the two chart points that bracket
  /// [radius]. Values outside the chart's range clamp to the nearest edge.
  double _interpolate(Map<int, double> chart, double radius) {
    final List<int> radii = chart.keys.toList()..sort();

    if (radius <= radii.first) return chart[radii.first]!;
    if (radius >= radii.last) return chart[radii.last]!;

    for (int i = 0; i < radii.length - 1; i++) {
      final int r1 = radii[i];
      final int r2 = radii[i + 1];
      if (radius >= r1 && radius <= r2) {
        final double c1 = chart[r1]!;
        final double c2 = chart[r2]!;
        final double t = (radius - r1) / (r2 - r1);
        return c1 + t * (c2 - c1);
      }
    }
    return chart[radii.last]!;
  }

  void _calculate() {
    FocusScope.of(context).unfocus();

    final double? radius = double.tryParse(_radiusCtrl.text.trim());
    final double? load = double.tryParse(_loadCtrl.text.trim());

    if (radius == null || radius <= 0 || load == null || load <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid radius and load weight.')),
      );
      return;
    }

    final double rated = _interpolate(_crane.chart, radius);
    final double utilization = (load / rated) * 100;

    setState(() {
      _ratedCapacity = rated;
      _utilization = utilization;
      // Industry good practice: keep utilization at or below 85% of chart capacity.
      _safe = utilization <= 85;
    });
  }

  void _showFullChart() {
    final List<int> radii = _crane.chart.keys.toList()..sort();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardGrey,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_crane.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                'Max Boom Length: ${_crane.maxBoomLength} m',
                style: const TextStyle(color: Colors.white70),
              ),
              const Divider(height: 24),
              const Row(
                children: [
                  Expanded(child: Text('Radius (m)', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Rated Capacity (t)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 8),
              ...radii.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('$r')),
                      Expanded(child: Text(_crane.chart[r]!.toStringAsFixed(2))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Representative chart for planning only — always confirm with the '
                "manufacturer's certified load chart for the actual unit before lifting.",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crane Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'View full load chart',
            onPressed: _showFullChart,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<_CraneManufacturer>(
              value: _manufacturer,
              decoration: const InputDecoration(labelText: 'Manufacturer'),
              dropdownColor: const Color(0xFF2A2E33),
              items: _craneDatabase
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _manufacturer = value;
                  _crane = value.models.first;
                  _ratedCapacity = null;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_CraneModel>(
              value: _crane,
              decoration: const InputDecoration(labelText: 'Crane Model'),
              dropdownColor: const Color(0xFF2A2E33),
              isExpanded: true,
              items: _manufacturer.models
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _crane = value ?? _crane;
                  _ratedCapacity = null;
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Max Boom Length: ${_crane.maxBoomLength} m  •  '
              'Max Rated Capacity: ${_crane.mainBoomCapacity} t',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: _showFullChart,
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('View Full Load Chart for this Crane'),
            ),
            const SizedBox(height: 8),
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
                      ResultRow(label: 'Crane', value: _crane.name),
                      ResultRow(label: 'Rated Capacity at Radius', value: '${_ratedCapacity!.toStringAsFixed(2)} t'),
                      ResultRow(label: 'Utilization', value: '${_utilization!.toStringAsFixed(1)} %'),
                      const SizedBox(height: 12),
                      SafetyStatusBanner(isSafe: _safe ?? false),
                      const SizedBox(height: 8),
                      const Text(
                        'This uses a simplified representative load chart for planning only. '
                        "Always use the crane manufacturer's certified load chart for the actual lift.",
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
