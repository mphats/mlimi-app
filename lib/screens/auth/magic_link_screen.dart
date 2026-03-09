import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class MagicLinkScreen extends StatefulWidget {
  const MagicLinkScreen({super.key});

  @override
  State<MagicLinkScreen> createState() => _MagicLinkScreenState();
}

class _MagicLinkScreenState extends State<MagicLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleMagicLinkRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.requestMagicLink(
      _emailController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() {
          _emailSent = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? AppStrings.genericError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AppStrings.magicLink, style: TextStyle(fontWeight: FontWeight.bold)),
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
                // Gradient Overlay
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
                    padding: const EdgeInsets.all(24.0),
                    child: _emailSent
                        ? _buildEmailSentContent()
                        : _buildEmailForm(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.link, size: 40, color: AppColors.primary),
          ),

          const SizedBox(height: 32),

          // Title and Description
          Text(
            'Magic Link Login',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter your email address and we\'ll send you a magic link to login instantly without a password.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Benefits
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Why Magic Link?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• No password to remember\n'
                  '• More secure than passwords\n'
                  '• Quick and easy access\n'
                  '• Works on any device',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Email Field
          CustomTextField(
            controller: _emailController,
            label: AppStrings.email,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleMagicLinkRequest(),
            validator: _validateEmail,
          ),

          const SizedBox(height: 32),

          // Send Magic Link Button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return CustomButton(
                text: AppStrings.sendMagicLink,
                onPressed: _handleMagicLinkRequest,
                isLoading: authProvider.isLoading,
                icon: Icons.send,
              );
            },
          ),

          const SizedBox(height: 24),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Back to Login',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),

        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 40,
            color: AppColors.success,
          ),
        ),

        const SizedBox(height: 32),

        // Success Message
        Text(
          'Magic Link Sent!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a magic link to ${_emailController.text}',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 40),

        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Next Steps:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '1. Check your email inbox\n'
                '2. Click the magic link in the email\n'
                '3. You\'ll be logged in automatically\n'
                '4. Start using the app!',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Countdown Timer (optional)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.timer, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Magic link expires in 15 minutes',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Resend Button
        CustomOutlinedButton(
          text: 'Resend Magic Link',
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          icon: Icons.refresh,
        ),

        const SizedBox(height: 16),

        // Back to Login
        CustomButton(
          text: 'Back to Login',
          onPressed: () => Navigator.of(context).pop(),
        ),

        const SizedBox(height: 24),

        // Help Text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'Didn\'t receive the email?',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your spam folder or try resending the magic link.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
