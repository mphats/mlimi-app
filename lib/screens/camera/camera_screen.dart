import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/services/camera_service.dart';
import '../../core/constants/app_colors.dart';

class CameraScreen extends StatefulWidget {
  final Function(String)? onImageCaptured;
  
  const CameraScreen({super.key, this.onImageCaptured});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin {
  late CameraService _cameraService;
  bool _isCameraInitialized = false;
  bool _isTakingPicture = false;
  XFile? _capturedImage;
  int _selectedCamera = 0;
  late AnimationController _flashAnimationController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _initializeCamera();
    
    // Initialize flash animation
    _flashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_flashAnimationController);
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = _cameraService.isInitialized;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing camera: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _flashAnimationController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized && !Platform.isWindows) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      String? imagePath;
      
      // On Windows, use image picker as fallback
      if (Platform.isWindows) {
        imagePath = await _cameraService.takePicture();
      } else {
        // Play flash animation for native camera
        _flashAnimationController.forward().then((_) {
          _flashAnimationController.reverse();
        });

        // Take the picture using camera plugin
        imagePath = await _cameraService.takePicture();
      }
      
      if (imagePath != null && mounted) {
        setState(() {
          _capturedImage = XFile(imagePath!);
        });

        // Process the image (resize/compress)
        final processedImagePath = await _cameraService.processImage(imagePath);
        
        // Notify the parent widget if callback is provided
        if (widget.onImageCaptured != null && processedImagePath != null) {
          widget.onImageCaptured!(processedImagePath);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    // On Windows, camera switching is not available
    if (Platform.isWindows) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera switching not available on Windows'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }
    
    try {
      final nextCameraIndex = (_selectedCamera + 1) % _cameraService.cameras.length;
      await _cameraService.switchCamera(nextCameraIndex);
      if (mounted) {
        setState(() {
          _selectedCamera = nextCameraIndex;
          _isCameraInitialized = _cameraService.isInitialized;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching camera: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview or captured image
          _buildCameraView(),
          
          // Flash overlay (only for non-Windows platforms)
          if (!Platform.isWindows) _buildFlashOverlay(),
          
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    // On Windows, show a simplified interface
    if (Platform.isWindows) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 100, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(height: 20),
            const Text(
              'Camera Preview',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Click the capture button to take a photo',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_capturedImage != null) {
      return Center(
        child: Image.file(
          File(_capturedImage!.path),
          fit: BoxFit.contain,
        ),
      );
    }

    // Camera preview
    return CameraPreview(_cameraService.controller!);
  }

  Widget _buildFlashOverlay() {
    return AnimatedBuilder(
      animation: _flashAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.white.withValues(alpha: _flashAnimation.value * 0.8),
        );
      },
    );
  }

  Widget _buildControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Cancel/Back button
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            
            // Capture button
            GestureDetector(
              onTap: _isTakingPicture ? null : _captureImage,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _isTakingPicture ? Colors.grey : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white30,
                    width: 3,
                  ),
                ),
                child: _isTakingPicture
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      )
                    : Container(),
              ),
            ),
            
            // Switch camera button (disabled on Windows)
            IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
              onPressed: Platform.isWindows || _cameraService.cameras.length <= 1 
                ? null 
                : _switchCamera,
            ),
          ],
        ),
      ),
    );
  }
}