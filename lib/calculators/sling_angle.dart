import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/calculation_engine.dart';
import '../app/calculation_details.dart';

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
  final _wllCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  AngleConvention _convention = AngleConvention.horizontal;
  bool _ratingVerified = false;
  CalculationResult? _result;
  double? _breakingKg;

  List<TextEditingController> get _controllers => [
    _loadCtrl,
    _legsCtrl,
    _angleCtrl,
    _sfCtrl,
    _wllCtrl,
    _sourceCtrl,
  ];
  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(_invalidate);
    }
    _wllCtrl.addListener(_invalidateRating);
    _sourceCtrl.addListener(_invalidateRating);
  }

  void _invalidate() {
    if (_result != null) setState(() => _result = null);
  }

  void _invalidateRating() {
    if (_ratingVerified) setState(() => _ratingVerified = false);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    try {
    final load = double.tryParse(_loadCtrl.text);
    final legs = int.tryParse(_legsCtrl.text);
    final angle = double.tryParse(_angleCtrl.text);
    final sf = double.tryParse(_sfCtrl.text);

    if (load == null || legs == null || angle == null || sf == null)
        throw ArgumentError(
          'Enter load, effective legs, angle and design factor.',
        );
      CalculationEngine.finite(sf, 'Design factor', positive: true);
      final rawWll = _wllCtrl.text.trim();
      final wll = rawWll.isEmpty ? null : double.tryParse(rawWll);
      if (rawWll.isNotEmpty && wll == null)
        throw ArgumentError('Enter a valid selected configuration WLL.');
      final result = CalculationEngine.sling(
        loadKg: load * 1000,
        effectiveLegs: legs,
        angleDegrees: angle,
        convention: _convention,
        selectedWllKg: wll == null ? null : wll * 1000,
        ratingSource: _sourceCtrl.text,
        ratingVerified: _ratingVerified,
      );
      final breaking = result.values['requiredWllKg']! * sf;
      CalculationEngine.finite(
        breaking,
        'Required breaking strength',
        positive: true,
      );
      setState(() {
        _result = result;
        _breakingKg = breaking;
      });
    } on ArgumentError catch (e) {
      setState(() => _result = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message.toString())));
    }
  }

  Widget _field(TextEditingController c, String label, {bool numeric = true}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('Sling Angle Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(_loadCtrl, 'Load Weight (t)'),
            _field(_legsCtrl, 'Effective Supporting Legs (1-4)'),
            const Text(
              'Confirm effective load sharing for the actual arrangement; installed legs may not share equally.',
            ),
            const SizedBox(height: 12),
            SegmentedButton<AngleConvention>(
              segments: const [
                ButtonSegment(
                  value: AngleConvention.horizontal,
                  label: Text('From horizontal'),
                ),
                ButtonSegment(
                  value: AngleConvention.vertical,
                  label: Text('From vertical'),
                ),
              ],
              selected: {_convention},
              onSelectionChanged: (s) => setState(() {
                _convention = s.first;
                _result = null;
              }),
            ),
            const SizedBox(height: 12),
            _field(_angleCtrl, 'Sling Angle (${_convention.name}, deg)'),
            _field(_sfCtrl, 'Design Factor (verify source)'),
            _field(_wllCtrl, 'Selected Configuration WLL per Leg (t)'),
            _field(
              _sourceCtrl,
              'Tag / certificate / derating source & revision',
              numeric: false,
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _ratingVerified,
              title: const Text(
                'Configuration WLL verified against tag, certificate and manufacturer data',
              ),
              onChanged: (v) => setState(() {
                _ratingVerified = v ?? false;
                _result = null;
              }),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE'),
            ),
            if (result != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: 'Vertical Load per Leg',
                        value:
                            '${(result.values['verticalLoadPerLegN']! / CalculationEngine.gravity / 1000).toStringAsFixed(3)} t',
                      ),
                      ResultRow(
                        label: 'Sling Tension',
                        value:
                            '${(result.values['tensionN']! / CalculationEngine.gravity / 1000).toStringAsFixed(3)} t',
                      ),
                      ResultRow(
                        label: 'Required Configuration WLL',
                        value:
                            '${(result.values['requiredWllKg']! / 1000).toStringAsFixed(3)} t',
                      ),
                      ResultRow(
                        label: 'Required Breaking Strength (with factor)',
                        value: '${(_breakingKg! / 1000).toStringAsFixed(3)} t',
                      ),
                      if (result.values.containsKey('utilizationPercent'))
                        ResultRow(
                          label: 'Utilization',
                          value:
                              '${result.values['utilizationPercent']!.toStringAsFixed(1)}%',
                        ),
                      const SizedBox(height: 12),
                      CalculationDetails(result: result),
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
