import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../viewmodels/attendance_viewmodel.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isVerifying = false;
  
  List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupCameras();
  }

  /// THE NUCLEAR FIX: Advanced camera detection for devices with non-standard IDs
  Future<void> _setupCameras() async {
    try {
      _availableCameras = await availableCameras();
      debugPrint("Total cameras detected: ${_availableCameras.length}");
      
      if (_availableCameras.isNotEmpty) {
        // 1. Try standard detection (LensDirection.front)
        int frontIndex = _availableCameras.indexWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front
        );
        
        // 2. Fallback A: Look for "1" in the name (common ID for front cameras on Android)
        if (frontIndex == -1 && _availableCameras.length > 1) {
          frontIndex = _availableCameras.indexWhere((cam) => cam.name.contains('1'));
        }

        // 3. Fallback B: If there are 2 cameras, and index 0 is back, assume index 1 is front
        if (frontIndex == -1 && _availableCameras.length > 1) {
          frontIndex = 1; 
        }
        
        // Set the index (default to 0 if all detections fail)
        _selectedCameraIndex = (frontIndex != -1) ? frontIndex : 0;
        
        _initializeCamera(_availableCameras[_selectedCameraIndex]);
      } else {
        debugPrint("No cameras found at all.");
      }
    } catch (e) {
      debugPrint("Error fetching cameras: $e");
    }
  }

  /// Robust initialization with mandatory disposal and delay
  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    // Stop image streams and dispose current controller before starting a new one
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      // Small delay to allow the OS to release the hardware lock
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.low, 
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera Initialization Error: $e");
      // If initialization fails, try to reset the state
      if (mounted) setState(() => _isCameraInitialized = false);
    }
  }

  void _toggleCamera() {
    if (_availableCameras.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Only one camera detected on this device."))
      );
      return;
    }

    setState(() {
      _isCameraInitialized = false; 
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    });
    
    _initializeCamera(_availableCameras[_selectedCameraIndex]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(_availableCameras[_selectedCameraIndex]);
    }
  }

  Future<void> _verifyAndMark() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isVerifying = true);

    try {
      final XFile image = await _controller!.takePicture();
      final viewModel = Provider.of<AttendanceViewModel>(context, listen: false);
      
      bool success = await viewModel.verifyFaceAndMarkAttendance(image.path);

      if (mounted) {
        _showStatusDialog(
          success ? "Success" : "Failed",
          success ? "Attendance marked successfully!" : "Face not recognized. Try again.",
          success ? Icons.check_circle : Icons.error,
          success ? Colors.green : Colors.red,
        );
      }
    } catch (e) {
      debugPrint("Verification Error: $e");
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _showStatusDialog(String title, String msg, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(children: [Icon(icon, color: color), const SizedBox(width: 10), Text(title)]),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mark Attendance"),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
        actions: [
          if (_availableCameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_android), 
              onPressed: _isVerifying ? null : _toggleCamera
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: (_isCameraInitialized && _controller != null)
                  ? Center(child: CameraPreview(_controller!))
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: (_isVerifying || !_isCameraInitialized) ? null : _verifyAndMark,
                icon: _isVerifying 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    ) 
                  : const Icon(Icons.face),
                label: Text(
                  _isVerifying ? "VERIFYING..." : "MARK ATTENDANCE", 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF263238),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}