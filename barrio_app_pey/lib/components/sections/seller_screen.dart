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
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _message = mensajeDe(error);
        });
    }
  }

  void _aviso(Object error) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(mensajeDe(error))));

  Future<void> _action(int id, String action) async {
    try {
      await context.read<BarrioApi>().post('/orders/$id/$action', {},
          token: context.read<AppState>().accessToken!);
      await _load();
    } catch (error) {
      if (mounted) _aviso(error);
    }
  }

  Future<void> _setOpen(bool value) async {
    try {
      await context.read<BarrioApi>().patch('/business', {'abierto': value},
          token: context.read<AppState>().accessToken!);
      await _load();
    } catch (error) {
      if (mounted) _aviso(error);
    }
  }

  Future<void> _newCoupon() async {
    final created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: BarrioColors.crema,
        builder: (_) => _CouponForm(
            products: (_business!['productos'] as List<dynamic>? ?? const [])
                .map((p) => p['nombre'].toString())
                .toList()));
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Listo. Tus clientes ya pueden usar ese código.')));
    }
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
                              business: _business!, onChanged: _setOpen),
                          const SizedBox(height: 12),
                          OutlinedButton(
                              onPressed: _newCoupon,
                              child: const Text('Crear código de descuento')),
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
          Text(_estado[state] ?? state),
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

const _estado = {
  'pendiente': 'Esperando tu respuesta',
  'aceptada': 'Cobro enviado, esperando el pago',
  'cobrada': 'Cobro enviado, esperando el pago',
  'pagada': 'Pagado. Prepáralo',
  'lista': 'Listo, esperando que lo recoja',
  'entregada': 'Entregado',
  'rechazada': 'Rechazado',
  'expirada': 'Sin respuesta a tiempo',
  'vencida': 'El cobro venció',
  'cancelada': 'Lo canceló el cliente',
};

class _CouponForm extends StatefulWidget {
  const _CouponForm({required this.products});
  final List<String> products;
  @override
  State<_CouponForm> createState() => _CouponFormState();
}

class _CouponFormState extends State<_CouponForm> {
  final _title = TextEditingController();
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _min = TextEditingController();
  String _type = 'porcentaje';
  String? _gift;
  int _days = 7;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _code.dispose();
    _value.dispose();
    _min.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = int.tryParse(_value.text.trim()) ?? 0;
    if (_type != 'producto_gratis' && value <= 0) {
      setState(() => _error = 'Escribe cuánto descuentas.');
      return;
    }
    if (_type == 'producto_gratis' && _gift == null) {
      setState(() => _error = 'Elige el producto que regalas.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<BarrioApi>().post(
          '/business/coupons',
          {
            'title': _title.text.trim(),
            'type': _type,
            // ponytail: sin monto fijo en pesos; porcentaje a toda la compra o producto gratis. Porcentaje por artículo pide soporte en la API.
            'value': value,
            if (_type == 'producto_gratis') 'free_product': _gift,
            if (_code.text.trim().isNotEmpty) 'code': _code.text.trim(),
            'min_amount_minor': (int.tryParse(_min.text.trim()) ?? 0) * 100,
            'expires_at': DateTime.now()
                .add(Duration(days: _days))
                .toUtc()
                .toIso8601String(),
          },
          token: context.read<AppState>().accessToken!);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = mensajeDe(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Código de descuento',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: BarrioColors.marino)),
            const SizedBox(height: 16),
            TextField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej. 10% a vecinos de la colonia')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(
                      value: 'porcentaje',
                      child: Text('Porcentaje en toda la compra')),
                  DropdownMenuItem(
                      value: 'producto_gratis',
                      child: Text('Un producto gratis')),
                ],
                onChanged: (v) => setState(() => _type = v!)),
            const SizedBox(height: 12),
            if (_type == 'producto_gratis')
              DropdownButtonFormField<String>(
                  initialValue: _gift,
                  decoration:
                      const InputDecoration(labelText: 'Producto que regalas'),
                  items: [
                    for (final p in widget.products)
                      DropdownMenuItem(value: p, child: Text(p))
                  ],
                  onChanged: (v) => setState(() => _gift = v))
            else
              TextField(
                  controller: _value,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Porcentaje (1 a 100)', hintText: 'Ej. 10')),
            const SizedBox(height: 12),
            TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Código (opcional)',
                    hintText: 'Ej. VECINOS10',
                    helperText:
                        'Sin código, solo lo ven quienes ya te compraron.')),
            const SizedBox(height: 12),
            TextField(
                controller: _min,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Compra mínima en pesos (opcional)',
                    hintText: 'Ej. 100')),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
                initialValue: _days,
                decoration: const InputDecoration(labelText: 'Dura'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 día')),
                  DropdownMenuItem(value: 7, child: Text('7 días')),
                  DropdownMenuItem(value: 30, child: Text('30 días')),
                ],
                onChanged: (v) => setState(() => _days = v!)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                  liveRegion: true,
                  child: Text(_error!,
                      style: const TextStyle(
                          color: BarrioColors.rojo,
                          fontWeight: FontWeight.w700))),
            ],
            const SizedBox(height: 16),
            AppButton(
                label: _busy ? 'Creando…' : 'Crear código',
                onPressed: _busy ? null : _save),
          ])));
}
