import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/radius_planning.dart';
import '../services/calculation_engine.dart';
import '../services/backup_service.dart';
import '../app/calculation_details.dart';

/// Existing Crane Boom & Capacity route, extended with surveyed radius methods.
class CraneBoomScreen extends StatefulWidget {
  const CraneBoomScreen({super.key});
  @override
  State<CraneBoomScreen> createState() => _CraneBoomScreenState();
}

class _CraneBoomScreenState extends State<CraneBoomScreen> {
  final fields = <String, TextEditingController>{};
  String method = 'Manual', message = '';
  bool verified = false, chartVerified = false, saving = false;
  Map<String, Object?>? result;
  Map<String, double>? geometry;
  CalculationResult? capacity;
  Uint8List? drawing;
  int imageWidth = 1, imageHeight = 1;
  final points = <PlanPoint>[];
  static const pointLabels = [
    'Scale start',
    'Scale end',
    'Crane centre',
    'Pick point',
    'Set point',
  ];
  TextEditingController c(String name) =>
      fields.putIfAbsent(name, TextEditingController.new);
  double n(String name) {
    final v = double.tryParse(c(name).text.trim().replaceAll(',', '.'));
    if (v == null || !v.isFinite)
      throw ArgumentError('$name requires a finite number.');
    return v;
  }

  void invalidate() {
    setState(() {
      result = null;
      capacity = null;
      geometry = null;
      message = '';
    });
  }

  Widget field(String name, {bool text = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c(name),
      keyboardType: text
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true, signed: true),
      onChanged: (_) => invalidate(),
      decoration: InputDecoration(
        labelText: name,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  @override
  void dispose() {
    for (final value in fields.values) {
      value.dispose();
    }
    super.dispose();
  }

  Future<void> pickDrawing() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024)
        throw ArgumentError('Drawing must be below 5 MB.');
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width, h = frame.image.height;
      frame.image.dispose();
      codec.dispose();
      if (!mounted) return;
      setState(() {
        drawing = bytes;
        imageWidth = w;
        imageHeight = h;
        points.clear();
        result = null;
        message = '';
      });
    } catch (e) {
      if (mounted) setState(() => message = '$e');
    }
  }

  void calculate() {
    try {
      double pick, set;
      switch (method) {
        case 'Site geometry':
          final crane = PlanPoint(n('Crane X (m)'), n('Crane Y (m)'));
          pick = RadiusPlanning.distance(
            crane,
            PlanPoint(n('Pick X (m)'), n('Pick Y (m)')),
          );
          set = RadiusPlanning.distance(
            crane,
            PlanPoint(n('Set X (m)'), n('Set Y (m)')),
          );
          break;
        case 'Scaled drawing':
          if (drawing == null || points.length != 5)
            throw ArgumentError('Import a plan and select all five points.');
          double measure(PlanPoint target) => RadiusPlanning.drawingRadius(
            scaleStart: points[0],
            scaleEnd: points[1],
            scaleMetres: n('Known scale distance (m)'),
            crane: points[2],
            load: target,
          );
          pick = measure(points[3]);
          set = measure(points[4]);
          break;
        case 'Boom geometry':
          double radius(String angle) => CalculationEngine.boomRadiusM(
            boomM: n('Boom length (m)'),
            angleDegrees: n(angle),
            pivotOffsetM: n('Signed pivot offset (m)'),
            hookOffsetM: n('Inward hook offset (m)'),
          );
          pick = radius('Pick boom angle from horizontal (deg)');
          set = radius('Set boom angle from horizontal (deg)');
          break;
        default:
          pick = n('Pick radius (m)');
          set = n('Set radius (m)');
      }
      final r = RadiusPlanning.record(
        method: method,
        source: c('Source / drawing revision / datum').text,
        inputs: {
          for (final e in fields.entries) e.key: e.value.text,
          if (method == 'Scaled drawing')
            'drawingPoints': points.map((p) => p.toJson()).toList(),
          if (method == 'Scaled drawing')
            'imagePixels': [imageWidth, imageHeight],
        },
        pickM: pick,
        setM: set,
        maximumM: n('Maximum entire-path radius (m)'),
        verifiedPickM: verified ? n('Verified pick radius (m)') : null,
        verifiedSetM: verified ? n('Verified set radius (m)') : null,
        verifiedMaximumM: verified ? n('Verified maximum radius (m)') : null,
        verifiedBy: verified ? c('Field verified by').text : '',
        verifiedAt: verified ? DateTime.now() : null,
      );
      Map<String, double>? g;
      if (c('Required boom tip height (m)').text.trim().isNotEmpty) {
        final maxR = verified
            ? n('Verified maximum radius (m)')
            : n('Maximum entire-path radius (m)');
        g = RadiusPlanning.heightGeometry(
          radiusM: maxR,
          pivotOffsetM: n('Height calculation pivot offset (m)'),
          tipHeightM: n('Required boom tip height (m)'),
          pivotHeightM: n('Pivot height above ground (m)'),
        );
      }
      CalculationResult? cap;
      if (c('Payload (t)').text.trim().isNotEmpty ||
          c('Limiting chart capacity (t)').text.trim().isNotEmpty) {
        final gross = CalculationEngine.grossLoadKg(n('Payload (t)') * 1000, [
          n('All accessories + hook block (t)') * 1000,
        ]);
        cap = CalculationEngine.craneUtilization(
          grossKg: gross,
          capacityKg: n('Limiting chart capacity (t)') * 1000,
          chartSource: c('Chart / configuration / page / revision').text,
          configurationVerified: verified && chartVerified,
        );
        r['capacityCheck'] = cap.toJson();
      }
      if (g != null) r['heightGeometryEstimate'] = g;
      setState(() {
        result = r;
        geometry = g;
        capacity = cap;
        message = '';
      });
    } catch (e) {
      setState(() {
        result = null;
        geometry = null;
        capacity = null;
        message = '$e';
      });
    }
  }

  Future<void> save() async {
    calculate();
    if (result == null || saving) return;
    final saved = Map<String, Object?>.from(result!);
    final image = method == 'Scaled drawing' && drawing != null
        ? base64Encode(drawing!)
        : null;
    setState(() => saving = true);
    try {
      final id = await BackupService.withDatabases(
        (db) => db.insert('Calculations', {
          'calculatorType': 'Smart Radius',
          'inputJson': jsonEncode({
            'inputs': saved['inputs'],
            if (image != null) 'drawingBase64': image,
          }),
          'resultJson': jsonEncode(saved),
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      if (mounted)
        setState(
          () => message =
              'Saved radius record #$id offline. Approval is still required.',
        );
    } catch (e) {
      if (mounted) setState(() => message = 'Could not save: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> history() async {
    try {
      final rows = await BackupService.withDatabases(
        (db) => db.query(
          'Calculations',
          where: 'calculatorType = ?',
          whereArgs: ['Smart Radius'],
          orderBy: 'id DESC',
        ),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Saved radius records'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (rows.isEmpty) const Text('No saved radius records.'),
                for (final row in rows)
                  ExpansionTile(
                    title: Text('#${row['id']} — ${row['createdAt']}'),
                    children: [
                      SelectableText(
                        const JsonEncoder.withIndent('  ')
                            .convert(jsonDecode(row['resultJson'] as String)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => message = 'Could not load records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final calculated = result?['calculated'] as Map<String, double>?;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crane Boom & Smart Radius'),
        actions: [
          IconButton(
            onPressed: history,
            icon: const Icon(Icons.history),
            tooltip: 'Radius history',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'RADIUS REQUIRES FIELD VERIFICATION\nPhone GPS is not a safety-critical radius measurement. Values below are estimates until verified on site.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: method,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Radius method'),
              items: [
                'Manual',
                'Site geometry',
                'Scaled drawing',
                'Boom geometry',
              ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    method = v;
                    verified = false;
                    result = null;
                    capacity = null;
                    geometry = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            field('Source / drawing revision / datum', text: true),
            if (method == 'Manual') ...[
              field('Pick radius (m)'),
              field('Set radius (m)'),
            ],
            if (method == 'Site geometry') ...[
              const Text(
                'Use surveyed coordinates in one horizontal local datum, in metres. Do not enter latitude/longitude degrees.',
              ),
              for (final label in [
                'Crane X (m)',
                'Crane Y (m)',
                'Pick X (m)',
                'Pick Y (m)',
                'Set X (m)',
                'Set Y (m)',
              ])
                field(label),
            ],
            if (method == 'Boom geometry') ...[
              const Text(
                'Estimated rigid boom geometry only: R = L cos(angle) + signed pivot offset - inward hook offset. Verify offsets and manufacturer geometry. Deflection/jib are not inferred.',
              ),
              for (final label in [
                'Boom length (m)',
                'Pick boom angle from horizontal (deg)',
                'Set boom angle from horizontal (deg)',
                'Signed pivot offset (m)',
                'Inward hook offset (m)',
              ])
                field(label),
              Builder(
                builder: (context) {
                  final length = double.tryParse(c('Boom length (m)').text),
                      angle = double.tryParse(
                        c('Pick boom angle from horizontal (deg)').text,
                      );
                  if (length == null ||
                      angle == null ||
                      !length.isFinite ||
                      !angle.isFinite ||
                      length <= 0 ||
                      angle < 0 ||
                      angle > 90)
                    return const SizedBox.shrink();
                  return SizedBox(
                    height: 160,
                    child: CustomPaint(
                      painter: _BoomPainter(
                        angle,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
            ],
            if (method == 'Scaled drawing') ...[
              OutlinedButton.icon(
                onPressed: pickDrawing,
                icon: const Icon(Icons.image),
                label: const Text('Import drawing image'),
              ),
              const Text(
                'Use an orthographic plan without perspective distortion. Scale and verify on site. Tap scale start, scale end, crane centre, pick and set in order.',
              ),
              field('Known scale distance (m)'),
              if (drawing != null) ...[
                Text(
                  points.length < 5
                      ? 'Next: ${pointLabels[points.length]}'
                      : 'All five points selected.',
                ),
                LayoutBuilder(
                  builder: (context, constraints) => GestureDetector(
                    onTapDown: (event) {
                      if (points.length >= 5) return;
                      final scale = imageWidth / constraints.maxWidth;
                      setState(() {
                        points.add(
                          PlanPoint(
                            event.localPosition.dx * scale,
                            event.localPosition.dy * scale,
                          ),
                        );
                        result = null;
                      });
                    },
                    child: AspectRatio(
                      aspectRatio: imageWidth / imageHeight,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(drawing!, fit: BoxFit.fill),
                          CustomPaint(
                            painter: _PlanPainter(
                              points,
                              imageWidth,
                              imageHeight,
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    points.clear();
                    result = null;
                  }),
                  child: const Text('Reset drawing points'),
                ),
              ],
            ],
            field('Maximum entire-path radius (m)'),
            const Text(
              'Maximum radius must include the complete path, not just endpoints. Check each pick, path and set configuration against its applicable chart; there is no automatic chart interpolation.',
            ),
            CheckboxListTile(
              value: verified,
              title: const Text('I have verified all radii in the field'),
              subtitle: const Text(
                'Local named attestation; identity is not authenticated.',
              ),
              onChanged: (v) => setState(() {
                verified = v ?? false;
                result = null;
                capacity = null;
              }),
            ),
            if (verified) ...[
              field('Verified pick radius (m)'),
              field('Verified set radius (m)'),
              field('Verified maximum radius (m)'),
              field('Field verified by', text: true),
            ],
            ExpansionTile(
              title: const Text('Boom height geometry (optional)'),
              children: [
                const Text(
                  'Tip height must include landing height, load height, sling height and hook-to-tip clearance. This is a geometric estimate, not a manufacturer boom selection.',
                ),
                field('Required boom tip height (m)'),
                field('Height calculation pivot offset (m)'),
                field('Pivot height above ground (m)'),
              ],
            ),
            ExpansionTile(
              title: const Text('Gross load and capacity check (optional)'),
              children: [
                field('Payload (t)'),
                field('All accessories + hook block (t)'),
                field('Limiting chart capacity (t)'),
                field('Chart / configuration / page / revision', text: true),
                CheckboxListTile(
                  value: chartVerified,
                  title: const Text(
                    'All required chart configurations and deductions verified',
                  ),
                  onChanged: (v) => setState(() {
                    chartVerified = v ?? false;
                    result = null;
                    capacity = null;
                  }),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: saving ? null : calculate,
              child: const Text('Calculate'),
            ),
            if (message.isNotEmpty)
              Padding(padding: const EdgeInsets.all(12), child: Text(message)),
            if (result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${result!['status']}'),
                      for (final entry in calculated!.entries)
                        Text(
                          '${entry.key}: ${entry.value.toStringAsFixed(3)} m',
                        ),
                      if (geometry != null)
                        Text(
                          'Estimated boom: ${geometry!['boomM']!.toStringAsFixed(3)} m, angle: ${geometry!['angleDegrees']!.toStringAsFixed(2)} degrees',
                        ),
                      if (capacity != null) ...[
                        Text(
                          'Crane utilization: ${capacity!.values['utilizationPercent']!.toStringAsFixed(2)}%',
                        ),
                        CalculationDetails(result: capacity!),
                      ],
                      const Text(
                        'Final approval remains with authorized personnel.',
                      ),
                      ElevatedButton.icon(
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.save),
                        label: Text(
                          saving ? 'Saving...' : 'Save radius record',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanPainter extends CustomPainter {
  final List<PlanPoint> points;
  final int width, height;
  final Color color;
  _PlanPainter(List<PlanPoint> points, this.width, this.height, this.color)
    : points = List.of(points);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    Offset position(PlanPoint p) =>
        Offset(p.x / width * size.width, p.y / height * size.height);
    if (points.length >= 2)
      canvas.drawLine(position(points[0]), position(points[1]), paint);
    if (points.length >= 4)
      canvas.drawLine(position(points[2]), position(points[3]), paint);
    if (points.length >= 5)
      canvas.drawLine(position(points[2]), position(points[4]), paint);
    for (var i = 0; i < points.length; i++) {
      final pos = position(points[i]);
      canvas.drawCircle(pos, 5, paint);
      final label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, pos + const Offset(5, 4));
    }
  }

  @override
  bool shouldRepaint(covariant _PlanPainter old) => true;
}

class _BoomPainter extends CustomPainter {
  final double angle;
  final Color color;
  _BoomPainter(this.angle, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 4;
    final base = Offset(24, size.height - 16),
        length = math.min(size.width - 48, size.height - 32);
    final tip =
        base +
        Offset(
          length * math.cos(angle * math.pi / 180),
          -length * math.sin(angle * math.pi / 180),
        );
    canvas.drawLine(base, tip, p);
    canvas.drawCircle(base, 6, p);
    p.strokeWidth = 1;
    canvas.drawLine(tip, Offset(tip.dx, base.dy), p);
    canvas.drawLine(base, Offset(tip.dx, base.dy), p);
  }

  @override
  bool shouldRepaint(covariant _BoomPainter old) =>
      angle != old.angle || color != old.color;
}
