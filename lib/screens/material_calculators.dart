import 'package:flutter/material.dart';
import 'unit_converter.dart';

double _v(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

String _f(double x, [int d = 2]) => x.toStringAsFixed(d);

Widget _field(TextEditingController c, String label, {String? suffix}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}

Widget _result(List<String> lines) {
  if (lines.isEmpty) return const SizedBox.shrink();
  return Card(
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(s,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ))
            .toList(),
      ),
    ),
  );
}

Widget _page(String title, List<Widget> children) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: children),
    ),
  );
}

class MaterialCalculatorsScreen extends StatelessWidget {
  const MaterialCalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String sub, Widget page) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => page)),
        ),
      );
    }

    return _page('Material Calculators', [
      tile(Icons.circle_outlined, 'Steel Pipe', 'Weight per meter & total',
          const SteelPipeCalculator()),
      tile(Icons.crop_square, 'Steel Plate', 'Plate weight (kg)',
          const SteelPlateCalculator()),
      tile(Icons.foundation, 'Concrete', 'Volume, cement, sand, aggregate',
          const ConcreteCalculator()),
      tile(Icons.swap_horiz, 'Unit Converter', 'mm, cm, m, inch, ft, kg, ton', const UnitConverterScreen()),
      tile(Icons.horizontal_rule, 'Rebar (Saria)', 'Weight by diameter',
          const RebarCalculator()),
    ]);
  }
}

class SteelPipeCalculator extends StatefulWidget {
  const SteelPipeCalculator({super.key});
  @override
  State<SteelPipeCalculator> createState() => _SteelPipeCalculatorState();
}

class _SteelPipeCalculatorState extends State<SteelPipeCalculator> {
  final od = TextEditingController();
  final th = TextEditingController();
  final len = TextEditingController(text: '6');
  final qty = TextEditingController(text: '1');
  List<String> result = [];

  void calc() {
    final o = _v(od), t = _v(th), l = _v(len), q = _v(qty);
    if (o <= 0 || t <= 0 || t * 2 >= o || l <= 0 || q <= 0) {
      setState(() => result = [
            'Sahi value daalo (thickness OD ke aadhe se kam honi chahiye)'
          ]);
      return;
    }
    final wpm = (o - t) * t * 0.02466;
    final total = wpm * l * q;
    setState(() => result = [
          'Inner dia: ${_f(o - 2 * t)} mm',
          'Weight per meter: ${_f(wpm)} kg/m',
          'Weight per pipe: ${_f(wpm * l)} kg',
          'Total weight: ${_f(total)} kg  (${_f(total / 1000, 3)} ton)',
        ]);
  }

  @override
  void dispose() {
    od.dispose();
    th.dispose();
    len.dispose();
    qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Steel Pipe Weight', [
      _field(od, 'Outer diameter (OD)', suffix: 'mm'),
      _field(th, 'Wall thickness', suffix: 'mm'),
      _field(len, 'Length of one pipe', suffix: 'm'),
      _field(qty, 'Quantity', suffix: 'nos'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _result(result),
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Formula: (OD - t) x t x 0.02466 kg/m (steel 7850 kg/m3)'),
      ),
    ]);
  }
}

class SteelPlateCalculator extends StatefulWidget {
  const SteelPlateCalculator({super.key});
  @override
  State<SteelPlateCalculator> createState() => _SteelPlateCalculatorState();
}

class _SteelPlateCalculatorState extends State<SteelPlateCalculator> {
  final len = TextEditingController();
  final wid = TextEditingController();
  final th = TextEditingController();
  final qty = TextEditingController(text: '1');
  List<String> result = [];

  void calc() {
    final l = _v(len), w = _v(wid), t = _v(th), q = _v(qty);
    if (l <= 0 || w <= 0 || t <= 0 || q <= 0) {
      setState(() => result = ['Sabhi value daalo']);
      return;
    }
    final one = l * w * t * 7.85;
    setState(() => result = [
          'Area: ${_f(l * w)} m2',
          'Weight of one plate: ${_f(one)} kg',
          'Total weight: ${_f(one * q)} kg  (${_f(one * q / 1000, 3)} ton)',
        ]);
  }

  @override
  void dispose() {
    len.dispose();
    wid.dispose();
    th.dispose();
    qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Steel Plate Weight', [
      _field(len, 'Length', suffix: 'm'),
      _field(wid, 'Width', suffix: 'm'),
      _field(th, 'Thickness', suffix: 'mm'),
      _field(qty, 'Quantity', suffix: 'nos'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _result(result),
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Formula: L(m) x W(m) x t(mm) x 7.85 kg'),
      ),
    ]);
  }
}

class ConcreteCalculator extends StatefulWidget {
  const ConcreteCalculator({super.key});
  @override
  State<ConcreteCalculator> createState() => _ConcreteCalculatorState();
}

class _ConcreteCalculatorState extends State<ConcreteCalculator> {
  final len = TextEditingController();
  final wid = TextEditingController();
  final hgt = TextEditingController();
  final qty = TextEditingController(text: '1');
  final waste = TextEditingController(text: '5');
  final Map<String, List<double>> grades = {
    'M15 (1:2:4)': [1.0, 2.0, 4.0],
    'M20 (1:1.5:3)': [1.0, 1.5, 3.0],
    'M25 (1:1:2)': [1.0, 1.0, 2.0],
  };
  String grade = 'M20 (1:1.5:3)';
  List<String> result = [];

  void calc() {
    final l = _v(len), w = _v(wid), h = _v(hgt), q = _v(qty), ws = _v(waste);
    if (l <= 0 || w <= 0 || h <= 0 || q <= 0) {
      setState(() => result = ['Length, width, height aur quantity daalo']);
      return;
    }
    final vol = l * w * h * q;
    final wet = vol * (1 + ws / 100);
    final dry = wet * 1.54;
    final r = grades[grade]!;
    final sum = r[0] + r[1] + r[2];
    final cementM3 = dry * r[0] / sum;
    final bags = cementM3 * 1440 / 50;
    final sand = dry * r[1] / sum;
    final agg = dry * r[2] / sum;
    setState(() => result = [
          'Concrete volume: ${_f(vol)} m3  (${_f(vol * 35.3147)} cft)',
          'With wastage: ${_f(wet)} m3',
          'Cement: ${_f(bags, 1)} bags (50 kg)',
          'Sand: ${_f(sand)} m3  (${_f(sand * 35.3147)} cft)',
          'Aggregate: ${_f(agg)} m3  (${_f(agg * 35.3147)} cft)',
        ]);
  }

  @override
  void dispose() {
    len.dispose();
    wid.dispose();
    hgt.dispose();
    qty.dispose();
    waste.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Concrete Calculator', [
      _field(len, 'Length', suffix: 'm'),
      _field(wid, 'Width', suffix: 'm'),
      _field(hgt, 'Height / Thickness', suffix: 'm'),
      _field(qty, 'Quantity', suffix: 'nos'),
      _field(waste, 'Wastage', suffix: '%'),
      Wrap(
        spacing: 8,
        children: grades.keys
            .map((g) => ChoiceChip(
                  label: Text(g),
                  selected: grade == g,
                  onSelected: (_) => setState(() => grade = g),
                ))
            .toList(),
      ),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _result(result),
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Dry volume = wet volume x 1.54. Cement 1440 kg/m3.'),
      ),
    ]);
  }
}

class RebarCalculator extends StatefulWidget {
  const RebarCalculator({super.key});
  @override
  State<RebarCalculator> createState() => _RebarCalculatorState();
}

class _RebarCalculatorState extends State<RebarCalculator> {
  final dia = TextEditingController();
  final len = TextEditingController(text: '12');
  final qty = TextEditingController(text: '1');
  List<String> result = [];

  void calc() {
    final d = _v(dia), l = _v(len), q = _v(qty);
    if (d <= 0 || l <= 0 || q <= 0) {
      setState(() => result = ['Sabhi value daalo']);
      return;
    }
    final wpm = d * d / 162;
    final total = wpm * l * q;
    setState(() => result = [
          'Weight per meter: ${_f(wpm, 3)} kg/m',
          'Weight per bar: ${_f(wpm * l)} kg',
          'Total weight: ${_f(total)} kg  (${_f(total / 1000, 3)} ton)',
        ]);
  }

  @override
  void dispose() {
    dia.dispose();
    len.dispose();
    qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Rebar (Saria) Weight', [
      _field(dia, 'Bar diameter', suffix: 'mm'),
      _field(len, 'Length of one bar', suffix: 'm'),
      _field(qty, 'Number of bars', suffix: 'nos'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _result(result),
      const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text('Formula: d x d / 162 kg/m'),
      ),
    ]);
  }
}
