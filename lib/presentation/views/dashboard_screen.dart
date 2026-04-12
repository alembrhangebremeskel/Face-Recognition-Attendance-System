import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'login_attendance_screen.dart';
import 'attendance_history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MIT Attendance System"),
        centerTitle: true,
        backgroundColor: const Color(0xFF263238), // Dark Blue Grey
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // SafeArea prevents content from being cut off by notches or system bars
      body: SafeArea(
        // SingleChildScrollView fixes the "RenderFlex overflowed" error
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                const Icon(Icons.school, size: 80, color: Color(0xFF263238)),
                const SizedBox(height: 16),
                const Text(
                  "Mekelle Institute of Technology",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Student Portal",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 48),

                // Navigation Buttons
                _buildMenuButton(
                  context,
                  title: "Student Registration",
                  subtitle: "Register new face records",
                  icon: Icons.person_add_alt_1,
                  color: Colors.blue.shade700,
                  destination: const RegistrationScreen(),
                ),
                const SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  title: "Mark Attendance",
                  subtitle: "Face scan & GPS verification",
                  icon: Icons.camera_front,
                  color: Colors.teal.shade700,
                  destination: const LoginAttendanceScreen(),
                ),
                const SizedBox(height: 20),
                _buildMenuButton(
                  context,
                  title: "Attendance History",
                  subtitle: "View logs and locations",
                  icon: Icons.assessment_outlined,
                  color: Colors.orange.shade800,
                  destination: const AttendanceHistoryScreen(),
                ),
                
                // Extra padding at the bottom to ensure the last button isn't cramped
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        ),
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 20),
              Expanded( // Added Expanded to handle long text safely
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}