import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart'; // Added for debugPrint
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  Interpreter? _interpreter;
  
  // OPTIMIZED: Using 'fast' mode for better performance on mobile hardware
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: false, 
      performanceMode: FaceDetectorMode.fast, 
      enableTracking: true,
    ),
  );

  /// --- INITIALIZATION ---
  Future<void> initializeModel() async {
    if (_interpreter != null) return; 

    try {
      final options = InterpreterOptions();
      
      if (Platform.isAndroid) {
        options.addDelegate(XNNPackDelegate());
      }

      _interpreter = await Interpreter.fromAsset(
        'assets/mobilefacenet.tflite', 
        options: options,
      );
      debugPrint("✅ TFLite Model Loaded Successfully");
    } catch (e) {
      debugPrint("❌ Error loading TFLite model: $e");
      _interpreter = null;
    }
  }

  /// --- STEP 1: DETECTION ---
  Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  /// --- STEP 2: EMBEDDING GENERATION ---
  List<double> getEmbeddings(img.Image faceImage) {
    if (_interpreter == null) {
      debugPrint("⚠️ Interpreter not ready");
      return [];
    }

    try {
      img.Image resizedImage = img.copyResize(faceImage, width: 112, height: 112);
      var input = _imageToByteListFloat32(resizedImage);
      var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

      _interpreter!.run(input, output);
      
      return List<double>.from(output[0]);
    } catch (e) {
      debugPrint("❌ Inference Error: $e");
      return [];
    }
  }

  /// --- STEP 3: COMPARISON (UPDATED) ---
  /// Calculates the Euclidean distance between two faces
  double compareFaces(List<dynamic> registeredFace, List<dynamic> liveFace) {
    if (registeredFace.isEmpty || liveFace.isEmpty) return 10.0; // Return high distance if empty
    if (registeredFace.length != liveFace.length) return 10.0; 

    double sum = 0.0;
    for (int i = 0; i < registeredFace.length; i++) {
      sum += pow(registeredFace[i] - liveFace[i], 2);
    }
    double distance = sqrt(sum);
    
    // This will show in your VS Code terminal so you can see the math in real-time
    debugPrint("📊 Face Recognition Distance: $distance");
    
    return distance;
  }

  /// HELPER: Checks if the face is a match based on a threshold
  bool isSameFace(List<dynamic> registeredFace, List<dynamic> liveFace) {
    double distance = compareFaces(registeredFace, liveFace);
    
    // --- THE THRESHOLD ADJUSTMENT ---
    // 0.7 - 0.8 is very strict (good for high-end iPhones)
    // 1.0 - 1.1 is recommended for TECNO/Android mid-range devices
    const double threshold = 1.1; 
    
    return distance < threshold;
  }

  /// --- STEP 4: OPTIMIZED BYTE CONVERSION ---
  Uint8List _imageToByteListFloat32(img.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var y = 0; y < 112; y++) {
      for (var x = 0; x < 112; x++) {
        var pixel = image.getPixel(x, y);
        
        buffer[pixelIndex++] = (pixel.r - 128) / 128.0;
        buffer[pixelIndex++] = (pixel.g - 128) / 128.0;
        buffer[pixelIndex++] = (pixel.b - 128) / 128.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }
}