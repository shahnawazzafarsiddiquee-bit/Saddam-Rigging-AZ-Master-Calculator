import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../app/routes.dart';
import 'material_calculators.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_DashboardItem>[
      _DashboardItem('Rigging Calculator', Icons.calculate, AppRoutes.riggingTools),
      _DashboardItem('Crane Planning', Icons.precision_manufacturing, AppRoutes.cranePlanning),
      _DashboardItem('Lift Plan Generator', Icons.assignment, AppRoutes.liftPlan),
      _DashboardItem('Equipment Management', Icons.inventory_2, AppRoutes.equipment),
      _DashboardItem('QR Scanner', Icons.qr_code_scanner, AppRoutes.equipment, qrShortcut: true),
      _DashboardItem('HSE Safety', Icons.health_and_safety, AppRoutes.hse),
      _DashboardItem('Material Calculators', Icons.construction, 'material:hub'),
      _DashboardItem('Reports', Icons.picture_as_pdf, AppRoutes.reports),
      _DashboardItem('Backup', Icons.backup, AppRoutes.settings),
      _DashboardItem('Settings', Icons.settings, AppRoutes.settings),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('SADDAM RIGGING A-Z', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Master Lifting Calculator', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: GridView.builder(
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, i) {
            final item = items[i];
            return _DashboardTile(item: item);
          },
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final String route;
  final bool qrShortcut;
  _DashboardItem(this.title, this.icon, this.route, {this.qrShortcut = false});
}

class _DashboardTile extends StatelessWidget {
  final _DashboardItem item;
  const _DashboardTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (item.route == 'material:hub') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialCalculatorsScreen()));
          } else {
            Navigator.pushNamed(context, item.route);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: AppColors.safetyOrange, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
