import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../app/theme.dart';
import '../services/ground_planning.dart';
import '../services/ground_repository.dart';
import '../services/calculation_engine.dart';
import '../services/pdf_service.dart';
import '../database/sqlite_helper.dart';

class GroundBearingScreen extends StatefulWidget {
  final String projectHint;
  final bool returnRecord;
  const GroundBearingScreen({
    super.key,
    this.projectHint = '',
    this.returnRecord = false,
  });
  @override
  State<GroundBearingScreen> createState() => _GroundBearingScreenState();
}

class _GroundBearingScreenState extends State<GroundBearingScreen> {
  final fields = <String, TextEditingController>{};
  String kind = 'MANUFACTURER', message = '';
  bool verified = false, busy = false;
  Map<String, Object?>? record;
  TextEditingController c(String key) =>
      fields.putIfAbsent(key, TextEditingController.new);
  @override
  void initState() {
    super.initState();
    c('Project / site').text = widget.projectHint;
    c('Mat quantity (inventory only)').text = '1';
  }

  @override
  void dispose() {
    for (final v in fields.values) {
      v.dispose();
    }
    super.dispose();
  }

  double number(String key) {
    final v = double.tryParse(c(key).text.trim().replaceAll(',', '.'));
    if (v == null || !v.isFinite)
      throw ArgumentError('$key requires a finite number.');
    return v;
  }

  double? optional(String key) =>
      c(key).text.trim().isEmpty ? null : number(key);
  Widget field(String key, {String? unit}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c(key),
      keyboardType: unit == null
          ? TextInputType.text
          : const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: key,
        suffixText: unit,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {
        record = null;
        verified = false;
        message = '';
      }),
    ),
  );
  Map<String, Object?> buildRecord() {
    final count = int.tryParse(c('Mat quantity (inventory only)').text.trim());
    if (count == null) throw ArgumentError('Mat quantity must be an integer.');
    return GroundPlanning.record(
      context: {
        'project': c('Project / site').text,
        'crane': c('Crane model / asset ID').text,
        'configuration': c('Crane configuration / boom position').text,
        'quadrant': c('Operating quadrant').text,
        'reactionKind': kind,
        'reactionSource': c('Reaction source, configuration & revision').text,
        'groundSource': c('Ground report / project document').text,
        'revision': c('Ground document revision').text,
        'approvedBy': c('Ground value approved by').text,
        'matType': c('Mat type / asset reference').text,
      },
      reactionN:
          number('Maximum outrigger reaction from verified source') *
          1000 *
          CalculationEngine.gravity,
      lengthM: number('Effective bearing length'),
      widthM: number('Effective bearing width'),
      allowablePa:
          number('Allowable ground pressure from approved report') *
          1000 *
          CalculationEngine.gravity,
      padLengthM: optional('Pad length'),
      padWidthM: optional('Pad width'),
      thicknessM: optional('Mat thickness') == null
          ? null
          : number('Mat thickness') / 1000,
      quantity: count,
      verified: verified,
      now: DateTime.now(),
    );
  }

  void calculate() {
    try {
      final data = buildRecord();
      setState(() {
        record = data;
        message = '';
      });
    } catch (e) {
      setState(() {
        record = null;
        message = e.toString();
      });
    }
  }

  Future<void> save({bool pdf = false}) async {
    setState(() => busy = true);
    try {
      final data = buildRecord();
      final saved = await GroundRepository.save(data);
      if (pdf) {
        final result = data['result'] as Map,
            inputs = result['inputs'] as Map,
            values = result['values'] as Map;
        final file = await PdfService.generateCalculationPdf(
          calculatorName: 'Ground Bearing',
          inputs: {
            'Project / crane': '${data['project']} / ${data['crane']}',
            'Configuration / quadrant':
                '${data['configuration']} / ${data['quadrant']}',
            'Reaction method/source':
                '${data['reactionKind']}: ${data['reactionSource']}',
            'Ground document / revision':
                '${data['groundSource']} / ${data['revision']}',
            'Approved by': '${data['approvedBy']}',
            'Reaction N': '${inputs['reactionN']}',
            'Allowable Pa': '${inputs['allowablePa']}',
            'Mat L x W x thickness m':
                '${inputs['lengthM']} x ${inputs['widthM']} x ${data['thicknessM']}',
            'Pad L x W m': '${data['padLengthM']} x ${data['padWidthM']}',
            'Mat type / inventory quantity':
                '${data['matType']} / ${data['quantity']}',
          },
          results: {
            'Pressure Pa': '${values['pressurePa']}',
            'Required area m2': '${values['requiredAreaM2']}',
            'Provided area m2': '${values['providedAreaM2']}',
            'Utilization %': '${values['utilizationPercent']}',
            'Limitation': 'Single outrigger, uniform effective bearing. Mat strength and ground engineering approval excluded. Quantity does not increase area.',
          },
          verdict:
              '${result['status']} - calculation only; no lifting authorization',
        );
        await SqliteHelper.instance.insert('Reports', {
          'reportType': 'Ground Bearing',
          'title': data['project'],
          'filePath': file.path,
          'createdAt': data['createdAt'],
        });
        if (!mounted) return;
        await Printing.sharePdf(
          bytes: await file.readAsBytes(),
          filename: file.path.split('/').last,
        );
      }
      if (!mounted) return;
      if (widget.returnRecord) {
        Navigator.pop(context, saved);
        return;
      }
      setState(() {
        record = data;
        message = 'Saved Ground #${saved['recordId']} offline.';
      });
    } catch (e) {
      if (mounted) setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> history() async {
    try {
      final rows = await GroundRepository.history();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ground history'),
          content: SizedBox(
            width: 500,
            child: ListView(
              shrinkWrap: true,
              children: [
                if (rows.isEmpty) const Text('No ground records saved.'),
                for (final row in rows)
                  ListTile(
                    title: Text('#${row['recordId']} ${row['project']}'),
                    subtitle: Text('${row['createdAt']}'),
                    onTap: () => showDialog<void>(
                      context: ctx,
                      builder: (detail) => AlertDialog(
                        title: const Text('Saved ground record'),
                        content: SingleChildScrollView(
                          child: SelectableText(
                            const JsonEncoder.withIndent('  ').convert(row),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(detail),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) setState(() => message = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = record?['result'] as Map?,
        values = result?['values'] as Map?,
        inputs = result?['inputs'] as Map?;
    final status = result?['status'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ground Bearing'),
        actions: [
          IconButton(
            onPressed: busy ? null : history,
            icon: const Icon(Icons.history),
            tooltip: 'Ground history',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Single-outrigger bearing-area check. Enter the effective footprint verified by engineering; do not infer soil capacity from GPS.',
            ),
            const SizedBox(height: 12),
            field(
              'Maximum outrigger reaction from verified source',
              unit: 'tonne-force',
            ),
            field('Effective bearing length', unit: 'm'),
            field('Effective bearing width', unit: 'm'),
            field(
              'Allowable ground pressure from approved report',
              unit: 'tonne-force/m2',
            ),
            field('Pad length', unit: 'm'),
            field('Pad width', unit: 'm'),
            field('Mat thickness', unit: 'mm'),
            field('Mat quantity (inventory only)', unit: 'count'),
            field('Mat type / asset reference'),
            field('Project / site'),
            field('Crane model / asset ID'),
            field('Crane configuration / boom position'),
            field('Operating quadrant'),
            DropdownButtonFormField<String>(
              initialValue: kind,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Reaction method'),
              items: [
                for (final v in ['MANUFACTURER', 'ENGINEERING ESTIMATE'])
                  DropdownMenuItem(value: v, child: Text(v)),
              ],
              onChanged: (v) => setState(() {
                kind = v!;
                record = null;
                verified = false;
              }),
            ),
            const SizedBox(height: 12),
            field('Ground report / project document'),
            field('Ground document revision'),
            field('Ground value approved by'),
            field('Reaction source, configuration & revision'),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: verified,
              title: const Text(
                'Ground value and maximum reaction verified against the documents',
              ),
              onChanged: (v) => setState(() {
                verified = v ?? false;
                record = null;
              }),
            ),
            ElevatedButton(
              onPressed: busy ? null : calculate,
              child: const Text('Calculate'),
            ),
            if (message.isNotEmpty)
              Padding(padding: const EdgeInsets.all(12), child: Text(message)),
            if (result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        status == 'acceptable'
                            ? 'ACCEPTABLE - CALCULATION ONLY'
                            : status == 'notAcceptable'
                            ? 'NOT ACCEPTABLE'
                            : status == 'reviewRequired'
                            ? 'REVIEW REQUIRED'
                            : 'INCOMPLETE - VERIFICATION REQUIRED',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: status == 'acceptable'
                              ? AppColors.success
                              : status == 'notAcceptable'
                              ? AppColors.danger
                              : AppColors.warning,
                        ),
                      ),
                      Text(
                        'Pressure: ${((values!['pressurePa'] as num) / 1000).toStringAsFixed(2)} kPa',
                      ),
                      Text('Provided area: ${values['providedAreaM2']} m2'),
                      Text('Required area: ${values['requiredAreaM2']} m2'),
                      Text(
                        'Utilization: ${(values['utilizationPercent'] as num).toStringAsFixed(2)}%',
                      ),
                      SizedBox(
                        height: 200,
                        child: CustomPaint(
                          painter: _MatDrawing(
                            (inputs!['lengthM'] as num).toDouble(),
                            (inputs['widthM'] as num).toDouble(),
                            (record!['padLengthM'] as num?)?.toDouble() ?? 0,
                            (record!['padWidthM'] as num?)?.toDouble() ?? 0,
                          ),
                        ),
                      ),
                      Text(
                        'Top view: effective mat footprint ${inputs['lengthM']} x ${inputs['widthM']} m; centered pad ${record!['padLengthM']} x ${record!['padWidthM']} m. Position is illustrative, not a verified site arrangement.',
                      ),
                      for (final w in result['warnings'] as List) Text('$w'),
                      ElevatedButton(
                        onPressed: busy ? null : () => save(),
                        child: Text(
                          widget.returnRecord
                              ? 'Save & attach to draft'
                              : 'Save ground record',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : () => save(pdf: true),
                        child: const Text('Save & export PDF'),
                      ),
                    ],
                  ),
                ),
              ),
            const Text(
              'Mat thickness, stiffness, bending, contact pressure, ground voids and load spreading require engineering verification. Final lifting authorization remains with authorized personnel.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MatDrawing extends CustomPainter {
  final double length, width, padLength, padWidth;
  _MatDrawing(this.length, this.width, this.padLength, this.padWidth);
  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width - 32) / length < (size.height - 32) / width
        ? (size.width - 32) / length
        : (size.height - 32) / width;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: length * scale,
        height: width * scale,
      ),
      Paint()
        ..color = AppColors.safetyOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: padLength * scale,
        height: padWidth * scale,
      ),
      Paint()..color = AppColors.navy,
    );
    canvas.drawLine(
      center - const Offset(8, 0),
      center + const Offset(8, 0),
      Paint()
        ..color = AppColors.safetyOrange
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      center - const Offset(0, 8),
      center + const Offset(0, 8),
      Paint()
        ..color = AppColors.safetyOrange
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _MatDrawing old) =>
      old.length != length ||
      old.width != width ||
      old.padLength != padLength ||
      old.padWidth != padWidth;
}

class GroundAttachment extends StatelessWidget {
  final Map<String, Object?>? value;
  final String project;
  final ValueChanged<Map<String, Object?>?> onChanged;
  const GroundAttachment({
    super.key,
    required this.value,
    required this.project,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ground bearing attachment',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value == null
                ? 'No ground record attached.'
                : GroundRepository.summary(value),
          ),
          OutlinedButton(
            onPressed: () async {
              final data = await Navigator.push<Map<String, Object?>>(
                context,
                MaterialPageRoute(
                  builder: (_) => GroundBearingScreen(
                    projectHint: project,
                    returnRecord: true,
                  ),
                ),
              );
              if (data != null) onChanged(data);
            },
            child: const Text('Calculate & attach ground record'),
          ),
          if (value != null)
            TextButton(
              onPressed: () => onChanged(null),
              child: const Text('Remove from draft'),
            ),
        ],
      ),
    ),
  );
}
