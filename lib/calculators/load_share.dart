import '../services/calculation_engine.dart';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 2. LOAD SHARE CALCULATOR — 2/3/4 leg slings with angle correction factor.
class LoadShareCalculator extends StatefulWidget {
  const LoadShareCalculator({super.key});

  @override
  State<LoadShareCalculator> createState() => _LoadShareCalculatorState();
}

class _LoadShareCalculatorState extends State<LoadShareCalculator> {
  final _loadCtrl = TextEditingController();
  final _angleCtrl = TextEditingController(text: '60');
  int _legs = 2;
  final _sfCtrl = TextEditingController(text: '5');

  List<double>? _legLoads;
  double? _angleFactor;

  void _calculate() {
    final load = double.tryParse(_loadCtrl.text);
    final angleDeg = double.tryParse(_angleCtrl.text);
    final sf = double.tryParse(_sfCtrl.text) ?? 5;

    if (load == null ||
        !load.isFinite ||
        load <= 0 ||
        angleDeg == null ||
        !angleDeg.isFinite ||
        angleDeg <= 0 ||
        angleDeg > 90 ||
        !sf.isFinite ||
        sf <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid load and angle (0-90 deg).'),
        ),
      );
      return;
    }

    final result = CalculationEngine.sling(
      loadKg: load * 1000,
      effectiveLegs: 2,
      angleDegrees: angleDeg,
    );
    final angleFactor = result.values['angleFactor']!;
    final legLoads = List.filled(_legs, result.values['requiredWllKg']! / 1000);

    setState(() {
      _legLoads = legLoads;
      _angleFactor = angleFactor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Load Share Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _loadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Total Load (t)'),
            ),
            const SizedBox(height: 12),
            const Text('Sling Configuration'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2 Leg')),
                ButtonSegment(value: 3, label: Text('3 Leg')),
                ButtonSegment(value: 4, label: Text('4 Leg')),
              ],
              selected: {_legs},
              onSelectionChanged: (s) => setState(() => _legs = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _angleCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Sling Angle from Horizontal (deg)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sfCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Safety Factor'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE'),
            ),
            if (_legLoads != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'Angle Correction Factor', value: _angleFactor!.toStringAsFixed(3),
                      ),
                      for (int i = 0; i < _legLoads!.length; i++)
                        ResultRow(label: 'Leg ${i + 1} Load', value: '${_legLoads![i].toStringAsFixed(2)} t',
                        ),
                      const SizedBox(height: 12),
                      SafetyStatusBanner(isSafe: false,
                        unsafeText: 'INCOMPLETE',
                      ),
                      const Text(
                        'Preliminary envelope using two effective supporting legs. This does not establish the actual load on every installed leg. Verify CG, geometry and configuration WLL.',
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
