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

  static Future<ChartHit?> lookup(
      String crane, double boom, double radius) async {
    final d = await _open();
    final r = await d.query('chart',
        where: 'crane = ? AND boom = ? AND radius >= ?',
        whereArgs: [crane, boom, radius],
        orderBy: 'radius ASC',
        limit: 1);
    if (r.isEmpty) return null;
    return ChartHit((r.first['radius'] as num).toDouble(),
        (r.first['capacity'] as num).toDouble());
  }

  static Future<void> replaceChart(
      String crane, String note, List<List<double>> data) async {
    final d = await _open();
    final b = d.batch();
    b.delete('chart', where: 'crane = ?', whereArgs: [crane]);
    for (final r in data) {
      b.insert('chart', {
        'crane': crane,
        'boom': r[0],
        'radius': r[1],
        'capacity': r[2],
        'note': note,
      });
    }
    await b.commit(noResult: true);
  }

  static Future<void> deleteCrane(String crane) async {
    final d = await _open();
    await d.delete('chart', where: 'crane = ?', whereArgs: [crane]);
  }

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
