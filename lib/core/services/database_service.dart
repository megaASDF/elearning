import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'elearning_offline.db');

    return await openDatabase(
      path,
      version: 2, // Updated version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Courses table
    await db.execute('''
      CREATE TABLE courses(
        id TEXT PRIMARY KEY,
        name TEXT,
        code TEXT,
        description TEXT,
        instructorName TEXT,
        data TEXT,
        lastSync TEXT
      )
    ''');

    // Assignments table
    await db.execute('''
      CREATE TABLE assignments(
        id TEXT PRIMARY KEY,
        courseId TEXT,
        title TEXT,
        description TEXT,
        deadline TEXT,
        data TEXT,
        lastSync TEXT
      )
    ''');

    // Announcements table
    await db.execute('''
      CREATE TABLE announcements(
        id TEXT PRIMARY KEY,
        courseId TEXT,
        title TEXT,
        content TEXT,
        data TEXT,
        lastSync TEXT
      )
    ''');

    // Materials table
    await db.execute('''
      CREATE TABLE materials(
        id TEXT PRIMARY KEY,
        courseId TEXT,
        title TEXT,
        description TEXT,
        data TEXT,
        lastSync TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS materials(
          id TEXT PRIMARY KEY,
          courseId TEXT,
          title TEXT,
          description TEXT,
          data TEXT,
          lastSync TEXT
        )
      ''');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}