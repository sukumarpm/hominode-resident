// lib/src/modals/post_menu_bottomsheet.dart
// Bottom sheet menu for post options

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/post.dart';

void showPostMenu(
  BuildContext context,
  Post post, {
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  required VoidCallback onReport,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => PostMenuBottomSheet(
      post: post,
      onEdit: onEdit,
      onDelete: onDelete,
      onReport: onReport,
    ),
  );
}

class PostMenuBottomSheet extends StatelessWidget {
  final Post post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  const PostMenuBottomSheet({
    super.key,
    required this.post,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),

            if (post.isMine) ...[
              // Edit option
              _buildMenuItem(
                icon: Icons.edit_outlined,
                label: 'Edit Post',
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              const Divider(height: 1),
              // Delete option
              _buildMenuItem(
                icon: Icons.delete_outline,
                label: 'Delete Post',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ] else ...[
              // Report option
              _buildMenuItem(
                icon: Icons.flag_outlined,
                label: 'Report Post',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  onReport();
                },
              ),
            ],

            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          children: [
            Icon(icon, color: color ?? const Color(0xFF111111), size: 24.w),
            SizedBox(width: 16.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: color ?? const Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
