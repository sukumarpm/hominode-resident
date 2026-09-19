import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

/// Emergency Call Confirmation Dialog
/// Pixel-perfect modal that appears when tapping emergency contacts
class EmergencyCallDialog extends StatelessWidget {
  final String title;
  final String phoneNumber;
  final String description;
  final IconData icon;
  final Color iconColor;

  const EmergencyCallDialog({
    super.key,
    required this.title,
    required this.phoneNumber,
    required this.description,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Confirm Emergency Call',
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: Color(0xFF888888),
                    size: 22.w,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Three-layer icon container
            _buildIconLayers(),

            SizedBox(height: 20.h),

            // Emergency title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 6.h),

            // Phone number
            Text(
              'Calling: $phoneNumber',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: 8.h),

            // Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFA3A3A3),
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),

            SizedBox(height: 24.h),

            // Call Now button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _makePhoneCall(phoneNumber);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E4778),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone, size: 20.w),
                    SizedBox(width: 8.w),
                    Text(
                      'Call Now',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // Cancel button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF111111),
                  side: const BorderSide(color: Color(0xFFE5E5E5), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Three-layer nested icon container (compact)
  Widget _buildIconLayers() {
    return Container(
      width: 160.w,
      height: 160.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.all(16.w),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(16.w),
        child: Container(
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 52.w),
          ),
        ),
      ),
    );
  }

  /// Make phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        debugPrint('Could not launch $phoneNumber');
      }
    } catch (e) {
      debugPrint('Error launching phone dialer: $e');
    }
  }
}

/// Show emergency call confirmation dialog
///
/// Usage:
/// ```dart
/// showEmergencyCallDialog(
///   context,
///   title: 'Security Emergency',
///   phoneNumber: '+91 98765 00001',
///   description: 'For security emergencies',
///   icon: Icons.shield_outlined,
///   iconColor: Color(0xFF0E4778),
/// );
/// ```
Future<void> showEmergencyCallDialog(
  BuildContext context, {
  required String title,
  required String phoneNumber,
  required String description,
  required IconData icon,
  required Color iconColor,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => EmergencyCallDialog(
      title: title,
      phoneNumber: phoneNumber,
      description: description,
      icon: icon,
      iconColor: iconColor,
    ),
  );
}
