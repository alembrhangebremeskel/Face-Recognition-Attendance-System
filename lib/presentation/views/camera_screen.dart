import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'; 
import '../viewmodels/attendance_viewmodel.dart';
import '../../data/services/face_recognition_service.dart';

class CameraScreen extends StatefulWidget {
  final String verifiedStudentId;

  const CameraScreen({super.key, required this.verifiedStudentId});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  late FaceRecognitionService _faceService;
  late FaceDetector _faceDetector; 
  bool _isCameraInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _faceService = FaceRecognitionService();
    
    // FIXED: Corrected FaceDetectorOptions and assigned to _faceDetector
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    
    WidgetsBinding.instance.addObserver(this);
    _initializeResources();
  }

  Future<void> _initializeResources() async {
    try {
      await _faceService.initializeModel();

      final availableCams = await availableCameras();
      if (availableCams.isNotEmpty) {
        final frontCamera = availableCams.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => availableCams.first,
        );

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.low, 
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
        if (mounted) setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Initialization Error: $e");
    }
  }

  Future<void> _handleAttendanceMarking() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final viewModel = context.read<AttendanceViewModel>();

      // 1. Take Picture
      final XFile photo = await _controller!.takePicture();
      
      // 2. Detect Face using ML Kit
      final inputImage = InputImage.fromFilePath(photo.path);
      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        throw Exception("No face detected. Please center your face in the circle.");
      }

      // 3. Crop the Face
      final bytes = await photo.readAsBytes();
      img.Image? fullImg = img.decodeImage(bytes);
      
      if (fullImg == null) throw Exception("Could not decode image");

      Face face = faces[0];
      Rect rect = face.boundingBox;

      img.Image faceCrop = img.copyCrop(
        fullImg,
        x: rect.left.toInt(),
        y: rect.top.toInt(),
        width: rect.width.toInt(),
        height: rect.height.toInt(),
      );

      // 4. Generate Embeddings
      List<double> liveEmbedding = _faceService.getEmbeddings(faceCrop);

      // 5. Verification
      bool success = await viewModel.verifyFaceAndMarkAttendance(
        studentId: widget.verifiedStudentId,
        liveEmbedding: liveEmbedding,
      );

      if (mounted) {
        if (success) {
          _showSuccessToast();
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          _showSecurityAlert(viewModel.errorMessage);
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      debugPrint("Recognition Error: $e");
      if (mounted) {
        _showSecurityAlert(e.toString().replaceAll("Exception: ", ""));
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Identity Verified! Attendance Marked."),
        backgroundColor: Color(0xFF00796B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
            Text("Verification Failed", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B)),
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
    _faceService.dispose();
    _faceDetector.close(); 
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeResources();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Face Recognition Scan", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00796B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          if (_isCameraInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.tealAccent)),

          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessing ? Colors.orange : Colors.tealAccent, 
                  width: 3
                ),
                shape: BoxShape.circle,
              ),
              child: _isProcessing 
                ? const CircularProgressIndicator(color: Colors.orange, strokeWidth: 4)
                : const SizedBox.shrink(),
            ),
          ),

          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Student ID: ${widget.verifiedStudentId}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: SizedBox(
                width: 260,
                height: 65,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.face_retouching_natural, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                    elevation: 10,
                  ),
                  onPressed: (_isCameraInitialized && !_isProcessing) 
                      ? _handleAttendanceMarking 
                      : null,
                  label: Text(
                    _isProcessing ? "ANALYZING..." : "VERIFY IDENTITY",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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