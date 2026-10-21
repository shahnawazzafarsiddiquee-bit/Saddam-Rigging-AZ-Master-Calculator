import 'package:flutter/material.dart';

import '../services/calculation_engine.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});
  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  static const groups = UnitConversion.groups;

  final input = TextEditingController(text: '1');
  String group = 'Length';
  String from = 'm';

  String fmt(double x) {
    if (x == 0) return '0';
    final a = x.abs();
    if (a >= 1000000 || a < 0.0001) return x.toStringAsExponential(4);
    String s = x.toStringAsFixed(4);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = groups[group]!;
    final v = double.tryParse(input.text.trim().replaceAll(',', '.'));
    final valid = v != null && v.isFinite;

    return Scaffold(
      appBar: AppBar(title: const Text('Unit Converter')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: groups.keys
                  .map((g) => ChoiceChip(
                        label: Text(g),
                        selected: group == g,
                        onSelected: (_) => setState(() {
                          group = g;
                          from = g == 'Length' ? 'm' : groups[g]!.keys.first;
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: input,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('From unit:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: units.keys
                  .map((u) => ChoiceChip(
                        label: Text(u),
                        selected: from == u,
                        onSelected: (_) => setState(() => from = u),
                      ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            if (!valid) const Text('Enter a finite numeric value.'),
            if (valid)
              ...units.entries.map((e) => Card(
                  child: ListTile(
                    title: Text(
                      '${fmt(UnitConversion.convert(v, from, e.key))} ${e.key}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Metric tonne = 1000 kg. US short ton and UK long ton are listed separately. Force and mass are different quantities.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
