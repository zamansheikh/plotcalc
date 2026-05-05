import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:injectable/injectable.dart';

@singleton
class DatabaseHelper {
  static Database? _database;

  static const String tableName = 'measurements';
  static const String dbName = 'plotcalc.db';
  static const int dbVersion = 2; // Updated version for new columns

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        shapeType TEXT NOT NULL,
        points TEXT NOT NULL,
        dimensions TEXT,
        sideMeasurements TEXT,
        diagonalMeasurements TEXT,
        area REAL NOT NULL,
        createdAt TEXT NOT NULL,
        preferredUnit TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN sideMeasurements TEXT',
      );
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN diagonalMeasurements TEXT',
      );
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
