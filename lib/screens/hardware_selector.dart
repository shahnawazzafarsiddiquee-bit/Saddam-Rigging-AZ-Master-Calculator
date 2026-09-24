import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';

double _n(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
String _f(double x, [int d = 2]) => x.toStringAsFixed(d);
double _rad(double d) => d * math.pi / 180;

enum SlingMat { web, round, wire, chainG80, chainG100 }

enum Hitch { vertical, choker, basket }

class _Size {
  final String label;
  final String short;
  final double wll;
  final Color? color;
  const _Size(this.label, this.short, this.wll, [this.color]);
}

const _violet = Color(0xFF8E24AA);
const _green = Color(0xFF43A047);
const _yellow = Color(0xFFFDD835);
const _grey = Color(0xFF9E9E9E);
const _red = Color(0xFFE53935);
const _brown = Color(0xFF6D4C41);
const _blue = Color(0xFF1E88E5);
const _orange = Color(0xFFFB8C00);

// EN 1492-1 flat web sling, duplex, colour code; widths are typical, vary by maker.
const List<_Size> _webSizes = [
  _Size('Violet 1 t (~30 mm chaudai)', 'Violet 1t', 1, _violet),
  _Size('Green 2 t (~60 mm chaudai)', 'Green 2t', 2, _green),
  _Size('Yellow 3 t (~90 mm chaudai)', 'Yellow 3t', 3, _yellow),
  _Size('Grey 4 t (~120 mm chaudai)', 'Grey 4t', 4, _grey),
  _Size('Red 5 t (~150 mm chaudai)', 'Red 5t', 5, _red),
  _Size('Brown 6 t (~180 mm chaudai)', 'Brown 6t', 6, _brown),
  _Size('Blue 8 t (~240 mm chaudai)', 'Blue 8t', 8, _blue),
  _Size('Orange 10 t (~300 mm chaudai)', 'Orange 10t', 10, _orange),
];

// EN 1492-2 round sling colour code.
const List<_Size> _roundSizes = [
  _Size('Violet 1 t', 'Violet 1t', 1, _violet),
  _Size('Green 2 t', 'Green 2t', 2, _green),
  _Size('Yellow 3 t', 'Yellow 3t', 3, _yellow),
  _Size('Grey 4 t', 'Grey 4t', 4, _grey),
  _Size('Red 5 t', 'Red 5t', 5, _red),
  _Size('Brown 6 t', 'Brown 6t', 6, _brown),
  _Size('Blue 8 t', 'Blue 8t', 8, _blue),
  _Size('Orange 10 t', 'Orange 10t', 10, _orange),
  _Size('Orange 12 t', 'Orange 12t', 12, _orange),
  _Size('Orange 15 t', 'Orange 15t', 15, _orange),
  _Size('Orange 20 t', 'Orange 20t', 20, _orange),
  _Size('Orange 25 t', 'Orange 25t', 25, _orange),
  _Size('Orange 30 t', 'Orange 30t', 30, _orange),
  _Size('Orange 40 t', 'Orange 40t', 40, _orange),
  _Size('Orange 50 t', 'Orange 50t', 50, _orange),
];

// Same d x d / 100 estimate the rest of the app uses for 6x36 IWRC.
final List<_Size> _wireSizes = [
  for (final d in const [8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36, 40, 44, 48, 52, 56, 60])
    _Size('$d mm (6x36 IWRC)', '$d mm', d * d / 100),
];

// EN 818-4 single-leg WLL.
const List<_Size> _g80Sizes = [
  _Size('6 mm G80', '6 mm', 1.12),
  _Size('7 mm G80', '7 mm', 1.5),
  _Size('8 mm G80', '8 mm', 2.0),
  _Size('10 mm G80', '10 mm', 3.15),
  _Size('13 mm G80', '13 mm', 5.3),
  _Size('16 mm G80', '16 mm', 8.0),
  _Size('18 mm G80', '18 mm', 10.0),
  _Size('20 mm G80', '20 mm', 12.5),
  _Size('22 mm G80', '22 mm', 15.0),
  _Size('26 mm G80', '26 mm', 21.2),
  _Size('32 mm G80', '32 mm', 31.5),
];

const List<_Size> _g100Sizes = [
  _Size('6 mm G100', '6 mm', 1.4),
  _Size('7 mm G100', '7 mm', 1.9),
  _Size('8 mm G100', '8 mm', 2.5),
  _Size('10 mm G100', '10 mm', 4.0),
  _Size('13 mm G100', '13 mm', 6.7),
  _Size('16 mm G100', '16 mm', 10.0),
  _Size('18 mm G100', '18 mm', 12.5),
  _Size('20 mm G100', '20 mm', 16.0),
  _Size('22 mm G100', '22 mm', 19.0),
  _Size('26 mm G100', '26 mm', 26.5),
  _Size('32 mm G100', '32 mm', 40.0),
];

// Bow shackle WLL (G-2130 style).
const List<_Size> _shackles = [
  _Size('1/4" (6 mm)', '', 0.5),
  _Size('5/16" (8 mm)', '', 0.75),
  _Size('3/8" (10 mm)', '', 1.0),
  _Size('7/16" (11 mm)', '', 1.5),
  _Size('1/2" (13 mm)', '', 2.0),
  _Size('5/8" (16 mm)', '', 3.25),
  _Size('3/4" (19 mm)', '', 4.75),
  _Size('7/8" (22 mm)', '', 6.5),
  _Size('1" (25 mm)', '', 8.5),
  _Size('1-1/8" (29 mm)', '', 9.5),
  _Size('1-1/4" (32 mm)', '', 12.0),
  _Size('1-3/8" (35 mm)', '', 13.5),
  _Size('1-1/2" (38 mm)', '', 17.0),
  _Size('1-3/4" (45 mm)', '', 25.0),
  _Size('2" (51 mm)', '', 35.0),
  _Size('2-1/2" (64 mm)', '', 55.0),
  _Size('3" (76 mm)', '', 85.0),
  _Size('3-1/2" (89 mm)', '', 120.0),
  _Size('4" (102 mm)', '', 150.0),
];

const Map<SlingMat, String> _matName = {
  SlingMat.web: 'Web Sling',
  SlingMat.round: 'Round Sling',
  SlingMat.wire: 'Wire Rope',
  SlingMat.chainG80: 'Chain G80',
  SlingMat.chainG100: 'Chain G100',
};

const Map<SlingMat, String> _tooBig = {
  SlingMat.web: '10 t se upar web sling nahi: Round sling ya zyada leg lo',
  SlingMat.round: '50 t se upar: engineer se poochho',
  SlingMat.wire: '60 mm se bada: engineer se poochho',
  SlingMat.chainG80: '32 mm G80 se bada: G100 ya zyada leg lo',
  SlingMat.chainG100: '32 mm G100 se bada: engineer se poochho',
};

// Choker rating as a fraction of vertical WLL at a normal (>=120 deg) choke.
const Map<SlingMat, double> _chokerBase = {
  SlingMat.web: 0.8,
  SlingMat.round: 0.8,
  SlingMat.wire: 0.75,
  SlingMat.chainG80: 0.8,
  SlingMat.chainG100: 0.8,
};

const List<String> _chokeLabels = [
  '120-180 deg (normal)',
  '90-119 deg',
  '60-89 deg',
  '30-59 deg',
];
const List<double> _chokeF = [1.0, 0.87, 0.74, 0.62];

const Map<Hitch, String> _hitchName = {
  Hitch.vertical: 'Vertical',
  Hitch.choker: 'Choker',
  Hitch.basket: 'Basket',
};

const Map<Hitch, String> _hitchHelp = {
  Hitch.vertical:
      'Vertical: sling seedha hook se load ke lifting point tak (1 leg = straight, 2-4 leg = bridle).',
  Hitch.choker:
      'Choker: sling load ke around lapet ke apne hi eye se nikalti hai. Capacity kam hoti hai.',
  Hitch.basket:
      'Basket: sling load ke neeche se U shape, dono eye hook par. Capacity double (angle ke saath kam).',
};

List<_Size> _table(SlingMat m) {
  switch (m) {
    case SlingMat.web:
      return _webSizes;
    case SlingMat.round:
      return _roundSizes;
    case SlingMat.wire:
      return _wireSizes;
    case SlingMat.chainG80:
      return _g80Sizes;
    case SlingMat.chainG100:
      return _g100Sizes;
  }
}

_Size? _pick(List<_Size> t, double need) {
  for (final s in t) {
    if (s.wll >= need - 1e-9) return s;
  }
  return null;
}

class _Calc {
  final int nEff;
  final double angleSin;
  final double hitchF;
  final double factor;
  final double req;
  final double legTension;
  final _Size? sling;
  const _Calc(this.nEff, this.angleSin, this.hitchF, this.factor, this.req,
      this.legTension, this.sling);
}

_Calc _compute(double w, SlingMat m, Hitch h, int legs, double angDeg,
    int chokeIdx, bool conservative) {
  final nEff = legs <= 2 ? legs : (conservative ? 2 : 3);
  final angleSin =
      (legs == 1 && h != Hitch.basket) ? 1.0 : math.sin(_rad(angDeg));
  final hitchF = switch (h) {
    Hitch.vertical => 1.0,
    Hitch.choker => _chokerBase[m]! * _chokeF[chokeIdx],
    Hitch.basket => 2.0,
  };
  final factor = nEff * angleSin * hitchF;
  final req = w / factor;
  final parts = h == Hitch.basket ? 2 : 1;
  final legTension = w / (nEff * parts * angleSin);
  return _Calc(nEff, angleSin, hitchF, factor, req, legTension,
      _pick(_table(m), req));
}

class HardwareSelectorScreen extends StatefulWidget {
  const HardwareSelectorScreen({super.key});
  @override
  State<HardwareSelectorScreen> createState() => _HardwareSelectorScreenState();
}

class _HardwareSelectorScreenState extends State<HardwareSelectorScreen> {
  final load = TextEditingController();
  final ang = TextEditingController(text: '60');
  final tag = TextEditingController();
  SlingMat mat = SlingMat.web;
  Hitch hitch = Hitch.vertical;
  int legs = 2;
  int chokeIdx = 0;
  bool conservative = true;

  @override
  void dispose() {
    load.dispose();
    ang.dispose();
    tag.dispose();
    super.dispose();
  }

  bool get _angleUsed => legs > 1 || hitch == Hitch.basket;

  Color? _col(int l) {
    if (l == 1) return Colors.greenAccent;
    if (l == 2) return Colors.orangeAccent;
    if (l == 3) return Colors.redAccent;
    return null;
  }

  Widget _line(String t, [int lvl = 0]) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(t,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _col(lvl))),
      );

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.safetyOrange,
                fontSize: 14)),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(t, style: const TextStyle(color: Colors.white70)),
      );

  Widget _chips<T>(List<T> values, T selected, String Function(T) name,
      void Function(T) onPick) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: values
          .map((v) => ChoiceChip(
                label: Text(name(v)),
                selected: v == selected,
                onSelected: (_) => setState(() => onPick(v)),
              ))
          .toList(),
    );
  }

  Widget _swatch(Color c) => Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white54),
        ),
      );

  Widget _slingLine(_Calc c) {
    final s = c.sling;
    if (s == null) return _line(_tooBig[mat]!, 3);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (s.color != null) _swatch(s.color!),
          Expanded(
            child: Text(
              '${_matName[mat]}: ${s.label}, WLL ${_f(s.wll)} t (vertical)',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _warnings(double angDeg) {
    final out = <Widget>[];
    if (_angleUsed) {
      if (angDeg < 30) {
        out.add(_line(
            'Angle 30 deg se kam: ALLOWED NAHI. Sling lambi karo ya spreader beam lo',
            3));
      } else if (angDeg < 45) {
        out.add(_line(
            'Angle 30-45 deg: KHATRA, tension bahut badh jati hai', 3));
      } else if (angDeg < 60) {
        out.add(_line('Angle 45-60 deg: chalega, par 60+ behtar hai', 2));
      } else {
        out.add(_line('Angle 60 deg ya upar: achha', 1));
      }
    }
    if (hitch == Hitch.choker) {
      out.add(_line(
          chokeIdx == 0
              ? 'Choker: choke point load ke edge se door rakho, sling ko zabardasti tight mat karo'
              : 'Choke angle ${_chokeLabels[chokeIdx]}: capacity ${_f((1 - _chokeF[chokeIdx]) * 100, 0)}% aur kam ho gayi',
          2));
    }
    if (legs >= 3) {
      out.add(conservative
          ? _line(
              '$legs leg: safe side ke liye sirf 2 leg load maane (rigid load, ASME B30.9 practice)')
          : _line(
              '$legs leg standard (EN 13414): 3 leg load maane. Sirf tab jab load flexible ho aur CG centre me ho',
              2));
    }
    switch (mat) {
      case SlingMat.web:
      case SlingMat.round:
        out.add(_line(
            'Sharp edge par edge protector / sleeve zaruri. Polyester: -40 se +100 C, alkali (chuna / cement) se bachao. Label na ho to use mat karo',
            2));
      case SlingMat.wire:
        if (hitch != Hitch.vertical) {
          out.add(_line(
              'Wire rope choker / basket me bend D/d 25 se kam ho to capacity aur ghategi (D/d Ratio calculator dekho)',
              2));
        }
        out.add(_line(
            'Kink, bird-cage, tooti wire, corrosion ho to sling reject'));
      case SlingMat.chainG80:
      case SlingMat.chainG100:
        out.add(_line(
            'Chain: twist / knot nahi, grade tag check karo, hook latch band. Stretch 3% ya link wear 10% se zyada ho to reject'));
    }
    return out;
  }

  Widget _results(double w, double angDeg) {
    final c = _compute(w, mat, hitch, legs, angDeg, chokeIdx, conservative);
    final tagW = _n(tag);
    final shackle =
        hitch == Hitch.basket ? null : _pick(_shackles, c.legTension);
    final children = <Widget>[
      _head('Configuration'),
      _line(
          '${_matName[mat]}, ${_hitchName[hitch]}, $legs leg${_angleUsed ? ', angle ${_f(angDeg, 0)} deg' : ''}'),
      _line('Load lene wale legs: ${c.nEff}'),
      _line(
          'Total factor: ${_f(c.factor, 2)}x  (${c.nEff} leg x ${_f(c.angleSin, 3)} angle x ${_f(c.hitchF, 2)} hitch)'),
      _head('Tension'),
      _line(hitch == Hitch.basket
          ? 'Har sling part ki tension: ${_f(c.legTension)} t'
          : 'Har leg ki tension: ${_f(c.legTension)} t'),
      _head('Sling'),
      _line('Har sling ki required WLL (vertical rating): ${_f(c.req)} t'),
      _slingLine(c),
      _head('Shackle'),
      if (hitch == Hitch.basket)
        _line('Basket me sling ka eye seedha hook par, load par shackle nahi lagta')
      else if (shackle == null)
        _line('150 t se upar: engineer se poochho', 3)
      else
        _line(
            'Bow shackle har lifting point par: min ${shackle.label}, WLL ${_f(shackle.wll)} t',
            1),
      _head('Master Link / Hook'),
      _line(
          legs >= 3
              ? 'Quad master link assembly (master + 2 intermediate link), WLL min ${_f(w)} t'
              : 'Master link / hook WLL min ${_f(w)} t',
          1),
      _head('Dhyan rakho'),
      ..._warnings(angDeg),
    ];
    if (tagW > 0) {
      final cap = tagW * c.factor;
      final util = w / cap * 100;
      children.addAll([
        _head('Aapki sling ka check'),
        ResultRow(
            label: 'Rig capacity (tag x factor)', value: '${_f(cap)} t'),
        ResultRow(label: 'Utilization', value: '${_f(util, 0)}%'),
        const SizedBox(height: 8),
        SafetyStatusBanner(isSafe: util <= 100),
      ]);
    }
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  Widget _cell(String t, {bool head = false}) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(t,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                fontWeight: head ? FontWeight.bold : FontWeight.normal)),
      );

  Widget _matrixCell(double w, double angDeg, Hitch h, int n) {
    final c = _compute(w, mat, h, n, angDeg, chokeIdx, conservative);
    final sel = h == hitch && n == legs;
    final s = c.sling;
    return InkWell(
      onTap: () => setState(() {
        hitch = h;
        legs = n;
      }),
      child: Container(
        color: sel ? AppColors.safetyOrange.withAlpha(60) : null,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (s?.color != null)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                        color: s!.color, shape: BoxShape.circle),
                  ),
                Flexible(
                  child: Text(s?.short ?? 'N/A',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: s == null ? Colors.redAccent : null)),
                ),
              ],
            ),
            Text('${_f(c.req, 1)} t',
                style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _matrix(double w, double angDeg) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(86),
        columnWidths: const {0: FixedColumnWidth(74)},
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder.all(color: Colors.white24),
        children: [
          TableRow(children: [
            _cell('Hitch', head: true),
            for (final n in const [1, 2, 3, 4]) _cell('$n Leg', head: true),
          ]),
          for (final h in Hitch.values)
            TableRow(children: [
              _cell(_hitchName[h]!, head: true),
              for (final n in const [1, 2, 3, 4])
                _matrixCell(w, angDeg, h, n),
            ]),
        ],
      ),
    );
  }

  Widget _colourLegend() {
    final t = mat == SlingMat.web ? _webSizes : _roundSizes;
    final seen = <String>{};
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final s in t)
          if (seen.add(s.color.toString()))
            Row(mainAxisSize: MainAxisSize.min, children: [
              _swatch(s.color!),
              Text(s.color == _orange && mat == SlingMat.round
                  ? '10 t+'
                  : '${_f(s.wll, 0)} t'),
            ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = _n(load);
    final a = _n(ang);
    final angDeg = (a > 0 && a <= 90) ? a : 60.0;
    final badAngle = _angleUsed && (a <= 0 || a > 90);

    return Scaffold(
      appBar: AppBar(title: const Text('Hardware Quick Selector')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: load,
              onChanged: (_) => setState(() {}),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Total load weight (rigging samet)',
                suffixText: 'ton',
                border: OutlineInputBorder(),
              ),
            ),
            _label('Sling material:'),
            _chips<SlingMat>(SlingMat.values, mat, (m) => _matName[m]!,
                (m) => mat = m),
            _label('Hitch type:'),
            _chips<Hitch>(Hitch.values, hitch, (h) => _hitchName[h]!,
                (h) => hitch = h),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_hitchHelp[hitch]!,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
            _label('Legs (bridle):'),
            _chips<int>(const [1, 2, 3, 4], legs, (n) => '$n Leg',
                (n) => legs = n),
            if (_angleUsed) ...[
              const SizedBox(height: 14),
              TextField(
                controller: ang,
                onChanged: (_) => setState(() {}),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Sling angle (horizontal se)',
                  suffixText: 'deg',
                  border: const OutlineInputBorder(),
                  errorText: badAngle ? '1 se 90 ke beech daalo' : null,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [90, 60, 45, 30]
                    .map((d) => ActionChip(
                          label: Text('$d deg'),
                          onPressed: () => setState(() => ang.text = '$d'),
                        ))
                    .toList(),
              ),
            ],
            if (hitch == Hitch.choker) ...[
              _label('Choke angle:'),
              _chips<int>(const [0, 1, 2, 3], chokeIdx,
                  (i) => _chokeLabels[i], (i) => chokeIdx = i),
            ],
            if (legs >= 3)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Safe side: sirf 2 leg load lete hain'),
                subtitle: const Text(
                    'Rigid load / CG pakka nahi ho to ON rakho. OFF = EN 13414 (3 leg)'),
                value: conservative,
                onChanged: (v) => setState(() => conservative = v),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: tag,
              onChanged: (_) => setState(() {}),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Aapki sling ka tag WLL (optional, check ke liye)',
                suffixText: 'ton',
                border: OutlineInputBorder(),
              ),
            ),
            if (w <= 0)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text('Load weight daalo, result turant dikhega.',
                    style: TextStyle(color: Colors.white54)),
              )
            else if (!badAngle) ...[
              _results(w, angDeg),
              _head('Sab hitch x leg ek saath (${_matName[mat]})'),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                    'Har box: suggested size aur required WLL per sling. Box dabao to wahi select ho jayega.',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              _matrix(w, angDeg),
            ],
            if (mat == SlingMat.web || mat == SlingMat.round) ...[
              _head('Colour code (EN 1492)'),
              _colourLegend(),
            ],
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Ye minimum size suggestion hai. Sling tag / certificate ki WLL hi final hai. Web sling width maker ke hisaab se badalti hai. Final decision competent person aur lift plan se lo.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
