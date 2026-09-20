import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../app/theme.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _exportBackup() async {
    setState(() => _busy = true);
    try {
      final file = await BackupService.exportBackup();
      await Share.shareXFiles([XFile(file.path)], text: 'Saddam Rigging backup');
    } catch (e) {
      _showError('Backup failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text('This will replace ALL current data with the selected backup. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await BackupService.importBackup(File(result.files.single.path!));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored successfully.')));
    } catch (e) {
      _showError('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file, color: AppColors.safetyOrange),
              title: const Text('Export Backup'),
              subtitle: const Text('Save all data (equipment, lift plans, HSE records) to a JSON file'),
              onTap: _busy ? null : _exportBackup,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download, color: AppColors.safetyOrange),
              title: const Text('Import / Restore Backup'),
              subtitle: const Text('Restore data from a previously exported JSON backup'),
              onTap: _busy ? null : _importBackup,
            ),
          ),
          const Divider(height: 32),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.safetyOrange),
              title: Text('Saddam Rigging A-Z Master Calculator'),
              subtitle: Text('Master Lifting Calculator — v1.0.0\nOffline-first rigging, crane & HSE toolkit.'),
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
