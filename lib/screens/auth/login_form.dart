import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;
  bool _rememberPassword = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email/Username Field
          TextFormField(
            controller: _usernameController,
            style: GoogleFonts.inter(color: Colors.black87),
            decoration: _minimalInputDecoration('Email Address', Icons.mail_outline),
            validator: (value) => value!.isEmpty ? 'Please enter your username' : null,
          ),
          const SizedBox(height: 20),

          // Password Field
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
            validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
          ),
          
          const SizedBox(height: 20),

          // Remember Me & Forgot Password
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberPassword,
                  onChanged: (value) => setState(() => _rememberPassword = value ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Remember password', 
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Forget password',
                  style: GoogleFonts.inter(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          
          // Error Message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage,
                style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
              ),
            ),

          // Login Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
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
                    'Login',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Social Login Separator
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[300])),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or connect with',
                  style: GoogleFonts.inter(color: Colors.grey[500]),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Social Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.facebook, const Color(0xFF3B5998)),
              const SizedBox(width: 20),
              _buildSocialIcon(Icons.camera_alt, const Color(0xFFE4405F)), // Instagram placeholder
              const SizedBox(width: 20),
              _buildSocialIcon(Icons.javascript, const Color(0xFFBD081C)), // Pinterest placeholder
              const SizedBox(width: 20),
              _buildSocialIcon(Icons.work, const Color(0xFF0077B5)), // LinkedIn placeholder
            ],
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

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (success) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
