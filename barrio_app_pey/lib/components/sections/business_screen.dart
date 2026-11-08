import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../shared/app_button.dart';
import '../shared/barrio_surface.dart';
import 'order_status_screen.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key, required this.businessId});
  final int businessId;
  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  Map<String, dynamic>? _business;
  final Map<String, int> _quantities = {};
  final _coupon = TextEditingController();
  bool _loading = true, _sending = false;
  String? _problem;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _problem = null;
    });
    try {
      final b = await context
          .read<BarrioApi>()
          .get('/businesses/${widget.businessId}') as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _business = b;
          _loading = false;
        });
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

  void _aviso(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _review() async {
    final token = context.read<AppState>().accessToken;
    final business = _business!;
    if (token == null) return;
    final items = _quantities.entries
        .where((x) => x.value > 0)
        .map((x) => {'nombre': x.key, 'cantidad': x.value})
        .toList();
    if (items.isEmpty) {
      _aviso('Agrega al menos un producto.');
      return;
    }
    setState(() => _sending = true);
    try {
      final quote = await context.read<BarrioApi>().post(
          '/orders/quotes',
          {
            'business_id': business['id'],
            'items': items,
            if (_coupon.text.trim().isNotEmpty)
              'coupon_code': _coupon.text.trim()
          },
          token: token) as Map<String, dynamic>;
      if (!mounted) return;
      await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: BarrioColors.crema,
          builder: (sheet) => _Ticket(
              quote: quote,
              onConfirm: () async {
                try {
                  final order = await context.read<BarrioApi>().post(
                      '/orders',
                      {
                        'quote_id': quote['quote_id'],
                        'confirmed_total_minor': quote['total_minor']
                      },
                      token: token,
                      idempotencyKey:
                          '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}');
                  if (sheet.mounted) Navigator.pop(sheet);
                  if (mounted) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => OrderStatusScreen(
                            orderId: (order['id'] as num).toInt())));
                  }
                } catch (error) {
                  if (sheet.mounted) Navigator.pop(sheet);
                  if (mounted) _aviso(mensajeDe(error));
                }
              }));
    } catch (error) {
      if (mounted) _aviso(mensajeDe(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('Negocio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          bottom: const PreferredSize(
              preferredSize: Size.fromHeight(2),
              child: Divider(
                  height: 2, thickness: 2, color: BarrioColors.marino))),
      body: BarrioBackdrop(
          child: SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _problem != null
                      ? BarrioProblema(message: _problem!, onRetry: _load)
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          children: [
                              Text(_business!['nombre'].toString(),
                                  style: const TextStyle(
                                      fontSize: 30,
                                      height: 1.1,
                                      fontWeight: FontWeight.w800,
                                      color: BarrioColors.marino)),
                              const SizedBox(height: 6),
                              Text(
                                  [
                                    _business!['categoria'],
                                    _business!['direccion']
                                  ]
                                      .where(
                                          (x) => x != null && '$x'.isNotEmpty)
                                      .join(' · '),
                                  style: const TextStyle(
                                      fontSize: 16, color: BarrioColors.gris)),
                              const SizedBox(height: 20),
                              const BarrioToldo(),
                              for (final p in (_business!['productos']
                                      as List<dynamic>? ??
                                  const []))
                                _ProductRow(
                                    product: p as Map<String, dynamic>,
                                    quantity: _quantities[p['nombre']] ?? 0,
                                    onChange: (delta) => setState(() =>
                                        _quantities[p['nombre'].toString()] =
                                            max(
                                                0,
                                                (_quantities[p['nombre']] ??
                                                        0) +
                                                    delta))),
                              const SizedBox(height: 20),
                              TextField(
                                  controller: _coupon,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: const InputDecoration(
                                      labelText: 'Código de descuento',
                                      hintText: 'Ej. VECINOS10',
                                      helperText:
                                          'Si tienes uno, se aplica a tu cuenta. Las promociones de este negocio se aplican solas.')),
                              const SizedBox(height: 20),
                              AppButton(
                                  label: _sending
                                      ? 'Armando tu cuenta…'
                                      : 'Ver mi cuenta',
                                  onPressed: _sending ? null : _review),
                            ]))));
}

class _ProductRow extends StatelessWidget {
  const _ProductRow(
      {required this.product, required this.quantity, required this.onChange});
  final Map<String, dynamic> product;
  final int quantity;
  final ValueChanged<int> onChange;
  @override
  Widget build(BuildContext c) => Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: BarrioColors.marino, width: 2))),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product['nombre'].toString(),
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          Text(formatMoney(((product['precio'] as num) * 100).round()),
              style: const TextStyle(color: BarrioColors.gris))
        ])),
        IconButton(
            tooltip: 'Quitar ${product['nombre']}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: quantity == 0 ? null : () => onChange(-1),
            icon: const Icon(Icons.remove)),
        SizedBox(
            width: 28,
            child: Text('$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: BarrioColors.marino))),
        IconButton(
            tooltip: 'Agregar ${product['nombre']}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => onChange(1),
            icon: const Icon(Icons.add))
      ]));
}

class _Ticket extends StatefulWidget {
  const _Ticket({required this.quote, required this.onConfirm});
  final Map<String, dynamic> quote;
  final Future<void> Function() onConfirm;
  @override
  State<_Ticket> createState() => _TicketState();
}

class _TicketState extends State<_Ticket> {
  bool _busy = false;

  @override
  Widget build(BuildContext c) {
    final quote = widget.quote;
    final discount = (quote['descuento_minor'] as num? ?? 0);
    return SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: BarrioPanel(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Tu cuenta',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: BarrioColors.marino)),
                  const Divider(color: BarrioColors.marino, thickness: 2),
                  for (final item
                      in (quote['items'] as List<dynamic>? ?? const []))
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  '${item['cantidad']} × ${item['nombre']}',
                                  style: const TextStyle(fontSize: 17))),
                          Text(
                              formatMoney((item['precio_minor'] as num) *
                                  (item['cantidad'] as num)),
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                        ])),
                  if (discount > 0)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(children: [
                          Expanded(
                              child: Text(
                                  '${quote['coupon']?['titulo'] ?? 'Descuento'}',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: BarrioColors.teal,
                                      fontWeight: FontWeight.w700))),
                          Text('−${formatMoney(discount)}',
                              style: const TextStyle(
                                  color: BarrioColors.teal,
                                  fontWeight: FontWeight.w700)),
                        ])),
                  const Divider(color: BarrioColors.marino, thickness: 2),
                  Text('Total ${formatMoney(quote['total_minor'])}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: BarrioColors.marino)),
                  const SizedBox(height: 8),
                  const Text('Revisa tu cuenta antes de confirmar.',
                      style: TextStyle(color: BarrioColors.gris)),
                  const SizedBox(height: 16),
                  AppButton(
                      label: _busy ? 'Mandando tu pedido…' : 'Confirmar pedido',
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() => _busy = true);
                              widget.onConfirm();
                            })
                ]))));
  }
}
