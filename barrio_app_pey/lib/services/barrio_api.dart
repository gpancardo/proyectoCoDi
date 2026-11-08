import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../apis/models/api_models.dart';

/// Cliente del único servidor autorizado para catálogo, pedidos y cobros.
/// No contiene llaves de servidor ni toma decisiones de dinero.
class BarrioApi {
  BarrioApi({http.Client? client, SupabaseClient? supabase})
      : _client = client ?? http.Client(),
        _supabase = supabase ?? Supabase.instance.client;

  final http.Client _client;
  final SupabaseClient _supabase;
  static const _timeout = Duration(seconds: 15);

  String get _apiBase {
    final value = dotenv.env['API_BASE_URL']?.trim() ?? '';
    if (value.isEmpty) {
      throw const BarrioApiException(
          'Falta configurar la dirección de Barrio.');
    }
    return value.replaceFirst(RegExp(r'/$'), '');
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth
          .signInWithPassword(email: email, password: password);
      return _sessionJson(response.session);
    } on AuthException catch (error) {
      throw BarrioApiException(error.message);
    }
  }

  Future<Map<String, dynamic>> signUp(
      String email, String password, String name) async {
    try {
      final response = await _supabase.auth
          .signUp(email: email, password: password, data: {'nombre': name});
      return _sessionJson(response.session);
    } on AuthException catch (error) {
      throw BarrioApiException(error.message);
    }
  }

  Map<String, dynamic> _sessionJson(Session? session) => {
        if (session != null) 'access_token': session.accessToken,
        if (session != null) 'refresh_token': session.refreshToken,
      };

  Future<AgentSearchResponse> searchAgent(
      {required String query,
      required String zone,
      required String? token}) async {
    final envelope = await _request('POST', '/search/agent',
        token: token,
        body: {
          'query': query,
          'filters': {'zone': zone}
        },
        includeEnvelope: true) as Map<String, dynamic>;
    return AgentSearchResponse.fromJson(envelope);
  }

  Future<QuoteResponse> createQuote({
    required int businessId,
    required List<Map<String, dynamic>> items,
    String? couponCode,
    required String token,
  }) async =>
      QuoteResponse.fromJson(await post(
          '/orders/quotes',
          {
            'business_id': businessId,
            'items': items,
            if (couponCode != null && couponCode.isNotEmpty)
              'coupon_code': couponCode,
          },
          token: token) as Map<String, dynamic>);

  Future<OrderResponse> confirmOrder({
    required int quoteId,
    required int confirmedTotalMinor,
    required String token,
    required String idempotencyKey,
  }) async =>
      OrderResponse.fromJson(await post(
          '/orders',
          {
            'quote_id': quoteId,
            'confirmed_total_minor': confirmedTotalMinor,
          },
          token: token,
          idempotencyKey: idempotencyKey) as Map<String, dynamic>);

  /// Pey se integra mediante el backend; la app nunca guarda sus llaves.
  Future<PaymentAttemptResponse> createPayment(
          {required int orderId, required String token}) async =>
      PaymentAttemptResponse.fromJson(
          await post('/orders/$orderId/payments', {}, token: token)
              as Map<String, dynamic>);

  Future<PaymentAttemptResponse?> currentPayment(
      {required int orderId, required String token}) async {
    final result = await get('/orders/$orderId/payments/current', token: token);
    return result is Map<String, dynamic>
        ? PaymentAttemptResponse.fromJson(result)
        : null;
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
      String? idempotencyKey,
      bool includeEnvelope = false}) async {
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
    return includeEnvelope ? decoded : decoded['data'];
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
