import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/student_model.dart';
import '../../data/services/location_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  List<Student> _records = [];
  String _errorMessage = ""; 
  bool _isLoading = false;

  List<Student> get records => _records;
  String get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  AttendanceViewModel() {
    loadAttendance();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Helper to normalize embeddings (Reduces distance errors)
  List<double> _normalize(List<double> embedding) {
    double sum = 0;
    for (var v in embedding) sum += v * v;
    double magnitude = sqrt(sum);
    if (magnitude == 0) return embedding;
    return embedding.map((v) => v / magnitude).toList();
  }

  Future<void> loadAttendance() async {
    try {
      final data = await DatabaseHelper.instance.getAllAttendance();
      _records = List.from(data);
      notifyListeners(); 
    } catch (e) {
      debugPrint("Error loading local attendance: $e");
    }
  }

  Future<bool> verifyCredentials(String studentId, String password) async {
    _setLoading(true);
    try {
      _errorMessage = "";
      bool isValid = await DatabaseHelper.instance.verifyPassword(studentId, password);
      
      _setLoading(false);
      if (!isValid) {
        _errorMessage = "Invalid ID or Password.";
        return false;
      }
      return true;
    } catch (e) {
      _errorMessage = "Verification Error: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  /// --- STEP 2: PROFESSIONAL FACE VERIFICATION (UPDATED THRESHOLD) ---
  Future<bool> verifyFaceAndMarkAttendance({
    required String studentId,
    required List<double> liveEmbedding,
  }) async {
    _setLoading(true);
    try {
      _errorMessage = ""; 

      var studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get()
          .timeout(const Duration(seconds: 10));
      
      if (!studentDoc.exists) {
        _errorMessage = "Identity not found in Cloud Database.";
        _setLoading(false);
        return false;
      }

      List<dynamic> savedData = studentDoc.data()?['face_embedding'] ?? [];
      if (savedData.isEmpty) {
        _errorMessage = "No face data found for this student.";
        _setLoading(false);
        return false;
      }
      
      // CRITICAL FIX: The Type Mismatch Fix
      List<double> registeredEmbedding = savedData.map((e) => double.parse(e.toString())).toList();

      // Normalize both for better accuracy across different lighting conditions
      List<double> normLive = _normalize(liveEmbedding);
      List<double> normSaved = _normalize(registeredEmbedding);

      // 3. MATH: Calculate Euclidean Distance
      double distance = 0;
      for (int i = 0; i < normLive.length; i++) {
        distance += pow((normLive[i] - normSaved[i]), 2);
      }
      distance = sqrt(distance);

      debugPrint("📊 Final Calculated Distance for $studentId: $distance");

      // 4. Threshold Check (MODIFIED)
      // Your previous value was 0.75. 
      // Based on your tests, 1.10 is the "Sweet Spot" for your device.
      const double recognitionThreshold = 1.10;

      if (distance < recognitionThreshold) {
        bool result = await markAttendance(studentDoc.data()?['name'] ?? "Unknown", studentId);
        _setLoading(false);
        return result;
      } else {
        // We show the distance in the error message to help you calibrate
        _errorMessage = "Face not recognized (Distance: ${distance.toStringAsFixed(2)})";
        _setLoading(false);
        return false;
      }
      
    } on TimeoutException {
      _errorMessage = "Cloud connection timeout. Check internet.";
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = "Recognition Error: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  Future<bool> markAttendance(String name, String studentId) async {
    try {
      String currentLoc = "Unknown Location";
      try {
        currentLoc = await LocationService.getCurrentLocation();
      } catch (e) {
        currentLoc = "GPS Disabled";
      }
      
      final DateTime now = DateTime.now();
      final String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      final newRecord = Student(
        name: name, 
        studentId: studentId.trim(),
        password: "", 
        timestamp: timestamp,
        location: currentLoc,
      );
      
      await DatabaseHelper.instance.insertAttendance(newRecord);

      _firestore.collection('attendance_logs').add({
        'student_id': studentId,
        'student_name': name,
        'timestamp': FieldValue.serverTimestamp(),
        'location': currentLoc,
        'status': 'Present',
      }).catchError((e) => debugPrint("Background Sync Failed: $e"));

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
    _errorMessage = "";
    
    try {
      // Normalize before saving to ensure data consistency
      List<double>? normalizedEmbedding = faceEmbedding != null ? _normalize(faceEmbedding) : null;

      await DatabaseHelper.instance.registerStudent(name, id, pass, normalizedEmbedding);

      try {
        await _firestore.collection('students').doc(id).set({
          'name': name,
          'student_id': id,
          'face_embedding': normalizedEmbedding, 
          'created_at': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 12));
      } catch (cloudError) {
        debugPrint("Cloud Registration Error: $cloudError");
      }

    } on Exception catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      rethrow; 
    } finally {
      _setLoading(false);
    }
  }
}