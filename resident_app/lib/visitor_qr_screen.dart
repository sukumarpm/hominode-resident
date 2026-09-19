import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Visitor QR Pass Screen
/// Displays the QR code for an approved visitor
/// Fetches visitor data from Firestore
class VisitorQRScreen extends StatefulWidget {
  final String visitorId;

  const VisitorQRScreen({super.key, required this.visitorId});

  @override
  State<VisitorQRScreen> createState() => _VisitorQRScreenState();
}

class _VisitorQRScreenState extends State<VisitorQRScreen> {
  final _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _visitorData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVisitorData();
  }

  Future<void> _loadVisitorData() async {
    print('🔵 QR Screen: Loading visitor data for ID: ${widget.visitorId}');

    try {
      final doc = await _firestore
          .collection('visitors')
          .doc(widget.visitorId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        print('✅ QR Screen: Visitor data loaded: $data');

        setState(() {
          _visitorData = data;
          _isLoading = false;
        });
      } else {
        print('❌ QR Screen: Visitor document not found');
        setState(() {
          _error = 'Visitor not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ QR Screen: Error loading visitor: $e');
      setState(() {
        _error = 'Failed to load visitor data';
        _isLoading = false;
      });
    }
  }

  String _generateQRData() {
    if (_visitorData == null) {
      return '';
    }

    final qrToken = _visitorData!['qrToken']?.toString().trim() ?? '';

    if (qrToken.isEmpty) {
      // Temporary compatibility for visitors created
      // before qrToken was introduced.
      return jsonEncode({'visitorId': widget.visitorId, 'legacy': true});
    }

    return jsonEncode({
      'type': 'hominode_visitor',
      'version': 1,
      'token': qrToken,
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar to black background with white icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Status bar spacer
          Container(
            color: Colors.black,
            height: MediaQuery.of(context).padding.top,
          ),

          // Main content
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: Column(
                children: [
                  _buildHeader(context),

                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? _buildError()
                        : SingleChildScrollView(
                            padding: EdgeInsets.all(24.w),
                            child: Column(
                              children: [
                                SizedBox(height: 20.h),
                                _buildQRCard(),
                                SizedBox(height: 24.h),
                                _buildVisitorDetails(),
                                SizedBox(height: 32.h),
                                _buildInstructions(),
                                SizedBox(height: 24.h),
                                _buildShareButton(context),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              'Visitor QR Pass',
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: Color(0xFFDC2626)),
            SizedBox(height: 16.h),
            Text(
              _error ?? 'An error occurred',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E4778),
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCard() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Actual QR Code
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
            child: QrImageView(
              data: _generateQRData(),
              version: QrVersions.auto,
              size: 240,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),

          SizedBox(height: 16.h),

          // Pass ID
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'Pass ID: ${_visitorData!['visitorPassCode'] ?? 'QR ONLY'}',
              style: TextStyle(
                color: const Color(0xFF0E4778),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorDetails() {
    if (_visitorData == null) return const SizedBox();

    final visitorName = _visitorData!['visitorName'] ?? 'N/A';
    final purpose = _visitorData!['purpose'] ?? 'N/A';
    final expectedArrival = _visitorData!['expectedArrival'] as Timestamp?;
    final timeString = expectedArrival != null
        ? '${expectedArrival.toDate().day}/${expectedArrival.toDate().month}/${expectedArrival.toDate().year} ${expectedArrival.toDate().hour}:${expectedArrival.toDate().minute.toString().padLeft(2, '0')}'
        : 'N/A';
    final flatLabel =
        _visitorData!['flatLabel'] ?? _visitorData!['flatId'] ?? 'N/A';
    final vehicleNumber = _visitorData!['vehicleNumber'] ?? 'N/A';

    return Container(
      padding: EdgeInsets.all(20.w),
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
          Text(
            'Visitor Details',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          _buildDetailRow(
            icon: Icons.person_outline,
            label: 'Name',
            value: visitorName,
          ),
          SizedBox(height: 12.h),
          _buildDetailRow(
            icon: Icons.home_outlined,
            label: 'Visiting',
            value: 'Flat $flatLabel',
          ),
          SizedBox(height: 12.h),
          _buildDetailRow(
            icon: Icons.category_outlined,
            label: 'Purpose',
            value: purpose,
          ),
          SizedBox(height: 12.h),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Expected Time',
            value: timeString,
          ),
          if (vehicleNumber != 'N/A') ...[
            SizedBox(height: 12.h),
            _buildDetailRow(
              icon: Icons.directions_car_outlined,
              label: 'Vehicle',
              value: vehicleNumber,
            ),
          ],
          SizedBox(height: 12.h),
          _buildDetailRow(
            icon: Icons.check_circle_outline,
            label: 'Status',
            value: 'Approved',
            valueColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20.w, color: const Color(0xFF64748B)),
        SizedBox(width: 12.w),
        Text(
          '$label: ',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF1E293B),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF0E4778).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF0E4778), size: 20.w),
              SizedBox(width: 8.w),
              Text(
                'Instructions',
                style: TextStyle(
                  color: Color(0xFF0E4778),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildInstructionItem('Show this QR code at the security gate'),
          _buildInstructionItem('Valid for single entry only'),
          _buildInstructionItem('Pass expires after scheduled time'),
          _buildInstructionItem('Visitor must carry valid ID proof'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.w,
            height: 6.h,
            decoration: const BoxDecoration(
              color: Color(0xFF0E4778),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Color(0xFF061C4C),
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return Container(
      width: double.infinity,
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
            color: const Color(0xFF0E4778).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleSharePass(context),
          borderRadius: BorderRadius.circular(16.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share_outlined, color: Colors.white, size: 24.w),
              SizedBox(width: 12.w),
              Text(
                'Share Pass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSharePass(BuildContext context) {
    final visitorName = _visitorData?['visitorName'] ?? 'Visitor';
    final flatLabel =
        _visitorData?['flatLabel'] ?? _visitorData?['flatId'] ?? '';

    final shareText =
        '''
Visitor Pass - Approved

Name: $visitorName
Visiting: Flat $flatLabel
Pass ID: ${widget.visitorId.substring(0, 12).toUpperCase()}

Please show this QR code at the security gate.
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Share QR Pass',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShareOption(
              context,
              icon: Icons.message_outlined,
              label: 'Share via SMS',
              onTap: () {
                Navigator.pop(context);
                _showShareSuccess(context, 'SMS');
              },
            ),
            SizedBox(height: 12.h),
            _buildShareOption(
              context,
              icon: Icons.email_outlined,
              label: 'Share via Email',
              onTap: () {
                Navigator.pop(context);
                _showShareSuccess(context, 'Email');
              },
            ),
            SizedBox(height: 12.h),
            _buildShareOption(
              context,
              icon: Icons.chat_bubble_outline,
              label: 'Share via WhatsApp',
              onTap: () {
                Navigator.pop(context);
                _showShareSuccess(context, 'WhatsApp');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: const Color(0xFF0E4778), size: 24.w),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSuccess(BuildContext context, String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pass shared via $method'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    );
  }
}
