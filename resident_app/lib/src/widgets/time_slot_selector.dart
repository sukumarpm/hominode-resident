import 'package:flutter/material.dart';

class TimeSlotSelector extends StatelessWidget {
  final List<String> timeSlots;
  final String? selectedSlot;
  final Set<String> disabledSlots;
  final Function(String) onSlotSelected;

  const TimeSlotSelector({
    super.key,
    required this.timeSlots,
    this.selectedSlot,
    this.disabledSlots = const {},
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
        ),
        itemCount: timeSlots.length,
        itemBuilder: (context, index) {
          final slot = timeSlots[index];
          final isSelected = slot == selectedSlot;
          final isDisabled = disabledSlots.contains(slot);

          return _buildTimeSlotChip(
            slot,
            isSelected: isSelected,
            isDisabled: isDisabled,
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotChip(String slot, {required bool isSelected, required bool isDisabled}) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isDisabled) {
      backgroundColor = const Color(0xFFF0F0F0);
      textColor = const Color(0xFFBDBDBD);
      borderColor = const Color(0xFFE6E6E6);
    } else if (isSelected) {
      backgroundColor = const Color(0xFF0B1020);
      textColor = Colors.white;
      borderColor = const Color(0xFF0B1020);
    } else {
      backgroundColor = Colors.white;
      textColor = Colors.black;
      borderColor = const Color(0xFFE6E6E6);
    }

    return GestureDetector(
      onTap: isDisabled ? null : () => onSlotSelected(slot),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Center(
          child: Text(
            slot,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
