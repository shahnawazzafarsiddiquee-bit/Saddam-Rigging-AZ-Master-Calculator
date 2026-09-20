part of 'rigging_pro2.dart';

const Map<String, List<String>> _checklists = {
  'Wire rope sling': [
    'Tag/ID aur WLL saaf padhi ja rahi hai',
    'Toote taar limit ke andar (ek lay me 10 random ya ek strand me 5, ASME B30.9)',
    'Kink, birdcage, crushing ya bend nahi',
    'Zang / pitting / heat damage nahi',
    'Eye splice, ferrule, thimble theek hain',
    'Rope ka diameter kam nahi hua (wear)',
    'Certificate aur colour code valid hai',
  ],
  'Crane pre-use': [
    'Outrigger poore extend, pin lage, mat ke upar',
    'Crane level hai (bubble check)',
    'LMI / anti-two-block kaam kar raha hai',
    'Hook latch, hoist rope aur brake theek',
    'Horn, light, alarm chal rahe hain',
    'Hydraulic / oil leak nahi',
    'Load chart cab me hai',
    'Wind speed limit ke andar hai',
    'Area barricade, signalman aur rigger tay',
    'Overhead line se safe doori',
  ],
  'Shackle / Hook': [
    'Shackle par WLL likhi hai',
    'Pin poora seat, lock / cotter lagi hai',
    'Shackle body ya pin bent / khichi nahi',
    'Hook latch theek, mouth khula nahi',
    'Hook me twist ya crack nahi',
    'Eye bolt / swivel / master link me crack ya wear nahi',
  ],
};

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});
  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  final item = TextEditingController();
  final who = TextEditingController();
  final notes = TextEditingController();
  String kind = 'Wire rope sling';
  final Map<int, int> ans = {};
  final List<Uint8List> pics = [];
  String msg = '';
  int msgLvl = 0;
  bool saving = false;

  Future<void> _pick(ImageSource src) async {
    if (pics.length >= 4) {
      setState(() {
        msg = 'Ek inspection me max 4 photo';
        msgLvl = 2;
      });
      return;
    }
    try {
      final x = await ImagePicker()
          .pickImage(source: src, maxWidth: 1280, imageQuality: 65);
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
    final items = _checklists[kind]!;
    if (item.text.trim().isEmpty) {
      setState(() {
        msg = 'Item / ID daalo (jaise Sling #12)';
        msgLvl = 3;
      });
      return;
    }
    final fails = ans.values.where((v) => v == 1).length;
    final result =
        fails > 0 ? 'FAIL' : (ans.length < items.length ? 'INCOMPLETE' : 'PASS');
    final lines = <String>[];
    for (int i = 0; i < items.length; i++) {
      final a = ans[i];
      final st =
          a == 0 ? 'OK' : (a == 1 ? 'FAIL' : (a == 2 ? 'NA' : 'PENDING'));
      lines.add('$st|${items[i]}');
    }
    final nt = notes.text.trim().replaceAll('\n', ' ');
    if (nt.isNotEmpty) lines.add('NOTE|$nt');
    setState(() => saving = true);
    try {
      final id = await Pro2Db.addInspection({
        'dt': _iso(DateTime.now()),
        'kind': kind,
        'item': item.text.trim(),
        'inspector': who.text.trim(),
        'result': result,
        'details': lines.join('\n'),
      });
      for (final p in pics) {
        await Pro2Db.addPhoto(id, p);
      }
      if (!mounted) return;
      setState(() {
        item.clear();
        notes.clear();
        ans.clear();
        pics.clear();
        msg = result == 'FAIL'
            ? 'Saved: FAIL. Is item ko use mat karo, tag lagao. History se PDF banao'
            : 'Saved: $result. History se PDF banao';
        msgLvl = result == 'PASS' ? 1 : (result == 'FAIL' ? 3 : 2);
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
                    builder: (_) => const InspectionHistoryScreen())),
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
                  .map((k) => ChoiceChip(
                        label: Text(k),
                        selected: kind == k,
                        onSelected: (_) => setState(() {
                          kind = k;
                          ans.clear();
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _textField(item, 'Item / ID (jaise: Sling #12, Tadano 50T)'),
            _textField(who, 'Inspector ka naam'),
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
                  .map((p) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(p,
                                width: 90, height: 90, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () => setState(() => pics.remove(p)),
                              child: const Icon(Icons.cancel,
                                  color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: saving ? null : _save,
              child: const Text('Inspection save karo'),
            ),
            if (msg.isNotEmpty) _results([_R(msg, msgLvl)]),
            _note(
                'General checklist hai. Company procedure aur competent person ki inspection final.'),
          ],
        ),
      ),
    );
  }
}
