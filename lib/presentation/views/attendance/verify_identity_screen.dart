import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import 'camera_screen.dart'; 

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  /// THE GATEKEEPER LOGIC (ID & Password Phase)
  Future<void> _handleProceed() async {
    final String studentId = _idController.text.trim();
    final String password = _passController.text;

    if (studentId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both ID and Password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final viewModel = context.read<AttendanceViewModel>();
      bool isAuthorized = await viewModel.verifyCredentials(studentId, password);

      if (mounted) {
        setState(() => _isLoading = false);

        if (isAuthorized) {
          // SUCCESS: Move to the camera screen for the Face Scan phase
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(verifiedStudentId: studentId),
            ),
          );
        } else {
          // FAILURE: Show the Security Alert for invalid credentials
          _showSecurityAlertDialog(viewModel.errorMessage);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSecurityAlertDialog("System Error: $e");
    }
  }

  /// THE "STOP" LOGIC: The Security Alert Dialog
  /// You can use this same logic in your CameraScreen if the face doesn't match!
  void _showSecurityAlertDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by clicking outside
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
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text("TRY AGAIN", style: TextStyle(color: Colors.white)),
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
            // UPDATED: Professional Scanner Icon instead of generic shield
            const Icon(
              Icons.camera_front_outlined, 
              size: 100, 
              color: Color(0xFF00796B)
            ),
            const SizedBox(height: 20),
            const Text(
              "Identity Check",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Step 1: Authenticate Credentials",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: "Student ID",
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF00796B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00796B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _handleProceed,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "PROCEED TO FACE SCAN",
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}