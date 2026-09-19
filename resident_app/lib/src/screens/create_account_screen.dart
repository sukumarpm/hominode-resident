import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_auth_service.dart';
import '../services/resident_database_service.dart';

/// Create Account Screen with Email/Phone and Password
///
/// Features:
/// - Email or Phone Number input
/// - Password with validation
/// - Block and Flat Number
/// - Firebase Authentication integration
/// - Firestore user data storage
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _flatController = TextEditingController();

  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _emailPhoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _blockFocusNode = FocusNode();
  final FocusNode _flatFocusNode = FocusNode();

  final FirebaseAuthService _authService = FirebaseAuthService();
  final ResidentDatabaseService _databaseService = ResidentDatabaseService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _fullNameError;
  String? _emailPhoneError;
  String? _passwordError;
  String? _blockError;
  String? _flatError;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_validateForm);
    _emailPhoneController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _blockController.addListener(_validateForm);
    _flatController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _blockController.dispose();
    _flatController.dispose();
    _fullNameFocusNode.dispose();
    _emailPhoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _blockFocusNode.dispose();
    _flatFocusNode.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {});
  }

  bool get _isFormValid {
    return _fullNameController.text.trim().isNotEmpty &&
        _emailPhoneController.text.trim().isNotEmpty &&
        _passwordController.text.trim().length >= 6 &&
        _blockController.text.trim().isNotEmpty &&
        _flatController.text.trim().isNotEmpty;
  }

  bool _validateFields() {
    bool isValid = true;
    setState(() {
      _fullNameError = null;
      _emailPhoneError = null;
      _passwordError = null;
      _blockError = null;
      _flatError = null;
    });

    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _fullNameError = 'Full name is required');
      isValid = false;
    }

    final emailOrPhone = _emailPhoneController.text.trim();
    if (emailOrPhone.isEmpty) {
      setState(() => _emailPhoneError = 'Email or phone number is required');
      isValid = false;
    } else if (!_authService.validateEmail(emailOrPhone) &&
        !_authService.validatePhoneNumber(emailOrPhone)) {
      setState(
        () => _emailPhoneError =
            'Please enter a valid email or 10-digit phone number',
      );
      isValid = false;
    }

    final passwordValidation = _authService.validatePassword(
      _passwordController.text,
    );
    if (passwordValidation != null) {
      setState(() => _passwordError = passwordValidation);
      isValid = false;
    }

    if (_blockController.text.trim().isEmpty) {
      setState(() => _blockError = 'Block is required');
      isValid = false;
    }

    if (_flatController.text.trim().isEmpty) {
      setState(() => _flatError = 'Flat number is required');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleCreateAccount() async {
    if (!_validateFields()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final emailOrPhone = _emailPhoneController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();
      final block = _blockController.text.trim();
      final flat = _flatController.text.trim();

      print('🔵 Starting registration process...');
      print('📧 Email/Phone: $emailOrPhone');
      print('👤 Full Name: $fullName');

      AuthResult result;
      String actualEmail = emailOrPhone;
      String? phoneNumber;

      // Check if input is email or phone number
      if (_authService.validateEmail(emailOrPhone)) {
        // Create account with email
        print('📧 Creating account with email...');
        result = await _authService.createAccountWithEmail(
          email: emailOrPhone,
          password: password,
        );
      } else {
        // For phone number, convert to email format
        phoneNumber = emailOrPhone;
        actualEmail = '$emailOrPhone@resident.app';
        print('📱 Creating account with phone: $phoneNumber');
        result = await _authService.createAccountWithEmail(
          email: actualEmail,
          password: password,
        );
      }

      print('✅ Auth result: ${result.success}');
      print('🆔 User ID: ${result.user?.uid}');

      if (result.success && result.user != null) {
        // Update display name in Firebase Auth
        await _authService.updateProfile(displayName: fullName);
        print('✅ Display name updated');

        // Create user document in Firestore
        print('💾 Creating Firestore document...');
        final dbResult = await _databaseService.createUser(
          userId: result.user!.uid,
          fullName: fullName,
          email: actualEmail,
          phoneNumber: phoneNumber,
          role: 'resident',
        );

        print('💾 Firestore result: ${dbResult.success}');
        print('💾 Message: ${dbResult.message}');
        if (!dbResult.success) {
          print('❌ Error code: ${dbResult.errorCode}');
        }

        setState(() => _isLoading = false);

        if (dbResult.success && mounted) {
          _showSuccess('Account created successfully!');
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            // Navigate to Setup Profile screen or Home
            Navigator.pushReplacementNamed(context, '/setup-profile');
          }
        } else {
          // Auth succeeded but Firestore failed
          _showError(dbResult.message ?? 'Failed to save user data');
        }
      } else {
        setState(() => _isLoading = false);
        _showError(result.message ?? 'Failed to create account');
      }
    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      _showError('An error occurred. Please try again.');
      print('❌ Create account error: $e');
      print('📍 Stack trace: $stackTrace');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
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
                      'Enter your details to register',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Full Name
                    _buildInputField(
                      label: 'Full Name',
                      controller: _fullNameController,
                      focusNode: _fullNameFocusNode,
                      hintText: 'Enter your full name',
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      error: _fullNameError,
                      onSubmitted: (_) => _emailPhoneFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 18),

                    // Email or Phone Number
                    _buildInputField(
                      label: 'Email or Phone Number',
                      controller: _emailPhoneController,
                      focusNode: _emailPhoneFocusNode,
                      hintText: 'Enter email or phone number',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      error: _emailPhoneError,
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 18),

                    // Password
                    _buildPasswordField(),
                    const SizedBox(height: 18),

                    // Block and Flat Number (side by side)
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Block',
                            controller: _blockController,
                            focusNode: _blockFocusNode,
                            hintText: 'A',
                            textInputAction: TextInputAction.next,
                            error: _blockError,
                            onSubmitted: (_) => _flatFocusNode.requestFocus(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            label: 'Flat Number',
                            controller: _flatController,
                            focusNode: _flatFocusNode,
                            hintText: '101',
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            error: _flatError,
                            onSubmitted: (_) {
                              if (_isFormValid) {
                                _handleCreateAccount();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Continue Button
                    _buildContinueButton(),
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
                'Create Account',
                style: TextStyle(
                  fontSize: 20,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? error,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
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
              inputFormatters: inputFormatters,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111111),
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 14,
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

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _passwordError != null
                  ? Colors.red
                  : const Color(0xFFE5E5E5),
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
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _blockFocusNode.requestFocus(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
            ),
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFA3A3A3),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF666666),
                  size: 20,
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
        if (_passwordError != null) ...[
          const SizedBox(height: 6),
          Text(
            _passwordError!,
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

  Widget _buildContinueButton() {
    final isEnabled = _isFormValid && !_isLoading;

    return Semantics(
      label: 'Continue button',
      button: true,
      enabled: isEnabled,
      child: GestureDetector(
        onTap: isEnabled ? _handleCreateAccount : null,
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
                    'Continue',
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
