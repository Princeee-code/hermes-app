import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/system_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';
import 'conversations_screen.dart';
import 'system_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _systemService = SystemService();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _currentModel = 'gemini/gemini-2.5-flash';
  List<String> _availableModels = [];
  StreamSubscription? _typingSub;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _loadModels();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages = [
        ChatMessage.fromAssistant(
          'Good evening, Prince. I am Hermes, your personal attendant. '
          'How may I be of service this evening?\n\n'
          'I have access to your system, your memory, and your AI models. '
          'Ask me anything — I am at your disposal.',
          model: 'Hermes v1.0',
        ),
      ];
    });
  }

  Future<void> _loadModels() async {
    final models = await _chatService.getAvailableModels();
    if (mounted) {
      setState(() => _availableModels = models);
    }
  }

  Future<void> _sendMessage(String text) async {
    final userMsg = ChatMessage.fromUser(text);
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

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
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage.fromAssistant(
            'I apologise, Prince — I encountered an error: $e',
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
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

  void _clearChat() {
    setState(() {
      _messages = [];
      _isLoading = false;
    });
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _typingSub?.cancel();
    _chatService.dispose();
    _systemService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.accentGold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Hermes'),
          ],
        ),
        actions: [
          // Model selector
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
                .where((m) => !['gemini/gemini-2.5-flash', 'auto/best-free', 'deepseek/deepseek-v4-flash'].contains(m))
                .map((m) => PopupMenuItem(value: m, child: Text(_shortModel(m)))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Clear chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Active model indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _currentModel,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return const TypingIndicator();
                }
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),

          // Input
          MessageInput(
            onSend: _sendMessage,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentDeep, AppTheme.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.accentDeep,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.accentGold.withAlpha(80), width: 2),
                    ),
                    child: const Center(
                      child: Text('H', style: TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      )),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Hermes', style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  )),
                  const Text('Your personal attendant',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),

            // Navigation
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.accentGold),
              title: const Text('Chat', style: TextStyle(color: AppTheme.textPrimary)),
              selected: true,
              selectedTileColor: AppTheme.surface2,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.memory_outlined, color: AppTheme.accentPurple),
              title: const Text('Conversations', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ConversationsScreen(),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined, color: AppTheme.accentPurple),
              title: const Text('System', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SystemScreen(service: _systemService),
                ));
              },
            ),
            const Divider(color: AppTheme.surface2),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
              title: const Text('About', style: TextStyle(color: AppTheme.textSecondary)),
              onTap: () {
                Navigator.pop(context);
                _showAbout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Hermes',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Built for Prince. Free stack, zero cost.',
      children: [
        const Text(
          'Hermes is an AI chat client that connects to your local '
          'OmniRoute gateway, Hindsight memory, and system services.',
          style: TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  String _shortModel(String m) {
    final parts = m.split('/');
    if (parts.length >= 2) return '${parts[0]}/${parts[1].length > 20 ? '${parts[1].substring(0, 20)}...' : parts[1]}';
    return m.length > 25 ? '${m.substring(0, 25)}...' : m;
  }
}
