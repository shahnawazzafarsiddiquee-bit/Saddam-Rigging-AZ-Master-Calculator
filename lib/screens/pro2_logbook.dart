part of 'rigging_pro2.dart';

Future<void> _logPdf(List<Map<String, Object?>> rows, String title) async {
  double heavy = 0;
  double maxU = 0;
  for (final r in rows) {
    heavy = math.max(heavy, (r['weight'] as num?)?.toDouble() ?? 0);
    maxU = math.max(maxU, (r['util'] as num?)?.toDouble() ?? 0);
  }
  pw.Widget cell(String s, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: pw.Text(s,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(24),
    build: (pw.Context ctx) => [
      pw.Text('LIFT LOGBOOK',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
      pw.Text(title),
      pw.Text(
          'Total lifts: ${rows.length} | Heaviest: ${_f(heavy)} ton | Max utilization: ${_f(maxU, 0)}%'),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1.3),
          1: const pw.FlexColumnWidth(1.6),
          2: const pw.FlexColumnWidth(2.6),
          3: const pw.FlexColumnWidth(0.9),
          4: const pw.FlexColumnWidth(2.6),
          5: const pw.FlexColumnWidth(0.9),
          6: const pw.FlexColumnWidth(1.3),
        },
        children: [
          pw.TableRow(children: [
            cell('Date', bold: true),
            cell('Project', bold: true),
            cell('Description', bold: true),
            cell('Load t', bold: true),
            cell('Crane / boom / radius', bold: true),
            cell('Util %', bold: true),
            cell('Result', bold: true),
          ]),
          ...rows.map((r) => pw.TableRow(children: [
                cell(_dmy(r['dt'] as String)),
                cell('${r['project'] ?? ''}'),
                cell('${r['descr'] ?? ''}'),
                cell(_f(((r['weight'] as num?) ?? 0).toDouble())),
                cell(
                    '${r['crane'] ?? ''} / ${_f(((r['boom'] as num?) ?? 0).toDouble(), 1)} m / ${_f(((r['radius'] as num?) ?? 0).toDouble(), 1)} m'),
                cell(_f(((r['util'] as num?) ?? 0).toDouble(), 0)),
                cell('${r['result'] ?? ''}'),
              ])),
        ],
      ),
    ],
  ));
  final bytes = await doc.save();
  await Printing.layoutPdf(
      onLayout: (PdfPageFormat f) async => bytes, name: 'lift_logbook');
}

class LogbookScreen extends StatefulWidget {
  const LogbookScreen({super.key});
  @override
  State<LogbookScreen> createState() => _LogbookScreenState();
}

class _LogbookScreenState extends State<LogbookScreen> {
  List<Map<String, Object?>> rows = [];
  String? proj;
  String err = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Pro2Db.lifts();
      if (!mounted) return;
      setState(() => rows = r);
    } catch (e) {
      if (mounted) setState(() => err = 'Database error: $e');
    }
  }

  List<Map<String, Object?>> get _shown => proj == null
      ? rows
      : rows.where((r) => (r['project'] as String?) == proj).toList();

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entry delete?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Nahi')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Haan')),
        ],
      ),
    );
    if (ok == true) {
      await Pro2Db.deleteLift(id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final projects = rows
        .map((r) => (r['project'] as String?) ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
    projects.sort();
    double heavy = 0;
    double maxU = 0;
    int crit = 0;
    for (final r in shown) {
      heavy = math.max(heavy, (r['weight'] as num?)?.toDouble() ?? 0);
      maxU = math.max(maxU, (r['util'] as num?)?.toDouble() ?? 0);
      if ((r['result'] as String?) == 'Critical') crit++;
    }
    return _page('Job Logbook', [
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LogEntryScreen()));
                _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Nayi lift entry'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: shown.isEmpty
                  ? null
                  : () => _logPdf(shown, proj ?? 'All projects'),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF report'),
            ),
          ),
        ],
      ),
      if (err.isNotEmpty) _results([_R(err, 3)]),
      if (projects.isNotEmpty) ...[
        const SizedBox(height: 12),
        DropdownButton<String?>(
          value: proj,
          isExpanded: true,
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(
                value: null, child: Text('Saare projects')),
            ...projects.map((p) =>
                DropdownMenuItem<String?>(value: p, child: Text(p))),
          ],
          onChanged: (v) => setState(() => proj = v),
        ),
      ],
      if (shown.isNotEmpty)
        _results([
          _R('Total lifts: ${shown.length}'),
          _R('Sabse bhaari: ${_f(heavy)} ton'),
          _R('Max utilization: ${_f(maxU, 0)}%',
              maxU <= 75 ? 1 : (maxU <= 85 ? 2 : 3)),
          _R('Critical lifts: $crit', crit > 0 ? 2 : 0),
        ]),
      const SizedBox(height: 8),
      if (shown.isEmpty && err.isEmpty)
        _note('Abhi koi lift entry nahi hai. "Nayi lift entry" dabao.'),
      ...shown.map((r) => Card(
            child: ListTile(
              title: Text(
                  '${_dmy(r['dt'] as String)} | ${(r['project'] as String?) ?? ''}'),
              subtitle: Text(
                  '${r['descr'] ?? ''}\n${_f(((r['weight'] as num?) ?? 0).toDouble())} t | ${r['crane'] ?? ''} | boom ${_f(((r['boom'] as num?) ?? 0).toDouble(), 1)} m @ ${_f(((r['radius'] as num?) ?? 0).toDouble(), 1)} m | ${_f(((r['util'] as num?) ?? 0).toDouble(), 0)}% | ${r['result'] ?? ''}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(r['id'] as int),
              ),
            ),
          )),
    ]);
  }
}

class LogEntryScreen extends StatefulWidget {
  const LogEntryScreen({super.key});
  @override
  State<LogEntryScreen> createState() => _LogEntryScreenState();
}

class _LogEntryScreenState extends State<LogEntryScreen> {
  final project = TextEditingController();
  final descr = TextEditingController();
  final wt = TextEditingController();
  final rig = TextEditingController(text: '0.5');
  final crane = TextEditingController();
  final boom = TextEditingController();
  final rad = TextEditingController();
  final util = TextEditingController();
  final notes = TextEditingController();
  DateTime date = DateTime.now();
  String result = 'Completed';
  List<String> cranes = [];
  String msg = '';
  int msgLvl = 0;

  @override
  void initState() {
    super.initState();
    _loadCranes();
  }

  Future<void> _loadCranes() async {
    try {
      final c = await ProDb.cranes();
      if (!mounted) return;
      setState(() => cranes = c);
    } catch (_) {}
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) setState(() => date = d);
  }

  Future<void> _autoUtil() async {
    final c = crane.text.trim();
    final b = _n(boom);
    final r = _n(rad);
    final w = _n(wt) + _n(rig);
    if (c.isEmpty || b <= 0 || r <= 0 || w <= 0) {
      setState(() {
        msg = 'Crane, boom, radius aur load daalo';
        msgLvl = 2;
      });
      return;
    }
    final hit = await ProDb.lookup(c, b, r);
    if (!mounted) return;
    if (hit == null) {
      setState(() {
        msg = 'Saved chart me is crane / boom / radius ka data nahi mila';
        msgLvl = 2;
      });
      return;
    }
    setState(() {
      util.text = _f(w / hit.capacity * 100, 0);
      msg = 'Utilization chart se nikala (load + rigging)';
      msgLvl = 1;
    });
  }

  Future<void> _save() async {
    if (_n(wt) <= 0) {
      setState(() {
        msg = 'Load weight daalo';
        msgLvl = 3;
      });
      return;
    }
    try {
      await Pro2Db.addLift({
        'dt': _iso(date),
        'project': project.text.trim(),
        'descr': descr.text.trim(),
        'weight': _n(wt),
        'crane': crane.text.trim(),
        'boom': _n(boom),
        'radius': _n(rad),
        'util': _n(util),
        'result': result,
        'notes': notes.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          msg = 'Save nahi hua: $e';
          msgLvl = 3;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in [project, descr, wt, rig, crane, boom, rad, util, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Nayi Lift Entry', [
      OutlinedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.event),
        label: Text('Date: ${_dmy(_iso(date))}'),
      ),
      const SizedBox(height: 12),
      _textField(project, 'Project / site'),
      _textField(descr, 'Lift description'),
      _field(wt, 'Load weight', suffix: 'ton'),
      _field(rig, 'Rigging + hook block', suffix: 'ton'),
      _textField(crane, 'Crane (naam)'),
      if (cranes.isNotEmpty)
        Wrap(
          spacing: 8,
          children: cranes
              .map((c) => ActionChip(
                    label: Text(c),
                    onPressed: () => setState(() => crane.text = c),
                  ))
              .toList(),
        ),
      const SizedBox(height: 12),
      _field(boom, 'Boom length', suffix: 'm'),
      _field(rad, 'Working radius', suffix: 'm'),
      _field(util, 'Utilization', suffix: '%'),
      OutlinedButton(
          onPressed: _autoUtil,
          child: const Text('Saved chart se utilization nikalo')),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: ['Completed', 'Critical', 'Aborted']
            .map((x) => ChoiceChip(
                  label: Text(x),
                  selected: result == x,
                  onSelected: (_) => setState(() => result = x),
                ))
            .toList(),
      ),
      const SizedBox(height: 12),
      _textField(notes, 'Notes'),
      FilledButton(onPressed: _save, child: const Text('Save')),
      if (msg.isNotEmpty) _results([_R(msg, msgLvl)]),
    ]);
  }
}
