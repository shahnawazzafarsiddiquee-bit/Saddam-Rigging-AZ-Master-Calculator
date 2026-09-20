part of 'rigging_pro2.dart';

const Map<String, String> _uAlias = {
  'mm': 'mm', 'millimeter': 'mm', 'millimeters': 'mm',
  'cm': 'cm', 'centimeter': 'cm', 'centimeters': 'cm',
  'm': 'm', 'meter': 'm', 'meters': 'm', 'metre': 'm', 'metres': 'm',
  'inch': 'inch', 'inches': 'inch', 'in': 'inch',
  'ft': 'ft', 'feet': 'ft', 'foot': 'ft',
  'kg': 'kg', 'kilo': 'kg', 'kilos': 'kg', 'kilogram': 'kg', 'kilograms': 'kg',
  'ton': 'ton', 'tons': 'ton', 'tonne': 'ton', 'tonnes': 'ton',
  'lb': 'lb', 'lbs': 'lb', 'pound': 'lb', 'pounds': 'lb',
};

const Map<String, double> _uFactor = {
  'mm': 0.001, 'cm': 0.01, 'm': 1.0, 'inch': 0.0254, 'ft': 0.3048,
  'kg': 1.0, 'ton': 1000.0, 'lb': 0.45359237,
};

const Set<String> _uLen = {'mm', 'cm', 'm', 'inch', 'ft'};

const List<double> _ropeSz = [
  8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36, 40, 44, 48, 52
];

String _rope2(double tension) {
  final need = math.sqrt(tension * 100);
  for (final s in _ropeSz) {
    if (s >= need) return '${_f(s, 0)} mm (6x36 IWRC)';
  }
  return '52 mm se bada: spreader beam / engineer';
}

class _VC {
  final String crane;
  final double boom;
  final double cap;
  final double util;
  _VC(this.crane, this.boom, this.cap, this.util);
}

Future<List<_R>> _runVoice(String raw) async {
  final t = raw.toLowerCase().replaceAll(',', '.').trim();
  if (t.isEmpty) return [const _R('Kuch bolo ya likho', 2)];
  final tonRe = RegExp(r'(\d+(?:\.\d+)?)\s*(?:ton|tons|tonne|tonnes)');

  final wd = RegExp(r'wind\D*(\d+(?:\.\d+)?)').firstMatch(t);
  if (wd != null) {
    final k = double.parse(wd.group(1)!);
    if (k <= 20) {
      return [_R('Wind ${_f(k, 0)} km/h: normal, lifting theek', 1)];
    }
    if (k <= 32) {
      return [_R('Wind ${_f(k, 0)} km/h: savdhani, tag line lagao', 2)];
    }
    return [_R('Wind ${_f(k, 0)} km/h: 32 se upar, lifting band karo', 3)];
  }

  if (t.contains('crane')) {
    final w = tonRe.firstMatch(t);
    final r = RegExp(r'radius\D*(\d+(?:\.\d+)?)').firstMatch(t);
    if (w != null && r != null) {
      final load = double.parse(w.group(1)!) + 0.5;
      final rad = double.parse(r.group(1)!);
      final cranes = await ProDb.cranes();
      if (cranes.isEmpty) {
        return [const _R('Pehle Crane Load Chart save karo', 3)];
      }
      final list = <_VC>[];
      for (final c in cranes) {
        for (final b in await ProDb.booms(c)) {
          final hit = await ProDb.lookup(c, b, rad);
          if (hit != null) {
            list.add(_VC(c, b, hit.capacity, load / hit.capacity * 100));
          }
        }
      }
      final ok = list.where((x) => x.util <= 100).toList();
      ok.sort((a, b) {
        final pa = a.util <= 75 ? 0 : 1;
        final pb = b.util <= 75 ? 0 : 1;
        if (pa != pb) return pa - pb;
        if (pa == 0) return a.boom.compareTo(b.boom);
        return a.util.compareTo(b.util);
      });
      final res = <_R>[
        _R('Hook load ${_f(load)} ton (rigging 0.5 ton jodkar), radius ${_f(rad, 1)} m'),
      ];
      if (ok.isEmpty) {
        res.add(const _R('Saved charts me koi crane ye lift nahi kar sakti', 3));
      } else {
        final show = ok.length > 5 ? 5 : ok.length;
        for (int i = 0; i < show; i++) {
          final x = ok[i];
          res.add(_R(
              '${x.crane} | boom ${_f(x.boom, 1)} m | cap ${_f(x.cap)} t | ${_f(x.util, 0)}%',
              x.util <= 75 ? 1 : 2));
        }
      }
      return res;
    }
  }

  if (t.contains('sling')) {
    final w = tonRe.firstMatch(t);
    final a = RegExp(r'(\d+(?:\.\d+)?)\s*(?:degree|degrees|deg)').firstMatch(t);
    if (w != null && a != null) {
      final wt = double.parse(w.group(1)!);
      final an = double.parse(a.group(1)!);
      if (an <= 0 || an >= 90) {
        return [const _R('Angle 0 se 90 ke beech bolo', 3)];
      }
      final ten = wt / (2 * math.sin(an * math.pi / 180));
      return [
        _R('Load ${_f(wt)} ton, 2 leg, ${_f(an, 0)} deg'),
        _R('Har leg par: ${_f(ten)} ton', an >= 60 ? 1 : (an >= 45 ? 2 : 3)),
        _R('Wire rope sling kam se kam: ${_rope2(ten)}', 1),
        const _R('Estimate hai. Sling tag se verify karo', 2),
      ];
    }
  }

  final cv = RegExp(r'(\d+(?:\.\d+)?)\s*([a-z]+)\s+(?:to|into|in|se)\s+([a-z]+)')
      .firstMatch(t);
  if (cv != null) {
    final v = double.parse(cv.group(1)!);
    final a = _uAlias[cv.group(2)!];
    final b = _uAlias[cv.group(3)!];
    if (a != null && b != null) {
      if (_uLen.contains(a) != _uLen.contains(b)) {
        return [_R('$a se $b convert nahi ho sakta (alag type)', 3)];
      }
      final r = v * _uFactor[a]! / _uFactor[b]!;
      return [_R('${_f(v, 3)} $a = ${_f(r, 4)} $b', 1)];
    }
  }

  return [
    const _R('Command samajh nahi aaya. Ye try karo:', 2),
    const _R('10 cm to inch'),
    const _R('sling 6 ton 60 degree'),
    const _R('crane 12 ton radius 18'),
    const _R('wind 25'),
  ];
}

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final cmd = TextEditingController();
  List<_R> out = [];

  Future<void> _run() async {
    final r = await _runVoice(cmd.text);
    if (!mounted) return;
    setState(() => out = r);
  }

  @override
  void dispose() {
    cmd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Smart Command', [
      TextField(
        controller: cmd,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Command likho ya keyboard ke mic se bolo',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _run(),
      ),
      const SizedBox(height: 8),
      FilledButton(onPressed: _run, child: const Text('Chalao')),
      _results(out),
      _note(
          'Examples: "10 cm to inch", "sling 6 ton 60 degree", "crane 12 ton radius 18", "wind 25". Bolne ke liye keyboard ke mic ka button dabao.'),
      _note(_disclaimer),
    ]);
  }
}
