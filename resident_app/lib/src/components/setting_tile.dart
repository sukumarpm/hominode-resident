// lib/src/components/setting_tile.dart
// Individual setting tile component

import 'package:flutter/material.dart';
import '../models/setting_item.dart';
import 'settings_toggle.dart';

class SettingTile extends StatelessWidget {
  final SettingItem item;

  const SettingTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.type == SettingType.toggle ? null : item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: const Color(0x10182840), // rgba(16, 24, 40, 0.04)
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon (if provided)
              if (item.icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: const Color(0xFF0E4778),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: item.type == SettingType.destructive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9AA0A6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing widget based on type
              _buildTrailing(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing() {
    switch (item.type) {
      case SettingType.toggle:
        return SettingsToggle(
          value: item.toggleValue ?? false,
          onChanged: item.onToggleChanged ?? (_) {},
        );

      case SettingType.status:
        if (item.statusText != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (item.statusColor ?? const Color(0xFF9AA0A6)).withOpacity(
                0.1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.statusText!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: item.statusColor ?? const Color(0xFF9AA0A6),
              ),
            ),
          );
        }
        return const Icon(
          Icons.chevron_right,
          size: 20,
          color: Color(0xFF9AA0A6),
        );

      case SettingType.navigation:
      case SettingType.destructive:
        return const Icon(
          Icons.chevron_right,
          size: 20,
          color: Color(0xFF9AA0A6),
        );
    }
  }
}
