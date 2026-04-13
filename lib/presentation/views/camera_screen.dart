import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/attendance_viewmodel.dart';

class CameraScreen extends StatefulWidget {
  final String verifiedStudentId;

  const CameraScreen({super.key, required this.verifiedStudentId});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameras();
  }

  Future<void> _setupCameras() async {
    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isNotEmpty) {
        int frontIndex = _availableCameras.indexWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front
        );
        _initializeCamera(_availableCameras[frontIndex != -1 ? frontIndex : 0]);
      }
    } catch (e) {
      debugPrint("Camera setup error: $e");
    }
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    if (_controller != null) await _controller!.dispose();

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium, // Increased for better face recognition accuracy
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Initialization error: $e");
    }
  }

  /// THE SECURITY GATE: Compares face and marks attendance
  Future<void> _handleAttendanceMarking() async {
    setState(() => _isProcessing = true);

    try {
      final viewModel = context.read<AttendanceViewModel>();

      // 1. Capture the "Live" frame from the camera
      // Note: In a production TFLite app, you would pass the actual image bytes here.
      // For your current setup, we are calling the verification logic.
      bool success = await viewModel.verifyFaceAndMarkAttendance(
        studentId: widget.verifiedStudentId,
        liveEmbedding: [0.1, 0.2, 0.3], // Replace with actual TFLite output
      );

      if (mounted) {
        if (success) {
          // SUCCESS: Show green confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Attendance Marked Successfully!"),
              backgroundColor: Color(0xFF00796B),
            ),
          );
          // Return to home screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // FAILURE: Show the Security Alert Dialog (The "Stop" Logic)
          _showSecurityAlert(viewModel.errorMessage);
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      debugPrint("System Error: $e");
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// EXCLUSIVE: Security Alert Dialog for Identity Mismatch
  void _showSecurityAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad_outlined, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Security Alert", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Face Recognition Scan"),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Camera Preview
          if (_isCameraInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 2. Face Guide Overlay (Visual Polish for IT Projects)
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.tealAccent, width: 2),
                borderRadius: BorderRadius.circular(150),
              ),
            ),
          ),

          // 3. Status Indicator
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "ID: ${widget.verifiedStudentId} (Verifying...)",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 4. Verification Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: SizedBox(
                width: 250,
                height: 60,
                child: ElevatedButton.icon(
                  icon: _isProcessing 
                      ? const SizedBox.shrink() 
                      : const Icon(Icons.face, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  onPressed: (_isCameraInitialized && !_isProcessing) 
                      ? _handleAttendanceMarking 
                      : null,
                  label: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "VERIFY & MARK",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}