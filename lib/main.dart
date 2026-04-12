import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'presentation/viewmodels/attendance_viewmodel.dart';
import 'presentation/views/dashboard_screen.dart';

void main() async {
  // 1. Initialize native bindings (Essential for SQLite and Camera)
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Wrap in a try-catch to catch any DB initialization errors on startup
  try {
    runApp(
      MultiProvider(
        providers: [
          // Providing the ViewModel at the root ensures ONE shared instance
          // for CameraScreen, Registration, and History.
          ChangeNotifierProvider(
            create: (_) => AttendanceViewModel(),
            lazy: false, // Ensures data loads even if user hasn't opened history yet
          ),
        ],
        child: const AttendanceApp(),
      ),
    );
  } catch (e) {
    debugPrint("Critical Startup Error: $e");
  }
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIT Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Using a professional MIT-inspired color palette
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF263238),
          primary: const Color(0xFF263238),
          secondary: Colors.teal,
        ),
        useMaterial3: true,
        // Global styling for buttons and cards
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      
      // Starting Screen
      home: const DashboardScreen(),
      
      // Global Routes
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
        // TIP: Add your other screens here once they are finished:
        // '/history': (context) => const AttendanceHistoryScreen(),
        // '/registration': (context) => const RegistrationScreen(),
      },
    );
  }
}