import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Setup Profile Screen - Pixel-perfect implementation
///
/// Design reference: /mnt/data/Setup Your Profile.png
/// Target device: iPhone 13 (390px width)
///
/// Features:
/// - Gradient header with back button
/// - Profile photo upload with circular placeholder
/// - Email address (optional)
/// - Emergency contact
/// - Form validation
/// - Complete Setup button with loading state
/// - Skip for now option
class SetupProfileScreen extends StatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emergencyContactController =
      TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _emergencyContactFocusNode = FocusNode();

  File? _profileImage;
  bool _isLoading = false;

  String? _emailError;
  String? _emergencyContactError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _emergencyContactController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emergencyContactController.dispose();
    _emailFocusNode.dispose();
    _emergencyContactFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {});
  }

  bool get _isFormValid {
    // Emergency contact is required
    return _emergencyContactController.text.trim().isNotEmpty;
  }

  bool _validateFields() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _emergencyContactError = null;
    });

    // Validate email if provided
    if (_emailController.text.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_emailController.text.trim())) {
        setState(() => _emailError = 'Please enter a valid email address');
        isValid = false;
      }
    }

    // Validate emergency contact (required)
    if (_emergencyContactController.text.trim().isEmpty) {
      setState(() => _emergencyContactError = 'Emergency contact is required');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeSetup() async {
    if (!_validateFields()) {
      return;
    }

    setState(() => _isLoading = true);

    // Save emergency contact and email to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'emergency_contact',
        _emergencyContactController.text.trim(),
      );
      if (_emailController.text.trim().isNotEmpty) {
        await prefs.setString('user_email', _emailController.text.trim());
      }
    } catch (e) {
      debugPrint('Error saving profile data: $e');
    }

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _skipForNow() {
    // Navigate to home without completing profile
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main heading
                    const Text(
                      'Add your details to complete your profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Profile photo upload
                    _buildProfilePhotoUpload(),
                    const SizedBox(height: 32),

                    // Email Address (Optional)
                    _buildInputField(
                      label: 'Email Address (Optional)',
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      hintText: 'Enter your email or username',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      error: _emailError,
                      onSubmitted: (_) =>
                          _emergencyContactFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 20),

                    // Emergency Contact
                    _buildInputField(
                      label: 'Emergency Contact',
                      controller: _emergencyContactController,
                      focusNode: _emergencyContactFocusNode,
                      hintText: 'Enter your email or username',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      error: _emergencyContactError,
                      onSubmitted: (_) {
                        if (_isFormValid) {
                          _completeSetup();
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Complete Setup Button
                    _buildCompleteSetupButton(),
                    const SizedBox(height: 16),

                    // Skip for now
                    Center(
                      child: GestureDetector(
                        onTap: _skipForNow,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E4778), Color(0xFF061C4C)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              Semantics(
                label: 'Back button',
                button: true,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Setup Your Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoUpload() {
    return Center(
      child: Column(
        children: [
          Semantics(
            label: 'Upload profile photo',
            button: true,
            child: GestureDetector(
              onTap: _pickImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _profileImage != null
                      ? Colors.transparent
                      : const Color(0xFFE5E5E5),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _profileImage != null
                    ? ClipOval(
                        child: Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      )
                    : const Icon(
                        Icons.file_download_outlined,
                        size: 40,
                        color: Color(0xFFA3A3A3),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Upload Profile Photo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? error,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: '$label input field',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: error != null ? Colors.red : const Color(0xFFE5E5E5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111111),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFA3A3A3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.red,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompleteSetupButton() {
    final isEnabled = _isFormValid && !_isLoading;

    return Semantics(
      label: 'Complete setup button',
      button: true,
      enabled: isEnabled,
      child: GestureDetector(
        onTap: isEnabled ? _completeSetup : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0E4778).withOpacity(isEnabled ? 1.0 : 0.4),
                Color(0xFF061C4C).withOpacity(isEnabled ? 1.0 : 0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF0E4778).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Complete Setup',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
