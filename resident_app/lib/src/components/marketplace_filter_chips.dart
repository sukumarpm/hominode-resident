import 'package:flutter/material.dart';

const kLightGrayBg = Color(0xFFF5F5F5);
const kSubtitle = Color(0xFF8C8C8C);
const kSectionTitle = Color(0xFF111111);

class MarketplaceFilterChips extends StatelessWidget {
  final String selectedCategory;
  final Function(String) onCategorySelected;

  const MarketplaceFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Furniture', 'Electronics', 'Other'];
    final selectedIndex = categories.indexOf(selectedCategory);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kLightGrayBg,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(
          categories.length,
          (index) => Expanded(
            child: _buildTab(categories[index], index, selectedIndex),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, int selectedIndex) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () => onCategorySelected(label),
      child: Container(
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
            color: isActive ? const Color(0xFF111111) : const Color(0xFF8C8C8C),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
