import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  
  String? _selectedRole;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _selectedRole = user?.role ?? 'FARMER';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final result = await _authService.updateProfile(
        firstName: _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : null,
        lastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : null,
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        role: _selectedRole,
      );

      if (result.isSuccess && mounted) {
        // Refresh user data in provider
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.profileUpdated),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate back to profile screen
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.genericError} $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.editProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.personalInfo,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // First Name Field
                  CustomTextField(
                    controller: _firstNameController,
                    label: AppStrings.firstName,
                    hint: AppStrings.firstName,
                    validator: (value) {
                      if (value != null && value.length > 50) {
                        return 'First name must be less than 50 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Last Name Field
                  CustomTextField(
                    controller: _lastNameController,
                    label: AppStrings.lastName,
                    hint: AppStrings.lastName,
                    validator: (value) {
                      if (value != null && value.length > 50) {
                        return 'Last name must be less than 50 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Username Field
                  CustomTextField(
                    controller: _usernameController,
                    label: AppStrings.username,
                    hint: AppStrings.username,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (value.length > 30) {
                        return 'Username must be less than 30 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: AppStrings.email,
                    hint: AppStrings.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return AppStrings.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Role Dropdown
                  // Note: In a real app, users might not be able to change their role
                  // This is included for completeness based on the design
                  /*
                  CustomDropdownField<String>(
                    value: _selectedRole,
                    items: const ['FARMER', 'TRADER', 'AGRONOMIST', 'ADMIN'],
                    label: AppStrings.role,
                    hint: AppStrings.selectRole,
                    itemBuilder: (role) {
                      switch (role) {
                        case 'FARMER':
                          return AppStrings.farmer;
                        case 'TRADER':
                          return AppStrings.trader;
                        case 'AGRONOMIST':
                          return AppStrings.agronomist;
                        case 'ADMIN':
                          return AppStrings.admin;
                        default:
                          return role;
                      }
                    },
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                  */
                  
                  const SizedBox(height: 32),
                  
                  // Update Button
                  CustomButton(
                    text: _isUpdating ? AppStrings.submitting : AppStrings.save,
                    onPressed: _isUpdating ? null : _updateProfile,
                    isLoading: _isUpdating,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Change Password Button
                  CustomButton(
                    text: AppStrings.changePassword,
                    onPressed: () {
                      // Navigate to change password screen
                      Navigator.pushNamed(context, '/change-password');
                    },
                    backgroundColor: AppColors.secondary,
                    textColor: AppColors.textInverse,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}