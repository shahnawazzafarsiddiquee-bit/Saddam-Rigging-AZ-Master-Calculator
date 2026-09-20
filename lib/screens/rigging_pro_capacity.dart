part of 'rigging_pro.dart';

class CapacityScreen extends StatefulWidget {
  const CapacityScreen({super.key});
  @override
  State<CapacityScreen> createState() => _CapacityScreenState();
}

class _CapacityScreenState extends State<CapacityScreen> {
  static const List<List<double>> shackles = [
    [13, 2.0], [16, 3.25], [19, 4.75], [22, 6.5], [25, 8.5], [29, 9.5],
    [32, 12.0], [35, 13.5], [38, 17.0], [45, 25.0], [51, 35.0],
  ];
  static const List<String> hitches = ['Vertical', 'Choker', 'Basket / 2-leg'];
  final wll = TextEditingController();
  final load = TextEditingController();
  String hitch = 'Vertical';
  List<_R> out = [];

  int _lv(int deg) => deg >= 60 ? 1 : (deg >= 45 ? 2 : 3);

  void calc() {
    final w = _n(wll);
    if (w <= 0) {
      setState(() => out = [const _R('Sling ki WLL (vertical) daalo', 3)]);
      return;
    }
    final res = <_R>[];
    if (hitch == 'Vertical') {
      res.add(_R('Vertical hitch capacity: ${_f(w)} ton', 1));
    } else if (hitch == 'Choker') {
      res.add(_R('Choker hitch capacity: ${_f(w * 0.75)} ton (75%)', 2));
      res.add(const _R(
          'Choke angle 120 deg se kam ho to capacity aur kam', 2));
    } else {
      for (final d in [90, 75, 60, 45, 30]) {
        final c = 2 * w * math.sin(_rad(d.toDouble()));
        res.add(_R('Angle $d deg: ${_f(c)} ton', _lv(d)));
      }
      res.add(const _R(
          'Ye 2 leg ki total capacity hai (angle horizontal se)'));
    }
    final l = _n(load);
    if (l > 0) {
      double dia = 0;
      double sw = 0;
      for (final s in shackles) {
        if (s[1] >= l) {
          dia = s[0];
          sw = s[1];
          break;
        }
      }
      if (dia > 0) {
        res.add(_R(
            'Bow shackle approx ${_f(dia, 0)} mm (WLL ${_f(sw)} ton) ya bada',
            1));
      } else {
        res.add(const _R('35 ton se upar: engineer se poochho', 3));
      }
    }
    setState(() => out = res);
  }

  Widget _cell(String s, {bool head = false}) => Padding(
        padding: const EdgeInsets.all(6),
        child: Text(s,
            style: TextStyle(
                fontSize: 13,
                fontWeight: head ? FontWeight.bold : FontWeight.normal)),
      );

  Widget _ropeTable() {
    const sizes = [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36, 40];
    return Table(
      border: TableBorder.all(color: Colors.white24),
      children: [
        TableRow(children: [
          _cell('Dia mm', head: true),
          _cell('Vertical', head: true),
          _cell('Choker', head: true),
          _cell('Basket', head: true),
          _cell('2leg 60', head: true),
        ]),
        ...sizes.map((d) {
          final w = d * d / 100;
          return TableRow(children: [
            _cell('$d'),
            _cell(_f(w)),
            _cell(_f(w * 0.75)),
            _cell(_f(w * 2)),
            _cell(_f(w * 2 * math.sin(_rad(60)))),
          ]);
        }),
      ],
    );
  }

  Widget _shackleTable() {
    return Table(
      border: TableBorder.all(color: Colors.white24),
      children: [
        TableRow(children: [
          _cell('Shackle mm', head: true),
          _cell('WLL ton', head: true),
        ]),
        ...shackles.map((s) => TableRow(children: [
              _cell(_f(s[0], 0)),
              _cell(_f(s[1])),
            ])),
      ],
    );
  }

  @override
  void dispose() {
    wll.dispose();
    load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Sling & Shackle Capacity', [
      _field(wll, 'Sling ki WLL (vertical / straight pull)', suffix: 'ton'),
      Wrap(
        spacing: 8,
        children: hitches
            .map((h) => ChoiceChip(
                  label: Text(h),
                  selected: hitch == h,
                  onSelected: (_) => setState(() => hitch = h),
                ))
            .toList(),
      ),
      const SizedBox(height: 16),
      _field(load, 'Shackle par load (optional)', suffix: 'ton'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      const SizedBox(height: 16),
      const Text('Wire rope sling (6x36 IWRC) approx WLL, ton',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      _ropeTable(),
      _note(
          'WLL = d x d / 100 ton (estimate, safe side). Basket = 90 deg, 2leg 60 = 2 leg 60 deg par.'),
      const SizedBox(height: 16),
      const Text('Bow shackle approx WLL',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      _shackleTable(),
      _note(
          'Shackle par load = us point ki tension. Shackle aur hook par likhi WLL hi final. Hook ki WLL uske stamp par dekho.'),
      _note(_disclaimer),
    ]);
  }
}
