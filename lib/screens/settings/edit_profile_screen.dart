import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/localization_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneNumberController = TextEditingController(text: ''); // Not in user model
    _addressController = TextEditingController(text: ''); // Not in user model
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.updateProfile(
        firstName: _firstNameController.text.trim().isNotEmpty ? _firstNameController.text.trim() : null,
        lastName: _lastNameController.text.trim().isNotEmpty ? _lastNameController.text.trim() : null,
      );

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LocalizationService>(context, listen: false)
                  .getString('profileUpdated'),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(); // Go back to settings
      } else if (mounted) {
        setState(() {
          _errorMessage = authProvider.errorMessage ??
              Provider.of<LocalizationService>(context, listen: false)
                  .getString('genericError');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizationService.getString('editProfile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // First Name Field
              CustomTextField(
                controller: _firstNameController,
                label: localizationService.getString('firstName'),
                hint: localizationService.getString('firstName'),
                validator: (value) {
                  if (value != null && value.length > 30) {
                    return 'First name must be less than 30 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name Field
              CustomTextField(
                controller: _lastNameController,
                label: localizationService.getString('lastName'),
                hint: localizationService.getString('lastName'),
                validator: (value) {
                  if (value != null && value.length > 30) {
                    return 'Last name must be less than 30 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number Field (Not in current user model, but included for completeness)
              CustomTextField(
                controller: _phoneNumberController,
                label: localizationService.getString('phoneNumber'),
                hint: localizationService.getString('phoneNumber'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 10) {
                    return localizationService.getString('invalidPhoneNumber');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Address Field (Not in current user model, but included for completeness)
              CustomTextField(
                controller: _addressController,
                label: localizationService.getString('address'),
                hint: localizationService.getString('address'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save Button
              CustomButton(
                text: localizationService.getString('save'),
                onPressed: _isLoading ? null : _updateProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),

              // Cancel Button
              CustomTextButton(
                text: localizationService.getString('cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}