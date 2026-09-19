import 'dart:math';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 1. SLING ANGLE CALCULATOR
/// Leg Load = Load / (Number of Legs x sin(angle))
class SlingAngleCalculator extends StatefulWidget {
  const SlingAngleCalculator({super.key});

  @override
  State<SlingAngleCalculator> createState() => _SlingAngleCalculatorState();
}

class _SlingAngleCalculatorState extends State<SlingAngleCalculator> {
  final _loadCtrl = TextEditingController();
  final _legsCtrl = TextEditingController(text: '2');
  final _angleCtrl = TextEditingController(text: '60');
  final _sfCtrl = TextEditingController(text: '5');

  double? _legLoad;
  double? _slingTension;
  double? _requiredWll;
  double? _requiredBreakingStrength;
  bool? _safe;

  void _calculate() {
    final load = double.tryParse(_loadCtrl.text);
    final legs = int.tryParse(_legsCtrl.text);
    final angleDeg = double.tryParse(_angleCtrl.text);
    final sf = double.tryParse(_sfCtrl.text) ?? 5;

    if (load == null || legs == null || legs <= 0 || angleDeg == null || angleDeg <= 0 || angleDeg > 90) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid load, legs and angle (0-90 deg).')),
      );
      return;
    }

    final angleRad = angleDeg * pi / 180;
    final legLoad = load / (legs * sin(angleRad));
    final requiredWll = legLoad; // the sling's WLL must be at or above the leg load
    final requiredBreakingStrength = legLoad * sf; // MBL the sling must be rated for at this SF
    final safe = angleDeg >= 30; // industry rule of thumb: avoid slings below 30 deg

    setState(() {
      _legLoad = legLoad;
      _slingTension = legLoad;
      _requiredWll = requiredWll;
      _requiredBreakingStrength = requiredBreakingStrength;
      _safe = safe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sling Angle Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _loadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Load Weight (t)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _legsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Sling Legs'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _angleCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Sling Angle from Horizontal (deg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sfCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Safety Factor'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE')),
            if (_legLoad != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'Load per Leg', value: '${_legLoad!.toStringAsFixed(2)} t'),
                      ResultRow(label: 'Sling Tension', value: '${_slingTension!.toStringAsFixed(2)} t'),
                      ResultRow(label: 'Required Sling WLL', value: '${_requiredWll!.toStringAsFixed(2)} t'),
                      ResultRow(label: 'Required Breaking Strength (with SF)', value: '${_requiredBreakingStrength!.toStringAsFixed(2)} t'),
                      const SizedBox(height: 12),
                      SafetyStatusBanner(isSafe: _safe ?? false),
                      if (!(_safe ?? true))
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Angle below 30° dramatically increases sling tension. Use longer slings or a spreader beam.',
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
