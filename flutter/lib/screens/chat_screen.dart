import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';
import '../main.dart';

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surface3.withAlpha(100),
                AppTheme.surface2.withAlpha(80),
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color: AppTheme.surface3.withAlpha(60),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppTheme.accentGold),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final ChatManager chatManager;

  const ChatScreen({super.key, required this.chatManager});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _chatService = ChatService();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _currentModel = 'gemini/gemini-2.5-flash';
  List<String> _availableModels = [];
  late AnimationController _orbController;
  late AnimationController _pulseController;

  final List<_QuickAction> _quickActions = const [
    _QuickAction('Check system', Icons.monitor_heart_outlined),
    _QuickAction('Help me plan', Icons.account_tree_outlined),
    _QuickAction('Analyze this', Icons.analytics_outlined),
    _QuickAction('Memory recall', Icons.memory_outlined),
    _QuickAction('Write code', Icons.code_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadSession();
    widget.chatManager.addListener(_onSessionsChanged);
    _loadModels();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatManager != widget.chatManager) {
      oldWidget.chatManager.removeListener(_onSessionsChanged);
      widget.chatManager.addListener(_onSessionsChanged);
      _loadSession();
    }
  }

  void _onSessionsChanged() {
    if (mounted) {
      _loadSession();
    }
  }

  void _loadSession() {
    _messages = List.from(widget.chatManager.activeSession.messages);
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _saveSession() {
    widget.chatManager.updateSessionMessages(
      widget.chatManager.activeIndex,
      _messages,
    );
  }

  Future<void> _loadModels() async {
    final models = await _chatService.getAvailableModels();
    if (mounted) setState(() => _availableModels = models);
  }

  Future<void> _sendMessage(String text) async {
    final userMsg = ChatMessage.fromUser(text);
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _saveSession();
    _scrollToBottom();
    _pulseController.repeat(reverse: true);

    try {
      final history = _messages
        .where((m) => m.role != 'system')
        .take(_messages.length > 20 ? _messages.length - 20 : _messages.length)
        .toList();

      final reply = await _chatService.sendMessage(
        message: text,
        history: history,
        model: _currentModel,
      );

      if (mounted) {
        setState(() {
          _messages.add(reply);
          _isLoading = false;
        });
        _saveSession();
        _pulseController.stop();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage.fromAssistant(
            'I apologise, Prince — I encountered an error. Please try again.',
          ));
          _isLoading = false;
        });
        _saveSession();
        _pulseController.stop();
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: AppTheme.easeOutExpo,
        );
      }
    });
  }

  void _newChat() {
    widget.chatManager.createNewSession();
  }

  @override
  void dispose() {
    widget.chatManager.removeListener(_onSessionsChanged);
    _orbController.dispose();
    _pulseController.dispose();
    _chatService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Column(
          children: [
            _buildSessionBar(),
            _buildQuickActions(),
            Expanded(child: _buildMessageList()),
            MessageInput(
              onSend: _sendMessage,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionBar() {
    final sessions = widget.chatManager.sessions;
    if (sessions.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final isActive = index == widget.chatManager.activeIndex;
          final session = sessions[index];
          final label = session.title.length > 18
              ? '${session.title.substring(0, 18)}...'
              : session.title;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => widget.chatManager.switchToSession(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.accentPurple.withAlpha(40)
                      : AppTheme.surface2.withAlpha(160),
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                  border: Border.all(
                    color: isActive
                        ? AppTheme.accentPurple.withAlpha(100)
                        : AppTheme.surface3.withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat_outlined, size: 12,
                      color: isActive ? AppTheme.accentPurple : AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(
                      color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    )),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _orbController,
            builder: (_, __) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.agentGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.glowPurple.withAlpha(
                        (80 + (_orbController.value * 40)).toInt(),
                      ),
                      blurRadius: 12 + _orbController.value * 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('H', style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  )),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hermes', style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              )),
              Row(
                children: [
                  Icon(Icons.circle, size: 6, color: AppTheme.accentEmerald),
                  SizedBox(width: 4),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 22),
          tooltip: 'New chat',
          onPressed: _newChat,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.smart_toy_outlined, size: 20),
          tooltip: 'Model',
          onSelected: (m) => setState(() => _currentModel = m),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'gemini/gemini-2.5-flash',
              child: Text('Gemini 2.5 Flash'),
            ),
            const PopupMenuItem(
              value: 'auto/best-free',
              child: Text('Auto Best Free'),
            ),
            const PopupMenuItem(
              value: 'deepseek/deepseek-v4-flash',
              child: Text('DeepSeek V4 Flash'),
            ),
            ..._availableModels
              .where((m) => ![
                'gemini/gemini-2.5-flash',
                'auto/best-free',
                'deepseek/deepseek-v4-flash',
              ].contains(m))
              .map((m) => PopupMenuItem(value: m, child: Text(_shortModel(m)))),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: 'Clear chat',
          onPressed: () {
            setState(() {
              _messages = [];
              _isLoading = false;
            });
            _pulseController.stop();
            _addWelcomeMessage();
          },
        ),
      ],
    );
  }

  void _addWelcomeMessage() {
    _messages = [
      ChatMessage.fromAssistant(
        'Good evening, Prince. I am **Hermes**, your personal attendant.\n\n'
        'I have access to your system, your memory, and your AI models. '
        'Ask me anything — I am at your disposal.',
        model: 'Hermes v1.0',
      ),
    ];
    _saveSession();
  }

  Widget _buildQuickActions() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppTheme.thinkingGradient,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color: AppTheme.accentPurple.withAlpha(60),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppTheme.accentPurple,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Thinking...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickActions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _QuickChip(
                icon: action.icon,
                label: action.label,
                onTap: () => _sendMessage(action.label),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return AnimatedList(
      key: ValueKey('chat-${widget.chatManager.activeIndex}'),
      controller: _scrollController,
      initialItemCount: _messages.length + (_isLoading ? 1 : 0),
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemBuilder: (context, index, animation) {
        if (index >= _messages.length) {
          return SizeTransition(
            sizeFactor: animation,
            child: const TypingIndicator(),
          );
        }
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppTheme.easeOutExpo,
            )),
            child: ChatBubble(message: _messages[index]),
          ),
        );
      },
    );
  }

  String _shortModel(String m) {
    final parts = m.split('/');
    if (parts.length >= 2) {
      final name = parts[1];
      return '${parts[0]}/${name.length > 18 ? '${name.substring(0, 18)}...' : name}';
    }
    return m.length > 22 ? '${m.substring(0, 22)}...' : m;
  }
}

class _QuickAction {
  final String label;
  final IconData icon;

  const _QuickAction(this.label, this.icon);
}
