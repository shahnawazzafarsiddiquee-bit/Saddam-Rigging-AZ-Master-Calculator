part of 'rigging_pro.dart';

class SectionWeightScreen extends StatefulWidget {
  const SectionWeightScreen({super.key});
  @override
  State<SectionWeightScreen> createState() => _SectionWeightScreenState();
}

class _SectionWeightScreenState extends State<SectionWeightScreen> {
  static const Map<String, double> ismb = {
    'ISMB 100': 11.5, 'ISMB 125': 13.0, 'ISMB 150': 14.9, 'ISMB 175': 19.3,
    'ISMB 200': 25.4, 'ISMB 225': 31.2, 'ISMB 250': 37.3, 'ISMB 300': 44.2,
    'ISMB 350': 52.4, 'ISMB 400': 61.6, 'ISMB 450': 72.4, 'ISMB 500': 86.9,
    'ISMB 550': 103.7, 'ISMB 600': 122.6,
  };
  static const Map<String, double> ismc = {
    'ISMC 75': 6.8, 'ISMC 100': 9.2, 'ISMC 125': 12.7, 'ISMC 150': 16.4,
    'ISMC 175': 19.1, 'ISMC 200': 22.1, 'ISMC 225': 25.9, 'ISMC 250': 30.4,
    'ISMC 300': 35.8, 'ISMC 350': 42.1, 'ISMC 400': 49.4,
  };
  static const List<String> types = [
    'ISMB', 'ISMC', 'Angle', 'Flat', 'Square', 'Round'
  ];
  final p1 = TextEditingController();
  final p2 = TextEditingController();
  final len = TextEditingController(text: '6');
  final qty = TextEditingController(text: '1');
  String type = 'ISMB';
  String size = 'ISMB 100';
  List<_R> out = [];

  Map<String, double> get _table => type == 'ISMB' ? ismb : ismc;
  String get _l1 => type == 'Angle'
      ? 'Leg size A (mm)'
      : (type == 'Flat'
          ? 'Width (mm)'
          : (type == 'Square' ? 'Side (mm)' : 'Diameter (mm)'));
  String get _l2 => type == 'Angle' ? 'Thickness t (mm)' : 'Thickness (mm)';

  void calc() {
    double kgm = 0;
    if (type == 'ISMB' || type == 'ISMC') {
      kgm = _table[size] ?? 0;
    } else if (type == 'Angle') {
      final a = _n(p1);
      final t = _n(p2);
      if (a > 0 && t > 0 && t < a) kgm = (2 * a - t) * t * 0.00785;
    } else if (type == 'Flat') {
      kgm = _n(p1) * _n(p2) * 0.00785;
    } else if (type == 'Square') {
      kgm = _n(p1) * _n(p1) * 0.00785;
    } else {
      kgm = _n(p1) * _n(p1) / 162;
    }
    final l = _n(len);
    final q = _n(qty);
    if (kgm <= 0 || l <= 0 || q <= 0) {
      setState(() => out = [const _R('Sabhi value sahi daalo', 3)]);
      return;
    }
    final total = kgm * l * q;
    setState(() => out = [
          _R('Weight per meter: ${_f(kgm)} kg/m'),
          _R('Weight per piece: ${_f(kgm * l)} kg'),
          _R('Total weight: ${_f(total)} kg (${_f(total / 1000, 3)} ton)', 1),
          _R(type == 'ISMB' || type == 'ISMC'
              ? 'Standard table (IS 808) ke hisaab se'
              : 'Formula se approx (corner radius ignore)'),
        ]);
  }

  @override
  void dispose() {
    p1.dispose();
    p2.dispose();
    len.dispose();
    qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Steel Section Weight', [
      Wrap(
        spacing: 8,
        children: types
            .map((t) => ChoiceChip(
                  label: Text(t),
                  selected: type == t,
                  onSelected: (_) => setState(() {
                    type = t;
                    if (t == 'ISMB') size = ismb.keys.first;
                    if (t == 'ISMC') size = ismc.keys.first;
                    out = [];
                  }),
                ))
            .toList(),
      ),
      const SizedBox(height: 12),
      if (type == 'ISMB' || type == 'ISMC')
        DropdownButton<String>(
          value: size,
          isExpanded: true,
          items: _table.keys
              .map((k) => DropdownMenuItem<String>(value: k, child: Text(k)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => size = v);
          },
        )
      else ...[
        _field(p1, _l1),
        if (type == 'Angle' || type == 'Flat') _field(p2, _l2),
      ],
      const SizedBox(height: 8),
      _field(len, 'Length of one piece', suffix: 'm'),
      _field(qty, 'Quantity', suffix: 'nos'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note(
          'Round bar: d x d / 162. Flat/Square: 0.00785 x mm x mm kg/m. Supplier ke chart se ek do size zaroor mila lo.'),
    ]);
  }
}

class ObjectWeightScreen extends StatefulWidget {
  const ObjectWeightScreen({super.key});
  @override
  State<ObjectWeightScreen> createState() => _ObjectWeightScreenState();
}

class _ObjectWeightScreenState extends State<ObjectWeightScreen> {
  static const Map<String, double> dens = {
    'Steel': 7850.0, 'Cast iron': 7200.0, 'Stainless': 8000.0,
    'Aluminium': 2700.0, 'Copper': 8960.0, 'Brass': 8500.0,
    'Concrete': 2400.0, 'Water': 1000.0, 'Wood': 600.0,
  };
  static const List<String> shapes = [
    'Block', 'Cylinder', 'Sphere', 'Tank (hollow)'
  ];
  final d1 = TextEditingController();
  final d2 = TextEditingController();
  final d3 = TextEditingController();
  final qty = TextEditingController(text: '1');
  String shape = 'Block';
  String mat = 'Steel';
  List<_R> out = [];

  String get _l1 => shape == 'Block' ? 'Length (m)' : 'Diameter (m)';
  String get _l2 => shape == 'Block'
      ? 'Width (m)'
      : (shape == 'Cylinder' ? 'Length (m)' : 'Height (m)');
  String get _l3 => shape == 'Block' ? 'Height (m)' : 'Wall thickness (mm)';

  void calc() {
    final a = _n(d1);
    final b = _n(d2);
    final c = _n(d3);
    final q = _n(qty);
    final rho = dens[mat] ?? 7850.0;
    if (q <= 0) {
      setState(() => out = [const _R('Quantity daalo', 3)]);
      return;
    }
    final res = <_R>[];
    if (shape == 'Tank (hollow)') {
      final t = c / 1000;
      if (a <= 0 || b <= 0 || t <= 0 || a - 2 * t <= 0 || b - 2 * t <= 0) {
        setState(() =>
            out = [const _R('Diameter, height, thickness sahi daalo', 3)]);
        return;
      }
      final outer = math.pi / 4 * a * a * b;
      final inner = math.pi / 4 * (a - 2 * t) * (a - 2 * t) * (b - 2 * t);
      final empty = (outer - inner) * rho * q;
      final full = empty + inner * 1000 * q;
      res.add(_R(
          'Khali tank: ${_f(empty, 0)} kg (${_f(empty / 1000, 3)} ton)', 1));
      res.add(_R(
          'Paani se bhara: ${_f(full, 0)} kg (${_f(full / 1000, 3)} ton)'));
      res.add(_R('Andar ka volume (ek tank): ${_f(inner * 1000, 0)} litre'));
    } else {
      double vol = 0;
      if (shape == 'Block') {
        vol = a * b * c;
      } else if (shape == 'Cylinder') {
        vol = math.pi / 4 * a * a * b;
      } else {
        vol = math.pi / 6 * a * a * a;
      }
      if (vol <= 0) {
        setState(() => out = [const _R('Dimensions sahi daalo', 3)]);
        return;
      }
      final kg = vol * rho * q;
      res.add(_R('Volume: ${_f(vol * q, 3)} m3'));
      res.add(_R(
          'Weight (solid): ${_f(kg, 0)} kg (${_f(kg / 1000, 3)} ton)', 1));
    }
    res.add(const _R(
        'ESTIMATE hai: lift plan me asli weight (nameplate / drawing) hi use karo',
        2));
    setState(() => out = res);
  }

  @override
  void dispose() {
    d1.dispose();
    d2.dispose();
    d3.dispose();
    qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Object & Tank Weight', [
      Wrap(
        spacing: 8,
        children: shapes
            .map((s) => ChoiceChip(
                  label: Text(s),
                  selected: shape == s,
                  onSelected: (_) => setState(() {
                    shape = s;
                    out = [];
                  }),
                ))
            .toList(),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: dens.keys
            .map((m) => ChoiceChip(
                  label: Text(m),
                  selected: mat == m,
                  onSelected: (_) => setState(() => mat = m),
                ))
            .toList(),
      ),
      const SizedBox(height: 12),
      _field(d1, _l1),
      if (shape != 'Sphere') _field(d2, _l2),
      if (shape == 'Block' || shape == 'Tank (hollow)') _field(d3, _l3),
      _field(qty, 'Quantity', suffix: 'nos'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note(
          'Tank me shell weight (dono end plate ke saath) aur paani se bhara weight dono milte hain.'),
    ]);
  }
}
