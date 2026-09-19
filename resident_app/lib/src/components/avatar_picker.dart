// lib/src/components/avatar_picker.dart
// Reusable avatar picker widget with photo upload

import 'package:flutter/material.dart';
import 'dart:io';

class AvatarPicker extends StatelessWidget {
  final String? avatarUrl;
  final File? avatarFile;
  final VoidCallback onTap;
  final double size;

  const AvatarPicker({
    super.key,
    this.avatarUrl,
    this.avatarFile,
    required this.onTap,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Avatar circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE5E7EB),
              border: Border.all(color: const Color(0xFF0E4778), width: 3),
            ),
            child: ClipOval(child: _buildAvatarContent()),
          ),
          // Edit button
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0E4778),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Show local file if available
    if (avatarFile != null) {
      return Image.file(
        avatarFile!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // Show network image if URL available
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // Show placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: const Color(0xFF9CA3AF),
      ),
    );
  }
}
