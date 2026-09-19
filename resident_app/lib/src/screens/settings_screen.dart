// lib/src/screens/settings_screen.dart
// Main Settings screen

import 'package:flutter/material.dart';
import '../models/setting_item.dart';
import '../components/setting_tile.dart';
import '../components/standard_screen.dart';
import '../models/user_profile_model.dart';
import '../modals/edit_profile_modal.dart';
import 'notifications_settings_screen.dart';
import 'language_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Settings',
      isScrollable: true,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._buildSections(),
          const SizedBox(height: 20),
          _buildLogoutButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOldHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF3AA6C8), Color(0xFF0E4778)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 16, 24),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
                padding: const EdgeInsets.all(12),
              ),
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections() {
    final sections = _getSettingSections();
    final widgets = <Widget>[];

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];

      // Section header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            section.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

      // Section items
      for (int j = 0; j < section.items.length; j++) {
        widgets.add(SettingTile(item: section.items[j]));
        if (j < section.items.length - 1) {
          widgets.add(const SizedBox(height: 8));
        }
      }

      // Divider between sections
      if (i < sections.length - 1) {
        widgets.add(const SizedBox(height: 24));
        widgets.add(
          const Divider(color: Color(0xFFECEFF3), thickness: 1, height: 1),
        );
        widgets.add(const SizedBox(height: 24));
      }
    }

    return widgets;
  }

  List<SettingSection> _getSettingSections() {
    return [
      // Account Section
      SettingSection(
        title: 'ACCOUNT',
        items: [
          SettingItem(
            id: 'edit_profile',
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            type: SettingType.navigation,
            icon: Icons.person_outline,
            onTap: () => _showEditProfile(),
          ),
          SettingItem(
            id: 'family_members',
            title: 'Family Members',
            type: SettingType.navigation,
            icon: Icons.people_outline,
            onTap: () => _navigateToFamilyMembers(),
          ),
          SettingItem(
            id: 'my_vehicles',
            title: 'My Vehicles',
            type: SettingType.navigation,
            icon: Icons.directions_car_outlined,
            onTap: () => _navigateToVehicles(),
          ),
        ],
      ),

      // Preferences Section
      SettingSection(
        title: 'PREFERENCES',
        items: [
          SettingItem(
            id: 'notifications',
            title: 'Notifications',
            type: SettingType.navigation,
            icon: Icons.notifications_outlined,
            onTap: () => _navigateToNotifications(),
          ),
          SettingItem(
            id: 'language',
            title: 'App Language',
            subtitle: 'English',
            type: SettingType.navigation,
            icon: Icons.language_outlined,
            onTap: () => _showLanguageSelector(),
          ),
        ],
      ),

      // Security Section
      SettingSection(
        title: 'SECURITY',
        items: [
          SettingItem(
            id: 'biometric',
            title: 'Biometric Login',
            type: SettingType.toggle,
            icon: Icons.fingerprint,
            toggleValue: _biometricEnabled,
            onToggleChanged: (value) {
              setState(() => _biometricEnabled = value);
              _saveBiometricSetting(value);
            },
          ),
          SettingItem(
            id: 'two_factor',
            title: 'Two-Factor Authentication',
            type: SettingType.status,
            icon: Icons.security_outlined,
            statusText: 'Enabled',
            statusColor: const Color(0xFF22C55E),
            onTap: () => _navigateToTwoFactor(),
          ),
        ],
      ),

      // Payments & Bookings Section
      SettingSection(
        title: 'PAYMENTS & BOOKINGS',
        items: [
          SettingItem(
            id: 'payment_methods',
            title: 'Payment Methods',
            type: SettingType.navigation,
            icon: Icons.credit_card_outlined,
            onTap: () => _navigateToPaymentMethods(),
          ),
          SettingItem(
            id: 'booking_history',
            title: 'Booking History',
            type: SettingType.navigation,
            icon: Icons.history_outlined,
            onTap: () => _navigateToBookingHistory(),
          ),
        ],
      ),

      // Support Section
      SettingSection(
        title: 'SUPPORT',
        items: [
          SettingItem(
            id: 'help',
            title: 'Help & Support',
            type: SettingType.navigation,
            icon: Icons.help_outline,
            onTap: () => _navigateToHelp(),
          ),
          SettingItem(
            id: 'terms',
            title: 'Terms & Privacy',
            type: SettingType.navigation,
            icon: Icons.description_outlined,
            onTap: () => _navigateToTerms(),
          ),
          SettingItem(
            id: 'report',
            title: 'Report an Issue',
            type: SettingType.navigation,
            icon: Icons.bug_report_outlined,
            onTap: () => _showReportIssue(),
          ),
        ],
      ),

      // Account Management Section
      SettingSection(
        title: 'ACCOUNT MANAGEMENT',
        items: [
          SettingItem(
            id: 'manage_account',
            title: 'Manage Account',
            subtitle: 'Delete account and data',
            type: SettingType.destructive,
            icon: Icons.admin_panel_settings_outlined,
            onTap: () => _showDeleteAccountConfirmation(),
          ),
        ],
      ),
    ];
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _showLogoutConfirmation,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF3AA6C8), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3AA6C8),
          ),
        ),
      ),
    );
  }

  // Navigation methods
  void _showEditProfile() {
    // TODO: Load current user profile from your state management or API
    final currentProfile = UserProfile.mock();

    showEditProfileModal(
      context,
      currentProfile: currentProfile,
      onSaved: (updatedProfile) {
        // TODO: Update your state management or sync to backend
        print('Profile updated: ${updatedProfile.toJson()}');

        // Show success message (already shown by modal)
        // You can also update local state here
      },
    );
  }

  void _navigateToFamilyMembers() {
    // TODO: Navigate to Family & Vehicles screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Navigate to Family Members')));
  }

  void _navigateToVehicles() {
    // TODO: Navigate to Vehicles screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Navigate to My Vehicles')));
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsSettingsScreen(),
      ),
    );
  }

  void _showLanguageSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
    );
  }

  void _navigateToTwoFactor() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Two-Factor Authentication - Coming Soon')),
    );
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => TwoFactorSettingsScreen(),
    //   ),
    // );
  }

  void _navigateToPaymentMethods() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Payment Methods')),
    );
  }

  void _navigateToBookingHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Booking History')),
    );
  }

  void _navigateToHelp() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Navigate to Help & Support')));
  }

  void _navigateToTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to Terms & Privacy')),
    );
  }

  void _showReportIssue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report an Issue',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe the issue...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue reported')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E4778),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Perform logout
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3AA6C8),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Perform account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion initiated'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Settings persistence methods (stub - replace with SharedPreferences)
  Future<void> _saveBiometricSetting(bool value) async {
    // TODO: Save to SharedPreferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('biometric_enabled', value);
    print('Biometric: $value');
  }
}
