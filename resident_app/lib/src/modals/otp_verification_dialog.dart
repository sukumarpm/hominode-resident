// lib/src/modals/otp_verification_dialog.dart
// OTP Verification Dialog for 2FA Setup

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/two_factor_service.dart';

/// Show OTP verification dialog for 2FA setup
/// Returns the entered code if verified, null if cancelled
Future<String?> showOTPVerificationDialog(
  BuildContext context, {
  required TwoFactorMethod method,
  String? destination,
  String? qrCode,
  String? secret,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => OTPVerificationDialog(
      method: method,
      destination: destination,
      qrCodeData: qrCode,
      secret: secret,
    ),
  );
}

class OTPVerificationDialog extends StatefulWidget {
  final TwoFactorMethod method;
  final String? destination;
  final String? qrCodeData;
  final String? secret;

  const OTPVerificationDialog({
    super.key,
    required this.method,
    this.destination,
    this.qrCodeData,
    this.secret,
  });

  @override
  State<OTPVerificationDialog> createState() => _OTPVerificationDialogState();
}

class _OTPVerificationDialogState extends State<OTPVerificationDialog> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isResending = false;
  int _resendCountdown = 0;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isCodeComplete => _code.length == 6;

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-submit when all digits are entered
    if (_isCodeComplete) {
      Navigator.pop(context, _code);
    }
  }

  void _onDigitBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _handleResendCode() async {
    if (_resendCountdown > 0) return;

    setState(() => _isResending = true);

    try {
      await TwoFactorService.instance.resend2FACode(widget.method);

      if (!mounted) return;

      setState(() {
        _isResending = false;
        _resendCountdown = 60;
      });

      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent'),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isResending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend code'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              if (widget.method == TwoFactorMethod.authenticatorApp) ...[
                _buildAuthenticatorInstructions(),
                const SizedBox(height: 24),
              ] else ...[
                _buildSMSEmailInstructions(),
                const SizedBox(height: 24),
              ],
              _buildOTPInput(),
              const SizedBox(height: 20),
              if (widget.method != TwoFactorMethod.authenticatorApp)
                _buildResendButton(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E4778).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.security, size: 40, color: Color(0xFF0E4778)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verify Your Identity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatorInstructions() {
    return Column(
      children: [
        const Text(
          'Scan this QR code with your authenticator app',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        // QR Code placeholder
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: widget.qrCodeData != null
              ? Center(
                  child: Text(
                    'QR Code:\n${widget.qrCodeData}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.qr_code_2,
                    size: 100,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
        ),
        if (widget.secret != null) ...[
          const SizedBox(height: 12),
          const Text(
            'Or enter this key manually:',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    widget.secret!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.secret!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Secret key copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Enter the 6-digit code from your app',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildSMSEmailInstructions() {
    final methodName = widget.method == TwoFactorMethod.sms ? 'SMS' : 'email';

    return Column(
      children: [
        Text(
          'We\'ve sent a 6-digit verification code to your $methodName',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        if (widget.destination != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.destination!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOTPInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Container(
          width: 45,
          height: 56,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : 6,
            right: index == 5 ? 0 : 6,
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0E4778),
                  width: 2,
                ),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => _onDigitChanged(index, value),
            onTap: () {
              // Clear the field when tapped
              _controllers[index].clear();
            },
          ),
        );
      }),
    );
  }

  Widget _buildResendButton() {
    return TextButton(
      onPressed: _resendCountdown > 0 || _isResending
          ? null
          : _handleResendCode,
      child: _isResending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              _resendCountdown > 0
                  ? 'Resend code in ${_resendCountdown}s'
                  : 'Resend code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _resendCountdown > 0
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF0E4778),
              ),
            ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isCodeComplete
                ? () => Navigator.pop(context, _code)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF0E4778),
              disabledBackgroundColor: const Color(0xFF93C5FD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Verify',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
