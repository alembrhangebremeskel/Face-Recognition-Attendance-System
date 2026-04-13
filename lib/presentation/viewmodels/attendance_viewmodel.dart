import 'dart:convert';
import 'dart:math'; // Required for sqrt and pow
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
    try {
      _errorMessage = "";
      bool isValid = await DatabaseHelper.instance.verifyPassword(studentId, password);
      
      if (!isValid) {
        _errorMessage = "Invalid ID or Password. Access Denied.";
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      _errorMessage = "Verification System Error: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  /// --- STEP 3: TRUE FACE RECOGNITION LOGIC ---
  /// This compares the live embedding against the registered one in SQLite.
  Future<bool> verifyFaceAndMarkAttendance({
    required String studentId,
    required List<double> liveEmbedding, // The numbers from the camera
  }) async {
    try {
      _errorMessage = ""; 
      
      // 1. Fetch registered student data (which contains their saved face_data)
      final studentData = await DatabaseHelper.instance.getStudentForVerification(studentId);
      
      if (studentData == null) {
        _errorMessage = "Security Alert: ID $studentId not found in records.";
        notifyListeners();
        return false;
      }

      // 2. Extract and decode the registered embedding
      // face_data is stored as a JSON string in SQLite
      List<double> registeredEmbedding = List<double>.from(
        jsonDecode(studentData['face_data'])
      );

      // 3. MATH: Calculate Euclidean Distance
      double distance = 0;
      for (int i = 0; i < liveEmbedding.length; i++) {
        distance += pow((liveEmbedding[i] - registeredEmbedding[i]), 2);
      }
      distance = sqrt(distance);

      debugPrint("Final Face Distance for $studentId: $distance");

      // 4. THE SECURITY THRESHOLD
      // 0.6 is the standard threshold. Lower is more secure.
      if (distance < 0.6) {
        // MATCH FOUND: Proceed to save attendance
        return await markAttendance(studentData['name'], studentId);
      } else {
        // SECURITY ALERT: The error message you requested
        _errorMessage = "Security Alert: Scanned face does not match the registered profile! Access Denied.";
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      _errorMessage = "Recognition Error: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  /// Final Step: Saving the Attendance Record
  Future<bool> markAttendance(String name, String studentId) async {
    try {
      _errorMessage = "";

      // 1. Get GPS Location
      String currentLoc = "Unknown Location";
      try {
        currentLoc = await LocationService.getCurrentLocation();
      } catch (locError) {
        currentLoc = "GPS Disabled";
      }
      
      // 2. Generate Timestamp
      final String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // 3. Create record
      final newRecord = Student(
        name: name, 
        studentId: studentId.trim(),
        password: "", 
        timestamp: timestamp,
        location: currentLoc,
      );

      // 4. Save to SQLite
      await DatabaseHelper.instance.insertAttendance(newRecord);
      
      // 5. HYBRID SYNC: Push to Firebase Firestore (Optional logic here)
      // await DatabaseHelper.instance.syncToCloud(newRecord); 
      
      await loadAttendance();
      return true;

    } catch (e) {
      _errorMessage = "Database Error: ${e.toString()}";
      notifyListeners();
      return false;
    }
  }

  Future<void> registerNewStudent(String name, String id, String pass, List<double>? faceEmbedding) async {
    try {
      _errorMessage = "";
      await DatabaseHelper.instance.registerStudent(name, id, pass, faceEmbedding);
      notifyListeners(); 
    } catch (e) {
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