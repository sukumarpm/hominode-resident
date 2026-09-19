import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../components/app_segmented_control.dart';
import '../components/standard_screen.dart';
import '../services/visitor_firestore_service.dart';
import '../../visitor_qr_screen.dart';
import '../../add_expected_visitor_modal.dart';
import '../providers/language_provider.dart';

/// Pixel-Perfect Visitor Management Screen
/// Based on reference design with exact spacing and colors
/// Now with Firestore integration
class VisitorManagementScreenNew extends StatefulWidget {
  const VisitorManagementScreenNew({super.key});

  @override
  State<VisitorManagementScreenNew> createState() =>
      _VisitorManagementScreenNewState();
}

class _VisitorManagementScreenNewState
    extends State<VisitorManagementScreenNew> {
  int _selectedTabIndex = 0;
  final _visitorService = VisitorFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          body: StandardScreen(
            title: 'visitor_management'.tr(),
            showBackButton: false,
            isScrollable: true,
            padding: EdgeInsets.zero,
            body: Column(
              children: [
                SizedBox(height: 20.h),

                // Segmented Control
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: AppSegmentedControl(
                    segments: [
                      'pending'.tr(),
                      'approved'.tr(),
                      'rejected'.tr(),
                      'deliveries'.tr(),
                    ],
                    selectedIndex: _selectedTabIndex,
                    onChanged: (index) {
                      setState(() => _selectedTabIndex = index);
                    },
                  ),
                ),

                SizedBox(height: 20.h),

                // Content - Stream from Firestore
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildTabContent(languageProvider),
                ),

                SizedBox(height: 100.h), // Space for FAB
              ],
            ),
          ),
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  Widget _buildTabContent(LanguageProvider languageProvider) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _visitorService.streamMyVisitors(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48.w,
                    color: Color(0xFFDC2626),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'error_loading_visitors'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14.sp, color: Color(0xFFA3A3A3)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final allVisitors = snapshot.data ?? [];

        // Filter based on selected tab
        List<Map<String, dynamic>> filteredVisitors;

        if (_selectedTabIndex == 0) {
          // Pending - not approved yet
          filteredVisitors = allVisitors
              .where(
                (v) => v['isApproved'] == false && v['status'] == 'expected',
              )
              .toList();
        } else if (_selectedTabIndex == 1) {
          // Approved - exclude departed/exited visitors
          filteredVisitors = allVisitors
              .where(
                (v) =>
                    v['isApproved'] == true &&
                    v['status'] != 'departed' &&
                    v['status'] != 'exited' &&
                    v['status'] != 'cancelled',
              )
              .toList();
        } else if (_selectedTabIndex == 2) {
          // Rejected - keep declined requests visible to the resident
          filteredVisitors = allVisitors
              .where((v) => v['status'] == 'rejected')
              .toList();
        } else {
          // Deliveries - for now, empty (can be implemented later)
          filteredVisitors = [];
        }

        // Empty state
        if (filteredVisitors.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(32.w),
              child: Column(
                children: [
                  Icon(
                    _selectedTabIndex == 0
                        ? Icons.pending_outlined
                        : _selectedTabIndex == 1
                        ? Icons.check_circle_outline
                        : _selectedTabIndex == 2
                        ? Icons.cancel_outlined
                        : Icons.local_shipping_outlined,
                    size: 64.w,
                    color: const Color(0xFFE5E5E5),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _selectedTabIndex == 0
                        ? 'No pending visitors'
                        : _selectedTabIndex == 1
                        ? 'No approved visitors'
                        : _selectedTabIndex == 2
                        ? 'No rejected visitors'
                        : 'No deliveries',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFA3A3A3),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _selectedTabIndex == 0
                        ? 'Add expected visitors using the + button.\nAdmin will approve your requests.'
                        : _selectedTabIndex == 1
                        ? 'Admin-approved visitors will appear here'
                        : _selectedTabIndex == 2
                        ? 'Visitor requests rejected by management will appear here.'
                        : 'Deliveries will appear here.',
                    style: TextStyle(fontSize: 14.sp, color: Color(0xFFA3A3A3)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Display visitors
        return Column(
          children: filteredVisitors
              .map(
                (visitor) => Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _buildVisitorCard(
                    visitor,
                    languageProvider,
                    isPending: _selectedTabIndex == 0,
                    isApproved: _selectedTabIndex == 1,
                    isRejected: _selectedTabIndex == 2,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  String _formatRejectedAt(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}, '
        '$hour:$minute $period';
  }

  Widget _buildVisitorCard(
    Map<String, dynamic> visitor,
    LanguageProvider languageProvider, {
    bool isPending = false,
    bool isApproved = false,
    bool isRejected = false,
  }) {
    // Extract data from Firestore document
    final visitorId = visitor['id'] as String;
    final visitorName = visitor['visitorName'] as String? ?? 'Unknown';
    final purpose = visitor['purpose'] as String? ?? 'No purpose';
    final expectedArrival = (visitor['expectedArrival'] as Timestamp?)
        ?.toDate();
    final phoneNumber = visitor['phoneNumber'] as String?;
    final rejectedAt = (visitor['rejectedAt'] as Timestamp?)?.toDate();

    // Format time
    String timeText = 'No time set';
    if (expectedArrival != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final visitDate = DateTime(
        expectedArrival.year,
        expectedArrival.month,
        expectedArrival.day,
      );

      final hour = expectedArrival.hour > 12
          ? expectedArrival.hour - 12
          : expectedArrival.hour == 0
          ? 12
          : expectedArrival.hour;
      final minute = expectedArrival.minute.toString().padLeft(2, '0');
      final period = expectedArrival.hour >= 12 ? 'PM' : 'AM';

      if (visitDate == today) {
        timeText = '$hour:$minute $period Today';
      } else if (visitDate == today.add(const Duration(days: 1))) {
        timeText = '$hour:$minute $period Tomorrow';
      } else {
        timeText =
            '$hour:$minute $period ${expectedArrival.day}/${expectedArrival.month}';
      }
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    visitorName.isNotEmpty ? visitorName[0].toUpperCase() : 'V',
                    style: TextStyle(
                      color: Color(0xFF0E4778),
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitorName,
                      style: TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      purpose,
                      style: TextStyle(
                        color: Color(0xFFA3A3A3),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14.w,
                          color: Color(0xFFA3A3A3),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          timeText,
                          style: TextStyle(
                            color: Color(0xFFA3A3A3),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    // Show phone if available
                    if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14.w,
                            color: Color(0xFFA3A3A3),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color: Color(0xFFA3A3A3),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isRejected && rejectedAt != null) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 14.w,
                            color: const Color(0xFFDC2626),
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              'Rejected ${_formatRejectedAt(rejectedAt)}',
                              style: TextStyle(
                                color: const Color(0xFFDC2626),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status Badge
              if (isPending)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6EB),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Awaiting Approval',
                    style: TextStyle(
                      color: Color(0xFFE11D48),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (isApproved)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Approved',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (isRejected)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Rejected',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          // Action Buttons
          if (isPending) ...[
            SizedBox(height: 16.h),
            // Only show Reject button - Admin approves, not user
            _buildRejectButton(visitorId, visitorName),
          ],

          if (isApproved) ...[
            SizedBox(height: 16.h),
            _buildViewQRButton(visitor),
          ],
        ],
      ),
    );
  }

  Widget _buildRejectButton(String visitorId, String visitorName) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: OutlinedButton(
        onPressed: () => _rejectVisitor(visitorId, visitorName),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFDC2626),
          side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          'Cancel Request',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildViewQRButton(Map<String, dynamic> visitor) {
    final visitorId = visitor['id'] as String? ?? '';

    if (visitorId.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: OutlinedButton.icon(
        onPressed: () {
          debugPrint('🔵 Opening QR screen for visitor ID: $visitorId');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisitorQRScreen(visitorId: visitorId),
            ),
          );
        },
        icon: Icon(Icons.qr_code_2, size: 20.w),
        label: Text(
          'View QR Pass',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0E4778),
          side: const BorderSide(color: Color(0xFF0E4778), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      width: 56.w,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E4778), Color(0xFF061C4C)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E4778).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Show modal - stream will automatically update on success
            await showAddExpectedVisitorModal(context);
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Icon(Icons.add, color: Colors.white, size: 28.w),
        ),
      ),
    );
  }

  Future<void> _rejectVisitor(String visitorId, String visitorName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Visitor Request'),
        content: Text(
          'Are you sure you want to cancel the visitor request for $visitorName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Delete visitor from Firestore
      final result = await _visitorService.deleteVisitor(visitorId);

      // Close loading
      if (mounted) Navigator.pop(context);

      if (result.success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Visitor request for $visitorName cancelled'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Failed to cancel request'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading if still open
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }
    }
  }
}

// ============================================================================
// DELIVERY CLASS - FOR FUTURE IMPLEMENTATION
// ============================================================================
// This class is reserved for the Deliveries tab feature (Tab 4)
// Currently, the Deliveries tab shows an empty state
// Implement delivery tracking functionality here when needed

class Delivery {
  final String id;
  final String title;
  final String subtitle;
  final DateTime dateTime;
  final bool isReceived;

  Delivery({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.dateTime,
    required this.isReceived,
  });
}