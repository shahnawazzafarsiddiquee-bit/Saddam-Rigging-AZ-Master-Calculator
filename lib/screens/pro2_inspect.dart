part of 'rigging_pro2.dart';

const _checklists = InspectionRules.checklists;

class InspectionScreen extends StatefulWidget {
  final String? assetId;
  const InspectionScreen({super.key, this.assetId});
  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final item = TextEditingController();
  final who = TextEditingController();
  final notes = TextEditingController();
  final project = TextEditingController();
  final procedure = TextEditingController();
  final naReason = TextEditingController();
  bool attested = false;
  String kind = 'Wire rope sling';
  final Map<int, int> ans = {};
  final List<Uint8List> pics = [];
  String msg = '';
  int msgLvl = 0;
  bool saving = false;
  Map<String, Object?>? environment;
  @override
  void initState() {
    super.initState();
    item.text = widget.assetId ?? "";
  }

  Future<void> _pick(ImageSource src) async {
    if (pics.length >= 4) {
      setState(() {
        msg = 'Ek inspection me max 4 photo';
        msgLvl = 2;
      });
      return;
    }
    try {
      final x = await ImagePicker().pickImage(
        source: src,
        maxWidth: 1280,
        imageQuality: 65,
      );
      if (x == null) return;
      final b = await x.readAsBytes();
      if (!mounted) return;
      setState(() => pics.add(b));
    } catch (e) {
      if (mounted) {
        setState(() {
          msg = 'Photo nahi mili: $e';
          msgLvl = 3;
        });
      }
    }
  }

  Future<void> _save() async {
    if (saving) return;
    final result = InspectionRules.result(kind, ans, naReason.text);
    setState(() => saving = true);
    try {
      await InspectionWorkflow.save(
        assetId: item.text,
        kind: kind,
        inspector: who.text,
        project: project.text,
        procedure: procedure.text,
        answers: Map.of(ans),
        naReason: naReason.text,
        notes: notes.text,
        attested: attested,
        photos: List.of(pics),
        environment: environment,
      );
      if (!mounted) return;
      setState(() {
        item.clear();
        notes.clear();
        ans.clear();
        pics.clear();
        attested = false;
        environment = null;
        msg = result == 'REJECT'
            ? 'Saved: REJECT. Equipment quarantined; do not use. History se PDF banao'
            : 'Saved: $result. History se PDF banao';
        msgLvl = result == 'PASS' ? 1 : (result == 'REJECT' ? 3 : 2);
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          msg = 'Save nahi hua: $e';
          msgLvl = 3;
        });
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    item.dispose();
    who.dispose();
    notes.dispose();
    project.dispose();
    procedure.dispose();
    naReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _checklists[kind]!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Checklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InspectionHistoryScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: _checklists.keys
                  .map(
                    (k) => ChoiceChip(
                      label: Text(k),
                      selected: kind == k,
                      onSelected: (_) => setState(() {
                        kind = k;
                        ans.clear();
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            _textField(item, 'Item / ID (jaise: Sling #12, Tadano 50T)'),
            _textField(who, 'Inspector ka naam'),
            _textField(project, 'Project / site'),
            EnvironmentAttachment(
              value: environment,
              project: project.text,
              onChanged: (value) => setState(() => environment = value),
            ),
            _textField(procedure, 'Approved procedure / revision'),
            _note(
              'Registered equipment ID required. REJECT quarantines the asset; HOLD blocks use. PASS never releases an existing quarantine.',
            ),
            ...List.generate(items.length, (i) {
              final a = ans[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[i]),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('OK'),
                            selected: a == 0,
                            selectedColor: Colors.green.shade700,
                            onSelected: (_) => setState(() => ans[i] = 0),
                          ),
                          ChoiceChip(
                            label: const Text('FAIL'),
                            selected: a == 1,
                            selectedColor: Colors.red.shade700,
                            onSelected: (_) => setState(() => ans[i] = 1),
                          ),
                          ChoiceChip(
                            label: const Text('N/A'),
                            selected: a == 2,
                            onSelected: (_) => setState(() => ans[i] = 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            _textField(naReason, 'Reason for N/A responses'),
            const SizedBox(height: 8),
            TextField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (kharabi, kya kiya)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pics
                  .map(
                    (p) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            p,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () => setState(() => pics.remove(p)),
                            child: const Icon(
                              Icons.cancel,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text(
                'I performed this inspection against the recorded procedure. My typed name records my attestation; it is not authenticated approval.',
              ),
              value: attested,
              onChanged: saving
                  ? null
                  : (v) => setState(() => attested = v ?? false),
            ),
            FilledButton(
              onPressed: saving ? null : _save,
              child: const Text('Inspection save karo'),
            ),
            if (msg.isNotEmpty) _results([_R(msg, msgLvl)]),
            _note(
              'General checklist hai. Company procedure aur competent person ki inspection final.',
            ),
          ],
        ),
      ),
    );
  }
}
