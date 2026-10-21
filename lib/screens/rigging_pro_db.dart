import 'dart:convert';
import '../services/backup_service.dart';
import '../services/crane_chart_rules.dart';
import 'package:sqflite/sqflite.dart';

class ChartHit {
  final double radius;
  final double capacity;
  const ChartHit(this.radius, this.capacity);
}

class ProDb {
  static Database? _db;

  static Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    final d = await openDatabase(
      '$dir/rigging_pro.db',
      version: 1,
      onCreate: (Database database, int version) async {
        await database.execute(
            'CREATE TABLE chart (id INTEGER PRIMARY KEY AUTOINCREMENT, crane TEXT NOT NULL, boom REAL NOT NULL, radius REAL NOT NULL, capacity REAL NOT NULL, note TEXT)');
        await database.execute(
            'CREATE TABLE certs (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, kind TEXT NOT NULL, ident TEXT, expiry TEXT NOT NULL)');
      },
    );
    _db = d;
    return d;
  }

  static Future<List<String>> cranes() async {
    final d = await _open();
    final r =
        await d.rawQuery('SELECT DISTINCT crane FROM chart ORDER BY crane');
    return r.map((e) => e['crane'] as String).toList();
  }

  static Future<List<double>> booms(String crane) async {
    final d = await _open();
    final r = await d.rawQuery(
        'SELECT DISTINCT boom FROM chart WHERE crane = ? ORDER BY boom',
        [crane]);
    return r.map((e) => (e['boom'] as num).toDouble()).toList();
  }

  static Future<String> note(String crane) async {
    final d = await _open();
    final r = await d.query('chart',
        columns: ['note'], where: 'crane = ?', whereArgs: [crane], limit: 1);
    if (r.isEmpty) return '';
    return (r.first['note'] as String?) ?? '';
  }

  static Future<List<Map<String, Object?>>> allRows(String crane) async {
    final d = await _open();
    return d.query('chart',
        where: 'crane = ?',
        whereArgs: [crane],
        orderBy: 'boom ASC, radius ASC');
  }

  static Future<ChartHit?> lookup(String crane,double boom,double radius) async {
    final rows=await allRows(crane);
    if(CraneChartRules.verifiedRows(rows)==null)return null;
    final hit=CraneChartRules.exactRow(rows,boom,radius);
    return hit==null?null:ChartHit((hit['radius'] as num).toDouble(),(hit['capacity'] as num).toDouble());
  }

  static Future<void> replaceChart(String crane,String note,List<List<double>> data,{String? previousName}) =>
    BackupService.withDatabases((db)=>replaceChartTo(db,crane,note,data,previousName:previousName));

  static Future<void> replaceChartTo(Database db,String crane,String note,List<List<double>> data,{String? previousName}) async {
    if(crane.trim().isEmpty)throw ArgumentError('Chart name required.');
    CraneChartRules.validateRows(data);
    await db.transaction((tx)async{
      final names={crane,if(previousName!=null)previousName};
      for(final name in names){
        final old=await tx.rawQuery('SELECT * FROM pro.chart WHERE crane = ?',[name]);
        if(old.isNotEmpty)await _archive(tx,name,old,'REPLACED');
        await tx.rawDelete('DELETE FROM pro.chart WHERE crane = ?',[name]);
      }
      for(final r in data){await tx.rawInsert('INSERT INTO pro.chart (crane,boom,radius,capacity,note) VALUES (?,?,?,?,?)',[crane,r[0],r[1],r[2],note]);}
    });
  }
  static Future<void> _archive(DatabaseExecutor tx,String name,List<Map<String,Object?>> rows,String reason)=>tx.insert('SafetyRecords',{
    'recordType':'Crane Chart Archive','title':name,'detailsJson':jsonEncode({'version':1,'reason':reason,'rows':rows}),'createdAt':DateTime.now().toUtc().toIso8601String()
  }).then((_){});
  static Future<void> deleteCrane(String crane)=>BackupService.withDatabases((db)=>db.transaction((tx)async{
    final rows=await tx.rawQuery('SELECT * FROM pro.chart WHERE crane = ?',[crane]);
    if(rows.isNotEmpty)await _archive(tx,crane,rows,'WITHDRAWN');
    await tx.rawDelete('DELETE FROM pro.chart WHERE crane = ?',[crane]);
  }));
  static Future<List<Map<String,Object?>>> chartHistory()=>BackupService.withDatabases((db)=>db.query('SafetyRecords',where:'recordType = ?',whereArgs:['Crane Chart Archive'],orderBy:'id DESC'));

  static Future<List<Map<String, Object?>>> certs() async {
    final d = await _open();
    return d.query('certs', orderBy: 'expiry ASC');
  }

  static Future<void> addCert(
      String name, String kind, String ident, String expiry) async {
    final d = await _open();
    await d.insert('certs',
        {'name': name, 'kind': kind, 'ident': ident, 'expiry': expiry});
  }

  static Future<void> deleteCert(int id) async {
    final d = await _open();
    await d.delete('certs', where: 'id = ?', whereArgs: [id]);
  }
}
