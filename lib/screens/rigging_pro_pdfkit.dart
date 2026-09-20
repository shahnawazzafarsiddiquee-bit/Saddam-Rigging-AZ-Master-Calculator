part of 'rigging_pro.dart';

String _today() => _fmtDate(DateTime.now());
String _dash(String s) => s.trim().isEmpty ? '-' : s.trim();

pw.Widget _pdfSection(String title, List<List<String>> rows) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 12),
      pw.Text(title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(3),
        },
        children: rows
            .map((r) => pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(r[0],
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(r[1]),
                  ),
                ]))
            .toList(),
      ),
    ],
  );
}

pw.Widget _pdfList(String title, List<String> items) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 12),
      pw.Text(title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      ...items.map((s) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(s),
          )),
    ],
  );
}

pw.Widget _pdfSign(String who) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 30),
        pw.Container(height: 0.5, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text('$who (Name / Sign / Date)'),
        pw.SizedBox(height: 4),
      ],
    ),
  );
}

const List<String> _liftChecklist = [
  '[   ] Load ka asli weight confirm kiya (nameplate / drawing)',
  '[   ] Crane load chart aur outrigger setting check ki',
  '[   ] Ground / mat ki bearing check ki',
  '[   ] Sling, shackle, hook ki inspection aur certificate valid',
  '[   ] Lifting points aur CG check kiye',
  '[   ] Wind speed limit ke andar hai',
  '[   ] Area barricade, sirf zaruri log andar',
  '[   ] Signalman aur rigger tay, communication clear',
  '[   ] Overhead line / obstruction se safe doori',
  '[   ] Toolbox talk kiya, sabko plan samjhaya',
];
