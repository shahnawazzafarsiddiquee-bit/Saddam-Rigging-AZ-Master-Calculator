import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'hardware_selector.dart';
import 'synthetic_sling.dart';

double _n(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
String _f(double x, [int d = 2]) => x.toStringAsFixed(d);
double _rad(double deg) => deg * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;

class _R {
  final String t;
  final int lvl; // 0=normal, 1=green, 2=orange, 3=red
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
                  child: Text(r.t,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _col(r.lvl))),
                ))
            .toList(),
      ),
    ),
  );
}

Widget _note(String s) =>
    Padding(padding: const EdgeInsets.only(top: 10), child: Text(s, style: const TextStyle(color: Colors.white54, fontSize: 13)));

Widget _page(String title, List<Widget> children) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: children),
    ),
  );
}

const String _disc =
    'Ye sirf estimate hain. Final decision lift plan aur competent person ke hisaab se lo.';

// ─────────────────────────────────────────────
//  HUB
// ─────────────────────────────────────────────
class AdvancedCalculatorsHub extends StatelessWidget {
  const AdvancedCalculatorsHub({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String sub, Widget page) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.navy,
            child: Icon(icon, color: AppColors.safetyOrange),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        ),
      );
    }

    return _page('Advanced Calculators', [
      const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Text(
          'Ye calculators advanced aur special lift scenarios ke liye hain.',
          style: TextStyle(color: Colors.white70),
        ),
      ),
      tile(Icons.double_arrow, 'Tandem Lift Calculator',
          'Do crane ek saath: load share, angle, hook load',
          const TandemLiftScreen()),
      tile(Icons.horizontal_rule, 'Spreader Beam Calculator',
          'Beam length, pin / lug load, bending moment',
          const SpreaderBeamScreen()),
      tile(Icons.bolt, 'Dynamic / Shock Load Factor',
          'Lift type se dynamic factor aur design load',
          const DynamicLoadScreen()),
      tile(Icons.build_circle, 'Hardware Quick Selector',
          'Web / round / wire / chain: vertical, choker, basket, 1-4 leg',
          const HardwareSelectorScreen()),
      tile(Icons.texture, 'Synthetic Sling Calculator',
          'Web / round sling: EN 1492 capacity, material, temperature, inspection',
          const SyntheticSlingScreen()),
      tile(Icons.balance, 'Multi-Point Lift Planner',
          '3 ya 4 point lift: har point ki load, sling tension',
          const MultiPointLiftScreen()),
      tile(Icons.rotate_right, 'Rigging Torque & Bolt Check',
          'Bolt size, torque, clamping force for rigging pads',
          const BoltTorqueScreen()),
      _note(_disc),
    ]);
  }
}

// ─────────────────────────────────────────────
//  1. TANDEM LIFT
// ─────────────────────────────────────────────
class TandemLiftScreen extends StatefulWidget {
  const TandemLiftScreen({super.key});
  @override
  State<TandemLiftScreen> createState() => _TandemLiftScreenState();
}

class _TandemLiftScreenState extends State<TandemLiftScreen> {
  final load = TextEditingController();
  final cgA = TextEditingController();
  final span = TextEditingController();
  final hA = TextEditingController(text: '8');
  final hB = TextEditingController(text: '8');
  final capA = TextEditingController();
  final capB = TextEditingController();
  List<_R> out = [];

  void calc() {
    final w = _n(load);
    final s = _n(span);
    final xa = _n(cgA);
    final ha = _n(hA);
    final hb = _n(hB);
    if (w <= 0 || s <= 0 || xa <= 0 || xa >= s || ha <= 0 || hb <= 0) {
      setState(() => out = [const _R('Sabhi fields sahi bharo. CG dono cranes ke beech hona chahiye.', 3)]);
      return;
    }
    // Load share by lever rule
    final rA = w * (s - xa) / s;
    final rB = w * xa / s;
    // Sling angles from vertical
    final angA = _deg(math.atan2(xa, ha));
    final angB = _deg(math.atan2(s - xa, hb));
    final tA = rA / math.cos(_rad(angA));
    final tB = rB / math.cos(_rad(angB));
    final ca = _n(capA);
    final cb = _n(capB);

    int lvA = angA <= 15 ? 1 : (angA <= 25 ? 2 : 3);
    int lvB = angB <= 15 ? 1 : (angB <= 25 ? 2 : 3);

    final res = <_R>[
      _R('— Crane A —'),
      _R('Hook load (vertical): ${_f(rA)} ton'),
      _R('Sling angle from vertical: ${_f(angA, 1)} deg', lvA),
      _R('Sling tension: ${_f(tA)} ton'),
      if (ca > 0)
        _R('Utilization: ${_f(rA / ca * 100, 0)}% (${_f(rA)} / ${_f(ca)} ton)',
            rA / ca <= 0.75 ? 1 : (rA / ca <= 0.9 ? 2 : 3)),
      _R('— Crane B —'),
      _R('Hook load (vertical): ${_f(rB)} ton'),
      _R('Sling angle from vertical: ${_f(angB, 1)} deg', lvB),
      _R('Sling tension: ${_f(tB)} ton'),
      if (cb > 0)
        _R('Utilization: ${_f(rB / cb * 100, 0)}% (${_f(rB)} / ${_f(cb)} ton)',
            rB / cb <= 0.75 ? 1 : (rB / cb <= 0.9 ? 2 : 3)),
      _R('— Tandem Notes —'),
      _R('CG shift: A par ${_f(rA / w * 100, 0)}%, B par ${_f(rB / w * 100, 0)}%'),
    ];
    if (angA > 25 || angB > 25) {
      res.add(const _R('Sling angle zyada hai: communication aur sync zaruri', 3));
    }
    res.add(const _R('Dono crane operators ek signalman se chalenge', 2));
    setState(() => out = res);
  }

  @override
  void dispose() {
    for (final c in [load, cgA, span, hA, hB, capA, capB]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Tandem Lift Calculator', [
      _field(load, 'Total load weight', suffix: 'ton'),
      _field(span, 'Crane A se Crane B tak ka span', suffix: 'm'),
      _field(cgA, 'CG, Crane A se kitni door', suffix: 'm'),
      const Text('Crane A hook height:', style: TextStyle(color: Colors.white70)),
      _field(hA, 'Crane A: hook height (load top se upar)', suffix: 'm'),
      _field(hB, 'Crane B: hook height (load top se upar)', suffix: 'm'),
      _field(capA, 'Crane A chart capacity (optional)', suffix: 'ton'),
      _field(capB, 'Crane B chart capacity (optional)', suffix: 'ton'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note('Tandem lift me CG offset se bada crane wala zyada uthata hai. Sling angle vertical ke paas rakho (< 15 deg best).'),
      _note(_disc),
    ]);
  }
}

// ─────────────────────────────────────────────
//  2. SPREADER BEAM
// ─────────────────────────────────────────────
class SpreaderBeamScreen extends StatefulWidget {
  const SpreaderBeamScreen({super.key});
  @override
  State<SpreaderBeamScreen> createState() => _SpreaderBeamScreenState();
}

class _SpreaderBeamScreenState extends State<SpreaderBeamScreen> {
  final load = TextEditingController();
  final span = TextEditingController();
  final beamWt = TextEditingController(text: '0');
  final modulus = TextEditingController(); // section modulus cm3
  final yld = TextEditingController(text: '250'); // yield strength MPa
  final pinD = TextEditingController(); // pin diameter mm
  List<_R> out = [];

  void calc() {
    final w = _n(load);
    final L = _n(span);
    final bw = _n(beamWt);
    if (w <= 0 || L <= 0) {
      setState(() => out = [const _R('Load aur span daalo', 3)]);
      return;
    }
    final total = w + bw;
    final reaction = total / 2; // symmetric
    // Bending moment at midspan of spreader beam (distributed from slings = point loads at ends)
    // Actually: slings attach at ends, load hangs from attachment points
    // Compression in beam = sling horizontal component (if slings are angled)
    // For vertical slings: pure compression = 0, but beam carries the loads as strut
    // Real spreader beam: top slings angle in, bottom attachments vertical = compression in beam
    // Compressive load = top sling horizontal component = (W/2) * (span/2) / topHeight
    // Simplified: just show reactions and ask user to check
    final res = <_R>[
      _R('Total hook load (load + beam): ${_f(total)} ton'),
      _R('Har end par reaction: ${_f(reaction)} ton'),
    ];
    final sm = _n(modulus);
    final fy = _n(yld);
    if (sm > 0 && fy > 0) {
      final stress = (reaction * 1000 * 9.81 * L * 1000 / 4) / (sm * 1000); // N/mm2
      final util = stress / fy * 100;
      res.add(_R('Bending stress (approx): ${_f(stress, 1)} MPa'));
      res.add(_R('Yield utilization: ${_f(util, 0)}%',
          util <= 60 ? 1 : (util <= 80 ? 2 : 3)));
      if (util > 100) {
        res.add(const _R('Beam overloaded: bada section lo ya span ghataao', 3));
      } else if (util > 80) {
        res.add(const _R('Utilization high: engineer se verify karo', 2));
      } else {
        res.add(const _R('Beam section OK (standard rigging practice ke hisaab se)', 1));
      }
    } else {
      res.add(const _R('Section modulus aur yield strength daalo stress check ke liye', 2));
    }
    final pd = _n(pinD);
    if (pd > 0) {
      // Single shear pin check: Fy_pin = 0.6 * fy * pi * d^2 / 4 (mm2)
      final shearCap = 0.6 * fy * math.pi * pd * pd / 4 / 9810; // N -> ton
      final lv = reaction <= shearCap ? 1 : 3;
      res.add(_R('Pin shear capacity (${_f(pd, 0)} mm single shear): ${_f(shearCap)} ton', lv));
      if (reaction > shearCap) {
        res.add(const _R('Pin overloaded: bada pin ya double shear use karo', 3));
      }
    } else {
      res.add(const _R('Pin diameter daalo pin check ke liye', 0));
    }
    setState(() => out = res);
  }

  @override
  void dispose() {
    for (final c in [load, span, beamWt, modulus, yld, pinD]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Spreader Beam Calculator', [
      _field(load, 'Load weight', suffix: 'ton'),
      _field(span, 'Beam span (attachment points ke beech)', suffix: 'm'),
      _field(beamWt, 'Beam khud ka weight', suffix: 'ton'),
      const Divider(),
      const Text('Optional – Section Check', style: TextStyle(fontWeight: FontWeight.bold)),
      _field(modulus, 'Section modulus (Z)', suffix: 'cm³'),
      _field(yld, 'Yield strength (Fy)', suffix: 'MPa'),
      _field(pinD, 'Pin diameter', suffix: 'mm'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note('Spreader beam me compression load aati hai upar wali slings ke angle se. Beam ka certified WLL / test certificate hona chahiye.'),
      _note(_disc),
    ]);
  }
}

// ─────────────────────────────────────────────
//  3. DYNAMIC / SHOCK LOAD FACTOR
// ─────────────────────────────────────────────
class DynamicLoadScreen extends StatefulWidget {
  const DynamicLoadScreen({super.key});
  @override
  State<DynamicLoadScreen> createState() => _DynamicLoadScreenState();
}

class _DynamicLoadScreenState extends State<DynamicLoadScreen> {
  final staticLoad = TextEditingController();
  int liftType = 0; // 0=slow, 1=normal, 2=fast, 3=shock
  List<_R> out = [];

  static const List<String> typeLabels = [
    'Slow / controlled (0.5 m/min)',
    'Normal crane speed (1-3 m/min)',
    'Fast hoist (> 3 m/min)',
    'Shock / sudden load',
  ];
  static const List<double> daf = [1.10, 1.25, 1.50, 2.00];
  static const List<int> dafLvl = [1, 1, 2, 3];

  void calc() {
    final sl = _n(staticLoad);
    if (sl <= 0) {
      setState(() => out = [const _R('Static load daalo', 3)]);
      return;
    }
    final f = daf[liftType];
    final design = sl * f;
    setState(() => out = [
          _R('Static load: ${_f(sl)} ton'),
          _R('Dynamic amplification factor (DAF): ${_f(f)}x', dafLvl[liftType]),
          _R('Design load: ${_f(design)} ton', dafLvl[liftType]),
          _R('Rigging aur crane is design load ke liye rated hona chahiye', dafLvl[liftType]),
          if (liftType >= 2)
            const _R('Fast ya shock lift: engineer se check karo, load chart utilization < 75% rakho', 3),
        ]);
  }

  @override
  void dispose() {
    staticLoad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Dynamic / Shock Load Factor', [
      _field(staticLoad, 'Static / rated load', suffix: 'ton'),
      const Text('Lift type select karo:', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 8),
      ...List.generate(typeLabels.length, (i) => RadioListTile<int>(
            value: i,
            groupValue: liftType,
            title: Text(typeLabels[i]),
            onChanged: (v) => setState(() => liftType = v!),
          )),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note('DAF values: AS 1418 / ASME B30 / EN 13001 standard se liye hain. Offshore lifts me zyada factor use hota hai.'),
      _note(_disc),
    ]);
  }
}

// ─────────────────────────────────────────────
//  5. MULTI-POINT LIFT PLANNER (3 or 4 point)
// ─────────────────────────────────────────────
class MultiPointLiftScreen extends StatefulWidget {
  const MultiPointLiftScreen({super.key});
  @override
  State<MultiPointLiftScreen> createState() => _MultiPointLiftScreenState();
}

class _MultiPointLiftScreenState extends State<MultiPointLiftScreen> {
  int points = 4;
  final load = TextEditingController();
  final cgX = TextEditingController(); // CG x from point 1 (length direction)
  final cgY = TextEditingController(); // CG y from point 1 (width direction)
  final lenAB = TextEditingController(text: '6'); // length A to B
  final widAC = TextEditingController(text: '3'); // width A to C
  final hookH = TextEditingController(text: '5');
  List<_R> out = [];

  void calc() {
    final w = _n(load);
    final L = _n(lenAB);
    final B = _n(widAC);
    final cx = _n(cgX);
    final cy = _n(cgY);
    final hh = _n(hookH);
    if (w <= 0 || L <= 0 || B <= 0 || hh <= 0) {
      setState(() => out = [const _R('Sabhi fields sahi bharo', 3)]);
      return;
    }
    if (points == 4) {
      if (cx <= 0 || cx >= L || cy <= 0 || cy >= B) {
        setState(() => out = [const _R('CG layout ke andar hona chahiye (0 < cx < L, 0 < cy < B)', 3)]);
        return;
      }
      // Load distribution: 4-point by bilinear interpolation
      final rA = w * (L - cx) / L * (B - cy) / B;
      final rB = w * cx / L * (B - cy) / B;
      final rC = w * (L - cx) / L * cy / B;
      final rD = w * cx / L * cy / B;
      final res = <_R>[
        _R('4 Point Load Distribution:'),
        _R('Point A (0,0): ${_f(rA)} ton (${_f(rA / w * 100, 0)}%)', 1),
        _R('Point B (L,0): ${_f(rB)} ton (${_f(rB / w * 100, 0)}%)', 1),
        _R('Point C (0,B): ${_f(rC)} ton (${_f(rC / w * 100, 0)}%)', 1),
        _R('Point D (L,B): ${_f(rD)} ton (${_f(rD / w * 100, 0)}%)', 1),
      ];
      final maxR = [rA, rB, rC, rD].reduce(math.max);
      res.add(_R('Sabse zyada load wala point: ${_f(maxR)} ton', maxR / w > 0.4 ? 2 : 1));
      res.add(_R('Sling size is max load ke hisaab se rakho'));
      setState(() => out = res);
    } else {
      // 3 point: equilateral assumption
      final perPt = w / 3;
      setState(() => out = [
            _R('3 Point symmetric: har point ${_f(perPt)} ton (${_f(100 / 3, 0)}%)', 1),
            const _R('3 point: CG offset hone se load unequal ho sakta hai. Survey karo.', 2),
          ]);
    }
  }

  @override
  void dispose() {
    for (final c in [load, cgX, cgY, lenAB, widAC, hookH]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Multi-Point Lift Planner', [
      _field(load, 'Total load weight', suffix: 'ton'),
      Wrap(
        spacing: 8,
        children: [3, 4]
            .map((n) => ChoiceChip(
                  label: Text('$n Point'),
                  selected: points == n,
                  onSelected: (_) => setState(() => points = n),
                ))
            .toList(),
      ),
      const SizedBox(height: 12),
      _field(lenAB, 'Length (A se B tak)', suffix: 'm'),
      if (points == 4) _field(widAC, 'Width (A se C tak)', suffix: 'm'),
      if (points == 4) _field(cgX, 'CG, length direction mein Point A se', suffix: 'm'),
      if (points == 4) _field(cgY, 'CG, width direction mein Point A se', suffix: 'm'),
      _field(hookH, 'Hook height (load top se upar)', suffix: 'm'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note('A=(0,0), B=(L,0), C=(0,B), D=(L,B). CG actual weight survey se lena chahiye.'),
      _note(_disc),
    ]);
  }
}

// ─────────────────────────────────────────────
//  6. BOLT TORQUE & RIGGING PAD CHECK
// ─────────────────────────────────────────────
class BoltTorqueScreen extends StatefulWidget {
  const BoltTorqueScreen({super.key});
  @override
  State<BoltTorqueScreen> createState() => _BoltTorqueScreenState();
}

class _BoltTorqueScreenState extends State<BoltTorqueScreen> {
  final boltD = TextEditingController(text: '24'); // mm
  final qty = TextEditingController(text: '4');
  final load = TextEditingController(); // ton
  int grade = 1; // 0=4.6, 1=8.8, 2=10.9
  List<_R> out = [];

  static const List<String> gradeLabels = ['Grade 4.6', 'Grade 8.8', 'Grade 10.9'];
  static const List<double> fy = [240.0, 660.0, 940.0]; // MPa yield

  void calc() {
    final d = _n(boltD);
    final n = _n(qty).toInt();
    final w = _n(load);
    if (d <= 0 || n <= 0 || w <= 0) {
      setState(() => out = [const _R('Bolt diameter, quantity aur load daalo', 3)]);
      return;
    }
    final area = math.pi * d * d / 4; // mm2 gross area
    final tensileArea = 0.75 * area; // approx stress area
    final fUlt = fy[grade] / 0.8; // approx UTS
    final proofTon = 0.7 * fUlt * tensileArea * n / 9810; // N -> ton
    final shearCap = 0.6 * fy[grade] * tensileArea * n / 9810;
    final torque = 0.2 * fy[grade] * 0.7 * tensileArea * d / 1000000; // kNm approx single bolt
    final torqueNm = torque * 1000; // Nm

    final util = w / proofTon * 100;
    final res = <_R>[
      _R('Bolt: M${d.toStringAsFixed(0)} x $n nos, ${gradeLabels[grade]}'),
      _R('Total tensile capacity: ${_f(proofTon)} ton', util <= 100 ? 1 : 3),
      _R('Shear capacity: ${_f(shearCap)} ton', w <= shearCap ? 1 : 3),
      _R('Utilization (tension): ${_f(util, 0)}%', util <= 80 ? 1 : (util <= 100 ? 2 : 3)),
      _R('Tightening torque (per bolt, approx): ${_f(torqueNm, 0)} Nm'),
      if (util > 100)
        const _R('Overloaded: zyada bolt ya bada size lagao', 3),
      if (util > 80 && util <= 100)
        const _R('High utilization: engineer se review karo', 2),
    ];
    setState(() => out = res);
  }

  @override
  void dispose() {
    for (final c in [boltD, qty, load]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Bolt Torque & Rigging Pad', [
      _field(boltD, 'Bolt diameter (M-size)', suffix: 'mm'),
      _field(qty, 'Number of bolts'),
      _field(load, 'Rigging load (per pad eye)', suffix: 'ton'),
      const Text('Bolt grade:', style: TextStyle(color: Colors.white70)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: gradeLabels.asMap().entries.map((e) =>
          ChoiceChip(
            label: Text(e.value),
            selected: grade == e.key,
            onSelected: (_) => setState(() => grade = e.key),
          )).toList(),
      ),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note('Ye approximate calculation hai. Structural connection ka final design licensed engineer se karo. Torque accurate wrench se apply karo.'),
      _note(_disc),
    ]);
  }
}
