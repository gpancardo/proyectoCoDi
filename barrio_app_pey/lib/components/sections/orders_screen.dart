import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../shared/barrio_surface.dart';
import 'order_status_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic>? _orders;
  String? _message;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<BarrioApi>().get('/orders?as=comprador',
          token: context.read<AppState>().accessToken) as List<dynamic>;
      if (mounted) setState(() => _orders = data);
    } catch (e) {
      if (mounted) setState(() => _message = mensajeDe(e));
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: BarrioBackdrop(
          child: _orders == null && _message == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if (_message != null)
                    BarrioPanel(child: Text(_message!))
                  else if (_orders!.isEmpty)
                    const Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Text(
                            'Aún no has pedido. Busca algo rico en Descubrir.'))
                  else
                    for (final item in _orders!)
                      _OrderCard(order: item as Map<String, dynamic>)
                ])));
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Map<String, dynamic> order;
  @override
  Widget build(BuildContext c) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
          onTap: () => Navigator.push(
              c,
              MaterialPageRoute(
                  builder: (_) => OrderStatusScreen(
                      orderId: (order['id'] as num).toInt()))),
          borderRadius: BorderRadius.circular(6),
          child: BarrioPanel(
              child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Pedido ${order['id']}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: BarrioColors.marino)),
                  Text(statusCopy[order['estado']] ?? '',
                      style: const TextStyle(color: BarrioColors.gris))
                ])),
            Text(formatMoney(order['total_minor']),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: BarrioColors.marino))
          ]))));
}
