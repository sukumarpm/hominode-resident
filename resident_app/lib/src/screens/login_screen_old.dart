import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/auth_primary_button.dart';
import '../components/auth_text_field.dart';
import '../services/firebase_auth_service.dart';
import '../services/flat_access_control_service.dart';
import 'verify_otp_screen_single_field.dart';

/// Login Screen with Phone OTP and Email/Password options
/// Supports both authentication methods
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Phone OTP controllers
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  // Email/Password controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Handle Phone OTP - Send OTP to phone number
  Future<void> _handleSendOTP() async {
    final phone = _phoneController.text.trim();

    // Validate
    if (!_authService.validatePhoneNumber(phone)) {
      _showError('Please enter a valid 10-digit phone number');
      return;
    }

    setState(() => _isLoading = true);

    // Format to E.164
    final formattedPhone = _authService.formatPhoneNumber(phone);

    await _authService.signInWithPhone(
      phoneNumber: formattedPhone,
      onCodeSent: (verificationId) {
        setState(() => _isLoading = false);
        _showSuccess('OTP sent to $phone');

        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOTPScreenSingleField(
              mobileNumber: phone,
              verificationId: verificationId,
            ),
          ),
        );
      },
      onError: (error) {
        setState(() => _isLoading = false);
        _showError(error);
      },
      onAutoVerify: (credential) async {
        // Auto-verified on Android
        setState(() => _isLoading = false);
        _showSuccess('Phone verified automatically!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      },
    );
  }

  /// Handle Email/Password Login - Flow Function Pattern
  Future<void> _handleEmailLogin() async {
    try {
      print('🔵 _handleEmailLogin: Starting email/password login...');

      final identifier = _emailController.text.trim();
      final password = _passwordController.text;

      // Validate identifier (email or phone)
      if (identifier.isEmpty) {
        _showError('Please enter your email or phone number');
        return;
      }

      // Check if it's a phone number or email
      final isPhone = RegExp(r'^[\d+\s()-]+$').hasMatch(identifier);

      if (!isPhone && !_authService.validateEmail(identifier)) {
        _showError('Please enter a valid email or phone number');
        return;
      }

      if (password.isEmpty) {
        _showError('Please enter your password');
        return;
      }

      print('🔐 Step 1: Validating credentials...');
      setState(() => _isLoading = true);

      final result = await _authService.signInWithEmail(
        email: identifier,
        password: password,
      );

      print('🔐 Step 2: Login result received');
      print('   Success: ${result.success}');
      print('   Message: ${result.message}');
      print('   User ID: ${result.userId}');

      setState(() => _isLoading = false);

      if (result.success) {
        print('✅ Login successful!');
        print('   User: ${result.userData?['name']}');
        print('   FlatId: ${result.userData?['flatId']}');

        _showSuccess('Login successful!');

        // Clear access control cache to force fresh check
        print('🗑️  Clearing access control cache...');
        FlatAccessControlService.instance.clearCache();

        // Wait for Firestore to be fully updated
        print('⏳ Waiting for data sync (1 second)...');
        await Future.delayed(const Duration(seconds: 1));

        print('🔐 Step 3: Navigating to home screen...');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
          print('✅ Navigation initiated');
        }
      } else {
        print('❌ Login failed: ${result.message}');
        _showError(result.message ?? 'Login failed');
      }
    } catch (e, stackTrace) {
      print('❌ Error in _handleEmailLogin: $e');
      print('   Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      _showError('An error occurred. Please try again.');
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleRegister() {
    Navigator.pushNamed(context, '/create-account');
  }

  void _handleForgotPassword() {
    // Show forgot password dialog
    showDialog(
      context: context,
      builder: (context) => _buildForgotPasswordDialog(),
    );
  }

  Widget _buildForgotPasswordDialog() {
    final emailController = TextEditingController();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Reset Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your email to receive password reset link'),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final email = emailController.text.trim();
            if (email.isEmpty || !_authService.validateEmail(email)) {
              _showError('Please enter a valid email');
              return;
            }

            Navigator.pop(context);

            final result = await _authService.sendPasswordResetEmail(
              email: email,
            );
            if (result.success) {
              _showSuccess('Password reset email sent!');
            } else {
              _showError(result.message ?? 'Failed to send reset email');
            }
          },
          child: const Text('Send'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2F80ED), // Gradient Top
                Color(0xFF2563EB), // Gradient Bottom
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 120),

                    // Welcome Back Title
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFFFFF),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    const Text(
                      'Login to your Hominode account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFF0F0F0),
                        letterSpacing: 0.1,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // White Card Container with Tabs
                    _buildLoginCard(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE0E0E0), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF666666),
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Phone OTP'),
                Tab(text: 'Email'),
              ],
            ),
          ),

          // Tab Content
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [_buildPhoneOTPTab(), _buildEmailPasswordTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneOTPTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Login with Phone',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Phone Number',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 10),
          AuthTextField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            hintText: 'Enter 10-digit phone number',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSendOTP(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            maxLength: 10,
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            text: 'Send OTP',
            onPressed: _handleSendOTP,
            isLoading: _isLoading,
            isEnabled: !_isLoading,
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/create-account'),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                  children: [
                    TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Login with Email',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Email or Phone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 10),
          AuthTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            hintText: 'Enter your email or phone number',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleEmailLogin(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
              ),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF111111).withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF666666),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _handleForgotPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          AuthPrimaryButton(
            text: 'Login',
            onPressed: _handleEmailLogin,
            isLoading: _isLoading,
            isEnabled: !_isLoading,
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/create-account'),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                  children: [
                    TextSpan(text: "Don't have an account? "),
                    TextSpan(
                      text: 'Register',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
