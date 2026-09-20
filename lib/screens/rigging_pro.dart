import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'rigging_pro_db.dart';

part 'rigging_pro_chartedit.dart';
part 'rigging_pro_chart.dart';
part 'rigging_pro_pdfkit.dart';
part 'rigging_pro_pdf.dart';
part 'rigging_pro_capacity.dart';
part 'rigging_pro_section.dart';
part 'rigging_pro_cert.dart';
part 'rigging_pro_pull.dart';

double _n(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
String _f(double x, [int d = 2]) => x.toStringAsFixed(d);
double _rad(double d) => d * math.pi / 180;

class _R {
  final String t;
  final int lvl;
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

Widget _textField(TextEditingController c, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
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
                        color: _col(r.lvl),
                      )),
                ))
            .toList(),
      ),
    ),
  );
}

Widget _note(String s) =>
    Padding(padding: const EdgeInsets.only(top: 12), child: Text(s));

Widget _page(String title, List<Widget> children) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: ListView(padding: const EdgeInsets.all(16), children: children),
    ),
  );
}

const String _disclaimer =
    'Ye sirf estimate hain. Final decision crane load chart, sling tag/certificate aur lift plan (competent person) ke hisaab se lo.';

const List<double> _ropeSizes = [
  8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36, 40, 44, 48, 52
];

double _pickRope(double tension) {
  final need = math.sqrt(tension * 100);
  for (final s in _ropeSizes) {
    if (s >= need) return s;
  }
  return 0;
}

int _daysLeft(String iso) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return DateTime.parse(iso).difference(today).inDays;
}

String _fmtIso(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  return '${p[2]}/${p[1]}/${p[0]}';
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class ProToolsScreen extends StatefulWidget {
  const ProToolsScreen({super.key});
  @override
  State<ProToolsScreen> createState() => _ProToolsScreenState();
}

class _ProToolsScreenState extends State<ProToolsScreen> {
  String certMsg = '';
  int certLvl = 0;

  @override
  void initState() {
    super.initState();
    _loadCerts();
  }

  Future<void> _loadCerts() async {
    try {
      final rows = await ProDb.certs();
      int expired = 0;
      int soon = 0;
      for (final r in rows) {
        final d = _daysLeft(r['expiry'] as String);
        if (d < 0) {
          expired++;
        } else if (d <= 30) {
          soon++;
        }
      }
      if (!mounted) return;
      setState(() {
        if (expired > 0) {
          certMsg =
              'Certificates: $expired EXPIRED, $soon 30 din me khatam. Tracker kholo';
          certLvl = 3;
        } else if (soon > 0) {
          certMsg = 'Certificates: $soon 30 din me expire honge';
          certLvl = 2;
        } else {
          certMsg = '';
          certLvl = 0;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String sub, Widget page) {
      return Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(sub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => page))
              .then((_) => _loadCerts()),
        ),
      );
    }

    return _page('Pro Tools', [
      if (certMsg.isNotEmpty) _results([_R(certMsg, certLvl)]),
      const SizedBox(height: 8),
      tile(Icons.table_chart, 'Crane Load Chart',
          'Chart save karo, capacity aur utilization', const CraneChartScreen()),
      tile(Icons.picture_as_pdf, 'Lift Plan PDF',
          'Calculations ke saath PDF plan', const LiftPlanPdfScreen()),
      tile(Icons.link, 'Sling & Shackle Capacity',
          'Choker / basket capacity, shackle size', const CapacityScreen()),
      tile(Icons.view_stream, 'Steel Section Weight',
          'ISMB, ISMC, angle, flat, square, round', const SectionWeightScreen()),
      tile(Icons.category, 'Object & Tank Weight',
          'Block, cylinder, sphere, tank', const ObjectWeightScreen()),
      tile(Icons.event_available, 'Certificate Tracker',
          'Sling, crane, operator expiry dates', const CertTrackerScreen()),
      tile(Icons.open_with, 'Pulling Force',
          'Skid / roller pulling, winch capacity', const PullingForceScreen()),
      _note(_disclaimer),
    ]);
  }
}
