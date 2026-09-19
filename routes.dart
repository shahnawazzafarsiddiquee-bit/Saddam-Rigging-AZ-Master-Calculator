import 'package:flutter/material.dart';

import '../screens/dashboard.dart';
import '../screens/rigging_tools.dart';
import '../screens/crane_planning.dart';
import '../screens/lift_plan.dart';
import '../screens/equipment.dart';
import '../screens/hse.dart';
import '../screens/reports.dart';
import '../screens/settings.dart';

import '../calculators/sling_angle.dart';
import '../calculators/load_share.dart';
import '../calculators/wll.dart';
import '../calculators/shackle.dart';
import '../calculators/wire_rope.dart';
import '../calculators/dd_ratio.dart';
import '../calculators/cog.dart';
import '../calculators/pad_eye.dart';

class AppRoutes {
  static const dashboard = '/';
  static const riggingTools = '/rigging-tools';
  static const cranePlanning = '/crane-planning';
  static const liftPlan = '/lift-plan';
  static const equipment = '/equipment';
  static const hse = '/hse';
  static const reports = '/reports';
  static const settings = '/settings';

  static const slingAngle = '/calc/sling-angle';
  static const loadShare = '/calc/load-share';
  static const wll = '/calc/wll';
  static const shackle = '/calc/shackle';
  static const wireRope = '/calc/wire-rope';
  static const ddRatio = '/calc/dd-ratio';
  static const cog = '/calc/cog';
  static const padEye = '/calc/pad-eye';

  static Map<String, WidgetBuilder> get routes => {
        dashboard: (_) => const DashboardScreen(),
        riggingTools: (_) => const RiggingToolsScreen(),
        cranePlanning: (_) => const CranePlanningScreen(),
        liftPlan: (_) => const LiftPlanScreen(),
        equipment: (_) => const EquipmentScreen(),
        hse: (_) => const HseScreen(),
        reports: (_) => const ReportsScreen(),
        settings: (_) => const SettingsScreen(),
        slingAngle: (_) => const SlingAngleCalculator(),
        loadShare: (_) => const LoadShareCalculator(),
        wll: (_) => const WllCalculator(),
        shackle: (_) => const ShackleCalculator(),
        wireRope: (_) => const WireRopeCalculator(),
        ddRatio: (_) => const DdRatioCalculator(),
        cog: (_) => const CogCalculator(),
        padEye: (_) => const PadEyeCalculator(),
      };
}
