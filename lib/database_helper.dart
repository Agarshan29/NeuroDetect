import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'scan_result.dart'; // Import the model

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const String _dbName = 'neurodetect_history.db';
  static const String _tableName = 'scan_history';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        imagePath TEXT NOT NULL UNIQUE, -- Ensure image path is unique if needed
        diagnosis TEXT NOT NULL,
        probabilities TEXT,           -- Store probabilities as JSON String
        reportJson TEXT NOT NULL      -- Store report details as JSON String
      )
      ''');
  }

  Future<int> insertScan(ScanResult scan) async {
    final db = await database;
    return await db.insert(_tableName, scan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ScanResult>> getAllScans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) => ScanResult.fromMap(maps[i]));
  }

  Future<int> deleteAllScans() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  Future close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}