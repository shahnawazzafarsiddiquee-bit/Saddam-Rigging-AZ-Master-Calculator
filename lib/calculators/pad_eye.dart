import 'dart:math';
import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 8. PAD EYE CHECK
/// Checks tensile (plate) stress and bearing (hole) stress against the
/// material's allowable stress, for a padeye of given plate thickness and
/// hole diameter, under an applied load at a given sling angle.
class PadEyeCalculator extends StatefulWidget {
  const PadEyeCalculator({super.key});

  @override
  State<PadEyeCalculator> createState() => _PadEyeCalculatorState();
}

class _PadEyeCalculatorState extends State<PadEyeCalculator> {
  final _loadCtrl = TextEditingController();
  final _thicknessCtrl = TextEditingController(); // mm
  final _holeDiaCtrl = TextEditingController(); // mm
  final _plateWidthCtrl = TextEditingController(); // mm, width of plate at pin (cheek plate width beyond hole x2)
  final _yieldCtrl = TextEditingController(text: '250'); // MPa, e.g. mild steel S275 ~ 275, use 250 conservative
  final _sfCtrl = TextEditingController(text: '3');

  double? _bearingStressMpa;
  double? _tensileStressMpa;
  double? _allowableStressMpa;
  bool? _safe;

  void _calculate() {
    final loadT = double.tryParse(_loadCtrl.text); // tonnes
    final thickness = double.tryParse(_thicknessCtrl.text); // mm
    final holeDia = double.tryParse(_holeDiaCtrl.text); // mm
    final plateWidth = double.tryParse(_plateWidthCtrl.text); // mm (net width beyond hole, both sides combined)
    final yieldMpa = double.tryParse(_yieldCtrl.text) ?? 250;
    final sf = double.tryParse(_sfCtrl.text) ?? 3;

    if (loadT == null || thickness == null || holeDia == null || plateWidth == null ||
        loadT <= 0 || thickness <= 0 || holeDia <= 0 || plateWidth <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all padeye fields with valid numbers.')),
      );
      return;
    }

    // Convert load: 1 tonne-force ~= 9.81 kN
    final loadKn = loadT * 9.81;
    final loadN = loadKn * 1000;

    // Bearing stress = Load / (hole diameter x plate thickness)
    final bearingArea = holeDia * thickness; // mm^2
    final bearingStress = loadN / bearingArea; // N/mm^2 = MPa

    // Tensile stress across net section beyond the hole = Load / (net width x thickness)
    final netArea = plateWidth * thickness; // mm^2 (net width already excludes hole)
    final tensileStress = loadN / netArea; // MPa

    final allowable = yieldMpa / sf;
    final worstStress = max(bearingStress, tensileStress);
    final safe = worstStress <= allowable;

    setState(() {
      _bearingStressMpa = bearingStress;
      _tensileStressMpa = tensileStress;
      _allowableStressMpa = allowable;
      _safe = safe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pad Eye Check')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _loadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Applied Load on Pad Eye (t)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _thicknessCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Plate Thickness (mm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _holeDiaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Pin Hole Diameter (mm)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plateWidthCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Net Plate Width Beyond Hole (mm, both sides)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yieldCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Plate Yield Strength (MPa, default 250)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sfCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Safety Factor (default 3:1)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE')),
            if (_bearingStressMpa != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'Bearing Stress', value: '${_bearingStressMpa!.toStringAsFixed(1)} MPa'),
                      ResultRow(label: 'Tensile Stress (net section)', value: '${_tensileStressMpa!.toStringAsFixed(1)} MPa'),
                      ResultRow(label: 'Allowable Stress', value: '${_allowableStressMpa!.toStringAsFixed(1)} MPa'),
                      const SizedBox(height: 12),
                      SafetyStatusBanner(isSafe: _safe ?? false),
                      const SizedBox(height: 8),
                      const Text(
                        'This is a simplified check (tensile + bearing only). A full padeye design must also verify shear-tear-out, weld/base-plate strength and cheek-plate requirements by a competent engineer.',
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
