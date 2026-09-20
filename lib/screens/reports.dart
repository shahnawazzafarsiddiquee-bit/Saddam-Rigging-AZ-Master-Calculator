import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../app/theme.dart';
import '../database/sqlite_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await SqliteHelper.instance.queryAll('Reports', orderBy: 'id DESC');
    setState(() {
      _reports = rows;
      _loading = false;
    });
  }

  Future<void> _openOrShare(Map<String, dynamic> report) async {
    final path = report['filePath'] as String;
    final file = File(path);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found on device (may have been cleared).')),
      );
      return;
    }
    await Printing.sharePdf(bytes: await file.readAsBytes(), filename: path.split('/').last);
  }

  Future<void> _delete(Map<String, dynamic> report) async {
    await SqliteHelper.instance.delete('Reports', report['id'] as int);
    _load();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'Lift Plan':
        return Icons.assignment;
      case 'JSA':
        return Icons.warning_amber;
      case 'Inspection':
        return Icons.fact_check;
      default:
        return Icons.picture_as_pdf;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(
                  child: Text('No reports generated yet.', style: TextStyle(color: Colors.white70)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: _reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = _reports[i];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.navy,
                            child: Icon(_iconFor(r['reportType'] as String), color: AppColors.safetyOrange),
                          ),
                          title: Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${r['reportType']} • ${r['createdAt'].toString().split('T').first}'),
                          onTap: () => _openOrShare(r),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _delete(r),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
