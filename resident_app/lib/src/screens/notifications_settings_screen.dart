// lib/src/screens/notifications_settings_screen.dart
// Notifications Preferences Screen

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Uncomment when ready to use
import '../components/standard_screen.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  // Only essential notifications
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Notification Settings',
      isScrollable: true,
      padding: EdgeInsets.all(16.w),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationsCard(),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildOldHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E4778), Color(0xFF061C4C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 16.h, 16.w, 20.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20.w,
                ),
                padding: EdgeInsets.all(8.w),
              ),
              SizedBox(width: 4.w),
              Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: Color(0xFF3B82F6),
                    size: 22.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildToggleRow(
            title: 'Push Notifications',
            subtitle: 'Get notified about updates',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _savePreference('push_notifications', value);
            },
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE5E7EB),
            indent: 16,
            endIndent: 16,
          ),
          _buildToggleRow(
            title: 'Email Notifications',
            subtitle: 'Receive emails about bills',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
              _savePreference('email_notifications', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13.sp, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF3B82F6),
            activeTrackColor: const Color(0xFFDBEAFE),
          ),
        ],
      ),
    );
  }

  // Persistence Methods
  Future<void> _loadPreferences() async {
    // TODO: Load from SharedPreferences
    print('📥 Loading notification preferences...');
  }

  Future<void> _savePreference(String key, bool value) async {
    // TODO: Save to SharedPreferences
    print('💾 Saved $key: $value');
  }
}
