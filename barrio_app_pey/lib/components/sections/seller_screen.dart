import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../shared/app_button.dart';
import '../shared/barrio_surface.dart';

/// Gestión deliberadamente corta: el negocio solo ve lo que puede resolver ya.
class SellerScreen extends StatefulWidget {
  const SellerScreen({super.key});
  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  bool _loading = true;
  String? _message;
  Map<String, dynamic>? _business;
  List<dynamic> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AppState>().accessToken;
    if (token == null) {
      setState(() {
        _loading = false;
        _message = 'Entra con tu cuenta para atender tu negocio.';
      });
      return;
    }
    try {
      final api = context.read<BarrioApi>();
      final me = await api.get('/me', token: token) as Map<String, dynamic>;
      final business = me['negocio'] as Map<String, dynamic>?;
      if (business == null) {
        setState(() {
          _loading = false;
          _message = 'Registra tu negocio desde la app web por ahora.';
        });
        return;
      }
      final orders = await api.get('/orders', token: token) as List<dynamic>;
      if (mounted)
        setState(() {
          _business = business;
          _orders = orders;
          _loading = false;
        });
    } on BarrioApiException catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _message = error.message;
        });
    }
  }

  Future<void> _action(int id, String action) async {
    final token = context.read<AppState>().accessToken!;
    await context
        .read<BarrioApi>()
        .post('/orders/$id/$action', {}, token: token);
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: BarrioBackdrop(
            child: SafeArea(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: BarrioColors.marino))
                    : ListView(padding: const EdgeInsets.all(16), children: [
                        Text(_business?['nombre']?.toString() ?? 'Tu negocio',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        if (_message != null)
                          BarrioPanel(child: Text(_message!))
                        else ...[
                          _BusinessSwitch(
                              business: _business!,
                              onChanged: (value) async {
                                await context.read<BarrioApi>().patch(
                                    '/business', {'abierto': value},
                                    token:
                                        context.read<AppState>().accessToken!);
                                await _load();
                              }),
                          const SizedBox(height: 24),
                          const Text('Pedidos',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: BarrioColors.marino)),
                          const SizedBox(height: 8),
                          if (_orders.isEmpty)
                            const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                    'Cuando alguien te pida, aparece aquí.')),
                          for (final order in _orders)
                            _OrderRow(
                                order: order as Map<String, dynamic>,
                                onAction: _action),
                        ],
                      ]))),
      );
}

class _BusinessSwitch extends StatelessWidget {
  const _BusinessSwitch({required this.business, required this.onChanged});
  final Map<String, dynamic> business;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final open = business['abierto'] == true;
    return BarrioPanel(
        child: Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(open ? 'Abierto' : 'Cerrado',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BarrioColors.marino)),
        const Text('Cámbialo cuando no puedas recibir pedidos.',
            style: TextStyle(color: BarrioColors.gris))
      ])),
      Switch(
          value: open,
          onChanged: onChanged,
          activeThumbColor: BarrioColors.mango),
    ]));
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.onAction});
  final Map<String, dynamic> order;
  final Future<void> Function(int, String) onAction;
  @override
  Widget build(BuildContext context) {
    final state = order['estado']?.toString() ?? '';
    final id = order['id'] as int;
    final total =
        ((order['total_minor'] as num? ?? 0) / 100).toStringAsFixed(0);
    return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: BarrioPanel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pedido $id · \$$total',
              style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: BarrioColors.marino)),
          const SizedBox(height: 4),
          Text(state == 'pendiente' ? 'Esperando tu respuesta' : state),
          for (final item in (order['items'] as List<dynamic>? ?? const []))
            Text('${item['cantidad']} × ${item['nombre']}'),
          if ((order['comprador_logros'] as List<dynamic>? ?? const [])
              .isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    'Logros de tu cliente: ${(order['comprador_logros'] as List<dynamic>).map((b) => b['nombre']).join(' · ')}',
                    style: const TextStyle(
                        color: BarrioColors.teal,
                        fontWeight: FontWeight.w700))),
          const SizedBox(height: 12),
          if (state == 'pendiente')
            Row(children: [
              Expanded(
                  child: AppButton(
                      label: 'Aceptar',
                      iconAsset: 'check',
                      onPressed: () => onAction(id, 'accept'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => onAction(id, 'reject'),
                      child: const Text('Rechazar')))
            ]),
          if (state == 'pagada')
            AppButton(
                label: 'Marcar listo',
                iconAsset: 'check',
                onPressed: () => onAction(id, 'ready')),
        ])));
  }
}
