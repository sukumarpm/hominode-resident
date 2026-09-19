// lib/events_announcements_screen.dart
// Events & Announcements Screen with Firestore integration

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'src/components/app_segmented_control.dart';
import 'src/components/standard_screen.dart';
import 'src/models/announcement_model.dart';
import 'src/models/event_model.dart';
import 'src/services/announcements_events_service.dart';
import 'src/providers/language_provider.dart';

// Design Constants
const kPrimaryBlue = Color(0xFF0E4778);
const kSectionTitle = Color(0xFF111827);
const kSubtitle = Color(0xFF6B7280);
const kCardBackground = Color(0xFFFFFFFF);
const kDivider = Color(0xFFE6E6E6);
const kCardRadius = 12.0;
const kSpacing = 16.0;

// Priority colors
const kHighPriorityBg = Color(0xFFFEE2E2);
const kHighPriorityText = Color(0xFFEF4444);
const kMediumPriorityBg = Color(0xFFDBEAFE);
const kMediumPriorityText = Color(0xFF0E4778);
const kLowPriorityBg = Color(0xFFD1FAE5);
const kLowPriorityText = Color(0xFF10B981);

class EventsAnnouncementsScreen extends StatefulWidget {
  const EventsAnnouncementsScreen({super.key});

  @override
  State<EventsAnnouncementsScreen> createState() =>
      _EventsAnnouncementsScreenState();
}

class _EventsAnnouncementsScreenState extends State<EventsAnnouncementsScreen> {
  int _selectedTab = 0; // 0: Announcements, 1: Events
  final _service = AnnouncementsEventsService();

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return StandardScreen(
          title: 'events'.tr(),
          showBackButton: false,
          isScrollable: false,
          padding: EdgeInsets.zero,
          body: Column(
            children: [
              SizedBox(height: 20.h),

              // Segmented Control
              AppSegmentedControl(
                segments: ['announcements'.tr(), 'events'.tr()],
                selectedIndex: _selectedTab,
                onChanged: (index) {
                  setState(() => _selectedTab = index);
                },
              ),

              SizedBox(height: 20.h),

              // Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildAnnouncementsTab(languageProvider)
                    : _buildEventsTab(languageProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Announcements Tab
  Widget _buildAnnouncementsTab(LanguageProvider languageProvider) {
    return StreamBuilder<List<AnnouncementModel>>(
      stream: _service.streamAnnouncements(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.w, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  'error_loading_announcements'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please try again later',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final announcements = snapshot.data ?? [];

        // Empty state
        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 64.w,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16.h),
                Text(
                  'No Announcements',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Check back later for updates',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // List of announcements
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: kSpacing),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            return _buildAnnouncementCard(announcements[index]);
          },
        );
      },
    );
  }

  /// Events Tab
  Widget _buildEventsTab(LanguageProvider languageProvider) {
    return StreamBuilder<List<EventModel>>(
      stream: _service.streamEvents(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.w, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  'error_loading_events'.tr(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please try again later',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];

        // Empty state
        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_outlined, size: 64.w, color: Colors.grey[400]),
                SizedBox(height: 16.h),
                Text(
                  'No Events',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Check back later for upcoming events',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // List of events
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: kSpacing),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(events[index]);
          },
        );
      },
    );
  }

  /// Announcement Card
  Widget _buildAnnouncementCard(AnnouncementModel announcement) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: kDivider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category and Priority
            Row(
              children: [
                // Category
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    announcement.category,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Priority Badge
                _buildPriorityBadge(announcement.priority),
              ],
            ),

            SizedBox(height: 12.h),

            // Title
            Text(
              announcement.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: kSectionTitle,
              ),
            ),

            SizedBox(height: 8.h),

            // Description (max 2 lines)
            Text(
              announcement.description,
              style: TextStyle(fontSize: 14.sp, color: kSubtitle, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 12.h),

            // Created Date
            Row(
              children: [
                Icon(Icons.access_time, size: 14.w, color: kSubtitle),
                SizedBox(width: 4.w),
                Text(
                  _formatDate(announcement.createdAt),
                  style: TextStyle(fontSize: 12.sp, color: kSubtitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Event Card
  Widget _buildEventCard(EventModel event) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: kDivider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Category and Status
            Row(
              children: [
                // Category
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    event.category,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Status Badge
                _buildStatusBadge(event.status),
              ],
            ),

            SizedBox(height: 12.h),

            // Title
            Text(
              event.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: kSectionTitle,
              ),
            ),

            SizedBox(height: 8.h),

            // Description (max 2 lines)
            Text(
              event.description,
              style: TextStyle(fontSize: 14.sp, color: kSubtitle, height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: 12.h),

            // Event Date and Time
            if (event.eventDate != null) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14.w, color: kSubtitle),
                  SizedBox(width: 4.w),
                  Text(
                    _formatEventDate(event.eventDate!),
                    style: TextStyle(fontSize: 12.sp, color: kSubtitle),
                  ),
                  if (event.time != null && event.time!.isNotEmpty) ...[
                    SizedBox(width: 8.w),
                    Icon(Icons.access_time, size: 14.w, color: kSubtitle),
                    SizedBox(width: 4.w),
                    Text(
                      event.time!,
                      style: TextStyle(fontSize: 12.sp, color: kSubtitle),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 6.h),
            ],

            // Location
            if (event.location != null && event.location!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.location_on, size: 14.w, color: kSubtitle),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: TextStyle(fontSize: 12.sp, color: kSubtitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
            ],

            // RSVP Count (if available)
            if (event.totalCapacity != null && event.totalCapacity! > 0) ...[
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14.w, color: kSubtitle),
                  SizedBox(width: 4.w),
                  Text(
                    '${event.rsvpCount ?? 0}/${event.totalCapacity} attending',
                    style: TextStyle(fontSize: 12.sp, color: kSubtitle),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
            ],

            // Created Date
            Row(
              children: [
                Icon(Icons.schedule, size: 14.w, color: kSubtitle),
                SizedBox(width: 4.w),
                Text(
                  'Posted ${_formatDate(event.createdAt)}',
                  style: TextStyle(fontSize: 12.sp, color: kSubtitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Priority Badge
  Widget _buildPriorityBadge(String priority) {
    Color bgColor;
    Color textColor;
    String label;

    switch (priority.toLowerCase()) {
      case 'high':
        bgColor = kHighPriorityBg;
        textColor = kHighPriorityText;
        label = 'High';
        break;
      case 'low':
        bgColor = kLowPriorityBg;
        textColor = kLowPriorityText;
        label = 'Low';
        break;
      default:
        bgColor = kMediumPriorityBg;
        textColor = kMediumPriorityText;
        label = 'Medium';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// Status Badge for Events
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'upcoming':
        bgColor = kMediumPriorityBg;
        textColor = kMediumPriorityText;
        label = 'Upcoming';
        break;
      case 'active':
      case 'ongoing':
        bgColor = kLowPriorityBg;
        textColor = kLowPriorityText;
        label = 'Active';
        break;
      case 'completed':
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = 'Completed';
        break;
      case 'cancelled':
        bgColor = kHighPriorityBg;
        textColor = kHighPriorityText;
        label = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
        label = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  /// Format event date
  String _formatEventDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}
