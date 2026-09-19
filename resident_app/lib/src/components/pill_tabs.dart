// lib/src/components/pill_tabs.dart
// Reusable pill-style tab bar

import 'package:flutter/material.dart';

const kLightGrayBg = Color(0xFFF5F5F5);
const kSubtitle = Color(0xFF8C8C8C);
const kSectionTitle = Color(0xFF111111);

class PillTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int) onTabSelected;

  const PillTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: kLightGrayBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: List.generate(
            tabs.length,
            (index) => Expanded(
              child: _buildTab(tabs[index], index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? kSectionTitle : kSubtitle,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
