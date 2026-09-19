// lib/src/screens/chat_conversation_screen.dart
// Chat conversation screen with Firestore integration - Real data only

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/chat_model.dart';
import '../services/chat_firestore_service.dart';
import '../constants/app_colors.dart';
import '../widgets/skeleton_loader.dart';

class ChatConversationScreen extends StatefulWidget {
  final String chatId;
  final String chatTitle;
  final String? chatSubtitle;
  final bool isGroup;

  const ChatConversationScreen({
    super.key,
    required this.chatId,
    required this.chatTitle,
    this.chatSubtitle,
    this.isGroup = false,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ChatFirestoreService _chatService = ChatFirestoreService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _isSending = false;
  String? _currentUserId;
  bool _userIdLoaded = false;

  @override
  void initState() {
    super.initState();
    // Get current user ID FIRST before anything else
    _initializeUserAndChat();
  }

  Future<void> _initializeUserAndChat() async {
    try {
      // Get current user ID and wait for it to complete
      final userId = await _chatService.getCurrentUserIdPublic();

      if (userId != null) {
        setState(() {
          _currentUserId = userId;
          _userIdLoaded = true;
        });
        print('✅ ChatScreen: User ID loaded: $userId');

        // Now mark chat as read after user ID is available
        await _chatService.markChatAsRead(widget.chatId);
      } else {
        print('❌ ChatScreen: Failed to get user ID');
        setState(() {
          _userIdLoaded = true;
        });
      }
    } catch (e) {
      print('❌ ChatScreen: Error initializing: $e');
      setState(() {
        _userIdLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messageController.clear();
    });

    try {
      await _chatService.sendMessage(chatId: widget.chatId, text: text);

      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList()),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, size: 24.w),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: 12.w),
          Container(
            width: 44.w,
            height: 44.h,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                widget.chatTitle[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
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
                  widget.chatTitle,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                if (widget.chatSubtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    widget.chatSubtitle!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!widget.isGroup)
            IconButton(
              onPressed: () {
                // TODO: Implement call functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Call feature coming soon'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: Icon(Icons.call_outlined, size: 22.w),
              color: const Color(0xFF6B7280),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    // If user ID not loaded yet, show loading state
    if (!_userIdLoaded) {
      return const SkeletonChatLoader();
    }

    // If user ID failed to load, show error
    if (_currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: Colors.red.shade300),
            SizedBox(height: 16.h),
            Text(
              'Failed to load user information',
              style: TextStyle(fontSize: 14.sp, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.streamChatMessages(widget.chatId),
      builder: (context, snapshot) {
        // Loading state - show skeleton
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonChatLoader();
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.w,
                  color: Colors.red.shade300,
                ),
                SizedBox(height: 16.h),
                Text(
                  'Error loading messages',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please try again',
                  style: TextStyle(fontSize: 14.sp, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }

        // Get messages
        final messages = snapshot.data ?? [];

        // Empty state
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64.w,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: 16.h),
                Text(
                  'No messages yet',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Start the conversation',
                  style: TextStyle(fontSize: 14.sp, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }

        // Scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        // Message list
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16.w),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _MessageBubble(
              message: messages[index],
              currentUserId: _currentUserId,
            );
          },
        );
      },
    );
  }

  Widget _buildMessageComposer() {
    final isMessageEmpty = _messageController.text.trim().isEmpty;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: _messageFocusNode.hasFocus
                        ? const Color(0xFF0E4778)
                        : const Color(0xFFE5E7EB),
                    width: _messageFocusNode.hasFocus ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                  ),
                  style: TextStyle(fontSize: 14.sp, color: Color(0xFF111111)),
                  onChanged: (value) => setState(() {}),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Send Button
            GestureDetector(
              onTap: isMessageEmpty ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isMessageEmpty
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFF0E4778),
                  shape: BoxShape.circle,
                  boxShadow: isMessageEmpty
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF0E4778).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Center(
                  child: _isSending
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: isMessageEmpty
                              ? const Color(0xFF9CA3AF)
                              : Colors.white,
                          size: 20.w,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGE BUBBLE
// ============================================================================
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String? currentUserId;

  const _MessageBubble({required this.message, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    // Determine if message is from current user
    final isMe = currentUserId != null && message.senderId == currentUserId;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (isMe) const Spacer(),
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF0E4778) : Colors.white,
              border: isMe ? null : Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show sender name for group chats
                if (!isMe) ...[
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: isMe ? Colors.white : const Color(0xFF111111),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isMe
                            ? Colors.white.withOpacity(0.8)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (isMe) ...[
                      SizedBox(width: 4.w),
                      _statusIcon(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isMe) const Spacer(),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _statusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12.w,
          height: 12.h,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white70,
          ),
        );
      case MessageStatus.sent:
        return Icon(Icons.check, size: 13.w, color: Colors.white70);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 13.w, color: Colors.white70);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 13.w, color: Colors.white);
      case MessageStatus.failed:
        return Icon(Icons.error_outline, size: 13.w, color: Colors.white70);
    }
  }
}
