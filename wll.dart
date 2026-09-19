import 'package:flutter/material.dart';
import '../app/theme.dart';

/// 3. WLL CALCULATOR
/// WLL = Breaking Load / Safety Factor  (checked against the applied load)
class WllCalculator extends StatefulWidget {
  const WllCalculator({super.key});

  @override
  State<WllCalculator> createState() => _WllCalculatorState();
}

enum _WllType { sling, chain, wireRope }

class _WllCalculatorState extends State<WllCalculator> {
  _WllType _type = _WllType.sling;
  final _breakingLoadCtrl = TextEditingController();
  final _sfCtrl = TextEditingController();
  final _appliedLoadCtrl = TextEditingController();

  double? _wll;
  bool? _safe;

  double _defaultSf(_WllType t) {
    switch (t) {
      case _WllType.sling:
        return 5; // synthetic/wire rope slings: typically 5:1 to 7:1
      case _WllType.chain:
        return 4; // chain slings: typically 4:1
      case _WllType.wireRope:
        return 5; // wire rope: typically 5:1
    }
  }

  void _calculate() {
    final breakingLoad = double.tryParse(_breakingLoadCtrl.text);
    final sf = double.tryParse(_sfCtrl.text) ?? _defaultSf(_type);
    final appliedLoad = double.tryParse(_appliedLoadCtrl.text);

    if (breakingLoad == null || breakingLoad <= 0 || sf <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid breaking load and safety factor.')),
      );
      return;
    }

    final wll = breakingLoad / sf;
    final safe = appliedLoad == null ? true : appliedLoad <= wll;

    setState(() {
      _wll = wll;
      _safe = safe;
    });
  }

  String _typeLabel(_WllType t) {
    switch (t) {
      case _WllType.sling:
        return 'Sling';
      case _WllType.chain:
        return 'Chain';
      case _WllType.wireRope:
        return 'Wire Rope';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WLL Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<_WllType>(
              segments: _WllType.values
                  .map((t) => ButtonSegment(value: t, label: Text(_typeLabel(t))))
                  .toList(),
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _breakingLoadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Minimum Breaking Load / MBL (t)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sfCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Safety Factor (default ${_defaultSf(_type).toStringAsFixed(0)}:1)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _appliedLoadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Applied Load (t) — optional, for SAFE check'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _calculate, child: const Text('CALCULATE')),
            if (_wll != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ResultRow(label: '${_typeLabel(_type)} WLL', value: '${_wll!.toStringAsFixed(2)} t'),
                      const SizedBox(height: 12),
                      SafetyStatusBanner(isSafe: _safe ?? true),
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
