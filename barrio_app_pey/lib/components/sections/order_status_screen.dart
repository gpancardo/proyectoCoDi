import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../apis/models/api_models.dart';
import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../shared/app_button.dart';
import '../shared/barrio_surface.dart';

const statusCopy = <String, String>{
  'pendiente': 'Esperando al negocio',
  'aceptada': 'El negocio aceptó tu pedido',
  'cobrada': 'Aprueba el cobro en tu banco',
  'pagada': '✅ ¡Pagado!',
  'lista': 'Tu pedido ya está listo',
  'entregada': 'Ya lo recibiste',
  'rechazada': 'El negocio no pudo aceptar tu pedido',
  'expirada': 'El negocio no contestó',
  'vencida': 'Este cobro ya venció',
  'cancelada': 'Cancelaste este pedido',
};

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key, required this.orderId});
  final int orderId;
  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen>
    with WidgetsBindingObserver {
  Timer? _poller;
  Map<String, dynamic>? _order;
  PaymentAttemptResponse? _payment;
  String? _problem;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _poller = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final token = context.read<AppState>().accessToken;
    if (token == null) return;
    try {
      final api = context.read<BarrioApi>();
      final order = await api.get('/orders/${widget.orderId}', token: token)
          as Map<String, dynamic>;
      PaymentAttemptResponse? payment;
      if (order['estado'] == 'cobrada') {
        try {
          payment =
              await api.currentPayment(orderId: widget.orderId, token: token);
        } on BarrioApiException {/* el siguiente ciclo vuelve a consultar */}
      }
      if (!mounted) return;
      setState(() {
        _order = order;
        _payment = payment;
        _problem = null;
        _loading = false;
      });
      if (const {'lista', 'entregada', 'rechazada', 'expirada', 'cancelada'}
          .contains(order['estado'])) {
        _poller?.cancel();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _problem = mensajeDe(error);
          _loading = false;
        });
      }
    }
  }

  /// Acción del pedido: si falla, avisa qué hacer en vez de quedarse callada.
  Future<void> _act(String path) async {
    try {
      await context.read<BarrioApi>().post('/orders/${widget.orderId}$path', {},
          token: context.read<AppState>().accessToken);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeDe(error))));
    }
  }

  Future<void> _cancel() => _act('/cancel');
  Future<void> _retryPayment() async {
    try {
      await context.read<BarrioApi>().createPayment(
          orderId: widget.orderId,
          token: context.read<AppState>().accessToken!);
      await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeDe(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: BarrioColors.marino)));
    }
    if (_problem != null && _order == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Tu pedido')),
          body: BarrioBackdrop(
              child: BarrioProblema(message: _problem!, onRetry: _refresh)));
    }
    final order = _order!;
    final state = order['estado'].toString();
    if (state == 'lista') {
      return _DeliveryConfirm(
          order: order, onReceived: () => _act('/received'));
    }
    if (state == 'pagada' || state == 'entregada') {
      return _PaidOrder(order: order, ready: state == 'entregada');
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Tu pedido')),
        body: BarrioBackdrop(
            child: ListView(padding: const EdgeInsets.all(16), children: [
          BarrioPanel(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(statusCopy[state] ?? state,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: BarrioColors.marino)),
                const SizedBox(height: 6),
                const Text('Esta pantalla se actualiza sola.',
                    style: TextStyle(color: BarrioColors.gris)),
                const SizedBox(height: 18),
                const Divider(color: BarrioColors.marino),
                for (final item
                    in (order['items'] as List<dynamic>? ?? const []))
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${item['cantidad']} × ${item['nombre']}')),
                const Divider(color: BarrioColors.marino),
                Text('Total ${formatMoney(order['total_minor'])}',
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: BarrioColors.marino)),
              ])),
          if (state == 'cobrada') ...[
            const SizedBox(height: 16),
            _PaymentInstructions(payment: _payment)
          ],
          if (const {'pendiente', 'aceptada', 'vencida'}.contains(state)) ...[
            const SizedBox(height: 16),
            if (state == 'vencida')
              AppButton(label: 'Mandar otro cobro', onPressed: _retryPayment),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: _cancel, child: const Text('Cancelar pedido'))
          ],
        ])));
  }
}

class _PaymentInstructions extends StatelessWidget {
  const _PaymentInstructions({required this.payment});
  final PaymentAttemptResponse? payment;
  @override
  Widget build(BuildContext context) {
    if (payment == null) {
      return const BarrioPanel(child: Text('Preparando tu cobro…'));
    }
    final via = payment!.via;
    final amount = payment!.amountMinor;
    return BarrioPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Abre la app de tu banco',
          style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: BarrioColors.marino)),
      const SizedBox(height: 8),
      Text(via == 'push'
          ? 'Te llegó un cobro por ${formatMoney(amount)}. Apruébalo desde tu banco.'
          : 'Cuando pagues, esta pantalla se actualiza sola.'),
    ]));
  }
}

class _DeliveryConfirm extends StatelessWidget {
  const _DeliveryConfirm({required this.order, required this.onReceived});
  final Map<String, dynamic> order;
  final Future<void> Function() onReceived;
  Future<void> _report() {
    final subject = Uri.encodeComponent('Problema con pedido ${order['id']}');
    final body = Uri.encodeComponent(
        'Hola, necesito ayuda con mi pedido.\n\nPedido: ${order['id']}\nVendedor: ${order['negocio_id']}\nTotal: ${formatMoney(order['total_minor'])}\n\nQué pasó: ');
    return launchUrl(
        Uri.parse('mailto:ghpancardo@gmail.com?subject=$subject&body=$body'));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: BarrioColors.teal,
      appBar: AppBar(
          backgroundColor: BarrioColors.teal,
          foregroundColor: BarrioColors.blanco),
      body: SafeArea(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Tu pedido está listo',
                            style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: BarrioColors.blanco),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        const Text('Cuando lo recibas, confírmalo aquí.',
                            style: TextStyle(
                                fontSize: 18, color: BarrioColors.blanco),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 28),
                        BarrioPanel(
                            child: Column(children: [
                          Text('Código ${order['codigo'] ?? '—'}',
                              semanticsLabel:
                                  'Código ${(order['codigo'] ?? '').toString().split('').join(' ')}',
                              style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: BarrioColors.marino)),
                          const SizedBox(height: 16),
                          AppButton(
                              label: 'Confirmar que lo recibí',
                              onPressed: () => onReceived()),
                          TextButton(
                              onPressed: _report,
                              child: const Text('Reportar un problema'))
                        ])),
                      ])))));
}

class _PaidOrder extends StatelessWidget {
  const _PaidOrder({required this.order, required this.ready});
  final Map<String, dynamic> order;
  final bool ready;
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: BarrioColors.teal,
      appBar: AppBar(
          backgroundColor: BarrioColors.teal,
          foregroundColor: BarrioColors.blanco),
      body: SafeArea(
          child: Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 64, color: BarrioColors.blanco),
                        const SizedBox(height: 12),
                        Text(ready ? 'Ya puedes pasar' : '¡Pagado!',
                            style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: BarrioColors.blanco)),
                        const SizedBox(height: 8),
                        Text('Total ${formatMoney(order['total_minor'])}',
                            style: const TextStyle(
                                fontSize: 26, color: BarrioColors.blanco)),
                        const SizedBox(height: 28),
                        BarrioPanel(
                            child: Column(children: [
                          const Text('Tu código',
                              style: TextStyle(color: BarrioColors.gris)),
                          Text(order['codigo']?.toString() ?? '—',
                              semanticsLabel: (order['codigo'] ?? '')
                                  .toString()
                                  .split('')
                                  .join(' '),
                              style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                  color: BarrioColors.marino)),
                          const Text('Muéstralo al recoger.',
                              style: TextStyle(color: BarrioColors.gris))
                        ])),
                      ])))));
}
