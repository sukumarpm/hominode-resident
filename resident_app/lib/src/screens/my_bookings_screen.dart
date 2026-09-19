// lib/src/screens/my_bookings_screen.dart
// My Bookings Screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_data_service.dart';
import '../widgets/skeleton_loader.dart';

// ============================================================================
// MY BOOKINGS SCREEN
// ============================================================================
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _userDataService = UserDataService();
  late Stream<List<Map<String, dynamic>>> _bookingsStream;
  String? _userId;
  String _selectedTab = 'upcoming'; // upcoming, completed, cancelled

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    print('🔵 MY BOOKINGS SCREEN: Initializing...');

    try {
      final userData = await _userDataService.getCurrentUserData();

      if (userData == null) {
        print('❌ No user data found');
        return;
      }

      final userId = userData['id'];

      if (userId == null || userId.isEmpty) {
        print('❌ No user ID found');
        return;
      }

      setState(() {
        _userId = userId;
        _bookingsStream = _getBookingsStream(userId);
      });

      print('✅ Stream initialized for user: $userId');
    } catch (e) {
      print('❌ Error initializing: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> _getBookingsStream(String userId) {
    print('📡 MY BOOKINGS FLOW: Streaming bookings for user: $userId');

    return _firestore
        .collection('amenityBookings')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 Found ${snapshot.docs.length} bookings');

          return snapshot.docs.map((doc) {
            final data = doc.data();
            final date =
                (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
            final status = data['status'] ?? 'pending';

            print('✅ Booking: ${data['amenityName']} - $status');

            return {
              'id': doc.id,
              'amenityName': data['amenityName'] ?? 'Amenity',
              'amenityId': data['amenityId'] ?? '',
              'date': date,
              'timeSlot': data['timeSlot'] ?? '',
              'numberOfPeople': data['numberOfPeople'] ?? 1,
              'status': status,
              'bookingType': data['bookingType'] ?? 'daily',
              'createdAt':
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'updatedAt':
                  (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'notes': data['notes'] ?? '',
              'price': data['price'] ?? 0,
              'userName': data['userName'] ?? 'You',
            };
          }).toList();
        })
        .handleError((error) {
          print('❌ Stream error: $error');
          return [];
        });
  }

  List<Map<String, dynamic>> _filterBookings(
    List<Map<String, dynamic>> bookings,
  ) {
    final now = DateTime.now();

    switch (_selectedTab) {
      case 'upcoming':
        return bookings.where((b) {
          final bookingDate = b['date'] as DateTime;
          return bookingDate.isAfter(now) && b['status'] != 'cancelled';
        }).toList();

      case 'completed':
        return bookings.where((b) {
          final bookingDate = b['date'] as DateTime;
          return bookingDate.isBefore(now) || b['status'] == 'completed';
        }).toList();

      case 'cancelled':
        return bookings.where((b) => b['status'] == 'cancelled').toList();

      default:
        return bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('my_bookings'.tr()),
        backgroundColor: const Color(0xFF0E4778),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _userId == null
          ? const Center(child: Text('Unable to load bookings'))
          : Column(
              children: [
                // Tab selector
                Container(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      _buildTabButton('upcoming'.tr(), 'upcoming'),
                      SizedBox(width: 8.w),
                      _buildTabButton('completed'.tr(), 'completed'),
                      SizedBox(width: 8.w),
                      _buildTabButton('cancelled'.tr(), 'cancelled'),
                    ],
                  ),
                ),
                // Bookings list
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _bookingsStream,
                    builder: (context, snapshot) {
                      // Loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return ListView.builder(
                          padding: EdgeInsets.all(16.w),
                          itemCount: 3,
                          itemBuilder: (context, index) => Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: SkeletonLoader(
                              width: double.infinity,
                              height: 140,
                              borderRadius: BorderRadius.circular(12.0.r),
                            ),
                          ),
                        );
                      }

                      // Error state
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48.w,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16.h),
                              Text('Error: ${snapshot.error}'),
                            ],
                          ),
                        );
                      }

                      final allBookings = snapshot.data ?? [];
                      final filteredBookings = _filterBookings(allBookings);

                      // Empty state
                      if (filteredBookings.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bookmark_outline,
                                size: 64.w,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No $_selectedTab bookings',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Bookings list
                      return ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return _buildBookingCard(context, booking);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    final isSelected = _selectedTab == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0E4778) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final date = booking['date'] as DateTime;
    final status = booking['status'] as String;
    final statusColor = _getStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _showBookingDetails(context, booking),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amenity name and status
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FDEB),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.bookmark_outline,
                      color: Color(0xFF10B981),
                      size: 24.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['amenityName'] ?? 'Amenity',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${booking['numberOfPeople']} people',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Date and time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16.w, color: Colors.grey),
                  SizedBox(width: 8.w),
                  Text(_formatDate(date), style: TextStyle(fontSize: 13.sp)),
                  SizedBox(width: 16.w),
                  Icon(Icons.access_time, size: 16.w, color: Colors.grey),
                  SizedBox(width: 8.w),
                  Text(
                    booking['timeSlot'] ?? 'Not specified',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking) {
    final date = booking['date'] as DateTime;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FDEB),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.bookmark_outline,
                      color: Color(0xFF10B981),
                      size: 28.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['amenityName'] ?? 'Amenity',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 4.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              booking['status'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            (booking['status'] as String).toUpperCase(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(booking['status']),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Details
              _buildDetailRow('Date', _formatDate(date)),
              _buildDetailRow(
                'Time Slot',
                booking['timeSlot'] ?? 'Not specified',
              ),
              _buildDetailRow(
                'Number of People',
                '${booking['numberOfPeople']} people',
              ),
              _buildDetailRow(
                'Booking Type',
                booking['bookingType'] ?? 'Daily',
              ),
              if (((booking['price'] as num?) ?? 0) > 0)
                _buildDetailRow('Price', '₹${booking['price']}'),
              if ((booking['notes'] as String?)?.isNotEmpty ?? false)
                _buildDetailRow('Notes', booking['notes'] ?? ''),
              _buildDetailRow(
                'Booked On',
                _formatDateTime(booking['createdAt'] as DateTime),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E4778),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
