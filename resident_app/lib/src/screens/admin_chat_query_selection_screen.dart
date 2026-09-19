// lib/src/screens/admin_chat_query_selection_screen.dart
// Query category selection screen for admin chat

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/admin_chat_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'admin_chat_query_template_screen.dart';

class AdminChatQuerySelectionScreen extends StatelessWidget {
  const AdminChatQuerySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat with Admin',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1.h, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),

            // Header text
            Text(
              'Select your query category:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 4.h),

            Text(
              'Choose the category that best matches your question',
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            ),

            SizedBox(height: 24.h),

            // Query categories
            _buildCategoryCard(context, category: QueryCategory.billing),

            SizedBox(height: 16.h),

            _buildCategoryCard(context, category: QueryCategory.maintenance),

            SizedBox(height: 16.h),

            _buildCategoryCard(context, category: QueryCategory.amenities),

            SizedBox(height: 16.h),

            _buildCategoryCard(context, category: QueryCategory.complaints),

            SizedBox(height: 16.h),

            _buildCategoryCard(context, category: QueryCategory.building),

            SizedBox(height: 16.h),

            _buildCategoryCard(context, category: QueryCategory.other),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required QueryCategory category,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminChatQueryTemplateScreen(category: category),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                gradient: _getCategoryGradient(category),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Text(category.icon, style: TextStyle(fontSize: 28.sp)),
              ),
            ),

            SizedBox(width: 16.w),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.displayName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    category.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 12.w),

            // Arrow
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16.w,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getCategoryGradient(QueryCategory category) {
    switch (category) {
      case QueryCategory.billing:
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case QueryCategory.maintenance:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case QueryCategory.amenities:
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF0E4778)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case QueryCategory.complaints:
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case QueryCategory.building:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case QueryCategory.other:
        return const LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
