part of 'rigging_pro.dart';

class PullingForceScreen extends StatefulWidget {
  const PullingForceScreen({super.key});
  @override
  State<PullingForceScreen> createState() => _PullingForceScreenState();
}

class _PullingForceScreenState extends State<PullingForceScreen> {
  static const Map<String, double> presets = {
    'Wheels': 0.03,
    'Rollers': 0.05,
    'Greased steel': 0.15,
    'Dry steel': 0.30,
    'Steel on concrete': 0.45,
    'Wood on earth': 0.60,
  };
  final load = TextEditingController();
  final mu = TextEditingController(text: '0.15');
  final slope = TextEditingController(text: '0');
  final margin = TextEditingController(text: '1.5');
  final parts = TextEditingController(text: '1');
  List<_R> out = [];

  void calc() {
    final w = _n(load);
    final m = _n(mu);
    final al = _rad(_n(slope));
    final mg = _n(margin) > 0 ? _n(margin) : 1.5;
    final pts = _n(parts) >= 1 ? _n(parts) : 1.0;
    if (w <= 0 || m <= 0) {
      setState(() => out = [const _R('Load aur friction factor daalo', 3)]);
      return;
    }
    final f = w * 1000 * (m * math.cos(al) + math.sin(al));
    if (f <= 0) {
      setState(() => out = [
            const _R('Load khud niche khiskega: holdback / brake lagao', 3)
          ]);
      return;
    }
    final req = f * mg;
    final res = <_R>[
      _R('Pulling force: ${_f(f, 0)} kgf (${_f(f / 1000, 2)} ton, ${_f(f * 0.00981, 1)} kN)'),
      _R('Margin ${_f(mg, 1)}x ke saath: ${_f(req, 0)} kgf'),
      _R('Winch / chain block / puller kam se kam: ${_f(req / 1000, 2)} ton',
          1),
    ];
    if (pts > 1) {
      res.add(_R(
          '${_f(pts, 0)} part line par line pull approx: ${_f(req / (pts * 0.9) / 1000, 2)} ton'));
    }
    if (_n(slope) > 0) {
      res.add(const _R(
          'Chadhai par load ke peeche holdback / stopper lagao', 2));
    }
    res.add(const _R(
        'Shuru me friction zyada hota hai: margin kam mat karo', 2));
    setState(() => out = res);
  }

  @override
  void dispose() {
    load.dispose();
    mu.dispose();
    slope.dispose();
    margin.dispose();
    parts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _page('Pulling Force', [
      _field(load, 'Load weight', suffix: 'ton'),
      const Text('Surface / support (friction factor):'),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        children: presets.entries
            .map((e) => ActionChip(
                  label: Text('${e.key} ${_f(e.value)}'),
                  onPressed: () => setState(() => mu.text = _f(e.value)),
                ))
            .toList(),
      ),
      const SizedBox(height: 12),
      _field(mu, 'Friction factor'),
      _field(slope, 'Slope (chadhai + / utrai -)', suffix: 'deg'),
      _field(margin, 'Safety margin'),
      _field(parts, 'Block ke parts of line (1 = seedha)'),
      ElevatedButton(onPressed: calc, child: const Text('Calculate')),
      _results(out),
      _note(
          'Force = W x (friction x cos + sin). Friction values approx hain, site ki surface ke hisaab se badlo.'),
      _note(_disclaimer),
    ]);
  }
}
