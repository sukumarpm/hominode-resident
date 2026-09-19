// lib/src/widgets/poll_progress_bar.dart
// Horizontal progress bar for poll results

import 'package:flutter/material.dart';

class PollProgressBar extends StatelessWidget {
  final double percent; // 0.0 to 1.0
  final Color fillColor;
  final Color trackColor;
  final double height;
  final BorderRadius? borderRadius;

  const PollProgressBar({
    super.key,
    required this.percent,
    this.fillColor = Colors.black,
    this.trackColor = const Color(0xFFE6E6E6),
    this.height = 6.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percent.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
