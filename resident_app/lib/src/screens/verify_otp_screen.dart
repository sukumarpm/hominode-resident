import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../components/standard_screen.dart';
import 'loading_screen.dart';

/// Pixel-perfect Verify OTP Screen
/// Reference: iPhone 13 (390px width)
/// Matches design specifications exactly
class VerifyOTPScreen extends StatefulWidget {
  final String? mobileNumber;

  const VerifyOTPScreen({super.key, this.mobileNumber});

  @override
  State<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends State<VerifyOTPScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Add listeners to focus nodes for animations
    for (int i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _animationController.forward();
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isComplete => _otp.length == 6;

  void _onChanged(int index, String value) {
    if (value.isEmpty) {
      // Handle backspace - move to previous box
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      setState(() {});
      return;
    }

    // Handle paste of full OTP (6 digits)
    if (value.length == 6 && RegExp(r'^\d{6}$').hasMatch(value)) {
      for (int i = 0; i < 6 && i < value.length; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes[5].requestFocus();
      setState(() {});
      return;
    }

    // Handle single digit input
    if (value.length > 1) {
      // Take only the last character typed
      _controllers[index].text = value[value.length - 1];
    }

    // Move to next box if current box has a digit
    if (_controllers[index].text.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  Future<void> _handleVerify() async {
    if (!_isComplete) return;

    setState(() => _isLoading = true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      final success = await _authService.verifyOTP(
        widget.mobileNumber ?? '',
        _otp,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        await _authService.saveLoginState(widget.mobileNumber ?? '');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoadingScreen()),
          );
        }
      } else {
        _showSnackBar('Invalid OTP. Please try again.', isError: true);
        _clearOTP();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('An error occurred. Please try again.', isError: true);
    }
  }

  Future<void> _handleResend() async {
    final mobile = widget.mobileNumber ?? '';

    if (mobile.isEmpty) {
      _showSnackBar('Mobile number not found', isError: true);
      return;
    }

    try {
      final success = await _authService.resendOTP(mobile);

      if (success && mounted) {
        _showSnackBar('OTP resent successfully');
        _clearOTP();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to resend OTP', isError: true);
      }
    }
  }

  void _clearOTP() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardScreen(
      title: 'Verify OTP',
      isScrollable: true,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // Main Headline
          const Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Subtext with phone number
          Text(
            "We've sent a verification code to",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF111111).withOpacity(0.7),
              height: 1.5,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.mobileNumber ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0E4778),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 48),

          // OTP INPUT BOXES
          _buildOTPBoxes(),

          const SizedBox(height: 48),

          // Verify Button
          _buildVerifyButton(),

          const SizedBox(height: 20),

          // Resend Link
          _buildResendLink(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOTPBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFocused = _focusNodes[index].hasFocus;
        final hasValue = _controllers[index].text.isNotEmpty;

        return Container(
          width: 52,
          height: 64,
          margin: EdgeInsets.only(right: index < 5 ? 12 : 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFocused
                  ? const Color(0xFF0E4778)
                  : hasValue
                  ? const Color(0xFF0E4778).withOpacity(0.5)
                  : const Color(0xFFD1D5DB),
              width: isFocused ? 2.5 : 2,
            ),
            boxShadow: [
              if (isFocused)
                BoxShadow(
                  color: const Color(0xFF0E4778).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              autofocus: index == 0,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                letterSpacing: 0,
                height: 1.0,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (value) => _onChanged(index, value),
              onTap: () {
                // Select text when tapping on filled box for easy replacement
                if (_controllers[index].text.isNotEmpty) {
                  _controllers[index].selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _controllers[index].text.length,
                  );
                }
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyButton() {
    final isEnabled = _isComplete && !_isLoading;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isEnabled ? _handleVerify : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E4778),
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Verify & Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildResendLink() {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : _handleResend,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              letterSpacing: 0.1,
            ),
            children: [
              TextSpan(text: "Didn't receive code? "),
              TextSpan(
                text: 'Resend',
                style: TextStyle(
                  color: Color(0xFF0E4778),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
