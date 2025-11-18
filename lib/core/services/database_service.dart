import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('elearning.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        displayName TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        avatarUrl TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Semesters table
    await db.execute('''
      CREATE TABLE semesters (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        isCurrent INTEGER NOT NULL
      )
    ''');

    // Courses table
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        semesterId TEXT NOT NULL,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        coverImageUrl TEXT,
        instructorName TEXT NOT NULL,
        numberOfSessions INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        groupCount INTEGER,
        studentCount INTEGER
      )
    ''');

    // Enrollments table
    await db.execute('''
      CREATE TABLE enrollments (
        id TEXT PRIMARY KEY,
        courseId TEXT NOT NULL,
        studentId TEXT NOT NULL,
        groupId TEXT NOT NULL,
        enrolledAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}