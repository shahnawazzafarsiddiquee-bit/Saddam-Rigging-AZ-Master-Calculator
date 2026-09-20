part of 'rigging_pro2.dart';

class _DiagramData {
  final double boom;
  final double ang;
  final double radius;
  final double off;
  final double foot;
  final double loadW;
  final double loadH;
  final double bottom;
  final double sling;
  final double obX;
  final double obH;
  const _DiagramData({
    required this.boom,
    required this.ang,
    required this.radius,
    required this.off,
    required this.foot,
    required this.loadW,
    required this.loadH,
    required this.bottom,
    required this.sling,
    required this.obX,
    required this.obH,
  });
}

class _DiagramPainter extends CustomPainter {
  final _DiagramData d;
  _DiagramPainter(this.d);

  @override
  void paint(Canvas canvas, Size size) {
    final tipX = d.off + d.boom * math.cos(d.ang);
    final tipY = d.foot + d.boom * math.sin(d.ang);
    final hookY = math.min(d.bottom + d.loadH + d.sling, tipY - 0.5);
    final maxX = math.max(tipX + d.loadW, d.obX + 2) + 1;
    const minX = -4.0;
    final maxY = tipY + 2;
    const padT = 30.0;
    const padB = 48.0;
    const padX = 24.0;
    final s = math.min((size.width - 2 * padX) / (maxX - minX),
        (size.height - padT - padB) / maxY);
    Offset p(double x, double y) =>
        Offset(padX + (x - minX) * s, size.height - padB - y * s);
    void txt(String t, Offset o, {Color c = Colors.black}) {
      final tp = TextPainter(
        text: TextSpan(
            text: t,
            style: TextStyle(
                color: c, fontSize: 12, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o);
    }

    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawLine(p(minX, 0), p(maxX, 0),
        Paint()..color = Colors.brown..strokeWidth = 3);
    canvas.drawRect(Rect.fromPoints(p(-2.5, 0), p(2.5, d.foot)),
        Paint()..color = Colors.grey.shade600);
    final bootPt = p(d.off, d.foot);
    final tip = p(tipX, tipY);
    canvas.drawLine(
        bootPt,
        tip,
        Paint()
          ..color = const Color(0xFFFF6D00)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
    final hook = p(tipX, hookY);
    final thin = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(tip, hook, thin);
    final loadRect = Rect.fromPoints(p(tipX - d.loadW / 2, d.bottom),
        p(tipX + d.loadW / 2, d.bottom + d.loadH));
    canvas.drawRect(loadRect, Paint()..color = Colors.blueGrey.shade300);
    canvas.drawRect(loadRect, thin);
    canvas.drawLine(hook, p(tipX - d.loadW / 2, d.bottom + d.loadH), thin);
    canvas.drawLine(hook, p(tipX + d.loadW / 2, d.bottom + d.loadH), thin);
    if (d.obX > 0 && d.obH > 0) {
      final ob = Rect.fromPoints(p(d.obX - 1, 0), p(d.obX + 1, d.obH));
      canvas.drawRect(ob, Paint()..color = Colors.red.withOpacity(0.55));
      txt('Obstruction', Offset(ob.left - 8, ob.top - 16), c: Colors.red);
    }
    canvas.drawArc(Rect.fromCircle(center: bootPt, radius: 46), 0, -d.ang,
        false, thin);
    txt('${_f(_deg(d.ang), 1)} deg', bootPt + const Offset(50, -22));
    txt('Boom ${_f(d.boom, 1)} m',
        Offset((bootPt.dx + tip.dx) / 2 - 40, (bootPt.dy + tip.dy) / 2 - 30));
    txt('Tip ${_f(tipY, 1)} m', tip + const Offset(-70, -22));
    final y0 = size.height - 22;
    canvas.drawLine(Offset(p(0, 0).dx, y0), Offset(p(tipX, 0).dx, y0), thin);
    txt('Radius ${_f(d.radius, 1)} m', Offset(p(0, 0).dx + 6, y0 - 18));
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter old) => true;
}

class LiftDiagramScreen extends StatefulWidget {
  const LiftDiagramScreen({super.key});
  @override
  State<LiftDiagramScreen> createState() => _LiftDiagramScreenState();
}

class _LiftDiagramScreenState extends State<LiftDiagramScreen> {
  final boom = TextEditingController();
  final rad = TextEditingController();
  final off = TextEditingController(text: '1.5');
  final foot = TextEditingController(text: '2');
  final lw = TextEditingController(text: '3');
  final lh = TextEditingController(text: '2');
  final land = TextEditingController(text: '5');
  final slh = TextEditingController(text: '3');
  final obx = TextEditingController();
  final obh = TextEditingController();
  final boxKey = GlobalKey();
  List<_R> out = [];
  _DiagramData? data;
  String info = '';

  void calc() {
    final bl = _n(boom);
    final r = _n(rad);
    final a = _n(off);
    final h = _n(foot);
    final x = r - a;
    if (bl <= 0 || r <= 0 || x <= 0 || x >= bl) {
      setState(() {
        data = null;
        out = [
          const _R(
              'Boom length aur radius sahi daalo (boom, radius se bada hona chahiye)',
              3)
        ];
      });
      return;
    }
    final th = math.acos(x / bl);
    final deg = _deg(th);
    final tipX = a + bl * math.cos(th);
    final tipY = h + bl * math.sin(th);
    final loadW = _n(lw);
    final loadH = _n(lh);
    final bottom = _n(land);
    final sling = _n(slh);
    final need = bottom + loadH + sling + 2;
    final res = <_R>[
      _R('Boom angle: ${_f(deg, 1)} deg', (deg < 30 || deg > 80) ? 2 : 1),
      _R('Boom tip height: ${_f(tipY)} m (chahiye ${_f(need)} m)'),
    ];
    final gapTip = tipY - need;
    res.add(_R(
        gapTip >= 0
            ? 'Tip height kaafi hai (${_f(gapTip)} m extra)'
            : 'Tip ${_f(-gapTip)} m kam hai: badi boom ya kam radius',
        gapTip >= 0 ? 1 : 3));
    final ox = _n(obx);
    final oh = _n(obh);
    if (ox > 0 && oh > 0) {
      if (ox > a && ox < tipX) {
        final yb = h + (ox - a) * math.tan(th);
        final gap = yb - oh;
        res.add(_R('Obstruction ke upar boom clearance: ${_f(gap)} m',
            gap < 0.5 ? 3 : (gap < 1.5 ? 2 : 1)));
      }
      if (tipX + loadW / 2 > ox - 1 && tipX - loadW / 2 < ox + 1 && bottom < oh) {
        res.add(const _R('Load obstruction se takra sakta hai', 3));
      }
    }
    setState(() {
      out = res;
      info = '';
      data = _DiagramData(
        boom: bl,
        ang: th,
        radius: r,
        off: a,
        foot: h,
        loadW: loadW,
        loadH: loadH,
        bottom: bottom,
        sling: sling,
        obX: ox,
        obH: oh,
      );
    });
  }

  Future<void> _toPlan() async {
    final png = await _capture(boxKey, ratio: 3);
    if (!mounted) return;
    if (png == null) {
      setState(() => info = 'Diagram capture nahi hua');
      return;
    }
    LiftDiagramCache.png = png;
    setState(() => info =
        'Diagram save ho gaya. Ab Lift Plan PDF banao, usme judega.');
  }

  Future<void> _pdf() async {
    final png = await _capture(boxKey, ratio: 3);
    if (!mounted) return;
    if (png == null) {
      setState(() => info = 'Diagram capture nahi hua');
      return;
    }
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('LIFT DIAGRAM',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Expanded(child: pw.Center(child: pw.Image(pw.MemoryImage(png)))),
          pw.SizedBox(height: 8),
          ...out.map((r) => pw.Text(r.t)),
          pw.SizedBox(height: 6),
          pw.Text('Estimate only. Verify with crane load chart.',
              style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    ));
    final bytes = await doc.save();
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat f) async => bytes, name: 'lift_diagram');
  }

  @override
  void dispose() {
    for (final c in [boom, rad, off, foot, lw, lh, land, slh, obx, obh]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Lift Diagram', [
      _field(boom, 'Boom length', suffix: 'm'),
      _field(rad, 'Working radius (slew centre se)', suffix: 'm'),
      _field(off, 'Boom foot offset', suffix: 'm'),
      _field(foot, 'Boom foot height', suffix: 'm'),
      _field(lw, 'Load width', suffix: 'm'),
      _field(lh, 'Load height', suffix: 'm'),
      _field(land, 'Load ka neeche wala level (ground se)', suffix: 'm'),
      _field(slh, 'Sling height (hook se load top tak)', suffix: 'm'),
      _field(obx, 'Obstruction ki doori slew centre se (optional)',
          suffix: 'm'),
      _field(obh, 'Obstruction ki height (optional)', suffix: 'm'),
      FilledButton(onPressed: calc, child: const Text('Diagram banao')),
      if (data != null) ...[
        const SizedBox(height: 12),
        RepaintBoundary(
          key: boxKey,
          child: SizedBox(
            height: 320,
            width: double.infinity,
            child: CustomPaint(painter: _DiagramPainter(data!)),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _toPlan,
          icon: const Icon(Icons.playlist_add),
          label: const Text('Lift Plan PDF me joda'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Sirf diagram ki PDF'),
        ),
      ],
      _results(out),
      if (info.isNotEmpty) _note(info),
      _note(_disclaimer),
    ]);
  }
}
