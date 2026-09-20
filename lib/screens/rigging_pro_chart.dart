part of 'rigging_pro.dart';

class CraneChartScreen extends StatefulWidget {
  const CraneChartScreen({super.key});
  @override
  State<CraneChartScreen> createState() => _CraneChartScreenState();
}

class _CraneChartScreenState extends State<CraneChartScreen> {
  final rad = TextEditingController();
  final load = TextEditingController();
  List<String> cranes = [];
  List<double> booms = [];
  String? crane;
  double? boom;
  String note = '';
  String err = '';
  bool loading = true;
  List<_R> out = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ProDb.cranes();
      String? sel = crane;
      if (sel == null || !list.contains(sel)) {
        sel = list.isEmpty ? null : list.first;
      }
      List<double> bl = [];
      String nt = '';
      if (sel != null) {
        bl = await ProDb.booms(sel);
        nt = await ProDb.note(sel);
      }
      if (!mounted) return;
      setState(() {
        cranes = list;
        crane = sel;
        booms = bl;
        boom = bl.isEmpty ? null : (bl.contains(boom) ? boom : bl.first);
        note = nt;
        loading = false;
        err = '';
        out = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        err = 'Database error: $e';
      });
    }
  }

  Future<void> _pick(String c) async {
    final bl = await ProDb.booms(c);
    final nt = await ProDb.note(c);
    if (!mounted) return;
    setState(() {
      crane = c;
      booms = bl;
      boom = bl.isEmpty ? null : bl.first;
      note = nt;
      out = [];
    });
  }

  Future<void> _lookup() async {
    final c = crane;
    final b = boom;
    final r = _n(rad);
    final w = _n(load);
    if (c == null || b == null || r <= 0 || w <= 0) {
      setState(() =>
          out = [const _R('Crane, boom, radius aur total load daalo', 3)]);
      return;
    }
    final hit = await ProDb.lookup(c, b, r);
    if (!mounted) return;
    if (hit == null) {
      setState(() => out = [
            const _R(
                'Is radius par chart me capacity nahi hai (chart se bahar). Lift mat karo',
                3)
          ]);
      return;
    }
    final u = w / hit.capacity * 100;
    final lv = u <= 75 ? 1 : (u <= 85 ? 2 : 3);
    final res = <_R>[
      _R('Chart radius (agla bada): ${_f(hit.radius, 1)} m'),
      _R('Capacity: ${_f(hit.capacity)} ton'),
      _R('Total load: ${_f(w)} ton'),
      _R('Utilization: ${_f(u, 0)}%', lv),
    ];
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
    setState(() => out = res);
  }

  Future<void> _delete() async {
    final c = crane;
    if (c == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chart delete?'),
        content: Text('$c ka poora chart delete hoga.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nahi')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Haan, delete')),
        ],
      ),
    );
    if (ok == true) {
      await ProDb.deleteCrane(c);
      crane = null;
      await _load();
    }
  }

  Future<void> _edit(String? existing) async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChartEditScreen(existing: existing)));
    _load();
  }

  @override
  void dispose() {
    rad.dispose();
    load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Crane Load Chart', [
      if (loading) const Center(child: CircularProgressIndicator()),
      if (err.isNotEmpty) _results([_R(err, 3)]),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('Naya chart'),
            ),
          ),
          if (crane != null) const SizedBox(width: 8),
          if (crane != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _edit(crane),
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
              ),
            ),
        ],
      ),
      if (cranes.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Text('Crane:'),
        DropdownButton<String>(
          value: crane,
          isExpanded: true,
          items: cranes
              .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) _pick(v);
          },
        ),
        if (note.isNotEmpty) _note('Chart config: $note'),
        const SizedBox(height: 8),
        const Text('Boom length (m):'),
        DropdownButton<double>(
          value: boom,
          isExpanded: true,
          items: booms
              .map((b) =>
                  DropdownMenuItem<double>(value: b, child: Text(_f(b, 1))))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                boom = v;
                out = [];
              });
            }
          },
        ),
        const SizedBox(height: 12),
        _field(rad, 'Working radius', suffix: 'm'),
        _field(load, 'Total hook load (load + rigging + block)',
            suffix: 'ton'),
        ElevatedButton(onPressed: _lookup, child: const Text('Capacity check')),
        _results(out),
        TextButton(
            onPressed: _delete,
            child: const Text('Is crane ka chart delete karo')),
        _note(
            'Radius ka agla bada chart value liya jata hai (safe side). Boom length chart wali hi chuno.'),
      ] else if (!loading) ...[
        _note('Abhi koi chart save nahi hai. "Naya chart" dabao.'),
      ],
      _note(_disclaimer),
    ]);
  }
}
