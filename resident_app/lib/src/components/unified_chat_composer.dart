// lib/src/components/unified_chat_composer.dart
// Unified chat message composer matching community wall comments design

import 'package:flutter/material.dart';

class UnifiedChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final String hintText;
  final bool showAttachment;

  const UnifiedChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.isSending = false,
    this.hintText = 'Type your message...',
    this.showAttachment = false,
  });

  @override
  State<UnifiedChatComposer> createState() => _UnifiedChatComposerState();
}

class _UnifiedChatComposerState extends State<UnifiedChatComposer> {
  @override
  Widget build(BuildContext context) {
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
            if (widget.showAttachment) ...[
              GestureDetector(
                onTap: () {
                  // Handle attachment
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.attach_file,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
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
                        controller: widget.controller,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: widget.controller.text.trim().isEmpty || widget.isSending
                  ? null
                  : widget.onSend,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.controller.text.trim().isEmpty
                      ? const Color(0xFFE5E7EB)
                      : const Color(0xFF0E4778),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: widget.isSending
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
                          color: widget.controller.text.trim().isEmpty
                              ? const Color(0xFF9CA3AF)
                              : Colors.white,
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
