part of 'rigging_pro.dart';

class LiftPlanPdfScreen extends StatefulWidget {
  const LiftPlanPdfScreen({super.key});
  @override
  State<LiftPlanPdfScreen> createState() => _LiftPlanPdfScreenState();
}

class _LiftPlanPdfScreenState extends State<LiftPlanPdfScreen> {
  final project = TextEditingController();
  final site = TextEditingController();
  final desc = TextEditingController();
  final sup = TextEditingController();
  final rigger = TextEditingController();
  final oper = TextEditingController();
  final wt = TextEditingController();
  final rig = TextEditingController(text: '0.5');
  final len = TextEditingController(text: '12');
  final wid = TextEditingController(text: '2.44');
  final ang = TextEditingController(text: '60');
  final rad = TextEditingController();
  final cap = TextEditingController();
  final wind = TextEditingController();
  int legs = 4;
  List<String> cranes = [];
  List<double> booms = [];
  String? crane;
  double? boom;
  List<_R> out = [];

  @override
  void initState() {
    super.initState();
    _loadCranes();
  }

  Future<void> _loadCranes() async {
    try {
      final list = await ProDb.cranes();
      final c = list.isEmpty ? null : list.first;
      final bl = c == null ? <double>[] : await ProDb.booms(c);
      if (!mounted) return;
      setState(() {
        cranes = list;
        crane = c;
        booms = bl;
        boom = bl.isEmpty ? null : bl.first;
      });
    } catch (_) {}
  }

  Future<void> _pickCrane(String? c) async {
    if (c == null) {
      setState(() {
        crane = null;
        booms = [];
        boom = null;
      });
      return;
    }
    final bl = await ProDb.booms(c);
    if (!mounted) return;
    setState(() {
      crane = c;
      booms = bl;
      boom = bl.isEmpty ? null : bl.first;
    });
  }

  Future<void> _generate() async {
    final w = _n(wt);
    final rg = _n(rig);
    final r = _n(rad);
    final a = _n(len);
    final b = _n(wid);
    final th = _n(ang);
    final kmh = _n(wind);
    if (w <= 0 ||
        r <= 0 ||
        a <= 0 ||
        th <= 0 ||
        th >= 90 ||
        (legs == 4 && b <= 0)) {
      setState(() => out =
          [const _R('Load, radius, sling length aur angle sahi daalo', 3)]);
      return;
    }
    final warns = <String>[];
    final total = w + rg;

    double capV = 0;
    String capSrc = 'Manual entry';
    final c = crane;
    final bm = boom;
    if (c != null && bm != null) {
      final hit = await ProDb.lookup(c, bm, r);
      if (hit != null) {
        capV = hit.capacity;
        capSrc =
            'Saved chart: $c, boom ${_f(bm, 1)} m, chart radius ${_f(hit.radius, 1)} m';
      } else {
        warns.add('Radius saved chart se bahar hai');
      }
    }
    if (capV <= 0) capV = _n(cap);
    double util = 0;
    if (capV > 0) {
      util = total / capV * 100;
      if (util > 100) {
        warns.add('OVERLOAD: crane utilization ${_f(util, 0)}%');
      } else if (util > 85) {
        warns.add(
            'Crane utilization ${_f(util, 0)}% (85% se upar): critical lift, engineer approval');
      } else if (util > 75) {
        warns.add('Crane utilization ${_f(util, 0)}%: critical lift check');
      }
    } else {
      warns.add('Crane capacity nahi mili: load chart se verify karo');
    }

    final run = legs == 4 ? math.sqrt(a * a + b * b) / 2 : a / 2;
    final t = _rad(th);
    final legLen = run / math.cos(t);
    final height = run * math.tan(t);
    final tension = w / (2 * math.sin(t));
    final pick = _pickRope(tension);
    if (th < 45) warns.add('Sling angle 45 deg se kam');
    if (pick <= 0) {
      warns.add('Sling 52 mm se bada chahiye: spreader beam / engineer');
    }

    String windTxt = 'Not entered';
    if (kmh > 0) {
      if (kmh <= 20) {
        windTxt = '${_f(kmh, 0)} km/h - OK';
      } else if (kmh <= 32) {
        windTxt = '${_f(kmh, 0)} km/h - CAUTION (tag line, savdhani)';
        warns.add('Wind 20-32 km/h: savdhani, tag line');
      } else {
        windTxt = '${_f(kmh, 0)} km/h - NO LIFT (above 32 km/h)';
        warns.add('Wind 32 km/h se upar: lifting band');
      }
    } else {
      warns.add('Wind speed daali nahi gayi');
    }

    setState(() => out = [
          _R('Total hook load: ${_f(total)} ton'),
          _R(
              capV > 0
                  ? 'Crane utilization: ${_f(util, 0)}%'
                  : 'Crane capacity nahi mili',
              capV <= 0 ? 3 : (util <= 75 ? 1 : (util <= 85 ? 2 : 3))),
          _R('Sling leg: ${_f(legLen)} m, tension ${_f(tension)} ton'),
          _R(
              warns.isEmpty
                  ? 'Koi calculated warning nahi'
                  : '${warns.length} warning PDF me hain',
              warns.isEmpty ? 1 : 2),
        ]);

    final doc = pw.Document();
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (pw.Context ctx) => [
        pw.Text('LIFT PLAN',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.Text('Date: ${_today()}'),
        _pdfSection('1. Job details', [
          ['Project', _dash(project.text)],
          ['Site / location', _dash(site.text)],
          ['Lift description', _dash(desc.text)],
          ['Supervisor', _dash(sup.text)],
          ['Rigger', _dash(rigger.text)],
          ['Crane operator', _dash(oper.text)],
        ]),
        _pdfSection('2. Load', [
          ['Load weight', '${_f(w)} ton'],
          ['Rigging + hook block', '${_f(rg)} ton'],
          ['Total hook load', '${_f(total)} ton'],
        ]),
        _pdfSection('3. Crane', [
          ['Crane', c ?? 'Manual'],
          ['Boom length', bm == null ? '-' : '${_f(bm, 1)} m'],
          ['Working radius', '${_f(r)} m'],
          [
            'Capacity at radius',
            capV > 0 ? '${_f(capV)} ton ($capSrc)' : 'Not available'
          ],
          ['Utilization', capV > 0 ? '${_f(util, 0)} %' : '-'],
        ]),
        _pdfSection('4. Rigging (sling)', [
          ['Sling legs', '$legs'],
          [
            'Lifting points',
            legs == 4 ? '${_f(a)} m x ${_f(b)} m' : 'spacing ${_f(a)} m'
          ],
          ['Sling angle (from horizontal)', '${_f(th, 0)} deg'],
          ['Sling length per leg', '${_f(legLen)} m'],
          ['Hook height above lifting points', '${_f(height)} m'],
          ['Load per leg', '${_f(tension)} ton'],
          [
            'Min wire rope size (est.)',
            pick > 0 ? '${_f(pick, 0)} mm 6x36 IWRC' : 'Above 52 mm'
          ],
          [
            'Note',
            legs == 4 ? 'Only 2 legs assumed to carry load' : '2 leg sling'
          ],
        ]),
        if (LiftDiagramCache.png != null) ...[
          pw.SizedBox(height: 12),
          pw.Text('Lift diagram', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Image(pw.MemoryImage(LiftDiagramCache.png!), height: 230),
        ],
        _pdfSection('5. Environment', [
          ['Wind speed', windTxt],
        ]),
        _pdfList(
            '6. Warnings', warns.isEmpty ? ['No calculated warnings'] : warns),
        _pdfList('7. Pre-lift checklist', _liftChecklist),
        pw.SizedBox(height: 16),
        pw.Row(children: [
          _pdfSign('Prepared by'),
          pw.SizedBox(width: 20),
          _pdfSign('Approved by'),
        ]),
        pw.SizedBox(height: 14),
        pw.Text(
            'Calculated values are estimates. Verify with crane load chart, sling tags/certificates and site procedure before lifting.',
            style: const pw.TextStyle(fontSize: 9)),
      ],
    ));
    final bytes = await doc.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'lift_plan',
    );
  }

  @override
  void dispose() {
    for (final c in [
      project, site, desc, sup, rigger, oper, wt, rig, len, wid, ang, rad,
      cap, wind
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Lift Plan PDF', [
      _textField(project, 'Project'),
      _textField(site, 'Site / location'),
      _textField(desc, 'Lift description (jaise: 6 ton pipe uthana)'),
      _textField(sup, 'Supervisor'),
      _textField(rigger, 'Rigger'),
      _textField(oper, 'Crane operator'),
      const Divider(),
      _field(wt, 'Load weight', suffix: 'ton'),
      _field(rig, 'Rigging + hook block weight', suffix: 'ton'),
      _field(len, 'Lifting points ke beech length', suffix: 'm'),
      if (legs == 4)
        _field(wid, 'Lifting points ke beech width', suffix: 'm'),
      _field(ang, 'Sling angle (horizontal se)', suffix: 'deg'),
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
      const SizedBox(height: 12),
      const Divider(),
      const Text('Crane (saved chart se capacity apne aap):'),
      DropdownButton<String?>(
        value: crane,
        isExpanded: true,
        hint: const Text('Manual (chart nahi)'),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
              value: null, child: Text('Manual (chart nahi)')),
          ...cranes.map(
              (c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
        ],
        onChanged: _pickCrane,
      ),
      if (crane != null)
        DropdownButton<double>(
          value: boom,
          isExpanded: true,
          items: booms
              .map((b) => DropdownMenuItem<double>(
                  value: b, child: Text('Boom ${_f(b, 1)} m')))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => boom = v);
          },
        ),
      const SizedBox(height: 8),
      _field(rad, 'Working radius', suffix: 'm'),
      _field(cap, 'Chart capacity (manual, chart na ho to)', suffix: 'ton'),
      _field(wind, 'Wind speed', suffix: 'km/h'),
      FilledButton.icon(
        onPressed: _generate,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF banao'),
      ),
      _results(out),
      _note(_disclaimer),
    ]);
  }
}
