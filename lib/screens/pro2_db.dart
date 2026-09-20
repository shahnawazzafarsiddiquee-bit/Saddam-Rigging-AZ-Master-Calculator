import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';

class LiftDiagramCache {
  static Uint8List? png;
}

class Pro2Db {
  static Database? _db;

  static Future<Database> _open() async {
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    final d = await openDatabase(
      '$dir/rigging_pro2.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
            'CREATE TABLE lifts (id INTEGER PRIMARY KEY AUTOINCREMENT, dt TEXT NOT NULL, project TEXT, descr TEXT, weight REAL, crane TEXT, boom REAL, radius REAL, util REAL, result TEXT, notes TEXT)');
        await db.execute(
            'CREATE TABLE inspections (id INTEGER PRIMARY KEY AUTOINCREMENT, dt TEXT NOT NULL, kind TEXT NOT NULL, item TEXT, inspector TEXT, result TEXT NOT NULL, details TEXT)');
        await db.execute(
            'CREATE TABLE photos (id INTEGER PRIMARY KEY AUTOINCREMENT, insp_id INTEGER NOT NULL, data BLOB NOT NULL)');
        await db.execute('CREATE TABLE favs (title TEXT PRIMARY KEY)');
      },
    );
    _db = d;
    return d;
  }

  static Future<int> addLift(Map<String, Object?> row) async {
    final d = await _open();
    return d.insert('lifts', row);
  }

  static Future<List<Map<String, Object?>>> lifts() async {
    final d = await _open();
    return d.query('lifts', orderBy: 'dt DESC, id DESC');
  }

  static Future<void> deleteLift(int id) async {
    final d = await _open();
    await d.delete('lifts', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> addInspection(Map<String, Object?> row) async {
    final d = await _open();
    return d.insert('inspections', row);
  }

  static Future<void> addPhoto(int inspId, Uint8List data) async {
    final d = await _open();
    await d.insert('photos', {'insp_id': inspId, 'data': data});
  }

  static Future<List<Map<String, Object?>>> inspections() async {
    final d = await _open();
    return d.query('inspections', orderBy: 'dt DESC, id DESC');
  }

  static Future<List<Uint8List>> photos(int inspId) async {
    final d = await _open();
    final r = await d.query('photos',
        where: 'insp_id = ?', whereArgs: [inspId], orderBy: 'id ASC');
    return r.map((e) => Uint8List.fromList(e['data'] as List<int>)).toList();
  }

  static Future<void> deleteInspection(int id) async {
    final d = await _open();
    await d.delete('photos', where: 'insp_id = ?', whereArgs: [id]);
    await d.delete('inspections', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Set<String>> favs() async {
    final d = await _open();
    final r = await d.query('favs');
    return r.map((e) => e['title'] as String).toSet();
  }

  static Future<void> toggleFav(String title) async {
    final d = await _open();
    final r = await d.query('favs', where: 'title = ?', whereArgs: [title]);
    if (r.isEmpty) {
      await d.insert('favs', {'title': title});
    } else {
      await d.delete('favs', where: 'title = ?', whereArgs: [title]);
    }
  }
}
