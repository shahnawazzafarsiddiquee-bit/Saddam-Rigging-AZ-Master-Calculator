part of 'rigging_pro.dart';

class _Pt {
  final double r;
  final double c;
  _Pt(this.r, this.c);
}

class _Cand {
  final String crane;
  final double boom;
  final double cap;
  final double radius;
  final double util;
  _Cand(this.crane, this.boom, this.cap, this.radius, this.util);
}

const List<List<double>> _shackleList = [
  [13, 2.0], [16, 3.25], [19, 4.75], [22, 6.5], [25, 8.5], [29, 9.5],
  [32, 12.0], [35, 13.5], [38, 17.0], [45, 25.0], [51, 35.0],
];

String _shackleText(double ton) {
  for (final s in _shackleList) {
    if (s[1] >= ton) {
      return 'approx ${_f(s[0], 0)} mm (WLL ${_f(s[1])} ton) ya bada';
    }
  }
  return '35 ton se upar: engineer se poochho';
}

class CraneFinderScreen extends StatefulWidget {
  const CraneFinderScreen({super.key});
  @override
  State<CraneFinderScreen> createState() => _CraneFinderScreenState();
}

class _CraneFinderScreenState extends State<CraneFinderScreen> {
  final load = TextEditingController();
  final rig = TextEditingController(text: '0.5');
  final rad = TextEditingController();
  final lim = TextEditingController(text: '75');
  int _seq = 0;
  List<_R> out = [];

  Future<void> _find() async {
    final my = ++_seq;
    final w0 = _n(load);
    if (w0 <= 0) {
      if (mounted) setState(() => out = []);
      return;
    }
    final w = w0 + _n(rig);
    final r = _n(rad);
    final lm = _n(lim) > 0 ? _n(lim) : 75.0;
    final cands = <_Cand>[];
    int craneCount = 0;
    try {
      final cranes = await ProDb.cranes();
      craneCount = cranes.length;
      for (final c in cranes) {
        final rows = await ProDb.allRows(c);
        final byBoom = <double, List<_Pt>>{};
        for (final row in rows) {
          final b = (row['boom'] as num).toDouble();
          byBoom.putIfAbsent(b, () => <_Pt>[]).add(_Pt(
              (row['radius'] as num).toDouble(),
              (row['capacity'] as num).toDouble()));
        }
        for (final e in byBoom.entries) {
          final pts = e.value;
          pts.sort((a, b) => a.r.compareTo(b.r));
          if (r > 0) {
            _Pt? hit;
            for (final p in pts) {
              if (p.r >= r) {
                hit = p;
                break;
              }
            }
            if (hit == null) continue;
            cands.add(_Cand(c, e.key, hit.c, hit.r, w / hit.c * 100));
          } else {
            double maxR = 0;
            double capAt = 0;
            for (final p in pts) {
              if (p.c * lm / 100 >= w && p.r > maxR) {
                maxR = p.r;
                capAt = p.c;
              }
            }
            if (maxR > 0) {
              cands.add(_Cand(c, e.key, capAt, maxR, w / capAt * 100));
            }
          }
        }
      }
    } catch (e) {
      if (!mounted || my != _seq) return;
      setState(() => out = [_R('Database error: $e', 3)]);
      return;
    }
    if (!mounted || my != _seq) return;

    final radTxt = r > 0 ? ' | radius ${_f(r, 1)} m' : '';
    final res = <_R>[
      _R('Total hook load: ${_f(w)} ton | limit ${_f(lm, 0)}%$radTxt'),
    ];
    if (craneCount == 0) {
      res.add(const _R(
          'Abhi koi crane chart save nahi hai. Crane Load Chart me PDF / photo se import karo',
          3));
    } else if (cands.isEmpty) {
      res.add(_R(
          r > 0
              ? 'Saved charts me is radius par koi crane / boom ye load nahi utha sakta'
              : 'Saved charts me is load ko ${_f(lm, 0)}% ke andar koi option nahi',
          3));
    } else if (r > 0) {
      final ok = cands.where((c) => c.util <= 100).toList();
      final over = cands.length - ok.length;
      ok.sort((a, b) {
        final pa = a.util <= lm ? 0 : 1;
        final pb = b.util <= lm ? 0 : 1;
        if (pa != pb) return pa - pb;
        if (pa == 0) return a.boom.compareTo(b.boom);
        return a.util.compareTo(b.util);
      });
      if (ok.isEmpty) {
        res.add(const _R(
            'Is radius par koi bhi crane / boom ye load nahi utha sakta', 3));
      } else {
        final top = ok.first;
        res.add(_R(
            'Best: ${top.crane}, boom ${_f(top.boom, 1)} m -> ${_f(top.util, 0)}%',
            top.util <= lm ? 1 : 2));
        final show = ok.length > 12 ? 12 : ok.length;
        for (int i = 0; i < show; i++) {
          final c = ok[i];
          res.add(_R(
              '${c.crane} | boom ${_f(c.boom, 1)} m | ${_f(c.cap)} t @ ${_f(c.radius, 1)} m | ${_f(c.util, 0)}%',
              c.util <= lm ? 1 : 2));
        }
        if (ok.length > show) {
          res.add(_R('... aur ${ok.length - show} option'));
        }
        if (over > 0) {
          res.add(_R('$over option overload (100% se upar) chhupaye'));
        }
      }
    } else {
      cands.sort((a, b) {
        final x = a.boom.compareTo(b.boom);
        return x != 0 ? x : a.crane.compareTo(b.crane);
      });
      final show = cands.length > 12 ? 12 : cands.length;
      for (int i = 0; i < show; i++) {
        final c = cands[i];
        res.add(_R(
            '${c.crane} | boom ${_f(c.boom, 1)} m | max radius ${_f(c.radius, 1)} m (cap ${_f(c.cap)} t, ${_f(c.util, 0)}%)',
            1));
      }
      if (cands.length > show) {
        res.add(_R('... aur ${cands.length - show} option'));
      }
    }

    final t = w0 / (2 * math.sin(_rad(60)));
    final rope = _pickRope(t);
    res.add(const _R('--- Rigging suggestion (2 leg, 60 deg) ---'));
    res.add(_R('Load per sling leg: ${_f(t)} ton'));
    res.add(_R(
        rope > 0
            ? 'Wire rope sling kam se kam: ${_f(rope, 0)} mm (6x36 IWRC)'
            : '52 mm se bada chahiye: spreader beam / engineer',
        rope > 0 ? 1 : 3));
    res.add(_R('Sling end shackle: ${_shackleText(t)}'));
    res.add(_R('Hook shackle: ${_shackleText(w)}'));
    res.add(const _R('Ye estimate hai. Sling tag aur load chart se verify karo', 2));
    setState(() => out = res);
  }

  Widget _live(TextEditingController c, String label, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => _find(),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    load.dispose();
    rig.dispose();
    rad.dispose();
    lim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Crane Finder (auto)', [
      _live(load, 'Load weight', 'ton'),
      _live(rig, 'Rigging + hook block weight', 'ton'),
      _live(rad, 'Working radius (khali = max radius batao)', 'm'),
      _live(lim, 'Utilization limit', '%'),
      FilledButton(onPressed: _find, child: const Text('Crane dhundo')),
      _results(out),
      _note(
          'Sirf aapke saved charts me se dhundta hai. Radius chart ke agle bade value par dekha jata hai (safe side). Pehle Crane Load Chart me chart import karo.'),
      _note(_disclaimer),
    ]);
  }
}
