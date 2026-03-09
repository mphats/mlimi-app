import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'FARMER';
  bool _acceptTerms = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Username
          TextFormField(
            controller: _usernameController,
            style: GoogleFonts.inter(color: Colors.black87),
            decoration: _minimalInputDecoration('Username', Icons.person_outline),
            validator: (value) => value!.isEmpty ? 'Please enter a username' : null,
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            style: GoogleFonts.inter(color: Colors.black87),
            decoration: _minimalInputDecoration('Email Address', Icons.email_outlined),
            validator: (value) => value!.contains('@') ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 16),

          // Role Dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            style: GoogleFonts.inter(color: Colors.black87, fontSize: 16),
            dropdownColor: Colors.white,
            decoration: _minimalInputDecoration('Select Role', Icons.work_outline),
            items: AppConstants.userRoles.map((role) {
              return DropdownMenuItem(value: role, child: Text(role));
            }).toList(),
            onChanged: (value) => setState(() => _selectedRole = value!),
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(color: Colors.black87),
            decoration: _minimalInputDecoration('Password', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) => value!.length < 8 ? 'Password must be 8+ chars' : null,
          ),
          const SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: GoogleFonts.inter(color: Colors.black87),
            decoration: _minimalInputDecoration('Confirm Password', Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
          ),
          
          const SizedBox(height: 20),

          // Terms
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
                    children: const [
                       TextSpan(text: 'I accept the '),
                       TextSpan(text: 'Terms', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                       TextSpan(text: ' and '),
                       TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          
          if (_errorMessage != null)
             Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
              ),
            ),

          // Register Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : Text(
                    'Register',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _minimalInputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 22),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Please accept the terms and conditions');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final userId = await authProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (mounted) {
      if (userId > 0) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OTPVerificationScreen(userId: userId),
          ),
        );
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Registration failed';
          _isLoading = false;
        });
      }
    }
  }
}
