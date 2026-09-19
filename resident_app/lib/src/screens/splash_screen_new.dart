import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Production-ready Splash Screen with animated waves and logo zoom
///
/// Features:
/// - Deep blue gradient background (#2563EB → #1E40AF)
/// - Animated translucent wave layers with parallax effect
/// - Logo zoom-in animation with overshoot and breathing loop
/// - Respects reduced motion accessibility settings
/// - GPU-optimized animations
///
/// Usage:
/// ```dart
/// SplashScreen(
///   logoAssetPath: 'assets/logo1.png',
///   duration: Duration(seconds: 3),
///   onFinish: () => Navigator.pushReplacement(...),
/// )
/// ```
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final String logoAssetPath;
  final VoidCallback? onFinish;
  final String? appName;
  final String? tagline;

  const SplashScreen({
    super.key,
    this.duration = const Duration(seconds: 10),
    this.logoAssetPath = 'assets/logo1.png',
    this.onFinish,
    this.appName = 'Hominode',
    this.tagline = 'Your Community, Connected',
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _logoController;
  late AnimationController _breathingController;
  late AnimationController _fadeController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _breathing;
  late Animation<double> _fadeIn;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    // Check for reduced motion preference
    _reduceMotion = false; // Will be set from MediaQuery in build

    // Wave animation (continuous loop)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Logo zoom animation (longer for cooler effect)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Logo scale: 0.6 → 1.05 → 1.0 with overshoot
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.6,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_logoController);

    // Logo opacity: 0 → 1
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Breathing animation (more pronounced pulse)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _breathing = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
  }

  void _startAnimations() {
    // Fade in immediately
    _fadeController.forward();

    // Start logo animation after 300ms for dramatic effect
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _logoController.forward().then((_) {
          // Start breathing loop after logo settles
          if (mounted && !_reduceMotion) {
            _breathingController.repeat(reverse: true);
          }
        });
      }
    });

    // Call onFinish after duration
    Future.delayed(widget.duration, () {
      if (mounted && widget.onFinish != null) {
        widget.onFinish!();
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _logoController.dispose();
    _breathingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check for reduced motion
    _reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Semantics(
        label: 'Splash screen with app logo',
        child: Scaffold(
          body: FadeTransition(
            opacity: _fadeIn,
            child: Stack(
              children: [
                // Gradient Background
                _buildGradientBackground(),

                // Animated Wave Layers
                if (!_reduceMotion) ...[
                  _buildWaveLayer(0, 0.08, 4.0, false),
                  _buildWaveLayer(1, 0.06, 5.0, true),
                  _buildWaveLayer(2, 0.10, 3.5, false),
                ],

                // Center Logo with Animation
                _buildCenterLogo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0E4778), // Primary blue
            Color(0xFF061C4C), // Secondary darker blue
          ],
        ),
      ),
    );
  }

  Widget _buildWaveLayer(
    int index,
    double opacity,
    double speed,
    bool reverse,
  ) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            animationValue: _waveController.value,
            waveOpacity: opacity,
            waveSpeed: speed,
            reverse: reverse,
            offset: index * 0.3,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildCenterLogo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo with cool animations (no background card)
          AnimatedBuilder(
            animation: Listenable.merge([
              _logoController,
              _breathingController,
            ]),
            builder: (context, child) {
              final scale =
                  _logoScale.value *
                  (_breathingController.isAnimating ? _breathing.value : 1.0);

              return Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 180,
                    height: 180,
                    padding: const EdgeInsets.all(20),
                    child: Semantics(
                      label: 'App logo',
                      child: Image.asset(
                        widget.logoAssetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // App Name with slide-up animation
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Opacity(
                opacity: _logoOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _logoOpacity.value)),
                  child: Text(
                    widget.appName ?? 'Hominode',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Tagline with delayed slide-up animation
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              final delayedOpacity = (_logoOpacity.value * 1.5 - 0.5).clamp(
                0.0,
                1.0,
              );

              return Opacity(
                opacity: delayedOpacity,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1 - delayedOpacity)),
                  child: Text(
                    widget.tagline ?? 'Your Community, Connected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated wave layers
///
/// Creates smooth sine waves that translate horizontally
/// Optimized for GPU rendering with repaint boundaries
class WavePainter extends CustomPainter {
  final double animationValue;
  final double waveOpacity;
  final double waveSpeed;
  final bool reverse;
  final double offset;

  WavePainter({
    required this.animationValue,
    required this.waveOpacity,
    required this.waveSpeed,
    required this.reverse,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA8C7FF).withValues(alpha: waveOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final waveHeight = size.height * 0.15;
    final waveLength = size.width * 1.5;

    // Calculate horizontal offset based on animation
    final horizontalOffset = reverse
        ? -animationValue * waveLength * waveSpeed
        : animationValue * waveLength * waveSpeed;

    // Start path
    path.moveTo(0, size.height);

    // Draw wave using sine function
    for (double x = 0; x <= size.width; x += 5) {
      final normalizedX = (x + horizontalOffset + offset * 100) / waveLength;
      final y =
          size.height * 0.6 +
          math.sin(normalizedX * 2 * math.pi * 2) * waveHeight;
      path.lineTo(x, y);
    }

    // Complete path
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
