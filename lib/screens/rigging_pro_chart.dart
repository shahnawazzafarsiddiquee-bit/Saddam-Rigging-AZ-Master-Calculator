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
  int revision=0;
  List<_R> out = [];

  @override
  void initState() {
    super.initState();
    _load();
    rad.addListener(_invalidate);load.addListener(_invalidate);
  }

  void _invalidate(){revision++;if(mounted)setState(()=>out=[]);}
  Future<void> _load() async {
    _invalidate();
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
    _invalidate();
    final request=revision;
    final bl = await ProDb.booms(c);
    final nt = await ProDb.note(c);
    if (!mounted||request!=revision) return;
    setState(() {
      crane = c;
      booms = bl;
      boom = bl.isEmpty ? null : bl.first;
      note = nt;
      out = [];
    });
  }

  Future<void> _lookup() async {
    final request=++revision;
    final c = crane;
    final b = boom;
    final r = _n(rad);
    final w = _n(load);
    if (c == null || b == null || !r.isFinite || !w.isFinite || r <= 0 || w <= 0) {
      setState(() =>
          out = [const _R('Crane, boom, radius aur total load daalo', 3)]);
      return;
    }
    final hit = await ProDb.lookup(c, b, r);
    if (!mounted||request!=revision) return;
    if (hit == null) {
      setState(() => out = [
            const _R(
                'No verified exact row. Review original chart, configuration and source metadata.',
                3)
          ]);
      return;
    }
    final u = w / hit.capacity * 100;
    final lv = u > 100 ? 3 : 2;
    final res = <_R>[
      _R('Exact chart radius: ${_f(hit.radius, 1)} m'),
      _R('Capacity: ${_f(hit.capacity)} ton'),
      _R('Total load: ${_f(w)} ton'),
      _R('Utilization: ${_f(u, 0)}%', lv),
    ];
    if (u > 100) {
      res.add(const _R('OVERLOAD: ye lift mat karo', 3));
    } else {
      res.add(const _R('Capacity comparison only. Verify actual setup, chart deductions and every required radius. Authorized personnel must approve the lift.',2));
    }
    setState(() => out = res);
  }

  Future<void> _delete() async {
    final c = crane;
    if (c == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw chart?'),
        content: Text('$c will be withdrawn from active selection. Its rows and metadata remain in chart history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nahi')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok == true) {
      await ProDb.deleteCrane(c);
      crane = null;
      await _load();
    }
  }

  Future<void> _history()async{
    final rows=await ProDb.chartHistory();if(!mounted)return;
    await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(title:const Text('Chart revision history'),content:SizedBox(width:500,child:ListView(shrinkWrap:true,children:[
      if(rows.isEmpty)const Text('No archived revisions.'),
      for(final r in rows)ListTile(title:Text('${r['title']}'),subtitle:Text('${r['createdAt']}'),onTap:()=>showDialog<void>(context:ctx,builder:(detail)=>AlertDialog(title:const Text('Archived original rows'),content:SingleChildScrollView(child:SelectableText('${r['detailsJson']}')),actions:[TextButton(onPressed:()=>Navigator.pop(detail),child:const Text('Close'))])))
    ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Close'))]));
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
      OutlinedButton(onPressed:_history,child:const Text('Chart revision history')),
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
        if (note.isNotEmpty) _note(CraneChartRules.describe(note)),
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
                revision++;
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
            child: const Text('Withdraw active chart')),
        _note(
            'Only exact boom/radius rows from verified source metadata are used. No rounding, interpolation or universal critical-lift threshold.'),
      ] else if (!loading) ...[
        _note('Abhi koi chart save nahi hai. "Naya chart" dabao.'),
      ],
      _note(_disclaimer),
    ]);
  }
}
