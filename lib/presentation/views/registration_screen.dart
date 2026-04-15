import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'; 
import '../viewmodels/attendance_viewmodel.dart';
import '../../data/services/face_recognition_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  
  CameraController? _controller;
  late FaceRecognitionService _faceService; 
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 1; 

  List<double>? _faceEmbedding; 
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _faceService = FaceRecognitionService();
    WidgetsBinding.instance.addObserver(this);
    _initializeResources();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _faceService.dispose(); 
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeResources();
    }
  }

  Future<void> _initializeResources() async {
    try {
      await _faceService.initializeModel(); 
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras[_selectedCameraIndex],
        ResolutionPreset.low, 
        enableAudio: false,
      );

      await _controller!.initialize();
      await _controller!.lockCaptureOrientation(); 

      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Setup error: $e");
    }
  }

  void _switchCamera() {
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    });
    _initializeResources();
  }

  Future<void> _captureFace() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final XFile imageFile = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await _faceService.detectFaces(inputImage);

      if (faces.isEmpty) {
        throw Exception("No face detected. Please face the camera clearly.");
      }

      final bytes = await imageFile.readAsBytes();
      img.Image? fullImg = img.decodeImage(bytes);

      if (fullImg != null) {
        Face face = faces[0];
        Rect rect = face.boundingBox;

        img.Image faceCrop = img.copyCrop(
          fullImg,
          x: rect.left.toInt(),
          y: rect.top.toInt(),
          width: rect.width.toInt(),
          height: rect.height.toInt(),
        );

        final embedding = _faceService.getEmbeddings(faceCrop);
        
        if (embedding.isEmpty) {
          throw Exception("AI model failed to generate data.");
        }

        setState(() {
          _faceEmbedding = embedding; 
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Face Captured Successfully!"),
              backgroundColor: Colors.teal,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_faceEmbedding == null || _faceEmbedding!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please scan your face first!"), backgroundColor: Colors.redAccent),
        );
        return;
      }

      setState(() => _isProcessing = true);
      
      try {
        final viewModel = Provider.of<AttendanceViewModel>(context, listen: false);
        
        // FIX: Sanitize ID by replacing '/' with '_' to prevent Firestore segment errors
        final studentId = _idController.text.trim().replaceAll('/', '_');

        await viewModel.registerNewStudent(
          _nameController.text.trim(),
          studentId,
          _passwordController.text.trim(),
          _faceEmbedding, 
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration Successful!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        String errorMessage = "Failed to register student.";
        if (e.toString().contains("UNIQUE constraint failed")) {
          errorMessage = "Student ID already exists!";
        } else {
          errorMessage = e.toString().replaceAll("Exception: ", "");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Registration", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF00796B),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 320, width: double.infinity, color: Colors.black,
                  child: (_isCameraInitialized && _controller != null)
                      ? Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            CameraPreview(_controller!),
                            Center(
                              child: Container(
                                width: 220, height: 220,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _faceEmbedding == null ? Colors.white54 : Colors.tealAccent, 
                                    width: 3
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10, right: 10,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: IconButton(
                                  icon: const Icon(Icons.flip_camera_android, color: Colors.white),
                                  onPressed: _switchCamera,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _captureFace,
                                icon: _isProcessing 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal))
                                  : Icon(_faceEmbedding == null ? Icons.face : Icons.check_circle),
                                label: Text(_faceEmbedding == null ? "SCAN FACE" : "RE-SCAN FACE"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _faceEmbedding == null ? Colors.white : Colors.tealAccent.shade700,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.teal)),
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(_nameController, "Full Name", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_idController, "Student ID", Icons.badge_outlined),
              const SizedBox(height: 15),
              _buildTextField(
                _passwordController, 
                "System Password", 
                Icons.lock_outline, 
                obscure: true, 
                validator: _validatePassword,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: (_isProcessing || _faceEmbedding == null) ? null : _handleRegister,
                  child: _isProcessing 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("COMPLETE REGISTRATION", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00796B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF00796B), width: 2), borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator ?? (value) => value!.isEmpty ? "This field is required" : null,
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 6) return "Min 6 characters";
    return null;
  }
}