import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// TRY ONE OF THESE TWO IMPORTS:
// 1. If viewmodels is inside lib:
import '../viewmodels/attendance_viewmodel.dart'; 

// 2. OR use the 'package' syntax (This is the SAFEST way):
// Replace 'attendance_app' with the name found in your pubspec.yaml
// import 'package:attendance_app/viewmodels/attendance_viewmodel.dart';

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
      // This will work once the import above is fixed
      final viewModel = context.read<AttendanceViewModel>();
      
      bool isAuthorized = await viewModel.verifyCredentials(id, pass);

      if (mounted) {
        setState(() => _isVerifying = false);

        if (isAuthorized) {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (_) => CameraScreen(verifiedStudentId: id),
            ),
          );
        } else {
          _showErrorDialog(viewModel.errorMessage);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isVerifying = false);
      _showErrorDialog("Path or Type Error: Ensure ViewModel is provided in main.dart");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Verification Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.security, size: 80, color: Color(0xFF00796B)),
            const SizedBox(height: 20),
            TextField(
              controller: _idController, 
              decoration: const InputDecoration(
                border: OutlineInputBorder(), 
                labelText: "Student ID",
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController, 
              decoration: const InputDecoration(
                border: OutlineInputBorder(), 
                labelText: "Password",
              ), 
              obscureText: true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B), 
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: _isVerifying ? null : _handleVerification,
                child: _isVerifying 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("PROCEED TO FACE SCAN", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}