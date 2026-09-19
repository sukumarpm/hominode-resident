// lib/src/components/notice_card.dart
// Reusable notice card component

import 'package:flutter/material.dart';
import '../models/notice.dart';

const kSectionTitle = Color(0xFF111111);
const kNoticeExcerpt = Color(0xFF9B9B9B);
const kDivider = Color(0xFFE6E6E6);
const kBadgeHighBg = Color(0xFFFFF1EB);
const kBadgeHighText = Color(0xFFFF6B35);
const kBadgeMediumBg = Color(0xFFEEF5FF);
const kBadgeMediumText = Color(0xFF2B6CE6);
const kLightGrayBg = Color(0xFFF5F5F5);
const kSubtitle = Color(0xFF8C8C8C);

class NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback? onTap;

  const NoticeCard({
    super.key,
    required this.notice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kDivider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getIconBgColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.campaign_outlined,
                color: _getIconColor(),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: const TextStyle(
                      color: kSectionTitle,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notice.excerpt,
                    style: const TextStyle(
                      color: kNoticeExcerpt,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notice.formattedDate,
                    style: const TextStyle(
                      color: kNoticeExcerpt,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Badge
            _buildBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBadgeBgColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getBadgeLabel(),
        style: TextStyle(
          color: _getBadgeTextColor(),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getIconBgColor() {
    switch (notice.priority) {
      case NoticePriority.high:
        return kBadgeHighBg;
      case NoticePriority.medium:
        return kBadgeMediumBg;
      case NoticePriority.low:
        return kLightGrayBg;
    }
  }

  Color _getIconColor() {
    switch (notice.priority) {
      case NoticePriority.high:
        return kBadgeHighText;
      case NoticePriority.medium:
        return kBadgeMediumText;
      case NoticePriority.low:
        return kSubtitle;
    }
  }

  Color _getBadgeBgColor() {
    switch (notice.priority) {
      case NoticePriority.high:
        return kBadgeHighBg;
      case NoticePriority.medium:
        return kBadgeMediumBg;
      case NoticePriority.low:
        return kLightGrayBg;
    }
  }

  Color _getBadgeTextColor() {
    switch (notice.priority) {
      case NoticePriority.high:
        return kBadgeHighText;
      case NoticePriority.medium:
        return kBadgeMediumText;
      case NoticePriority.low:
        return kSubtitle;
    }
  }

  String _getBadgeLabel() {
    switch (notice.priority) {
      case NoticePriority.high:
        return 'High';
      case NoticePriority.medium:
        return 'Medium';
      case NoticePriority.low:
        return 'Low';
    }
  }
}
