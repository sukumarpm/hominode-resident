import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Configuration for splash screen animations and timing
class SplashConfig {
  // Animation durations (in milliseconds)
  static const int logoEntryDuration = 600;
  static const int shadowDuration = 550;
  static const int squashDuration = 90;
  static const int taglineDuration = 400;
  static const int holdDuration = 650;
  static const int transitionDuration = 300;
  static const int totalDuration = 2200;

  // Animation delays (in milliseconds)
  static const int shadowDelay = 350;
  static const int squashDelay = 600;
  static const int taglineDelay = 850;
  static const int particlesDelay = 600;
  static const int transitionDelay = 1900;

  // Easing curves
  static const Curve logoEntryCurve = Curves.easeOutBack;
  static const Curve shadowCurve = Curves.easeOut;
  static const Curve taglineCurve = Curves.easeOut;
  static const Curve transitionCurve = Curves.easeInOut;

  // Animation values
  static const double logoInitialScale = 0.6;
  static const double logoOvershoot = 1.05;
  static const double logoInitialRotation = -3.0; // degrees
  static const double logoInitialY = 20.0;
  static const double squashScaleX = 1.08;
  static const double squashScaleY = 0.94;
  static const double taglineInitialY = 12.0;
  static const double transitionScale = 0.98;

  // Colors
  static const Color gradientStart = Color(0xFF3AA6C8);
  static const Color gradientEnd = Color(0xFF0E4778);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color shadowColor = Color(0x59000000); // rgba(0,0,0,0.35)

  // Typography
  static const double appNameSize = 32.0;
  static const double taglineSize = 16.0;
  static const FontWeight appNameWeight = FontWeight.w600;
  static const FontWeight taglineWeight = FontWeight.w400;
  static const double taglineOpacity = 0.9;

  // Performance
  static const bool enableParticles = false; // Set to true for particles
  static const int particleCount = 4;
}

/// Modern animated splash screen with physics-based micro-interactions
class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final bool reduceMotion;
  final bool simulateSlowDevice;

  const AnimatedSplashScreen({
    super.key,
    this.onAnimationComplete,
    this.reduceMotion = false,
    this.simulateSlowDevice = false,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _squashController;

  // Logo animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _logoY;

  // Shadow & depth animations
  late Animation<double> _shadowOpacity;
  late Animation<double> _shadowBlur;
  late Animation<double> _reflectionOpacity;

  // Tagline animations
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineY;

  // Transition animations
  late Animation<double> _transitionOpacity;
  late Animation<double> _transitionScale;

  // Squash & stretch
  late Animation<double> _squashScaleX;
  late Animation<double> _squashScaleY;

  // Particle animations (optional)
  final List<Animation<double>> _particleY = [];
  final List<Animation<double>> _particleOpacity = [];

  bool _shouldReduceMotion = false;

  @override
  void initState() {
    super.initState();
    _checkReducedMotion();
    _initializeAnimations();
    _startAnimation();
  }

  void _checkReducedMotion() {
    // Check platform accessibility settings
    final platformDispatcher = SchedulerBinding.instance.platformDispatcher;
    _shouldReduceMotion =
        widget.reduceMotion ||
        widget.simulateSlowDevice ||
        platformDispatcher.accessibilityFeatures.reduceMotion;
  }

  void _initializeAnimations() {
    // Master controller for main timeline
    _masterController = AnimationController(
      duration: Duration(milliseconds: SplashConfig.totalDuration),
      vsync: this,
    );

    // Squash controller for micro bounce
    _squashController = AnimationController(
      duration: Duration(milliseconds: SplashConfig.squashDuration),
      vsync: this,
    );

    if (_shouldReduceMotion) {
      _initializeReducedMotionAnimations();
    } else {
      _initializeFullAnimations();
    }
  }

  void _initializeReducedMotionAnimations() {
    // Simple fade-in for reduced motion
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 1.0, end: 1.0).animate(_masterController);
    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_masterController);
    _logoY = Tween<double>(begin: 0.0, end: 0.0).animate(_masterController);

    _shadowOpacity = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_masterController);
    _shadowBlur = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_masterController);
    _reflectionOpacity = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_masterController);

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.3, 0.5, curve: Curves.easeIn),
      ),
    );
    _taglineY = Tween<double>(begin: 0.0, end: 0.0).animate(_masterController);

    _transitionOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
      ),
    );
    _transitionScale = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(_masterController);

    _squashScaleX = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(_squashController);
    _squashScaleY = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(_squashController);
  }

  void _initializeFullAnimations() {
    // 1. LOGO ENTRY (0.0s → 0.6s)
    _logoScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(
              begin: SplashConfig.logoInitialScale,
              end: SplashConfig.logoOvershoot,
            ).chain(CurveTween(curve: SplashConfig.logoEntryCurve)),
            weight: 1.0,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: Interval(
              0.0,
              SplashConfig.logoEntryDuration / SplashConfig.totalDuration,
            ),
          ),
        );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: Interval(
          0.0,
          SplashConfig.logoEntryDuration / SplashConfig.totalDuration,
        ),
      ),
    );

    _logoRotation =
        Tween<double>(
          begin: SplashConfig.logoInitialRotation,
          end: 0.0,
        ).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: Interval(
              0.0,
              SplashConfig.logoEntryDuration / SplashConfig.totalDuration,
              curve: SplashConfig.logoEntryCurve,
            ),
          ),
        );

    _logoY = Tween<double>(begin: SplashConfig.logoInitialY, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: Interval(
          0.0,
          SplashConfig.logoEntryDuration / SplashConfig.totalDuration,
          curve: SplashConfig.logoEntryCurve,
        ),
      ),
    );

    // 2. SHADOW & DEPTH (0.35s → 0.9s)
    _shadowOpacity = Tween<double>(begin: 0.0, end: 0.35).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: Interval(
          SplashConfig.shadowDelay / SplashConfig.totalDuration,
          (SplashConfig.shadowDelay + SplashConfig.shadowDuration) /
              SplashConfig.totalDuration,
          curve: SplashConfig.shadowCurve,
        ),
      ),
    );

    _shadowBlur = Tween<double>(begin: 8.0, end: 24.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: Interval(
          SplashConfig.shadowDelay / SplashConfig.totalDuration,
          (SplashConfig.shadowDelay + SplashConfig.shadowDuration) /
              SplashConfig.totalDuration,
          curve: SplashConfig.shadowCurve,
        ),
      ),
    );

    _reflectionOpacity = Tween<double>(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: Interval(
          SplashConfig.shadowDelay / SplashConfig.totalDuration,
          (SplashConfig.shadowDelay + SplashConfig.shadowDuration) /
              SplashConfig.totalDuration,
          curve: SplashConfig.shadowCurve,
        ),
      ),
    );

    // 3. SQUASH & SETTLE (0.6s → 0.9s) - micro bounce
    _squashScaleX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: SplashConfig.squashScaleX),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: SplashConfig.squashScaleX, end: 1.0),
        weight: 0.5,
      ),
    ]).animate(_squashController);

    _squashScaleY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: SplashConfig.squashScaleY),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: SplashConfig.squashScaleY, end: 1.0),
        weight: 0.5,
      ),
    ]).animate(_squashController);

    // 4. TAGLINE (0.85s → 1.25s)
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: Interval(
          SplashConfig.taglineDelay / SplashConfig.totalDuration,
          (SplashConfig.taglineDelay + SplashConfig.taglineDuration) /
              SplashConfig.totalDuration,
          curve: SplashConfig.taglineCurve,
        ),
      ),
    );

    _taglineY = Tween<double>(begin: SplashConfig.taglineInitialY, end: 0.0)
        .animate(
          CurvedAnimation(
            parent: _masterController,
            curve: Interval(
              SplashConfig.taglineDelay / SplashConfig.totalDuration,
              (SplashConfig.taglineDelay + SplashConfig.taglineDuration) /
                  SplashConfig.totalDuration,
              curve: SplashConfig.taglineCurve,
            ),
          ),
        );

    // 5. TRANSITION (1.9s → 2.2s)
    _transitionOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: Interval(
          SplashConfig.transitionDelay / SplashConfig.totalDuration,
          1.0,
          curve: SplashConfig.transitionCurve,
        ),
      ),
    );

    _transitionScale =
        Tween<double>(begin: 1.0, end: SplashConfig.transitionScale).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: Interval(
              SplashConfig.transitionDelay / SplashConfig.totalDuration,
              1.0,
              curve: SplashConfig.transitionCurve,
            ),
          ),
        );

    // 6. PARTICLES (optional, 0.6s → 1.6s)
    if (SplashConfig.enableParticles) {
      _initializeParticles();
    }
  }

  void _initializeParticles() {
    for (int i = 0; i < SplashConfig.particleCount; i++) {
      final delay = (i * 150) / SplashConfig.totalDuration;
      final duration = 1000 / SplashConfig.totalDuration;

      _particleY.add(
        Tween<double>(begin: 0.0, end: -80.0 - (i * 20)).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: Interval(delay, delay + duration, curve: Curves.easeOut),
          ),
        ),
      );

      _particleOpacity.add(
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 0.08),
            weight: 0.3,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.08, end: 0.0),
            weight: 0.7,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: Interval(delay, delay + duration),
          ),
        ),
      );
    }
  }

  void _startAnimation() {
    _masterController.forward();

    // Trigger squash animation at the right time
    if (!_shouldReduceMotion) {
      Future.delayed(Duration(milliseconds: SplashConfig.squashDelay), () {
        if (mounted) {
          _squashController.forward();
        }
      });
    }

    // Navigate to home after animation completes
    _masterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    _squashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_masterController, _squashController]),
        builder: (context, child) {
          return Opacity(
            opacity: _transitionOpacity.value,
            child: Transform.scale(
              scale: _transitionScale.value,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      SplashConfig.gradientStart,
                      SplashConfig.gradientEnd,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle radial vignette
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            Colors.white.withValues(alpha: 0.03),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // Particles (optional)
                    if (SplashConfig.enableParticles && !_shouldReduceMotion)
                      ..._buildParticles(),

                    // Main content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with all animations
                          _buildAnimatedLogo(),

                          const SizedBox(height: 24),

                          // App name
                          Opacity(
                            opacity: _taglineOpacity.value,
                            child: Transform.translate(
                              offset: Offset(0, _taglineY.value),
                              child: const Text(
                                'Hominode',
                                style: TextStyle(
                                  fontSize: SplashConfig.appNameSize,
                                  fontWeight: SplashConfig.appNameWeight,
                                  color: SplashConfig.textWhite,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Tagline
                          Opacity(
                            opacity:
                                _taglineOpacity.value *
                                SplashConfig.taglineOpacity,
                            child: Transform.translate(
                              offset: Offset(0, _taglineY.value),
                              child: const Text(
                                'Your Community, Connected',
                                style: TextStyle(
                                  fontSize: SplashConfig.taglineSize,
                                  fontWeight: SplashConfig.taglineWeight,
                                  color: SplashConfig.textWhite,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return Hero(
      tag: 'appLogoHero',
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Reflection layer (behind logo)
          if (!_shouldReduceMotion)
            Opacity(
              opacity: _reflectionOpacity.value,
              child: Transform.translate(
                offset: const Offset(0, 8),
                child: Transform.scale(
                  scale: (_logoScale.value * 0.95) * _squashScaleX.value,
                  scaleY: (_logoScale.value * 0.95) * _squashScaleY.value,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: _buildLogoImage(opacity: 0.4),
                  ),
                ),
              ),
            ),

          // Shadow
          if (!_shouldReduceMotion)
            Opacity(
              opacity: _shadowOpacity.value,
              child: Transform.translate(
                offset: Offset(0, _logoY.value + 4),
                child: Transform.scale(
                  scale: _logoScale.value * _squashScaleX.value,
                  scaleY: _logoScale.value * _squashScaleY.value,
                  child: Transform.rotate(
                    angle: _logoRotation.value * 3.14159 / 180,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: SplashConfig.shadowColor,
                            blurRadius: _shadowBlur.value,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Main logo
          Opacity(
            opacity: _logoOpacity.value,
            child: Transform.translate(
              offset: Offset(0, _logoY.value),
              child: Transform.scale(
                scale: _logoScale.value * _squashScaleX.value,
                scaleY: _logoScale.value * _squashScaleY.value,
                child: Transform.rotate(
                  angle: _logoRotation.value * 3.14159 / 180,
                  child: _buildLogoImage(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoImage({double opacity = 1.0}) {
    // Try to load logo1.png for splash screen, fallback to logo.png, then custom design
    return Image.asset(
      'assets/logo1.png',
      width: 140,
      height: 140,
      fit: BoxFit.contain,
      opacity: AlwaysStoppedAnimation(opacity),
      errorBuilder: (context, error, stackTrace) {
        // Try logo.png as fallback
        return Image.asset(
          'assets/logo.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
          opacity: AlwaysStoppedAnimation(opacity),
          errorBuilder: (context, error2, stackTrace2) {
            // Beautiful fallback logo matching your design
            return SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _LyvoLogoFallbackPainter(opacity: opacity),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(SplashConfig.particleCount, (index) {
      final xOffset = (index % 2 == 0 ? -1 : 1) * (40 + index * 20.0);
      return Positioned(
        left: MediaQuery.of(context).size.width / 2 + xOffset,
        top: MediaQuery.of(context).size.height / 2,
        child: Opacity(
          opacity: _particleOpacity[index].value,
          child: Transform.translate(
            offset: Offset(0, _particleY[index].value),
            child: Container(
              width: 8 + (index * 2.0),
              height: 8 + (index * 2.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Fallback logo painter matching Hominode design
class _LyvoLogoFallbackPainter extends CustomPainter {
  final double opacity;

  _LyvoLogoFallbackPainter({this.opacity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color(0xFF061C4C).withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.fill;

    // Draw two stylized slanted rectangles matching your logo
    // Left larger rectangle
    final path1 = Path()
      ..moveTo(size.width * 0.25, size.height * 0.2)
      ..lineTo(size.width * 0.42, size.height * 0.2)
      ..lineTo(size.width * 0.52, size.height * 0.8)
      ..lineTo(size.width * 0.35, size.height * 0.8)
      ..close();

    // Right smaller rectangle
    final path2 = Path()
      ..moveTo(size.width * 0.55, size.height * 0.28)
      ..lineTo(size.width * 0.68, size.height * 0.28)
      ..lineTo(size.width * 0.75, size.height * 0.72)
      ..lineTo(size.width * 0.62, size.height * 0.72)
      ..close();

    // Draw shadows first
    canvas.save();
    canvas.translate(3, 3);
    canvas.drawPath(path1, shadowPaint);
    canvas.drawPath(path2, shadowPaint);
    canvas.restore();

    // Draw main shapes
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
