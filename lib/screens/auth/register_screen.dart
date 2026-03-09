import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'FARMER';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final userId = await authProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (mounted) {
      if (userId > 0) {
        // Show success message and navigate to OTP verification screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email for the verification code.'),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Navigate to OTP verification screen with the actual user ID
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(userId: userId),
          ),
        );
      } else if (userId == 0) {
        // Registration succeeded but no user ID returned
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please check your email for verification instructions.'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate back to login screen
        Navigator.of(context).pop();
      } else {
        // Registration failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? AppStrings.genericError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 150) {
      return 'Username must not exceed 150 characters';
    }
    // Check for valid characters (alphanumeric and @/./+/-/_)
    final validPattern = RegExp(r'^[a-zA-Z0-9@.+\-_]+$');
    if (!validPattern.hasMatch(value)) {
      return 'Username contains invalid characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailPattern.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length < 8) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value != _passwordController.text) {
      return AppStrings.passwordMismatch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          AppStrings.createAccount,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: Stack(
              children: [
                // Premium Background
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/auth_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient Overlay for readability
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.8),
                          Colors.white,
                        ],
                        stops: const [0.0, 0.4, 0.8],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),
                            // Welcome text
                            Text(
                              'Join Mlimi',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Connect with farmers and grow together',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),

                            // Form Glass Container
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  CustomTextField(
                                    controller: _usernameController,
                                    label: AppStrings.username,
                                    prefixIcon: Icons.person_rounded,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateUsername,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _emailController,
                                    label: AppStrings.email,
                                    prefixIcon: Icons.alternate_email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomDropdownField<String>(
                                    value: _selectedRole,
                                    label: AppStrings.role,
                                    prefixIcon: Icons.badge_rounded,
                                    items: AppConstants.userRoles,
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
                                        setState(() => _selectedRole = value);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _passwordController,
                                    label: AppStrings.password,
                                    prefixIcon: Icons.lock_rounded,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: _validatePassword,
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _confirmPasswordController,
                                    label: AppStrings.confirmPassword,
                                    prefixIcon: Icons.lock_clock_rounded,
                                    obscureText: _obscureConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _handleRegister(),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                    validator: _validateConfirmPassword,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            // Terms and Conditions
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                                    child: RichText(
                                      text: TextSpan(
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        children: [
                                          const TextSpan(text: 'I accept the '),
                                          TextSpan(
                                            text: 'Terms & Conditions',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            // Register Button
                            CustomButton(
                              text: AppStrings.createAccount,
                              onPressed: _handleRegister,
                              isLoading: authProvider.isLoading,
                            ),

                            const SizedBox(height: 24),
                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppStrings.alreadyHaveAccount,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    AppStrings.login,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
