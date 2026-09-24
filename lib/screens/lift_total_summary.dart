import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../app/theme.dart';

// ─────────────────────────────────────────────
//  LIFT TOTAL SUMMARY SHEET
//  Ek jagah par poori lift ki saari calculations
//  fill karo aur PDF export karo.
// ─────────────────────────────────────────────

double _n(String s) => double.tryParse(s.trim().replaceAll(',', '.')) ?? 0;
String _f(double x, [int d = 2]) => x.toStringAsFixed(d);
double _rad(double d) => d * math.pi / 180;

class LiftTotalSummaryScreen extends StatefulWidget {
  const LiftTotalSummaryScreen({super.key});
  @override
  State<LiftTotalSummaryScreen> createState() => _LiftTotalSummaryScreenState();
}

class _LiftTotalSummaryScreenState extends State<LiftTotalSummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // ─── Job Info ───
  final jobName = TextEditingController();
  final jobNo = TextEditingController();
  final location = TextEditingController();
  final rig = TextEditingController();
  final prepBy = TextEditingController();
  final jobDate = TextEditingController(
      text:
          '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}');

  // ─── Load ───
  final loadDesc = TextEditingController();
  final loadWt = TextEditingController();
  final riggingWt = TextEditingController(text: '0.5');
  final hookBlockWt = TextEditingController(text: '0.2');

  // ─── Crane ───
  final craneModel = TextEditingController();
  final craneRadius = TextEditingController();
  final boomLen = TextEditingController();
  final boomAngle = TextEditingController();
  final chartCap = TextEditingController();

  // ─── Slings ───
  final slingType = TextEditingController(text: 'Wire rope 6x36 IWRC');
  final slingDia = TextEditingController();
  final slingLen = TextEditingController();
  final slingLegs = TextEditingController(text: '2');
  final slingAngleCtrl = TextEditingController(text: '60');

  // ─── Shackle ───
  final shackleSize = TextEditingController();
  final shackleWLL = TextEditingController();

  // ─── Wind ───
  final windSpeed = TextEditingController();

  // ─── Calculated Results (auto) ───
  Map<String, String> _results = {};
  bool _calculated = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [
      jobName, jobNo, location, rig, prepBy, jobDate,
      loadDesc, loadWt, riggingWt, hookBlockWt,
      craneModel, craneRadius, boomLen, boomAngle, chartCap,
      slingType, slingDia, slingLen, slingLegs, slingAngleCtrl,
      shackleSize, shackleWLL,
      windSpeed,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    final w = _n(loadWt.text);
    final rg = _n(riggingWt.text);
    final hb = _n(hookBlockWt.text);
    final cap = _n(chartCap.text);
    final ang = _n(slingAngleCtrl.text);
    final legs = _n(slingLegs.text).toInt().clamp(1, 4);
    final wind = _n(windSpeed.text);

    final total = w + rg + hb;
    final util = cap > 0 ? total / cap * 100 : 0.0;
    final tension = ang > 0 && ang < 90
        ? w / (legs * math.sin(_rad(ang)))
        : 0.0;
    final angleFactor = ang > 0 ? 1 / math.sin(_rad(ang)) : 0.0;

    String windStatus = '';
    if (wind > 0) {
      if (wind <= 20) {
        windStatus = 'SAFE ($wind km/h ≤ 20)';
      } else if (wind <= 32) {
        windStatus = 'CAUTION ($wind km/h, tag line use karo)';
      } else {
        windStatus = 'STOP LIFT ($wind km/h > 32 km/h limit)';
      }
    }

    String utilStatus = '';
    if (cap > 0) {
      if (util <= 75) {
        utilStatus = '${_f(util, 0)}% — SAFE (≤ 75%)';
      } else if (util <= 85) {
        utilStatus = '${_f(util, 0)}% — CAUTION (75–85%, critical check)';
      } else if (util <= 100) {
        utilStatus = '${_f(util, 0)}% — HIGH (> 85%, engineer required)';
      } else {
        utilStatus = '${_f(util, 0)}% — OVERLOAD! Lift mat karo';
      }
    }

    setState(() {
      _calculated = true;
      _results = {
        'Total Hook Load': '${_f(total)} ton',
        'Load': '${_f(w)} ton',
        'Rigging + Block': '${_f(rg + hb)} ton',
        'Crane Utilization': cap > 0 ? utilStatus : 'Chart capacity nahi di',
        'Sling Tension per Leg': tension > 0 ? '${_f(tension)} ton' : 'Angle daalo',
        'Angle Factor': ang > 0 ? '${_f(angleFactor, 3)}x' : '—',
        'Wind Status': windStatus.isEmpty ? 'Wind speed nahi di' : windStatus,
      };
    });
  }

  // ─── Status color helper ───
  Color _statusColor(String v) {
    if (v.contains('OVERLOAD') || v.contains('STOP')) return Colors.redAccent;
    if (v.contains('CAUTION') || v.contains('HIGH')) return Colors.orangeAccent;
    if (v.contains('SAFE') || v.contains('≤')) return Colors.greenAccent;
    return AppColors.textLight;
  }

  Future<void> _exportPdf() async {
    _calculate();
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = '${now.day}/${now.month}/${now.year}';

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('LIFT TOTAL SUMMARY',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(dateStr),
            ],
          ),
        ),
        _pdfSection('JOB INFORMATION', [
          ['Job Name', jobName.text],
          ['Job No.', jobNo.text],
          ['Location', location.text],
          ['Rig / Site', rig.text],
          ['Prepared By', prepBy.text],
          ['Date', jobDate.text],
        ]),
        _pdfSection('LOAD DETAILS', [
          ['Description', loadDesc.text],
          ['Load Weight', '${loadWt.text} ton'],
          ['Rigging Weight', '${riggingWt.text} ton'],
          ['Hook Block Weight', '${hookBlockWt.text} ton'],
          ['Total Hook Load', _results['Total Hook Load'] ?? ''],
        ]),
        _pdfSection('CRANE', [
          ['Model', craneModel.text],
          ['Working Radius', '${craneRadius.text} m'],
          ['Boom Length', '${boomLen.text} m'],
          ['Boom Angle', '${boomAngle.text} deg'],
          ['Chart Capacity', '${chartCap.text} ton'],
          ['Utilization', _results['Crane Utilization'] ?? ''],
        ]),
        _pdfSection('SLINGS', [
          ['Type', slingType.text],
          ['Diameter', '${slingDia.text} mm'],
          ['Length', '${slingLen.text} m'],
          ['No. of Legs', slingLegs.text],
          ['Sling Angle', '${slingAngleCtrl.text} deg'],
          ['Tension per Leg', _results['Sling Tension per Leg'] ?? ''],
          ['Angle Factor', _results['Angle Factor'] ?? ''],
        ]),
        _pdfSection('SHACKLE', [
          ['Size', shackleSize.text],
          ['WLL', '${shackleWLL.text} ton'],
        ]),
        _pdfSection('WIND CHECK', [
          ['Wind Speed', '${windSpeed.text} km/h'],
          ['Status', _results['Wind Status'] ?? ''],
        ]),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all()),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('SIGN-OFF',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(children: [
                pw.Expanded(child: pw.Text('Rigger: ___________________')),
                pw.Expanded(child: pw.Text('Supervisor: ___________________')),
              ]),
              pw.SizedBox(height: 8),
              pw.Row(children: [
                pw.Expanded(child: pw.Text('Engineer: ___________________')),
                pw.Expanded(child: pw.Text('Date: ___________________')),
              ]),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'DISCLAIMER: Ye sirf estimate hain. Final decision competent person, crane load chart aur certified lift plan ke hisaab se lo.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  pw.Widget _pdfSection(String title, List<List<String>> rows) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.SizedBox(height: 12),
      pw.Text(title,
          style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline)),
      pw.SizedBox(height: 6),
      pw.Table(
        border: pw.TableBorder.all(width: 0.5),
        columnWidths: {
          0: const pw.FixedColumnWidth(130),
          1: const pw.FlexColumnWidth(),
        },
        children: rows
            .map((r) => pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(r[0],
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 10))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(r[1], style: const pw.TextStyle(fontSize: 10))),
                ]))
            .toList(),
      ),
    ]);
  }

  Widget _inputField(TextEditingController c, String label,
      {String? suffix, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type ??
            (suffix != null
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(s,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.safetyOrange)),
      );

  Widget _tabJob() => ListView(padding: const EdgeInsets.all(16), children: [
        _sectionTitle('Job Information'),
        _inputField(jobName, 'Job Name / Description',
            type: TextInputType.text),
        _inputField(jobNo, 'Job Number / Work Order', type: TextInputType.text),
        _inputField(location, 'Location / Site', type: TextInputType.text),
        _inputField(rig, 'Rig / Plant Name', type: TextInputType.text),
        _inputField(prepBy, 'Prepared By', type: TextInputType.text),
        _inputField(jobDate, 'Date', type: TextInputType.text),
        _sectionTitle('Load Details'),
        _inputField(loadDesc, 'Load Description', type: TextInputType.text),
        _inputField(loadWt, 'Load Weight', suffix: 'ton'),
        _inputField(riggingWt, 'Rigging (slings + hardware)', suffix: 'ton'),
        _inputField(hookBlockWt, 'Hook block weight', suffix: 'ton'),
      ]);

  Widget _tabCrane() => ListView(padding: const EdgeInsets.all(16), children: [
        _sectionTitle('Crane Details'),
        _inputField(craneModel, 'Crane Model', type: TextInputType.text),
        _inputField(craneRadius, 'Working Radius', suffix: 'm'),
        _inputField(boomLen, 'Boom Length', suffix: 'm'),
        _inputField(boomAngle, 'Boom Angle', suffix: 'deg'),
        _inputField(chartCap, 'Chart Capacity at this radius', suffix: 'ton'),
        _sectionTitle('Wind'),
        _inputField(windSpeed, 'Wind Speed', suffix: 'km/h'),
      ]);

  Widget _tabRigging() => ListView(padding: const EdgeInsets.all(16), children: [
        _sectionTitle('Slings'),
        _inputField(slingType, 'Sling Type', type: TextInputType.text),
        _inputField(slingDia, 'Diameter', suffix: 'mm'),
        _inputField(slingLen, 'Length', suffix: 'm'),
        _inputField(slingLegs, 'Number of Legs'),
        _inputField(slingAngleCtrl, 'Sling Angle (horizontal se)', suffix: 'deg'),
        _sectionTitle('Shackle'),
        _inputField(shackleSize, 'Shackle Size', type: TextInputType.text),
        _inputField(shackleWLL, 'Shackle WLL', suffix: 'ton'),
      ]);

  Widget _tabSummary() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (!_calculated)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Pehle sabhi tabs fill karo, phir "Calculate" dabao.',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ElevatedButton.icon(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate),
        label: const Text('Calculate All'),
      ),
      const SizedBox(height: 16),
      if (_calculated) ...[
        _sectionTitle('LIFT TOTALS'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _results.entries.map((e) {
              final color = _statusColor(e.value);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    Flexible(
                      child: Text(
                        e.value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _liftSafetyChecklist(),
        const SizedBox(height: 20),
      ],
      OutlinedButton.icon(
        onPressed: _exportPdf,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Export PDF'),
      ),
      const SizedBox(height: 12),
      const Text(
        'DISCLAIMER: Ye sirf estimate hain. Final decision crane load chart, sling tag/certificate aur lift plan (competent person) ke hisaab se lo.',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      ),
    ]);
  }

  Widget _liftSafetyChecklist() {
    final items = [
      'Lift plan prepare aur approve hua?',
      'Crane load chart is radius ke liye dekha?',
      'Sling/shackle certificate aur expiry check ki?',
      'Ground/outrigger bearing confirm hua?',
      'Overhead clearance check ki?',
      'Tag line lagane ki arrangement hai?',
      'Wind speed acceptable hai?',
      'Exclusion zone set ki?',
      'Communication plan (signalman, radio) confirm?',
      'Emergency plan tayyar hai?',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pre-Lift Safety Checklist',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.safetyOrange,
                fontSize: 15)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_box_outline_blank,
                      color: AppColors.safetyOrange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Lift Total Summary',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text('Poori lift ek jagah',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.work), text: 'Job'),
            Tab(icon: Icon(Icons.precision_manufacturing), text: 'Crane'),
            Tab(icon: Icon(Icons.link), text: 'Rigging'),
            Tab(icon: Icon(Icons.summarize), text: 'Total'),
          ],
          labelColor: AppColors.safetyOrange,
          unselectedLabelColor: Colors.white54,
          indicatorColor: AppColors.safetyOrange,
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _tabJob(),
          _tabCrane(),
          _tabRigging(),
          _tabSummary(),
        ],
      ),
    );
  }
}
