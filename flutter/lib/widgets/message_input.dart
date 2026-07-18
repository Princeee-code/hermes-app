import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;

  const MessageInput({super.key, required this.onSend, this.isLoading = false});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surface2, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: widget.isLoading ? null : (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Message Hermes...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: widget.isLoading
                ? AppTheme.textSecondary.withAlpha(80)
                : AppTheme.accentGold,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: widget.isLoading ? null : _submit,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: widget.isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textSecondary,
                        ),
                      )
                    : const Icon(Icons.arrow_upward, color: AppTheme.bg, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
