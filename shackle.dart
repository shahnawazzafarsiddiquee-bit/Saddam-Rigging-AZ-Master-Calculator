import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 4. SHACKLE CALCULATOR
/// Required shackle WLL = (Load per leg) x Safety Factor margin,
/// then rounded up to the nearest standard shackle size.
class ShackleCalculator extends StatefulWidget {
  const ShackleCalculator({super.key});

  @override
  State<ShackleCalculator> createState() => _ShackleCalculatorState();
}

// Standard metric bow shackle WLL sizes (tonnes) — common rigging catalogue values.
const List<double> _standardShackleSizes = [
  0.5, 0.75, 1, 1.5, 2, 3.25, 4.75, 6.5, 8.5, 9.5, 12, 13.5, 17, 25, 35, 55, 75, 85, 120, 150
];

class _ShackleCalculatorState extends State<ShackleCalculator> {
  final _loadCtrl = TextEditingController();
  int _legs = 1;
  final _sfCtrl = TextEditingController(text: '1.25');

  double? _requiredCapacity;
  double? _recommendedSize;

  void _calculate() {
    final load = double.tryParse(_loadCtrl.text);
    final sf = double.tryParse(_sfCtrl.text) ?? 1.25;

    if (load == null || load <= 0 || _legs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid load.')),
      );
      return;
    }

    final loadPerShackle = load / _legs;
    final required = loadPerShackle * sf;
    final recommended = _standardShackleSizes.firstWhere(
      (s) => s >= required,
      orElse: () => _standardShackleSizes.last,
    );

    setState(() {
      _requiredCapacity = required;
      _recommendedSize = recommended;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shackle Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _loadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Load per Sling Arrangement (t)'),
            ),
            const SizedBox(height: 12),
            const Text('Number of Shackles Sharing the Load'),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
              ],
              selected: {_legs},
              onSelectionChanged: (s) => setState(() => _legs = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sfCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Safety Margin Factor (default 1.25)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE')),
            if (_requiredCapacity != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'Required Shackle Capacity', value: '${_requiredCapacity!.toStringAsFixed(2)} t'),
                      ResultRow(label: 'Recommended Standard Size', value: '${_recommendedSize!.toStringAsFixed(2)} t WLL'),
                      const SizedBox(height: 8),
                      const Text(
                        'Always confirm the pin diameter matches the sling eye and check manufacturer markings before use.',
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
}
