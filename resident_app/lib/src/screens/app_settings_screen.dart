// lib/src/screens/app_settings_screen.dart
// App Settings Screen with Language Switcher

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hominode_legal/hominode_legal.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';

// ============================================================================
// APP SETTINGS SCREEN
// ============================================================================
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _twoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('settings'.tr()),
            backgroundColor: const Color(0xFF0E4778),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Language Settings Section
                _buildSectionHeader(context, 'language'),
                _buildLanguageSection(context),

                const Divider(height: 32),

                // Notification Settings Section
                _buildSectionHeader(context, 'notifications'),
                _buildNotificationSettings(context),

                const Divider(height: 32),

                // Security Settings Section
                _buildSectionHeader(context, 'settings_security'),
                _buildSecuritySettings(context),

                const Divider(height: 32),

                // Privacy Settings Section
                _buildSectionHeader(context, 'settings_privacy'),
                _buildPrivacySettings(context),

                const Divider(height: 32),

                // About Section
                _buildSectionHeader(context, 'about'),
                _buildAboutSection(context),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // LANGUAGE SECTION
  // ========================================================================
  Widget _buildLanguageSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8, // Adjusted ratio to give enough height
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: languageProvider.supportedLanguages.length,
            itemBuilder: (context, index) {
              final language = languageProvider.supportedLanguages[index];
              final isSelected =
                  languageProvider.currentLanguageCode == language;

              return GestureDetector(
                onTap: () async {
                  await languageProvider.setLanguage(language, context);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0E4778)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0E4778)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getLanguageFlag(language),
                        style: TextStyle(fontSize: 24.sp),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        languageProvider.getLanguageName(language),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getLanguageFlag(String languageCode) {
    const flagMap = {
      'en': '🇬🇧',
      'ta': '🇮🇳',
      'hi': '🇮🇳',
      'es': '🇪🇸',
      'ar': '🇸🇦',
    };
    return flagMap[languageCode] ?? '🌐';
  }

  // ========================================================================
  // NOTIFICATION SETTINGS
  // ========================================================================
  Widget _buildNotificationSettings(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'receive_notifications'.tr(),
            subtitle: 'notifications'.tr(),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
              activeThumbColor: const Color(0xFF0E4778),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.email,
            title: 'email_notifications'.tr(),
            subtitle: 'email_notifications'.tr(),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeThumbColor: const Color(0xFF0E4778),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.sms,
            title: 'sms_notifications'.tr(),
            subtitle: 'sms_notifications'.tr(),
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeThumbColor: const Color(0xFF0E4778),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // SECURITY SETTINGS
  // ========================================================================
  Widget _buildSecuritySettings(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.security,
            title: 'two_factor_auth'.tr(),
            subtitle: 'two_factor_auth'.tr(),
            trailing: Switch(
              value: _twoFactorEnabled,
              onChanged: (value) {
                setState(() => _twoFactorEnabled = value);
              },
              activeThumbColor: const Color(0xFF0E4778),
            ),
          ),
          _buildSettingsTile(
            icon: Icons.devices,
            title: 'active_sessions'.tr(),
            subtitle: 'active_sessions'.tr(),
            onTap: () {
              _showActiveSessionsDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // PRIVACY SETTINGS
  // ========================================================================
  Widget _buildPrivacySettings(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'privacy_policy'.tr(),
            subtitle: 'privacy_policy'.tr(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HominodeLegalDocumentViewer(
                    title: 'privacy_policy'.tr(),
                    assetPath: HominodeLegalDocuments.privacyPolicyAsset,
                  ),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'terms_conditions'.tr(),
            subtitle: 'terms_conditions'.tr(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HominodeLegalDocumentViewer(
                    title: 'terms_conditions'.tr(),
                    assetPath: HominodeLegalDocuments.termsAndConditionsAsset,
                  ),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.delete_outline,
            title: 'delete_account'.tr(),
            subtitle: 'delete_account'.tr(),
            onTap: () {
              _showDeleteAccountDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // ABOUT SECTION
  // ========================================================================
  Widget _buildAboutSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.info,
            title: 'about'.tr(),
            subtitle: 'version'.tr(),
          ),
          _buildSettingsTile(
            icon: Icons.help,
            title: 'help_support'.tr(),
            subtitle: 'help_support'.tr(),
            onTap: () {
              _showHelpDialog(context);
            },
          ),
          _buildSettingsTile(
            icon: Icons.feedback,
            title: 'send_feedback'.tr(),
            subtitle: 'send_feedback'.tr(),
            onTap: () {
              _showFeedbackDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // HELPER WIDGETS
  // ========================================================================
  Widget _buildSectionHeader(BuildContext context, String titleKey) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 12.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          titleKey.tr(),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0E4778),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0E4778)),
      title: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
    );
  }

  // ========================================================================
  // DIALOGS
  // ========================================================================
  void _showActiveSessionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('active_sessions'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('current_device'.tr()),
              subtitle: const Text('Android Phone'),
              trailing: Text('active_sessions'.tr()),
            ),
            ListTile(
              title: const Text('iPad'),
              subtitle: Text('last_active'.tr()),
              trailing: TextButton(
                onPressed: () {},
                child: Text('sign_out'.tr()),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_account'.tr()),
        content: Text('delete_account'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('help_support'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'faq'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              Text('help_support'.tr()),
              SizedBox(height: 16.h),
              Text('contact_support'.tr()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('send_feedback'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'feedback_subject'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              decoration: InputDecoration(
                labelText: 'feedback_message'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E4778),
            ),
            child: Text('send'.tr()),
          ),
        ],
      ),
    );
  }
}
