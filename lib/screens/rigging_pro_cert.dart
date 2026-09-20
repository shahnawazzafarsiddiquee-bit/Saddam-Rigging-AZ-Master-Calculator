part of 'rigging_pro.dart';

class CertTrackerScreen extends StatefulWidget {
  const CertTrackerScreen({super.key});
  @override
  State<CertTrackerScreen> createState() => _CertTrackerScreenState();
}

class _CertTrackerScreenState extends State<CertTrackerScreen> {
  static const List<String> kinds = [
    'Sling', 'Shackle/Hook', 'Crane', 'Operator', 'Other'
  ];
  final name = TextEditingController();
  final ident = TextEditingController();
  String kind = 'Sling';
  DateTime? expiry;
  List<Map<String, Object?>> rows = [];
  String err = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ProDb.certs();
      if (!mounted) return;
      setState(() => rows = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => err = 'Database error: $e');
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: expiry ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (d != null && mounted) setState(() => expiry = d);
  }

  Future<void> _add() async {
    final n = name.text.trim();
    final e = expiry;
    if (n.isEmpty || e == null) {
      setState(() => err = 'Naam aur expiry date daalo');
      return;
    }
    await ProDb.addCert(
        n, kind, ident.text.trim(), e.toIso8601String().substring(0, 10));
    name.clear();
    ident.clear();
    setState(() {
      expiry = null;
      err = '';
    });
    await _load();
  }

  @override
  void dispose() {
    name.dispose();
    ident.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int expired = 0;
    int soon = 0;
    for (final r in rows) {
      final d = _daysLeft(r['expiry'] as String);
      if (d < 0) {
        expired++;
      } else if (d <= 30) {
        soon++;
      }
    }
    return _page('Certificate Tracker', [
      if (rows.isNotEmpty)
        _results([
          _R(
              '$expired expired, $soon 30 din me khatam, ${rows.length - expired - soon} valid',
              expired > 0 ? 3 : (soon > 0 ? 2 : 1)),
        ]),
      const SizedBox(height: 12),
      _textField(name, 'Naam (Sling 20mm No.12, Crane 50T, Operator Raju)'),
      _textField(ident, 'ID / tag / license no (optional)'),
      Wrap(
        spacing: 8,
        children: kinds
            .map((k) => ChoiceChip(
                  label: Text(k),
                  selected: kind == k,
                  onSelected: (_) => setState(() => kind = k),
                ))
            .toList(),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _pickDate,
        icon: const Icon(Icons.event),
        label: Text(expiry == null
            ? 'Expiry date chuno'
            : 'Expiry: ${_fmtDate(expiry!)}'),
      ),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: _add, child: const Text('Add')),
      if (err.isNotEmpty) _results([_R(err, 3)]),
      const SizedBox(height: 12),
      ...rows.map((r) {
        final d = _daysLeft(r['expiry'] as String);
        final lv = d < 0 ? 3 : (d <= 30 ? 2 : 1);
        final label = d < 0
            ? 'EXPIRED ${-d} din pehle'
            : (d == 0 ? 'Aaj expire' : '$d din baaki');
        final id = (r['ident'] as String?) ?? '';
        final sub = (r['kind'] as String) +
            (id.isEmpty ? '' : ' | ' + id) +
            ' | ' +
            _fmtIso(r['expiry'] as String);
        return Card(
          child: ListTile(
            title: Text(r['name'] as String),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub),
                Text(label,
                    style: TextStyle(
                        color: _col(lv), fontWeight: FontWeight.w600)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await ProDb.deleteCert(r['id'] as int);
                _load();
              },
            ),
          ),
        );
      }),
      _note(
          'Notification abhi nahi hai. Pro Tools kholte hi expired / 30 din wale certificate ka alert upar dikhega.'),
    ]);
  }
}
