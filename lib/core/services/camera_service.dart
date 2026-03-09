import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  // Getters
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  List<CameraDescription> get cameras => _cameras;

  // Initialize the camera service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Get available cameras
      _cameras = await availableCameras();
      debugPrint('Found ${_cameras.length} cameras');

      if (_cameras.isNotEmpty) {
        // Initialize the first camera (usually the rear camera)
        await _initializeCamera(_cameras.first);
      } else {
        debugPrint('No cameras found');
      }
    } catch (e) {
      debugPrint('Error initializing camera service: $e');
      // On Windows, fall back to image picker if camera is not available
      if (Platform.isWindows) {
        debugPrint('On Windows, camera may not be available. Will use image picker as fallback.');
      }
    }
  }

  // Initialize a specific camera
  Future<void> _initializeCamera(CameraDescription camera) async {
    try {
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _controller?.initialize();
      _isInitialized = true;
      debugPrint('Camera initialized successfully');
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isInitialized = false;
    }
  }

  // Switch to a different camera
  Future<void> switchCamera(int cameraIndex) async {
    if (cameraIndex < 0 || cameraIndex >= _cameras.length) {
      throw Exception('Invalid camera index');
    }

    try {
      // Dispose of the current controller
      await _controller?.dispose();

      // Initialize the new camera
      await _initializeCamera(_cameras[cameraIndex]);
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  // Take a picture - with Windows fallback
  Future<String?> takePicture() async {
    // On Windows, use image picker as camera might not be available
    if (Platform.isWindows) {
      return _pickImageFromCamera();
    }

    if (!_isInitialized || _controller == null) {
      throw Exception('Camera is not initialized');
    }

    try {
      // Ensure the camera is initialized
      if (!_controller!.value.isInitialized) {
        await _controller!.initialize();
      }

      // Prepare for capture
      if (_controller!.value.isTakingPicture) {
        // A capture is already in progress
        return null;
      }

      // Take the picture
      final XFile file = await _controller!.takePicture();
      
      // Return the file path
      return file.path;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  // Fallback method for Windows to pick image from camera using image_picker
  Future<String?> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      
      if (photo != null) {
        return photo.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera (Windows fallback): $e');
      return null;
    }
  }

  // Pick image from gallery (for both platforms)
  Future<String?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  // Record a video (start)
  Future<void> startVideoRecording() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera is not initialized');
    }

    try {
      if (_controller!.value.isRecordingVideo) {
        // Already recording
        return;
      }

      await _controller!.startVideoRecording();
    } catch (e) {
      debugPrint('Error starting video recording: $e');
    }
  }

  // Stop video recording
  Future<String?> stopVideoRecording() async {
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera is not initialized');
    }

    try {
      if (!_controller!.value.isRecordingVideo) {
        // Not recording
        return null;
      }

      final XFile file = await _controller!.stopVideoRecording();
      return file.path;
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      return null;
    }
  }

  // Dispose of the camera controller
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  // Process image (resize, compress, etc.)
  Future<String?> processImage(String imagePath, {int maxWidth = 1920, int quality = 80}) async {
    try {
      // Read the image file
      final imageBytes = await File(imagePath).readAsBytes();
      
      // Decode the image
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        debugPrint('Failed to decode image');
        return null;
      }
      
      // Resize the image if needed
      img.Image resizedImage;
      if (image.width > maxWidth) {
        final ratio = maxWidth / image.width;
        final newHeight = (image.height * ratio).round();
        resizedImage = img.copyResize(image, width: maxWidth, height: newHeight);
      } else {
        resizedImage = image;
      }
      
      // Encode as JPEG with specified quality
      final processedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      // Save to a new file
      final originalFile = File(imagePath);
      final directory = originalFile.parent;
      final fileName = originalFile.path.split('/').last.split('.').first;
      final processedPath = '${directory.path}/${fileName}_processed.jpg';
      
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(processedBytes);
      
      return processedPath;
    } catch (e) {
      debugPrint('Error processing image: $e');
      return null;
    }
  }
}