import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/localization_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _autoRefreshEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _locationServicesEnabled = prefs.getBool('location_services_enabled') ?? true;
      _autoRefreshEnabled = prefs.getBool('auto_refresh_enabled') ?? true;
      _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showHelpAndSupport(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizationService.getString('helpAndSupport')),
          content: SingleChildScrollView(
            child: Text(localizationService.getString('helpAndSupportContent')),
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

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          localizationService.getString('settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(localizationService.getString('language')),
          _buildSettingsCard([
            _buildSettingsTile(
              title: localizationService.currentLanguage == 'en'
                  ? localizationService.getString('english')
                  : localizationService.getString('chichewa'),
              subtitle: 'Current Language',
              icon: Icons.language_rounded,
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.pushNamed(context, '/language-selection'),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(localizationService.getString('appSettings')),
          _buildSettingsCard([
            _buildSwitchTile(
              title: localizationService.getString('enableNotifications'),
              value: _notificationsEnabled,
              icon: Icons.notifications_active_rounded,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _savePreference('notifications_enabled', value);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              title: localizationService.getString('enableLocationServices'),
              value: _locationServicesEnabled,
              icon: Icons.location_on_rounded,
              onChanged: (value) {
                setState(() => _locationServicesEnabled = value);
                _savePreference('location_services_enabled', value);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              title: localizationService.getString('autoRefresh'),
              value: _autoRefreshEnabled,
              icon: Icons.refresh_rounded,
              onChanged: (value) {
                setState(() => _autoRefreshEnabled = value);
                _savePreference('auto_refresh_enabled', value);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              title: localizationService.getString('darkMode'),
              value: _darkModeEnabled,
              icon: Icons.dark_mode_rounded,
              onChanged: (value) {
                setState(() => _darkModeEnabled = value);
                _savePreference('dark_mode_enabled', value);
              },
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(localizationService.getString('accountSettings')),
          _buildSettingsCard([
            _buildSettingsTile(
              title: localizationService.getString('viewProfile'),
              icon: Icons.person_rounded,
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            _buildDivider(),
            _buildSettingsTile(
              title: localizationService.getString('changePassword'),
              icon: Icons.lock_rounded,
              onTap: () => Navigator.pushNamed(context, '/change-password'),
            ),
            _buildDivider(),
            _buildSettingsTile(
              title: localizationService.getString('notificationPreferences'),
              icon: Icons.tune_rounded,
              onTap: () => Navigator.pushNamed(context, '/notification-preferences'),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionHeader(localizationService.getString('about')),
          _buildSettingsCard([
            _buildSettingsTile(
              title: localizationService.getString('helpSupport'),
              icon: Icons.help_outline_rounded,
              onTap: () => _showHelpAndSupport(context),
            ),
            _buildDivider(),
            _buildSettingsTile(
              title: localizationService.getString('version'),
              subtitle: '1.0.0+1',
              icon: Icons.info_outline_rounded,
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: AppColors.background,
    );
  }
}