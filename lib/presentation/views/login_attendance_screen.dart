import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/attendance_viewmodel.dart'; 
import 'camera_screen.dart'; 

class LoginAttendanceScreen extends StatefulWidget {
  const LoginAttendanceScreen({super.key});

  @override
  State<LoginAttendanceScreen> createState() => _LoginAttendanceScreenState();
}

class _LoginAttendanceScreenState extends State<LoginAttendanceScreen> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  /// Validates credentials before opening the camera
  Future<void> _handleVerification() async {
    final String rawId = _idController.text.trim();
    final String pass = _passController.text;

    if (rawId.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both ID and Password"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final viewModel = context.read<AttendanceViewModel>();
      
      // FIX: Sanitize the ID IMMEDIATELY. 
      // Since registration now saves IDs as 'mit_ur_1007_10', 
      // we must search for the sanitized version to match the database record.
      final String sanitizedId = rawId.replaceAll('/', '_');

      // Step 1: Verify Credentials using the sanitized ID
      bool isAuthorized = await viewModel.verifyCredentials(sanitizedId, pass);

      if (mounted) {
        if (isAuthorized) {
          // Success: Pass the SANITIZED ID to the Camera Screen for Face Recognition (Step 2)
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (_) => CameraScreen(verifiedStudentId: sanitizedId),
            ),
          );
        } else {
          _showSecurityAlertDialog(viewModel.errorMessage.isNotEmpty 
              ? viewModel.errorMessage 
              : "Invalid ID or Password. Access Denied.");
        }
      }
    } catch (e) {
      if (mounted) {
        _showSecurityAlertDialog("Connection Error: Please check your network.");
      }
    }
  }

  void _showSecurityAlertDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_update_warning_rounded, color: Colors.red, size: 30),
            SizedBox(width: 12),
            Text(
              "Access Denied", 
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("TRY AGAIN", style: TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AttendanceViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("MIT Attendance System", style: TextStyle(color: Colors.white)), 
        backgroundColor: const Color(0xFF00796B),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF00796B).withOpacity(0.1), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              const Icon(
                Icons.account_circle_rounded, 
                size: 100, 
                color: Color(0xFF00796B)
              ),
              
              const SizedBox(height: 20),
              const Text(
                "Authentication",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF002420)),
              ),
              const SizedBox(height: 10),
              const Text(
                "Step 1: Verify your account to proceed",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),

              _buildInputField(
                controller: _idController,
                label: "Student ID",
                icon: Icons.badge_rounded,
                isLoading: viewModel.isLoading,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              _buildInputField(
                controller: _passController,
                label: "Account Password",
                icon: Icons.vpn_key_rounded,
                isPassword: true,
                isLoading: viewModel.isLoading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleVerification(),
              ),
              
              const SizedBox(height: 45),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B), 
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                  ),
                  onPressed: viewModel.isLoading ? null : _handleVerification,
                  child: viewModel.isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "NEXT: SCAN FACE", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1
                        )
                      ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    required bool isLoading,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller, 
      obscureText: isPassword,
      enabled: !isLoading,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00796B)),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blueGrey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF00796B), width: 2),
        ),
      ),
    );
  }
}