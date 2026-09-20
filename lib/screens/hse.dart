import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../app/theme.dart';
import '../database/sqlite_helper.dart';
import '../services/pdf_service.dart';

class HseScreen extends StatelessWidget {
  const HseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HSE Safety'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.safetyOrange,
            tabs: [
              Tab(text: 'JSA'),
              Tab(text: 'Risk Assessment'),
              Tab(text: 'Toolbox Talk'),
              Tab(text: 'Inspection'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _JsaTab(),
            _RiskAssessmentTab(),
            _ToolboxTalkTab(),
            _InspectionTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// JSA
// ---------------------------------------------------------------------------
class _JsaStep {
  final TextEditingController step = TextEditingController();
  final TextEditingController hazard = TextEditingController();
  final TextEditingController risk = TextEditingController();
  final TextEditingController control = TextEditingController();
}

class _JsaTab extends StatefulWidget {
  const _JsaTab();
  @override
  State<_JsaTab> createState() => _JsaTabState();
}

class _JsaTabState extends State<_JsaTab> {
  final _activityCtrl = TextEditingController();
  final List<_JsaStep> _steps = [_JsaStep()];
  bool _saving = false;

  Future<void> _generate() async {
    if (_activityCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the activity name.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final stepsData = _steps
          .map((s) => {
                'step': s.step.text,
                'hazard': s.hazard.text,
                'risk': s.risk.text,
                'control': s.control.text,
              })
          .toList();

      final file = await PdfService.generateJsaPdf(activity: _activityCtrl.text, steps: stepsData);

      await SqliteHelper.instance.insert('SafetyRecords', {
        'recordType': 'JSA',
        'title': _activityCtrl.text,
        'detailsJson': stepsData.toString(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      await SqliteHelper.instance.insert('Reports', {
        'reportType': 'JSA',
        'title': _activityCtrl.text,
        'filePath': file.path,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      await Printing.sharePdf(bytes: await file.readAsBytes(), filename: file.path.split('/').last);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _activityCtrl, decoration: const InputDecoration(labelText: 'Activity')),
          const SizedBox(height: 12),
          for (int i = 0; i < _steps.length; i++) _buildStepCard(i),
          OutlinedButton.icon(
            onPressed: () => setState(() => _steps.add(_JsaStep())),
            icon: const Icon(Icons.add),
            label: const Text('ADD WORK STEP'),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saving ? null : _generate,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(_saving ? 'GENERATING...' : 'GENERATE JSA PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int i) {
    final s = _steps[i];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Text('Step ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_steps.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => setState(() => _steps.removeAt(i)),
                ),
            ]),
            TextField(controller: s.step, decoration: const InputDecoration(labelText: 'Work Step')),
            const SizedBox(height: 8),
            TextField(controller: s.hazard, decoration: const InputDecoration(labelText: 'Hazard')),
            const SizedBox(height: 8),
            TextField(controller: s.risk, decoration: const InputDecoration(labelText: 'Risk')),
            const SizedBox(height: 8),
            TextField(controller: s.control, decoration: const InputDecoration(labelText: 'Control Measure')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Risk Assessment — Risk Score = Probability x Severity
// ---------------------------------------------------------------------------
class _RiskAssessmentTab extends StatefulWidget {
  const _RiskAssessmentTab();
  @override
  State<_RiskAssessmentTab> createState() => _RiskAssessmentTabState();
}

class _RiskAssessmentTabState extends State<_RiskAssessmentTab> {
  int _probability = 3;
  int _severity = 3;

  String _riskLevel(int score) {
    if (score <= 4) return 'LOW';
    if (score <= 9) return 'MEDIUM';
    if (score <= 15) return 'HIGH';
    return 'EXTREME';
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'LOW':
        return AppColors.success;
      case 'MEDIUM':
        return AppColors.warning;
      case 'HIGH':
        return Colors.deepOrange;
      default:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _probability * _severity;
    final level = _riskLevel(score);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Probability: $_probability', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _probability.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_probability',
            activeColor: AppColors.safetyOrange,
            onChanged: (v) => setState(() => _probability = v.round()),
          ),
          const SizedBox(height: 8),
          Text('Severity: $_severity', style: const TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: _severity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_severity',
            activeColor: AppColors.safetyOrange,
            onChanged: (v) => setState(() => _severity = v.round()),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ResultRow(label: 'Risk Score (P x S)', value: '$score'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _riskColor(level).withOpacity(0.18),
                      border: Border.all(color: _riskColor(level), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'RISK LEVEL: $level',
                        style: TextStyle(color: _riskColor(level), fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbox Talk
// ---------------------------------------------------------------------------
class _ToolboxTalkTab extends StatefulWidget {
  const _ToolboxTalkTab();
  @override
  State<_ToolboxTalkTab> createState() => _ToolboxTalkTabState();
}

class _ToolboxTalkTabState extends State<_ToolboxTalkTab> {
  final _topicCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _supervisorCtrl = TextEditingController();
  final _attendanceCtrl = TextEditingController();

  Future<void> _save() async {
    if (_topicCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a topic.')));
      return;
    }
    await SqliteHelper.instance.insert('SafetyRecords', {
      'recordType': 'Toolbox Talk',
      'title': _topicCtrl.text,
      'detailsJson':
          '{"date":"${_dateCtrl.text}","supervisor":"${_supervisorCtrl.text}","attendance":"${_attendanceCtrl.text}"}',
      'createdAt': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toolbox talk record saved.')));
    _topicCtrl.clear();
    _supervisorCtrl.clear();
    _attendanceCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(controller: _topicCtrl, decoration: const InputDecoration(labelText: 'Topic')),
          const SizedBox(height: 12),
          TextField(controller: _dateCtrl, decoration: const InputDecoration(labelText: 'Date')),
          const SizedBox(height: 12),
          TextField(controller: _supervisorCtrl, decoration: const InputDecoration(labelText: 'Supervisor')),
          const SizedBox(height: 12),
          TextField(
            controller: _attendanceCtrl,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Attendance (names, comma separated)'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('SAVE TOOLBOX TALK')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inspection checklists
// ---------------------------------------------------------------------------
class _InspectionTab extends StatefulWidget {
  const _InspectionTab();
  @override
  State<_InspectionTab> createState() => _InspectionTabState();
}

class _InspectionTabState extends State<_InspectionTab> {
  String _checklistType = 'Crane Checklist';

  static const _craneItems = [
    'Load chart available in cab',
    'Hoist limit switch functional',
    'Outriggers fully extended & set',
    'Hydraulic hoses free of leaks',
    'Wire rope free of visible damage',
    'Boom angle indicator working',
    'Fire extinguisher present & in date',
  ];

  static const _riggingItems = [
    'Sling free of cuts, kinks, corrosion',
    'Shackle pin fully seated & secured',
    'WLL tag legible on all equipment',
    'No signs of overload/deformation',
    'Inspection date within validity',
    'Hooks fitted with safety latch',
  ];

  late Map<String, bool> _checks;

  @override
  void initState() {
    super.initState();
    _resetChecks();
  }

  void _resetChecks() {
    final items = _checklistType == 'Crane Checklist' ? _craneItems : _riggingItems;
    _checks = {for (final i in items) i: false};
  }

  Future<void> _save() async {
    final passed = _checks.values.where((v) => v).length;
    final total = _checks.length;
    await SqliteHelper.instance.insert('SafetyRecords', {
      'recordType': 'Inspection Checklist',
      'title': _checklistType,
      'detailsJson': _checks.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checklist saved: $passed / $total items passed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Crane Checklist', label: Text('Crane')),
              ButtonSegment(value: 'Rigging Checklist', label: Text('Rigging')),
            ],
            selected: {_checklistType},
            onSelectionChanged: (s) => setState(() {
              _checklistType = s.first;
              _resetChecks();
            }),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _checks.keys
                .map((k) => CheckboxListTile(
                      value: _checks[k],
                      title: Text(k),
                      activeColor: AppColors.safetyOrange,
                      onChanged: (v) => setState(() => _checks[k] = v ?? false),
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(onPressed: _save, child: const Text('SAVE CHECKLIST')),
        ),
      ],
    );
  }
}
