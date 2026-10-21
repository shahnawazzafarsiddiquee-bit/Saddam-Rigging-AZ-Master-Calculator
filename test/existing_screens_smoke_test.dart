import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:saddam_rigging_az_master_calculator/app/routes.dart';
import 'package:saddam_rigging_az_master_calculator/app/theme.dart';
import 'package:saddam_rigging_az_master_calculator/screens/rigging_advanced.dart';
import 'package:saddam_rigging_az_master_calculator/screens/rigging_pro.dart';
import 'package:saddam_rigging_az_master_calculator/screens/rigging_pro2.dart';
import 'package:saddam_rigging_az_master_calculator/screens/material_calculators.dart';
import 'package:saddam_rigging_az_master_calculator/screens/advanced_calculators.dart';
import 'package:saddam_rigging_az_master_calculator/screens/unit_converter.dart';
import 'package:saddam_rigging_az_master_calculator/screens/synthetic_sling.dart';
import 'package:saddam_rigging_az_master_calculator/screens/hardware_selector.dart';
import 'package:saddam_rigging_az_master_calculator/screens/lift_total_summary.dart';

// These tests exercise layout and existing route construction with empty local
// data. They do not claim to test camera, OCR, file sharing, BLE or device APIs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactorySqflitePlugin;
  var nextDatabaseId = 0;
  const sqliteChannel = MethodChannel('com.tekartik.sqflite');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sqliteChannel, (call) async {
          switch (call.method) {
            case 'getDatabasesPath':
              return '/tmp/rigsafe_widget_databases';
            case 'openDatabase':
              return {'id': ++nextDatabaseId};
            case 'query':
              final sql = (call.arguments as Map)['sql'] as String;
              if (sql.toLowerCase().contains('pragma user_version')) {
                return [
                  {'user_version': 1},
                ];
              }
              return <Map<String, Object?>>[];
            case 'batch':
              return <Object?>[];
            case 'insert':
              return 1;
            case 'update':
              return 0;
            default:
              return null;
          }
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sqliteChannel, null);
  });

  test(
    'original theme palette, backgrounds and button colours are preserved',
    () {
      final theme = AppTheme.darkTheme;
      expect(AppColors.navy, const Color(0xFF15335C));
      expect(AppColors.safetyOrange, const Color(0xFFFF6F00));
      expect(theme.scaffoldBackgroundColor, const Color(0xFF1E1E1E));
      expect(theme.cardTheme.color, const Color(0xFF2A2E33));
      expect(theme.colorScheme.primary, AppColors.safetyOrange);
      expect(theme.colorScheme.secondary, AppColors.safetyOrange);
      expect(theme.appBarTheme.backgroundColor, AppColors.navy);
      expect(
        theme.elevatedButtonTheme.style!.backgroundColor!.resolve({}),
        AppColors.safetyOrange,
      );
      expect(
        theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
        AppColors.safetyOrange,
      );
    },
  );

  final standalone = <String, Widget>{
    'advanced rigging': const AdvancedRiggingScreen(),
    'sling length': const SlingLengthScreen(),
    'boom geometry': const CraneBoomScreen(),
    'wind': const WindCheckScreen(),
    'CG share': const CgShareScreen(),
    'ground bearing': const GroundBearingScreen(),
    'pro tools': const ProToolsScreen(),
    'chart editor': const ChartEditScreen(),
    'load chart': const CraneChartScreen(),
    'lift PDF': const LiftPlanPdfScreen(),
    'sling capacity': const CapacityScreen(),
    'steel section': const SectionWeightScreen(),
    'object weight': const ObjectWeightScreen(),
    'certificates': const CertTrackerScreen(),
    'pulling force': const PullingForceScreen(),
    'crane finder': const CraneFinderScreen(),
    'diagram': const LiftDiagramScreen(),
    'inspection': const InspectionScreen(),
    'inspection history': const InspectionHistoryScreen(),
    'logbook': const LogbookScreen(),
    'log entry': const LogEntryScreen(),
    'voice command': const VoiceScreen(),
    'material tools': const MaterialCalculatorsScreen(),
    'pipe': const SteelPipeCalculator(),
    'plate': const SteelPlateCalculator(),
    'concrete': const ConcreteCalculator(),
    'rebar': const RebarCalculator(),
    'advanced calculators': const AdvancedCalculatorsHub(),
    'tandem': const TandemLiftScreen(),
    'spreader': const SpreaderBeamScreen(),
    'dynamic': const DynamicLoadScreen(),
    'multipoint': const MultiPointLiftScreen(),
    'bolt': const BoltTorqueScreen(),
    'unit conversion': const UnitConverterScreen(),
    'synthetic sling': const SyntheticSlingScreen(),
    'hardware selector': const HardwareSelectorScreen(),
    'total summary': const LiftTotalSummaryScreen(),
  };

  Future<void> render(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(432, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: screen),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  for (final entry in AppRoutes.routes.entries) {
    testWidgets('existing registered route renders: ${entry.key}', (
      tester,
    ) async {
      await render(tester, Builder(builder: entry.value));
    });
  }
  for (final entry in standalone.entries) {
    testWidgets('existing tool renders: ${entry.key}', (tester) async {
      await render(tester, entry.value);
    });
  }
}
