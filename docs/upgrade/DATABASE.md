# Existing database documentation

All schemas remain version 1. No tables or columns were removed or rebuilt.

Backups preserve these 12 application tables and their IDs/photo bytes. External
PDF paths remain paths; the PDF files themselves are not embedded.

## saddam_rigging_master.db

```sql
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
      );
CREATE TABLE Inspection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        equipmentId TEXT NOT NULL,
        inspectorName TEXT,
        inspectionDate TEXT,
        result TEXT,
        remarks TEXT
      );
CREATE TABLE Calculations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        calculatorType TEXT NOT NULL,
        inputJson TEXT NOT NULL,
        resultJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      );
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
      );
CREATE TABLE SafetyRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recordType TEXT NOT NULL,
        title TEXT NOT NULL,
        detailsJson TEXT NOT NULL,
        createdAt TEXT NOT NULL
      );
CREATE TABLE Reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reportType TEXT NOT NULL,
        title TEXT NOT NULL,
        filePath TEXT NOT NULL,
        createdAt TEXT NOT NULL
      );
```

## rigging_pro.db

```sql
CREATE TABLE chart (id INTEGER PRIMARY KEY AUTOINCREMENT, crane TEXT NOT NULL, boom REAL NOT NULL, radius REAL NOT NULL, capacity REAL NOT NULL, note TEXT);
CREATE TABLE certs (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, kind TEXT NOT NULL, ident TEXT, expiry TEXT NOT NULL);
```

## rigging_pro2.db

```sql
CREATE TABLE lifts (id INTEGER PRIMARY KEY AUTOINCREMENT, dt TEXT NOT NULL, project TEXT, descr TEXT, weight REAL, crane TEXT, boom REAL, radius REAL, util REAL, result TEXT, notes TEXT);
CREATE TABLE inspections (id INTEGER PRIMARY KEY AUTOINCREMENT, dt TEXT NOT NULL, kind TEXT NOT NULL, item TEXT, inspector TEXT, result TEXT NOT NULL, details TEXT);
CREATE TABLE photos (id INTEGER PRIMARY KEY AUTOINCREMENT, insp_id INTEGER NOT NULL, data BLOB NOT NULL);
CREATE TABLE favs (title TEXT PRIMARY KEY);
```

## Backup/restore behavior

Version-2 backups require all three schemas and all expected tables. Legacy
six-table JSON restores main only. Types, IDs, columns and photo references
are validated before deletion. A recovery snapshot precedes restore. Multi-file
restore supports DELETE/TRUNCATE/PERSIST rollback journals and refuses WAL
before changing records. New schema versions must extend the backup format and
frozen migration tests; never replace the released fixture with new schemas.
