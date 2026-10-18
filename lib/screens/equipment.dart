import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app/theme.dart';
import '../database/sqlite_helper.dart';
import '../models/equipment_model.dart';
import '../services/qr_service.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<EquipmentModel> _equipment = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await SqliteHelper.instance.queryAll(
      'Equipment',
      orderBy: 'id DESC',
    );
    if (!mounted) return;
    setState(() {
      _equipment = rows.map((r) => EquipmentModel.fromMap(r)).toList();
      _loading = false;
    });
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScannerScreen()),
    );
    if (result == null) return;
    final equipmentId = QrService.parseEquipmentId(result);
    if (equipmentId == null) return;

    final row = await SqliteHelper.instance.findByEquipmentId(equipmentId);
    if (!mounted) return;
    if (row == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No equipment found for ID "$equipmentId".')),
      );
      return;
    }
    final eq = EquipmentModel.fromMap(row);
    _showDetail(eq);
  }

  void _showDetail(EquipmentModel eq) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                eq.type,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: QrImageView(
                  data: QrService.buildPayload(eq.equipmentId),
                  size: 140,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ResultRow(label: 'Equipment ID', value: eq.equipmentId),
              ResultRow(label: 'Serial Number', value: eq.serialNumber),
              ResultRow(label: 'Manufacturer', value: eq.manufacturer),
              ResultRow(label: 'WLL', value: '${eq.wll} t'),
              ResultRow(label: 'Last Inspection', value: eq.inspectionDate),
              ResultRow(label: 'Expiry Date', value: eq.expiryDate),
              const SizedBox(height: 8),
              SafetyStatusBanner(
                isSafe: eq.hasCurrentRegistration,
                safeText: 'REGISTRATION CURRENT - VERIFY CERTIFICATE',
                unsafeText: eq.isExpired
                    ? 'EXPIRED / DATE UNVERIFIED'
                    : eq.isRestricted
                    ? eq.status.toUpperCase()
                    : 'INCOMPLETE - VERIFY REGISTRATION',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openForm({EquipmentModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EquipmentForm(existing: existing),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQr,
            tooltip: 'Scan QR',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.safetyOrange,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _equipment.isEmpty
          ? const Center(
              child: Text(
                'No equipment yet. Tap + to add your first item.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: _equipment.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final eq = _equipment[i];
                  final expired = eq.isExpired;
                  final knownExpiry =
                      EquipmentModel.validDate(eq.expiryDate) != null;
                  final statusColor =
                      eq.isRestricted || (knownExpiry && expired)
                      ? AppColors.danger
                      : eq.hasCurrentRegistration
                      ? AppColors.success
                      : AppColors.warning;
                  return Card(
                    child: ListTile(
                      onTap: () => _showDetail(eq),
                      onLongPress: () => _openForm(existing: eq),
                      leading: CircleAvatar(
                        backgroundColor: statusColor,
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        eq.equipmentId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${eq.type} • WLL ${eq.wll} t • ${eq.manufacturer}',
                      ),
                      trailing: Text(
                        !knownExpiry
                            ? 'DATE UNVERIFIED'
                            : expired
                            ? 'EXPIRED'
                            : eq.status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _EquipmentForm extends StatefulWidget {
  final EquipmentModel? existing;
  const _EquipmentForm({this.existing});

  @override
  State<_EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends State<_EquipmentForm> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _typeCtrl;
  late final TextEditingController _serialCtrl;
  late final TextEditingController _manufacturerCtrl;
  late final TextEditingController _wllCtrl;
  late final TextEditingController _inspectionCtrl;
  late final TextEditingController _expiryCtrl;
  String _status = 'Active';
  bool _saving = false;
  String? _error;

  static const _types = [
    'Wire Rope Sling',
    'Chain Sling',
    'Web Sling',
    'Shackle',
    'Hook',
    'Spreader Beam',
    'Round Sling',
    'Master Link',
    'Lifting Beam',
    'Crane',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _idCtrl = TextEditingController(text: e?.equipmentId ?? '');
    _typeCtrl = TextEditingController(text: e?.type ?? _types.first);
    _serialCtrl = TextEditingController(text: e?.serialNumber ?? '');
    _manufacturerCtrl = TextEditingController(text: e?.manufacturer ?? '');
    _wllCtrl = TextEditingController(text: e?.wll.toString() ?? '');
    _inspectionCtrl = TextEditingController(
      text:
          e?.inspectionDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _expiryCtrl = TextEditingController(
      text:
          e?.expiryDate ??
          DateFormat('yyyy-MM-dd')
              .format(DateTime.now().add(const Duration(days: 365))),
    );
    _status = e?.status ?? 'Active';
  }

  Future<void> _pickDate(TextEditingController c) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(c.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null)
      setState(() => c.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _error = null);
    if (_idCtrl.text.trim().isEmpty || _wllCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Equipment ID and WLL are required.');
      return;
    }

    final wll = double.tryParse(_wllCtrl.text.trim().replaceAll(',', '.'));
    if (wll == null || !wll.isFinite || wll <= 0) {
      setState(() => _error = 'WLL must be finite and greater than zero.');
      return;
    }
    if (widget.existing?.isRestricted == true &&
        !EquipmentModel.restrictedStatus(_status)) {
      setState(
        () => _error = 'Restricted equipment needs an authorized release workflow. Keep it on hold.',
      );
      return;
    }
    final row = {
      'equipmentId': _idCtrl.text.trim(),
      'type': _typeCtrl.text,
      'serialNumber': _serialCtrl.text,
      'manufacturer': _manufacturerCtrl.text,
      'wll': wll,
      'inspectionDate': _inspectionCtrl.text,
      'expiryDate': _expiryCtrl.text,
      'status': _status,
    };

    setState(() => _saving = true);
    try {
      final db = await SqliteHelper.instance.database;
      await db.transaction((txn) async {
        final duplicate = await txn.query(
          'Equipment',
          columns: ['id'],
          where: 'equipmentId = ? AND id != ?',
          whereArgs: [row['equipmentId'], widget.existing?.id ?? -1],
        );
        if (duplicate.isNotEmpty)
          throw StateError(
            'Equipment ID already exists. Use a unique ID for QR tracking.',
          );
        if (widget.existing?.id != null) {
          final updated = await txn.update(
            'Equipment',
            row,
            where: 'id = ?',
            whereArgs: [widget.existing!.id],
          );
          if (updated != 1)
            throw StateError(
              'Equipment record changed or is missing. Refresh and retry.',
            );
        } else {
          await txn.insert('Equipment', row);
        }
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Equipment not saved: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _idCtrl,
      _typeCtrl,
      _serialCtrl,
      _manufacturerCtrl,
      _wllCtrl,
      _inspectionCtrl,
      _expiryCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Add Equipment' : 'Edit Equipment',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _idCtrl,
              decoration: const InputDecoration(labelText: 'Equipment ID'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _types.contains(_typeCtrl.text)
                  ? _typeCtrl.text
                  : _types.first,
              decoration: const InputDecoration(labelText: 'Type'),
              dropdownColor: const Color(0xFF2A2E33),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _typeCtrl.text = v ?? _types.first),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _serialCtrl,
              decoration: const InputDecoration(labelText: 'Serial Number'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _manufacturerCtrl,
              decoration: const InputDecoration(labelText: 'Manufacturer'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _wllCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'WLL (t)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _inspectionCtrl,
              readOnly: true,
              onTap: () => _pickDate(_inspectionCtrl),
              decoration: const InputDecoration(labelText: 'Inspection Date'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _expiryCtrl,
              readOnly: true,
              onTap: () => _pickDate(_expiryCtrl),
              decoration: const InputDecoration(labelText: 'Expiry Date'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              dropdownColor: const Color(0xFF2A2E33),
              items:
                  <String>{
                        'Active',
                        'Quarantine',
                        'Quarantined',
                        'Hold',
                        'Expired',
                        'Scrapped',
                        if (widget.existing != null) widget.existing!.status,
                      }
                      .toList()
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();
  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Equipment QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (!handled && mounted && barcodes.isNotEmpty) {
            final value = barcodes.first.rawValue;
            if (value != null) {
              handled = true;
              Navigator.pop(context, value);
            }
          }
        },
      ),
    );
  }
}
