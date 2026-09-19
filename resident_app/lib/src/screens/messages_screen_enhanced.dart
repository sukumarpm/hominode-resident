// lib/src/screens/messages_screen_enhanced.dart
// Enhanced Messages screen with Chats & Requests tabs, flat members, and admin chat

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/chat_model.dart';
import '../services/chat_firestore_service.dart';
import '../services/admin_chat_service.dart';
import '../widgets/skeleton_loader.dart';
import 'chat_conversation_screen.dart';
import 'admin_chat_query_selection_screen.dart';
import 'admin_chat_conversation_screen.dart';
import '../components/app_segmented_control.dart';
import '../components/primary_header.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class MessagesScreenEnhanced extends StatefulWidget {
  const MessagesScreenEnhanced({super.key});

  @override
  State<MessagesScreenEnhanced> createState() => _MessagesScreenEnhancedState();
}

class _MessagesScreenEnhancedState extends State<MessagesScreenEnhanced> {
  final ChatFirestoreService _chatService = ChatFirestoreService.instance;
  int _selectedTab = 0; // 0 = Chats, 1 = Requests
  String? _currentUserId; // Store current user ID for chat display

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
  }

  Future<void> _initializeCurrentUser() async {
    final userId = await _chatService.getCurrentUserIdPublic();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          const PrimaryHeader(title: 'Messages'),

          SizedBox(height: 20.h),

          // Segmented Control - Chats & Requests
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pagePadding,
            ),
            child: AppSegmentedControl(
              segments: const ['Chats', 'Requests'],
              selectedIndex: _selectedTab,
              onChanged: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ),

          SizedBox(height: 16.h),

          // Content
          Expanded(
            child: _selectedTab == 0 ? _buildChatsList() : _buildRequestsList(),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () => _showBuildingMembersDialog(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildChatsList() {
    return StreamBuilder<List<ChatModel>>(
      stream: _chatService.streamUserChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SkeletonListLoader(itemCount: 5, itemHeight: 80);
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error loading chats');
        }

        final chats = snapshot.data ?? [];

        // Filter out admin chats from regular chats list
        final regularChats = chats
            .where((chat) => chat.type != 'admin')
            .toList();

        // Always show admin chat + regular chats (excluding admin type)
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            0,
            AppSizes.pagePadding,
            AppSizes.pagePadding,
          ),
          itemCount:
              regularChats.length + 1, // +1 for admin chat card (always shown)
          itemBuilder: (context, index) {
            if (index == 0) {
              // Admin chat card - always shown at top (green box)
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSizes.spaceBetweenCards,
                ),
                child: _buildAdminChatCard(),
              );
            }

            // Regular chats (excluding admin chats)
            final chatIndex = index - 1;
            if (chatIndex < regularChats.length) {
              final chat = regularChats[chatIndex];
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSizes.spaceBetweenCards,
                ),
                child: _buildChatCard(chat),
              );
            }

            // Empty state after admin chat if no regular chats
            if (regularChats.isEmpty && index == 1) {
              return Padding(
                padding: EdgeInsets.only(top: 40.h),
                child: _buildEmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No chats yet',
                  subtitle: 'Start a conversation with building members',
                ),
              );
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return StreamBuilder<List<ChatRequestModel>>(
      stream: _chatService.streamIncomingChatRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SkeletonListLoader(itemCount: 5, itemHeight: 100);
        }

        if (snapshot.hasError) {
          print('❌ MessagesScreen: Requests tab error: ${snapshot.error}');
          return _buildErrorState(
            'Error loading requests\n${snapshot.error.toString().contains('index') ? 'Missing Firestore index' : 'Please try again'}',
          );
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No requests',
            subtitle: 'Chat requests from building members will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.pagePadding,
            0,
            AppSizes.pagePadding,
            AppSizes.pagePadding,
          ),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Padding(
              padding: const EdgeInsets.only(
                bottom: AppSizes.spaceBetweenCards,
              ),
              child: _buildRequestCard(request),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminChatCard() {
    return GestureDetector(
      onTap: () async {
        // Check if admin chat exists
        final existingChat = await AdminChatService.instance
            .getExistingAdminChat();

        if (existingChat != null && mounted) {
          // Open existing chat conversation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminChatConversationScreen(chat: existingChat),
            ),
          );
        } else if (mounted) {
          // Show query selection screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminChatQuerySelectionScreen(),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.support_agent, color: Colors.white, size: 24.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Building Admin',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Get help and support',
                    style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16.w),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(ChatModel chat) {
    // Get the correct participant name based on current user
    String displayName = chat.title;

    // If participantNames map exists, get the other participant's name
    if (chat.participantNames != null &&
        chat.participantNames!.isNotEmpty &&
        _currentUserId != null) {
      // Find the name of the OTHER participant (not current user)
      for (final entry in chat.participantNames!.entries) {
        if (entry.key != _currentUserId) {
          displayName = entry.value;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationScreen(
              chatId: chat.id,
              chatTitle: displayName,
              chatSubtitle: chat.subtitle,
              isGroup: chat.isGroup,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    color: _getIconColor(chat.iconBg),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: chat.iconUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.network(
                              chat.iconUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildDefaultIcon(chat, displayName),
                            ),
                          )
                        : _buildDefaultIcon(chat, displayName),
                  ),
                ),
                if (chat.unreadCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      constraints: BoxConstraints(
                        minWidth: 20.w,
                        minHeight: 20.h,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          chat.unreadCount > 9 ? '9+' : '${chat.unreadCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      if (chat.lastMessageTime != null)
                        Text(
                          _formatTimestamp(chat.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    chat.lastMessage ?? 'No messages yet',
                    style: TextStyle(
                      fontSize: 14.sp,
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

  Widget _buildRequestCard(ChatRequestModel request) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF3B82F6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    request.senderName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.senderName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Wants to chat with you',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final chatId = await _chatService.acceptChatRequest(
                      request.id,
                    );
                    if (chatId != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request accepted!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Navigate to chat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatConversationScreen(
                            chatId: chatId,
                            chatTitle: request.senderName,
                            isGroup: false,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final success = await _chatService.rejectChatRequest(
                      request.id,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request rejected'),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBuildingMembersDialog() async {
    final members = await _chatService.getBuildingMembers();

    if (!mounted) return;

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No other members in your flat'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BuildingMembersSheet(
        members: members,
        onMemberTap: (member) async {
          Navigator.pop(context);
          await _sendChatRequest(member);
        },
      ),
    );
  }

  Future<void> _sendChatRequest(Map<String, dynamic> member) async {
    final requestId = await _chatService.sendChatRequest(
      toUserId: member['id'],
      toUserName: member['name'] ?? 'Unknown',
    );

    if (requestId == null && mounted) {
      // Chat already exists
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat already exists with this member'),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (requestId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat request sent!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildDefaultIcon(ChatModel chat, String displayName) {
    if (chat.iconName != null) {
      return Icon(
        _getIconData(chat.iconName!),
        color: Colors.white,
        size: 24.w,
      );
    }

    return Text(
      displayName[0].toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64.w,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.w, color: Colors.red.shade300),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 18.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please try again',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getIconColor(String? colorHex) {
    if (colorHex == null) return AppColors.primary;

    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.primary;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'apartment':
        return Icons.apartment;
      case 'security':
        return Icons.security;
      case 'groups':
        return Icons.groups;
      case 'build':
        return Icons.build;
      case 'person':
        return Icons.person;
      case 'support_agent':
        return Icons.support_agent;
      default:
        return Icons.chat_bubble;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      final hour = timestamp.hour > 12
          ? timestamp.hour - 12
          : (timestamp.hour == 0 ? 12 : timestamp.hour);
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = timestamp.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

// Building Members Bottom Sheet
class _BuildingMembersSheet extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final Function(Map<String, dynamic>) onMemberTap;

  const _BuildingMembersSheet({
    required this.members,
    required this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Icon(Icons.people, color: const Color(0xFF0E4778), size: 24.w),
                SizedBox(width: 12.w),
                Text(
                  'Building Members',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 24.w),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Members count
          if (members.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Row(
                children: [
                  Text(
                    '${members.length} ${members.length == 1 ? 'member' : 'members'} in your flat',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Members list
          Expanded(
            child: members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64.w,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No building members found',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'No other residents in your flat',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return _buildMemberCard(context, member);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Map<String, dynamic> member) {
    final memberName = member['name'] ?? 'Unknown';
    final flatNumber = member['flatNumber'] ?? 'N/A';
    final photoUrl = member['photoUrl'];

    return GestureDetector(
      onTap: () => onMemberTap(member),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
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
            // Avatar
            Container(
              width: 56.w,
              height: 56.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E4778), Color(0xFF061C4C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.network(
                        photoUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            memberName[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        memberName[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            SizedBox(width: 16.w),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memberName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Flat $flatNumber',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF0E4778).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 20.w,
                color: Color(0xFF0E4778),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
