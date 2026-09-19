import 'package:flutter/material.dart';

/// Loading Screen with Skeleton UI
/// Shows for 2 seconds after successful login
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header Skeleton
            _buildHeaderSkeleton(),

            const SizedBox(height: 20),

            // Content Skeletons
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Banner Skeleton
                    _buildBannerSkeleton(),

                    const SizedBox(height: 24),

                    // Quick Access Grid Skeleton
                    _buildQuickAccessSkeleton(),

                    const SizedBox(height: 24),

                    // Cards Skeleton
                    _buildCardSkeleton(),
                    const SizedBox(height: 16),
                    _buildCardSkeleton(),
                  ],
                ),
              ),
            ),

            // Bottom Nav Skeleton
            _buildBottomNavSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3AA6C8), Color(0xFF0E4778)],
        ),
      ),
      child: Row(
        children: [
          _shimmerBox(width: 40, height: 40, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 120, height: 16, radius: 4),
                const SizedBox(height: 6),
                _shimmerBox(width: 80, height: 12, radius: 4),
              ],
            ),
          ),
          _shimmerBox(width: 40, height: 40, radius: 20),
        ],
      ),
    );
  }

  Widget _buildBannerSkeleton() {
    return _shimmerBox(width: double.infinity, height: 160, radius: 16);
  }

  Widget _buildQuickAccessSkeleton() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: List.generate(8, (index) {
        return Column(
          children: [
            _shimmerBox(width: 56, height: 56, radius: 12),
            const SizedBox(height: 8),
            _shimmerBox(width: 50, height: 10, radius: 4),
          ],
        );
      }),
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(width: 150, height: 18, radius: 4),
          const SizedBox(height: 12),
          _shimmerBox(width: double.infinity, height: 14, radius: 4),
          const SizedBox(height: 8),
          _shimmerBox(width: double.infinity, height: 14, radius: 4),
          const SizedBox(height: 8),
          _shimmerBox(width: 200, height: 14, radius: 4),
        ],
      ),
    );
  }

  Widget _buildBottomNavSkeleton() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _shimmerBox(width: 24, height: 24, radius: 4),
              const SizedBox(height: 4),
              _shimmerBox(width: 40, height: 10, radius: 4),
            ],
          );
        }),
      ),
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }
}
