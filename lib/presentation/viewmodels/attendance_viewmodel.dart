import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/student_model.dart';
import '../../data/services/location_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  List<Student> _records = [];
  String _errorMessage = ""; 

  List<Student> get records => _records;
  String get errorMessage => _errorMessage;

  AttendanceViewModel() {
    loadAttendance();
  }

  /// Loads all attendance logs from the database
  Future<void> loadAttendance() async {
    try {
      final data = await DatabaseHelper.instance.getAllAttendance();
      _records = List.from(data);
      notifyListeners(); 
    } catch (e) {
      debugPrint("Error loading attendance: $e");
    }
  }

  /// --- THE GATEKEEPER: PASSWORD VERIFICATION ---
  /// This method is called in the UI before navigating to the camera.
  /// It returns true only if the ID and Password match a registered student.
  Future<bool> verifyCredentials(String studentId, String password) async {
    try {
      _errorMessage = "";
      
      // Strict check against the 'students' table in SQLite
      bool isValid = await DatabaseHelper.instance.verifyPassword(studentId, password);
      
      if (!isValid) {
        _errorMessage = "Invalid ID or Password. Access Denied.";
        notifyListeners();
        return false;
      }
      
      return true; // Match found!
    } catch (e) {
      _errorMessage = "Verification System Error: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  /// Face Recognition Entry Point
  /// Called after successful ID/Password login
  Future<bool> verifyFaceAndMarkAttendance({
    required String name, 
    required String studentId,
  }) async {
    try {
      _errorMessage = ""; 
      
      // Small delay to simulate processing for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Proceed to save the record
      return await markAttendance(name, studentId);
      
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Final Step: Saving the Attendance Record
  Future<bool> markAttendance(String name, String studentId) async {
    try {
      _errorMessage = "";

      // 1. Fetch the official student data from DB (Security check)
      final studentData = await DatabaseHelper.instance.getStudentForVerification(studentId);
      
      if (studentData == null) {
        _errorMessage = "Attendance Denied: ID $studentId is not registered.";
        notifyListeners();
        return false;
      }

      // 2. Get GPS Location
      String currentLoc = "Unknown Location";
      try {
        currentLoc = await LocationService.getCurrentLocation();
      } catch (locError) {
        currentLoc = "GPS/Location Services Disabled";
      }
      
      // 3. Generate Timestamp
      final String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // 4. Create the record object
      // We use studentData['name'] to ensure the logged name is the one registered in DB
      final newRecord = Student(
        name: studentData['name'] ?? name, 
        studentId: studentId.trim(),
        password: "", // Security: Do not store passwords in logs
        timestamp: timestamp,
        location: currentLoc,
      );

      // 5. Save the record to the 'attendance' table
      await DatabaseHelper.instance.insertAttendance(newRecord);
      
      // 6. Refresh the local list for the History Screen
      await loadAttendance();
      return true;

    } catch (e) {
      _errorMessage = "System Error: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  /// Register a new student into the system
  Future<void> registerNewStudent(String name, String id, String pass, List<double>? faceEmbedding) async {
    try {
      _errorMessage = "";
      await DatabaseHelper.instance.registerStudent(name, id, pass, faceEmbedding);
      notifyListeners(); 
    } catch (e) {
      // Handle the UNIQUE constraint error if the ID already exists
      if (e.toString().contains("UNIQUE constraint failed")) {
        _errorMessage = "Registration Error: ID $id is already in use!";
      } else {
        _errorMessage = "Registration Error: ${e.toString()}";
      }
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }
}