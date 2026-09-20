part of 'rigging_pro.dart';

class _Tok {
  final double v;
  final double x;
  final double y;
  final double h;
  _Tok(this.v, this.x, this.y, this.h);
}

double? _tokNum(String raw, String unit) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  s = s.replaceFirst(RegExp(r'(kg|m|t)$', caseSensitive: false), '');
  if (unit == 'kg' && RegExp(r'^\d{1,3},\d{3}$').hasMatch(s)) {
    s = s.replaceAll(',', '');
  }
  s = s.replaceAll(',', '.');
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(s)) return null;
  final v = double.tryParse(s);
  if (v == null || v <= 0) return null;
  return v;
}

String _num3(double v) {
  var s = v.toStringAsFixed(3);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  s = s.replaceFirst(RegExp(r'\.$'), '');
  return s;
}

Future<List<String>> _pdfToPngs(String pdfPath, int maxPages) async {
  final file = File(pdfPath);
  final bytes = await file.readAsBytes();
  final dir = file.parent.path;
  final out = <String>[];
  int i = 0;
  await for (final page in Printing.raster(bytes, dpi: 200)) {
    final png = await page.toPng();
    final f = File('$dir/chart_page_$i.png');
    await f.writeAsBytes(png);
    out.add(f.path);
    i++;
    if (i >= maxPages) break;
  }
  return out;
}

Future<List<_Tok>> _ocrFile(String path, String unit) async {
  final rec = mlk.TextRecognizer(script: mlk.TextRecognitionScript.latin);
  try {
    final res = await rec.processImage(mlk.InputImage.fromFilePath(path));
    final out = <_Tok>[];
    for (final b in res.blocks) {
      for (final l in b.lines) {
        for (final e in l.elements) {
          final v = _tokNum(e.text, unit);
          if (v == null) continue;
          final r = e.boundingBox;
          out.add(_Tok(v, r.center.dx, r.center.dy, r.height));
        }
      }
    }
    return out;
  } finally {
    await rec.close();
  }
}

List<List<_Tok>> _groupRows(List<_Tok> toks) {
  final hs = toks.map((t) => t.h).toList()..sort();
  final medH = hs[hs.length ~/ 2];
  final tol = medH * 0.6;
  final sorted = [...toks]..sort((a, b) => a.y.compareTo(b.y));
  final rows = <List<_Tok>>[];
  double rowY = 0;
  for (final t in sorted) {
    if (rows.isEmpty || (t.y - rowY).abs() > tol) {
      rows.add([t]);
      rowY = t.y;
    } else {
      rows.last.add(t);
      rowY = (rowY * (rows.last.length - 1) + t.y) / rows.last.length;
    }
  }
  for (final r in rows) {
    r.sort((a, b) => a.x.compareTo(b.x));
  }
  return rows;
}

List<List<double>> _buildTable(
    List<_Tok> toks, bool radiusSide, List<String> notes) {
  final out = <List<double>>[];
  if (toks.length < 8) {
    notes.add('Kam numbers mile');
    return out;
  }
  final rows = _groupRows(toks);
  int hi = -1;
  int best = 0;
  final lim = rows.length < 14 ? rows.length : 14;
  for (int i = 0; i < lim; i++) {
    final r = rows[i];
    if (r.length < 3) continue;
    bool inc = true;
    for (int k = 1; k < r.length; k++) {
      if (r[k].v <= r[k - 1].v) {
        inc = false;
        break;
      }
    }
    if (inc && r.length > best) {
      best = r.length;
      hi = i;
    }
  }
  if (hi < 0) {
    notes.add('Header row (boom / radius) nahi mili');
    return out;
  }
  final hdr = rows[hi];
  final gaps = <double>[];
  for (int k = 1; k < hdr.length; k++) {
    gaps.add(hdr[k].x - hdr[k - 1].x);
  }
  gaps.sort();
  final colTol = gaps[gaps.length ~/ 2] * 0.5;
  final left = hdr.first.x - colTol;
  for (int i = hi + 1; i < rows.length; i++) {
    final r = rows[i];
    _Tok? lead;
    for (final t in r) {
      if (t.x < left) lead = t;
    }
    if (lead == null) continue;
    for (final t in r) {
      if (t.x < left) continue;
      int bj = -1;
      double bd = double.infinity;
      for (int j = 0; j < hdr.length; j++) {
        final d = (t.x - hdr[j].x).abs();
        if (d < bd) {
          bd = d;
          bj = j;
        }
      }
      if (bj < 0 || bd > colTol) continue;
      if (radiusSide) {
        out.add([hdr[bj].v, lead.v, t.v]);
      } else {
        out.add([lead.v, hdr[bj].v, t.v]);
      }
    }
  }
  return out;
}

List<String> _checkChart(List<List<double>> rows) {
  final by = <double, List<List<double>>>{};
  for (final r in rows) {
    by.putIfAbsent(r[0], () => <List<double>>[]).add(r);
  }
  final warns = <String>[];
  for (final e in by.entries) {
    final l = e.value;
    l.sort((a, b) => a[1].compareTo(b[1]));
    for (int i = 1; i < l.length; i++) {
      if (l[i][2] > l[i - 1][2] + 0.000001) {
        warns.add(
            'Boom ${_num3(e.key)}: radius ${_num3(l[i - 1][1])} se ${_num3(l[i][1])} par capacity badh rahi hai (OCR galti ho sakti hai)');
      }
    }
  }
  return warns;
}
