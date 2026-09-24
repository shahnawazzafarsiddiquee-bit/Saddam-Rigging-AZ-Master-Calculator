import 'package:flutter/material.dart';
import '../app/theme.dart';

double _n(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
String _f(double x, [int d = 2]) => x.toStringAsFixed(d);

enum _Type { web, round }

enum _Mat { pes, pa, pp }

enum _Chem { none, acid, alkali }

class _MatInfo {
  final String name;
  final String label;
  final Color labelColor;
  final double minT;
  final double maxT;
  final bool acidOk;
  final bool alkaliOk;
  const _MatInfo(this.name, this.label, this.labelColor, this.minT, this.maxT,
      this.acidOk, this.alkaliOk);
}

// EN 1492: label colour identifies the material, sling colour identifies the WLL.
const Map<_Mat, _MatInfo> _mats = {
  _Mat.pes: _MatInfo('Polyester (PES)', 'Blue label', Color(0xFF1E88E5), -40,
      100, true, false),
  _Mat.pa: _MatInfo('Nylon / Polyamide (PA)', 'Green label', Color(0xFF43A047),
      -40, 100, false, true),
  _Mat.pp: _MatInfo('Polypropylene (PP)', 'Brown label', Color(0xFF6D4C41),
      -40, 80, true, true),
};

Color _wllColour(double wll) {
  if (wll <= 1) return const Color(0xFF8E24AA);
  if (wll <= 2) return const Color(0xFF43A047);
  if (wll <= 3) return const Color(0xFFFDD835);
  if (wll <= 4) return const Color(0xFF9E9E9E);
  if (wll <= 5) return const Color(0xFFE53935);
  if (wll <= 6) return const Color(0xFF6D4C41);
  if (wll <= 8) return const Color(0xFF1E88E5);
  return const Color(0xFFFB8C00);
}

String _wllColourName(double wll) {
  if (wll <= 1) return 'Violet';
  if (wll <= 2) return 'Green';
  if (wll <= 3) return 'Yellow';
  if (wll <= 4) return 'Grey';
  if (wll <= 5) return 'Red';
  if (wll <= 6) return 'Brown';
  if (wll <= 8) return 'Blue';
  return 'Orange';
}

const List<double> _webWll = [1, 2, 3, 4, 5, 6, 8, 10];
const List<double> _roundWll = [1, 2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 25, 30, 40, 50];

class _Mode {
  final String config;
  final String angle;
  final double m;
  const _Mode(this.config, this.angle, this.m);
}

// EN 1492-1 / EN 1492-2 mode factors (angle beta measured from vertical).
const List<_Mode> _modes = [
  _Mode('1 leg Vertical', '-', 1.0),
  _Mode('1 leg Choker', '-', 0.8),
  _Mode('1 leg Basket (parallel)', '0 deg', 2.0),
  _Mode('1 leg Basket', '0-45 deg', 1.4),
  _Mode('1 leg Basket', '45-60 deg', 1.0),
  _Mode('2 leg Bridle', '0-45 deg', 1.4),
  _Mode('2 leg Bridle', '45-60 deg', 1.0),
  _Mode('2 leg Choker', '0-45 deg', 1.12),
  _Mode('2 leg Choker', '45-60 deg', 0.8),
  _Mode('3/4 leg Bridle', '0-45 deg', 2.1),
  _Mode('3/4 leg Bridle', '45-60 deg', 1.5),
  _Mode('3/4 leg Choker', '0-45 deg', 1.68),
  _Mode('3/4 leg Choker', '45-60 deg', 1.2),
];

const List<String> _rejectItems = [
  'Label nahi hai ya padha nahi ja raha',
  'Cut, ched ya ghisaai (abrasion) dikhti hai',
  'Silai (stitching) tooti ya dheeli',
  'Garmi se jala / pighla / chamakdar sakht hissa',
  'Chemical ka daag, rang badla ya kamzor fibre',
  'Round sling ka cover phata, andar ka core dikh raha',
  'Gaanth (knot) lagi hai',
  'Eye ya fitting damage / zang',
];

class SyntheticSlingScreen extends StatefulWidget {
  const SyntheticSlingScreen({super.key});
  @override
  State<SyntheticSlingScreen> createState() => _SyntheticSlingScreenState();
}

class _SyntheticSlingScreenState extends State<SyntheticSlingScreen> {
  _Type type = _Type.web;
  _Mat mat = _Mat.pes;
  _Chem chem = _Chem.none;
  double wll = 2;
  bool sharpEdge = false;
  final load = TextEditingController();
  final temp = TextEditingController(text: '30');
  final Set<int> rejects = {};

  @override
  void dispose() {
    load.dispose();
    temp.dispose();
    super.dispose();
  }

  List<double> get _sizes => type == _Type.web ? _webWll : _roundWll;

  Color? _col(int l) {
    if (l == 1) return Colors.greenAccent;
    if (l == 2) return Colors.orangeAccent;
    if (l == 3) return Colors.redAccent;
    return null;
  }

  Widget _line(String t, [int lvl = 0]) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(t,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _col(lvl))),
      );

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.safetyOrange,
                fontSize: 15)),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t, style: const TextStyle(color: Colors.white70)),
      );

  Widget _dot(Color c, [double s = 14]) => Container(
        width: s,
        height: s,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.white54),
        ),
      );

  Widget _chips<T>(List<T> values, T selected, Widget Function(T) label,
      void Function(T) onPick) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: values
          .map((v) => ChoiceChip(
                label: label(v),
                selected: v == selected,
                onSelected: (_) => setState(() => onPick(v)),
              ))
          .toList(),
    );
  }

  String _short(double w) => '${_wllColourName(w)} ${_f(w, 0)}t';

  double? _minFor(double need) {
    for (final s in _sizes) {
      if (s >= need - 1e-9) return s;
    }
    return null;
  }

  // Returns env problems as (text, level); level 3 means the sling must not be used.
  List<(String, int)> _envChecks() {
    final info = _mats[mat]!;
    final out = <(String, int)>[];
    final tText = temp.text.trim();
    if (tText.isNotEmpty) {
      final t = _n(temp);
      if (t < info.minT || t > info.maxT) {
        out.add((
          '${_f(t, 0)} C: ${info.name} ki range ${_f(info.minT, 0)} se +${_f(info.maxT, 0)} C hai. USE MAT KARO',
          3
        ));
      } else if (t < 0) {
        out.add((
          '${_f(t, 0)} C: range me hai, par geeli sling jam sakti hai. Barf / nami check karo',
          2
        ));
      } else {
        out.add(('${_f(t, 0)} C: temperature theek', 1));
      }
    }
    switch (chem) {
      case _Chem.none:
        out.add(('Chemical nahi: theek', 1));
      case _Chem.acid:
        out.add(info.acidOk
            ? ('Acid: ${info.name} acid jhel leta hai. Use ke baad saaf paani se dho', 1)
            : ('Acid: ${info.name} acid se kamzor hota hai. Polyester ya PP lo', 3));
      case _Chem.alkali:
        out.add(info.alkaliOk
            ? ('Alkali (chuna / cement): ${info.name} theek. Use ke baad dho', 1)
            : ('Alkali (chuna / cement): ${info.name} kamzor hota hai. Nylon ya PP lo', 3));
    }
    out.add(sharpEdge
        ? ('Sharp edge: edge protector / sleeve ZARURI, bina protector ke sling kat jayegi', 3)
        : ('Edge: gol / smooth. Edge radius sling ki motai se bada ho', 1));
    return out;
  }

  Widget _cell(String t,
          {bool head = false, Color? color, TextAlign align = TextAlign.left}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Text(t,
            textAlign: align,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: head ? FontWeight.bold : FontWeight.normal)),
      );

  Widget _capacityTable(double w) {
    final hasLoad = w > 0;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.white24),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: const FixedColumnWidth(118),
          1: const FixedColumnWidth(74),
          2: const FixedColumnWidth(44),
          3: const FixedColumnWidth(70),
          if (hasLoad) 4: const FixedColumnWidth(84),
        },
        children: [
          TableRow(children: [
            _cell('Config', head: true),
            _cell('Angle (vertical se)', head: true),
            _cell('M', head: true),
            _cell('Capacity', head: true),
            if (hasLoad) _cell('Is load ke liye min', head: true),
          ]),
          for (final md in _modes) _modeRow(md, w),
        ],
      ),
    );
  }

  TableRow _modeRow(_Mode md, double w) {
    final hasLoad = w > 0;
    final cap = wll * md.m;
    final ok = !hasLoad || cap >= w - 1e-9;
    final min = hasLoad ? _minFor(w / md.m) : null;
    return TableRow(children: [
      _cell(md.config),
      _cell(md.angle),
      _cell(_f(md.m, md.m == md.m.roundToDouble() ? 1 : 2)),
      _cell('${_f(cap, 1)} t',
          head: true,
          color: hasLoad ? (ok ? Colors.greenAccent : Colors.redAccent) : null),
      if (hasLoad)
        _cell(min == null ? 'N/A' : _short(min),
            color: min == null ? Colors.redAccent : null),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final info = _mats[mat]!;
    final w = _n(load);
    final env = _envChecks();
    final envBad = env.any((e) => e.$2 == 3);
    final rejected = rejects.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Synthetic Sling Calculator')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Sling type:'),
            _chips<_Type>(
                _Type.values,
                type,
                (t) => Text(t == _Type.web
                    ? 'Flat Web (EN 1492-1)'
                    : 'Round Sling (EN 1492-2)'),
                (t) {
                  type = t;
                  if (!_sizes.contains(wll)) wll = _webWll.last;
                }),
            _label('Material (label ka rang):'),
            _chips<_Mat>(
                _Mat.values,
                mat,
                (m) => Row(mainAxisSize: MainAxisSize.min, children: [
                      _dot(_mats[m]!.labelColor, 12),
                      Flexible(
                          child: Text(_mats[m]!.name,
                              overflow: TextOverflow.ellipsis)),
                    ]),
                (m) => mat = m),
            _label('Sling ka rang / WLL (vertical):'),
            _chips<double>(
                _sizes,
                wll,
                (s) => Row(mainAxisSize: MainAxisSize.min, children: [
                      _dot(_wllColour(s), 12),
                      Text('${_f(s, 0)} t'),
                    ]),
                (s) => wll = s),
            const SizedBox(height: 14),
            TextField(
              controller: load,
              onChanged: (_) => setState(() {}),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Load weight (optional, check ke liye)',
                suffixText: 'ton',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: temp,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              decoration: const InputDecoration(
                labelText: 'Kaam ki jagah ka temperature',
                suffixText: 'C',
                border: OutlineInputBorder(),
              ),
            ),
            _label('Chemical mahaul:'),
            _chips<_Chem>(
                _Chem.values,
                chem,
                (c) => Text(switch (c) {
                      _Chem.none => 'Kuch nahi',
                      _Chem.acid => 'Acid',
                      _Chem.alkali => 'Alkali / chuna / cement',
                    }),
                (c) => chem = c),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Load par sharp edge hai'),
              value: sharpEdge,
              onChanged: (v) => setState(() => sharpEdge = v),
            ),
            Card(
              margin: const EdgeInsets.only(top: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _dot(_wllColour(wll), 22),
                      Expanded(
                        child: Text(
                          '${_wllColourName(wll)} ${type == _Type.web ? 'web' : 'round'} sling, WLL ${_f(wll, 0)} t',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _dot(info.labelColor),
                      Expanded(
                          child: Text('${info.name}: ${info.label} hona chahiye')),
                    ]),
                    const SizedBox(height: 6),
                    ResultRow(
                        label: 'MBL (safety factor 7:1)',
                        value: '${_f(wll * 7, 0)} t'),
                    if (type == _Type.web)
                      ResultRow(
                          label: 'Chaudai (duplex, approx)',
                          value: '~${_f(wll * 30, 0)} mm'),
                    ResultRow(
                        label: 'Temperature range',
                        value:
                            '${_f(info.minT, 0)} se +${_f(info.maxT, 0)} C'),
                  ],
                ),
              ),
            ),
            _head('Mahaul check'),
            ...env.map((e) => _line(e.$1, e.$2)),
            _head('Capacity table (EN 1492 mode factor)'),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                  'Capacity = WLL x M. Angle vertical se: 0-45 = horizontal se 45-90, 45-60 = horizontal se 30-45. 60 se zyada (horizontal se 30 se kam) allowed nahi.',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            _capacityTable(w),
            _head('Use se pehle inspection (koi bhi tick = REJECT)'),
            ...List.generate(
              _rejectItems.length,
              (i) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(_rejectItems[i]),
                value: rejects.contains(i),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    rejects.add(i);
                  } else {
                    rejects.remove(i);
                  }
                }),
              ),
            ),
            const SizedBox(height: 8),
            SafetyStatusBanner(
              isSafe: !envBad && !rejected,
              safeText: 'SLING OK',
              unsafeText: rejected ? 'REJECT' : 'NOT SAFE',
            ),
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Text(
                'Ye estimate hai. Sling ke label / certificate ki WLL hi final hai. Width aur temperature limit maker ke hisaab se badal sakti hai. Final decision competent person aur lift plan se lo.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
