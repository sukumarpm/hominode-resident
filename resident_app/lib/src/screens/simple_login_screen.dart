import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/country_dial_codes.dart';
import '../services/firebase_auth_service.dart';
import '../services/resident_auth_routing.dart';
import 'verify_otp_screen_single_field.dart';

typedef ResidentOtpScreenBuilder =
    Widget Function(String phoneNumber, String verificationId);

class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({super.key, this.authGateway, this.otpScreenBuilder});

  final ResidentPhoneAuthGateway? authGateway;
  final ResidentOtpScreenBuilder? otpScreenBuilder;

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen>
    with SingleTickerProviderStateMixin {
  static const String _countryPreferenceWriteKey =
      'resident_login_country_iso2';
  static const List<String> _countryPreferenceReadKeys = [
    _countryPreferenceWriteKey,
    'phone_country_iso2',
    'selected_country_iso2',
    'phone_country_code',
    'selected_country_code',
  ];

  static const CountryDialCode _defaultCountry = CountryDialCode(
    isoCode: 'PH',
    name: 'Philippines',
    dialCode: '+63',
  );

  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  late final ResidentPhoneAuthGateway _authService;
  late final AnimationController _introController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  bool _isLoading = false;
  bool _navigationStarted = false;
  String? _lastOtpPhone;
  String? _inlineError;
  CountryDialCode _selectedCountry = _defaultCountry;

  @override
  void initState() {
    super.initState();
    _authService = widget.authGateway ?? FirebaseAuthService();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final curve = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    _logoScaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(curve);
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(curve);
    _introController.forward();
    _initializeCountrySelection();
  }

  Future<void> _initializeCountrySelection() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedIsoCode;
    for (final key in _countryPreferenceReadKeys) {
      final value = prefs.getString(key)?.trim();
      if (value != null && value.isNotEmpty) {
        savedIsoCode = value.toUpperCase();
        break;
      }
    }

    final localeIsoCode =
        WidgetsBinding.instance.platformDispatcher.locale.countryCode;

    final selected =
        _countryByIso(savedIsoCode) ??
        _countryByIso(localeIsoCode) ??
        _countryByIso('PH') ??
        _defaultCountry;

    if (!mounted) return;
    setState(() => _selectedCountry = selected);
  }

  CountryDialCode? _countryByIso(String? isoCode) {
    if (isoCode == null || isoCode.trim().isEmpty) return null;
    final upper = isoCode.toUpperCase();
    for (final country in kCountryDialCodes) {
      if (country.isoCode == upper) {
        return country;
      }
    }
    return null;
  }

  Future<void> _saveCountryIsoCode(String isoCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryPreferenceWriteKey, isoCode.toUpperCase());
  }

  String _composeCanonicalPhone() {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) return '';

    if (raw.startsWith('+')) {
      final digits = raw.substring(1).replaceAll(RegExp(r'\D'), '');
      return digits.isEmpty ? '' : '+$digits';
    }

    final dialDigits = _selectedCountry.dialCode.substring(1);
    var localDigits = raw.replaceAll(RegExp(r'\D'), '');
    if (localDigits.startsWith(dialDigits)) {
      localDigits = localDigits.substring(dialDigits.length);
    }
    localDigits = localDigits.replaceFirst(RegExp(r'^0+'), '');

    return '${_selectedCountry.dialCode}$localDigits';
  }

  Future<void> _sendOtp() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _inlineError = null);

    final phone = _composeCanonicalPhone();

    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      _showInlineError('Enter a valid phone number.');
      return;
    }

    final forceResend = _lastOtpPhone == phone;

    setState(() {
      _isLoading = true;
      _navigationStarted = false;
    });

    var callbackFinished = false;

    // Safety fallback: Firebase should never leave the UI loading forever.
    Future.delayed(const Duration(seconds: 65), () {
      if (!mounted || callbackFinished || _navigationStarted || !_isLoading) {
        return;
      }

      callbackFinished = true;

      setState(() {
        _isLoading = false;
        _navigationStarted = false;
      });

      _showInlineError('OTP request timed out. Please try again.');
    });

    try {
      await _authService.sendOtp(
        phoneNumber: phone,

        // If this number already received an OTP in this login session,
        // use Firebase's Android resend token for the next request.
        forceResend: forceResend,

        onCodeSent: (verificationId) {
          if (!mounted || callbackFinished || _navigationStarted) return;

          callbackFinished = true;
          _navigationStarted = true;
          _lastOtpPhone = phone;

          setState(() {
            _inlineError = null;
          });

          Navigator.of(context)
              .push(
                PageRouteBuilder(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  pageBuilder: (_, __, ___) =>
                      widget.otpScreenBuilder?.call(phone, verificationId) ??
                      VerifyOTPScreenSingleField(
                        mobileNumber: phone,
                        verificationId: verificationId,
                        intent: ResidentAuthenticationIntent.login,
                      ),
                ),
              )
              .then((_) {
                if (!mounted) return;

                setState(() {
                  _isLoading = false;
                  _navigationStarted = false;
                });
              });
        },

        onError: (result) {
          if (!mounted || callbackFinished) return;

          callbackFinished = true;

          setState(() {
            _isLoading = false;
            _navigationStarted = false;
          });

          _showInlineError(result.message ?? 'Unable to send OTP.');
        },
      );
    } catch (e, stackTrace) {
      callbackFinished = true;

      debugPrint('SimpleLoginScreen _sendOtp error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _navigationStarted = false;
      });

      _showInlineError('Unable to send OTP. Please try again.');
    }
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

  Widget _buildCountrySelector() {
    final disabled = _isLoading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: disabled ? null : _openCountryPicker,
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2247),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: disabled
                  ? const Color(0xFF18406B)
                  : const Color(0xFF1A4E83),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedCountry.flag, style: TextStyle(fontSize: 16.sp)),
              SizedBox(width: 6.w),
              Text(
                _selectedCountry.dialCode,
                style: TextStyle(
                  color: disabled ? const Color(0xFF8BA9C8) : Colors.white,
                  fontSize: 14.sp.clamp(13.0, 15.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: disabled
                    ? const Color(0xFF6B89AC)
                    : const Color(0xFF7ADFFF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCountryPicker() async {
    final insets = MediaQuery.of(context).viewInsets;
    final selection = await showModalBottomSheet<CountryDialCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final searchController = TextEditingController();
        var filteredCountries = List<CountryDialCode>.from(kCountryDialCodes);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void applySearch(String query) {
              final normalized = query.trim().toLowerCase();
              setSheetState(() {
                if (normalized.isEmpty) {
                  filteredCountries = List<CountryDialCode>.from(
                    kCountryDialCodes,
                  );
                } else {
                  filteredCountries = kCountryDialCodes
                      .where((country) => country.matches(normalized))
                      .toList(growable: false);
                }
              });
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: insets.bottom),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.82,
                  decoration: BoxDecoration(
                    color: const Color(0xFF061A36),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                    border: Border.all(color: const Color(0xFF1A4E83)),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 10.h),
                      Container(
                        width: 44.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D5B88),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select country code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF89CAFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                        child: TextField(
                          controller: searchController,
                          style: const TextStyle(color: Colors.white),
                          onChanged: applySearch,
                          decoration: InputDecoration(
                            hintText: 'Search country or code',
                            hintStyle: const TextStyle(
                              color: Color(0xFF7AA4CF),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF34D9FF),
                            ),
                            suffixIcon: searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      searchController.clear();
                                      applySearch('');
                                    },
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Color(0xFF9EC8FF),
                                    ),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFF082347),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF1A5E96),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF1A5E96),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: const BorderSide(
                                color: Color(0xFF33D6FF),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filteredCountries.isEmpty
                            ? Center(
                                child: Text(
                                  'No countries found',
                                  style: TextStyle(
                                    color: const Color(0xFF9EC8FF),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: filteredCountries.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: const Color(
                                    0xFF1C3E65,
                                  ).withValues(alpha: 0.7),
                                  indent: 16.w,
                                  endIndent: 16.w,
                                ),
                                itemBuilder: (context, index) {
                                  final country = filteredCountries[index];
                                  final isSelected =
                                      country.isoCode ==
                                      _selectedCountry.isoCode;
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 1.h,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          country.flag,
                                          style: TextStyle(fontSize: 20.sp),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: Text(
                                            country.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.sp,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          country.dialCode,
                                          style: TextStyle(
                                            color: const Color(0xFF7ADFFF),
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      country.isoCode,
                                      style: TextStyle(
                                        color: const Color(0xFF83A7CD),
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF31D5FF),
                                          )
                                        : null,
                                    onTap: () =>
                                        Navigator.of(sheetContext).pop(country),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (selection == null || !mounted) return;
    setState(() => _selectedCountry = selection);
    await _saveCountryIsoCode(selection.isoCode);
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: Ink(
          height: 50.h.clamp(46.0, 54.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFF35D8FF), Color(0xFF0F65FF)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF335B6B), Color(0xFF2B4570)],
                  ),
            boxShadow: enabled
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
                    width: 20.w,
                    height: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
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
                                      'Phone Number',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17.sp.clamp(15.0, 17.0),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        _buildCountrySelector(),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: TextField(
                                            controller: _phoneController,
                                            focusNode: _phoneFocusNode,
                                            readOnly: _isLoading,
                                            keyboardType: TextInputType.phone,
                                            textInputAction:
                                                TextInputAction.done,
                                            onChanged: (_) {
                                              if (_inlineError != null) {
                                                setState(
                                                  () => _inlineError = null,
                                                );
                                              }
                                            },
                                            onSubmitted: (_) => _sendOtp(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.sp.clamp(14.0, 16.0),
                                              fontWeight: FontWeight.w500,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: '912 345 6789',
                                              hintStyle: TextStyle(
                                                color: const Color(0xFF7AA4CF),
                                                fontSize: 14.sp,
                                              ),
                                              filled: true,
                                              fillColor: const Color(
                                                0xFF081E40,
                                              ),
                                              prefixIcon: const Icon(
                                                Icons.phone,
                                                color: Color(0xFF2FD5FF),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14.r),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF1A5E96),
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14.r),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF1A5E96),
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14.r),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF33D6FF),
                                                  width: 1.4,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 14.h),
                                    _buildPrimaryButton(
                                      label: 'Send OTP',
                                      onTap: _isLoading ? null : _sendOtp,
                                    ),
                                    SizedBox(height: 8.h),
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
                                      'Your Resident account must already be created by your Community Admin.',
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

  @override
  void dispose() {
    _introController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }
}
