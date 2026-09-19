// lib/src/screens/domestic_staff_screen.dart
// Domestic Staff Management Screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_data_service.dart';
import '../widgets/skeleton_loader.dart';

// ============================================================================
// DOMESTIC STAFF SCREEN
// ============================================================================
class DomesticStaffScreen extends StatefulWidget {
  const DomesticStaffScreen({super.key});

  @override
  State<DomesticStaffScreen> createState() => _DomesticStaffScreenState();
}

class _DomesticStaffScreenState extends State<DomesticStaffScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _userDataService = UserDataService();
  late Stream<List<Map<String, dynamic>>> _staffStream;
  String? _flatId;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  Future<void> _initializeStream() async {
    print('🔵 DOMESTIC STAFF SCREEN: Initializing...');

    try {
      final userData = await _userDataService.getCurrentUserData();

      if (userData == null) {
        print('❌ No user data found');
        return;
      }

      final flatId = userData['flatId'] ?? userData['flatLabel'];

      if (flatId == null || flatId.isEmpty) {
        print('❌ No flat ID found');
        return;
      }

      setState(() {
        _flatId = flatId;
        _staffStream = _getDomesticStaffStream(flatId);
      });

      print('✅ Stream initialized for flat: $flatId');
    } catch (e) {
      print('❌ Error initializing: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> _getDomesticStaffStream(String flatId) {
    print('📡 DOMESTIC STAFF FLOW: Streaming staff for flat: $flatId');

    return _firestore
        .collection('domesticStaff')
        .where('flatId', isEqualTo: flatId)
        .where('status', isEqualTo: 'active')
        .orderBy('addedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 Found ${snapshot.docs.length} domestic staff members');

          return snapshot.docs.map((doc) {
            final data = doc.data();
            print('✅ Staff: ${data['name']} - ${data['role']}');

            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'role': data['role'] ?? 'Staff',
              'phone': data['phone'] ?? '',
              'email': data['email'] ?? '',
              'address': data['address'] ?? '',
              'joinDate':
                  (data['addedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'salary': data['salary'] ?? 0,
              'status': data['status'] ?? 'active',
              'notes': data['notes'] ?? '',
              'aadharNumber': data['aadharNumber'] ?? '',
              'bankAccount': data['bankAccount'] ?? '',
            };
          }).toList();
        })
        .handleError((error) {
          print('❌ Stream error: $error');
          return [];
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('domestic_staff'.tr()),
        backgroundColor: const Color(0xFF0E4778),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _flatId == null
          ? Center(child: Text('unable_to_load_staff_information'.tr()))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _staffStream,
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
                        height: 120,
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
                        Text(
                          'error_loading_staff'.tr(args: ['${snapshot.error}']),
                        ),
                      ],
                    ),
                  );
                }

                final staffList = snapshot.data ?? [];

                // Empty state
                if (staffList.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64.w,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'no_domestic_staff_added'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Staff list
                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return _buildStaffCard(context, staff);
                  },
                );
              },
            ),
    );
  }

  Widget _buildStaffCard(BuildContext context, Map<String, dynamic> staff) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _showStaffDetails(context, staff),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and role
              Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.cleaning_services_outlined,
                      color: Color(0xFFF97316),
                      size: 24.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          staff['role'] ?? 'Staff',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              SizedBox(height: 12.h),
              // Contact info
              if ((staff['phone'] as String?)?.isNotEmpty ?? false)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 16.w, color: Colors.grey),
                      SizedBox(width: 8.w),
                      Text(
                        staff['phone'] ?? '',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ],
                  ),
                ),
              if ((staff['email'] as String?)?.isNotEmpty ?? false)
                Row(
                  children: [
                    Icon(Icons.email, size: 16.w, color: Colors.grey),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        staff['email'] ?? '',
                        style: TextStyle(fontSize: 13.sp),
                        overflow: TextOverflow.ellipsis,
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

  void _showStaffDetails(BuildContext context, Map<String, dynamic> staff) {
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
                      color: const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.cleaning_services_outlined,
                      color: Color(0xFFF97316),
                      size: 28.w,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          staff['role'] ?? 'Staff',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Details
              _buildDetailRow('Phone', staff['phone'] ?? 'Not provided'),
              _buildDetailRow('Email', staff['email'] ?? 'Not provided'),
              _buildDetailRow('Address', staff['address'] ?? 'Not provided'),
              _buildDetailRow(
                'Aadhar Number',
                staff['aadharNumber'] ?? 'Not provided',
              ),
              _buildDetailRow(
                'Bank Account',
                staff['bankAccount'] ?? 'Not provided',
              ),
              if (((staff['salary'] as num?) ?? 0) > 0)
                _buildDetailRow('Monthly Salary', '₹${staff['salary']}'),
              if (staff['joinDate'] != null)
                _buildDetailRow(
                  'Join Date',
                  _formatDate(staff['joinDate'] as DateTime),
                ),
              if ((staff['notes'] as String?)?.isNotEmpty ?? false)
                _buildDetailRow('Notes', staff['notes'] ?? ''),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
