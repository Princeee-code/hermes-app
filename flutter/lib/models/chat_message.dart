class ChatMessage {
  static int _idCounter = 0;

  static String _generateId() {
    _idCounter++;
    return '${DateTime.now().millisecondsSinceEpoch}-$_idCounter';
  }

  final String id;
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;
  final String? modelUsed;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.modelUsed,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };

  static ChatMessage fromUser(String content) => ChatMessage(
    id: _generateId(),
    role: 'user',
    content: content,
  );

  static ChatMessage fromAssistant(String content, {String? model}) => ChatMessage(
    id: _generateId(),
    role: 'assistant',
    content: content,
    modelUsed: model,
  );
}

class Conversation {
  final String id;
  String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get preview {
    if (messages.isEmpty) return 'New conversation';
    final last = messages.last;
    return last.content.length > 60
        ? '${last.content.substring(0, 60)}...'
        : last.content;
  }
}
