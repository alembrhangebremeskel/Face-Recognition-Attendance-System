import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../viewmodels/attendance_viewmodel.dart';

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
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 1; 

  List<double>? _faceEmbedding; 
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  void _switchCamera() {
    setState(() {
      _isCameraInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    });
    _initializeCamera();
  }

  Future<void> _captureFace() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile image = await _controller!.takePicture();
      setState(() {
        _faceEmbedding = List.generate(128, (index) => 0.5); 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Face Captured Successfully!")),
      );
    } catch (e) {
      debugPrint("Capture error: $e");
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 8) return "Must be at least 8 characters";
    
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);

    if (!hasLetter || !hasNumber) {
      return "Must contain both letters and numbers";
    }
    return null;
  }

  // --- UPDATED: HANDLE REGISTER WITH DUPLICATE CHECK ---
  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_faceEmbedding == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please capture face data before saving!"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() => _isProcessing = true);
      
      try {
        final viewModel = Provider.of<AttendanceViewModel>(context, listen: false);
        
        await viewModel.registerNewStudent(
          _nameController.text.trim(),
          _idController.text.trim(),
          _passwordController.text.trim(),
          _faceEmbedding, 
        );

        // If successful, show success message and go back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Student Registered Successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        // --- DUPLICATE ID HANDLING ---
        String errorMsg = e.toString();
        String userFriendlyError = "An error occurred during registration.";

        if (errorMsg.contains("UNIQUE constraint failed") || errorMsg.contains("already registered")) {
          userFriendlyError = "This Student ID is already registered!";
        } else if (errorMsg.contains("Password")) {
          userFriendlyError = "Registration failed: Password does not meet requirements.";
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userFriendlyError),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
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
        title: const Text("New Student Registration"),
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 250, width: double.infinity, color: Colors.black,
                  child: (_isCameraInitialized && _controller != null)
                      ? Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            CameraPreview(_controller!),
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
                              padding: const EdgeInsets.only(bottom: 10),
                              child: ElevatedButton.icon(
                                onPressed: _captureFace,
                                icon: Icon(_faceEmbedding == null ? Icons.camera_alt : Icons.check),
                                label: Text(_faceEmbedding == null ? "CAPTURE" : "RETAKE"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _faceEmbedding == null ? Colors.white : Colors.teal,
                                  foregroundColor: _faceEmbedding == null ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
              
              _buildTextField(_nameController, "Full Name", Icons.person),
              const SizedBox(height: 20),
              _buildTextField(_idController, "Student ID", Icons.badge),
              const SizedBox(height: 20),
              
              _buildTextField(
                _passwordController, 
                "System Password", 
                Icons.lock, 
                obscure: true, 
                validator: _validatePassword,
                helperText: "Min. 8 characters with letters & numbers",
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isProcessing ? null : _handleRegister,
                  child: _isProcessing 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE REGISTRATION", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {bool obscure = false, String? Function(String?)? validator, String? helperText}
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator ?? (value) => value!.isEmpty ? "Required" : null,
    );
  }
}