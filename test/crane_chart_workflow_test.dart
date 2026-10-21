import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:saddam_rigging_az_master_calculator/services/crane_chart_rules.dart';
import 'package:saddam_rigging_az_master_calculator/screens/rigging_pro_db.dart';
import 'package:saddam_rigging_az_master_calculator/screens/rigging_pro.dart';
import 'package:saddam_rigging_az_master_calculator/screens/rigging_pro2.dart';
import 'backup_preservation_test.dart' show releasedSchemas;

Map<String,Object?> metadata()=>{
  for(final k in CraneChartRules.fields)k:'fixture $k',
  'version':1,'assetId':'C1','configuration':'Full R1','partsOfLine':'4',
  'verified':true,'verifiedAt':'2026-10-19T00:00:00Z',
};
List<Map<String,Object?>> rows({String? note})=>[
  for(final pair in [[5.0,20.0],[10.0,12.0],[15.0,8.0]])
    {'boom':30.0,'radius':pair[0],'capacity':pair[1],'note':note??CraneChartRules.encode(metadata())},
];
void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  test('legacy, malformed and incomplete configuration remain unverified',(){
    expect(CraneChartRules.metadata('old note'),isNull);
    expect(CraneChartRules.metadata('${CraneChartRules.prefix}{'),isNull);
    for(final key in CraneChartRules.fields){
      expect(CraneChartRules.incomplete({...metadata(),key:''}),isNotNull);
    }
    expect(CraneChartRules.incomplete({...metadata(),'verified':false}),isNotNull);
    expect(CraneChartRules.incomplete({...metadata(),'partsOfLine':'0'}),isNotNull);
    expect(CraneChartRules.incomplete(metadata()),isNull);
  });
  test('exact row never rounds or substitutes the next radius',(){
    expect(CraneChartRules.exactRow(rows(),30,10)!['capacity'],12);
    expect(CraneChartRules.exactRow(rows(),30,9.99),isNull);
    expect(CraneChartRules.exactRow(rows(),29.99,10),isNull);
    expect(CraneChartRules.exactRow([...rows(),rows()[1]],30,10),isNull);
  });
  test('duplicate, nonfinite, nonpositive and malformed rows blocked',(){
    for(final bad in <List<List<double>>>[
      [],[[30,5]],[[30,5,20],[30,5,10]],[[30,double.nan,20]],[[30,5,double.infinity]],[[30,0,20]],
    ]){expect(()=>CraneChartRules.validateRows(bad),throwsArgumentError);}
  });
  test('mixed source metadata cannot lend verification to other rows',(){
    final r=rows();r[1]={...r[1],'note':'unverified'};
    expect(CraneChartRules.verifiedRows(r),isNull);
    expect(CraneChartRules.verifiedRows(rows()),isNotNull);
  });
  test('finder checks all path radii, eligible asset and exact configuration',(){
    double? find({List<double> radii=const [5,15,10],String config='Full R1',Set<String> eligible=const {'C1'}})=>CraneChartRules.limitingCapacity(rows(),boom:30,radii:radii,configuration:config,eligibleAssetIds:eligible);
    expect(find(),8);
    expect(find(eligible:{}),isNull);
    expect(find(config:'Partial R1'),isNull);
    expect(find(radii:[5,14,10]),isNull);
    expect(()=>find(radii:[10,5,10]),throwsArgumentError);
    expect(()=>find(radii:[5,10]),throwsArgumentError);
  });
  group('existing database chart revision preservation',(){
    sqfliteFfiInit();
    late Directory dir;late Database db;
    setUp(()async{
      dir=await Directory.systemTemp.createTemp('rigsafe-chart-');
      db=await databaseFactoryFfi.openDatabase('${dir.path}/main.db');
      await db.execute('ATTACH DATABASE ? AS pro',['${dir.path}/pro.db']);
      for(final name in ['main','pro']){
        for(final sql in releasedSchemas[name]!){await db.execute(sql.replaceFirst('CREATE TABLE ','CREATE TABLE $name.'));}
      }
      await db.rawInsert('INSERT INTO pro.chart (id,crane,boom,radius,capacity,note) VALUES (7,?,?,?,?,?)',['Old',30,10,12,'legacy source']);
    });
    tearDown(()async{await db.close();await dir.delete(recursive:true);});
    test('rename archives original ID, values and source atomically',()async{
      await ProDb.replaceChartTo(db,'New',CraneChartRules.encode(metadata()),[[30,10,11]],previousName:'Old');
      final active=await db.rawQuery('SELECT * FROM pro.chart');
      expect(active.single['crane'],'New');
      final archive=await db.query('SafetyRecords');
      final old=(jsonDecode(archive.single['detailsJson'] as String)['rows'] as List).single;
      expect(old['id'],7);expect(old['capacity'],12);expect(old['note'],'legacy source');
    });
    test('failed new insertion rolls back archive and deletion',()async{
      await db.execute("CREATE TRIGGER pro.reject_new BEFORE INSERT ON chart BEGIN SELECT RAISE(ABORT,'fixture insert failure'); END");
      await expectLater(ProDb.replaceChartTo(db,'New','draft',[[30,10,11]],previousName:'Old'),throwsA(isA<DatabaseException>()));
      expect((await db.rawQuery('SELECT * FROM pro.chart')).single['id'],7);
      expect(await db.query('SafetyRecords'),isEmpty);
    });
    test('invalid replacement leaves original active chart untouched',()async{
      await expectLater(ProDb.replaceChartTo(db,'Old','draft',[[30,10,11],[30,10,9]]),throwsArgumentError);
      expect((await db.rawQuery('SELECT * FROM pro.chart')).single['note'],'legacy source');
      expect(await db.query('SafetyRecords'),isEmpty);
    });
  });
  testWidgets('Finder requires actual weights and never inserts default rigging',(tester)async{
    tester.view.physicalSize=const Size(432,960);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home:CraneFinderScreen()));
    final button=find.widgetWithText(ElevatedButton,'Crane dhundo');
    await tester.ensureVisible(button);await tester.pumpAndSettle();await tester.tap(button);await tester.pump();
    expect(find.textContaining('Payload requires a finite value.'),findsOneWidget);
    expect(find.text('0.5'),findsNothing);
  });
  testWidgets('voice crane command records inputs without guessed gross weight',(tester)async{
    await tester.pumpWidget(const MaterialApp(home:VoiceScreen()));
    await tester.enterText(find.byType(TextField),'crane 12 ton radius 18');
    FocusManager.instance.primaryFocus?.unfocus();await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton,'Chalao'));await tester.pumpAndSettle();
    expect(find.textContaining('Recognized payload: 12.00'),findsOneWidget);
    expect(find.textContaining('INCOMPLETE - confirm'),findsOneWidget);
    expect(find.textContaining('12.50'),findsNothing);
  });
}
