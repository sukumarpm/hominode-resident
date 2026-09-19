// lib/complaints_screen.dart
// Complaints & Requests screen

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'src/models/complaint.dart';
import 'src/models/staff_model.dart';
import 'src/services/complaints_service.dart';
import 'src/services/staff_firestore_service.dart';
import 'src/modals/create_complaint_modal.dart';
import 'src/modals/complaint_detail_modal.dart';
import 'src/components/standard_screen.dart';
import 'src/components/app_segmented_control.dart';

const kPrimaryBlue = Color(0xFF0E4778);
const kPendingRed = Color(0xFFDC2626);
const kInProgressOrange = Color(0xFFF97316);
const kCompletedGreen = Color(0xFF10B981);

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  final ComplaintsService _service = ComplaintsService();
  final StaffFirestoreService _staffService = StaffFirestoreService.instance;
  List<Complaint> _complaints = [];
  final Map<String, StaffModel> _staffCache = {}; // Cache staff details
  bool _isLoading = true;
  final bool _useRealtime = true; // Toggle for real-time updates
  int _selectedTabIndex = 0; // 0 = Active, 1 = History

  @override
  void initState() {
    super.initState();
    if (_useRealtime) {
      _setupRealtimeUpdates();
    } else {
      _loadComplaints();
    }
  }

  // Get active complaints (pending + in progress)
  List<Complaint> get _activeComplaints => _complaints
      .where(
        (c) =>
            c.status == ComplaintStatus.pending ||
            c.status == ComplaintStatus.inProgress,
      )
      .toList();

  // Get completed complaints (history)
  List<Complaint> get _completedComplaints =>
      _complaints.where((c) => c.status == ComplaintStatus.completed).toList();

  void _setupRealtimeUpdates() {
    setState(() => _isLoading = true);

    print('🔄 Setting up real-time complaint updates...');

    _service.streamComplaints().listen(
      (complaints) async {
        print('🔄 Real-time update received: ${complaints.length} complaints');

        for (var complaint in complaints) {
          print(
            '  - ${complaint.id}: ${complaint.status} (${complaint.assignedTo ?? "unassigned"})',
          );
        }

        // Fetch staff details for assigned complaints
        for (var complaint in complaints) {
          if (complaint.assignedStaffId != null &&
              !_staffCache.containsKey(complaint.assignedStaffId)) {
            print('📥 Fetching staff: ${complaint.assignedStaffId}');
            final staff = await _staffService.getStaffById(
              complaint.assignedStaffId!,
            );
            if (staff != null) {
              _staffCache[complaint.assignedStaffId!] = staff;
              print('✅ Staff cached: ${staff.name}');
            }
          }
        }

        if (mounted) {
          setState(() {
            _complaints = complaints;
            _isLoading = false;
          });
          print('✅ UI updated with ${complaints.length} complaints');
        }
      },
      onError: (error) {
        print('❌ Stream error: $error');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoading = true);
    try {
      final complaints = await _service.fetchComplaints();

      // Fetch staff details for assigned complaints
      for (var complaint in complaints) {
        if (complaint.assignedStaffId != null &&
            !_staffCache.containsKey(complaint.assignedStaffId)) {
          final staff = await _staffService.getStaffById(
            complaint.assignedStaffId!,
          );
          if (staff != null) {
            _staffCache[complaint.assignedStaffId!] = staff;
          }
        }
      }

      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading complaints: $e');
      setState(() => _isLoading = false);
    }
  }

  int get _pendingCount =>
      _complaints.where((c) => c.status == ComplaintStatus.pending).length;
  int get _inProgressCount =>
      _complaints.where((c) => c.status == ComplaintStatus.inProgress).length;
  int get _completedCount =>
      _complaints.where((c) => c.status == ComplaintStatus.completed).length;

  void _handleComplaintCreated(Complaint complaint) {
    setState(() {
      _complaints.insert(0, complaint);
    });
  }

  Future<void> _handleDeleteComplaint(Complaint complaint) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Complaint'),
        content: const Text('Are you sure you want to delete this complaint?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteComplaint(complaint.id);
        setState(() {
          _complaints.removeWhere((c) => c.id == complaint.id);
        });
        _showSnackBar('Complaint deleted', Colors.green);
      } catch (e) {
        _showSnackBar('Failed to delete complaint', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComplaintOptions(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: const Icon(
                Icons.visibility_outlined,
                color: kPrimaryBlue,
              ),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                final staff = complaint.assignedStaffId != null
                    ? _staffCache[complaint.assignedStaffId]
                    : null;
                showComplaintDetailModal(
                  context,
                  complaint,
                  assignedStaff: staff,
                  onDelete: () => _handleDeleteComplaint(complaint),
                  onChat: () {
                    _showSnackBar('Chat feature coming soon', Colors.blue);
                  },
                );
              },
            ),
            if (complaint.status == ComplaintStatus.pending)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Complaint',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleDeleteComplaint(complaint);
                },
              ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayComplaints = _selectedTabIndex == 0
        ? _activeComplaints
        : _completedComplaints;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: StandardScreen(
        title: 'Complaints & Requests',
        onBackPressed: () => Navigator.maybePop(context),
        isScrollable: false,
        padding: EdgeInsets.zero,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(height: 20.h),

                  // Segmented Control
                  AppSegmentedControl(
                    segments: const ['Active', 'History'],
                    selectedIndex: _selectedTabIndex,
                    onChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                  ),

                  SizedBox(height: 20.h),

                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadComplaints,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Status summary cards (only for active tab)
                            if (_selectedTabIndex == 0) _buildStatusSummary(),

                            // Complaints list
                            Padding(
                              padding: EdgeInsets.all(16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedTabIndex == 0
                                        ? 'Active Complaints'
                                        : 'Complaint History',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  if (displayComplaints.isEmpty)
                                    _buildEmptyState()
                                  else
                                    ...displayComplaints.map(
                                      (complaint) => Padding(
                                        padding: EdgeInsets.only(bottom: 16.h),
                                        child: _buildComplaintCard(complaint),
                                      ),
                                    ),
                                  SizedBox(height: 80.h), // Space for FAB
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCreateComplaintModal(context, onCreated: _handleComplaintCreated);
        },
        backgroundColor: kPrimaryBlue,
        child: Icon(Icons.add, color: Colors.white, size: 28.w),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          children: [
            Icon(
              _selectedTabIndex == 0
                  ? Icons.check_circle_outline
                  : Icons.history,
              size: 64.w,
              color: const Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16.h),
            Text(
              _selectedTabIndex == 0
                  ? 'No active complaints'
                  : 'No complaint history',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _selectedTabIndex == 0
                  ? 'Create a new complaint to get started'
                  : 'Completed complaints will appear here',
              style: TextStyle(fontSize: 14.sp, color: Color(0xFF9CA3AF)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.w, 16.h, 16.w, 20.h),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.w),
              padding: EdgeInsets.all(8.w),
            ),
            SizedBox(width: 4.w),
            Text(
              'Complaints & Requests',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusCard(
              count: _pendingCount,
              label: 'Pending',
              color: kPendingRed,
              backgroundColor: const Color(0xFFFEE2E2),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatusCard(
              count: _inProgressCount,
              label: 'In Progress',
              color: kInProgressOrange,
              backgroundColor: const Color(0xFFFFF3E8),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatusCard(
              count: _completedCount,
              label: 'Completed',
              color: kCompletedGreen,
              backgroundColor: const Color(0xFFE8FDEB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required int count,
    required String label,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    final staff = complaint.assignedStaffId != null
        ? _staffCache[complaint.assignedStaffId]
        : null;

    return GestureDetector(
      onTap: () {
        showComplaintDetailModal(
          context,
          complaint,
          assignedStaff: staff,
          onDelete: () => _handleDeleteComplaint(complaint),
          onChat: () {
            // TODO: Navigate to chat screen
            _showSnackBar('Chat feature coming soon', Colors.blue);
          },
        );
      },
      onLongPress: () {
        _showComplaintOptions(complaint);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: _getIconBackgroundColor(complaint.category),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    _getIconForCategory(complaint.category),
                    color: _getIconColor(complaint.category),
                    size: 24.w,
                  ),
                ),
                SizedBox(width: 12.w),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              complaint.title,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                          _buildStatusBadge(complaint.status),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        complaint.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '${complaint.categoryDisplayName} • ${complaint.formattedDate}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (staff != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E4778).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF0E4778),
                        size: 20.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111111),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '${staff.roleDisplayName} • ${staff.phone}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (complaint.assignedTo != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16.w,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Assigned to: ${complaint.assignedTo}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ComplaintStatus status) {
    Color color;
    Color backgroundColor;
    String label;

    switch (status) {
      case ComplaintStatus.pending:
        color = kPendingRed;
        backgroundColor = const Color(0xFFFEE2E2);
        label = 'Pending';
        break;
      case ComplaintStatus.inProgress:
        color = kInProgressOrange;
        backgroundColor = const Color(0xFFFFF3E8);
        label = 'in-progress';
        break;
      case ComplaintStatus.completed:
        color = kCompletedGreen;
        backgroundColor = const Color(0xFFE8FDEB);
        label = 'completed';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _getIconForCategory(ComplaintCategory category) {
    switch (category) {
      case ComplaintCategory.plumbing:
        return Icons.water_drop_outlined;
      case ComplaintCategory.electrical:
        return Icons.bolt_outlined;
      case ComplaintCategory.maintenance:
        return Icons.build_outlined;
      case ComplaintCategory.cleaning:
        return Icons.cleaning_services_outlined;
      case ComplaintCategory.security:
        return Icons.security_outlined;
      case ComplaintCategory.other:
        return Icons.help_outline;
    }
  }

  Color _getIconColor(ComplaintCategory category) {
    switch (category) {
      case ComplaintCategory.plumbing:
        return const Color(0xFF3B82F6);
      case ComplaintCategory.electrical:
        return const Color(0xFFF59E0B);
      case ComplaintCategory.maintenance:
        return const Color(0xFF10B981);
      case ComplaintCategory.cleaning:
        return const Color(0xFF8B5CF6);
      case ComplaintCategory.security:
        return const Color(0xFFEF4444);
      case ComplaintCategory.other:
        return const Color(0xFF6B7280);
    }
  }

  Color _getIconBackgroundColor(ComplaintCategory category) {
    switch (category) {
      case ComplaintCategory.plumbing:
        return const Color(0xFFEAF1FF);
      case ComplaintCategory.electrical:
        return const Color(0xFFFFF3E8);
      case ComplaintCategory.maintenance:
        return const Color(0xFFE8FDEB);
      case ComplaintCategory.cleaning:
        return const Color(0xFFEDE9FF);
      case ComplaintCategory.security:
        return const Color(0xFFFEE2E2);
      case ComplaintCategory.other:
        return const Color(0xFFF3F4F6);
    }
  }
}
