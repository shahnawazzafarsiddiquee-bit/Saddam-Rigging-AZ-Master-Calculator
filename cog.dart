import 'package:flutter/material.dart';
import '../app/theme.dart';

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
}

class _CogCalculatorState extends State<CogCalculator> {
  final List<_PointLoad> _points = [_PointLoad(), _PointLoad()];

  double? _cogX;
  double? _cogY;
  double? _totalWeight;

  void _addPoint() {
    if (_points.length < 6) setState(() => _points.add(_PointLoad()));
  }

  void _removePoint(int i) {
    if (_points.length > 2) setState(() => _points.removeAt(i));
  }

  void _calculate() {
    double totalWeight = 0;
    double sumWx = 0;
    double sumWy = 0;
    bool valid = true;

    for (final p in _points) {
      final w = double.tryParse(p.weight.text);
      final x = double.tryParse(p.x.text);
      final y = double.tryParse(p.y.text);
      if (w == null || x == null || y == null) {
        valid = false;
        break;
      }
      totalWeight += w;
      sumWx += w * x;
      sumWy += w * y;
    }

    if (!valid || totalWeight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in weight, X and Y for every point load.')),
      );
      return;
    }

    setState(() {
      _totalWeight = totalWeight;
      _cogX = sumWx / totalWeight;
      _cogY = sumWy / totalWeight;
    });
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
              'Enter each significant weight component with its X/Y position (m) measured from a common datum point (e.g. one corner of the load).',
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
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE')),
            if (_cogX != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'Total Weight', value: '${_totalWeight!.toStringAsFixed(2)} t'),
                      ResultRow(label: 'COG — X from datum', value: '${_cogX!.toStringAsFixed(3)} m'),
                      ResultRow(label: 'COG — Y from datum', value: '${_cogY!.toStringAsFixed(3)} m'),
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
                Text('Point ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_points.length > 2)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _removePoint(i),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: p.weight,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Weight (t)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: p.x,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'X (m)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: p.y,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Y (m)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
