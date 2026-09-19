import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/vehicle.dart';

class AddEditVehicleModal extends StatefulWidget {
  final Vehicle? vehicle;
  final Function(Vehicle) onSave;

  const AddEditVehicleModal({super.key, this.vehicle, required this.onSave});

  /// Static helper to show the modal
  static Future<void> show(
    BuildContext context, {
    Vehicle? vehicle,
    required Function(Vehicle) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) =>
          AddEditVehicleModal(vehicle: vehicle, onSave: onSave),
    );
  }

  @override
  State<AddEditVehicleModal> createState() => _AddEditVehicleModalState();
}

class _AddEditVehicleModalState extends State<AddEditVehicleModal>
    with SingleTickerProviderStateMixin {
  late TextEditingController _typeController;
  late TextEditingController _plateController;
  late TextEditingController _brandController;
  late TextEditingController _parkingSlotController;

  bool _isLoading = false;
  String? _typeError;
  String? _plateError;
  String? _photoUrl;
  File? _photoFile;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.vehicle?.type ?? '');
    _plateController = TextEditingController(
      text: widget.vehicle?.plateNumber ?? '',
    );
    _brandController = TextEditingController(text: widget.vehicle?.name ?? '');
    _parkingSlotController = TextEditingController(
      text: widget.vehicle?.color ?? '',
    );
    _photoUrl = widget.vehicle?.photoUrl;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _plateController.dispose();
    _brandController.dispose();
    _parkingSlotController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _typeError = _typeController.text.trim().isEmpty
          ? 'Vehicle type is required'
          : null;
      _plateError = _plateController.text.trim().isEmpty
          ? 'Vehicle number is required'
          : null;
    });

    return _typeError == null && _plateError == null;
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 800));

    final vehicle = Vehicle(
      id:
          widget.vehicle?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _brandController.text.trim().isEmpty
          ? 'Vehicle'
          : _brandController.text.trim(),
      type: _typeController.text.trim(),
      plateNumber: _plateController.text.trim(),
      color: _parkingSlotController.text.trim().isEmpty
          ? 'N/A'
          : _parkingSlotController.text.trim(),
      photoUrl: _photoUrl,
    );

    widget.onSave(vehicle);

    if (mounted) {
      await _animationController.reverse();
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleCancel() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickPhoto() async {
    try {
      // Show source selection dialog
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
                    child: const Icon(
                      Icons.camera_alt,
                      color: Color(0xFF0E4778),
                    ),
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

      if (source == null) return;

      // Pick image from selected source
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

        // TODO: Upload to server
        // Example:
        // final uploadedUrl = await uploadImageToServer(image.path);
        // setState(() => _photoUrl = uploadedUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final modalWidth = screenWidth < 720 ? screenWidth * 0.92 : 720.0;
    final isFormValid =
        _typeController.text.trim().isNotEmpty &&
        _plateController.text.trim().isNotEmpty;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: modalWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 720.w,
              ),
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 20.h, 12.w, 16.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.vehicle == null
                                ? 'Add Vehicle'
                                : 'Edit Vehicle',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isLoading ? null : _handleCancel,
                          icon: Icon(
                            Icons.close,
                            size: 26.w,
                            color: Color(0xFF9CA3AF),
                          ),
                          padding: EdgeInsets.all(10.w),
                          constraints: BoxConstraints(
                            minWidth: 44.w,
                            minHeight: 44.h,
                          ),
                          splashRadius: 22,
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle Type field
                          _buildTextField(
                            label: 'Vehicle Type',
                            controller: _typeController,
                            error: _typeError,
                            hint: 'e.g., Car, Bike',
                          ),
                          SizedBox(height: 20.h),
                          // Vehicle Number field
                          _buildTextField(
                            label: 'Vehicle Number',
                            controller: _plateController,
                            error: _plateError,
                            hint: 'TN 72 XX XXXX',
                          ),
                          SizedBox(height: 20.h),
                          // Brand/Model field
                          _buildTextField(
                            label: 'Brand/Model',
                            controller: _brandController,
                            hint: 'e.g., Honda City',
                          ),
                          SizedBox(height: 20.h),
                          // Parking Slot field
                          _buildTextField(
                            label: 'Parking Slot',
                            controller: _parkingSlotController,
                            hint: 'e.g., A-101',
                          ),
                          SizedBox(height: 24.h),
                          // Photo upload section
                          Text(
                            'Attach photo (optional)',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildPhotoUploadButton(),
                          SizedBox(height: 32.h),
                          // Add Vehicle button
                          SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !isFormValid)
                                  ? null
                                  : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E4778),
                                disabledBackgroundColor: const Color(
                                  0xFF0E4778,
                                ).withOpacity(0.4),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 22.h,
                                      width: 22.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      widget.vehicle == null
                                          ? 'Add Vehicle'
                                          : 'Update Vehicle',
                                      style: TextStyle(
                                        fontSize: 17.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: -0.2,
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? error,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 10.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: (value) {
            // Clear error on change
            if (error != null) {
              setState(() {
                if (label == 'Vehicle Type') _typeError = null;
                if (label == 'Vehicle Number') _plateError = null;
              });
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Color(0xFFB9BDC1),
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE6E9EC), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF0E4778), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorText: error,
            errorStyle: TextStyle(fontSize: 13.sp, color: Color(0xFFEF4444)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
          style: TextStyle(fontSize: 16.sp, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadButton() {
    if (_photoUrl != null) {
      // Show thumbnail with change option
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
                child: _photoFile != null
                    ? Image.file(
                        _photoFile!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      )
                    : _photoUrl!.startsWith('http')
                    ? Image.network(
                        _photoUrl!,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.directions_car,
                            size: 24.w,
                            color: Color(0xFF9CA3AF),
                          );
                        },
                      )
                    : Image.file(
                        File(_photoUrl!),
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.directions_car,
                            size: 24.w,
                            color: Color(0xFF9CA3AF),
                          );
                        },
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
                    onTap: _pickPhoto,
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
              onPressed: () {
                setState(() {
                  _photoUrl = null;
                  _photoFile = null;
                });
              },
              icon: Icon(Icons.close, size: 20.w, color: Color(0xFF9CA3AF)),
              padding: EdgeInsets.all(8.w),
              constraints: BoxConstraints(minWidth: 36.w, minHeight: 36.h),
            ),
          ],
        ),
      );
    }

    // Show upload button
    return InkWell(
      onTap: _pickPhoto,
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
