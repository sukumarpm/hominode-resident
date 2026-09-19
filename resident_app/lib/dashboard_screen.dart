import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hominode_sos/hominode_sos.dart';
import 'package:provider/provider.dart';

import 'community_wall_screen.dart';
import 'complaints_screen.dart';
import 'src/screens/amenities_booking_screen.dart';
import 'src/screens/emergency_sos_screen.dart';
import 'src/screens/marketplace_screen.dart';
import 'src/screens/messages_screen.dart';
import 'src/screens/notifications_screen.dart';
import 'src/services/apartment_images_service.dart';
import 'src/services/bill_firestore_service.dart';
import 'src/services/complaint_firestore_service.dart';
import 'src/services/recent_activity_flow_function.dart';
import 'src/services/tenant_resolution_service.dart';
import 'src/services/visitor_firestore_service.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const Color _navy = Color(0xFF082F73);
  static const Color _blue = Color(0xFF1558D6);
  static const Color _cyan = Color(0xFF2B95C8);
  static const Color _ink = Color(0xFF0E2247);
  static const Color _muted = Color(0xFF667792);
  static const Color _pageBg = Color(0xFFF7F9FD);

  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Future<List<dynamic>> _recentActivityFuture;

  final _billService = BillFirestoreService();
  final _visitorService = VisitorFirestoreService();
  final _complaintService = ComplaintFirestoreService();
  final _apartmentImagesService = ApartmentImagesService();

  String _userName = 'User';
  String _userFlat = 'Not Set';
  String _organizationName = 'Your Apartment';
  bool _isLoading = true;

  double _pendingBillAmount = 0;
  int _visitorTodayCount = 0;
  int _openComplaintCount = 0;
  List<String> _bannerImages = [];

  @override
  void initState() {
    super.initState();
    _recentActivityFuture = _fetchRecentActivities();
    _loadDashboardData();
    _loadApartmentImages();
    Future.delayed(const Duration(seconds: 5), _autoScroll);
  }

  Future<void> _loadDashboardData() async {
    if (mounted) setState(() => _isLoading = true);
    final tenantName = context.read<TenantResolutionService>().current?.name;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? 'User';
      final userFlat = userData['flatLabel'] ?? userData['flatId'] ?? 'Not Set';
      final userOrganization = (userData['organization'] as String?)?.trim();
      var organizationName = tenantName?.isNotEmpty == true
          ? tenantName!
          : userOrganization?.isNotEmpty == true
          ? userOrganization!
          : 'Your Apartment';

      final communityId = (userData['communityId'] as String?)?.trim();
      if (communityId?.isNotEmpty == true) {
        try {
          final communityDoc = await FirebaseFirestore.instance
              .collection('communities')
              .doc(communityId)
              .get();
          final communityName = (communityDoc.data()?['name'] as String?)
              ?.trim();
          if (communityDoc.exists && communityName?.isNotEmpty == true) {
            organizationName = communityName!;
          }
        } catch (error) {
          debugPrint(
            'Dashboard community lookup failed for $communityId: $error',
          );
        }
      }

      final currentBill = await _billService.getCurrentBill();
      final billAmount = currentBill != null
          ? (currentBill['amount'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      final results = await Future.wait<dynamic>([
        _visitorService.getMyVisitors(),
        _complaintService.getMyComplaints(),
      ]);

      final visitors = results[0] as List<Map<String, dynamic>>;
      final complaints = results[1] as List;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final visitorsToday = visitors.where((visitor) {
        final expectedArrival = visitor['expectedArrival'];
        DateTime? visitDate;
        if (expectedArrival is Timestamp) {
          visitDate = expectedArrival.toDate();
        } else if (expectedArrival is DateTime) {
          visitDate = expectedArrival;
        }
        if (visitDate == null) return false;
        return visitDate.isAfter(todayStart) && visitDate.isBefore(todayEnd);
      }).length;

      final openComplaints = complaints.where((complaint) {
        if (complaint is Map) {
          final status = complaint['status'] as String?;
          return status == 'pending' ||
              status == 'in-progress' ||
              status == 'inProgress';
        }
        final status = (complaint as dynamic).status?.toString() ?? '';
        return status == 'pending' ||
            status == 'in-progress' ||
            status == 'inProgress';
      }).length;

      if (mounted) {
        setState(() {
          _userName = userName;
          _userFlat = userFlat;
          _organizationName = organizationName;
          _pendingBillAmount = billAmount;
          _visitorTodayCount = visitorsToday;
          _openComplaintCount = openComplaints;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Dashboard load error: $e');
      debugPrint('$stackTrace');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadApartmentImages() async {
    try {
      final result = await _apartmentImagesService.getApartmentImages();
      if (!result.success) {
        if (mounted) setState(() => _bannerImages = []);
        return;
      }
      if (mounted) {
        setState(() => _bannerImages = result.imageUrls ?? []);
      }
    } catch (e) {
      debugPrint('Apartment image load error: $e');
      if (mounted) setState(() => _bannerImages = []);
    }
  }

  void _autoScroll() {
    if (!mounted) return;
    if (_bannerImages.length < 2) {
      Future.delayed(const Duration(seconds: 5), _autoScroll);
      return;
    }

    final nextPage = (_currentPage + 1) % _bannerImages.length;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    }
    Future.delayed(const Duration(seconds: 5), _autoScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _pageBg,
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_loadDashboardData(), _loadApartmentImages()]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroAndBanner(),
                SizedBox(height: 12.h),
                SosEntryButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const EmergencySosScreen(),
                    ),
                  ),
                ),
                _buildSummaryCards(),
                SizedBox(height: 20.h),
                _buildQuickAccessSection(),
                SizedBox(height: 18.h),
                _buildRecentActivitySection(),
                SizedBox(height: 110.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAndBanner() {
    final topInset = MediaQuery.of(context).padding.top;

    // Keep header + banner to roughly 45-48% of an iPhone-height screen.
    // The Stack itself reserves the banner's full height, so following widgets
    // can never overlap it.
    final heroHeight = 230.h + topInset;
    final bannerHeight = 150.h;
    final bannerTop = heroHeight - 24.h;
    final indicatorSpace = 22.h;
    final totalHeight = bannerTop + bannerHeight + indicatorSpace;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: heroHeight,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B376C),
                  Color(0xFF103F78),
                  Color(0xFF2CA4C7),
                ],
                stops: [0.05, 0.60, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -45.w,
                  top: topInset + 8.h,
                  child: Container(
                    width: 220.w,
                    height: 125.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    topInset + 10.h,
                    20.w,
                    18.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: _notificationButton(),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'good_morning'.tr(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Hi, $_userName!',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23.sp,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text('👋', style: TextStyle(fontSize: 21.sp)),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Welcome back to your community',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 12.5.sp,
                        ),
                      ),
                      SizedBox(height: 9.h),
                      _apartmentCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 16.w,
            right: 16.w,
            top: bannerTop,
            child: _bannerCard(height: bannerHeight),
          ),
        ],
      ),
    );
  }

  Widget _notificationButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(13.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: _blue,
              size: 23.w,
            ),
          ),
          Positioned(
            right: 7.w,
            top: 7.h,
            child: Container(
              width: 8.w,
              height: 8.w,
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B3B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _apartmentCard() {
    return Container(
      width: 245.w,
      constraints: BoxConstraints(minHeight: 62.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(color: Colors.white.withOpacity(0.40), width: 1.1),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: const Color(0xFF0D4EA8).withOpacity(0.86),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.apartment_rounded,
              color: Colors.white,
              size: 23.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _organizationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _userFlat,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white, size: 25.w),
        ],
      ),
    );
  }

  Widget _bannerCard({required double height}) {
    return Column(
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E2247).withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: _bannerImages.isEmpty
                ? _bannerEmptyState()
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _bannerImages.length,
                    onPageChanged: (index) {
                      if (mounted) setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        _bannerImages[index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: const Color(0xFFEFF3F8),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _bannerEmptyState(
                            title: 'failed_to_load_image'.tr(),
                            icon: Icons.broken_image_outlined,
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
        SizedBox(height: 10.h),
        if (_bannerImages.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerImages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: _currentPage == index ? 8.w : 7.w,
                height: _currentPage == index ? 8.w : 7.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? _blue
                      : const Color(0xFFD6DAE2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _bannerEmptyState({
    String? title,
    IconData icon = Icons.apartment_rounded,
  }) {
    return Container(
      color: const Color(0xFFF0F4F9),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF9BA8BA), size: 44.w),
          SizedBox(height: 8.h),
          Text(
            title ?? 'no_images_available'.tr(),
            style: TextStyle(
              color: const Color(0xFF75849A),
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(
            child: _summaryCard(
              icon: Icons.receipt_long_rounded,
              iconColor: const Color(0xFF08A760),
              iconBg: const Color(0xFFE2F8EA),
              value: _pendingBillAmount > 0
                  ? '₹${_pendingBillAmount.toStringAsFixed(0)}'
                  : '₹0',
              label: 'billing'.tr(),
              onTap: () => widget.onTabChange?.call(2),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _summaryCard(
              icon: Icons.groups_2_outlined,
              iconColor: const Color(0xFF7848F5),
              iconBg: const Color(0xFFEDE5FF),
              value: '$_visitorTodayCount',
              label: 'visitors'.tr(),
              onTap: () => widget.onTabChange?.call(1),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _summaryCard(
              icon: Icons.support_agent_rounded,
              iconColor: const Color(0xFF1568E9),
              iconBg: const Color(0xFFE7F0FF),
              value: '$_openComplaintCount',
              label: 'complaints'.tr(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComplaintsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          constraints: BoxConstraints(minHeight: 108.h),
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 10.w, 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A3A64).withOpacity(0.075),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24.w),
              ),
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF34445D),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 29.w,
                    height: 29.w,
                    decoration: BoxDecoration(
                      color: iconBg.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: iconColor,
                      size: 21.w,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    final items = <_QuickAccessItemData>[
      _QuickAccessItemData(
        icon: Icons.groups_2_outlined,
        label: 'visitors'.tr(),
        iconColor: const Color(0xFF1568E9),
        backgroundColor: const Color(0xFFE7F0FF),
        onTap: () => widget.onTabChange?.call(1),
      ),
      _QuickAccessItemData(
        icon: Icons.receipt_long_outlined,
        label: 'billing'.tr(),
        iconColor: const Color(0xFF08A760),
        backgroundColor: const Color(0xFFE2F8EA),
        onTap: () => widget.onTabChange?.call(2),
      ),
      _QuickAccessItemData(
        icon: Icons.calendar_month_rounded,
        label: 'events'.tr(),
        iconColor: const Color(0xFF7848F5),
        backgroundColor: const Color(0xFFEDE5FF),
        onTap: () => widget.onTabChange?.call(3),
      ),
      _QuickAccessItemData(
        icon: Icons.support_agent_rounded,
        label: 'complaints'.tr(),
        iconColor: const Color(0xFFF26A21),
        backgroundColor: const Color(0xFFFFEFE4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComplaintsScreen()),
          );
        },
      ),
      _QuickAccessItemData(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'messages'.tr(),
        iconColor: const Color(0xFFF26A21),
        backgroundColor: const Color(0xFFFFEFE4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MessagesScreenEnhanced()),
          );
        },
      ),
      _QuickAccessItemData(
        icon: Icons.groups_rounded,
        label: 'community_wall'.tr(),
        iconColor: const Color(0xFF7848F5),
        backgroundColor: const Color(0xFFEDE5FF),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommunityWallScreen()),
          );
        },
      ),
      _QuickAccessItemData(
        icon: Icons.fitness_center_outlined,
        label: 'amenities'.tr(),
        iconColor: const Color(0xFF08A760),
        backgroundColor: const Color(0xFFE2F8EA),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AmenitiesBookingScreen()),
          );
        },
      ),
      _QuickAccessItemData(
        icon: Icons.shopping_bag_outlined,
        label: 'marketplace'.tr(),
        iconColor: const Color(0xFF1568E9),
        backgroundColor: const Color(0xFFE7F0FF),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
          );
        },
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'quick_access'.tr(),
                style: TextStyle(
                  color: _ink,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              // Text(
              //   'View All',
              //   style: TextStyle(
              //     color: _blue,
              //     fontSize: 13.sp,
              //     fontWeight: FontWeight.w700,
              //   ),
              // ),
            ],
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 0.87,
            ),
            itemBuilder: (context, index) => _quickAccessCard(items[index]),
          ),
        ],
      ),
    );
  }

  Widget _quickAccessCard(_QuickAccessItemData item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 11.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF193A65).withOpacity(0.055),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  color: item.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.iconColor, size: 24.w),
              ),
              SizedBox(height: 8.h),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: 11.5.sp,
                    height: 1.05,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(15.w, 14.h, 15.w, 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF193A65).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'recent_activity'.tr(),
                  style: TextStyle(
                    color: _ink,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // const Spacer(),
                // TextButton(
                //   onPressed: () {},
                //   style: TextButton.styleFrom(
                //     padding: EdgeInsets.zero,
                //     minimumSize: Size(52.w, 30.h),
                //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                //   ),
                //   child: Text(
                //     'View All',
                //     style: TextStyle(
                //       color: _blue,
                //       fontSize: 13.sp,
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                // ),
              ],
            ),
            FutureBuilder<List<dynamic>>(
              future: _recentActivityFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final activities = snapshot.data ?? [];
                if (activities.isEmpty) return _emptyRecentActivity();

                return Column(
                  children: List.generate(
                    activities.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(top: index == 0 ? 6.h : 10.h),
                      child: _activityItemFromData(activities[index]),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyRecentActivity() {
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 4.h, 4.w, 2.h),
      child: Row(
        children: [
          Container(
            width: 72.w,
            height: 58.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: const Color(0xFF75A2F4),
              size: 34.w,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No recent activities',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "You're all caught up!",
                  style: TextStyle(color: _muted, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> _fetchRecentActivities() async {
    try {
      final result = await RecentActivityFlowFunction.instance
          .fetchRecentActivities(limit: 5);
      return result.success ? result.activities : [];
    } catch (e) {
      debugPrint('Recent activity error: $e');
      return [];
    }
  }

  Widget _activityItemFromData(dynamic activity) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    if (activity.activityType == 'booking') {
      icon = Icons.calendar_today;
      iconColor = const Color(0xFF7848F5);
      iconBg = const Color(0xFFEDE5FF);
    } else if (activity.activityType == 'visitor') {
      icon = Icons.shield_outlined;
      iconColor = const Color(0xFFF26A21);
      iconBg = const Color(0xFFFFEFE4);
    } else if (activity.activityType == 'complaint') {
      icon = Icons.warning_amber_rounded;
      iconColor = const Color(0xFFE54848);
      iconBg = const Color(0xFFFFE8E8);
    } else {
      icon = Icons.info_outline_rounded;
      iconColor = const Color(0xFF1568E9);
      iconBg = const Color(0xFFE7F0FF);
    }

    final status = activity.statusText.toLowerCase();
    late Color statusColor;
    late Color statusBg;

    if (status.contains('confirmed') ||
        status.contains('approved') ||
        status.contains('received')) {
      statusColor = const Color(0xFF08A760);
      statusBg = const Color(0xFFE2F8EA);
    } else if (status.contains('pending')) {
      statusColor = const Color(0xFFE39513);
      statusBg = const Color(0xFFFFF2D6);
    } else if (status.contains('rejected') || status.contains('cancelled')) {
      statusColor = const Color(0xFFE54848);
      statusBg = const Color(0xFFFFE8E8);
    } else {
      statusColor = const Color(0xFF1568E9);
      statusBg = const Color(0xFFE7F0FF);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(13.r),
          ),
          child: Icon(icon, color: iconColor, size: 22.w),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                activity.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _muted,
                  fontSize: 11.5.sp,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Text(
            activity.statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAccessItemData {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _QuickAccessItemData({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });
}
