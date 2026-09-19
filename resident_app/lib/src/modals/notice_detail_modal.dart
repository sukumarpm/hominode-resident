// lib/src/modals/notice_detail_modal.dart
// Notice detail modal overlay

import 'package:flutter/material.dart';
import '../models/notice.dart';

const kPrimaryBlue = Color(0xFF0E4778);
const kBadgeHighBg = Color(0xFFFFF1EB);
const kBadgeHighText = Color(0xFFFF6B35);
const kBadgeMediumBg = Color(0xFFEEF5FF);
const kBadgeMediumText = Color(0xFF2B6CE6);

void showNoticeDetailModal(BuildContext context, Notice notice) {
  showDialog(
    context: context,
    builder: (context) => NoticeDetailModal(notice: notice),
  );
}

class NoticeDetailModal extends StatelessWidget {
  final Notice notice;

  const NoticeDetailModal({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getHeaderColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    color: _getIconColor(),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _getIconColor(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notice.formattedDate,
                          style: TextStyle(
                            fontSize: 14,
                            color: _getIconColor().withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBadge(),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Text(
                  notice.fullContent,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF374151),
                    height: 1.6,
                  ),
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getBadgeLabel(),
        style: TextStyle(
          color: _getIconColor(),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getHeaderColor() {
    switch (notice.priority) {
      case NoticePriority.high:
        return kBadgeHighBg;
      case NoticePriority.medium:
        return kBadgeMediumBg;
      case NoticePriority.low:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getIconColor() {
    switch (notice.priority) {
      case NoticePriority.high:
        return kBadgeHighText;
      case NoticePriority.medium:
        return kBadgeMediumText;
      case NoticePriority.low:
        return const Color(0xFF6B7280);
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
