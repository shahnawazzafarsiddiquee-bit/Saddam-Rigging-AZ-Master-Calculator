import 'package:flutter/material.dart';
import 'app/theme.dart';
import 'app/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaddamRiggingApp());
}

class SaddamRiggingApp extends StatelessWidget {
  const SaddamRiggingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saddam Rigging A-Z Master Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.dashboard,
      routes: AppRoutes.routes,
    );
  }
}
