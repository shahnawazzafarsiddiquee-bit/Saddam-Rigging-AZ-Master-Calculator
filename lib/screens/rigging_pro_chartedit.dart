part of 'rigging_pro.dart';

List<List<double>>? _parseChart(String text, List<String> errs) {
  final out = <List<double>>[];
  final lines = text.split('\n');
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp(r'[,;\t ]+'));
    final nums = parts.map((p) => double.tryParse(p)).toList();
    if (nums.length != 3 || nums.any((v) => v == null || v <= 0)) {
      errs.add(
          'Line ${i + 1} galat hai: "$line" (format: boom, radius, capacity)');
      return null;
    }
    out.add([nums[0]!, nums[1]!, nums[2]!]);
  }
  if (out.isEmpty) {
    errs.add('Chart data daalo');
    return null;
  }
  return out;
}

class ChartEditScreen extends StatefulWidget {
  final String? existing;
  const ChartEditScreen({super.key, this.existing});
  @override
  State<ChartEditScreen> createState() => _ChartEditScreenState();
}

class _ChartEditScreenState extends State<ChartEditScreen> {
  final name = TextEditingController();
  final cfg = TextEditingController();
  final data = TextEditingController();
  String msg = '';

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final c = widget.existing;
    if (c == null) return;
    try {
      final rows = await ProDb.allRows(c);
      final nt = await ProDb.note(c);
      if (!mounted) return;
      setState(() {
        name.text = c;
        cfg.text = nt;
        data.text = rows
            .map((r) => '${r['boom']}, ${r['radius']}, ${r['capacity']}')
            .join('\n');
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    final c = name.text.trim();
    if (c.isEmpty) {
      setState(() => msg = 'Crane ka naam daalo');
      return;
    }
    final errs = <String>[];
    final rows = _parseChart(data.text, errs);
    if (rows == null) {
      setState(() => msg = errs.isEmpty ? 'Chart data daalo' : errs.first);
      return;
    }
    try {
      final old = widget.existing;
      if (old != null && old != c) await ProDb.deleteCrane(old);
      await ProDb.replaceChart(c, cfg.text.trim(), rows);
    } catch (e) {
      setState(() => msg = 'Save nahi hua: $e');
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    name.dispose();
    cfg.dispose();
    data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Crane Chart Daalo', [
      _textField(name, 'Crane ka naam (jaise: Tadano 50T)'),
      _textField(cfg, 'Chart config (outrigger, counterweight, 360 deg)'),
      TextField(
        controller: data,
        maxLines: 12,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          labelText: 'Chart data: boom, radius, capacity (har line me ek)',
          hintText: '24, 6, 30\n24, 8, 22\n24, 10, 16\n30, 8, 18',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(onPressed: _save, child: const Text('Save')),
      if (msg.isNotEmpty) _results([_R(msg, 3)]),
      _note(
          'Boom length (m), radius (m), capacity (ton). Numbers apni crane ki original load chart se hi daalo. Ek boom length ki saari radius lines daalo.'),
    ]);
  }
}
