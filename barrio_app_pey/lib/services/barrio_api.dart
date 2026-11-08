import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Cliente del único servidor autorizado para catálogo, pedidos y cobros.
/// No contiene llaves de servidor ni toma decisiones de dinero.
class BarrioApi {
  BarrioApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 15);

  String get _apiBase {
    final value = dotenv.env['API_BASE_URL']?.trim() ?? '';
    if (value.isEmpty) {
      throw const BarrioApiException(
          'Falta configurar la dirección de Barrio.');
    }
    return value.replaceFirst(RegExp(r'/$'), '');
  }

  String get _supabaseUrl => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  String get _publishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim() ?? '';

  Future<Map<String, dynamic>> signIn(String email, String password) => _auth(
      'token?grant_type=password', {'email': email, 'password': password});

  Future<Map<String, dynamic>> signUp(
          String email, String password, String name) =>
      _auth('signup', {
        'email': email,
        'password': password,
        'data': {'nombre': name}
      });

  Future<Map<String, dynamic>> refresh(String refreshToken) =>
      _auth('token?grant_type=refresh_token', {'refresh_token': refreshToken});

  Future<Map<String, dynamic>> _auth(
      String route, Map<String, dynamic> body) async {
    if (_supabaseUrl.isEmpty || _publishableKey.isEmpty) {
      throw const BarrioApiException('Falta configurar la sesión de Barrio.');
    }
    final response = await _client
        .post(Uri.parse('$_supabaseUrl/auth/v1/$route'),
            headers: {
              'apikey': _publishableKey,
              'Content-Type': 'application/json'
            },
            body: jsonEncode(body))
        .timeout(_timeout);
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BarrioApiException(data['msg']?.toString() ??
          data['error_description']?.toString() ??
          'No pudimos entrar. Revisa tus datos.');
    }
    return data;
  }

  Future<dynamic> get(String route, {String? token}) =>
      _request('GET', route, token: token);
  Future<dynamic> post(String route, Map<String, dynamic> body,
          {String? token, String? idempotencyKey}) =>
      _request('POST', route,
          token: token, body: body, idempotencyKey: idempotencyKey);
  Future<dynamic> patch(String route, Map<String, dynamic> body,
          {required String token}) =>
      _request('PATCH', route, token: token, body: body);
  Future<dynamic> delete(String route, {required String token}) =>
      _request('DELETE', route, token: token);

  Future<dynamic> _request(String method, String route,
      {String? token,
      Map<String, dynamic>? body,
      String? idempotencyKey}) async {
    final response = await _client
        .send(http.Request(method, Uri.parse('$_apiBase/api/v1$route'))
          ..headers.addAll({
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
            if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey
          })
          ..body = body == null ? '' : jsonEncode(body))
        .then(http.Response.fromStream)
        .timeout(_timeout);
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded['error'];
      throw BarrioApiException(
          error is Map
              ? (error['message']?.toString() ?? 'No pudimos hacerlo ahora.')
              : 'No pudimos hacerlo ahora.',
          statusCode: response.statusCode);
    }
    return decoded['data'];
  }

  Map<String, dynamic> _decode(http.Response response) {
    final value = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes));
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }
}

class BarrioApiException implements Exception {
  const BarrioApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
