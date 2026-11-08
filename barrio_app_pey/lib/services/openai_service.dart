import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Cliente de la API Barrio. OpenAI vive en el servidor; la app nunca lleva su llave.
class OpenAIService {
  OpenAIService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 15);

  Future<AgentSearchResult> search(String query, {required String zone}) async {
    final baseUrl = dotenv.env['API_BASE_URL']?.trim() ?? '';
    if (baseUrl.isEmpty) {
      throw const OpenAIServiceException(
          'Falta configurar la dirección de la API Barrio.');
    }

    final uri =
        Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/search/agent');
    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({
            'query': query.trim(),
            'filters': {'zone': zone},
          }),
        )
        .timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenAIServiceException(
          'No pude buscar ahora. Inténtalo de nuevo. (${response.statusCode})');
    }

    final body =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final meta = body['meta'] as Map<String, dynamic>? ?? const {};
    return AgentSearchResult(
      answer: meta['answer'] as String? ??
          'Estas opciones coinciden con lo que buscas.',
      businesses: data,
    );
  }
}

class AgentSearchResult {
  const AgentSearchResult({required this.answer, required this.businesses});
  final String answer;
  final List<Map<String, dynamic>> businesses;
}

class OpenAIServiceException implements Exception {
  const OpenAIServiceException(this.message);
  final String message;
}
