import 'package:flutter/material.dart';

/// Standardized Segmented Control Component
/// Used for tab selection across the app
/// 
/// Design Specifications:
/// - Background: Light gray (#F5F5F5)
/// - Active tab: White with shadow
/// - Border radius: 24px
/// - Padding: 4px container, 12px vertical items
/// - Font size: 15px
/// - Active weight: 600 (Semibold)
/// - Inactive weight: 500 (Medium)
class SegmentedControl extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int) onTabChanged;

  const SegmentedControl({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: _buildTabItem(
              label: tabs[index],
              index: index,
              isSelected: selectedIndex == index,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF1E293B)
                : const Color(0xFF64748B),
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
