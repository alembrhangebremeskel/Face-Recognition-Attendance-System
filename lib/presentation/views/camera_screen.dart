import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/attendance_viewmodel.dart';

class CameraScreen extends StatefulWidget {
  // Receive the ID that was already verified on the previous screen
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
        // Automatically select the front camera for face scanning
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
      ResolutionPreset.low,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      debugPrint("Initialization error: $e");
    }
  }

  /// DIRECT ACTION: Marks attendance using the ID passed from Identity Screen
  Future<void> _handleAttendanceMarking() async {
    setState(() => _isProcessing = true);

    try {
      final viewModel = context.read<AttendanceViewModel>();

      // Call the mark attendance logic directly using the verified ID
      bool success = await viewModel.verifyFaceAndMarkAttendance(
        name: "Verified Student", // The ViewModel will pull the real name from DB
        studentId: widget.verifiedStudentId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Attendance Marked Successfully!"),
              backgroundColor: Colors.teal,
            ),
          );
          // Return to the main home screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      debugPrint("System Error: $e");
      if (mounted) setState(() => _isProcessing = false);
    }
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
      appBar: AppBar(
        title: const Text("Face Scan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && _controller != null)
            SizedBox.expand(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator()),

          // Verified ID Indicator (Top)
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
                "Scanning for ID: ${widget.verifiedStudentId}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Action Button (Bottom)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: SizedBox(
                width: 250,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: (_isCameraInitialized && !_isProcessing) 
                      ? _handleAttendanceMarking 
                      : null,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "MARK ATTENDANCE",
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