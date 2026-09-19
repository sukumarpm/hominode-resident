// lib/src/screens/notifications_screen.dart
// Notifications screen matching app design standards

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/notice_model.dart';
import '../services/notice_firestore_service.dart';
import '../components/primary_header.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NoticeModel> _allNotices = [];
  bool _isLoading = true;
  final NoticeFirestoreService _noticeService = NoticeFirestoreService.instance;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      print('========================================');
      print('🔵 NOTIFICATIONS SCREEN: Loading notifications');
      print('========================================');
      print('🔵 Calling NoticeFirestoreService.getNotices()...');

      final notices = await _noticeService.getNotices();

      print('🔵 NoticeFirestoreService returned ${notices.length} notices');

      if (mounted) {
        setState(() {
          _allNotices = notices;
          _isLoading = false;
        });
        print('✅ UI updated with ${notices.length} notifications');
        print('========================================');
      }
    } catch (e, stackTrace) {
      print('❌ NOTIFICATIONS SCREEN ERROR: $e');
      print('   Stack trace: $stackTrace');
      print('========================================');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNoticeDetail(NoticeModel notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notice.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category and Priority badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Category badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getIconBgColorForCategory(notice.category),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForCategory(notice.category),
                          size: 14.w,
                          color: _getIconColorForCategory(notice.category),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _getCategoryLabel(notice.category),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _getIconColorForCategory(notice.category),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Priority badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityBgColor(notice.priority),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      _getPriorityLabel(notice.priority),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _getPriorityTextColor(notice.priority),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Content
              Text(
                notice.content,
                style: TextStyle(fontSize: 15.sp, height: 1.5),
              ),
              SizedBox(height: 16.h),
              // Author
              if (notice.authorName.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16.w,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Posted by: ${notice.authorName}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],
              // Published date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16.w,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Published: ${_formatFullDate(notice.publishDate)}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Expiry date
              if (notice.expiryDate != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 16.w,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Expires: ${_formatFullDate(notice.expiryDate!)}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              // Attachments
              if (notice.attachments.isNotEmpty) ...[
                SizedBox(height: 16.h),
                const Divider(),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16.w,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Attachments (${notice.attachments.length})',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ...notice.attachments.map(
                  (attachment) => Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      '• $attachment',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getCategoryLabel(String category) {
    final cat = category.toLowerCase();
    if (cat == 'maintenance') return 'Maintenance';
    if (cat == 'event') return 'Event';
    if (cat == 'emergency') return 'Emergency';
    if (cat == 'urgent') return 'Urgent';
    if (cat == 'billing') return 'Billing';
    if (cat == 'security') return 'Security';
    return 'General';
  }

  String _getPriorityLabel(String priority) {
    final p = priority.toLowerCase();
    if (p == 'urgent' || p == 'high') return 'URGENT';
    if (p == 'medium') return 'MEDIUM';
    if (p == 'low') return 'LOW';
    return priority.toUpperCase();
  }

  Color _getPriorityBgColor(String priority) {
    final p = priority.toLowerCase();
    if (p == 'urgent' || p == 'high') return const Color(0xFFFEE2E2);
    if (p == 'medium') return const Color(0xFFFEF3C7);
    if (p == 'low') return const Color(0xFFE0F2FE);
    return const Color(0xFFF3F4F6);
  }

  Color _getPriorityTextColor(String priority) {
    final p = priority.toLowerCase();
    if (p == 'urgent' || p == 'high') return const Color(0xFFDC2626);
    if (p == 'medium') return const Color(0xFFD97706);
    if (p == 'low') return const Color(0xFF0284C7);
    return const Color(0xFF6B7280);
  }

  IconData _getIconForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat == 'maintenance') return Icons.build_outlined;
    if (cat == 'event') return Icons.event_outlined;
    if (cat == 'emergency' || cat == 'urgent') {
      return Icons.warning_amber_outlined;
    }
    if (cat == 'billing') return Icons.receipt_outlined;
    if (cat == 'security') return Icons.security_outlined;
    return Icons.notifications_outlined;
  }

  Color _getIconBgColorForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat == 'maintenance') return const Color(0xFFFFF3E8);
    if (cat == 'event') return const Color(0xFFEDE9FF);
    if (cat == 'emergency' || cat == 'urgent') return const Color(0xFFFEE2E2);
    if (cat == 'billing') return const Color(0xFFE8FDEB);
    if (cat == 'security') return const Color(0xFFFEE2E2);
    return const Color(0xFFEAF1FF);
  }

  Color _getIconColorForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat == 'maintenance') return const Color(0xFFF97316);
    if (cat == 'event') return const Color(0xFF8B5CF6);
    if (cat == 'emergency' || cat == 'urgent') return const Color(0xFFDC2626);
    if (cat == 'billing') return const Color(0xFF10B981);
    if (cat == 'security') return const Color(0xFFDC2626);
    return const Color(0xFF0E4778);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = [
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
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const PrimaryHeader(title: 'Notifications'),
          SizedBox(height: 20.h),
          // Notifications list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allNotices.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSizes.pagePadding,
                        0,
                        AppSizes.pagePadding,
                        AppSizes.pagePadding,
                      ),
                      itemCount: _allNotices.length,
                      itemBuilder: (context, index) {
                        final notice = _allNotices[index];

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _NoticeCard(
                            notice: notice,
                            onTap: () => _showNoticeDetail(notice),
                            formatDate: _formatDate,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64.w,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You\'re all caught up!',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NOTICE CARD - MATCHING APP DESIGN STANDARDS
// ============================================================================
class _NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  const _NoticeCard({
    required this.notice,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon box
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: _getIconBgColor(notice.category),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                _getIcon(notice.category),
                size: 24.w,
                color: _getIconColor(notice.category),
              ),
            ),
            SizedBox(width: 12.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notice.content,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      // Priority badge
                      if (notice.priority == 'high' ||
                          notice.priority == 'urgent')
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'URGENT',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      if (notice.priority == 'high' ||
                          notice.priority == 'urgent')
                        SizedBox(width: 8.w),
                      // Category label
                      Text(
                        _getCategoryDisplayLabel(notice.category),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _getIconColor(notice.category),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // Time
                      Expanded(
                        child: Text(
                          formatDate(notice.publishDate),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Author name
                  if (notice.authorName.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12.w,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          notice.authorName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String category) {
    // Handle both 'category' and 'type' field names
    final cat = category.toLowerCase();

    if (cat == 'maintenance') {
      return Icons.build_outlined;
    } else if (cat == 'event') {
      return Icons.event_outlined;
    } else if (cat == 'emergency' || cat == 'urgent') {
      return Icons.warning_amber_outlined;
    } else if (cat == 'billing') {
      return Icons.receipt_outlined;
    } else if (cat == 'security') {
      return Icons.security_outlined;
    } else {
      // general or default
      return Icons.notifications_outlined;
    }
  }

  String _getCategoryDisplayLabel(String category) {
    final cat = category.toLowerCase();
    if (cat == 'maintenance') return 'Maintenance';
    if (cat == 'event') return 'Event';
    if (cat == 'emergency') return 'Emergency';
    if (cat == 'urgent') return 'Urgent';
    if (cat == 'billing') return 'Billing';
    if (cat == 'security') return 'Security';
    return 'General';
  }

  Color _getIconBgColor(String category) {
    final cat = category.toLowerCase();

    if (cat == 'maintenance') {
      return const Color(0xFFFFF3E8);
    } else if (cat == 'event') {
      return const Color(0xFFEDE9FF);
    } else if (cat == 'emergency' || cat == 'urgent') {
      return const Color(0xFFFEE2E2);
    } else if (cat == 'billing') {
      return const Color(0xFFE8FDEB);
    } else if (cat == 'security') {
      return const Color(0xFFFEE2E2);
    } else {
      // general or default
      return const Color(0xFFEAF1FF);
    }
  }

  Color _getIconColor(String category) {
    final cat = category.toLowerCase();

    if (cat == 'maintenance') {
      return const Color(0xFFF97316);
    } else if (cat == 'event') {
      return const Color(0xFF8B5CF6);
    } else if (cat == 'emergency' || cat == 'urgent') {
      return const Color(0xFFDC2626);
    } else if (cat == 'billing') {
      return const Color(0xFF10B981);
    } else if (cat == 'security') {
      return const Color(0xFFDC2626);
    } else {
      // general or default
      return const Color(0xFF0E4778);
    }
  }
}
