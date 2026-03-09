import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/localization_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/api_service.dart';
import '../../widgets/custom_button.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _dataSharingEnabled = true;
  bool _analyticsEnabled = true;
  bool _marketingEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dataSharingEnabled = prefs.getBool('data_sharing_enabled') ?? true;
      _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
      _marketingEnabled = prefs.getBool('marketing_enabled') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showPrivacyPolicy(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizationService.getString('privacyPolicy')),
          content: SingleChildScrollView(
            child: Text(localizationService.getString('privacyPolicyContent')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDataExportDialog(BuildContext context) {
    String selectedFormat = 'json';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Export Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select export format:'),
                  RadioListTile<String>(
                    title: const Text('JSON'),
                    value: 'json',
                    // ignore: deprecated_member_use
                    groupValue: selectedFormat,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        selectedFormat = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('CSV'),
                    value: 'csv',
                    // ignore: deprecated_member_use
                    groupValue: selectedFormat,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        selectedFormat = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _exportUserData(selectedFormat);
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _exportUserData(String format) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Processing data export...'),
              ],
            ),
          );
        },
      );

      final apiService = Provider.of<ApiService>(context, listen: false);
      final token = await apiService.getAccessToken();
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/user/data-export'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'format': format}),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Data export initiated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initiate data export'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initiate data export'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initiate data export'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    String password = '';
    String reason = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Are you sure you want to delete your account? This action cannot be undone.'),
                    const SizedBox(height: 16),
                    const Text('Please enter your password to confirm:'),
                    TextField(
                      obscureText: true,
                      onChanged: (value) {
                        setState(() {
                          password = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Reason for deletion (optional):'),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          reason = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Reason for deletion',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: password.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _deleteAccount(password, reason);
                        },
                  child: const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteAccount(String password, String reason) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Deleting account...'),
              ],
            ),
          );
        },
      );

      final apiService = Provider.of<ApiService>(context, listen: false);
      final token = await apiService.getAccessToken();
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/user/delete-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'password': password,
          'reason': reason,
        }),
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Show success message and log out user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Log out user
          final authProvider = Provider.of<AuthService>(context, listen: false);
          await authProvider.logout();
          
          // Navigate to login screen
          if (!mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } else {
          // Show error message
          String errorMessage = data['error'] ?? 'Failed to delete account';
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        String errorMessage = data['error'] ?? 'Invalid password';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete account'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete account'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizationService.getString('privacy')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Data Sharing Preferences
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Sharing',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Share data with partners'),
                    subtitle: const Text('Allow us to share your data with trusted partners'),
                    value: _dataSharingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _dataSharingEnabled = value;
                      });
                      _savePreference('data_sharing_enabled', value);
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Analytics'),
                    subtitle: const Text('Help us improve our app by sharing usage data'),
                    value: _analyticsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _analyticsEnabled = value;
                      });
                      _savePreference('analytics_enabled', value);
                    },
                  ),
                  
                  SwitchListTile(
                    title: const Text('Marketing communications'),
                    subtitle: const Text('Receive promotional emails and offers'),
                    value: _marketingEnabled,
                    onChanged: (value) {
                      setState(() {
                        _marketingEnabled = value;
                      });
                      _savePreference('marketing_enabled', value);
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Account Information
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListTile(
                    title: const Text('Data Export'),
                    subtitle: const Text('Request a copy of your data'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showDataExportDialog(context),
                  ),
                  
                  ListTile(
                    title: const Text('Delete Account'),
                    subtitle: const Text('Permanently delete your account and data'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showDeleteAccountDialog(context),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Privacy Policy
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Read our complete privacy policy to understand how we collect, use, and protect your data.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomButton(
                    text: localizationService.getString('privacyPolicy'),
                    onPressed: () => _showPrivacyPolicy(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}