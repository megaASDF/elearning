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
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const boolType = 'INTEGER'; // 0 for false, 1 for true
    const intType = 'INTEGER';
    const doubleType = 'REAL';

    // 1. Semesters
    await db.execute('''
      CREATE TABLE semesters (
        id $idType,
        code $textType NOT NULL,
        name $textType NOT NULL,
        startDate $textType NOT NULL,
        endDate $textType NOT NULL,
        isCurrent $boolType NOT NULL,
        createdAt $textType,
        updatedAt $textType
      )
    ''');

    // 2. Courses
    await db.execute('''
      CREATE TABLE courses (
        id $idType,
        semesterId $textType NOT NULL,
        code $textType NOT NULL,
        name $textType NOT NULL,
        description $textType,
        coverImageUrl $textType,
        instructorName $textType,
        numberOfSessions $intType,
        groupCount $intType,
        studentCount $intType,
        createdAt $textType,
        lastSync $textType,
        FOREIGN KEY (semesterId) REFERENCES semesters (id) ON DELETE CASCADE
      )
    ''');

    // 3. Groups
    await db.execute('''
      CREATE TABLE groups (
        id $idType,
        courseId $textType NOT NULL,
        name $textType NOT NULL,
        studentCount $intType DEFAULT 0,
        createdAt $textType,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // 4. Students
    await db.execute('''
      CREATE TABLE students (
        id $idType,
        username $textType,
        displayName $textType,
        email $textType,
        role $textType,
        groupId $textType,
        groupName $textType,
        phoneNumber $textType,
        bio $textType,
        department $textType,
        avatarUrl $textType,
        createdAt $textType,
        updatedAt $textType,
        FOREIGN KEY (groupId) REFERENCES groups (id) ON DELETE SET NULL
      )
    ''');

    // 5. Assignments
    await db.execute('''
      CREATE TABLE assignments (
        id $idType,
        courseId $textType NOT NULL,
        groupIds $textType, -- Stored as JSON string
        title $textType NOT NULL,
        description $textType,
        attachments $textType, -- Stored as JSON string
        startDate $textType,
        deadline $textType,
        lateDeadline $textType,
        allowLateSubmission $boolType,
        maxAttempts $intType,
        allowedFileFormats $textType, -- Stored as JSON string
        maxFileSizeMB $doubleType,
        createdAt $textType,
        updatedAt $textType,
        lastSync $textType,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // 6. Quizzes
    await db.execute('''
      CREATE TABLE quizzes (
        id $idType,
        courseId $textType NOT NULL,
        groupIds $textType, -- JSON string
        title $textType NOT NULL,
        description $textType,
        openTime $textType,
        closeTime $textType,
        durationMinutes $intType,
        maxAttempts $intType,
        easyQuestions $intType,
        mediumQuestions $intType,
        hardQuestions $intType,
        questionIds $textType, -- JSON string
        createdAt $textType,
        updatedAt $textType,
        lastSync $textType,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // 7. Questions
    await db.execute('''
      CREATE TABLE questions (
        id $idType,
        courseId $textType NOT NULL,
        questionText $textType NOT NULL,
        choices $textType NOT NULL, -- JSON string
        correctAnswerIndex $intType NOT NULL,
        difficulty $textType NOT NULL,
        createdAt $textType,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // 8. Materials
    await db.execute('''
      CREATE TABLE materials (
        id $idType,
        courseId $textType NOT NULL,
        title $textType NOT NULL,
        description $textType,
        attachments $textType, -- JSON
        links $textType, -- JSON
        createdAt $textType,
        updatedAt $textType,
        authorName $textType,
        viewCount $intType,
        downloadCount $intType,
        lastSync $textType,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // 9. Forum Topics
    await db.execute('''
      CREATE TABLE forum_topics (
        id $idType,
        courseId $textType NOT NULL,
        title $textType NOT NULL,
        content $textType NOT NULL,
        authorId $textType,
        authorName $textType,
        attachments $textType, -- JSON
        createdAt $textType,
        replyCount $intType,
        lastReplyAt $textType,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // 10. Messages
    await db.execute('''
      CREATE TABLE messages (
        id $idType,
        senderId $textType NOT NULL,
        senderName $textType,
        receiverId $textType NOT NULL,
        receiverName $textType,
        content $textType,
        attachments $textType,
        isRead $boolType,
        createdAt $textType
      )
    ''');

    // 11. Announcements
    await db.execute('''
      CREATE TABLE announcements (
        id $idType,
        courseId $textType NOT NULL,
        title $textType NOT NULL,
        content $textType NOT NULL,
        attachments $textType, -- JSON
        groupIds $textType, -- JSON
        createdAt $textType,
        authorName $textType,
        viewCount $intType,
        commentCount $intType,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');
  }

  // Helper to close DB (optional)
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}