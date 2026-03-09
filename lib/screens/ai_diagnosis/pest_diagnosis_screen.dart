import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/pest_diagnosis_service.dart';
import '../../core/services/offline_service.dart';
import '../../core/models/pest_diagnosis_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import 'diagnosis_detail_screen.dart';

class PestDiagnosisScreenWidget extends StatefulWidget {
  const PestDiagnosisScreenWidget({super.key});

  @override
  State<PestDiagnosisScreenWidget> createState() => _PestDiagnosisScreenWidgetState();
}

class _PestDiagnosisScreenWidgetState extends State<PestDiagnosisScreenWidget> {
  final _formKey = GlobalKey<FormState>();
  final _symptomsController = TextEditingController();
  final _diagnosisService = PestDiagnosisService();
  final _imagePicker = ImagePicker();

  String _selectedCropType = 'Maize';
  File? _selectedImage;
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  bool _isOfflineMode = false;
  List<PestDiagnosisModel> _diagnosisHistory = [];
  int _totalDiagnoses = 0;

  @override
  void initState() {
    super.initState();
    _loadDiagnosisHistory();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnosisHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final result = await _diagnosisService.getDiagnosisHistory();

      if (result.isSuccess) {
        setState(() {
          _diagnosisHistory = result.diagnoses;
          _totalDiagnoses = result.totalCount;
          _isOfflineMode = false;
        });
        
        // Save data for offline use
        final List<Map<String, dynamic>> offlineData = 
            result.diagnoses.map((d) => d.toJson()).toList();
        await OfflineService.saveDiagnosisHistory(offlineData);
      } else {
        // Try to load offline data if API fails
        await _loadOfflineData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result.message}. Showing offline data.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      // Try to load offline data if API fails
      await _loadOfflineData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load diagnosis history: ${e.toString()}. Showing offline data.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _loadOfflineData() async {
    try {
      final isRecent = await OfflineService.isDataRecent();
      if (isRecent) {
        final offlineData = await OfflineService.getDiagnosisHistory();
        if (offlineData != null && offlineData.isNotEmpty) {
          final diagnoses = offlineData.map((json) => PestDiagnosisModel.fromJson(json)).toList();
          if (mounted) {
            setState(() {
              _diagnosisHistory = diagnoses;
              _totalDiagnoses = diagnoses.length;
              _isOfflineMode = true;
            });
          }
        }
      }
    } catch (e) {
      // Silently fail if offline data is not available
      debugPrint('Failed to load offline data: $e');
    }
  }

  /// Check if we have the necessary permissions before picking an image
  Future<bool> _checkPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final requestedStatus = await Permission.camera.request();
        return requestedStatus.isGranted;
      }
      return true;
    } else {
      // For gallery, check storage permissions
      final storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        final requestedStatus = await Permission.storage.request();
        if (requestedStatus.isGranted) {
          return true;
        }
        
        // For Android 10+, also check manage external storage permission
        final manageStorageStatus = await Permission.manageExternalStorage.status;
        if (!manageStorageStatus.isGranted) {
          final requestedManageStatus = await Permission.manageExternalStorage.request();
          return requestedManageStatus.isGranted;
        }
      }
      
      // Also check manage external storage for Android 10+
      final manageStorageStatus = await Permission.manageExternalStorage.status;
      if (!manageStorageStatus.isGranted) {
        final requestedManageStatus = await Permission.manageExternalStorage.request();
        return requestedManageStatus.isGranted;
      }
      
      return true;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Check permissions first
      final hasPermission = await _checkPermissions(source);
      if (!hasPermission) {
        if (mounted) {
          String permissionName = source == ImageSource.camera ? 'Camera' : 'Storage';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$permissionName permission is required to ${source == ImageSource.camera ? 'take photos' : 'access gallery'}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submitDiagnosis() async {
    if (!_formKey.currentState!.validate()) return;

    if (_symptomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the symptoms'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _diagnosisService.diagnosePest(
        cropType: _selectedCropType,
        symptoms: _symptomsController.text.trim(),
        image: _selectedImage,
      );

      if (result.isSuccess) {
        // After successful diagnosis, reload the history
        await _loadDiagnosisHistory();

        // Clear the form
        setState(() {
          _symptomsController.clear();
          _selectedImage = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Diagnosis completed successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          // Handle authentication errors specifically
          if (result.message.contains('Authentication error') || 
              result.message.contains('token') || 
              result.message.contains('Token') ||
              result.message.contains('403')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your session has expired. Please log in again.'),
                backgroundColor: AppColors.error,
              ),
            );
            // TODO: Navigate to login screen
          } else if (result.message.contains('Invalid image')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: AppColors.warning,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}. Please check your connection and try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitAsyncDiagnosis() async {
    if (!_formKey.currentState!.validate()) return;

    if (_symptomsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the symptoms'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _diagnosisService.diagnoseAsync(
        cropType: _selectedCropType,
        symptoms: _symptomsController.text.trim(),
        image: _selectedImage,
      );

      if (result.isSuccess && result.result != null) {
        // Show task started message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.success,
            ),
          );
        }

        // Clear the form
        setState(() {
          _symptomsController.clear();
          _selectedImage = null;
        });

        // Reload history to show the new pending diagnosis
        await _loadDiagnosisHistory();
        
        // Start polling for task status if we have a task ID
        if (result.result?.taskId != null) {
          _pollTaskStatus(result.result!.taskId!);
        }
      } else {
        if (mounted) {
          // Handle authentication errors specifically
          if (result.message.contains('Authentication error') || 
              result.message.contains('token') || 
              result.message.contains('Token') ||
              result.message.contains('403')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your session has expired. Please log in again.'),
                backgroundColor: AppColors.error,
              ),
            );
            // TODO: Navigate to login screen
          } else if (result.message.contains('Invalid image')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: AppColors.warning,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}. Please check your connection and try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Poll for task status updates
  Future<void> _pollTaskStatus(String taskId) async {
    // Poll every 5 seconds for up to 2 minutes
    int attempts = 0;
    const maxAttempts = 24; // 24 * 5 seconds = 2 minutes
    
    while (attempts < maxAttempts && mounted) {
      await Future.delayed(const Duration(seconds: 5));
      attempts++;
      
      try {
        final result = await _diagnosisService.getTaskStatus(taskId);
        
        if (result.isSuccess && result.result != null) {
          // Check if task is completed
          if (result.result!.isCompleted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Diagnosis completed: ${result.result!.diagnosis}'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
            // Reload history to show completed diagnosis
            await _loadDiagnosisHistory();
            break;
          } else if (result.result!.hasFailed) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Diagnosis failed: ${result.result!.diagnosis}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            break;
          } else {
            // Still processing, show progress
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Diagnosis in progress...'),
                  backgroundColor: AppColors.info,
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          }
          // If still processing, continue polling
        } else if (result.isFailure) {
          // Handle API error but continue polling
          debugPrint('Task status check failed: ${result.message}');
        }
      } catch (e) {
        debugPrint('Error polling task status: $e');
        // Continue polling even if one request fails
      }
    }
    
    // If we've reached max attempts without completion, notify user
    if (attempts >= maxAttempts && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnosis is taking longer than expected. Please check back later.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Pest Diagnosis'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_isOfflineMode)
              IconButton(
                icon: const Icon(Icons.offline_pin, color: AppColors.warning),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Showing offline data. Connect to the internet for latest updates.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDiagnosisHistory,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadDiagnosisHistory,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with stats
                _buildHeader(),
                const SizedBox(height: 24),

                // How It Works Section
                _buildHowItWorks(),
                const SizedBox(height: 24),
                // Diagnosis Form
                _buildDiagnosisForm(),
                const SizedBox(height: 32),
                // Diagnosis History
                _buildDiagnosisHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.aiPestDiagnosis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload images of your crops to get instant AI-powered pest and disease diagnosis',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (_totalDiagnoses > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Diagnoses',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_totalDiagnoses',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'How It Works',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHowItWorksStep(
                Icons.camera_alt,
                'Upload Image',
                AppColors.primary,
                1,
              ),
              _buildHowItWorksStep(
                Icons.auto_graph,
                'AI Analysis',
                AppColors.secondary,
                2,
              ),
              _buildHowItWorksStep(
                Icons.lightbulb_outline,
                'Get Results',
                AppColors.success,
                3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep(
    IconData icon,
    String label,
    Color color,
    int step,
  ) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 8),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDiagnosisForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Submit Diagnosis Request',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Crop Type Dropdown
            _buildCropTypeDropdown(),

            const SizedBox(height: 16),

            // Symptoms Input
            CustomTextField(
              controller: _symptomsController,
              label: AppStrings.symptoms,
              hint: AppStrings.describeSymptoms,
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe the symptoms';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Image Upload Section
            _buildImageUploadSection(),

            const SizedBox(height: 24),

            // Submit Buttons
            LayoutBuilder(
              builder: (context, constraints) {
                // If screen is wide enough, use Row, otherwise use Column
                if (constraints.maxWidth > 400) {
                  return Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Quick Diagnosis',
                          onPressed: _submitDiagnosis,
                          isLoading: _isLoading,
                          width: double.infinity,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Advanced Analysis',
                          onPressed: _submitAsyncDiagnosis,
                          isLoading: _isLoading,
                          width: double.infinity,
                          backgroundColor: AppColors.secondary,
                        ),
                      ),
                    ],
                  );
                } else {
                  // On narrow screens, stack buttons vertically
                  return Column(
                    children: [
                      CustomButton(
                        text: 'Quick Diagnosis',
                        onPressed: _submitDiagnosis,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Advanced Analysis',
                        onPressed: _submitAsyncDiagnosis,
                        isLoading: _isLoading,
                        width: double.infinity,
                        backgroundColor: AppColors.secondary,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropTypeDropdown() {
    final cropTypes = _diagnosisService.getSupportedCropTypes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.cropType,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCropType,
              isExpanded: true,
              items: cropTypes.map((crop) {
                return DropdownMenuItem(
                  value: crop, 
                  child: Text(
                    crop,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCropType = value;
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.uploadImage,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedImage != null
                    ? AppColors.primary
                    : AppColors.inputBorder,
                width: 1,
              ),
              image: _selectedImage != null
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to upload image',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supported formats: JPG, PNG',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosisHistory() {
    if (_isLoadingHistory && _diagnosisHistory.isEmpty) {
      return const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading diagnosis history...'),
          ],
        ),
      );
    }

    if (_diagnosisHistory.isEmpty) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Diagnosis History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No diagnosis history yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit your first diagnosis request to get started!',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textHint),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Try it now',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_downward,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Diagnosis History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            // Improved the diagnosis counter container with better padding and responsive design
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_diagnosisHistory.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'diagnoses',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Fixed the GridView to use shrinkWrap and remove fixed height to prevent overflow
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _diagnosisHistory.length,
          itemBuilder: (context, index) {
            final diagnosis = _diagnosisHistory[index];
            return _buildDiagnosisCard(diagnosis);
          },
        ),
      ],
    );
  }

  Widget _buildDiagnosisCard(PestDiagnosisModel diagnosis) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiagnosisDetailScreen(diagnosis: diagnosis),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: diagnosis.isCompleted
                ? (diagnosis.isPositive ? AppColors.error : AppColors.success)
                : AppColors.warning,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge and timestamp row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: diagnosis.isCompleted
                        ? (diagnosis.isPositive
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1))
                        : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    diagnosis.isCompleted
                        ? (diagnosis.isPositive ? 'Positive' : 'Negative')
                        : 'Processing',
                    style: TextStyle(
                      color: diagnosis.isCompleted
                          ? (diagnosis.isPositive
                              ? AppColors.error
                              : AppColors.success)
                          : AppColors.warning,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  diagnosis.timeAgo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Crop type and diagnosis result
            Text(
              diagnosis.cropTypeDisplay,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (diagnosis.isCompleted)
              Text(
                diagnosis.diagnosis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            
            // Confidence score
            if (diagnosis.isCompleted)
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    diagnosis.confidencePercentage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: diagnosis.confidenceScore,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        diagnosis.confidenceScore >= 0.7 
                            ? AppColors.success 
                            : (diagnosis.confidenceScore >= 0.5 
                                ? AppColors.warning 
                                : AppColors.error),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            
            // Image container with improved styling
            if (diagnosis.imagePath != null || diagnosis.image.isNotEmpty)
              Container(
                constraints: const BoxConstraints(minHeight: 70, maxHeight: 120),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: diagnosis.imagePath != null &&
                          File(diagnosis.imagePath!).existsSync()
                      ? Image.file(
                          File(diagnosis.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImagePlaceholder();
                          },
                        )
                      : (diagnosis.image.startsWith('http')
                          ? _buildNetworkImage(diagnosis.image)
                          : (diagnosis.imageUrl.isNotEmpty
                              ? _buildNetworkImage(diagnosis.imageUrl)
                              : _buildImagePlaceholder())),
                ),
              )
            else
              _buildImagePlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 20,
              color: AppColors.textHint,
            ),
            const SizedBox(width: 8),
            Text(
              'No image',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    // Validate URL before attempting to load
    if (imageUrl.isEmpty || !Uri.parse(imageUrl).isAbsolute) {
      return _buildImagePlaceholder();
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading network image: $error');
        return _buildImagePlaceholder();
      },
    );
  }
}