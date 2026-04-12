import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/attendance_viewmodel.dart';
import 'camera_screen.dart'; // Ensure this points to your CameraScreen file

class VerifyIdentityScreen extends StatefulWidget {
  const VerifyIdentityScreen({super.key});

  @override
  State<VerifyIdentityScreen> createState() => _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends State<VerifyIdentityScreen> {
  // 1. Controllers to capture the input from the text fields
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  /// THE GATEKEEPER LOGIC
  /// This runs when the user clicks "PROCEED TO FACE SCAN"
  Future<void> _handleProceed() async {
    final String studentId = _idController.text.trim();
    final String password = _passController.text;

    // Basic check for empty fields
    if (studentId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both ID and Password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final viewModel = context.read<AttendanceViewModel>();

      // 2. DATABASE CHECK: We check the registration BEFORE opening the camera
      bool isAuthorized = await viewModel.verifyCredentials(studentId, password);

      if (mounted) {
        setState(() => _isLoading = false);

        if (isAuthorized) {
          // 3. SUCCESS: Move to the camera and pass the verified ID
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CameraScreen(verifiedStudentId: studentId),
            ),
          );
        } else {
          // 4. FAILURE: Show error and stop the user here
          _showErrorDialog(viewModel.errorMessage);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showErrorDialog("System Error: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Access Denied"),
          ],
        ),
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
            const Icon(Icons.shield, size: 80, color: Color(0xFF00796B)),
            const SizedBox(height: 24),
            const Text(
              "Identity Verification",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // ID Field
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: "Student ID",
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Password Field
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),

            // PROCEED BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleProceed,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "PROCEED TO FACE SCAN",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}