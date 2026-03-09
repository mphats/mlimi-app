import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../camera/camera_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/token_utils.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/user_model.dart';
import '../../core/utils/image_url_processor.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/image_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  UserModel? _profileData;
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ImagePicker _picker = ImagePicker();
  final ImageService _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : _profileData != null
                  ? _buildProfileContent()
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('No profile data available'),
                          SizedBox(height: 20),
                          CircularProgressIndicator(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.error,
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _loadProfileData,
                child: const Text('Retry'),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: _handleLogout,
                child: const Text('Logout'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    _animationController.forward();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          // Cover image section with gradient overlay
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverImage(),
                  // Gradient overlay for better text contrast
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Edit cover image button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _pickCoverImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Profile image and info section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(top: 80, left: 16, right: 16),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildProfileStats(),
                  const SizedBox(height: 24),
                  _buildProfileDetails(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage() {
    final coverImageUrl = _profileData?.coverImageUrl;
    final processedCoverUrl = ImageUrlProcessor.processImageUrl(coverImageUrl);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.3),
      ),
      child: coverImageUrl != null && coverImageUrl.isNotEmpty
          ? Image.network(
              processedCoverUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
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
            )
          : _buildDefaultCover(),
    );
  }

  Widget _buildDefaultCover() {
    return Image.asset(
      'assets/images/dashboard_header.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile image with badge
          Stack(
            children: [
              _buildProfileImage(),
              // Online status badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: AppColors.cardBackground,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              // Edit profile image button
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBackground,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    onPressed: _pickProfileImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profileData!.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _profileData!.roleDisplayName,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _profileData!.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _profileData!.isActive 
                        ? AppColors.success.withValues(alpha: 0.1) 
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _profileData!.isActive ? 'Active Account' : 'Inactive Account',
                    style: TextStyle(
                      fontSize: 12,
                      color: _profileData!.isActive 
                          ? AppColors.success 
                          : AppColors.error,
                      fontWeight: FontWeight.w500,
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

  Widget _buildProfileImage() {
    final profileImageUrl = _profileData?.profileImageUrl;
    final processedProfileUrl = ImageUrlProcessor.processImageUrl(profileImageUrl);
    
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.cardBackground,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 55,
        backgroundColor: AppColors.surface,
        child: profileImageUrl != null && profileImageUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  processedProfileUrl,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultProfileImage();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              )
            : _buildDefaultProfileImage(),
      ),
    );
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      width: 110,
      height: 110,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
      ),
      child: Center(
        child: Text(
          _profileData!.initials,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Member', 'Since'),
          _buildStatItem('Account', _profileData!.isActive ? 'Active' : 'Inactive'),
          _buildStatItem('Role', _profileData!.role.substring(0, 3).toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.person, 'Username', _profileData!.username),
          _buildDetailRow(Icons.email, 'Email', _profileData!.email),
          _buildDetailRow(Icons.badge, 'First Name', _profileData!.firstName ?? 'Not provided'),
          _buildDetailRow(Icons.badge, 'Last Name', _profileData!.lastName ?? 'Not provided'),
          _buildDetailRow(Icons.work, 'Role', _profileData!.roleDisplayName),
          _buildDetailRow(
            Icons.calendar_today,
            'Member Since',
            _profileData!.dateJoined != null
                ? '${_profileData!.dateJoined!.day.toString().padLeft(2, '0')} ${_getMonthName(_profileData!.dateJoined!.month)} ${_profileData!.dateJoined!.year}'
                : 'Not available'
          ),
          _buildDetailRow(
            Icons.lock,
            'Account Status',
            _profileData!.isActive ? 'Active' : 'Inactive'
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isFarmer = authProvider.user?.role == 'FARMER';
    final isAgronomist = authProvider.user?.role == 'AGRONOMIST';
    
    final List<Widget> actionButtons = [
      ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/edit-profile');
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.edit, size: 20),
        label: const Text(
          'Edit Profile',
          style: TextStyle(fontSize: 16),
        ),
      ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/change-password');
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.lock, size: 20),
        label: const Text(
          'Change Password',
          style: TextStyle(fontSize: 16),
        ),
      ),
      const SizedBox(height: 12),
    ];

    // Add consultation button based on user role
    if (isFarmer || isAgronomist) {
      actionButtons.addAll([
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/consultations');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.question_answer, size: 20),
          label: Text(
            isFarmer ? 'My Consultations' : 'Expert Consultations',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }

    actionButtons.add(
      OutlinedButton.icon(
        onPressed: _handleLogout,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.error,
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actionButtons,
      ),
    );
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService().get(AppConstants.userProfile);
      
      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _profileData = UserModel.fromJson(data);
        });
        // Reset animation for fresh content
        _animationController.reset();
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
        });
        // Navigate to login after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile data. Status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading profile data: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      // Clear stored tokens
      await TokenUtils.clearTokens();
      
      // Navigate to login screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  // Pick and upload profile image
  Future<void> _pickProfileImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      XFile? pickedFile;
      
      if (source == ImageSource.camera) {
        if (!mounted) return;
        // Open camera screen
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(
              onImageCaptured: (path) {
                Navigator.pop(context, path);
              },
            ),
          ),
        );
        
        if (result != null) {
          pickedFile = XFile(result);
        }
      } else {
        // Pick from gallery
        pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );
      }

      if (pickedFile != null) {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        }

        // Upload the image
        final imageFile = File(pickedFile.path);
        final result = await _imageService.uploadProfileImage(imageFile);

        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
        }

        if (result.isSuccess && mounted) {
          // Update the profile data with new image URL
          setState(() {
            _profileData = _profileData?.copyWith(
              profileImageUrl: result.imageUrl,
            );
          });

          // Also update the auth provider
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.refreshUser();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if showing
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Show dialog to select image source (camera or gallery)
  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose where to pick your image from'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );
  }

  // Pick and upload cover image
  Future<void> _pickCoverImage() async {
    final source = await _showImageSourceDialog();
    if (source == null) return;

    try {
      XFile? pickedFile;
      
      if (source == ImageSource.camera) {
        if (!mounted) return;
        // Open camera screen
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(
              onImageCaptured: (path) {
                Navigator.pop(context, path);
              },
            ),
          ),
        );
        
        if (result != null) {
          pickedFile = XFile(result);
        }
      } else {
        // Pick from gallery
        pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );
      }

      if (pickedFile != null) {
        // Show loading indicator
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        }

        // Upload the image
        final imageFile = File(pickedFile.path);
        final result = await _imageService.uploadCoverImage(imageFile);

        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
        }

        if (result.isSuccess && mounted) {
          // Update the profile data with new image URL
          setState(() {
            _profileData = _profileData?.copyWith(
              coverImageUrl: result.imageUrl,
            );
          });

          // Also update the auth provider
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.refreshUser();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cover image updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator if showing
      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}