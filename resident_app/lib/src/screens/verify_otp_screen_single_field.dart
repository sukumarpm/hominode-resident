import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../services/firebase_auth_service.dart';
import '../services/resident_auth_routing.dart';
import '../services/tenant_resolution_service.dart';

/// OTP Screen with Single TextField Input
/// Firebase Phone Authentication OTP Verification
class VerifyOTPScreenSingleField extends StatefulWidget {
  final String? mobileNumber;
  final String? verificationId;
  final ResidentAuthenticationIntent intent;

  const VerifyOTPScreenSingleField({
    super.key,
    this.mobileNumber,
    this.verificationId,
    this.intent = ResidentAuthenticationIntent.login,
  });

  @override
  State<VerifyOTPScreenSingleField> createState() =>
      _VerifyOTPScreenSingleFieldState();
}

class _VerifyOTPScreenSingleFieldState extends State<VerifyOTPScreenSingleField>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;
  late String? _verificationId;
  String? _inlineError;

  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final curve = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(curve);
    _logoScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(curve);
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(curve);
    _introController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        _otpFocusNode.requestFocus();
      });
    });

    _otpController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String get _otp => _otpController.text;
  bool get _isComplete => _otp.length == 6;

  void _onChanged(String value) {
    // Only allow digits
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 6 digits
    if (digitsOnly.length <= 6) {
      _otpController.value = TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
    }

    setState(() {});
  }

  Future<void> _handleVerify() async {
    if (!_isComplete) return;

    setState(() {
      _isLoading = true;
      _inlineError = null;
    });

    try {
      final result = await _authService.verifyOtp(
        smsCode: _otp,
        verificationId: _verificationId,
        tenantResolver: context.read<TenantResolutionService>(),
      );

      if (!mounted) return;

      final routedResult = ResidentAuthRouting.resultForIntent(
        result,
        widget.intent,
      );

      if (routedResult.success) {
        ResidentAuthRouting.navigateToResult(context, routedResult);
      } else {
        if (result.state == ResidentAuthState.registrationRequired &&
            widget.intent == ResidentAuthenticationIntent.login) {
          await _authService.signOut(context.read<TenantResolutionService>());
        }
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showInlineError(
          routedResult.message ?? 'Unable to complete authentication.',
        );
        if (routedResult.errorCode == 'invalid-verification-code') {
          _clearOTP();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showInlineError('An error occurred. Please try again.');
    }
  }

  Future<void> _handleResend() async {
    final mobile = widget.mobileNumber ?? '';

    if (mobile.isEmpty) {
      _showInlineError('Mobile number not found');
      return;
    }

    setState(() {
      _isLoading = true;
      _inlineError = null;
    });

    final formattedPhone = _authService.formatPhoneNumber(mobile);

    await _authService.sendOtp(
      phoneNumber: formattedPhone,
      forceResend: true,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _inlineError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      },
      onError: (result) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showInlineError(result.message ?? 'Unable to resend OTP.');
      },
    );
  }

  void _changeNumber() {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _inlineError = null;
      _verificationId = null;
    });
    _clearOTP();
    Navigator.of(context).pop();
  }

  void _clearOTP() {
    _otpController.clear();
    _otpFocusNode.requestFocus();
    setState(() {});
  }

  void _showInlineError(String message) {
    final value = message.trim();
    if (value.isEmpty) return;
    setState(() => _inlineError = value);
  }

  void _showContactAdmin() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF081B3C),
        title: const Text(
          'Contact Admin',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your Resident account is created and managed by your Community Admin. Contact your Community Admin if you cannot access your account.',
          style: TextStyle(color: Color(0xFFB8D7F6), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'lib/assets/images/resident_login_background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xAA02102B),
                    Color(0xCC031632),
                    Color(0xE603132D),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardMaxWidth = constraints.maxWidth > 620
                      ? 520.0
                      : 600.0;

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      12.h,
                      20.w,
                      (insets.bottom + 16.h).clamp(16.0, 220.0),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _logoScaleAnimation,
                            child: Column(
                              children: [
                                SizedBox(height: 2.h),
                                Image.asset(
                                  'lib/assets/Resident_New.png',
                                  width: (constraints.maxWidth * 0.33).clamp(
                                    120.0,
                                    200.0,
                                  ),
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'HOMINODE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24.sp.clamp(20.0, 24.0),
                                    letterSpacing: 1.8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 5.h),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Smart ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.sp.clamp(12.0, 14.0),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'place. Better lives.',
                                        style: TextStyle(
                                          color: const Color(0xFF30D3FF),
                                          fontSize: 14.sp.clamp(12.0, 14.0),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: const Color(0x1A3DD2FF),
                                    border: Border.all(
                                      color: const Color(0x6633D9FF),
                                    ),
                                  ),
                                  child: Text(
                                    'Resident Access',
                                    style: TextStyle(
                                      color: const Color(0xFF88E8FF),
                                      fontSize: 11.sp.clamp(11.0, 12.0),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SlideTransition(
                            position: _cardSlideAnimation,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: cardMaxWidth,
                              ),
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xCC061B3B),
                                  borderRadius: BorderRadius.circular(24.r),
                                  border: Border.all(
                                    color: const Color(0xFF1E5E99),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF28CFFF,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 26,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Verify OTP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.sp.clamp(18.0, 20.0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      'Code sent to ${widget.mobileNumber ?? ''}',
                                      style: TextStyle(
                                        color: const Color(0xFF9EC8FF),
                                        fontSize: 12.sp.clamp(12.0, 14.0),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _changeNumber,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size(0, 30.h),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          foregroundColor: const Color(
                                            0xFF54DFFF,
                                          ),
                                        ),
                                        child: Text(
                                          'Wrong number? Change number',
                                          style: TextStyle(
                                            fontSize: 13.sp.clamp(12.0, 13.0),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    _buildOTPInput(),
                                    SizedBox(height: 14.h),
                                    _buildVerifyButton(),
                                    SizedBox(height: 6.h),
                                    _buildResendLink(),
                                    _buildInlineError(),
                                    SizedBox(height: 10.h),
                                    _buildSecureAccessRow(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xA8071A38),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color(0xFF1B4679),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    color: Color(0xFF32D8FF),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      'Your resident account access depends on your community profile status.',
                                      style: TextStyle(
                                        color: const Color(0xFFE5F4FF),
                                        height: 1.4,
                                        fontSize: 12.sp.clamp(11.0, 12.0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          TextButton(
                            onPressed: _showContactAdmin,
                            child: Text(
                              'Need help? Contact Admin',
                              style: TextStyle(
                                color: const Color(0xFF6CE2FF),
                                fontSize: 12.sp.clamp(11.0, 13.0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPInput() {
    return GestureDetector(
      onTap: () => _otpFocusNode.requestFocus(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFF081E40),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: _otpFocusNode.hasFocus
                ? const Color(0xFF33D6FF)
                : const Color(0xFF1A5E96),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: _otpFocusNode.hasFocus
                  ? const Color(0xFF22D2FF).withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.10),
              blurRadius: _otpFocusNode.hasFocus ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final hasDigit = index < _otp.length;
                final digit = hasDigit ? _otp[index] : '';

                return Container(
                  width: 34.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: hasDigit
                            ? const Color(0xFF33D6FF)
                            : const Color(0xFF2B547F),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      digit,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                );
              }),
            ),

            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  style: const TextStyle(color: Colors.transparent),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: _onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    final isEnabled = _isComplete && !_isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: isEnabled ? _handleVerify : null,
        child: Ink(
          height: 50.h.clamp(46.0, 54.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [Color(0xFF35D8FF), Color(0xFF0F65FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF335B6B), Color(0xFF2B4570)],
                  ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF22D2FF).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify OTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp.clamp(14.0, 16.0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 24.w.clamp(22.0, 28.0),
                        height: 24.w.clamp(22.0, 28.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 14.w,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : _handleResend,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF7ADFFF),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Resend OTP',
            style: TextStyle(
              fontSize: 12.sp.clamp(12.0, 13.0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineError() {
    final message = _inlineError;
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0x662A1020),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFB95673)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF8CA8), size: 18),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFFFFD5DE),
                fontSize: 12.sp.clamp(12.0, 13.0),
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecureAccessRow() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFF1A4E83))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFF34D9FF),
                size: 18,
              ),
              SizedBox(width: 8.w),
              Text(
                'SECURE RESIDENT ACCESS',
                style: TextStyle(
                  color: const Color(0xFF34D9FF),
                  fontSize: 10.sp.clamp(10.0, 11.0),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFF1A4E83))),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inlineError != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _inlineError = args.trim();
    }
  }
}
