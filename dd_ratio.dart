import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 6. D/d RATIO CALCULATOR
/// D/d = Sheave (or Drum) Diameter / Rope Diameter
/// Minimum recommended D/d for general lifting service is typically 18:1 (often 20:1+ for critical lifts).
class DdRatioCalculator extends StatefulWidget {
  const DdRatioCalculator({super.key});

  @override
  State<DdRatioCalculator> createState() => _DdRatioCalculatorState();
}

class _DdRatioCalculatorState extends State<DdRatioCalculator> {
  final _sheaveCtrl = TextEditingController();
  final _ropeCtrl = TextEditingController();
  final _minRatioCtrl = TextEditingController(text: '18');

  double? _ratio;
  bool? _safe;

  void _calculate() {
    final sheave = double.tryParse(_sheaveCtrl.text);
    final rope = double.tryParse(_ropeCtrl.text);
    final minRatio = double.tryParse(_minRatioCtrl.text) ?? 18;

    if (sheave == null || rope == null || rope <= 0 || sheave <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid sheave and rope diameters.')),
      );
      return;
    }

    final ratio = sheave / rope;
    setState(() {
      _ratio = ratio;
      _safe = ratio >= minRatio;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('D/d Ratio Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _sheaveCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Sheave / Drum Diameter (mm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ropeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Rope Diameter (mm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minRatioCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Minimum Required D/d (default 18:1)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE')),
            if (_ratio != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'D/d Ratio', value: '${_ratio!.toStringAsFixed(2)} : 1'),
                      const SizedBox(height: 12),
                      SafetyStatusBanner(isSafe: _safe ?? false),
                      if (!(_safe ?? true))
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Low D/d ratio accelerates rope fatigue and reduces effective strength. Use a larger sheave or thinner rope.',
                            style: TextStyle(color: Colors.orangeAccent),
                          ),
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
