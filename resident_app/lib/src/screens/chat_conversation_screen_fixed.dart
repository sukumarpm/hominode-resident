// lib/src/screens/chat_conversation_screen_fixed.dart
// FIXED: Chat screen with proper keyboard behavior and message composer

import 'dart:async';
import 'package:flutter/material.dart';

// ============================================================================
// MODELS
// ============================================================================
enum MessageStatus { sending, sent, delivered, read }

class ConversationFixed {
  final String id;
  final String title;
  final String? subtitle;
  final bool isGroup;
  final int unreadCount;
  final IconData? icon;
  final Color? iconBg;

  ConversationFixed({
    required this.id,
    required this.title,
    this.subtitle,
    this.isGroup = false,
    this.unreadCount = 0,
    this.icon,
    this.iconBg,
  });
}

class ChatMessageFixed {
  final String id;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isMe;

  ChatMessageFixed({
    required this.id,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    required this.isMe,
  });

  ChatMessageFixed copyWith({MessageStatus? status}) {
    return ChatMessageFixed(
      id: id,
      text: text,
      timestamp: timestamp,
      status: status ?? this.status,
      isMe: isMe,
    );
  }
}

// ============================================================================
// CHAT CONVERSATION SCREEN - FIXED VERSION
// ============================================================================
class ChatConversationScreenFixed extends StatefulWidget {
  final ConversationFixed conversation;

  const ChatConversationScreenFixed({super.key, required this.conversation});

  @override
  State<ChatConversationScreenFixed> createState() =>
      _ChatConversationScreenFixedState();
}

class _ChatConversationScreenFixedState
    extends State<ChatConversationScreenFixed> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final List<ChatMessageFixed> _messages = [];
  bool _isSending = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _simulateIncomingMessage();
  }

  void _loadInitialMessages() {
    setState(() {
      _messages.addAll([
        ChatMessageFixed(
          id: 'msg_1',
          text:
              'Hello! I have checked the issue. Will arrive at your flat in 30 minutes.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
          status: MessageStatus.read,
          isMe: false,
        ),
        ChatMessageFixed(
          id: 'msg_2',
          text: 'Thank you! Please bring the necessary tools.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
          status: MessageStatus.read,
          isMe: true,
        ),
        ChatMessageFixed(
          id: 'msg_3',
          text: 'Sure, I have all the required materials. See you soon.',
          timestamp: DateTime.now(),
          status: MessageStatus.delivered,
          isMe: false,
        ),
      ]);
    });
    _scrollToBottom();
  }

  void _simulateIncomingMessage() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isTyping = true);
      }
    });

    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessageFixed(
              id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
              text: 'I am on my way now.',
              timestamp: DateTime.now(),
              status: MessageStatus.delivered,
              isMe: false,
            ),
          );
        });
        _scrollToBottom();
      }
    });
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

    final tempMessage = ChatMessageFixed(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      isMe: true,
    );

    setState(() {
      _messages.add(tempMessage);
      _messageController.clear();
      _isSending = true;
    });
    _scrollToBottom();

    // Simulate sending
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = tempMessage.copyWith(status: MessageStatus.sent);
        }
        _isSending = false;
      });

      // Simulate delivery
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            final index = _messages.indexWhere((m) => m.id == tempMessage.id);
            if (index != -1) {
              _messages[index] = tempMessage.copyWith(
                status: MessageStatus.delivered,
              );
            }
          });
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessageList()),
            if (_isTyping) _buildTypingIndicator(),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  // FIXED: Properly sized header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            icon: const Icon(Icons.arrow_back, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.conversation.iconBg ?? const Color(0xFF0E4778),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.conversation.icon != null
                ? Icon(widget.conversation.icon, color: Colors.white, size: 22)
                : Center(
                    child: Text(
                      widget.conversation.title[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                if (widget.conversation.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.conversation.subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!widget.conversation.isGroup)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.call_outlined, size: 22),
              color: const Color(0xFF6B7280),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _MessageBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Typing',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 20,
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [_TypingDot(), _TypingDot(), _TypingDot()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Properly sized message composer with keyboard handling
  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text Input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 44,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send Button
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _messageController.text.trim().isEmpty
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFF0E4778),
                shape: BoxShape.circle,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _messageController.text.trim().isEmpty
                      ? null
                      : _sendMessage,
                  borderRadius: BorderRadius.circular(22),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.send,
                            size: 20,
                            color: _messageController.text.trim().isEmpty
                                ? const Color(0xFF9CA3AF)
                                : Colors.white,
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
}

// ============================================================================
// MESSAGE BUBBLE
// ============================================================================
class _MessageBubble extends StatelessWidget {
  final ChatMessageFixed message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (message.isMe) const Spacer(),
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: message.isMe ? const Color(0xFF0E4778) : Colors.white,
              border: message.isMe
                  ? null
                  : Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                bottomRight: Radius.circular(message.isMe ? 4 : 16),
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
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 15,
                    color: message.isMe
                        ? Colors.white
                        : const Color(0xFF111111),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: message.isMe
                            ? Colors.white.withOpacity(0.8)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (message.isMe) ...[
                      const SizedBox(width: 4),
                      _statusIcon(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!message.isMe) const Spacer(),
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
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white70,
          ),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 13, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 13, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 13, color: Colors.white);
    }
  }
}

// ============================================================================
// TYPING DOT ANIMATION
// ============================================================================
class _TypingDot extends StatefulWidget {
  const _TypingDot();

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: Color(0xFF9CA3AF),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
