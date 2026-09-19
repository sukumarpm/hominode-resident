// lib/src/modals/edit_profile_modal.dart
// Edit Profile modal with form validation

import 'package:flutter/material.dart';
import 'dart:io';
import '../models/user_profile_model.dart';
import '../components/avatar_picker.dart';

/// Show Edit Profile modal
/// Returns updated UserProfile via callback
Future<void> showEditProfileModal(
  BuildContext context, {
  required UserProfile currentProfile,
  required Function(UserProfile) onSaved,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        EditProfileModal(currentProfile: currentProfile, onSaved: onSaved),
  );
}

class EditProfileModal extends StatefulWidget {
  final UserProfile currentProfile;
  final Function(UserProfile) onSaved;

  const EditProfileModal({
    super.key,
    required this.currentProfile,
    required this.onSaved,
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _apartmentController;

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  bool _isLoading = false;
  File? _avatarFile;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.currentProfile.fullName,
    );
    _phoneController = TextEditingController(text: widget.currentProfile.phone);
    _emailController = TextEditingController(
      text: widget.currentProfile.email ?? '',
    );
    _apartmentController = TextEditingController(
      text: widget.currentProfile.apartment,
    );
    _avatarUrl = widget.currentProfile.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool isValid = true;

    setState(() {
      // Name validation
      if (_nameController.text.trim().isEmpty) {
        _nameError = 'Name is required';
        isValid = false;
      } else {
        _nameError = null;
      }

      // Phone validation
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        _phoneError = 'Phone is required';
        isValid = false;
      } else if (!_isValidPhone(phone)) {
        _phoneError = 'Invalid phone format';
        isValid = false;
      } else {
        _phoneError = null;
      }

      // Email validation (optional but validated if present)
      final email = _emailController.text.trim();
      if (email.isNotEmpty && !_isValidEmail(email)) {
        _emailError = 'Invalid email format';
        isValid = false;
      } else {
        _emailError = null;
      }
    });

    return isValid;
  }

  bool _isValidPhone(String phone) {
    // Basic phone validation (adjust regex for your needs)
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(phone);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    // TODO: Replace with actual API call
    // Example:
    // try {
    //   final response = await updateProfile({
    //     'fullName': _nameController.text.trim(),
    //     'phone': _phoneController.text.trim(),
    //     'email': _emailController.text.trim(),
    //     'apartment': _apartmentController.text.trim(),
    //   });
    //   if (response.success) { ... }
    // } catch (e) { ... }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isLoading = false);

      // Create updated profile
      final updatedProfile = widget.currentProfile.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        apartment: _apartmentController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      // Call callback
      widget.onSaved(updatedProfile);

      // Close modal
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _handleAvatarTap() async {
    // TODO: Implement image picker
    // Add dependency: image_picker: ^1.0.4
    //
    // Example implementation:
    // final ImagePicker picker = ImagePicker();
    // final ImageSource? source = await _showImageSourceDialog();
    // if (source != null) {
    //   final XFile? image = await picker.pickImage(
    //     source: source,
    //     maxWidth: 800,
    //     maxHeight: 800,
    //     imageQuality: 85,
    //   );
    //   if (image != null) {
    //     setState(() {
    //       _avatarFile = File(image.path);
    //     });
    //     // TODO: Upload to server
    //     // final uploadedUrl = await uploadAvatar(_avatarFile!);
    //     // setState(() => _avatarUrl = uploadedUrl);
    //   }
    // }

    // For now, show placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Change Avatar'),
        content: const Text(
          'Image picker not implemented yet.\n\n'
          'Add image_picker dependency and implement photo selection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildAvatarSection(),
                  const SizedBox(height: 32),
                  _buildNameField(),
                  const SizedBox(height: 20),
                  _buildPhoneField(),
                  const SizedBox(height: 20),
                  _buildEmailField(),
                  const SizedBox(height: 20),
                  _buildApartmentField(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 24),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Semantics(
          label: 'Profile picture',
          hint: 'Tap to change profile picture',
          button: true,
          child: AvatarPicker(
            avatarUrl: _avatarUrl,
            avatarFile: _avatarFile,
            onTap: _handleAvatarTap,
            size: 100,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to change photo',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF0E4778),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Full Name',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            hintStyle: const TextStyle(color: Color(0xFFB9BDC1), fontSize: 16),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0E4778), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorText: _nameError,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (_) {
            if (_nameError != null) {
              setState(() => _nameError = null);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'OTP',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0E4778),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+91 98765 43210',
            hintStyle: const TextStyle(color: Color(0xFFB9BDC1), fontSize: 16),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0E4778), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorText: _phoneError,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (_) {
            if (_phoneError != null) {
              setState(() => _phoneError = null);
            }
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Phone changes require OTP verification',
          style: TextStyle(fontSize: 13, color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional)',
              style: TextStyle(fontSize: 14, color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'your.email@example.com',
            hintStyle: const TextStyle(color: Color(0xFFB9BDC1), fontSize: 16),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0E4778), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorText: _emailError,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          onChanged: (_) {
            if (_emailError != null) {
              setState(() => _emailError = null);
            }
          },
        ),
      ],
    );
  }

  Widget _buildApartmentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Apartment / Flat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _apartmentController,
          decoration: InputDecoration(
            hintText: 'Block A, Flat 301',
            hintStyle: const TextStyle(color: Color(0xFFB9BDC1), fontSize: 16),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0E4778), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E4778),
          disabledBackgroundColor: const Color(0xFF0E4778).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
