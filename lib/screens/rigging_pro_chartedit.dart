part of 'rigging_pro.dart';

List<List<double>>? _parseChart(String text, List<String> errs) {
  final out = <List<double>>[];
  final lines = text.split('\n');
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final parts = line.split(RegExp(r'[,;\t ]+'));
    final nums = parts.map((p) => double.tryParse(p)).toList();
    if (nums.length != 3 || nums.any((v) => v == null || !v.isFinite || v <= 0)) {
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
  final metadataFields={for(final k in CraneChartRules.fields)k:TextEditingController()};
  bool verified=false;
  String msg = '';
  void invalidate(){if(mounted)setState(()=>verified=false);}
  String unit = 'ton';
  String lengthUnit='m';
  bool radiusSide = true;
  bool busy = false;
  String status = '';
  int statusLvl = 0;

  @override
  void initState() {
    super.initState();
    _prefill();
    for(final c in [name,cfg,data,...metadataFields.values]){c.addListener(invalidate);}
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
        final meta=CraneChartRules.metadata(nt);
        cfg.text = meta==null?nt:'${meta['configuration']??''}';
        if(meta!=null){for(final k in metadataFields.keys){metadataFields[k]!.text='${meta[k]??''}';}}
        verified=false;
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
      final meta=<String,Object?>{'version':1,for(final e in metadataFields.entries)e.key:e.value.text.trim(),'configuration':cfg.text.trim(),'storedLengthUnit':'m','storedCapacityUnit':'metric tonne','verified':verified,'verifiedAt':verified?DateTime.now().toUtc().toIso8601String():null};
      if(verified){final reason=CraneChartRules.incomplete(meta);if(reason!=null)throw ArgumentError(reason);}
      await ProDb.replaceChart(c,CraneChartRules.encode(meta),rows,previousName:old);
    } catch (e) {
      setState(() => msg = 'Save nahi hua: $e');
      return;
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _import() async {
    if (busy) return;
    setState(() {
      busy = true;
      status = 'File chuno...';
      statusLvl = 0;
    });
    try {
      final res = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      String? path =
          (res == null || res.files.isEmpty) ? null : res.files.single.path;
      if (path == null) {
        if (mounted) {
          setState(() {
            status = '';
          });
        }
        return;
      }
      if(!mounted)return;
      final importUnit=unit,importLength=lengthUnit,importLayout=radiusSide;
      final original=File(path);
      if(await original.length()>30*1024*1024)throw ArgumentError('Chart document exceeds 30 MB. Import selected pages.');
      final dir=Directory('${(await getApplicationDocumentsDirectory()).path}/chart_documents');await dir.create(recursive:true);
      final suffix=path.split('.').last.toLowerCase();
      path=(await original.copy('${dir.path}/chart_${DateTime.now().microsecondsSinceEpoch}.$suffix')).path;
      if(!mounted)return;
      metadataFields['document']!.text=path;
      verified=false;
      List<String> images = [path];
      if (path.toLowerCase().endsWith('.pdf')) {
        if (mounted) {
          setState(() => status = 'PDF ke pages tayyar ho rahe hain...');
        }
        images = await _pdfToPngs(path, 8);
      }
      final found = <List<double>>[];
      final notes = <String>[];
      for (int i = 0; i < images.length; i++) {
        if (mounted) {
          setState(() => status = 'Page ${i + 1}/${images.length} padh rahe hain...');
        }
        final toks = await _ocrFile(images[i], importUnit);
        found.addAll(_buildTable(toks, importLayout, notes));
      }
      if (!mounted) return;
      if (found.isEmpty) {
        setState(() {
          status =
              'Table nahi mila. ${notes.isEmpty ? '' : notes.first}. Seedhi, saaf photo lo ya "layout" badlo';
          statusLvl = 3;
        });
        return;
      }
      final caps = found.map((r) => r[2]).toList()..sort();
      final med = caps[caps.length ~/ 2];
      final k = importUnit == 'kg' ? 0.001 : (importUnit == 'lb' ? 0.00045359237 : 1.0);
      final seen = <String>{};
      final rows = <List<double>>[];
      for (final r in found) {
        final key = '${r[0]}|${r[1]}';
        if(!seen.add(key))notes.add('Duplicate boom/radius: $key; split configurations or correct rows before saving.');
        rows.add([r[0]*(importLength=='ft'?0.3048:1), r[1]*(importLength=='ft'?0.3048:1), r[2] * k]);
      }
      final warns = <String>[];
      if (importUnit == 'ton' && med > 400) {
        warns.add(
            'Capacity bahut badi hai: chart kg me ho sakta hai. Unit "kg" chuno aur dobara import karo');
      }
      warns.addAll(notes.take(4));
      warns.addAll(_checkChart(rows).take(4));
      final text = rows
          .map((r) => '${r[0]}, ${r[1]}, ${r[2]}')
          .join('\n');
      final head =
          '${rows.length} values mile (${images.length} page). Neeche check karo, original chart se milao, phir Save.';
      setState(() {
        data.text = data.text.trim().isEmpty ? text : data.text.trim() + '\n' + text;
        status = warns.isEmpty ? head : head + '\n' + warns.join('\n');
        statusLvl = 2;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          status = 'Import fail: $e';
          statusLvl = 3;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    for(final c in metadataFields.values){c.dispose();}
    name.dispose();
    cfg.dispose();
    data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Crane Chart Daalo', [
      _textField(name, 'Crane ka naam (jaise: Tadano 50T full outrigger)'),
      _textField(cfg, 'Chart config (outrigger, counterweight, 360 deg)'),
      for(final e in metadataFields.entries)if(e.key!='configuration')_textField(e.value,'Chart ${e.key}'),
      const Text('Use explicit NONE where a configuration item is absent. Register the crane in Equipment using the exact assetId; current inspection and certificate are required for Finder.'),
      const Divider(),
      const Text('PDF / Photo se auto import',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Imported capacity unit: ton = metric tonne'),
      Wrap(spacing:8,children:[for(final u in ['m','ft'])ChoiceChip(label:Text('Length: $u'),selected:lengthUnit==u,onSelected:(_)=>setState(()=>lengthUnit=u))]),
      Wrap(
        spacing: 8,
        children: ['ton', 'kg', 'lb']
            .map((u) => ChoiceChip(
                  label: Text(u),
                  selected: unit == u,
                  onSelected: (_) => setState(() => unit = u),
                ))
            .toList(),
      ),
      const SizedBox(height: 8),
      const Text('Table ka layout:'),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Radius side me, boom upar'),
            selected: radiusSide,
            onSelected: (_) => setState(() => radiusSide = true),
          ),
          ChoiceChip(
            label: const Text('Boom side me, radius upar'),
            selected: !radiusSide,
            onSelected: (_) => setState(() => radiusSide = false),
          ),
        ],
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: busy ? null : _import,
        icon: const Icon(Icons.upload_file),
        label: const Text('PDF / Photo chuno'),
      ),
      if (busy)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(),
        ),
      if (status.isNotEmpty) _results([_R(status, statusLvl)]),
      const Divider(),
      TextField(
        controller: data,
        maxLines: 12,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          labelText: 'Stored chart: boom m, radius m, capacity metric tonne',
          hintText: '24, 6, 30\n24, 8, 22\n24, 10, 16\n30, 8, 18',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      CheckboxListTile(value:verified,onChanged:busy?null:(v)=>setState(()=>verified=v??false),title:const Text('I checked every value, unit and configuration against the original chart; OCR is only a draft')),
      ElevatedButton(onPressed: busy?null:_save, child: const Text('Save')),
      if (msg.isNotEmpty) _results([_R(msg, 3)]),
      _note(
          'Ek page ka ek table (ek configuration) ek baar import karo. Auto-detect draft hai: har number original chart se milao, galat ho to yahin sudhaar do.'),
    ]);
  }
}
