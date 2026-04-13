import 'dart:convert';
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/student_model.dart';
import '../../data/services/location_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  List<Student> _records = [];
  String _errorMessage = ""; 
  
  // --- NEW: Loading State ---
  bool _isLoading = false;

  List<Student> get records => _records;
  String get errorMessage => _errorMessage;
  
  // --- NEW: Loading Getter ---
  bool get isLoading => _isLoading;

  AttendanceViewModel() {
    loadAttendance();
  }

  // Helper to toggle loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

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
  Future<bool> verifyCredentials(String studentId, String password) async {
    _setLoading(true); // Start loading
    try {
      _errorMessage = "";
      bool isValid = await DatabaseHelper.instance.verifyPassword(studentId, password);
      
      if (!isValid) {
        _errorMessage = "Invalid ID or Password. Access Denied.";
        _setLoading(false);
        return false;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = "Verification System Error: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  /// --- STEP 3: TRUE FACE RECOGNITION LOGIC ---
  Future<bool> verifyFaceAndMarkAttendance({
    required String studentId,
    required List<double> liveEmbedding,
  }) async {
    _setLoading(true); // Start loading while processing face/location
    try {
      _errorMessage = ""; 
      
      final studentData = await DatabaseHelper.instance.getStudentForVerification(studentId);
      
      if (studentData == null) {
        _errorMessage = "Security Alert: ID $studentId not found.";
        _setLoading(false);
        return false;
      }

      List<double> registeredEmbedding = List<double>.from(
        jsonDecode(studentData['face_data'])
      );

      // MATH: Calculate Euclidean Distance
      double distance = 0;
      for (int i = 0; i < liveEmbedding.length; i++) {
        distance += pow((liveEmbedding[i] - registeredEmbedding[i]), 2);
      }
      distance = sqrt(distance);

      debugPrint("Final Face Distance for $studentId: $distance");

      if (distance < 0.6) {
        // MATCH: markAttendance handles the location search
        bool result = await markAttendance(studentData['name'], studentId);
        _setLoading(false); // Done
        return result;
      } else {
        _errorMessage = "Security Alert: Face does not match profile!";
        _setLoading(false);
        return false;
      }
      
    } catch (e) {
      _errorMessage = "Recognition Error: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  /// Final Step: Saving the Attendance Record
  Future<bool> markAttendance(String name, String studentId) async {
    try {
      _errorMessage = "";

      // 1. Get GPS Location (This uses your Deep Scan logic)
      String currentLoc = "Unknown Location";
      try {
        // This part takes time, so the UI will show the spinner
        currentLoc = await LocationService.getCurrentLocation();
      } catch (locError) {
        currentLoc = "GPS Disabled";
      }
      
      final String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      final newRecord = Student(
        name: name, 
        studentId: studentId.trim(),
        password: "", 
        timestamp: timestamp,
        location: currentLoc,
      );

      await DatabaseHelper.instance.insertAttendance(newRecord);
      await loadAttendance();
      return true;

    } catch (e) {
      _errorMessage = "Database Error: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  Future<void> registerNewStudent(String name, String id, String pass, List<double>? faceEmbedding) async {
    _setLoading(true);
    try {
      _errorMessage = "";
      await DatabaseHelper.instance.registerStudent(name, id, pass, faceEmbedding);
      _setLoading(false);
    } catch (e) {
      if (e.toString().contains("UNIQUE constraint failed")) {
        _errorMessage = "Registration Error: ID $id already exists!";
      } else {
        _errorMessage = "Registration Error: ${e.toString()}";
      }
      _setLoading(false);
      throw Exception(_errorMessage);
    }
  }
}