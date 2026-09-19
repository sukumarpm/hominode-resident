// lib/src/widgets/skeleton_loader.dart
// Skeleton Loading Animation - Flow Function Pattern

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Skeleton Loader Widget
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final EdgeInsets margin;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    print('🔄 SkeletonLoader: Initializing animation');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat();
    print('✅ SkeletonLoader: Animation initialized');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1 - _animation.value, 0),
                end: Alignment(1 - _animation.value, 0),
                colors: const [
                  Color(0xFFE0E0E0),
                  Color(0xFFF5F5F5),
                  Color(0xFFE0E0E0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds);
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: widget.borderRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Skeleton Card Loader
class SkeletonCardLoader extends StatelessWidget {
  final double height;
  final EdgeInsets padding;

  const SkeletonCardLoader({
    super.key,
    this.height = 120,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          SkeletonLoader(
            width: 150,
            height: 16,
            margin: EdgeInsets.only(bottom: 12.h),
          ),
          // Content skeleton
          SkeletonLoader(
            width: double.infinity,
            height: 12,
            margin: EdgeInsets.only(bottom: 8.h),
          ),
          SkeletonLoader(
            width: double.infinity,
            height: 12,
            margin: EdgeInsets.only(bottom: 8.h),
          ),
          SkeletonLoader(width: 200, height: 12),
        ],
      ),
    );
  }
}

/// Skeleton List Loader
class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonListLoader({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    print('📋 SkeletonListLoader: Building list with $itemCount items');

    return ListView.builder(
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return SkeletonCardLoader(height: itemHeight);
      },
    );
  }
}

/// Skeleton Dashboard Loader
class SkeletonDashboardLoader extends StatelessWidget {
  const SkeletonDashboardLoader({super.key});

  @override
  Widget build(BuildContext context) {
    print('📊 SkeletonDashboardLoader: Building dashboard skeleton');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          Container(
            height: 120.h,
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE0E0E0), Color(0xFFF5F5F5)],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: 200,
                    height: 20,
                    margin: EdgeInsets.only(bottom: 12.h),
                  ),
                  SkeletonLoader(width: 150, height: 16),
                ],
              ),
            ),
          ),
          // Statistics cards skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon skeleton
                        Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Text skeleton
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLoader(
                                width: 100,
                                height: 14,
                                margin: EdgeInsets.only(bottom: 8.h),
                              ),
                              SkeletonLoader(width: 80, height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton Chat Loader
class SkeletonChatLoader extends StatelessWidget {
  const SkeletonChatLoader({super.key});

  @override
  Widget build(BuildContext context) {
    print('💬 SkeletonChatLoader: Building chat skeleton');

    return Column(
      children: [
        // Header skeleton
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: 150,
                      height: 14,
                      margin: EdgeInsets.only(bottom: 6.h),
                    ),
                    SkeletonLoader(width: 100, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Messages skeleton
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            padding: EdgeInsets.all(16.w),
            itemBuilder: (context, index) {
              final isLeft = index % 2 == 0;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: 12.h,
                  left: isLeft ? 0 : 60,
                  right: isLeft ? 60 : 0,
                ),
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: SkeletonLoader(
                    width: double.infinity,
                    height: 12,
                    margin: EdgeInsets.zero,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Skeleton Profile Loader
class SkeletonProfileLoader extends StatelessWidget {
  const SkeletonProfileLoader({super.key});

  @override
  Widget build(BuildContext context) {
    print('👤 SkeletonProfileLoader: Building profile skeleton');

    return SingleChildScrollView(
      child: Column(
        children: [
          // Avatar skeleton
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(50.r),
              ),
            ),
          ),
          // Profile info skeleton
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SkeletonLoader(
                  width: 200,
                  height: 18,
                  margin: EdgeInsets.only(bottom: 12.h),
                ),
                SkeletonLoader(
                  width: 150,
                  height: 14,
                  margin: EdgeInsets.only(bottom: 24.h),
                ),
                // Profile fields
                ...List.generate(
                  4,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(
                          width: 100,
                          height: 12,
                          margin: EdgeInsets.only(bottom: 8.h),
                        ),
                        SkeletonLoader(width: double.infinity, height: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
