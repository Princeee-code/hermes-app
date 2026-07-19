import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 80 : 16,
        right: isUser ? 16 : 80,
        top: 6,
        bottom: 6,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAgentHeader(),
          if (!isUser) const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(
                      colors: [
                        AppTheme.surface3.withAlpha(180),
                        AppTheme.surface2.withAlpha(200),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppTheme.surface.withAlpha(200),
                        AppTheme.surface2.withAlpha(160),
                      ],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppTheme.bubbleRadius),
                topRight: const Radius.circular(AppTheme.bubbleRadius),
                bottomLeft: Radius.circular(isUser ? AppTheme.bubbleRadius : 4),
                bottomRight: Radius.circular(isUser ? 4 : AppTheme.bubbleRadius),
              ),
              border: Border.all(
                color: isUser
                    ? AppTheme.accentGold.withAlpha(40)
                    : AppTheme.accentPurple.withAlpha(50),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isUser ? AppTheme.accentGold : AppTheme.accentPurple)
                      .withAlpha(10),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: isUser ? _buildUserContent() : _buildAssistantContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.agentGradient,
            ),
            child: const Center(
              child: Text('H', style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              )),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Hermes', style: TextStyle(
            color: AppTheme.accentGold,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          )),
          if (message.modelUsed != null) ...[
            const SizedBox(width: 6),
            Text(
              '· ${message.modelUsed}',
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SelectableText(
          message.content,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(message.timestamp),
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAssistantContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          message.content,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              _formatTime(message.timestamp),
              style: const TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // Copy to clipboard would go here
              },
              child: Icon(
                Icons.content_copy,
                size: 14,
                color: AppTheme.textTertiary.withAlpha(120),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}';
  }
}
