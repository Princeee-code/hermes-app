import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

/// Configuration for the OmniRoute API.
///
/// In production these values should come from environment
/// variables or a secure configuration source.
class _ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:20128/v1';
  static const String apiKey = '5f238e76072d7926';
  static const String defaultModel = 'gemini/gemini-2.5-flash';
}

class ChatService {
  final http.Client _client;

  ChatService() : _client = http.Client();

  /// Build the message list from the user input and conversation history.
  List<Map<String, dynamic>> _buildMessages(
    String message,
    List<ChatMessage> history,
  ) {
    return [
      {
        'role': 'system',
        'content': 'You are Hermes, a refined AI attendant. '
            'Respond concisely with elegance and precision. '
            'Use Markdown for formatting where helpful.',
      },
      ...history.map((m) => m.toJson()),
      {'role': 'user', 'content': message},
    ];
  }

  /// Send a message and get a complete response.
  Future<ChatMessage> sendMessage({
    required String message,
    required List<ChatMessage> history,
    String? model,
  }) async {
    final messages = _buildMessages(message, history);

    final body = jsonEncode({
      'model': model ?? _ApiConfig.defaultModel,
      'messages': messages,
      'stream': false,
      'max_tokens': 4096,
    });

    final response = await _client.post(
      Uri.parse('${_ApiConfig.baseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_ApiConfig.apiKey}',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'The AI service returned an error (${response.statusCode}). '
        'Please try again later.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final modelUsed = data['model'] as String?;
    final choices = data['choices'] as List?;

    if (choices == null || choices.isEmpty) {
      throw Exception('No response from the AI service. Please try again.');
    }

    final reply = choices[0]['message']['content'] as String? ?? '';
    return ChatMessage.fromAssistant(reply, model: modelUsed);
  }

  /// Stream a response token by token.
  Stream<String> streamMessage({
    required String message,
    required List<ChatMessage> history,
    String? model,
  }) async* {
    final messages = _buildMessages(message, history);

    final body = jsonEncode({
      'model': model ?? _ApiConfig.defaultModel,
      'messages': messages,
      'stream': true,
      'max_tokens': 4096,
    });

    final request = http.Request('POST',
      Uri.parse('${_ApiConfig.baseUrl}/chat/completions'));
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer ${_ApiConfig.apiKey}';
    request.body = body;

    final streamedResponse = await _client.send(request);

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      // Parse SSE lines
      for (final line in chunk.split('\n')) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6);
        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;
          final delta = choices[0]['delta'] as Map<String, dynamic>?;
          final content = delta?['content'] as String?;
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        } catch (_) {
          // Skip malformed chunks
        }
      }
    }
  }

  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _client.get(
        Uri.parse('${_ApiConfig.baseUrl}/models'),
        headers: {'Authorization': 'Bearer ${_ApiConfig.apiKey}'},
      );
      if (response.statusCode != 200) return [_ApiConfig.defaultModel];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final models = data['data'] as List?;
      if (models == null) return [_ApiConfig.defaultModel];

      return models
        .map((m) => m['id'] as String)
        .where((id) =>
          id.startsWith('gemini/') ||
          id.startsWith('auto/') ||
          id.startsWith('deepseek/') ||
          id == _ApiConfig.defaultModel)
        .take(20)
        .toList()
      ..sort();
    } catch (_) {
      return [_ApiConfig.defaultModel];
    }
  }

  void dispose() => _client.close();
}
