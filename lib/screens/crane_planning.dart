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
  final double maxBoomLength; // m
  final double mainBoomCapacity; // t, rated capacity at shortest chart radius
  // radius (m) -> rated capacity (t) on main boom, no jib, full outriggers.
  final Map<double, double> chart;
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
    _CraneModel('LTM 1030-2.1 (35t)', 30, 35, {3: 35, 6: 18, 9: 11, 12: 7.5, 16: 5, 20: 3.2}),
    _CraneModel('LTM 1050-3.1 (50t)', 36, 50, {3: 50, 6: 26, 9: 16, 12: 11, 16: 7.5, 20: 5.2, 26: 3.2}),
    _CraneModel('LTM 1070-4.2 (70t)', 42, 70, {3: 70, 6: 40, 9: 26, 12: 18, 16: 12.5, 20: 9, 26: 6}),
    _CraneModel('LTM 1090-4.2 (90t)', 50, 90, {4: 90, 8: 48, 12: 30, 16: 21, 20: 15, 26: 10, 32: 6.5}),
    _CraneModel('LTM 1130-5.1 (130t)', 60, 130, {4: 130, 8: 78, 12: 52, 16: 37, 20: 27, 26: 18, 32: 12.5, 40: 8}),
    _CraneModel('LTM 1200-5.1 (200t)', 64, 200, {5: 200, 10: 110, 15: 68, 20: 46, 25: 33, 30: 24, 40: 14, 50: 8.5}),
    _CraneModel('LTM 1300-6.2 (300t)', 72, 300, {6: 300, 10: 190, 15: 120, 20: 82, 25: 60, 30: 45, 40: 27, 50: 17}),
    _CraneModel('LTM 1500-8.1 (500t)', 84, 500, {6: 500, 10: 320, 15: 210, 20: 150, 25: 112, 30: 86, 40: 54, 50: 35, 60: 22}),
    _CraneModel('LR 1300 Crawler (300t)', 84, 300, {6: 300, 10: 195, 15: 125, 20: 88, 25: 65, 30: 49, 40: 30, 50: 19}),
    _CraneModel('LR 1750 Crawler (750t)', 96, 750, {8: 750, 14: 460, 20: 300, 26: 210, 32: 155, 40: 105, 50: 68, 60: 44}),
  ]),
  _CraneManufacturer('Tadano', [
    _CraneModel('GR-250N Rough Terrain (25t)', 33, 25, {3: 25, 6: 13, 9: 8, 12: 5.5, 16: 3.6, 20: 2.3}),
    _CraneModel('GR-550EX Rough Terrain (55t)', 38, 55, {3: 55, 6: 30, 9: 19, 12: 13, 16: 8.8, 20: 6}),
    _CraneModel('ATF 70G-4 (70t)', 41, 70, {3: 70, 6: 39, 9: 25, 12: 17, 16: 11.5, 20: 8, 26: 5.2}),
    _CraneModel('ATF 90G-4 (90t)', 48, 90, {4: 90, 8: 47, 12: 29, 16: 20, 20: 14, 26: 9, 32: 5.8}),
    _CraneModel('ATF 130G-5 (130t)', 55, 130, {4: 130, 8: 76, 12: 50, 16: 35, 20: 25, 26: 17, 32: 11.5, 40: 7.2}),
    _CraneModel('ATF 220G-5 (220t)', 65, 220, {5: 220, 10: 118, 15: 74, 20: 50, 25: 36, 30: 26, 40: 15.5, 50: 9.5}),
    _CraneModel('AC 5.220-1 (220t)', 65, 220, {5: 220, 10: 116, 15: 72, 20: 49, 25: 35, 30: 25.5, 40: 15, 50: 9}),
    _CraneModel('GT-550E Truck Crane (55t)', 38, 55, {3: 55, 6: 29, 9: 18.5, 12: 12.5, 16: 8.4, 20: 5.7}),
  ]),
  _CraneManufacturer('Grove (Manitowoc)', [
    _CraneModel('RT540E Rough Terrain (40t)', 32, 40, {3: 40, 6: 21, 9: 13.5, 12: 9, 16: 6, 20: 3.9}),
    _CraneModel('GMK3050-2 (50t)', 36, 50, {3: 50, 6: 27, 9: 16.5, 12: 11.5, 16: 7.7, 20: 5.3}),
    _CraneModel('GMK4100L-1 (100t)', 52, 100, {4: 100, 8: 53, 12: 33, 16: 23, 20: 16.5, 26: 10.8, 32: 7}),
    _CraneModel('GMK5150L (150t)', 60, 150, {4: 150, 8: 88, 12: 58, 16: 41, 20: 30, 26: 20, 32: 13.5, 40: 8.5}),
    _CraneModel('GMK5220 (220t)', 64, 220, {5: 220, 10: 119, 15: 75, 20: 51, 25: 37, 30: 27, 40: 16, 50: 9.8}),
    _CraneModel('GMK6300L-1 (300t)', 72, 300, {6: 300, 10: 192, 15: 122, 20: 84, 25: 62, 30: 46, 40: 28, 50: 17.5}),
    _CraneModel('GMK7550 (550t)', 82, 550, {6: 550, 10: 350, 15: 232, 20: 165, 25: 123, 30: 94, 40: 59, 50: 38, 60: 24}),
  ]),
  _CraneManufacturer('Terex', [
    _CraneModel('RT 90 Rough Terrain (90t)', 39, 90, {3: 90, 6: 49, 9: 32, 12: 22, 16: 15, 20: 10.5}),
    _CraneModel('AC 40-1 City (40t)', 31, 40, {3: 40, 6: 22, 9: 14, 12: 9.5, 16: 6.3, 20: 4.2}),
    _CraneModel('AC 100-4L (100t)', 50, 100, {4: 100, 8: 54, 12: 34, 16: 24, 20: 17, 26: 11, 32: 7.1}),
    _CraneModel('AC 250-5 (250t)', 68, 250, {5: 250, 10: 134, 15: 84, 20: 57, 25: 41, 30: 30, 40: 17.5, 50: 10.8}),
    _CraneModel('CC 2800-1 Crawler (600t)', 100, 600, {8: 600, 14: 368, 20: 240, 26: 168, 32: 124, 40: 84, 50: 55, 60: 35}),
  ]),
  _CraneManufacturer('XCMG', [
    _CraneModel('QY25K5 (25t)', 33, 25, {3: 25, 6: 13.2, 9: 8.2, 12: 5.6, 16: 3.7, 20: 2.4}),
    _CraneModel('QY50KA (50t)', 40, 50, {3: 50, 6: 26.5, 9: 16, 12: 11, 16: 7.4, 20: 5}),
    _CraneModel('QY100K (100t)', 48, 100, {4: 100, 8: 52, 12: 32.5, 16: 22.5, 20: 16, 26: 10.4, 32: 6.7}),
    _CraneModel('XCA220 (220t)', 64, 220, {5: 220, 10: 117, 15: 73, 20: 49.5, 25: 35.5, 30: 25.8, 40: 15.2, 50: 9.3}),
    _CraneModel('XCA1600 Crawler (160t)', 66, 160, {5: 160, 10: 92, 15: 60, 20: 42, 25: 30.5, 30: 22, 40: 13}),
  ]),
  _CraneManufacturer('Sany', [
    _CraneModel('STC250 Truck Crane (25t)', 34, 25, {3: 25, 6: 13, 9: 8, 12: 5.5, 16: 3.6, 20: 2.3}),
    _CraneModel('SAC2500 All-Terrain (250t)', 68, 250, {5: 250, 10: 135, 15: 85, 20: 58, 25: 42, 30: 31, 40: 18, 50: 11}),
    _CraneModel('SCC4000A Crawler (400t)', 96, 400, {8: 400, 14: 246, 20: 160, 26: 112, 32: 83, 40: 56, 50: 36, 60: 23}),
  ]),
  _CraneManufacturer('Kobelco', [
    _CraneModel('CK1000G Crawler (100t)', 60, 100, {4: 100, 8: 62, 12: 41, 16: 29, 20: 21, 26: 14, 32: 9.5}),
    _CraneModel('CKE2500-2 Crawler (250t)', 70, 250, {5: 250, 10: 136, 15: 86, 20: 59, 25: 43, 30: 31.5, 40: 18.5, 50: 11.4}),
    _CraneModel('SL6000 Crawler (600t)', 100, 600, {8: 600, 14: 370, 20: 242, 26: 170, 32: 126, 40: 85, 50: 56, 60: 36}),
  ]),
];

class _CranePlanningScreenState extends State<CranePlanningScreen> {
  late _CraneManufacturer _manufacturer;
  late _CraneModel _crane;
  final _radiusCtrl = TextEditingController();
  final _loadCtrl = TextEditingController();

  double? _ratedCapacity;
  double? _utilization;
  bool? _safe;

  @override
  void initState() {
    super.initState();
    _manufacturer = _craneDatabase.first;
    _crane = _manufacturer.models.first;
  }

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
      // Industry good practice: keep utilization at or below 85% of chart capacity.
      _safe = utilization <= 85;
    });
  }

  void _showFullChart() {
    final radii = _crane.chart.keys.toList()..sort();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardGrey,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_crane.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Max Boom Length: ${_crane.maxBoomLength.toStringAsFixed(0)} m',
                style: const TextStyle(color: Colors.white70)),
            const Divider(height: 24),
            Row(
              children: const [
                Expanded(child: Text('Radius (m)', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Rated Capacity (t)', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 8),
            for (final r in radii)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(r.toStringAsFixed(0))),
                    Expanded(child: Text(_crane.chart[r]!.toStringAsFixed(2))),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Representative chart for planning only — always confirm with the '
              'manufacturer\'s certified load chart for the actual unit before lifting.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
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
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _manufacturer = v;
                  _crane = v.models.first;
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
              onChanged: (v) => setState(() {
                _crane = v ?? _crane;
                _ratedCapacity = null;
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'Max Boom Length: ${_crane.maxBoomLength.toStringAsFixed(0)} m  •  '
              'Max Rated Capacity: ${_crane.mainBoomCapacity.toStringAsFixed(0)} t',
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
