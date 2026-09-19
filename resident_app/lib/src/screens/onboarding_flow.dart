import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/animated_onboarding_card.dart';
import '../constants/onboarding_styles.dart';

/// Production-ready onboarding flow with 4 screens
/// Implements smooth page transitions, animations, and state persistence
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _buttonAnimationController;
  late AnimationController _waveAnimationController;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.apartment_rounded,
      title: 'Welcome to Hominode',
      subtitle:
          'Manage your apartment community with ease. Everything you need in one place.',
      iconData: Icons.apartment_rounded,
    ),
    OnboardingPage(
      icon: Icons.people_outline_rounded,
      title: 'Visitor Management',
      subtitle:
          'Pre-approve visitors, track deliveries, and manage entry passes seamlessly.',
      iconData: Icons.people_outline_rounded,
    ),
    OnboardingPage(
      icon: Icons.notifications_none_rounded,
      title: 'Stay Updated',
      subtitle:
          'Get real-time notifications for bills, events, announcements, and more.',
      iconData: Icons.notifications_none_rounded,
    ),
    OnboardingPage(
      icon: Icons.shield_outlined,
      title: 'Safe & Secure',
      subtitle:
          'Your data is protected with enterprise-grade security. Privacy guaranteed.',
      iconData: Icons.shield_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
    _waveAnimationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding completion flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

    // Navigate to login screen after onboarding
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _skipOnboarding() async {
    await _completeOnboarding();

    // Show skip confirmation
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Intro skipped'),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingStyles.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Background wave animation
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveAnimationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animationValue: _waveAnimationController.value,
                    ),
                  );
                },
              ),
            ),

            // Main content
            Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.only(right: 16, top: 8),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Semantics(
                      label: 'Skip onboarding',
                      button: true,
                      child: TextButton(
                        onPressed: _skipOnboarding,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: OnboardingStyles.skipTextStyle,
                        ),
                      ),
                    ),
                  ),
                ),

                // PageView with content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - index;
                            value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                          }
                          return Center(
                            child: Opacity(
                              opacity: value,
                              child: Transform.scale(
                                scale: value,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _buildPageContent(_pages[index]),
                      );
                    },
                  ),
                ),

                // Page indicators
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                ),

                // CTA Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Semantics(
                    label: _currentPage == _pages.length - 1
                        ? 'Get Started'
                        : 'Next page',
                    button: true,
                    child: GestureDetector(
                      onTapDown: (_) {
                        _buttonAnimationController.forward();
                      },
                      onTapUp: (_) {
                        _buttonAnimationController.reverse();
                        _nextPage();
                      },
                      onTapCancel: () {
                        _buttonAnimationController.reverse();
                      },
                      child: AnimatedBuilder(
                        animation: _buttonAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale:
                                1.0 - (_buttonAnimationController.value * 0.05),
                            child: child,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: OnboardingStyles.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: OnboardingStyles.primaryBlue.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: OnboardingStyles.buttonTextStyle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ), // Standard app padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated card with icon
          AnimatedOnboardingCard(
            icon: page.iconData,
            key: ValueKey(page.title),
          ),

          const SizedBox(height: 40),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              page.title,
              style: OnboardingStyles.titleTextStyle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              page.subtitle,
              style: OnboardingStyles.subtitleTextStyle,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? OnboardingStyles.primaryBlue
            : OnboardingStyles.primaryBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData iconData;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconData,
  });
}

/// Custom painter for subtle background wave animation
class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = OnboardingStyles.primaryBlue.withValues(alpha: 0.02)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 20.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height * 0.3);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.3 +
            waveHeight *
                Math.sin(
                  (i / waveLength * 2 * Math.pi) +
                      (animationValue * 2 * Math.pi),
                ),
      );
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Math helper
class Math {
  static double sin(double value) => math.sin(value);
  static double pi = math.pi;
}
