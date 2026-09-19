// lib/src/components/primary_header.dart
// Reusable primary header with gradient background

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

const kPrimaryBlue = AppColors.primary;

class PrimaryHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;

  const PrimaryHeader({super.key, required this.title, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(4.w, 12.h, 16.w, 24.h),
          child: Row(
            children: [
              if (canPop)
                IconButton(
                  onPressed: onBackPressed ?? () => Navigator.maybePop(context),
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20.w,
                  ),
                  padding: EdgeInsets.all(12.w),
                  constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.h),
                ),
              if (!canPop) SizedBox(width: 12.w),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
