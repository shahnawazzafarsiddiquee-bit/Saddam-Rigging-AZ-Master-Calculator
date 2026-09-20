import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../app/routes.dart';
import 'material_calculators.dart';
import 'unit_converter.dart';
import 'rigging_advanced.dart';
import 'rigging_pro.dart';
import 'rigging_pro_db.dart';
import 'rigging_pro2.dart';
import 'pro2_db.dart';

class _Tool {
  final String title;
  final IconData icon;
  final String? route;
  final Widget Function()? page;
  final String keys;
  _Tool(this.title, this.icon, {this.route, this.page, this.keys = ''});
}

class _Section {
  final String title;
  final IconData icon;
  final List<_Tool> tools;
  _Section(this.title, this.icon, this.tools);
}

List<_Section> _sections() => [
      _Section('Rigging & Lifting', Icons.construction, [
        _Tool('Rigging Calculator', Icons.calculate,
            route: AppRoutes.riggingTools,
            keys: 'sling load angle wll shackle chain rope'),
        _Tool('Sling Length & Angle', Icons.straighten,
            page: () => const SlingLengthScreen(),
            keys: 'container pipe 60 degree leg length'),
        _Tool('Crane Finder (auto)', Icons.auto_awesome,
            page: () => const CraneFinderScreen(),
            keys: 'crane finder select auto weight boom radius best'),
        _Tool('Crane Planning', Icons.precision_manufacturing,
            route: AppRoutes.cranePlanning, keys: 'crane radius boom'),
        _Tool('Crane Boom & Capacity', Icons.architecture,
            page: () => const CraneBoomScreen(),
            keys: 'boom length angle utilization radius'),
        _Tool('Lift Diagram', Icons.timeline,
            page: () => const LiftDiagramScreen(),
            keys: 'diagram drawing boom obstruction clearance'),
        _Tool('CG Load Share', Icons.compare_arrows,
            page: () => const CgShareScreen(),
            keys: 'centre of gravity cg two point'),
        _Tool('Wind Check', Icons.air,
            page: () => const WindCheckScreen(), keys: 'wind speed hawa force'),
        _Tool('Ground Bearing', Icons.terrain,
            page: () => const GroundBearingScreen(),
            keys: 'outrigger mat soil pressure'),
        _Tool('Pulling Force', Icons.open_with,
            page: () => const PullingForceScreen(),
            keys: 'skid roller winch pulling friction'),
        _Tool('Voice Commands', Icons.mic,
            page: () => const VoiceScreen(),
            keys: 'voice bolo mic command speak'),
      ]),
      _Section('Plans & Documents', Icons.assignment, [
        _Tool('Lift Plan Generator', Icons.assignment,
            route: AppRoutes.liftPlan, keys: 'lift plan'),
        _Tool('Lift Plan PDF', Icons.picture_as_pdf,
            page: () => const LiftPlanPdfScreen(), keys: 'lift plan pdf print'),
        _Tool('Crane Load Chart', Icons.table_chart,
            page: () => const CraneChartScreen(),
            keys: 'chart capacity table import photo pdf'),
        _Tool('Job Logbook', Icons.menu_book,
            page: () => const LogbookScreen(),
            keys: 'logbook log record history lifts report'),
        _Tool('Reports', Icons.summarize,
            route: AppRoutes.reports, keys: 'report pdf'),
      ]),
      _Section('Materials & Weights', Icons.scale_outlined, [
        _Tool('Material Calculators', Icons.construction,
            page: () => const MaterialCalculatorsScreen(),
            keys: 'pipe plate concrete rebar saria'),
        _Tool('Unit Converter', Icons.swap_horiz,
            page: () => const UnitConverterScreen(),
            keys: 'mm cm meter inch feet kg ton'),
        _Tool('Steel Section Weight', Icons.view_stream,
            page: () => const SectionWeightScreen(),
            keys: 'ismb ismc angle flat bar beam channel'),
        _Tool('Object & Tank Weight', Icons.category,
            page: () => const ObjectWeightScreen(),
            keys: 'block cylinder sphere tank weight'),
        _Tool('Sling & Shackle Capacity', Icons.link,
            page: () => const CapacityScreen(),
            keys: 'choker basket hitch shackle wire rope'),
      ]),
      _Section('Safety & Equipment', Icons.health_and_safety, [
        _Tool('HSE Safety', Icons.health_and_safety,
            route: AppRoutes.hse, keys: 'safety hse'),
        _Tool('Inspection Checklist', Icons.fact_check,
            page: () => const InspectionScreen(),
            keys: 'inspection checklist sling crane shackle photo'),
        _Tool('Equipment Management', Icons.inventory_2,
            route: AppRoutes.equipment, keys: 'equipment inventory'),
        _Tool('QR Scanner', Icons.qr_code_scanner,
            route: AppRoutes.equipment, keys: 'qr scan'),
        _Tool('Certificate Tracker', Icons.event_available,
            page: () => const CertTrackerScreen(),
            keys: 'certificate expiry sling crane operator'),
      ]),
      _Section('System', Icons.settings, [
        _Tool('Backup', Icons.backup, route: AppRoutes.settings, keys: 'backup'),
        _Tool('Settings', Icons.settings,
            route: AppRoutes.settings, keys: 'settings'),
      ]),
    ];

const List<String> _quickTitles = [
  'Crane Finder (auto)',
  'Sling Length & Angle',
  'Lift Diagram',
  'Voice Commands',
  'Inspection Checklist',
  'Job Logbook',
  'Lift Plan PDF',
  'Wind Check',
];

const List<String> _tips = [
  'Load ka asli weight confirm karo, andaza mat lagao.',
  'Sling angle 45 deg se kam mat rakho.',
  'Lift se pehle hook latch aur sling tag check karo.',
  'Load ke neeche kabhi khade mat ho.',
  'Wind 32 km/h se upar ho to lifting band.',
  'Tag line lagao, load ko haath se mat pakdo.',
  'Crane ki load chart hamesha cab me rakho.',
  'Overhead line se safe doori rakho.',
  'Outrigger ke neeche mazboot mat lagao.',
  'Ek hi signalman ke signal maano.',
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _search = TextEditingController();
  final _voiceIn = VoiceInput();
  bool _listening = false;
  String _q = '';
  int _expired = 0;
  int _soon = 0;
  Set<String> _favs = {};

  @override
  void initState() {
    super.initState();
    _loadCerts();
    _loadFavs();
  }

  Future<void> _loadFavs() async {
    try {
      final f = await Pro2Db.favs();
      if (!mounted) return;
      setState(() => _favs = f);
    } catch (_) {}
  }

  Future<void> _toggleFav(_Tool t) async {
    try {
      await Pro2Db.toggleFav(t.title);
      await _loadFavs();
      if (!mounted) return;
      final now = _favs.contains(t.title);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(now
            ? '${t.title} favourite me joda'
            : '${t.title} favourite se hataya'),
        duration: const Duration(seconds: 1),
      ));
    } catch (_) {}
  }

  Future<void> _loadCerts() async {
    try {
      final rows = await ProDb.certs();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      int e = 0;
      int s = 0;
      for (final r in rows) {
        final d =
            DateTime.parse(r['expiry'] as String).difference(today).inDays;
        if (d < 0) {
          e++;
        } else if (d <= 30) {
          s++;
        }
      }
      if (!mounted) return;
      setState(() {
        _expired = e;
        _soon = s;
      });
    } catch (_) {}
  }

  Future<void> _voiceSearch() async {
    if (_listening) {
      await _voiceIn.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    final e = await _voiceIn.start((text, done) {
      if (!mounted) return;
      setState(() {
        _search.text = text;
        _q = text.trim().toLowerCase();
        if (done) _listening = false;
      });
    });
    if (e != null && mounted) {
      setState(() => _listening = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e)));
    }
  }

  void _open(_Tool t) {
    final p = t.page;
    final r = t.route;
    if (p != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => p()))
          .then((_) => _loadCerts());
    } else if (r != null) {
      Navigator.pushNamed(context, r).then((_) => _loadCerts());
    }
  }

  @override
  void dispose() {
    _voiceIn.stop();
    _search.dispose();
    super.dispose();
  }

  Widget _header(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.safetyOrange, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _grid(List<_Tool> tools) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.85,
      children: tools
          .map((t) => _ToolTile(
                tool: t,
                fav: _favs.contains(t.title),
                onTap: () => _open(t),
                onLong: () => _toggleFav(t),
              ))
          .toList(),
    );
  }

  Widget _certBanner() {
    final red = _expired > 0;
    final c = red ? Colors.redAccent : Colors.orangeAccent;
    final msg = red
        ? '$_expired certificate EXPIRED, $_soon 30 din me khatam'
        : '$_soon certificate 30 din me expire honge';
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c),
      ),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: c),
        title:
            Text(msg, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
        subtitle: const Text('Certificate Tracker kholo'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CertTrackerScreen()))
            .then((_) => _loadCerts()),
      ),
    );
  }

  Widget _tipCard() {
    final now = DateTime.now();
    final tip = _tips[(now.day + now.month) % _tips.length];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.tips_and_updates, color: AppColors.safetyOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aaj ki safety yaad',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(tip),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    final all = <_Tool>[];
    for (final s in sections) {
      all.addAll(s.tools);
    }
    final quick = all.where((t) => _quickTitles.contains(t.title)).toList();
    final favTools = all.where((t) => _favs.contains(t.title)).toList();
    final results = _q.isEmpty
        ? <_Tool>[]
        : all
            .where((t) => ('${t.title} ${t.keys}').toLowerCase().contains(_q))
            .toList();

    final children = <Widget>[
      TextField(
        controller: _search,
        onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Tool dhundo ya bolo (sling, crane, wind...)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                    color: _listening ? Colors.redAccent : null),
                onPressed: _voiceSearch,
              ),
              if (_q.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    setState(() => _q = '');
                  },
                ),
            ],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          isDense: true,
        ),
      ),
      const SizedBox(height: 12),
    ];
    if (_expired > 0 || _soon > 0) children.add(_certBanner());
    if (_q.isEmpty) {
      children.add(_tipCard());
      if (favTools.isNotEmpty) {
        children.add(_header('Favourites', Icons.star));
        children.add(_grid(favTools));
      }
      children.add(_header('Quick Access', Icons.bolt));
      children.add(SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: quick
              .map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(t.icon,
                          size: 18, color: AppColors.safetyOrange),
                      label: Text(t.title),
                      onPressed: () => _open(t),
                    ),
                  ))
              .toList(),
        ),
      ));
      for (final s in sections) {
        children.add(_header(s.title, s.icon));
        children.add(_grid(s.tools));
      }
      children.add(const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text('Tile ko dabakar rakho: favourite ban jayega',
            style: TextStyle(fontSize: 12, color: Colors.white54)),
      ));
    } else {
      children.add(_header('Results (${results.length})', Icons.search));
      children.add(results.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Kuch nahi mila. Doosra naam try karo.'))
          : _grid(results));
    }
    children.add(const SizedBox(height: 24));

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('SADDAM RIGGING A-Z',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Master Lifting Calculator  |  v3 Pro',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: children),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final _Tool tool;
  final bool fav;
  final VoidCallback onTap;
  final VoidCallback onLong;
  const _ToolTile({
    required this.tool,
    required this.fav,
    required this.onTap,
    required this.onLong,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLong,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(tool.icon,
                          color: AppColors.safetyOrange, size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tool.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            if (fav)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(Icons.star, size: 16, color: Colors.amber),
              ),
          ],
        ),
      ),
    );
  }
}
