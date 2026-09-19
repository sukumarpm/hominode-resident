// lib/src/screens/edit_profile_screen.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/standard_screen.dart';
import '../services/profile_image_service.dart';
import '../services/user_data_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userDataService = UserDataService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _flatNumberController;

  String? _photoUrl;
  File? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _flatNumberController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    print('🔵 EDIT PROFILE LOAD FLOW: Starting...');
    setState(() => _isLoading = true);

    try {
      // STEP 1: Fetch user data from Firestore
      print('📥 STEP 1: Fetching user data from Firestore...');
      var userData = await _userDataService.getCurrentUserData(
        forceRefresh: true,
      );

      // If first attempt fails, try getting from SharedPreferences user_id
      if (userData == null) {
        print('⚠️  First attempt failed, trying alternative method...');
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id');

        if (userId != null) {
          print('   Trying to fetch with user_id: $userId');
          userData = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get()
              .then((doc) {
                if (doc.exists) {
                  final data = doc.data() as Map<String, dynamic>;
                  data['id'] = doc.id;
                  return data;
                }
                return null;
              });
        }
      }

      if (userData == null) {
        print('❌ STEP 1 FAILED: No user data found');
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'User profile not found. Please contact administrator.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      print('✅ STEP 1 PASSED: User data loaded');
      print('   Name: ${userData['name']}');
      print('   Email: ${userData['email']}');
      print('   Phone: ${userData['phone']}');
      print('   Flat: ${userData['flatLabel'] ?? userData['flatId']}');

      // STEP 2: Populate form fields
      print('🎨 STEP 2: Populating form fields...');
      if (mounted) {
        setState(() {
          _nameController.text = userData?['name'] ?? '';
          _emailController.text =
              userData?['email'] ??
              FirebaseAuth.instance.currentUser?.email ??
              '';
          _phoneController.text = userData?['phone'] ?? '';
          _flatNumberController.text =
              userData?['flatLabel'] ?? userData?['flatId'] ?? '';
          _photoUrl = userData?['profileImage'] ?? userData?['photoURL'];
          _isLoading = false;
        });

        print('✅ STEP 2 PASSED: Form fields populated');
        print('');
        print('✅ EDIT PROFILE LOAD FLOW: COMPLETE');
      }
    } catch (e, stackTrace) {
      print('❌ ERROR in EDIT PROFILE LOAD FLOW: $e');
      print('   Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _flatNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Edit Profile',
      isScrollable: true,
      padding: EdgeInsets.all(16.w),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildPhotoSection(),
                  SizedBox(height: 24.h),
                  _buildTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    hint: 'Enter your name',
                    icon: Icons.person_outline,
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    label: 'Email',
                    controller: _emailController,
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    enabled: true, // Enabled for editing
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    label: 'Phone',
                    controller: _phoneController,
                    hint: 'Enter your phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    enabled: false, // Phone changes require OTP re-verification
                  ),
                  SizedBox(height: 16.h),
                  _buildTextField(
                    label: 'Flat Number',
                    controller: _flatNumberController,
                    hint: 'e.g., A-101',
                    icon: Icons.home_outlined,
                    enabled: false, // Flat/unit assignment is managed by Admin
                  ),
                  SizedBox(height: 32.h),
                  _buildSaveButton(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100.w,
                height: 100.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE0E7FF),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: ClipOval(
                  child: _photoFile != null
                      ? Image.file(_photoFile!, fit: BoxFit.cover)
                      : _photoUrl != null
                      ? Image.network(_photoUrl!, fit: BoxFit.cover)
                      : Icon(
                          Icons.person,
                          size: 50.w,
                          color: const Color(0xFF0E4778),
                        ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E4778),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Tap to change photo',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          validator:
              validator ??
              (value) {
                if (!enabled) return null;
                if (value == null || value.trim().isEmpty) {
                  return '$label is required';
                }
                return null;
              },
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF0E4778), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 14.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E4778),
          disabledBackgroundColor: const Color(0xFF93C5FD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? SizedBox(
                height: 20.h,
                width: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
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
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF0E4778),
                    ),
                  ),
                  title: const Text('Camera'),
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
                  title: const Text('Gallery'),
                  subtitle: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );

      if (source != null) {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _photoFile = File(image.path);
            _photoUrl = image.path;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    print('🔵 EDIT PROFILE SAVE FLOW: Starting...');
    setState(() => _isSaving = true);

    try {
      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();

      // STEP 1: Prepare updates for Firestore
      print('📋 Preparing profile updates for Firestore...');
      final updates = <String, dynamic>{'name': newName, 'email': newEmail};

      // STEP 2: Upload image if selected
      print('📸 Checking for image upload...');
      String? uploadedImageUrl;
      if (_photoFile != null) {
        final imageResult = await ProfileImageService.instance
            .uploadProfileImage(imagePath: _photoFile!.path);

        if (imageResult.success && imageResult.imageUrl != null) {
          uploadedImageUrl = imageResult.imageUrl;
          updates['profileImage'] = imageResult.imageUrl;
          _photoUrl = imageResult.imageUrl;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image upload failed: ${imageResult.message}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }

      // STEP 3: Update Firestore Document directly
      print('💾 Updating user data in Firestore...');
      final success = await _userDataService.updateUserData(updates);

      if (!success) {
        throw Exception('Failed to update profile in Firestore');
      }

      // STEP 4: Force refresh image cache if needed
      if (uploadedImageUrl != null) {
        final userId = await _getUserId();
        if (userId != null) {
          await ProfileImageService.instance.forceRefreshProfileImage(
            userId: userId,
          );
        }
      }

      setState(() => _isSaving = false);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF22C55E),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR in EDIT PROFILE SAVE FLOW: $e');

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var userId = prefs.getString('user_id');

      if (userId == null) {
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          userId = firebaseUser.uid;
          await prefs.setString('user_id', userId);
        }
      }

      return userId;
    } catch (e) {
      print('⚠️  Error getting user ID: $e');
      return null;
    }
  }
}
