import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student_model.dart';
import 'dart:convert'; 

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mit_attendance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    // Student Registration Table
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        studentId TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        face_data TEXT 
      )
    ''');

    // Attendance Logs Table
    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        studentId TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        location TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE students ADD COLUMN face_data TEXT');
    }
  }

  // --- Student Registration ---
  Future<int> registerStudent(String name, String studentId, String password, List<double>? faceEmbedding) async {
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    if (password.length < 8 || !hasLetter || !hasNumber) {
      throw Exception("Password must be 8+ chars with letters and numbers.");
    }

    final db = await instance.database;
    String? faceDataJson = faceEmbedding != null ? jsonEncode(faceEmbedding) : null;

    return await db.insert('students', {
      'name': name.trim(),
      'studentId': studentId.trim(),
      'password': password, // Ideally, use a hash here for production
      'face_data': faceDataJson,
    });
  }

  // --- STEP 3 UPDATE: Strict Password & ID Matching ---
  /// This method strictly checks if a row exists with BOTH matching ID and Password.
  Future<bool> verifyPassword(String studentId, String providedPassword) async {
    final db = await instance.database;
    
    // We query the 'students' table. 
    // The 'AND' operator ensures both conditions must be true for the SAME row.
    final List<Map<String, dynamic>> maps = await db.query(
      'students',
      where: 'studentId = ? AND password = ?',
      whereArgs: [studentId.trim(), providedPassword],
    );
    
    // Returns true ONLY if exactly one matching record is found.
    // If ID is wrong OR Password is wrong, maps.length will be 0.
    return maps.length == 1; 
  }

  // --- Attendance Logic (Ensures Data Integrity) ---
  Future<int> insertAttendance(Student student) async {
    final db = await instance.database;
    final String cleanId = student.studentId.trim();

    // 1. Fetch official record to verify existence and grab the registered name
    final List<Map<String, dynamic>> registeredStudent = await db.query(
      'students',
      where: 'studentId = ?',
      whereArgs: [cleanId],
    );

    if (registeredStudent.isEmpty) {
      throw Exception("Access Denied: ID $cleanId is not registered in the system.");
    }

    // 2. Extract official name to ensure the attendance log uses the registered identity
    final String officialName = registeredStudent.first['name'] as String;

    final row = {
      'name': officialName, 
      'studentId': cleanId,
      'timestamp': student.timestamp,
      'location': student.location,
    };
    
    return await db.insert('attendance', row);
  }

  // --- Helper Methods ---

  Future<List<Student>> getAllAttendance() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'attendance', 
      orderBy: 'timestamp DESC'
    );
    
    return List.generate(result.length, (i) {
      return Student(
        id: result[i]['id'] as int?,
        name: result[i]['name'] as String,
        studentId: result[i]['studentId'] as String,
        password: "", 
        timestamp: result[i]['timestamp'] as String,
        location: result[i]['location'] as String,
      );
    });
  }

  Future<int> deleteAllAttendance() async {
    final db = await instance.database;
    return await db.delete('attendance');
  }

  Future<Map<String, dynamic>?> getStudentForVerification(String studentId) async {
    final db = await instance.database;
    final results = await db.query(
      'students',
      where: 'studentId = ?',
      whereArgs: [studentId.trim()],
    );
    
    return results.isNotEmpty ? results.first : null;
  }
}