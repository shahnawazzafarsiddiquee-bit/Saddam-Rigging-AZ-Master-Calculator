import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rigging_pro.dart';
import 'smart_radius.dart';
import 'site_environment.dart';
export 'site_environment.dart' show WindCheckScreen;
export 'smart_radius.dart' show CraneBoomScreen;
import '../services/calculation_engine.dart';
import '../app/calculation_details.dart';

double _n(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

String _f(double x, [int d = 2]) => x.toStringAsFixed(d);

double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;

class _R {
  final String t;
  final int lvl;
  const _R(this.t, [this.lvl = 0]);
}

Color? _col(int l) {
  if (l == 1) return Colors.greenAccent;
  if (l == 2) return Colors.orangeAccent;
  if (l == 3) return Colors.redAccent;
  return null;
}

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

Widget _results(List<_R> rs) {
  if (rs.isEmpty) return const SizedBox.shrink();
  return Card(
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rs
            .map(
              (r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  r.t,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _col(r.lvl),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
}

Widget _note(String s) {
  return Padding(padding: const EdgeInsets.only(top: 12), child: Text(s));
}

Widget _page(String title, List<Widget> children) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: children),
    ),
  );
}

const String _disclaimer =
    'Ye sirf estimate hain. Final decision crane load chart, sling tag/certificate aur lift plan (competent person) ke hisaab se lo.';

// ---------------- Hub ----------------
class AdvancedRiggingScreen extends StatelessWidget {
  const AdvancedRiggingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String sub, Widget page) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        ),
      );
    }

    return _page('Advanced Rigging', [
      tile(
        Icons.straighten,
        'Sling Length & Angle',
        'Container / pipe: sling length, angle, size',
        const SlingLengthScreen(),
      ),
      tile(
        Icons.precision_manufacturing,
        'Crane Boom & Capacity',
        'Boom length, angle, utilization %',
        const CraneBoomScreen(),
      ),
      tile(
        Icons.air,
        'Wind Check',
        'Wind force on load, go / no-go',
        const WindCheckScreen(),
      ),
      tile(
        Icons.compare_arrows,
        'CG Load Share',
        '2 point lift: load per point & sling',
        const CgShareScreen(),
      ),
      tile(
        Icons.terrain,
        'Ground Bearing',
        'Outrigger mat pressure',
        const GroundBearingScreen(),
      ),
      tile(
        Icons.handyman,
        'Pro Tools',
        'Crane chart, lift plan PDF, capacity, certificates',
        const ProToolsScreen(),
      ),
      _note(_disclaimer),
    ]);
  }
}

// ---------------- Sling length & angle ----------------
class SlingLengthScreen extends StatefulWidget {
  const SlingLengthScreen({super.key});
  @override
  State<SlingLengthScreen> createState() => _SlingLengthScreenState();
}

class _SlingLengthScreenState extends State<SlingLengthScreen> {
  static const List<double> sizes = [
    8,
    10,
    12,
    14,
    16,
    18,
    20,
    22,
    24,
    26,
    28,
    32,
    36,
    40,
    44,
    48,
    52,
  ];
  final load = TextEditingController();
  final len = TextEditingController(text: '12');
  final wid = TextEditingController(text: '2.44');
  final ang = TextEditingController(text: '60');
  final avail = TextEditingController();
  int legs = 4;
  List<_R> out = [];

  void calc() {
    final w = _n(load);
    final a = _n(len);
    final b = _n(wid);
    final th = _n(ang);
    final av = _n(avail);
    if (w <= 0 || a <= 0 || th <= 0 || th >= 90 || (legs == 4 && b <= 0)) {
      setState(
        () => out = [
          const _R('Load, length aur angle sahi daalo (4 leg me width bhi)', 3),
        ],
      );
      return;
    }
    final run = legs == 4 ? math.sqrt(a * a + b * b) / 2 : a / 2;
    final t = _rad(th);
    final legLen = run / math.cos(t);
    final height = run * math.tan(t);
    final tension = w / (2 * math.sin(t));
    final needD = math.sqrt(tension * 100);
    double pick = 0;
    for (final s in sizes) {
      if (s >= needD) {
        pick = s;
        break;
      }
    }
    final res = <_R>[
      _R('Har leg ki sling length: ${_f(legLen)} m'),
      _R('Hook lifting points se upar: ${_f(height)} m (headroom)'),
      _R('Load per leg (tension): ${_f(tension)} ton'),
      _R('Angle factor: ${_f(1 / math.sin(t), 3)}x'),
    ];
    if (th >= 60) {
      res.add(const _R('Angle 60 ya upar: achha', 1));
    } else if (th >= 45) {
      res.add(const _R('Angle 45-60: chalega, par 60 behtar hai', 2));
    } else {
      res.add(
        const _R(
          'Angle 45 se kam: KHATRA. Sling lambi karo ya spreader beam lo',
          3,
        ),
      );
    }
    if (pick > 0) {
      res.add(
        _R(
          'Wire rope sling (6x36 IWRC) kam se kam ${_f(pick, 0)} mm (WLL approx ${_f(pick * pick / 100)} ton)',
          1,
        ),
      );
    } else {
      res.add(
        const _R(
          '52 mm se bada chahiye: spreader beam ya engineer se poochho',
          3,
        ),
      );
    }
    if (legs == 4) {
      res.add(
        const _R('4 leg me safe side ke liye sirf 2 leg carry maane hain', 2),
      );
    }
    if (av > 0) {
      if (av <= run) {
        res.add(
          const _R(
            'Aapki sling bahut chhoti hai (leg length horizontal doori se badi honi chahiye)',
            3,
          ),
        );
      } else {
        final ta = math.acos(run / av);
        final tt = w / (2 * math.sin(ta));
        final lv = ta >= _rad(60) ? 1 : (ta >= _rad(45) ? 2 : 3);
        res.add(
          _R(
            'Aapki ${_f(av)} m sling se angle: ${_f(_deg(ta), 1)} deg, load per leg ${_f(tt)} ton',
            lv,
          ),
        );
      }
    }
    setState(() => out = res);
  }

  @override
  void dispose() {
    load.dispose();
    len.dispose();
    wid.dispose();
    ang.dispose();
    avail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Sling Length & Angle', [
      _field(load, 'Load weight', suffix: 'ton'),
      _field(len, 'Lifting points ke beech length', suffix: 'm'),
      if (legs == 4) _field(wid, 'Lifting points ke beech width', suffix: 'm'),
      _field(ang, 'Target sling angle (horizontal se)', suffix: 'deg'),
      _field(avail, 'Aapke paas sling ki length (optional)', suffix: 'm'),
      Wrap(
        spacing: 8,
        children: [2, 4]
            .map(
              (n) => ChoiceChip(
                label: Text('$n leg'),
                selected: legs == n,
                onSelected: (_) => setState(() => legs = n),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note(
        'Container: 12 m x 2.44 m, 4 leg. Pipe: 2 leg, length = dono sling points ke beech doori. Wire rope size rule: WLL = d x d / 100 ton (estimate).',
      ),
      _note(_disclaimer),
    ]);
  }
}

// ---------------- CG load share ----------------
class CgShareScreen extends StatefulWidget {
  const CgShareScreen({super.key});
  @override
  State<CgShareScreen> createState() => _CgShareScreenState();
}

class _CgShareScreenState extends State<CgShareScreen> {
  final load = TextEditingController();
  final sp = TextEditingController();
  final cg = TextEditingController();
  final hh = TextEditingController(text: '5');
  List<_R> out = [];

  int _lv(double a) => a >= _rad(60) ? 1 : (a >= _rad(45) ? 2 : 3);

  void calc() {
    final w = _n(load);
    final s = _n(sp);
    final x = _n(cg);
    final h = _n(hh);
    if (w <= 0 || s <= 0 || h <= 0) {
      setState(() => out = [const _R('Sabhi value sahi daalo', 3)]);
      return;
    }
    if (x <= 0 || x >= s) {
      setState(
        () => out = [
          const _R(
            'CG dono lifting points ke beech me nahi hai: load palat sakta hai. Points badlo',
            3,
          ),
        ],
      );
      return;
    }
    CalculationResult share;
    try {
      share = CalculationEngine.twoPointShare(
        loadKg: w * 1000,
        spanM: s,
        cgFromLeftM: x,
      );
    } on ArgumentError catch (e) {
      setState(() => out = [_R(e.message.toString(), 3)]);
      return;
    }
    final ra = share.values['leftKg']! / 1000;
    final rb = share.values['rightKg']! / 1000;
    final aA = math.atan2(h, x);
    final aB = math.atan2(h, s - x);
    final tA = ra / math.sin(aA);
    final tB = rb / math.sin(aB);
    final lA = math.sqrt(x * x + h * h);
    final lB = math.sqrt((s - x) * (s - x) + h * h);
    setState(
      () => out = [
        _R('Point A par load: ${_f(ra)} ton'),
        _R('Point B par load: ${_f(rb)} ton'),
        _R(
          'Sling A: ${_f(lA)} m, angle ${_f(_deg(aA), 1)} deg, tension ${_f(tA)} ton',
          _lv(aA),
        ),
        _R(
          'Sling B: ${_f(lB)} m, angle ${_f(_deg(aB), 1)} deg, tension ${_f(tB)} ton',
          _lv(aB),
        ),
        _R(
          'Hook / master link point A se ${_f(x)} m par, CG ke seedha upar rakho',
        ),
      ],
    );
  }

  @override
  void dispose() {
    load.dispose();
    sp.dispose();
    cg.dispose();
    hh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('CG Load Share', [
      _field(load, 'Load weight', suffix: 'ton'),
      _field(sp, 'Dono lifting points ke beech doori', suffix: 'm'),
      _field(cg, 'CG, point A se kitni doori par', suffix: 'm'),
      _field(hh, 'Hook ki height lifting points se upar', suffix: 'm'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note(
        'CG jis point ke paas ho, us par zyada load aur us sling ki tension zyada. Dono sling ki tension ke hisaab se size lo.',
      ),
      _note(_disclaimer),
    ]);
  }
}

// ---------------- Ground bearing ----------------
class GroundBearingScreen extends StatefulWidget {
  const GroundBearingScreen({super.key});
  @override
  State<GroundBearingScreen> createState() => _GroundBearingScreenState();
}

class _GroundBearingScreenState extends State<GroundBearingScreen> {
  final rxn = TextEditingController(),
      ml = TextEditingController(),
      mw = TextEditingController(),
      sb = TextEditingController();
  final groundDocument = TextEditingController(),
      revision = TextEditingController(),
      approvedBy = TextEditingController(),
      reactionSource = TextEditingController();
  bool verified = false;
  CalculationResult? result;
  String error = '';
  List<TextEditingController> get controllers => [
    rxn,
    ml,
    mw,
    sb,
    groundDocument,
    revision,
    approvedBy,
    reactionSource,
  ];
  @override
  void initState() {
    super.initState();
    for (final c in controllers) {
      c.addListener(invalidate);
    }
  }

  void invalidate() {
    setState(() {
      result = null;
      verified = false;
      error = '';
    });
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void calc() {
    try {
      final hasGroundSource = [
        groundDocument,
        revision,
        approvedBy,
      ].every((c) => c.text.trim().isNotEmpty);
      final r = CalculationEngine.ground(
        reactionN: _n(rxn) * 1000 * CalculationEngine.gravity,
        lengthM: _n(ml),
        widthM: _n(mw),
        allowablePa: sb.text.trim().isEmpty
            ? null
            : _n(sb) * 1000 * CalculationEngine.gravity,
        groundSource: hasGroundSource
            ? '${groundDocument.text}, rev ${revision.text}, approved by ${approvedBy.text}'
            : '',
        reactionSource: reactionSource.text,
        sourcesVerified: verified,
      );
      setState(() {
        result = r;
        error = '';
      });
    } on ArgumentError catch (e) {
      setState(() {
        result = null;
        error = e.message.toString();
      });
    }
  }

  Widget text(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final r = result;
    return _page('Ground Bearing', [
      _field(
        rxn,
        'Maximum outrigger reaction from verified source',
        suffix: 'tonne-force',
      ),
      _field(ml, 'Effective bearing length', suffix: 'm'),
      _field(mw, 'Effective bearing width', suffix: 'm'),
      _field(
        sb,
        'Allowable ground pressure from approved report',
        suffix: 'tonne-force/m2',
      ),
      text(groundDocument, 'Ground report / project document'),
      text(revision, 'Ground document revision'),
      text(approvedBy, 'Ground value approved by'),
      text(reactionSource, 'Reaction source, configuration & revision'),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: verified,
        title: const Text(
          'Ground value and maximum reaction verified against the documents',
        ),
        onChanged: (v) => setState(() {
          verified = v ?? false;
          result = null;
        }),
      ),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      if (error.isNotEmpty) _results([_R(error, 3)]),
      if (r != null)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Pressure: ${_f(r.values['pressurePa']! / 1000)} kPa'),
                Text('Provided area: ${_f(r.values['providedAreaM2']!)} m2'),
                if (r.values.containsKey('requiredAreaM2'))
                  Text(
                    'Required bearing area: ${_f(r.values['requiredAreaM2']!)} m2',
                  ),
                if (r.values.containsKey('utilizationPercent'))
                  Text('Utilization: ${_f(r.values['utilizationPercent']!)}%'),
                const SizedBox(height: 12),
                CalculationDetails(result: r),
              ],
            ),
          ),
        ),
      _note(
        'Bearing-area check only. Mat thickness, bending strength and load spreading require engineering verification.',
      ),
      _note(_disclaimer),
    ]);
  }
}
