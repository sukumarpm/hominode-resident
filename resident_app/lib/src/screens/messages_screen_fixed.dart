// lib/src/screens/messages_screen_fixed.dart
// FIXED: Messages screen with proper search bar, segmented control, and layout

import 'package:flutter/material.dart';
import 'chat_conversation_screen_fixed.dart';
import '../components/app_segmented_control.dart';
import '../components/primary_header.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

// ============================================================================
// MESSAGE MODEL
// ============================================================================
class Message {
  final String id;
  final String title;
  final String preview;
  final String timestamp;
  final int unreadCount;
  final IconData? icon;
  final Color? iconBg;

  Message({
    required this.id,
    required this.title,
    required this.preview,
    required this.timestamp,
    this.unreadCount = 0,
    this.icon,
    this.iconBg,
  });
}

// ============================================================================
// MESSAGES SCREEN - FIXED VERSION
// ============================================================================
class MessagesScreenFixed extends StatefulWidget {
  const MessagesScreenFixed({super.key});

  @override
  State<MessagesScreenFixed> createState() => _MessagesScreenFixedState();
}

class _MessagesScreenFixedState extends State<MessagesScreenFixed> {
  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Message> get _chatMessages => [
        Message(
          id: '1',
          title: 'Amazon Delivery',
          preview: 'Maintenance bill for November has been gener...',
          timestamp: '2:30 PM',
          unreadCount: 2,
          icon: Icons.apartment,
          iconBg: const Color(0xFF5C9FD8),
        ),
        Message(
          id: '2',
          title: 'Security',
          preview: 'Your visitor has arrived at the gate',
          timestamp: '1:30 PM',
          unreadCount: 1,
          icon: Icons.security,
          iconBg: const Color(0xFFFDB022),
        ),
        Message(
          id: '3',
          title: 'Community Group',
          preview: 'Raj: Anyone interested in badminton tomor...',
          timestamp: '12:30 PM',
          unreadCount: 9,
          icon: Icons.groups,
          iconBg: const Color(0xFFE53935),
        ),
        Message(
          id: '4',
          title: 'Maintenance Team',
          preview: 'Your complaint has been resolved',
          timestamp: 'Yesterday',
          unreadCount: 0,
          icon: Icons.build,
          iconBg: const Color(0xFF6B7280),
        ),
      ];

  List<Message> get _notificationMessages => [
        Message(
          id: 'n1',
          title: 'Visitor Approved',
          preview: 'Your visitor Amit Kumar has been approved',
          timestamp: '1 hour ago',
          unreadCount: 0,
          icon: Icons.person_add,
          iconBg: const Color(0xFF10B981),
        ),
        Message(
          id: 'n2',
          title: 'Bill Payment Due',
          preview: 'Your maintenance bill is due on Nov 5, 2025',
          timestamp: '3 hours ago',
          unreadCount: 0,
          icon: Icons.notifications,
          iconBg: const Color(0xFFF97316),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          const PrimaryHeader(title: 'Messages'),
          
          const SizedBox(height: 20),
          
          // Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pagePadding),
            child: AppSegmentedControl(
              segments: const ['Chats', 'Notifications'],
              selectedIndex: _selectedTab,
              onChanged: (index) {
                setState(() => _selectedTab = index);
                _searchFocusNode.unfocus();
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Search Bar (only for Chats tab)
          if (_selectedTab == 0) _buildSearchBar(),
          
          // Message List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.pagePadding,
                0,
                AppSizes.pagePadding,
                AppSizes.pagePadding,
              ),
              itemCount: _selectedTab == 0
                  ? _chatMessages.length
                  : _notificationMessages.length,
              itemBuilder: (context, index) {
                final message = _selectedTab == 0
                    ? _chatMessages[index]
                    : _notificationMessages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spaceBetweenCards),
                  child: _buildMessageCard(message),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // FIXED: Properly sized and styled search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.pagePadding,
        0,
        AppSizes.pagePadding,
        16,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                onPressed: () {
                  setState(() => _searchController.clear());
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(Message message) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationScreenFixed(
              conversation: ConversationFixed(
                id: message.id,
                title: message.title,
                subtitle: _selectedTab == 0 ? 'Online' : null,
                icon: message.icon,
                iconBg: message.iconBg,
                isGroup: message.title.contains('Group'),
                unreadCount: message.unreadCount,
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon/Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: message.iconBg ?? AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    message.icon ?? Icons.message,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (message.unreadCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          message.unreadCount > 9 ? '9+' : '${message.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        message.timestamp,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.preview,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
