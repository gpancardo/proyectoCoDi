import 'dart:async';

import 'package:flutter/services.dart';

import '../state/app_state.dart';
import 'barrio_api.dart';

const _canal = MethodChannel('barrio/avisos');

const _textos = {
  'cobrada': ('Te llegó el cobro', 'Apruébalo en la app de tu banco.'),
  'pagada': ('¡Pagado! ✅', 'Te avisamos cuando tu pedido esté listo.'),
  'lista': ('Tu pedido está listo', 'Pasa por él con tu código.'),
  'rechazada': ('No pudieron tomar tu pedido', 'Busca otra opción cerca de ti.'),
  'expirada': ('Tu pedido venció', 'El negocio no alcanzó a verlo.'),
  'vencida': ('Tu cobro venció', 'Puedes intentarlo otra vez desde tu pedido.'),
};

typedef Aviso = ({int id, String titulo, String texto});

/// Solo avisa si el estado cambió y ese estado le importa a quien compró.
List<Aviso> avisosNuevos(Map<int, String> antes, Map<int, String> ahora) => [
      for (final MapEntry(key: id, value: estado) in ahora.entries)
        if (antes[id] != estado && _textos[estado] != null)
          (id: id, titulo: _textos[estado]!.$1, texto: _textos[estado]!.$2),
    ];

/// ponytail: sondeo cada 10 s con avisos locales; solo llegan mientras Android
/// mantenga viva la app. Si la cierran a la fuerza no hay aviso. Mejora: FCM.
class AvisosPedidos {
  AvisosPedidos(this._state, this._api);
  final AppState _state;
  final BarrioApi _api;
  Map<int, String>? _estados; // null: la primera lectura no avisa de lo que ya pasó
  bool _revisando = false;
  bool _permisoPedido = false;

  void iniciar() {
    Timer.periodic(const Duration(seconds: 10), (_) => revisar());
    revisar();
  }

  Future<void> revisar() async {
    final token = _state.accessToken ?? '';
    if (token.isEmpty) {
      _estados = null;
      return;
    }
    if (_revisando) return;
    _revisando = true;
    try {
      if (!_permisoPedido) {
        _permisoPedido = true;
        await _canal.invokeMethod('permiso');
      }
      final filas = await _api.get('/orders?as=comprador', token: token);
      final ahora = {
        for (final o in (filas as List).whereType<Map<String, dynamic>>())
          (o['id'] as num).toInt(): '${o['estado']}',
      };
      final antes = _estados;
      _estados = ahora;
      if (antes == null) return;
      for (final a in avisosNuevos(antes, ahora)) {
        await _canal.invokeMethod(
            'mostrar', {'id': a.id, 'titulo': a.titulo, 'texto': a.texto});
      }
    } catch (_) {
      // sin señal o sin perfil de comprador: se intenta en la siguiente vuelta
    } finally {
      _revisando = false;
    }
  }
}
