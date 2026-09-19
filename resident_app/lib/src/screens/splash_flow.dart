import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Production-ready Splash Flow with multi-stage animations
///
/// Flow: Gradient Wave Splash → Bottom Loader → Center-Only Logo → Navigation
///
/// Features:
/// - Stage 1: Full splash with waves, logo pop, app name & tagline (2.0s)
/// - Stage 2: Bottom loader with progress animation (1.0s)
/// - Stage 3: Transition to center-only logo (0.4s)
/// - Optional Night/Galaxy variant with twinkling stars
/// - Reduced motion accessibility support
/// - GPU-optimized animations
class SplashFlow extends StatefulWidget {
  final Duration initialDuration;
  final Duration loaderDuration;
  final Duration transitionDuration;
  final bool nightMode;
  final bool useSmartWave;
  final String logoAssetPath;
  final String? appName;
  final String? tagline;
  final VoidCallback? onFinish;

  const SplashFlow({
    super.key,
    this.initialDuration = const Duration(milliseconds: 2000),
    this.loaderDuration = const Duration(milliseconds: 1000),
    this.transitionDuration = const Duration(milliseconds: 400),
    this.nightMode = false,
    this.useSmartWave = false,
    this.logoAssetPath = 'assets/logo1.png',
    this.appName = 'Hominode',
    this.tagline = 'Your Community, Connected',
    this.onFinish,
  });

  @override
  State<SplashFlow> createState() => _SplashFlowState();
}

class _SplashFlowState extends State<SplashFlow> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _waveController;
  late AnimationController _logoController;
  late AnimationController _breathingController;
  late AnimationController _loaderController;
  late AnimationController _transitionController;
  AnimationController? _starsController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _breathing;
  late Animation<double> _loaderProgress;
  late Animation<double> _backgroundFade;
  late Animation<double> _textFade;
  late Animation<double> _logoTransition;

  // State
  bool _reduceMotion = false;
  int _currentStage = 1; // 1: Initial, 2: Loader, 3: Center-only

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSplashFlow();
  }

  void _initAnimations() {
    // Wave animation (continuous)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Logo pop animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    // Logo scale with overshoot
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

    // Logo opacity
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Breathing animation
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _breathing = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    // Loader progress
    _loaderController = AnimationController(
      vsync: this,
      duration: widget.loaderDuration,
    );

    _loaderProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );

    // Transition animations
    _transitionController = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );

    _backgroundFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut),
    );

    _textFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _logoTransition = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.elasticOut),
    );

    // Stars animation (for night mode)
    if (widget.nightMode) {
      _starsController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 8),
      )..repeat();
    }
  }

  void _startSplashFlow() async {
    // Check for reduced motion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reduceMotion = MediaQuery.of(context).disableAnimations;
    });

    // Stage 1: Initial splash with logo pop
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      _logoController.forward().then((_) {
        if (mounted && !_reduceMotion) {
          _breathingController.repeat(reverse: true);
        }
      });
    }

    // Wait for initial duration
    await Future.delayed(widget.initialDuration);

    // Stage 2: Show loader
    if (mounted) {
      setState(() => _currentStage = 2);
      _loaderController.forward();
      await Future.delayed(widget.loaderDuration);
    }

    // Stage 3: Transition to center-only logo
    if (mounted) {
      setState(() => _currentStage = 3);
      _transitionController.forward();
      await Future.delayed(widget.transitionDuration);
    }

    // Complete and navigate
    if (mounted && widget.onFinish != null) {
      widget.onFinish!();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _logoController.dispose();
    _breathingController.dispose();
    _loaderController.dispose();
    _transitionController.dispose();
    _starsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Semantics(
        label: 'Splash screen loading',
        child: Scaffold(
          body: Stack(
            children: [
              // Background (gradient or night)
              _buildBackground(),

              // Animated waves (stage 1 & 2)
              if (_currentStage < 3 && !_reduceMotion) ...[
                _buildWaveLayer(0, 0.08, 4.0, false),
                _buildWaveLayer(1, 0.06, 5.0, true),
                _buildWaveLayer(2, 0.10, 3.5, false),
              ],

              // Smart wave for stage 3
              if (_currentStage == 3 && widget.useSmartWave && !_reduceMotion)
                _buildSmartWave(),

              // Stars for night mode
              if (widget.nightMode &&
                  !_reduceMotion &&
                  _starsController != null)
                _buildStarsLayer(),

              // Main content
              _buildMainContent(),

              // Bottom loader (stage 2)
              if (_currentStage == 2) _buildBottomLoader(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (_currentStage == 3 && !widget.useSmartWave) {
      // Plain white background for center-only stage
      return Container(color: Colors.white);
    }

    return AnimatedBuilder(
      animation: _transitionController,
      builder: (context, child) {
        final opacity = _currentStage < 3 ? 1.0 : _backgroundFade.value;
        return Opacity(
          opacity: opacity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.nightMode
                    ? [
                        const Color(0xFF0B2A5B), // Night top
                        const Color(0xFF061226), // Night bottom
                      ]
                    : [
                        const Color(0xFF0E4778), // Primary blue
                        const Color(0xFF061C4C), // Secondary blue
                      ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveLayer(
    int index,
    double opacity,
    double speed,
    bool reverse,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _transitionController]),
      builder: (context, child) {
        final waveOpacity = _currentStage < 3
            ? opacity
            : opacity * _backgroundFade.value;
        return Opacity(
          opacity: waveOpacity,
          child: CustomPaint(
            painter: WavePainter(
              animationValue: _waveController.value,
              waveOpacity: 1.0, // Opacity handled by parent
              waveSpeed: speed,
              reverse: reverse,
              offset: index * 0.3,
              nightMode: widget.nightMode,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildSmartWave() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: SmartWavePainter(animationValue: _waveController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildStarsLayer() {
    return AnimatedBuilder(
      animation: _starsController!,
      builder: (context, child) {
        return CustomPaint(
          painter: StarsPainter(animationValue: _starsController!.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _breathingController,
          _transitionController,
        ]),
        builder: (context, child) {
          final logoScale =
              _logoScale.value *
              (_breathingController.isAnimating ? _breathing.value : 1.0) *
              (_currentStage == 3 ? _logoTransition.value : 1.0);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: logoScale,
                  child: Container(
                    width: _currentStage == 3 ? 120 : 180,
                    height: _currentStage == 3 ? 120 : 180,
                    decoration: _currentStage == 3
                        ? null
                        : BoxDecoration(
                            color: widget.nightMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: widget.nightMode ? 30 : 20,
                                offset: const Offset(0, 8),
                              ),
                              if (widget.nightMode)
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                            ],
                          ),
                    padding: EdgeInsets.all(_currentStage == 3 ? 16 : 28),
                    child: Semantics(
                      label: 'App logo',
                      child: Image.asset(
                        widget.logoAssetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              // App Name & Tagline (stages 1 & 2 only)
              if (_currentStage < 3) ...[
                const SizedBox(height: 32),
                // App Name
                AnimatedBuilder(
                  animation: _transitionController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value * _textFade.value,
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
                // Tagline
                AnimatedBuilder(
                  animation: _transitionController,
                  builder: (context, child) {
                    final delayedOpacity = (_logoOpacity.value * 1.5 - 0.5)
                        .clamp(0.0, 1.0);
                    return Opacity(
                      opacity: delayedOpacity * _textFade.value,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - delayedOpacity)),
                        child: Text(
                          widget.tagline ?? 'Your Community, Connected',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomLoader() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedBuilder(
          animation: _loaderProgress,
          builder: (context, child) {
            return Column(
              children: [
                // Progress bar
                Container(
                  width: 200,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _loaderProgress.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.nightMode
                              ? [Colors.white, Colors.white70]
                              : [Colors.white, Colors.white70],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Loading text
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Wave painter for animated background waves
class WavePainter extends CustomPainter {
  final double animationValue;
  final double waveOpacity;
  final double waveSpeed;
  final bool reverse;
  final double offset;
  final bool nightMode;

  WavePainter({
    required this.animationValue,
    required this.waveOpacity,
    required this.waveSpeed,
    required this.reverse,
    required this.offset,
    this.nightMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = nightMode
          ? const Color(0xFF4A90E2).withOpacity(waveOpacity * 0.3)
          : const Color(0xFFA8C7FF).withOpacity(waveOpacity)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    final waveHeight = size.height * 0.15;
    final waveLength = size.width * 1.5;

    final horizontalOffset = reverse
        ? -animationValue * waveLength * waveSpeed
        : animationValue * waveLength * waveSpeed;

    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 5) {
      final normalizedX = (x + horizontalOffset + offset * 100) / waveLength;
      final y =
          size.height * 0.6 +
          math.sin(normalizedX * 2 * math.pi * 2) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Smart wave painter for center-only stage
class SmartWavePainter extends CustomPainter {
  final double animationValue;

  SmartWavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0E4778).withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.05;
    final waveLength = size.width * 2;

    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x += 10) {
      final normalizedX = (x + animationValue * waveLength) / waveLength;
      final y =
          size.height * 0.8 + math.sin(normalizedX * 2 * math.pi) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SmartWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Stars painter for night mode
class StarsPainter extends CustomPainter {
  final double animationValue;

  StarsPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistent stars

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final twinkle = math.sin(animationValue * 2 * math.pi + i) * 0.5 + 0.5;
      final starSize = random.nextDouble() * 2 + 1;

      paint.color = Colors.white.withOpacity(twinkle * 0.8);
      canvas.drawCircle(Offset(x, y), starSize, paint);
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
