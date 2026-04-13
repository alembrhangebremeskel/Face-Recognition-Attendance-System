import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// IMPORTANT: Replace 'attendance_app' with the 'name' from your pubspec.yaml file
// This is the most reliable way to fix the "path not specified" error.
import 'package:attendance_app/presentation/viewmodels/attendance_viewmodel.dart';
import 'camera_screen.dart'; 

class LoginAttendanceScreen extends StatefulWidget {
  const LoginAttendanceScreen({super.key});

  @override
  State<LoginAttendanceScreen> createState() => _LoginAttendanceScreenState();
}

class _LoginAttendanceScreenState extends State<LoginAttendanceScreen> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  bool _isVerifying = false; 

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleVerification() async {
    final String id = _idController.text.trim();
    final String pass = _passController.text;

    if (id.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both ID and Password")),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      // Accessing the ViewModel via Provider
      final viewModel = context.read<AttendanceViewModel>();
      
      bool isAuthorized = await viewModel.verifyCredentials(id, pass);

      if (mounted) {
        setState(() => _isVerifying = false);

        if (isAuthorized) {
          // Success: Navigate to Face Scan
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (_) => CameraScreen(verifiedStudentId: id),
            ),
          );
        } else {
          // Failure: Show the Security Alert
          _showSecurityAlertDialog(viewModel.errorMessage);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isVerifying = false);
      _showSecurityAlertDialog("Initialization Error: Check if AttendanceViewModel is provided in main.dart");
    }
  }

  /// THE "STOP" LOGIC: Specialized Security Alert Dialog
  void _showSecurityAlertDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad_outlined, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text(
              "Security Alert", 
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Identity"), 
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            
            /// POLISHED: Modern Face Scanner Icon for your IT Project
            const Icon(
              Icons.face_retouching_natural_rounded, 
              size: 100, 
              color: Color(0xFF00796B)
            ),
            
            const SizedBox(height: 20),
            const Text(
              "Identity Authentication",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Step 1: Enter Registered Credentials",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 35),

            /// ID Input
            TextField(
              controller: _idController, 
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF00796B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                labelText: "Student ID",
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// Password Input
            TextField(
              controller: _passController, 
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_person_outlined, color: Color(0xFF00796B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
                labelText: "Password",
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
                ),
              ), 
            ),
            
            const SizedBox(height: 45),
            
            /// PROCEED BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B), 
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isVerifying ? null : _handleVerification,
                child: _isVerifying 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "PROCEED TO FACE SCAN", 
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2
                      )
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}