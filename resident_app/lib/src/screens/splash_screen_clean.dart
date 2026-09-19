import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Resident production splash screen.
///
/// Uses the Resident background artwork and Resident icon so the Flutter
/// startup screen matches the Resident app theme.
class CleanSplashScreen extends StatefulWidget {
  final String logoAssetPath;
  final String? appName;
  final String? tagline;
  final Duration duration;
  final VoidCallback? onFinish;
  final Color primaryColor;
  final Color secondaryColor;

  const CleanSplashScreen({
    super.key,
    this.logoAssetPath = 'lib/assets/Resident_New.png',
    this.appName = 'Hominode',
    this.tagline = 'Your Community, Connected',
    this.duration = const Duration(milliseconds: 3000),
    this.onFinish,
    this.primaryColor = const Color(0xFF06182B),
    this.secondaryColor = const Color(0xFF0E4778),
  });

  @override
  State<CleanSplashScreen> createState() => _CleanSplashScreenState();
}

class _CleanSplashScreenState extends State<CleanSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textOffset;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF06182B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textOffset = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    _textController.forward();

    await Future.delayed(widget.duration);
    if (!mounted) return;

    widget.onFinish?.call();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF06182B),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: widget.primaryColor,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'lib/assets/images/resident_login_background.png',
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.secondaryColor.withValues(alpha: 0.20),
                    widget.primaryColor.withValues(alpha: 0.42),
                    widget.primaryColor.withValues(alpha: 0.72),
                  ],
                  stops: const [0.0, 0.56, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: _logoController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: _logoOpacity.value,
                                  child: Transform.scale(
                                    scale: _logoScale.value,
                                    child: Image.asset(
                                      widget.logoAssetPath,
                                      width: 132.w,
                                      height: 132.w,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 24.h),
                            FadeTransition(
                              opacity: _textOpacity,
                              child: SlideTransition(
                                position: _textOffset,
                                child: Column(
                                  children: [
                                    Text(
                                      widget.appName ?? 'Hominode',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 30.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 7.h),
                                    Text(
                                      widget.tagline ??
                                          'Your Community, Connected',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(
                                          alpha: 0.90,
                                        ),
                                        letterSpacing: 0.25,
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
                  Padding(
                    padding: EdgeInsets.only(bottom: 34.h),
                    child: SizedBox(
                      width: 30.w,
                      height: 30.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.8,
                        color: Color(0xFF31D6E5),
                        backgroundColor: Color(0x33FFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
