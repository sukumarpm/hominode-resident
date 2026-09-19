import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/localized_text.dart';

/// App Settings Screen with Full Localization Support
/// Demonstrates how to use localization throughout the app
class AppSettingsScreenLocalized extends StatefulWidget {
  const AppSettingsScreenLocalized({super.key});

  @override
  State<AppSettingsScreenLocalized> createState() =>
      _AppSettingsScreenLocalizedState();
}

class _AppSettingsScreenLocalizedState
    extends State<AppSettingsScreenLocalized> {
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E4778),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: LocalizedAppBarTitle(
              'settings',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Section
                _buildSectionHeader(context, 'language'),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: LanguageSelector(showTitle: true, isCompact: false),
                ),
                const Divider(height: 1),

                // Notifications Section
                _buildSectionHeader(context, 'settings_notifications'),
                _buildNotificationTile(
                  context,
                  'receive_notifications',
                  _notificationsEnabled,
                  (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
                _buildNotificationTile(
                  context,
                  'email_notifications',
                  _emailNotificationsEnabled,
                  (value) {
                    setState(() => _emailNotificationsEnabled = value);
                  },
                ),
                _buildNotificationTile(
                  context,
                  'sms_notifications',
                  _smsNotificationsEnabled,
                  (value) {
                    setState(() => _smsNotificationsEnabled = value);
                  },
                ),
                const Divider(height: 1),

                // Security Section
                _buildSectionHeader(context, 'settings_security'),
                _buildNotificationTile(
                  context,
                  'two_factor_auth',
                  _twoFactorEnabled,
                  (value) {
                    setState(() => _twoFactorEnabled = value);
                  },
                ),
                _buildSettingsTile(context, 'change_password', Icons.lock, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: LocalizedText('change_password')),
                  );
                }),
                const Divider(height: 1),

                // Privacy Section
                _buildSectionHeader(context, 'settings_privacy'),
                _buildSettingsTile(
                  context,
                  'privacy_policy',
                  Icons.privacy_tip,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: LocalizedText('privacy_policy')),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  'terms_conditions',
                  Icons.description,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: LocalizedText('terms_conditions')),
                    );
                  },
                ),
                const Divider(height: 1),

                // About Section
                _buildSectionHeader(context, 'about'),
                _buildSettingsTile(context, 'faq', Icons.help, () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: LocalizedText('faq')));
                }),
                _buildSettingsTile(
                  context,
                  'contact_support',
                  Icons.support_agent,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: LocalizedText('contact_support')),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  'send_feedback',
                  Icons.feedback,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: LocalizedText('send_feedback')),
                    );
                  },
                ),
                const Divider(height: 1),

                // App Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        'version',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9B9B9B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: LocalizedButton(
                      'logout',
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String translationKey) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LocalizedText(
        translationKey,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0E4778),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String translationKey,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0E4778)),
      title: LocalizedText(translationKey),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    String translationKey,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: LocalizedText(translationKey),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF0E4778),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: LocalizedText('logout'),
        content: LocalizedText('confirm'),
        actions: [
          LocalizedTextButton(
            'cancel',
            onPressed: () => Navigator.pop(context),
          ),
          LocalizedButton(
            'logout',
            onPressed: () {
              Navigator.pop(context);
              // Perform logout
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: LocalizedText('logout')));
            },
          ),
        ],
      ),
    );
  }
}
