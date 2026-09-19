import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

/// Generates PDF reports for lift plans, calculations, JSA and inspections.
/// Every PDF is saved locally under the app documents directory (offline-first)
/// and the file path is returned so it can be stored in the Reports table
/// and shared/opened by the caller.
class PdfService {
  static Future<File> _save(pw.Document doc, String baseName) async {
    final dir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${dir.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${reportsDir.path}/${baseName}_$timestamp.pdf');
    await file.writeAsBytes(await doc.save());
    return file;
  }

  static pw.Widget _header(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('SADDAM RIGGING A-Z MASTER CALCULATOR',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 1.5),
      ],
    );
  }

  static pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 170, child: pw.Text(k, style: const pw.TextStyle(color: PdfColors.grey700))),
          pw.Expanded(child: pw.Text(v, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static Future<File> generateCalculationPdf({
    required String calculatorName,
    required Map<String, String> inputs,
    required Map<String, String> results,
    required String verdict,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('$calculatorName Report'),
            pw.SizedBox(height: 12),
            pw.Text('Inputs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ...inputs.entries.map((e) => _kv(e.key, e.value)),
            pw.SizedBox(height: 16),
            pw.Text('Results', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ...results.entries.map((e) => _kv(e.key, e.value)),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.5)),
              child: pw.Text('STATUS: $verdict',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    return _save(doc, calculatorName.replaceAll(' ', '_').toLowerCase());
  }

  static Future<File> generateLiftPlanPdf({
    required String projectName,
    required String client,
    required String location,
    required String date,
    required String loadDescription,
    required String loadWeight,
    required String craneDetails,
    required String riggingArrangement,
    required String liftingSequence,
    required String personnel,
    required String safetyRequirements,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header('Lift Plan'),
          pw.SizedBox(height: 12),
          _kv('Project Name', projectName),
          _kv('Client', client),
          _kv('Location', location),
          _kv('Date', date),
          pw.SizedBox(height: 12),
          pw.Text('Load Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          _kv('Description', loadDescription),
          _kv('Weight', loadWeight),
          pw.SizedBox(height: 12),
          pw.Text('Crane Details', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.Text(craneDetails),
          pw.SizedBox(height: 12),
          pw.Text('Rigging Arrangement', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.Text(riggingArrangement),
          pw.SizedBox(height: 12),
          pw.Text('Lifting Sequence', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.Text(liftingSequence),
          pw.SizedBox(height: 12),
          pw.Text('Personnel & Responsibilities', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.Text(personnel),
          pw.SizedBox(height: 12),
          pw.Text('Safety Requirements', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.Text(safetyRequirements),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Prepared By: ____________________'),
                pw.SizedBox(height: 20),
                pw.Text('Date: ____________________'),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Approved By: ____________________'),
                pw.SizedBox(height: 20),
                pw.Text('Date: ____________________'),
              ]),
            ],
          ),
        ],
      ),
    );
    return _save(doc, 'lift_plan_${projectName.replaceAll(' ', '_')}');
  }

  static Future<File> generateJsaPdf({
    required String activity,
    required List<Map<String, String>> steps, // step, hazard, risk, control
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _header('Job Safety Analysis (JSA)'),
          pw.SizedBox(height: 8),
          _kv('Activity', activity),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Work Step', 'Hazard', 'Risk', 'Control Measure'],
            data: steps
                .map((s) => [s['step'] ?? '', s['hazard'] ?? '', s['risk'] ?? '', s['control'] ?? ''])
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.all(6),
          ),
        ],
      ),
    );
    return _save(doc, 'jsa_${activity.replaceAll(' ', '_')}');
  }

  static Future<File> generateInspectionPdf({
    required String equipmentId,
    required String type,
    required String inspector,
    required String date,
    required String result,
    required String remarks,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header('Equipment Inspection Report'),
            pw.SizedBox(height: 12),
            _kv('Equipment ID', equipmentId),
            _kv('Type', type),
            _kv('Inspector', inspector),
            _kv('Date', date),
            _kv('Result', result),
            pw.SizedBox(height: 12),
            pw.Text('Remarks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(remarks),
          ],
        ),
      ),
    );
    return _save(doc, 'inspection_$equipmentId');
  }
}
