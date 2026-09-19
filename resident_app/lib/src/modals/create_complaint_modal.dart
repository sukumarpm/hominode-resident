// lib/src/modals/create_complaint_modal.dart
// Centered modal overlay for creating new complaints

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../models/complaint.dart';
import '../services/complaints_service.dart';
import '../services/complaint_image_service.dart';

// ============================================================================
// THEME CONSTANTS
// ============================================================================
const Color kPrimary = Color(0xFF0E4778);
const Color kModalBackground = Color(0xFFFFFFFF);
const Color kOverlayDim = Color(0x5C000000); // rgba(0,0,0,0.36)
const Color kInputBorder = Color(0xFFE6E6E6);
const Color kPlaceholderText = Color(0xFFBDBDBD);
const Color kHeaderText = Color(0xFF111111);
const Color kLabelText = Color(0xFF111111);
const Color kErrorText = Color(0xFFEF4444);
const double kModalRadius = 16.0;
const double kInputRadius = 8.0;

// ============================================================================
// HELPER: SHOW CREATE COMPLAINT MODAL
// ============================================================================
/// Opens the create complaint modal with fade+scale animation
void showCreateComplaintModal(
  BuildContext context, {
  Function(Complaint)? onCreated,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Create New Complaint',
    barrierColor: kOverlayDim,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) {
      return CreateComplaintModal(onCreated: onCreated);
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

// ============================================================================
// CREATE COMPLAINT MODAL WIDGET
// ============================================================================
class CreateComplaintModal extends StatefulWidget {
  final Function(Complaint)? onCreated;

  const CreateComplaintModal({super.key, this.onCreated});

  @override
  State<CreateComplaintModal> createState() => _CreateComplaintModalState();
}

class _CreateComplaintModalState extends State<CreateComplaintModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  ComplaintCategory? _selectedCategory;
  File? _attachedImage;
  bool _isSubmitting = false;

  final Map<String, String?> _errors = {
    'category': null,
    'title': null,
    'description': null,
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool isFormValid() {
    return _selectedCategory != null &&
        _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
  }

  Map<String, String?> validateFields() {
    final errors = <String, String?>{};

    if (_selectedCategory == null) {
      errors['category'] = 'Please select a category';
    }

    if (_titleController.text.trim().isEmpty) {
      errors['title'] = 'Title is required';
    } else if (_titleController.text.trim().length < 5) {
      errors['title'] = 'Title must be at least 5 characters';
    }

    if (_descriptionController.text.trim().isEmpty) {
      errors['description'] = 'Description is required';
    } else if (_descriptionController.text.trim().length < 10) {
      errors['description'] = 'Description must be at least 10 characters';
    } else if (_descriptionController.text.length > 1000) {
      errors['description'] = 'Description must not exceed 1000 characters';
    }

    return errors;
  }

  Future<void> _selectCategory() async {
    final category = await showDialog<ComplaintCategory>(
      context: context,
      builder: (context) =>
          _CategoryPickerDialog(selectedCategory: _selectedCategory),
    );

    if (category != null) {
      setState(() {
        _selectedCategory = category;
        _errors['category'] = null;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // Show source selection dialog (same as family member modal)
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Select Photo Source',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading: Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF0E4778)),
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Take a new photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF16A34A),
                  ),
                ),
                title: Text(
                  'Gallery',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      try {
        final image = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (image != null && mounted) {
          setState(() {
            _attachedImage = File(image.path);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error picking image: ${e.toString()}'),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _removeImage() {
    setState(() {
      _attachedImage = null;
    });
  }

  Future<void> _submitComplaint() async {
    // Validate all fields
    final errors = validateFields();
    setState(() {
      _errors.addAll(errors);
    });

    if (errors.isNotEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      print('🔵 Submitting complaint with image...');

      // Step 1: Create complaint
      print('📝 Creating complaint...');
      final complaint = await ComplaintsService().createComplaint(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
      );
      print('✅ Complaint created: ${complaint.id}');

      // Step 2: Upload image if attached
      if (_attachedImage != null) {
        print('📸 Image attached, uploading to Cloudinary...');
        final imageResult = await ComplaintImageService.instance
            .uploadComplaintImage(
              imagePath: _attachedImage!.path,
              complaintId: complaint.id,
            );

        if (imageResult.success) {
          print('✅ Image uploaded successfully');
          print('🔗 Image URL: ${imageResult.imageUrl}');
        } else {
          print('⚠️ Image upload failed: ${imageResult.message}');
          // Don't fail the complaint submission if image upload fails
        }
      } else {
        print('⚠️ No image attached');
      }

      if (mounted) {
        // Close modal
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );

        // Callback
        widget.onCreated?.call(complaint);
      }
    } catch (e) {
      print('❌ Submission error: $e');
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit complaint: ${e.toString()}'),
            backgroundColor: kErrorText,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(maxWidth: 450.w, maxHeight: 620.h),
        margin: EdgeInsets.only(
          top: 30.h,
          bottom: keyboardPadding > 0 ? keyboardPadding + 20 : 30,
        ),
        decoration: BoxDecoration(
          color: kModalBackground,
          borderRadius: BorderRadius.circular(kModalRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryField(),
                        SizedBox(height: 18.h),
                        _buildTitleField(),
                        SizedBox(height: 18.h),
                        _buildDescriptionField(),
                        SizedBox(height: 18.h),
                        _buildAttachPhotoField(),
                        SizedBox(height: 24.h),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 12.w, 18.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kInputBorder, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Create New Complaint',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19.sp,
                fontWeight: FontWeight.w600,
                color: kHeaderText,
              ),
            ),
          ),
          SizedBox(
            width: 44.w,
            height: 44.h,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, color: Color(0xFF9E9E9E), size: 26.w),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryField() {
    return LabeledDropdown(
      label: 'Category',
      placeholder: 'Select Category',
      value: _selectedCategory?.categoryDisplayName,
      error: _errors['category'],
      onTap: _selectCategory,
    );
  }

  Widget _buildTitleField() {
    return LabeledTextField(
      label: 'Title',
      placeholder: 'Brief description',
      controller: _titleController,
      error: _errors['title'],
      onChanged: (value) {
        if (_errors['title'] != null) {
          setState(() => _errors['title'] = null);
        }
      },
    );
  }

  Widget _buildDescriptionField() {
    return LabeledTextArea(
      label: 'Description',
      placeholder: 'Detailed description',
      controller: _descriptionController,
      error: _errors['description'],
      maxLength: 1000,
      onChanged: (value) {
        if (_errors['description'] != null) {
          setState(() => _errors['description'] = null);
        }
      },
    );
  }

  Widget _buildAttachPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach photo (optional)',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: kLabelText,
          ),
        ),
        SizedBox(height: 10.h),
        UploadPhotoBox(
          image: _attachedImage,
          onTap: _pickImage,
          onRemove: _removeImage,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return PrimaryButton(
      label: 'Submit Complaint',
      onPressed: isFormValid() && !_isSubmitting ? _submitComplaint : null,
      isLoading: _isSubmitting,
    );
  }
}

// ============================================================================
// CATEGORY PICKER DIALOG
// ============================================================================
class _CategoryPickerDialog extends StatelessWidget {
  final ComplaintCategory? selectedCategory;

  const _CategoryPickerDialog({this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kModalRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Category',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: kHeaderText,
              ),
            ),
            SizedBox(height: 16.h),
            ...ComplaintCategory.values.map((category) {
              final isSelected = category == selectedCategory;
              return InkWell(
                onTap: () => Navigator.pop(context, category),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 16.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getIconForCategory(category),
                        color: isSelected ? kPrimary : const Color(0xFF6B7280),
                        size: 24.w,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          category.categoryDisplayName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected ? kPrimary : kHeaderText,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, color: kPrimary, size: 24.w),
                    ],
                  ),
                ),
              );
            }),
          ],
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
}

// ============================================================================
// REUSABLE COMPONENTS
// ============================================================================

class LabeledDropdown extends StatelessWidget {
  final String label;
  final String placeholder;
  final String? value;
  final String? error;
  final VoidCallback onTap;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.placeholder,
    this.value,
    this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: kLabelText,
          ),
        ),
        SizedBox(height: 10.h),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kInputRadius),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: error != null ? kErrorText : kInputBorder,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(kInputRadius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: value != null ? kHeaderText : kPlaceholderText,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: kPlaceholderText,
                  size: 24.w,
                ),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          SizedBox(height: 6.h),
          Text(
            error!,
            style: TextStyle(fontSize: 13.sp, color: kErrorText),
          ),
        ],
      ],
    );
  }
}

class LabeledTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String>? onChanged;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.error,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: kLabelText,
          ),
        ),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(fontSize: 14.sp, color: kPlaceholderText),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kInputRadius),
              borderSide: const BorderSide(color: kInputBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kInputRadius),
              borderSide: BorderSide(
                color: error != null ? kErrorText : kInputBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kInputRadius),
              borderSide: BorderSide(
                color: error != null ? kErrorText : kPrimary,
                width: 1.5,
              ),
            ),
          ),
          style: TextStyle(fontSize: 14.sp, color: kHeaderText),
        ),
        if (error != null) ...[
          SizedBox(height: 6.h),
          Text(
            error!,
            style: TextStyle(fontSize: 13.sp, color: kErrorText),
          ),
        ],
      ],
    );
  }
}

class LabeledTextArea extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final String? error;
  final int maxLength;
  final ValueChanged<String>? onChanged;

  const LabeledTextArea({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.error,
    this.maxLength = 1000,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: kLabelText,
          ),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: 5,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(fontSize: 14.sp, color: kPlaceholderText),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 14.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kInputRadius),
              borderSide: const BorderSide(color: kInputBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kInputRadius),
              borderSide: BorderSide(
                color: error != null ? kErrorText : kInputBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kInputRadius),
              borderSide: BorderSide(
                color: error != null ? kErrorText : kPrimary,
                width: 1.5,
              ),
            ),
            counterStyle: TextStyle(fontSize: 12.sp, color: kPlaceholderText),
          ),
          style: TextStyle(fontSize: 15.sp, color: kHeaderText, height: 1.5),
        ),
        if (error != null) ...[
          SizedBox(height: 6.h),
          Text(
            error!,
            style: TextStyle(fontSize: 13.sp, color: kErrorText),
          ),
        ],
      ],
    );
  }
}

class UploadPhotoBox extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const UploadPhotoBox({
    super.key,
    this.image,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      // Show thumbnail with change option (same as family member modal)
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6E9EC)),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                color: const Color(0xFFF3F4F6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.r),
                child: Image.file(
                  image!,
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo attached',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  GestureDetector(
                    onTap: onTap,
                    child: Text(
                      'Change photo',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Color(0xFF0E4778),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close, size: 20.w, color: Color(0xFF9CA3AF)),
              padding: EdgeInsets.all(8.w),
              constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
            ),
          ],
        ),
      );
    }

    // Show upload button (same as family member modal)
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE6E9EC), width: 1.5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_upload_outlined,
              size: 24.w,
              color: Color(0xFF111827),
            ),
            SizedBox(width: 10.w),
            Text(
              'Upload photo',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kPrimary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

// ============================================================================
// USAGE SUMMARY
// ============================================================================
// 1. Paste file to: lib/src/modals/create_complaint_modal.dart
// 2. Assets: Icons.file_upload_outlined, Icons.close, Icons.keyboard_arrow_down (Material Icons)
// 3. Usage: showCreateComplaintModal(context, onCreated: (complaint) { /* refresh list */ });
