import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../database/sqlite_helper.dart';
import '../services/pdf_service.dart';

class LiftPlanScreen extends StatefulWidget {
  const LiftPlanScreen({super.key});

  @override
  State<LiftPlanScreen> createState() => _LiftPlanScreenState();
}

class _LiftPlanScreenState extends State<LiftPlanScreen> {
  final _projectCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _loadDescCtrl = TextEditingController();
  final _loadWeightCtrl = TextEditingController();
  final _craneDetailsCtrl = TextEditingController();
  final _riggingCtrl = TextEditingController();
  final _sequenceCtrl = TextEditingController();
  final _personnelCtrl = TextEditingController();
  final _safetyCtrl = TextEditingController();

  bool _saving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _generate() async {
    if (_projectCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project name is required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await SqliteHelper.instance.insert('LiftPlans', {
        'projectName': _projectCtrl.text,
        'client': _clientCtrl.text,
        'location': _locationCtrl.text,
        'date': _dateCtrl.text,
        'loadDescription': _loadDescCtrl.text,
        'loadWeight': double.tryParse(_loadWeightCtrl.text) ?? 0,
        'craneDetails': _craneDetailsCtrl.text,
        'riggingArrangement': _riggingCtrl.text,
        'liftingSequence': _sequenceCtrl.text,
        'personnel': _personnelCtrl.text,
        'safetyRequirements': _safetyCtrl.text,
      });

      final file = await PdfService.generateLiftPlanPdf(
        projectName: _projectCtrl.text,
        client: _clientCtrl.text,
        location: _locationCtrl.text,
        date: _dateCtrl.text,
        loadDescription: _loadDescCtrl.text,
        loadWeight: '${_loadWeightCtrl.text} t',
        craneDetails: _craneDetailsCtrl.text,
        riggingArrangement: _riggingCtrl.text,
        liftingSequence: _sequenceCtrl.text,
        personnel: _personnelCtrl.text,
        safetyRequirements: _safetyCtrl.text,
      );

      await SqliteHelper.instance.insert('Reports', {
        'reportType': 'Lift Plan',
        'title': _projectCtrl.text,
        'filePath': file.path,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      await Printing.sharePdf(bytes: await file.readAsBytes(), filename: file.path.split('/').last);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lift plan saved and PDF generated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating lift plan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lift Plan Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(_projectCtrl, 'Project Name'),
            _field(_clientCtrl, 'Client'),
            _field(_locationCtrl, 'Location'),
            TextField(
              controller: _dateCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today)),
            ),
            const SizedBox(height: 12),
            _field(_loadDescCtrl, 'Load Description'),
            _field(_loadWeightCtrl, 'Load Weight (t)', type: const TextInputType.numberWithOptions(decimal: true)),
            _field(_craneDetailsCtrl, 'Crane Details', maxLines: 2),
            _field(_riggingCtrl, 'Rigging Arrangement', maxLines: 3),
            _field(_sequenceCtrl, 'Lifting Sequence', maxLines: 4),
            _field(_personnelCtrl, 'Personnel & Responsibilities', maxLines: 2),
            _field(_safetyCtrl, 'Safety Requirements', maxLines: 3),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saving ? null : _generate,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_saving ? 'GENERATING...' : 'SAVE & GENERATE PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
