import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/system_screen.dart';
import 'services/system_service.dart';
import 'theme/app_theme.dart';
import 'models/chat_message.dart';

/// Manages multiple chat sessions at the app level.
class ChatManager extends ChangeNotifier {
  final List<Conversation> _sessions = [];
  int _activeIndex = 0;

  List<Conversation> get sessions => List.unmodifiable(_sessions);
  int get activeIndex => _activeIndex;
  Conversation get activeSession => _sessions[_activeIndex];

  ChatManager() {
    createNewSession();
  }

  void createNewSession() {
    final session = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      messages: [
        ChatMessage.fromAssistant(
          'Good evening, Prince. I am **Hermes**, your personal attendant.\n\n'
          'I have access to your system, your memory, and your AI models. '
          'Ask me anything — I am at your disposal.',
          model: 'Hermes v1.0',
        ),
      ],
    );
    _sessions.add(session);
    _activeIndex = _sessions.length - 1;
    notifyListeners();
  }

  void switchToSession(int index) {
    if (index >= 0 && index < _sessions.length) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  void deleteSession(int index) {
    if (_sessions.length <= 1) return;
    _sessions.removeAt(index);
    if (_activeIndex >= _sessions.length) {
      _activeIndex = _sessions.length - 1;
    }
    notifyListeners();
  }

  void updateSessionMessages(int index, List<ChatMessage> messages) {
    if (index >= 0 && index < _sessions.length) {
      _sessions[index].messages.clear();
      _sessions[index].messages.addAll(messages);
      // Auto-generate title from first user message
      final firstUser = messages.where((m) => m.role == 'user').firstOrNull;
      if (firstUser != null && _sessions[index].title == 'New Chat') {
        _sessions[index].title = firstUser.content.length > 40
            ? '${firstUser.content.substring(0, 40)}...'
            : firstUser.content;
      }
      notifyListeners();
    }
  }
}

class HermesApp extends StatelessWidget {
  const HermesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hermes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final _systemService = SystemService();
  final _chatManager = ChatManager();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      ChatScreen(chatManager: _chatManager),
      ConversationsScreen(
          chatManager: _chatManager,
          onSwitchToChat: () => setState(() => _currentIndex = 0),
        ),
      SystemScreen(service: _systemService),
    ];
  }

  @override
  void dispose() {
    _systemService.dispose();
    _chatManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: AppTheme.easeOutExpo,
        switchOutCurve: AppTheme.easeOutExpo,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.surface3.withAlpha(80),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Memory',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.monitor_heart_outlined),
              activeIcon: Icon(Icons.monitor_heart),
              label: 'System',
            ),
          ],
        ),
      ),
    );
  }
}
