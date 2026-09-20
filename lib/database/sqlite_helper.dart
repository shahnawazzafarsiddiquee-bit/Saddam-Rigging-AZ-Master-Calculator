import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Central SQLite helper. Single writable database file shared by the
/// whole app (offline-first — no network calls are ever made here).
class SqliteHelper {
  SqliteHelper._internal();
  static final SqliteHelper instance = SqliteHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'saddam_rigging_master.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Equipment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipmentId TEXT NOT NULL,
        type TEXT NOT NULL,
        serialNumber TEXT,
        manufacturer TEXT,
        wll REAL NOT NULL,
        inspectionDate TEXT,
        expiryDate TEXT,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Inspection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipmentId TEXT NOT NULL,
        inspectorName TEXT,
        inspectionDate TEXT,
        result TEXT,
        remarks TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Calculations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        calculatorType TEXT NOT NULL,
        inputJson TEXT NOT NULL,
        resultJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE LiftPlans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        projectName TEXT NOT NULL,
        client TEXT,
        location TEXT,
        date TEXT,
        loadDescription TEXT,
        loadWeight REAL,
        craneDetails TEXT,
        riggingArrangement TEXT,
        liftingSequence TEXT,
        personnel TEXT,
        safetyRequirements TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE SafetyRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recordType TEXT NOT NULL,
        title TEXT NOT NULL,
        detailsJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reportType TEXT NOT NULL,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // ---------- Generic helpers ----------
  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    return db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table,
      {String? orderBy}) async {
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  Future<int> update(String table, Map<String, dynamic> row, int id) async {
    final db = await database;
    return db.update(table, row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> findByEquipmentId(String equipmentId) async {
    final db = await database;
    final rows = await db.query(
      'Equipment',
      where: 'equipmentId = ?',
      whereArgs: [equipmentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Wipes and recreates all tables — used by the backup/restore service.
  Future<void> resetDatabase() async {
    final db = await database;
    final tables = [
      'Equipment',
      'Inspection',
      'Calculations',
      'LiftPlans',
      'SafetyRecords',
      'Reports'
    ];
    for (final t in tables) {
      await db.delete(t);
    }
  }
}
