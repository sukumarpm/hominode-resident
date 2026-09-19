import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ============================================================================
// THEME CONSTANTS
// ============================================================================
const Color kPrimary = Color(0xFF0E4778);
const Color kIncomingBubbleBg = Color(0xFFFFFFFF);
const Color kIncomingBubbleBorder = Color(0xFFE6E6E6);
const Color kOutgoingBubbleBg = Color(0xFF0E4778);
const Color kTextDark = Color(0xFF111111);
const Color kTextMuted = Color(0xFF8C8C8C);
const Color kTimestampColor = Color(0xFFC4C4C4);
const Color kHeaderBg = Color(0xFFFFFFFF);
const Color kInputBg = Color(0xFFF5F5F5);
const double kBubbleRadius = 16.0;
const double kAvatarSize = 48.0;
const double kBubbleMaxWidth = 0.72;

// ============================================================================
// MODELS
// ============================================================================
enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isMe;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.status = MessageStatus.sent,
    required this.isMe,
    this.imageUrl,
  });

  ChatMessage copyWith({MessageStatus? status, String? text}) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      text: text ?? this.text,
      timestamp: timestamp,
      status: status ?? this.status,
      isMe: isMe,
      imageUrl: imageUrl,
    );
  }
}

enum ChatEventType { message, typing, statusUpdate }

class ChatEvent {
  final ChatEventType type;
  final ChatMessage? message;
  final bool? isTyping;
  final String? messageId;
  final MessageStatus? newStatus;

  ChatEvent.message(this.message)
    : type = ChatEventType.message,
      isTyping = null,
      messageId = null,
      newStatus = null;

  ChatEvent.typing(this.isTyping)
    : type = ChatEventType.typing,
      message = null,
      messageId = null,
      newStatus = null;

  ChatEvent.statusUpdate(this.messageId, this.newStatus)
    : type = ChatEventType.statusUpdate,
      message = null,
      isTyping = null;
}

// ============================================================================
// CHAT REPOSITORY (Mock Implementation)
// ============================================================================
class ChatRepository {
  final StreamController<ChatEvent> _streamController =
      StreamController<ChatEvent>.broadcast();
  final List<ChatMessage> _queuedMessages = [];
  bool isOnline = true;

  // Mock: Fetch initial messages
  Future<List<ChatMessage>> fetchMessages({
    required String chatId,
    int page = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Sample conversation matching screenshot
    return [
      ChatMessage(
        id: 'msg_1',
        senderId: 'tech_001',
        text:
            'Hello! I have checked the issue. Will arrive at your flat in 30 minutes.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
        status: MessageStatus.read,
        isMe: false,
      ),
      ChatMessage(
        id: 'msg_2',
        senderId: 'resident_001',
        text: 'Thank you! Please bring the necessary tools.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        status: MessageStatus.read,
        isMe: true,
      ),
      ChatMessage(
        id: 'msg_3',
        senderId: 'tech_001',
        text: 'Sure, I have all the required materials. See you soon.',
        timestamp: DateTime.now(),
        status: MessageStatus.delivered,
        isMe: false,
      ),
    ];
  }

  // Mock: Send message with network simulation
  Future<ChatMessage> sendMessage(String chatId, ChatMessage msg) async {
    if (!isOnline) {
      _queuedMessages.add(msg);
      throw Exception('No internet connection. Message queued.');
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate 10% failure rate for testing retry
    // if (Random().nextInt(10) == 0) throw Exception('Send failed');

    final sentMsg = msg.copyWith(status: MessageStatus.sent);

    // Simulate delivery after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      _streamController.add(
        ChatEvent.statusUpdate(sentMsg.id, MessageStatus.delivered),
      );
    });

    // Simulate read after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _streamController.add(
        ChatEvent.statusUpdate(sentMsg.id, MessageStatus.read),
      );
    });

    return sentMsg;
  }

  // Mock: Real-time chat stream (WebSocket simulation)
  Stream<ChatEvent> chatStream(String chatId) {
    // Simulate incoming message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _streamController.add(ChatEvent.typing(true));
    });

    Future.delayed(const Duration(seconds: 7), () {
      _streamController.add(ChatEvent.typing(false));
      _streamController.add(
        ChatEvent.message(
          ChatMessage(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            senderId: 'tech_001',
            text: 'I am on my way now.',
            timestamp: DateTime.now(),
            status: MessageStatus.delivered,
            isMe: false,
          ),
        ),
      );
    });

    return _streamController.stream;
  }

  // Offline queue sync (integrate with Hive/SQLite for persistence)
  Future<void> syncQueuedMessages(String chatId) async {
    if (!isOnline || _queuedMessages.isEmpty) return;

    final messagesToSync = List<ChatMessage>.from(_queuedMessages);
    _queuedMessages.clear();

    for (var msg in messagesToSync) {
      try {
        await sendMessage(chatId, msg);
      } catch (e) {
        _queuedMessages.add(msg); // Re-queue on failure
      }
    }
  }

  void dispose() {
    _streamController.close();
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================
String formatTimestamp(DateTime timestamp) {
  final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
  final minute = timestamp.minute.toString().padLeft(2, '0');
  final period = timestamp.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

Widget messageStatusIcon(MessageStatus status) {
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
      return Icon(Icons.check, size: 14.w, color: Colors.white70);
    case MessageStatus.delivered:
      return Icon(Icons.done_all, size: 14.w, color: Colors.white70);
    case MessageStatus.read:
      return Icon(Icons.done_all, size: 14.w, color: Colors.white);
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================
class ChatWithTechnicianScreen extends StatefulWidget {
  final String chatId;
  final String technicianName;
  final String technicianRole;
  final String? technicianAvatar;
  final String? technicianPhone;

  const ChatWithTechnicianScreen({
    super.key,
    required this.chatId,
    this.technicianName = 'Ramesh Kumar',
    this.technicianRole = 'Plumbing Technician',
    this.technicianAvatar,
    this.technicianPhone,
  });

  @override
  State<ChatWithTechnicianScreen> createState() =>
      _ChatWithTechnicianScreenState();
}

class _ChatWithTechnicianScreenState extends State<ChatWithTechnicianScreen> {
  final ChatRepository _repository = ChatRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenToChatStream();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _repository.fetchMessages(chatId: widget.chatId);
      setState(() {
        _messages.addAll(messages);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _listenToChatStream() {
    _chatSubscription = _repository.chatStream(widget.chatId).listen((event) {
      switch (event.type) {
        case ChatEventType.message:
          if (event.message != null) {
            setState(() => _messages.add(event.message!));
            _scrollToBottom();
          }
          break;
        case ChatEventType.typing:
          setState(() => _isTyping = event.isTyping ?? false);
          break;
        case ChatEventType.statusUpdate:
          if (event.messageId != null && event.newStatus != null) {
            setState(() {
              final index = _messages.indexWhere(
                (m) => m.id == event.messageId,
              );
              if (index != -1) {
                _messages[index] = _messages[index].copyWith(
                  status: event.newStatus,
                );
              }
            });
          }
          break;
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

    final tempMessage = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'resident_001',
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

    try {
      final sentMessage = await _repository.sendMessage(
        widget.chatId,
        tempMessage,
      );
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = sentMessage;
        }
        _isSending = false;
      });
    } catch (e) {
      // Mark as failed, show retry option
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = tempMessage.copyWith(
            status: MessageStatus.sending,
          );
        }
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: ${e.toString()}'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _retrySend(tempMessage),
          ),
        ),
      );
    }
  }

  Future<void> _retrySend(ChatMessage message) async {
    // Implement retry logic
    _sendMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMessageList(),
            ),
            if (_isTyping) _buildTypingIndicator(),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: kHeaderBg,
        border: Border(
          bottom: BorderSide(color: kIncomingBubbleBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: kAvatarSize / 2,
            backgroundColor: kPrimary,
            child: Text(
              widget.technicianName[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.technicianName,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  widget.technicianRole,
                  style: TextStyle(fontSize: 14.sp, color: kTextMuted),
                ),
                if (widget.technicianPhone != null) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 12.w, color: kTextMuted),
                      SizedBox(width: 4.w),
                      Text(
                        widget.technicianPhone!,
                        style: TextStyle(fontSize: 13.sp, color: kTextMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(22.r),
              child: Container(
                width: 44.w,
                height: 44.h,
                alignment: Alignment.center,
                child: Icon(Icons.close, size: 24.w, color: kTextMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return MessageBubble(message: message);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: kIncomingBubbleBg,
          border: Border.all(color: kIncomingBubbleBorder),
          borderRadius: BorderRadius.circular(kBubbleRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Typing',
              style: TextStyle(fontSize: 14.sp, color: kTextMuted),
            ),
            SizedBox(width: 4.w),
            _buildTypingDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return Row(
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          builder: (context, value, child) {
            return Container(
              margin: EdgeInsets.only(left: index > 0 ? 3 : 0),
              width: 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: kTextMuted.withOpacity(0.3 + (value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE6E6E6), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14.sp,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                style: TextStyle(fontSize: 14.sp, color: kTextDark),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? Center(
                      child: SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(Icons.send, color: Colors.white, size: 20.w),
                      padding: EdgeInsets.zero,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGE BUBBLE COMPONENT
// ============================================================================
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * kBubbleMaxWidth;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: message.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isMe) const Spacer(),
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: message.isMe ? kOutgoingBubbleBg : kIncomingBubbleBg,
              border: message.isMe
                  ? null
                  : Border.all(color: kIncomingBubbleBorder),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(kBubbleRadius),
                topRight: const Radius.circular(kBubbleRadius),
                bottomLeft: Radius.circular(message.isMe ? kBubbleRadius : 4),
                bottomRight: Radius.circular(message.isMe ? 4 : kBubbleRadius),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                    fontSize: 15.sp,
                    color: message.isMe ? Colors.white : kTextDark,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatTimestamp(message.timestamp),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: message.isMe ? Colors.white70 : kTimestampColor,
                      ),
                    ),
                    if (message.isMe) ...[
                      SizedBox(width: 6.w),
                      messageStatusIcon(message.status),
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
}
