import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/system_info.dart';

class SystemService {
  static const String _baseUrl = 'http://127.0.0.1:9091';

  final http.Client _client;

  SystemService() : _client = http.Client();

  Future<SystemInfo> getStatus() async {
    try {
      final resp = await _client.get(
        Uri.parse('$_baseUrl/system/status'),
      ).timeout(const Duration(seconds: 5));

      if (resp.statusCode != 200) return SystemInfo.empty();
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return SystemInfo.fromJson(json);
    } catch (_) {
      return SystemInfo.empty();
    }
  }

  void dispose() => _client.close();
}
