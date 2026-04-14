import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'presentation/viewmodels/attendance_viewmodel.dart';
import 'presentation/views/dashboard_screen.dart';
// Import your service to load the model here
import 'data/services/face_recognition_service.dart'; 

void main() async {
  // 1. Ensure native bindings are ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase Initialized");
  } catch (e) {
    debugPrint("❌ Firebase Initialization Error: $e");
  }

  // 3. Pre-load the TFLite Model
  // This prevents the app from lagging when the camera starts
  final faceService = FaceRecognitionService();
  await faceService.initializeModel();

  // 4. Run the App
  runApp(
    MultiProvider(
      providers: [
        // Provide the service instance so other parts of the app can use it
        Provider<FaceRecognitionService>.value(value: faceService),
        
        ChangeNotifierProvider(
          create: (_) => AttendanceViewModel(),
          lazy: false, 
        ),
      ],
      child: const AttendanceApp(),
    ),
  );
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIT Attendance System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF263238),
          primary: const Color(0xFF263238),
          secondary: Colors.teal,
        ),
        useMaterial3: true,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const DashboardScreen(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}