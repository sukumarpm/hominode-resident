import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'src/services/visitor_firestore_service.dart';

// Design Constants
const kPrimary = Color(0xFF0E4778);
const kModalBackground = Color(0xFFFFFFFF);
const kInputBorder = Color(0xFFE6E6E6);
const kPlaceholder = Color(0xFFBDBDBD);
const kDimOverlay = Color(0x5C000000); // rgba(0,0,0,0.36)
const kRadius = 20.0;
const kInputRadius = 12.0;
const kSpacing = 16.0;
const kLargeSpacing = 24.0;

/// Helper function to show the Add Expected Visitor modal
/// Call this from FAB or any button tap
/// Returns true if visitor was added successfully, false otherwise
Future<bool?> showAddExpectedVisitorModal(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: kDimOverlay,
    barrierDismissible: true,
    builder: (context) => const AddExpectedVisitorModal(),
  );
}

/// Main modal widget - Add Expected Visitor form
class AddExpectedVisitorModal extends StatefulWidget {
  const AddExpectedVisitorModal({super.key});

  @override
  State<AddExpectedVisitorModal> createState() =>
      _AddExpectedVisitorModalState();
}

class _AddExpectedVisitorModalState extends State<AddExpectedVisitorModal> {
  final _nameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _visitorService = VisitorFirestoreService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isFormValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _purposeController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid =
          _nameController.text.isNotEmpty &&
          _purposeController.text.isNotEmpty &&
          _selectedDate != null &&
          _selectedTime != null;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _validateForm();
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: const ColorScheme.light(primary: kPrimary)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _validateForm();
      });
    }
  }

  Future<void> _handleAddVisitor() async {
    if (!_isFormValid || _isLoading) return;

    // Set loading state
    setState(() => _isLoading = true);

    try {
      // Convert TimeOfDay to DateTime
      final expectedTime = DateTime(
        2000,
        1,
        1, // Dummy date, only time matters
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Call Firestore service
      final result = await _visitorService.addExpectedVisitor(
        visitorName: _nameController.text.trim(),
        purpose: _purposeController.text.trim(),
        expectedDate: _selectedDate!,
        expectedTime: expectedTime,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        vehicleNumber: _vehicleController.text.trim().isEmpty
            ? null
            : _vehicleController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result.success) {
        // Close modal
        Navigator.pop(context, true); // Return true to indicate success

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Visitor added successfully'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            margin: EdgeInsets.all(16.w),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Failed to add visitor'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            margin: EdgeInsets.all(16.w),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          margin: EdgeInsets.all(16.w),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: kModalBackground,
            borderRadius: BorderRadius.circular(kRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(kLargeSpacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and close button
                _buildHeader(),

                SizedBox(height: 32.h),

                // Visitor Name field
                _buildLabeledTextField(
                  label: 'Visitor Name',
                  placeholder: 'Enter name',
                  controller: _nameController,
                ),

                const SizedBox(height: kLargeSpacing),

                // Purpose field
                _buildLabeledTextField(
                  label: 'Purpose',
                  placeholder: 'e.g., Personal visit',
                  controller: _purposeController,
                ),

                const SizedBox(height: kLargeSpacing),

                // Phone Number field (Optional)
                _buildLabeledTextField(
                  label: 'Phone Number (Optional)',
                  placeholder: 'Enter phone number',
                  controller: _phoneController,
                ),

                const SizedBox(height: kLargeSpacing),

                // Vehicle Number field (Optional)
                _buildLabeledTextField(
                  label: 'Vehicle Number (Optional)',
                  placeholder: 'e.g., MH 01 AB 1234',
                  controller: _vehicleController,
                ),

                const SizedBox(height: kLargeSpacing),

                // Date and Time row
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeField(
                        label: 'Date',
                        placeholder: 'dd-mm-yyyy',
                        value: _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : null,
                        onTap: _selectDate,
                      ),
                    ),
                    const SizedBox(width: kSpacing),
                    Expanded(
                      child: _buildDateTimeField(
                        label: 'Time',
                        placeholder: '-- / --',
                        value: _selectedTime != null
                            ? _formatTime(_selectedTime!)
                            : null,
                        onTap: _selectTime,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Add Visitor button
                _buildPrimaryButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header with centered title and close button
  Widget _buildHeader() {
    return Stack(
      children: [
        // Centered title
        Center(
          child: Text(
            'Add Expected Visitor',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ),

        // Close button (top-right)
        Positioned(
          right: 0,
          top: -8,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                width: 48.w,
                height: 48.h,
                alignment: Alignment.center,
                child: Icon(Icons.close, size: 28.w, color: Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Labeled text field component
  Widget _buildLabeledTextField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),

        SizedBox(height: 12.h),

        // Text field
        TextField(
          controller: controller,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              color: kPlaceholder,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kInputRadius),
              borderSide: const BorderSide(color: kInputBorder, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kInputRadius),
              borderSide: const BorderSide(color: kInputBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kInputRadius),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  /// Date/Time picker field component
  Widget _buildDateTimeField({
    required String label,
    required String placeholder,
    required String? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),

        SizedBox(height: 12.h),

        // Tappable field
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kInputRadius),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kInputRadius),
              border: Border.all(color: kInputBorder, width: 1),
            ),
            child: Text(
              value ?? placeholder,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w400,
                color: value != null ? const Color(0xFF1E293B) : kPlaceholder,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Primary CTA button
  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: (_isFormValid && !_isLoading) ? _handleAddVisitor : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          disabledBackgroundColor: kPrimary.withOpacity(0.5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kInputRadius),
          ),
          padding: EdgeInsets.symmetric(vertical: 18.h),
        ),
        child: _isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Add Visitor',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
