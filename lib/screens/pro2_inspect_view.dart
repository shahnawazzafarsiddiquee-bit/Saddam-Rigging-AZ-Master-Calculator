part of 'rigging_pro2.dart';

Future<void> _inspectionPdf(
    Map<String, Object?> r, List<Uint8List> pics) async {
  final rows = <List<String>>[];
  String note = '';
  for (final l in ((r['details'] as String?) ?? '').split('\n')) {
    final k = l.indexOf('|');
    if (k < 0) continue;
    final tag = l.substring(0, k);
    final txt = l.substring(k + 1);
    if (tag == 'NOTE') {
      note = txt;
    } else {
      rows.add([tag, txt]);
    }
  }
  final who = ((r['inspector'] as String?) ?? '').trim();
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(28),
    build: (pw.Context ctx) => [
      pw.Text('INSPECTION REPORT',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.Text('Item: ${r['item']}'),
      pw.Text('Type: ${r['kind']}'),
      pw.Text('Date: ${_dmy(r['dt'] as String)}'),
      pw.Text('Inspector: ${who.isEmpty ? '-' : who}'),
      pw.Text('Result: ${r['result']}',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(5),
        },
        children: rows
            .map((x) => pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(x[0],
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(x[1]),
                  ),
                ]))
            .toList(),
      ),
      if (note.isNotEmpty)
        pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text('Notes: $note')),
      if (pics.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                pics.map((b) => pw.Image(pw.MemoryImage(b), width: 240)).toList(),
          ),
        ),
      pw.SizedBox(height: 30),
      pw.Container(height: 0.5, color: PdfColors.black),
      pw.Text('Inspector / Supervisor (Name / Sign / Date)'),
    ],
  ));
  final bytes = await doc.save();
  await Printing.layoutPdf(
      onLayout: (PdfPageFormat f) async => bytes, name: 'inspection_report');
}

Color _resColor(String r) =>
    r == 'PASS' ? Colors.greenAccent : (r == 'FAIL' ? Colors.redAccent : Colors.orangeAccent);

class InspectionHistoryScreen extends StatefulWidget {
  const InspectionHistoryScreen({super.key});
  @override
  State<InspectionHistoryScreen> createState() =>
      _InspectionHistoryScreenState();
}

class _InspectionHistoryScreenState extends State<InspectionHistoryScreen> {
  List<Map<String, Object?>> rows = [];
  String err = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Pro2Db.inspections();
      if (!mounted) return;
      setState(() => rows = r);
    } catch (e) {
      if (mounted) setState(() => err = 'Database error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _page('Inspection History', [
      if (err.isNotEmpty) _results([_R(err, 3)]),
      if (rows.isEmpty && err.isEmpty)
        _note('Abhi koi inspection save nahi hai.'),
      ...rows.map((r) => Card(
            child: ListTile(
              title: Text('${r['item']}'),
              subtitle: Text('${r['kind']} | ${_dmy(r['dt'] as String)}'),
              trailing: Text('${r['result']}',
                  style: TextStyle(
                      color: _resColor(r['result'] as String),
                      fontWeight: FontWeight.bold)),
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => InspectionDetailScreen(row: r)));
                _load();
              },
            ),
          )),
    ]);
  }
}

class InspectionDetailScreen extends StatefulWidget {
  final Map<String, Object?> row;
  const InspectionDetailScreen({super.key, required this.row});
  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  List<Uint8List> pics = [];

  @override
  void initState() {
    super.initState();
    _loadPics();
  }

  Future<void> _loadPics() async {
    try {
      final p = await Pro2Db.photos(widget.row['id'] as int);
      if (!mounted) return;
      setState(() => pics = p);
    } catch (_) {}
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inspection delete?'),
        content: const Text('Ye record aur uski photos delete hongi.'),
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
      await Pro2Db.deleteInspection(widget.row['id'] as int);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    final lines = ((r['details'] as String?) ?? '').split('\n');
    final tiles = <Widget>[];
    for (final l in lines) {
      final k = l.indexOf('|');
      if (k < 0) continue;
      final tag = l.substring(0, k);
      final txt = l.substring(k + 1);
      final c = tag == 'OK'
          ? Colors.greenAccent
          : (tag == 'FAIL'
              ? Colors.redAccent
              : (tag == 'NOTE' ? Colors.white : Colors.orangeAccent));
      tiles.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text('$tag  $txt',
            style: TextStyle(color: c, fontWeight: FontWeight.w600)),
      ));
    }
    return _page('Inspection', [
      Text('${r['item']}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text('${r['kind']} | ${_dmy(r['dt'] as String)}'),
      Text('Inspector: ${r['inspector']}'),
      Text('Result: ${r['result']}',
          style: TextStyle(
              color: _resColor(r['result'] as String),
              fontWeight: FontWeight.bold)),
      const Divider(),
      ...tiles,
      if (pics.isNotEmpty) const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: pics
            .map((p) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(p,
                      width: 150, height: 150, fit: BoxFit.cover),
                ))
            .toList(),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: () => _inspectionPdf(r, pics),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF report'),
      ),
      TextButton(onPressed: _delete, child: const Text('Delete karo')),
    ]);
  }
}
