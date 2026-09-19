// lib/profile_screen.dart
// Profile / Settings screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'community_wall_screen.dart';
import 'src/providers/language_provider.dart';
import 'src/screens/app_settings_screen.dart';
import 'src/screens/documents_circulars_screen.dart';
import 'src/screens/domestic_staff_screen.dart';
import 'src/screens/edit_profile_screen.dart';
import 'src/screens/family_vehicles_screen.dart';
import 'src/screens/marketplace_screen.dart';
import 'src/screens/my_bookings_screen.dart';
import 'src/screens/notifications_settings_screen.dart';
import 'src/services/announcements_events_service.dart';
import 'src/services/firebase_auth_service.dart';
import 'src/services/organization_service.dart';
import 'src/services/profile_image_service.dart';
import 'src/services/tenant_resolution_service.dart';

// ============================================================================
// THEME CONSTANTS
// ============================================================================
const Color kPrimaryBlue = Color(0xFF0E4778);
const Color kCardWhite = Color(0xFFFFFFFF);
const Color kBackgroundGrey = Color(0xFFF7F7F7);
const Color kBorderColor = Color(0xFFE6E6E6);
const Color kTextPrimary = Color(0xFF111111);
const Color kTextMuted = Color(0xFF9B9B9B);
const double kPadding = 16.0;
const double kGap = 12.0;
const double kCardRadius = 12.0;

// ============================================================================
// PROFILE SCREEN
// ============================================================================
class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({super.key, this.showBackButton = false});

  static MaterialPageRoute route() {
    return MaterialPageRoute(
      builder: (_) => const ProfileScreen(showBackButton: true),
    );
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = FirebaseAuthService();
  final _organizationService = OrganizationService();
  final _eventsService = AnnouncementsEventsService();
  Map<String, dynamic>? _userProfile;
  String _organizationName = 'Your Apartment'; // Default fallback
  bool _isLoading = true;
  late bool _isLoggingOut = false;
  String? _userId; // Track user ID for image streaming
  int _points = 0;
  int _eventsCount = 0;
  int _badges = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    print('🔵 PROFILE SCREEN LOAD FLOW: Starting...');
    setState(() => _isLoading = true);
    final tenantName = context.read<TenantResolutionService>().current?.name;

    try {
      // STEP 1: Fetch the authenticated resident's canonical user document.
      print('📥 STEP 1: Fetching user data from Firestore...');
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw StateError('No authenticated resident');
      }

      final userId = firebaseUser.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userData = userDoc.data();

      if (!userDoc.exists || userData == null) {
        print('❌ STEP 1 FAILED: No user data found');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'User profile not found. Please contact administrator.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      print('✅ STEP 1 PASSED: User data loaded');
      print('   Name: ${userData['name']}');
      print('   Email: ${userData['email']}');
      print('   Phone: ${userData['phone']}');
      print('   Flat: ${userData['flatLabel'] ?? userData['flatId']}');
      print('   Community: ${userData['communityId']}');
      print('   Building: ${userData['buildingId']}');

      // STEP 2: Load independent profile extras in parallel.
      final communityId = userData['communityId'] as String? ?? '';
      final organizationFuture = tenantName?.isNotEmpty == true
          ? Future<String>.value(tenantName)
          : _organizationService.getOrganizationNameForUser(userId).catchError((
              Object error,
            ) {
              print('⚠️ Could not fetch organization name: $error');
              return 'Your Apartment';
            });
      final eventsFuture = _eventsService
          .getVisibleEventsCount(communityId)
          .catchError((Object error) {
            print(
              '⚠️ Could not count events using events/communityId/status query: '
              '$error',
            );
            return 0;
          });
      final results = await Future.wait<Object>([
        organizationFuture,
        eventsFuture,
      ]);
      final organizationName = results[0] as String;
      final eventsCount = results[1] as int;

      // TODO: Set this from a confirmed resident points backend when available.
      const points = 0;
      // TODO: Set this from a confirmed resident badge backend when available.
      const badges = 0;

      // STEP 3: Update UI with data
      print('🎨 STEP 3: Updating UI with profile data...');
      if (mounted) {
        setState(() {
          _userId = userId; // Store user ID for image streaming
          _userProfile = {
            'name': userData['name'] ?? 'User',
            'email': userData['email'] ?? '',
            'phone': userData['phone'] ?? '',
            'flatNumber':
                userData['flatLabel'] ?? userData['flatId'] ?? 'Not Set',
          };
          _organizationName = organizationName;
          _points = points;
          _eventsCount = eventsCount;
          _badges = badges;
          _isLoading = false;
        });

        print('✅ STEP 3 PASSED: UI updated with data');
        print('');
        print('✅ PROFILE SCREEN LOAD FLOW: COMPLETE');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR in PROFILE SCREEN LOAD FLOW: $e');
      print('   Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String get _userName => _userProfile?['name'] ?? 'User';
  String get _userPhone => _userProfile?['phone'] ?? '';
  String get _userFlat => _userProfile?['flatNumber'] ?? 'Not Set';

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.black,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Column(
              children: [
                Container(
                  color: Colors.black,
                  height: MediaQuery.of(context).padding.top,
                ),
                Expanded(
                  child: Container(
                    color: kBackgroundGrey,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildHeader(),
                                _buildStatsRow(),
                                Padding(
                                  padding: const EdgeInsets.all(kPadding),
                                  child: Column(
                                    children: [
                                      _buildSettingCard(
                                        icon: Icons.person_outline,
                                        iconBg: const Color(0xFFDBEAFE),
                                        iconColor: const Color(0xFF3B82F6),
                                        title: 'edit_profile'.tr(),
                                        onTap: () => _showEditProfile(context),
                                      ),
                                      const SizedBox(height: kGap),
                                      _buildSettingCard(
                                        icon: Icons.people_outline,
                                        iconBg: const Color(0xFFEDE9FF),
                                        iconColor: const Color(0xFF8B5CF6),
                                        title: 'family_members_vehicles'.tr(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const FamilyVehiclesScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: kGap),
                                      _buildSettingCard(
                                        icon: Icons.cleaning_services_outlined,
                                        iconBg: const Color(0xFFFFF3E8),
                                        iconColor: const Color(0xFFF97316),
                                        title: 'domestic_staff'.tr(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const DomesticStaffScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: kGap),
                                      _buildSettingCard(
                                        icon: Icons.bookmark_outline,
                                        iconBg: const Color(0xFFFCE7F3),
                                        iconColor: const Color(0xFFEC4899),
                                        title: 'my_bookings'.tr(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const MyBookingsScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: kGap),
                                      _buildSettingCard(
                                        icon: Icons.description_outlined,
                                        iconBg: const Color(0xFFDCFCE7),
                                        iconColor: const Color(0xFF16A34A),
                                        title: 'documents_circulars'.tr(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const DocumentsCircularsScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: kGap),
                                      _buildSettingCard(
                                        icon: Icons.groups_outlined,
                                        iconBg: const Color(0xFFEDE9FF),
                                        iconColor: const Color(0xFF8B5CF6),
                                        title: 'community_wall'.tr(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const CommunityWallScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: kGap),
                                      _buildSettingCard(
                                        icon: Icons.shopping_bag_outlined,
                                        iconBg: const Color(0xFFFFF9E6),
                                        iconColor: const Color(0xFFFDB022),
                                        title: 'marketplace'.tr(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const MarketplaceScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: kGap),
                                      _buildSettingCard(
                                        icon: Icons.notifications_outlined,
                                        iconBg: const Color(0xFFF3F4F6),
                                        iconColor: const Color(0xFF6B7280),
                                        title: 'notifications'.tr(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const NotificationsSettingsScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: kGap),
                                      _buildSettingCard(
                                        icon: Icons.settings_outlined,
                                        iconBg: const Color(0xFFF3F4F6),
                                        iconColor: const Color(0xFF6B7280),
                                        title: 'settings'.tr(),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AppSettingsScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 24.h),
                                      _buildLogoutButton(
                                        context,
                                        languageProvider,
                                      ),
                                      SizedBox(height: 100.h),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
          children: [
            // Time and status bar placeholder
            SizedBox(height: 8.h),

            // Avatar and user info with real-time image streaming
            Row(
              children: [
                if (widget.showBackButton && Navigator.canPop(context)) ...[
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20.w,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 40.w,
                      minHeight: 44.h,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                // StreamBuilder for real-time image fetching
                _userId != null
                    ? StreamBuilder<ProfileImageResult>(
                        stream: ProfileImageService.instance.streamProfileImage(
                          userId: _userId!,
                        ),
                        builder: (context, snapshot) {
                          print('🔵 ProfileScreen: Image stream update');

                          // Loading state
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            print('⏳ ProfileScreen: Image stream loading...');
                            return CircleAvatar(
                              radius: 28.r,
                              backgroundColor: Colors.white,
                              child: SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0E4778),
                                  ),
                                ),
                              ),
                            );
                          }

                          // Error or no data state
                          if (!snapshot.hasData || snapshot.data == null) {
                            print('⚠️ ProfileScreen: No image data in stream');
                            return CircleAvatar(
                              radius: 28.r,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 32.w,
                                color: Color(0xFF0E4778),
                              ),
                            );
                          }

                          final result = snapshot.data!;

                          // Success state - image found
                          if (result.success && result.imageUrl != null) {
                            print(
                              '✅ ProfileScreen: Image URL received: ${result.imageUrl}',
                            );
                            return CircleAvatar(
                              radius: 28.r,
                              backgroundColor: Colors.white,
                              backgroundImage: NetworkImage(result.imageUrl!),
                            );
                          }

                          // Failure state - no image
                          print('❌ ProfileScreen: ${result.message}');
                          return CircleAvatar(
                            radius: 28.r,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 32.w,
                              color: Color(0xFF0E4778),
                            ),
                          );
                        },
                      )
                    : CircleAvatar(
                        radius: 28.r,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 32.w,
                          color: Color(0xFF0E4778),
                        ),
                      ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_userPhone.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          _userPhone,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Apartment card
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _organizationName, // Dynamic organization name
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _userFlat,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.all(kPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile(
              value: '$_points',
              label: 'Points',
              gradient: const LinearGradient(
                colors: [Color(0xFFE8FDEB), Color(0xFFD1FAE5)],
              ),
              textColor: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: kGap),
          Expanded(
            child: _buildStatTile(
              value: '$_eventsCount',
              label: 'Events',
              gradient: const LinearGradient(
                colors: [Color(0xFFF3E8FF), Color(0xFFEDE9FF)],
              ),
              textColor: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: kGap),
          Expanded(
            child: _buildStatTile(
              value: '$_badges',
              label: 'Badges',
              gradient: const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFDBEAFE)],
              ),
              textColor: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String value,
    required String label,
    required Gradient gradient,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(kCardRadius),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: kCardWhite,
      borderRadius: BorderRadius.circular(kCardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kCardRadius),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            border: Border.all(color: kBorderColor, width: 1),
            borderRadius: BorderRadius.circular(kCardRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.w),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: kTextPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: kTextMuted, size: 24.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: OutlinedButton(
        onPressed: _isLoggingOut ? null : () => _handleLogout(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimaryBlue,
          side: BorderSide(
            color: _isLoggingOut
                ? kPrimaryBlue.withValues(alpha: 0.4)
                : kPrimaryBlue,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kCardRadius),
          ),
        ),
        child: _isLoggingOut
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: kPrimaryBlue,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Signing out…',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'logout'.tr(),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || _isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _authService.signOut(context.read<TenantResolutionService>());

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to logout. Please try again.')),
      );
    }
  }

  void _showEditProfile(BuildContext context) async {
    // Navigate to Edit Profile screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );

    // Reload profile if changes were made
    if (result == true) {
      _loadUserProfile();
    }
  }
}

// ============================================================================
// USAGE
// ============================================================================
// 1. File location: lib/profile_screen.dart
// 2. Assets: None required (uses Material Icons)
// 3. Usage: Navigator.push(context, ProfileScreen.route());
