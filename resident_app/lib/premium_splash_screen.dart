/*
 * ============================================================================
 * PREMIUM ANIMATED SPLASH SCREEN
 * ============================================================================
 * 
 * ASSET SETUP:
 * Add to pubspec.yaml under flutter > assets:
 *   assets:
 *     - assets/logo1.png
 * 
 * USAGE:
 * 1. Auto-navigate mode (default):
 *    PremiumSplashScreen(
 *      onComplete: () => Navigator.pushReplacementNamed(context, '/login'),
 *    )
 * 
 * 2. Manual navigation mode:
 *    PremiumSplashScreen(
 *      autoNavigate: false,
 *      showProgressIndicator: false,
 *    )
 * 
 * FEATURES:
 * - Background fade-in (0-300ms)
 * - Logo entry with elastic bounce (300-900ms)
 * - Depth layer parallax effect (400-1200ms)
 * - Shimmer sweep animation (900-1600ms)
 * - Tagline fade & slide (1100-1500ms)
 * - Progress indicator (1500-2200ms)
 * - Auto-navigation with crossfade (2200-2550ms)
 * 
 * DEVICE: iPhone 13 (390px width) - Responsive
 * ============================================================================
 */

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumSplashScreen extends StatefulWidget {
  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Auto-navigate after animation (default: true)
  final bool autoNavigate;

  /// Show progress indicator during hold phase (default: true)
  final bool showProgressIndicator;

  const PremiumSplashScreen({
    super.key,
    this.onComplete,
    this.autoNavigate = true,
    this.showProgressIndicator = true,
  });

  @override
  State<PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<PremiumSplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _masterController;
  late AnimationController _shimmerController;

  // Background animations
  late Animation<double> _backgroundOpacity;

  // Logo animations
  late Animation<double> _logoY;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _shadowBlur;

  // Depth layer animations
  late Animation<double> _depthLayerX;
  late Animation<double> _depthLayerY;
  late Animation<double> _depthLayerRotation;
  late Animation<double> _depthLayerOpacity;

  // Shimmer animation
  late Animation<double> _shimmerPosition;

  // Tagline animations
  late Animation<double> _taglineOpacity;
  late Animation<double> _taglineY;

  // Progress indicator
  late Animation<double> _progressOpacity;

  @override
  void initState() {
    super.initState();

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Master controller (0-2200ms)
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Shimmer controller (700ms, repeats once)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 1. Background fade-in (0-300ms)
    _backgroundOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.136, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Logo entry (300-900ms)
    _logoY = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.136, 0.409, curve: Curves.elasticOut),
      ),
    );

    _logoScale =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.85, end: 1.02),
            weight: 70,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.02, end: 1.0),
            weight: 30,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.136, 0.409, curve: Curves.easeOut),
          ),
        );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.136, 0.318, curve: Curves.easeOut),
      ),
    );

    // Shadow growth (300-900ms)
    _shadowBlur = Tween<double>(begin: 4.0, end: 18.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.136, 0.409, curve: Curves.easeOut),
      ),
    );

    // 3. Depth layer parallax (400-1200ms)
    _depthLayerX =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween<double>(begin: 0, end: 3), weight: 50),
          TweenSequenceItem(
            tween: Tween<double>(begin: 3, end: -2),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.182, 0.545, curve: Curves.easeInOut),
          ),
        );

    _depthLayerY =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween<double>(begin: 0, end: 3), weight: 50),
          TweenSequenceItem(
            tween: Tween<double>(begin: 3, end: -2),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.182, 0.545, curve: Curves.easeInOut),
          ),
        );

    _depthLayerRotation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0, end: -1),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: -1, end: 1),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _masterController,
            curve: const Interval(0.182, 0.545, curve: Curves.easeInOut),
          ),
        );

    _depthLayerOpacity = Tween<double>(begin: 0.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.182, 0.409, curve: Curves.easeOut),
      ),
    );

    // 4. Shimmer sweep (controlled by separate controller)
    _shimmerPosition = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // 5. Tagline fade & slide (1100-1500ms)
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.5, 0.682, curve: Curves.easeOut),
      ),
    );

    _taglineY = Tween<double>(begin: 10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.5, 0.682, curve: Curves.easeOut),
      ),
    );

    // 6. Progress indicator (1500-2200ms)
    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.682, 0.773, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimations() {
    // Start master animation
    _masterController.forward();

    // Start shimmer at 900ms
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _shimmerController.forward();
      }
    });

    // Auto-navigate at 2200ms
    if (widget.autoNavigate) {
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = math.min(260.0, screenWidth * 0.66);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_masterController, _shimmerController]),
        builder: (context, child) {
          return Opacity(
            opacity: _backgroundOpacity.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2B6DE8), // #2B6DE8
                    Color(0xFF1E4ED8), // #1E4ED8
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with depth layer and shimmer
                      _buildAnimatedLogo(logoSize),

                      const SizedBox(height: 32),

                      // Tagline
                      _buildTagline(),

                      // Progress indicator
                      if (widget.showProgressIndicator)
                        _buildProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLogo(double size) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Depth layer (behind logo)
            Opacity(
              opacity: _depthLayerOpacity.value,
              child: Transform.translate(
                offset: Offset(_depthLayerX.value + 4, _depthLayerY.value + 4),
                child: Transform.rotate(
                  angle: _depthLayerRotation.value * math.pi / 180,
                  child: _buildLogoImage(size: size * 0.9, opacity: 0.3),
                ),
              ),
            ),

            // Main logo with animations
            Opacity(
              opacity: _logoOpacity.value,
              child: Transform.translate(
                offset: Offset(0, _logoY.value),
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          blurRadius: _shadowBlur.value,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(size * 0.15),
                      child: Stack(
                        children: [
                          // Logo image
                          _buildLogoImage(size: size),

                          // Shimmer overlay
                          _buildShimmerOverlay(size),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoImage({required double size, double opacity = 1.0}) {
    return Image.asset(
      'assets/logo1.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      opacity: AlwaysStoppedAnimation(opacity),
      errorBuilder: (context, error, stackTrace) {
        // Fallback: Placeholder with app initials
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(size * 0.15),
          ),
          child: Center(
            child: Text(
              'Hominode',
              style: TextStyle(
                fontSize: size * 0.25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerOverlay(double size) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.15),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shimmerPosition.value * size, 0),
              child: Container(
                width: size * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTagline() {
    return Opacity(
      opacity: _taglineOpacity.value,
      child: Transform.translate(
        offset: Offset(0, _taglineY.value),
        child: const Text(
          'Your Community, Connected',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xF2FFFFFF), // White 95% opacity
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Opacity(
      opacity: _progressOpacity.value,
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        width: 32,
        height: 32,
        child: const CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

// ============================================================================
// DEMO APP
// ============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const PremiumSplashDemoApp());
}

class PremiumSplashDemoApp extends StatelessWidget {
  const PremiumSplashDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hominode - Premium Splash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF0E4778),
      ),
      home: PremiumSplashScreen(
        autoNavigate: true,
        showProgressIndicator: true,
        onComplete: () {
          // Navigate to login screen
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return const DummyLoginScreen();
              },
              transitionDuration: const Duration(milliseconds: 350),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    // Crossfade + slide up transition
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                        child: child,
                      ),
                    );
                  },
            ),
          );
        },
      ),
    );
  }
}

// Dummy login screen for demo
class DummyLoginScreen extends StatelessWidget {
  const DummyLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login, size: 64, color: Color(0xFF0E4778)),
            const SizedBox(height: 16),
            const Text(
              'Login Screen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Splash animation complete!',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
