import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'pro2_db.dart';
import 'rigging_pro_db.dart';

part 'pro2_diagram.dart';
part 'pro2_inspect.dart';
part 'pro2_inspect_view.dart';
part 'pro2_logbook.dart';
part 'pro2_voice.dart';

double _n(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;
String _f(double x, [int d = 2]) => x.toStringAsFixed(d);
double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _dmy(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  return '${p[2]}/${p[1]}/${p[0]}';
}

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

Future<Uint8List?> _capture(GlobalKey key, {double ratio = 2.0}) async {
  final ctx = key.currentContext;
  if (ctx == null) return null;
  final ro = ctx.findRenderObject();
  if (ro is! RenderRepaintBoundary) return null;
  final ui.Image img = await ro.toImage(pixelRatio: ratio);
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  return bd?.buffer.asUint8List();
}
