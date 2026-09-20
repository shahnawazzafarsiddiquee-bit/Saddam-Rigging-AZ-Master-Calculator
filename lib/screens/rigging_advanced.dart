import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'rigging_pro.dart';

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
            .map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    r.t,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _col(r.lvl),
                    ),
                  ),
                ))
            .toList(),
      ),
    ),
  );
}

Widget _note(String s) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(s),
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
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => page)),
        ),
      );
    }

    return _page('Advanced Rigging', [
      tile(Icons.straighten, 'Sling Length & Angle',
          'Container / pipe: sling length, angle, size',
          const SlingLengthScreen()),
      tile(Icons.precision_manufacturing, 'Crane Boom & Capacity',
          'Boom length, angle, utilization %', const CraneBoomScreen()),
      tile(Icons.air, 'Wind Check', 'Wind force on load, go / no-go',
          const WindCheckScreen()),
      tile(Icons.compare_arrows, 'CG Load Share',
          '2 point lift: load per point & sling', const CgShareScreen()),
      tile(Icons.terrain, 'Ground Bearing', 'Outrigger mat pressure',
          const GroundBearingScreen()),
      tile(Icons.handyman, 'Pro Tools', 'Crane chart, lift plan PDF, capacity, certificates', const ProToolsScreen()),
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
    8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36, 40, 44, 48, 52
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
      setState(() => out = [
            const _R('Load, length aur angle sahi daalo (4 leg me width bhi)', 3)
          ]);
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
      res.add(const _R(
          'Angle 45 se kam: KHATRA. Sling lambi karo ya spreader beam lo', 3));
    }
    if (pick > 0) {
      res.add(_R(
          'Wire rope sling (6x36 IWRC) kam se kam ${_f(pick, 0)} mm (WLL approx ${_f(pick * pick / 100)} ton)',
          1));
    } else {
      res.add(const _R(
          '52 mm se bada chahiye: spreader beam ya engineer se poochho', 3));
    }
    if (legs == 4) {
      res.add(const _R(
          '4 leg me safe side ke liye sirf 2 leg carry maane hain', 2));
    }
    if (av > 0) {
      if (av <= run) {
        res.add(const _R(
            'Aapki sling bahut chhoti hai (leg length horizontal doori se badi honi chahiye)',
            3));
      } else {
        final ta = math.acos(run / av);
        final tt = w / (2 * math.sin(ta));
        final lv = ta >= _rad(60) ? 1 : (ta >= _rad(45) ? 2 : 3);
        res.add(_R(
            'Aapki ${_f(av)} m sling se angle: ${_f(_deg(ta), 1)} deg, load per leg ${_f(tt)} ton',
            lv));
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
      if (legs == 4)
        _field(wid, 'Lifting points ke beech width', suffix: 'm'),
      _field(ang, 'Target sling angle (horizontal se)', suffix: 'deg'),
      _field(avail, 'Aapke paas sling ki length (optional)', suffix: 'm'),
      Wrap(
        spacing: 8,
        children: [2, 4]
            .map((n) => ChoiceChip(
                  label: Text('$n leg'),
                  selected: legs == n,
                  onSelected: (_) => setState(() => legs = n),
                ))
            .toList(),
      ),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note(
          'Container: 12 m x 2.44 m, 4 leg. Pipe: 2 leg, length = dono sling points ke beech doori. Wire rope size rule: WLL = d x d / 100 ton (estimate).'),
      _note(_disclaimer),
    ]);
  }
}

// ---------------- Crane boom & capacity ----------------
class CraneBoomScreen extends StatefulWidget {
  const CraneBoomScreen({super.key});
  @override
  State<CraneBoomScreen> createState() => _CraneBoomScreenState();
}

class _CraneBoomScreenState extends State<CraneBoomScreen> {
  final load = TextEditingController();
  final rig = TextEditingController(text: '0.5');
  final rad = TextEditingController();
  final land = TextEditingController(text: '10');
  final lht = TextEditingController(text: '2');
  final slh = TextEditingController(text: '3');
  final clr = TextEditingController(text: '3');
  final off = TextEditingController(text: '1.5');
  final foot = TextEditingController(text: '2');
  final chart = TextEditingController();
  List<_R> out = [];

  void calc() {
    final w = _n(load);
    final rg = _n(rig);
    final r = _n(rad);
    final x = r - _n(off);
    final tip = _n(land) + _n(lht) + _n(slh) + _n(clr);
    final y = tip - _n(foot);
    if (w <= 0 || r <= 0 || x <= 0 || y <= 0) {
      setState(() => out = [
            const _R('Load, radius aur heights sahi daalo', 3)
          ]);
      return;
    }
    final boom = math.sqrt(x * x + y * y);
    final angle = _deg(math.atan2(y, x));
    final total = w + rg;
    final cap = _n(chart);
    final res = <_R>[
      _R('Boom tip height chahiye: ${_f(tip)} m'),
      _R('Minimum boom length: ${_f(boom)} m'),
      _R('Boom angle: ${_f(angle, 1)} deg',
          (angle < 30 || angle > 80) ? 2 : 1),
      _R('Total hook load: ${_f(total)} ton (load + rigging + block)'),
    ];
    if (angle < 30) {
      res.add(const _R('Boom angle kam hai: chart me allowed hai ya nahi dekho', 2));
    }
    if (angle > 80) {
      res.add(const _R('Boom angle bahut zyada: peeche girne ka risk', 3));
    }
    if (cap > 0) {
      final u = total / cap * 100;
      final lv = u <= 75 ? 1 : (u <= 85 ? 2 : 3);
      res.add(_R(
          'Chart capacity ${_f(cap)} ton par utilization: ${_f(u, 0)}%', lv));
      if (u > 100) {
        res.add(const _R('OVERLOAD: ye lift mat karo', 3));
      } else if (u > 85) {
        res.add(const _R(
            '85% se upar: critical lift, engineer aur lift plan zaruri', 3));
      } else if (u > 75) {
        res.add(const _R('75-85%: savdhani, critical lift check karo', 2));
      } else {
        res.add(const _R('75% ke andar: theek', 1));
      }
    } else {
      res.add(const _R(
          'Load chart se is radius aur boom length ki capacity daalke utilization check karo',
          2));
    }
    setState(() => out = res);
  }

  @override
  void dispose() {
    load.dispose();
    rig.dispose();
    rad.dispose();
    land.dispose();
    lht.dispose();
    slh.dispose();
    clr.dispose();
    off.dispose();
    foot.dispose();
    chart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Crane Boom & Capacity', [
      _field(load, 'Load weight', suffix: 'ton'),
      _field(rig, 'Rigging + hook block weight', suffix: 'ton'),
      _field(rad, 'Working radius (slew centre se load tak)', suffix: 'm'),
      _field(land, 'Load ko kitni oonchai par rakhna hai', suffix: 'm'),
      _field(lht, 'Load ki apni height', suffix: 'm'),
      _field(slh, 'Sling height (hook se load top tak)', suffix: 'm'),
      _field(clr, 'Boom tip se hook tak clearance', suffix: 'm'),
      _field(off, 'Boom foot offset (slew centre se)', suffix: 'm'),
      _field(foot, 'Boom foot height (ground se)', suffix: 'm'),
      _field(chart, 'Load chart capacity (optional)', suffix: 'ton'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note(
          'Ye geometry se minimum boom length hai. Chart me agli available boom length lo aur wahi ki capacity daalo. Jib, boom bend aur outrigger setting shamil nahi.'),
      _note(_disclaimer),
    ]);
  }
}

// ---------------- Wind check ----------------
class WindCheckScreen extends StatefulWidget {
  const WindCheckScreen({super.key});
  @override
  State<WindCheckScreen> createState() => _WindCheckScreenState();
}

class _WindCheckScreenState extends State<WindCheckScreen> {
  final spd = TextEditingController();
  final ar = TextEditingController();
  final load = TextEditingController();
  final cdc = TextEditingController(text: '1.2');
  List<_R> out = [];

  void calc() {
    final kmh = _n(spd);
    if (kmh <= 0) {
      setState(() => out = [const _R('Wind speed daalo', 3)]);
      return;
    }
    final v = kmh / 3.6;
    final res = <_R>[_R('Wind speed: ${_f(v, 1)} m/s')];
    if (kmh <= 20) {
      res.add(const _R('20 km/h tak: normal, lifting theek', 1));
    } else if (kmh <= 32) {
      res.add(const _R(
          '20-32 km/h: savdhani, tag line lagao, badi surface wale load me risk',
          2));
    } else {
      res.add(const _R(
          '32 km/h se upar: lifting band karo (crane manual ka limit dekho)',
          3));
    }
    final area = _n(ar);
    final w = _n(load);
    final cd = _n(cdc);
    if (area > 0 && w > 0 && cd > 0) {
      final f = 0.5 * 1.225 * v * v * cd * area;
      final kgf = f / 9.81;
      final pct = kgf / (w * 1000) * 100;
      final sway = _deg(math.atan(kgf / (w * 1000)));
      res.add(_R('Load par wind force: ${_f(kgf, 0)} kgf'));
      res.add(_R('Load weight ka ${_f(pct, 1)}%'));
      res.add(_R('Load ka sway angle approx: ${_f(sway, 1)} deg',
          pct > 10 ? 2 : 1));
      if (pct > 10) {
        res.add(const _R(
            'Wind force zyada: load jhulega, radius badh sakta hai. Tag line zaruri', 2));
      }
    } else {
      res.add(const _R(
          'Wind force ke liye load area aur weight bhi daalo', 2));
    }
    setState(() => out = res);
  }

  @override
  void dispose() {
    spd.dispose();
    ar.dispose();
    load.dispose();
    cdc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Wind Check', [
      _field(spd, 'Wind speed', suffix: 'km/h'),
      _field(ar, 'Load ka hawa wala area (length x height)', suffix: 'm2'),
      _field(load, 'Load weight', suffix: 'ton'),
      _field(cdc, 'Drag factor (flat surface ~1.2)'),
      ElevatedButton(onPressed: calc, child: const Text('Check')),
      _results(out),
      _note(
          'Force = 0.5 x 1.225 x v x v x Cd x Area. Gust isse zyada ho sakta hai, isliye margin rakho.'),
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
      setState(() => out = [
            const _R(
                'CG dono lifting points ke beech me nahi hai: load palat sakta hai. Points badlo', 3)
          ]);
      return;
    }
    final ra = w * (s - x) / s;
    final rb = w * x / s;
    final aA = math.atan2(h, x);
    final aB = math.atan2(h, s - x);
    final tA = ra / math.sin(aA);
    final tB = rb / math.sin(aB);
    final lA = math.sqrt(x * x + h * h);
    final lB = math.sqrt((s - x) * (s - x) + h * h);
    setState(() => out = [
          _R('Point A par load: ${_f(ra)} ton'),
          _R('Point B par load: ${_f(rb)} ton'),
          _R('Sling A: ${_f(lA)} m, angle ${_f(_deg(aA), 1)} deg, tension ${_f(tA)} ton',
              _lv(aA)),
          _R('Sling B: ${_f(lB)} m, angle ${_f(_deg(aB), 1)} deg, tension ${_f(tB)} ton',
              _lv(aB)),
          _R('Hook / master link point A se ${_f(x)} m par, CG ke seedha upar rakho'),
        ]);
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
          'CG jis point ke paas ho, us par zyada load aur us sling ki tension zyada. Dono sling ki tension ke hisaab se size lo.'),
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
  final rxn = TextEditingController();
  final ml = TextEditingController();
  final mw = TextEditingController();
  final sb = TextEditingController();
  List<_R> out = [];

  void calc() {
    final rx = _n(rxn);
    final l = _n(ml);
    final wd = _n(mw);
    final q = _n(sb);
    if (rx <= 0 || l <= 0 || wd <= 0) {
      setState(() => out = [
            const _R('Outrigger reaction aur mat size daalo', 3)
          ]);
      return;
    }
    final p = rx / (l * wd);
    final res = <_R>[
      _R('Mat par pressure: ${_f(p)} ton/m2 (${_f(p * 9.81, 1)} kPa)'),
    ];
    if (q > 0) {
      final ratio = p / q * 100;
      res.add(_R('Soil capacity ka ${_f(ratio, 0)}% use ho raha hai',
          ratio <= 100 ? 1 : 3));
      res.add(_R('Kam se kam mat area chahiye: ${_f(rx / q)} m2'));
      if (ratio > 100) {
        res.add(const _R('Mat chhota hai: bada mat ya cribbing lagao', 3));
      }
    } else {
      res.add(const _R(
          'Soil allowable bearing daalo (soil report / site engineer se)', 2));
    }
    setState(() => out = res);
  }

  @override
  void dispose() {
    rxn.dispose();
    ml.dispose();
    mw.dispose();
    sb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Ground Bearing', [
      _field(rxn, 'Outrigger reaction (crane manual / chart se)', suffix: 'ton'),
      _field(ml, 'Mat length', suffix: 'm'),
      _field(mw, 'Mat width', suffix: 'm'),
      _field(sb, 'Soil allowable bearing (soil report se)', suffix: 'ton/m2'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note(
          'Outrigger par max load usually crane ke weight aur load dono se aata hai. Exact value crane manual me dekho.'),
      _note(_disclaimer),
    ]);
  }
}
