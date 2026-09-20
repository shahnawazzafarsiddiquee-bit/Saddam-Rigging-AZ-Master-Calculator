import 'dart:math';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 5. WIRE ROPE CALCULATOR
/// Approximate Breaking Strength (tonnes) = K x d^2 (d in mm),
/// where K depends on construction/grade. WLL = Breaking Strength / SF.
class WireRopeCalculator extends StatefulWidget {
  const WireRopeCalculator({super.key});

  @override
  State<WireRopeCalculator> createState() => _WireRopeCalculatorState();
}

class _Construction {
  final String label;
  final double k; // empirical breaking-strength coefficient
  const _Construction(this.label, this.k);
}

const List<_Construction> _constructions = [
  _Construction('6x19 Fibre Core (FC)', 0.034),
  _Construction('6x19 Independent Wire Rope Core (IWRC)', 0.037),
  _Construction('6x36 IWRC', 0.038),
  _Construction('8x19 IWRC (rotation resistant)', 0.033),
  _Construction('Compacted / Dyform IWRC', 0.042),
];

class _WireRopeCalculatorState extends State<WireRopeCalculator> {
  final _diameterCtrl = TextEditingController();
  _Construction _construction = _constructions[1];
  final _sfCtrl = TextEditingController(text: '5');
  final _appliedLoadCtrl = TextEditingController();

  double? _breakingStrength;
  double? _wll;
  bool? _safe;

  void _calculate() {
    final d = double.tryParse(_diameterCtrl.text);
    final sf = double.tryParse(_sfCtrl.text) ?? 5;
    final appliedLoad = double.tryParse(_appliedLoadCtrl.text);

    if (d == null || d <= 0 || sf <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid rope diameter.')),
      );
      return;
    }

    final breaking = _construction.k * pow(d, 2);
    final wll = breaking / sf;
    final safe = appliedLoad == null ? true : appliedLoad <= wll;

    setState(() {
      _breakingStrength = breaking.toDouble();
      _wll = wll.toDouble();
      _safe = safe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wire Rope Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _diameterCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Rope Diameter (mm)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_Construction>(
              value: _construction,
              decoration: const InputDecoration(labelText: 'Construction / Grade'),
              dropdownColor: const Color(0xFF2A2E33),
              items: _constructions
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _construction = v ?? _construction),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sfCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Design Safety Factor (default 5:1)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _appliedLoadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Applied Load (t) — optional, for SAFE check'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE')),
            if (_breakingStrength != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'Approx. Breaking Strength', value: '${_breakingStrength!.toStringAsFixed(2)} t'),
                      ResultRow(label: 'Working Load Limit (WLL)', value: '${_wll!.toStringAsFixed(2)} t'),
                      const SizedBox(height: 12),
                      SafetyStatusBanner(isSafe: _safe ?? true),
                      const SizedBox(height: 8),
                      const Text(
                        'Coefficients are typical catalogue approximations — always confirm against the manufacturer\'s certified breaking load.',
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
