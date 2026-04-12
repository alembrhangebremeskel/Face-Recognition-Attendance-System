import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceRecognitionService {
  // Initialize the Face Detector with accurate mode for your senior thesis
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // Detects faces in an image
  Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  // MATHEMATICAL COMPARISON (Euclidean Distance)
  // Used to compare the 'Live' face against the 'Registered' face
  double compareFaces(List<double> registeredFace, List<double> liveFace) {
    if (registeredFace.length != liveFace.length) return 1.0; // Fail if sizes mismatch

    double sum = 0.0;
    for (int i = 0; i < registeredFace.length; i++) {
      sum += pow(registeredFace[i] - liveFace[i], 2);
    }
    
    // Distance < 0.6 usually means it's the same person
    return sqrt(sum);
  }

  void dispose() {
    _faceDetector.close();
  }
}