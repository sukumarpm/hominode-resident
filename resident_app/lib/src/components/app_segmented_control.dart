import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Premium Segmented Control Component
///
/// A high-end, reusable segmented control with smooth animations
/// matching Airbnb/Apple level design standards.
///
/// Design Specifications:
/// - Track background: #F0F1F3 (light grey)
/// - Height: 48px
/// - Corner radius: 30px (pill shape)
/// - Active pill: White with shadow
/// - Shadow: rgba(16, 24, 40, 0.12), blur 12, offset y=3
/// - Animation: 220ms easeOut
/// - Active text: Bold #0F172A
/// - Inactive text: Medium #9AA0A6, 15px
///
/// Usage:
/// ```dart
/// AppSegmentedControl(
///   segments: ['All', 'Furniture', 'Electronics', 'Other'],
///   selectedIndex: _selectedIndex,
///   onChanged: (index) => setState(() => _selectedIndex = index),
/// )
/// ```
class AppSegmentedControl extends StatefulWidget {
  /// List of segment labels (2-5 segments recommended)
  final List<String> segments;

  /// Currently selected segment index
  final int selectedIndex;

  /// Callback when segment is tapped, returns the new index
  final ValueChanged<int> onChanged;

  /// Optional custom height (default: 48px)
  final double? height;

  /// Optional horizontal margin (default: 20px)
  final double? horizontalMargin;

  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    this.height,
    this.horizontalMargin,
  }) : assert(
         segments.length >= 2 && segments.length <= 5,
         'Segments must contain 2-5 items',
       );

  @override
  State<AppSegmentedControl> createState() => _AppSegmentedControlState();
}

class _AppSegmentedControlState extends State<AppSegmentedControl>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(AppSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height ?? 48.0;
    final horizontalMargin = widget.horizontalMargin ?? 20.0;

    return Container(
      height: height,
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / widget.segments.length;

            return Stack(
              children: [
                // Animated sliding pill
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final startPosition = _previousIndex * segmentWidth;
                    final endPosition = widget.selectedIndex * segmentWidth;
                    final currentPosition =
                        startPosition +
                        (endPosition - startPosition) * _animation.value;

                    return Positioned(
                      left: currentPosition,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0x10182840,
                              ), // rgba(16, 24, 40, 0.12)
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Segment labels
                Row(
                  children: List.generate(
                    widget.segments.length,
                    (index) => Expanded(
                      child: _buildSegment(
                        label: widget.segments[index],
                        index: index,
                        isSelected: widget.selectedIndex == index,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (widget.selectedIndex != index) {
          widget.onChanged(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF0F172A) // Active: Dark slate
                : const Color(0xFF9AA0A6), // Inactive: Medium grey
            fontSize: 15.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: -0.2,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
