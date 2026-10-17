import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/calculation_engine.dart';

/// 7. CENTER OF GRAVITY (COG) CALCULATOR
/// Computes the combined COG of up to 4 point loads on a 2D plan (x, y in metres from a datum),
/// then recommends symmetric lifting-point offsets.
class CogCalculator extends StatefulWidget {
  const CogCalculator({super.key});

  @override
  State<CogCalculator> createState() => _CogCalculatorState();
}

class _PointLoad {
  final TextEditingController weight = TextEditingController();
  final TextEditingController x = TextEditingController();
  final TextEditingController y = TextEditingController();
  final TextEditingController z = TextEditingController(text: '0');
  void dispose() {
    weight.dispose();
    x.dispose();
    y.dispose();
    z.dispose();
  }
}

class _CogCalculatorState extends State<CogCalculator> {
  final List<_PointLoad> _points = [_PointLoad(), _PointLoad()];

  double? _cogX;
  double? _cogY;
  double? _cogZ;
  double? _totalWeight;

  void _addPoint() {
    if (_points.length < 6) setState(() => _points.add(_PointLoad()));
  }

  void _removePoint(int i) {
    if (_points.length > 2) setState(() {
        _points.removeAt(i).dispose();
        _cogX = null;
      });
  }

  @override
  void dispose() {
    for (final point in _points) {
      point.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    try {
      final points = <MassPoint>[];
      for (final p in _points) {
        final values = [
          p.weight,
          p.x,
          p.y,
          p.z,
        ].map((c) => double.tryParse(c.text)).toList();
        if (values.any((v) => v == null))
          throw ArgumentError('Fill weight and X/Y/Z for every point.');
        points.add(
          MassPoint(values[0]! * 1000, values[1]!, values[2]!, values[3]!),
        );
      }
      final result = CalculationEngine.centerOfMass(points);
      setState(() {
        _totalWeight = result.values['massKg']! / 1000;
        _cogX = result.values['xM'];
        _cogY = result.values['yM'];
        _cogZ = result.values['zM'];
      });
    } on ArgumentError catch (e) {
      setState(() => _cogX = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Center of Gravity Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter each significant weight component with its X/Y/Z position (m) measured from a common datum point (e.g. one corner of the load).',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < _points.length; i++) _buildPointCard(i),
            OutlinedButton.icon(
              onPressed: _addPoint,
              icon: const Icon(Icons.add),
              label: const Text('ADD WEIGHT POINT'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE'),
            ),
            if (_cogX != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'Total Weight', value: '${_totalWeight!.toStringAsFixed(2)} t',
                      ),
                      ResultRow(
                        label: 'COG — X from datum',
                        value: '${_cogX!.toStringAsFixed(3)} m',
                      ),
                      ResultRow(
                        label: 'COG — Y from datum',
                        value: '${_cogY!.toStringAsFixed(3)} m',
                      ),
                      ResultRow(
                        label: 'COG — Z from datum',
                        value: '${_cogZ!.toStringAsFixed(3)} m',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Recommendation: position lifting points symmetrically about the calculated COG and verify by trial-lift a few centimetres off the ground.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
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

  Widget _buildPointCard(int i) {
    final p = _points[i];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Point ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_points.length > 2)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent,
                    ),
                    onPressed: () => _removePoint(i),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: p.weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Weight (t)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: p.x,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'X (m)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: p.y,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Y (m)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: p.z,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Z (m, same datum)'),
            ),
          ],
        ),
      ),
    );
  }
}
