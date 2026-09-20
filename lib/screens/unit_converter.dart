import 'package:flutter/material.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});
  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  static const Map<String, Map<String, double>> groups = {
    'Length': {
      'mm': 0.001,
      'cm': 0.01,
      'm': 1.0,
      'inch': 0.0254,
      'ft': 0.3048,
    },
    'Weight': {
      'kg': 1.0,
      'ton': 1000.0,
      'lb': 0.45359237,
    },
  };

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
    final v = double.tryParse(input.text.trim().replaceAll(',', '.')) ?? 0;
    final base = v * units[from]!;

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
                          from = g == 'Length' ? 'm' : 'kg';
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: input,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            ...units.entries.map((e) => Card(
                  child: ListTile(
                    title: Text(
                      '${fmt(base / e.value)} ${e.key}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                )),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('1 inch = 25.4 mm, 1 ft = 12 inch, 1 ton = 1000 kg'),
            ),
          ],
        ),
      ),
    );
  }
}
