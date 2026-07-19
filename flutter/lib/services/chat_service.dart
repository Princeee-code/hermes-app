import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ChatService {
  static String _baseUrl = 'http://127.0.0.1:20128/v1';
  static String _apiKey = '5f238e76072d7926';
  static String _defaultModel = 'gemini/gemini-2.5-flash';

  final http.Client _client;

  ChatService() : _client = http.Client() {
    _loadConfig();
  }

  void _loadConfig() {
    // In debug/profile, API key is compiled in.
    // For release builds where it matters, read from env or a config file.
    // Currently the OmniRoute gateway doesn't require auth at localhost,
    // so _apiKey isn't critical for local use.
    try {
      if (!kIsWeb && Platform.environment.containsKey('OMNIROUTE_API_KEY')) {
        _apiKey = Platform.environment['OMNIROUTE_API_KEY']!;
      }
      if (!kIsWeb && Platform.environment.containsKey('OMNIROUTE_URL')) {
        _baseUrl = Platform.environment['OMNIROUTE_URL']!;
      }
      if (!kIsWeb && Platform.environment.containsKey('HERMES_DEFAULT_MODEL')) {
        _defaultModel = Platform.environment['HERMES_DEFAULT_MODEL']!;
      }
    } catch (_) {
      // Non-web platforms without Platform support use defaults
    }
  }

  /// Send a message and get a complete response.
  Future<ChatMessage> sendMessage({
    required String message,
    required List<ChatMessage> history,
    String? model,
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': 'You are Hermes, a refined AI attendant. '
            'Respond concisely with elegance and precision. '
            'Use Markdown for formatting where helpful.'
      },
      ...history.map((m) => m.toJson()),
      {'role': 'user', 'content': message},
    ];

    final body = jsonEncode({
      'model': model ?? _defaultModel,
      'messages': messages,
      'stream': false,
      'max_tokens': 4096,
    });

    final response = await _client.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'OmniRoute error ${response.statusCode}: ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final modelUsed = data['model'] as String?;
    final choices = data['choices'] as List?;

    if (choices == null || choices.isEmpty) {
      throw const HttpException('No response from model');
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
    final messages = [
      {
        'role': 'system',
        'content': 'You are Hermes, a refined AI attendant. '
            'Respond concisely with elegance and precision. '
            'Use Markdown for formatting where helpful.'
      },
      ...history.map((m) => m.toJson()),
      {'role': 'user', 'content': message},
    ];

    final body = jsonEncode({
      'model': model ?? _defaultModel,
      'messages': messages,
      'stream': true,
      'max_tokens': 4096,
    });

    final request = http.Request('POST',
      Uri.parse('$_baseUrl/chat/completions'));
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $_apiKey';
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
        Uri.parse('$_baseUrl/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );
      if (response.statusCode != 200) return [_defaultModel];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final models = data['data'] as List?;
      if (models == null) return [_defaultModel];

      return models
        .map((m) => m['id'] as String)
        .where((id) =>
          id.startsWith('gemini/') ||
          id.startsWith('auto/') ||
          id.startsWith('deepseek/') ||
          id == _defaultModel)
        .take(20)
        .toList()
      ..sort();
    } catch (_) {
      return [_defaultModel];
    }
  }

  void dispose() => _client.close();
}
