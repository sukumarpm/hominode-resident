import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Splash Screen Configuration
class SplashConfig {
  static const Duration totalDuration = Duration(milliseconds: 2200);
  static const Duration logoEntryDuration = Duration(milliseconds: 600);
  static const Duration shadowDuration = Duration(milliseconds: 550);
  static const Duration bounceDuration = Duration(milliseconds: 300);
  static const Duration taglineDuration = Duration(milliseconds: 400);
  static const Duration holdDuration = Duration(milliseconds: 650);
  static const Duration exitDuration = Duration(milliseconds: 300);

  static const bool enableParticles = true;
  static const bool respectReducedMotion = true;
}

/// Modern Animated Splash Screen
/// Features smooth logo entrance, depth effects, and tagline animation
class SplashScreen extends StatefulWidget {
  final bool reduceMotion;

  const SplashScreen({super.key, this.reduceMotion = false});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _shadowController;
  late AnimationController _bounceController;
  late AnimationController _taglineController;
  late AnimationController _exitController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotation;
  late Animation<double> _logoTranslateY;

  late Animation<double> _shadowOpacity;
  late Animation<double> _shadowBlur;

  late Animation<double> _squashX;
  late Animation<double> _squashY;

  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineTranslateY;

  late Animation<double> _exitScale;
  late Animation<double> _exitOpacity;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimationSequence();
  }

  void _initAnimations() {
    // Logo entry animation
    _logoController = AnimationController(
      vsync: this,
      duration: SplashConfig.logoEntryDuration,
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoRotation = Tween<double>(
      begin: -0.05,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoTranslateY = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Shadow animation
    _shadowController = AnimationController(
      vsync: this,
      duration: SplashConfig.shadowDuration,
    );

    _shadowOpacity = Tween<double>(begin: 0.0, end: 0.35).animate(
      CurvedAnimation(parent: _shadowController, curve: Curves.easeOut),
    );

    _shadowBlur = Tween<double>(begin: 0.0, end: 40.0).animate(
      CurvedAnimation(parent: _shadowController, curve: Curves.easeOut),
    );

    // Bounce animation
    _bounceController = AnimationController(
      vsync: this,
      duration: SplashConfig.bounceDuration,
    );

    _squashX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.03),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.03, end: 1.0),
        weight: 50,
      ),
    ]).animate(_bounceController);

    _squashY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.97),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.97, end: 1.0),
        weight: 50,
      ),
    ]).animate(_bounceController);

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: SplashConfig.taglineDuration,
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    _taglineTranslateY = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    // Exit animation
    _exitController = AnimationController(
      vsync: this,
      duration: SplashConfig.exitDuration,
    );

    _exitScale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _exitOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
  }

  Future<void> _startAnimationSequence() async {
    if (widget.reduceMotion) {
      // Simple fade-in for reduced motion
      await _logoController.forward();
      await Future.delayed(const Duration(milliseconds: 1500));
      await _navigateToHome();
      return;
    }

    // Start logo entry
    _logoController.forward();

    // Start shadow after 350ms
    await Future.delayed(const Duration(milliseconds: 350));
    _shadowController.forward();

    // Start bounce at 600ms
    await Future.delayed(const Duration(milliseconds: 250));
    _bounceController.forward();

    // Start tagline at 850ms
    await Future.delayed(const Duration(milliseconds: 250));
    _taglineController.forward();

    // Hold for branding
    await Future.delayed(SplashConfig.holdDuration);

    // Exit and navigate
    await _exitController.forward();
    await _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shadowController.dispose();
    _bounceController.dispose();
    _taglineController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3AA6C8), Color(0xFF0E4778)],
            ),
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([_exitController]),
            builder: (context, child) {
              return Opacity(
                opacity: _exitOpacity.value,
                child: Transform.scale(scale: _exitScale.value, child: child),
              );
            },
            child: Stack(
              children: [
                // Subtle vignette
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                ),

                // Particles (optional)
                if (SplashConfig.enableParticles && !widget.reduceMotion)
                  ..._buildParticles(),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with animations
                      _buildAnimatedLogo(),

                      const SizedBox(height: 24),

                      // App name
                      AnimatedBuilder(
                        animation: _taglineController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _taglineOpacity.value,
                            child: Transform.translate(
                              offset: Offset(0, _taglineTranslateY.value),
                              child: child,
                            ),
                          );
                        },
                        child: const Text(
                          'Hominode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Tagline
                      AnimatedBuilder(
                        animation: _taglineController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _taglineOpacity.value * 0.9,
                            child: Transform.translate(
                              offset: Offset(0, _taglineTranslateY.value),
                              child: child,
                            ),
                          );
                        },
                        child: const Text(
                          'Your Community, Connected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
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
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _shadowController,
        _bounceController,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _logoTranslateY.value),
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Transform.scale(
              scaleX: _logoScale.value * _squashX.value,
              scaleY: _logoScale.value * _squashY.value,
              child: Opacity(
                opacity: _logoOpacity.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shadow layer
                    Transform.translate(
                      offset: Offset(0, _shadowBlur.value * 0.3),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: _shadowOpacity.value,
                              ),
                              blurRadius: _shadowBlur.value,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Logo
                    Hero(tag: 'appLogoHero', child: _buildLyvoLogo()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLyvoLogo() {
    // Custom Hominode logo using CustomPaint
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(painter: _LyvoLogoPainter()),
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(5, (index) {
      return _FloatingParticle(
        delay: Duration(milliseconds: 600 + (index * 200)),
        offset: Offset((index - 2) * 60.0, -100 + (index * 40.0)),
      );
    });
  }
}

/// Custom painter for Hominode logo
class _LyvoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF061C4C);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw left slash (larger)
    final leftPath = Path();
    leftPath.moveTo(centerX - 35, centerY - 50);
    leftPath.lineTo(centerX - 15, centerY - 50);
    leftPath.lineTo(centerX - 25, centerY + 50);
    leftPath.lineTo(centerX - 45, centerY + 50);
    leftPath.close();

    // Shadow for left slash
    canvas.save();
    canvas.translate(4, 6);
    canvas.drawPath(leftPath, shadowPaint);
    canvas.restore();

    // Main left slash
    canvas.drawPath(leftPath, paint);

    // Draw right slash (smaller)
    final rightPath = Path();
    rightPath.moveTo(centerX + 10, centerY - 35);
    rightPath.lineTo(centerX + 25, centerY - 35);
    rightPath.lineTo(centerX + 15, centerY + 35);
    rightPath.lineTo(centerX, centerY + 35);
    rightPath.close();

    // Shadow for right slash
    canvas.save();
    canvas.translate(4, 6);
    canvas.drawPath(rightPath, shadowPaint);
    canvas.restore();

    // Main right slash
    canvas.drawPath(rightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating particle widget
class _FloatingParticle extends StatefulWidget {
  final Duration delay;
  final Offset offset;

  const _FloatingParticle({required this.delay, required this.offset});

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _translateY = Tween<double>(
      begin: 0.0,
      end: -80.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.08),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.08, end: 0.08),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.08, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width / 2 + widget.offset.dx,
          top:
              MediaQuery.of(context).size.height / 2 +
              widget.offset.dy +
              _translateY.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
