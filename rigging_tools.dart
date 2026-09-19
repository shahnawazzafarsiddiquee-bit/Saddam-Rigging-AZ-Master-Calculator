import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../app/routes.dart';

class RiggingToolsScreen extends StatelessWidget {
  const RiggingToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      ('Sling Angle Calculator', Icons.architecture, AppRoutes.slingAngle),
      ('Load Share Calculator', Icons.call_split, AppRoutes.loadShare),
      ('WLL Calculator', Icons.fitness_center, AppRoutes.wll),
      ('Shackle Calculator', Icons.link, AppRoutes.shackle),
      ('Wire Rope Calculator', Icons.cable, AppRoutes.wireRope),
      ('D/d Ratio Calculator', Icons.circle_outlined, AppRoutes.ddRatio),
      ('Center of Gravity Calculator', Icons.center_focus_strong, AppRoutes.cog),
      ('Pad Eye Check', Icons.hexagon_outlined, AppRoutes.padEye),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Rigging Calculator')),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (title, icon, route) = tools[i];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.navy,
                child: Icon(icon, color: AppColors.safetyOrange),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, route),
            ),
          );
        },
      ),
    );
  }
}
