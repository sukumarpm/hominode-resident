// lib/src/screens/admin_chat_query_template_screen.dart
// Query template selection screen for admin chat

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/admin_chat_model.dart';
import '../services/admin_chat_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'admin_chat_conversation_screen.dart';

class AdminChatQueryTemplateScreen extends StatefulWidget {
  final QueryCategory category;

  const AdminChatQueryTemplateScreen({super.key, required this.category});

  @override
  State<AdminChatQueryTemplateScreen> createState() =>
      _AdminChatQueryTemplateScreenState();
}

class _AdminChatQueryTemplateScreenState
    extends State<AdminChatQueryTemplateScreen> {
  final TextEditingController _customQueryController = TextEditingController();
  final AdminChatService _adminChatService = AdminChatService.instance;
  bool _isLoading = false;
  String? _selectedTemplate;

  @override
  void dispose() {
    _customQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final templates = widget.category.templates;
    final hasTemplates = templates.isNotEmpty;

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
          widget.category.displayName,
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 8.h),

            if (hasTemplates) ...[
              // Quick queries header
              Text(
                'Quick queries:',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              SizedBox(height: 4.h),

              Text(
                'Tap a query to send it to admin',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),

              SizedBox(height: 16.h),

              // Template buttons
              ...templates.map(
                (template) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildTemplateButton(template),
                ),
              ),

              SizedBox(height: 24.h),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),

              SizedBox(height: 24.h),
            ],

            // Custom query input
            Text(
              hasTemplates ? 'Type your own question:' : 'Type your question:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 12.h),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _customQueryController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your query in detail...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.w),
                ),
                style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
              ),
            ),

            SizedBox(height: 24.h),

            // Send button
            ElevatedButton(
              onPressed: _isLoading ? null : _sendCustomQuery,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Send Query',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateButton(String template) {
    final isSelected = _selectedTemplate == template;

    return GestureDetector(
      onTap: () => _sendTemplateQuery(template),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 20.w,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                template,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward,
              size: 18.w,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTemplateQuery(String template) async {
    setState(() {
      _selectedTemplate = template;
      _isLoading = true;
    });

    await _createChatAndNavigate(template);
  }

  Future<void> _sendCustomQuery() async {
    final query = _customQueryController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your question'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _createChatAndNavigate(query);
  }

  Future<void> _createChatAndNavigate(String query) async {
    try {
      final chat = await _adminChatService.getOrCreateAdminChat(
        category: widget.category,
        initialMessage: query,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (chat == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to create admin chat. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navigate to conversation screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminChatConversationScreen(chat: chat),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
