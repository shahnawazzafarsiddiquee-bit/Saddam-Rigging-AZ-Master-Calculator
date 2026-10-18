import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../database/sqlite_helper.dart';
import '../services/pdf_service.dart';
import '../services/lift_equipment_service.dart';
import '../models/equipment_model.dart';

class LiftPlanScreen extends StatefulWidget {
  const LiftPlanScreen({super.key});

  @override
  State<LiftPlanScreen> createState() => _LiftPlanScreenState();
}

class _LiftPlanScreenState extends State<LiftPlanScreen> {
  final _projectCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final _loadDescCtrl = TextEditingController();
  final _loadWeightCtrl = TextEditingController();
  final _craneDetailsCtrl = TextEditingController();
  final _riggingCtrl = TextEditingController();
  final _sequenceCtrl = TextEditingController();
  final _personnelCtrl = TextEditingController();
  final _safetyCtrl = TextEditingController();

  bool _saving = false;
  final Set<int> _selectedAssets = {};
  late Future<List<EquipmentModel>> _eligibleAssets;
  @override
  void initState() {
    super.initState();
    _eligibleAssets = LiftEquipmentService.eligible();
  }

  String? _weightError;

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

    final loadWeight = double.tryParse(
      _loadWeightCtrl.text.trim().replaceAll(',', '.'),
    );
    if (loadWeight == null || !loadWeight.isFinite || loadWeight <= 0) {
      setState(
        () =>
            _weightError = 'Load weight must be finite and greater than zero.',
      );
      return;
    }
    setState(() => _weightError = null);
    setState(() => _saving = true);
    try {
      final assets = await _eligibleAssets;
      final selectedText = assets
          .where((a) => _selectedAssets.contains(a.id))
          .map((a) => a.equipmentId)
          .join(', ');
      final riggingText =
          '${_riggingCtrl.text}\nRegistered equipment: $selectedText\nDRAFT - COMPETENT PERSON REVIEW REQUIRED';
      await LiftEquipmentService.save({
        'projectName': _projectCtrl.text,
        'client': _clientCtrl.text,
        'location': _locationCtrl.text,
        'date': _dateCtrl.text,
        'loadDescription': _loadDescCtrl.text,
        'loadWeight': loadWeight,
        'craneDetails': _craneDetailsCtrl.text,
        'riggingArrangement': riggingText,
        'liftingSequence': _sequenceCtrl.text,
        'personnel': _personnelCtrl.text,
        'safetyRequirements': _safetyCtrl.text,
      }, _selectedAssets);

      final file = await PdfService.generateLiftPlanPdf(
        projectName: _projectCtrl.text,
        client: _clientCtrl.text,
        location: _locationCtrl.text,
        date: _dateCtrl.text,
        loadDescription: _loadDescCtrl.text,
        loadWeight: '${_loadWeightCtrl.text} t',
        craneDetails: _craneDetailsCtrl.text,
        riggingArrangement: riggingText,
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
      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename: file.path.split('/').last,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lift plan saved and PDF generated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error generating lift plan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _projectCtrl,
      _clientCtrl,
      _locationCtrl,
      _dateCtrl,
      _loadDescCtrl,
      _loadWeightCtrl,
      _craneDetailsCtrl,
      _riggingCtrl,
      _sequenceCtrl,
      _personnelCtrl,
      _safetyCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType? type,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, errorText: errorText),
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
              decoration: const InputDecoration(
                labelText: 'Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 12),
            _field(_loadDescCtrl, 'Load Description'),
            _field(
              _loadWeightCtrl,
              'Load Weight (t)',
              type: const TextInputType.numberWithOptions(decimal: true),
              errorText: _weightError,
            ),
            _field(_craneDetailsCtrl, 'Crane Details', maxLines: 2),
            _field(_riggingCtrl, 'Rigging Arrangement', maxLines: 3),
            ExpansionTile(
              title: const Text('Select registered rigging equipment'),
              subtitle: const Text(
                'Expired, held, quarantined and uncertified assets are excluded. Selection rechecked on save.',
              ),
              children: [
                FutureBuilder<List<EquipmentModel>>(
                  future: _eligibleAssets,
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Equipment could not be loaded. Reopen this screen to retry.',
                        ),
                      );
                    if (!snapshot.hasData)
                      return const LinearProgressIndicator();
                    if (snapshot.data!.isEmpty)
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'No eligible assets. Register an asset and link its exact equipment ID in Certificates.',
                        ),
                      );
                    return Column(
                      children: snapshot.data!
                          .map(
                            (a) => CheckboxListTile(
                              title: Text(a.equipmentId),
                              subtitle: Text('${a.type} | WLL ${a.wll} t'),
                              value: _selectedAssets.contains(a.id),
                              onChanged: _saving
                                  ? null
                                  : (v) => setState(() {
                                      if (v == true) {
                                        _selectedAssets.add(a.id!);
                                      } else {
                                        _selectedAssets.remove(a.id);
                                      }
                                    }),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
            const Text(
              'DRAFT - selected equipment still requires physical fit, rating and certificate-document verification. Saving does not authorize lifting.',
            ),
            _field(_sequenceCtrl, 'Lifting Sequence', maxLines: 4),
            _field(_personnelCtrl, 'Personnel & Responsibilities', maxLines: 2),
            _field(_safetyCtrl, 'Safety Requirements', maxLines: 3),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saving ? null : _generate,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_saving ? 'GENERATING...' : 'SAVE & GENERATE PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
