import 'package:flutter/material.dart';
import '../constants/onboarding_styles.dart';

/// Reusable animated card widget for onboarding screens
/// Features entrance animation with fade-in and scale effects
class AnimatedOnboardingCard extends StatefulWidget {
  final IconData icon;

  const AnimatedOnboardingCard({
    super.key,
    required this.icon,
  });

  @override
  State<AnimatedOnboardingCard> createState() => _AnimatedOnboardingCardState();
}

class _AnimatedOnboardingCardState extends State<AnimatedOnboardingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedOnboardingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.icon != widget.icon) {
      // Restart animation when icon changes
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate card size based on screen width (iPhone 13: 390px)
    final screenWidth = MediaQuery.of(context).size.width;
    final cardSize = screenWidth * 0.65; // ~254px on iPhone 13

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: cardSize,
        height: cardSize,
        decoration: BoxDecoration(
          gradient: OnboardingStyles.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: OnboardingStyles.primaryBlue.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: OnboardingStyles.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 48,
              offset: const Offset(0, 16),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            widget.icon,
            size: cardSize * 0.4, // Icon is ~40% of card size
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
