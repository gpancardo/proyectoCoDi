import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../shared/app_button.dart';
import '../shared/barrio_surface.dart';
import 'seller_setup.dart';

/// Gestión deliberadamente corta: el negocio solo ve lo que puede resolver ya.
class SellerScreen extends StatefulWidget {
  const SellerScreen({super.key});
  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  bool _loading = true;
  bool _needsSetup = false;
  String? _message;
  Map<String, dynamic>? _business;
  List<dynamic> _orders = const [];
  List<dynamic> _coupons = const [];
  Map<String, dynamic>? _dashboard;
  final _busy = <int>{};
  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _load();
    // ponytail: sondeo cada 8 s aunque la pestaña no se vea; push cuando haya avisos reales.
    _poller = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_business != null) _load(quiet: true);
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  String? get _token => context.read<AppState>().accessToken;

  Future<void> _load({bool quiet = false}) async {
    final token = _token;
    if (token == null) return;
    try {
      final api = context.read<BarrioApi>();
      final me = await api.get('/me', token: token) as Map<String, dynamic>;
      final business = me['negocio'] as Map<String, dynamic>?;
      if (business == null) {
        if (mounted) {
          setState(() {
            _needsSetup = true;
            _loading = false;
            _message = null;
          });
        }
        return;
      }
      final orders = await api.get('/orders', token: token) as List<dynamic>;
      final coupons =
          await api.get('/business/coupons', token: token) as List<dynamic>;
      Map<String, dynamic>? dashboard;
      try {
        dashboard = await api.get('/business/dashboard', token: token)
            as Map<String, dynamic>;
      } catch (_) {/* el panel se queda con el dato anterior */}
      if (mounted) {
        setState(() {
          _needsSetup = false;
          _dashboard = dashboard ?? _dashboard;
          _business = business;
          _orders = orders;
          _coupons = coupons;
          _message = null;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && !quiet) {
        setState(() {
          _loading = false;
          _message = mensajeDe(error);
        });
      }
    }
  }

  void _aviso(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _attempt(Future<void> Function() work) async {
    try {
      await work();
      await _load(quiet: true);
    } catch (error) {
      if (mounted) _aviso(mensajeDe(error));
    }
  }

  Future<void> _action(int id, String action) async {
    if (!_busy.add(id)) return;
    setState(() {});
    await _attempt(() async {
      await context
          .read<BarrioApi>()
          .post('/orders/$id/$action', {}, token: _token);
    });
    if (mounted) setState(() => _busy.remove(id));
  }

  Future<bool> _confirm(String title, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialog, false),
                child: const Text('Regresar')),
            TextButton(
                onPressed: () => Navigator.pop(dialog, true),
                child: Text(action)),
          ],
        ),
      ) ??
      false;

  Future<void> _reject(int id) async {
    if (await _confirm('¿Rechazar este pedido?', 'Rechazar pedido')) {
      await _action(id, 'reject');
    }
  }

  Future<void> _patch(Map<String, dynamic> change) => _attempt(() async {
        await context
            .read<BarrioApi>()
            .patch('/business', change, token: _token!);
      });

  Future<void> _removeCoupon(int id) async {
    if (!await _confirm('¿Quitar esta promoción?', 'Quitar promoción')) return;
    await _attempt(() async {
      await context
          .read<BarrioApi>()
          .delete('/business/coupons/$id', token: _token!);
    });
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
      _aviso('Listo. Tu promoción ya está activa.');
      await _load(quiet: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: BarrioBackdrop(
          child: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _message != null
                    ? BarrioProblema(
                        message: _message!,
                        onRetry: () {
                          setState(() => _loading = true);
                          _load();
                        })
                    : _needsSetup
                        ? BusinessSetup(onCreated: () {
                            setState(() => _loading = true);
                            _load();
                          })
                        : _panel(),
          ),
        ),
      );

  Widget _panel() {
    final business = _business!;
    final open = business['abierto'] == true;
    final pending = _orders.where((o) => o['estado'] == 'pendiente').length;
    final products = (business['productos'] as List<dynamic>? ?? const [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();
    return DefaultTabController(
      length: 4,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(business['nombre'].toString(),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BarrioColors.marino)),
            subtitle: Text(open ? 'Abierto: recibes pedidos' : 'Cerrado',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: open ? BarrioColors.teal : BarrioColors.gris)),
            value: open,
            onChanged: (value) => _patch({'abierto': value}),
          ),
        ),
        TabBar(
          labelPadding: EdgeInsets.zero,
          labelColor: BarrioColors.marino,
          unselectedLabelColor: BarrioColors.gris,
          indicatorColor: BarrioColors.marino,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Archivo'),
          tabs: [
            const Tab(text: 'Resumen'),
            Tab(text: pending > 0 ? 'Pedidos ($pending)' : 'Pedidos'),
            const Tab(text: 'Menú'),
            const Tab(text: 'Promos'),
          ],
        ),
        const Divider(height: 2, thickness: 2, color: BarrioColors.marino),
        Expanded(
          child: TabBarView(children: [
            RefreshIndicator(
              onRefresh: () => _load(quiet: true),
              child: _DashboardTab(data: _dashboard),
            ),
            RefreshIndicator(
              onRefresh: () => _load(quiet: true),
              child: _OrdersTab(
                  orders: _orders,
                  open: open,
                  busy: _busy,
                  onAction: _action,
                  onReject: _reject),
            ),
            ListView(padding: const EdgeInsets.all(16), children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aceptar pedidos en automático',
                    style: TextStyle(fontSize: 17, color: BarrioColors.tinta)),
                subtitle: const Text('El cobro sale sin que contestes.',
                    style: TextStyle(fontSize: 14, color: BarrioColors.gris)),
                value: business['auto_aceptar'] == true,
                onChanged: (value) => _patch({'auto_aceptar': value}),
              ),
              const SizedBox(height: 8),
              ProductsEditor(
                products: products,
                onChanged: (next) {
                  if (next.isEmpty) {
                    _aviso('Deja al menos un producto en tu menú.');
                    return;
                  }
                  _patch({'productos': next});
                },
              ),
            ]),
            _CouponsTab(
                coupons: _coupons,
                onCreate: _newCoupon,
                onRemove: _removeCoupon),
          ]),
        ),
      ]),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.data});
  final Map<String, dynamic>? data;

  static const _letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  static const _section = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w700, color: BarrioColors.marino);

  int _int(Object? value) => (value as num? ?? 0).toInt();

  @override
  Widget build(BuildContext context) {
    final d = data;
    if (d == null) {
      return ListView(padding: const EdgeInsets.all(24), children: const [
        Text(
            'Aún no podemos mostrar tu resumen. Desliza hacia abajo para intentar de nuevo.',
            style: TextStyle(fontSize: 17, color: BarrioColors.tinta)),
      ]);
    }
    final today = d['hoy'] as Map<String, dynamic>;
    final sold = _int(today['ventas_minor']);
    final count = _int(today['cobros']);
    final diff = sold - _int(d['ayer_minor']);
    final pending = d['por_atender'] as Map<String, dynamic>;
    final week = (d['semana'] as List<dynamic>).cast<Map<String, dynamic>>();
    final peak = week.fold<int>(
        1, (m, x) => x['ventas_minor'] > m ? _int(x['ventas_minor']) : m);
    final products =
        (d['productos'] as List<dynamic>).cast<Map<String, dynamic>>();
    final clients = d['clientes'] as Map<String, dynamic>;
    final month = d['mes'] as Map<String, dynamic>;
    final monthSold = _int(month['ventas_minor']);
    final tab = DefaultTabController.of(context);
    Widget stat(String label, Object? n) => Expanded(
          child: Semantics(
            button: true,
            child: InkWell(
              onTap: () => tab.animateTo(1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(children: [
                  Text('${_int(n)}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: BarrioColors.marino)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, color: BarrioColors.tinta)),
                ]),
              ),
            ),
          ),
        );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        const Text('Hoy vendiste',
            style: TextStyle(fontSize: 17, color: BarrioColors.tinta)),
        Text(formatMoney(sold),
            style: const TextStyle(
                fontSize: 56,
                height: 1.05,
                fontWeight: FontWeight.w800,
                color: BarrioColors.marino)),
        Text(
            count == 0
                ? 'Todavía sin cobros hoy.'
                : '${count == 1 ? '1 cobro' : '$count cobros'} · promedio ${formatMoney(_int(today['ticket_minor']))}',
            style: const TextStyle(fontSize: 16, color: BarrioColors.gris)),
        if (diff != 0)
          Text(
              '${formatMoney(diff.abs())} ${diff > 0 ? 'más' : 'menos'} que ayer',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: diff > 0 ? BarrioColors.teal : BarrioColors.gris)),
        const SizedBox(height: 16),
        const Divider(height: 2, thickness: 2, color: BarrioColors.marino),
        Row(children: [
          stat('Por responder', pending['responder']),
          stat('Por preparar', pending['preparar']),
          stat('Por recoger', pending['recoger']),
        ]),
        const Divider(height: 2, thickness: 2, color: BarrioColors.marino),
        const SizedBox(height: 20),
        const Text('Tus últimos 7 días', style: _section),
        const SizedBox(height: 12),
        Semantics(
          label: week
              .map(
                  (x) => '${x['dia']}: ${formatMoney(_int(x['ventas_minor']))}')
              .join(', '),
          child: ExcludeSemantics(
            child: SizedBox(
              height: 148,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < week.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 4 +
                                  112 * _int(week[i]['ventas_minor']) / peak,
                              decoration: BoxDecoration(
                                color: i == week.length - 1
                                    ? BarrioColors.mango
                                    : BarrioColors.marino,
                                border: i == week.length - 1
                                    ? Border.all(
                                        color: BarrioColors.marino, width: 2)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                                _letters[
                                    DateTime.parse(week[i]['dia'].toString())
                                            .weekday -
                                        1],
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: i == week.length - 1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: BarrioColors.tinta)),
                          ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        if (products.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Lo que más sale', style: _section),
          const SizedBox(height: 4),
          for (final item in products)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: BarrioColors.marino, width: 2))),
              child: Row(children: [
                Expanded(
                    child: Text(item['nombre'].toString(),
                        style: const TextStyle(
                            fontSize: 17, color: BarrioColors.tinta))),
                Text('${_int(item['cantidad'])}',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: BarrioColors.marino)),
              ]),
            ),
        ],
        const SizedBox(height: 24),
        const Text('Tus últimos 30 días', style: _section),
        const SizedBox(height: 6),
        Text(
            '${formatMoney(monthSold)} en ${_int(month['cobros'])} cobros, sin comisión.',
            style: const TextStyle(fontSize: 17, color: BarrioColors.tinta)),
        if (_int(clients['total']) > 0)
          Text(
              '${_int(clients['total'])} clientes, ${_int(clients['regresan'])} regresaron.',
              style: const TextStyle(fontSize: 17, color: BarrioColors.tinta)),
        if (_int(month['descuentos_minor']) > 0)
          Text(
              'Diste ${formatMoney(_int(month['descuentos_minor']))} en promociones.',
              style: const TextStyle(fontSize: 17, color: BarrioColors.tinta)),
        if (monthSold > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
                // ponytail: 3.5% es una comisión de ejemplo, solo para comparar; no toca ningún cobro.
                'Con una terminal al 3.5% habrías dejado ${formatMoney((monthSold * .035).round())}.',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BarrioColors.teal)),
          ),
      ],
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({
    required this.orders,
    required this.open,
    required this.busy,
    required this.onAction,
    required this.onReject,
  });
  final List<dynamic> orders;
  final bool open;
  final Set<int> busy;
  final Future<void> Function(int, String) onAction;
  final Future<void> Function(int) onReject;

  static const _groups = <(String, Set<String>, String?)>[
    (
      'Por responder',
      {'pendiente'},
      'Si no contestas en 8 minutos, se cancela.'
    ),
    ('Por preparar', {'pagada'}, null),
    ('Esperando el pago', {'aceptada', 'cobrada', 'vencida'}, null),
    ('Listos para recoger', {'lista'}, null),
    ('Anteriores', {'entregada', 'rechazada', 'expirada', 'cancelada'}, null),
  ];

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                  open
                      ? 'Cuando alguien te pida, aparece aquí.'
                      : 'Abre tu negocio para recibir pedidos.',
                  style:
                      const TextStyle(fontSize: 17, color: BarrioColors.tinta)),
            ),
          for (final (title, states, help) in _groups)
            if (orders.any((o) => states.contains(o['estado']))) ...[
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: BarrioColors.marino)),
              if (help != null)
                Text(help,
                    style: const TextStyle(
                        fontSize: 14, color: BarrioColors.gris)),
              for (final order
                  in orders.where((o) => states.contains(o['estado'])).take(10))
                _OrderRow(
                    order: order as Map<String, dynamic>,
                    busy: busy.contains(order['id']),
                    onAction: onAction,
                    onReject: onReject),
            ],
        ],
      );
}

const _estado = {
  'aceptada': 'Mandando el cobro',
  'cobrada': 'Cobro enviado a su banco',
  'pagada': 'Pagado. Prepáralo',
  'lista': 'Listo. Pide su código al entregar',
  'entregada': 'Entregado',
  'rechazada': 'Rechazado',
  'expirada': 'Sin respuesta a tiempo',
  'vencida': 'El cobro venció',
  'cancelada': 'Lo canceló el cliente',
};

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.busy,
    required this.onAction,
    required this.onReject,
  });
  final Map<String, dynamic> order;
  final bool busy;
  final Future<void> Function(int, String) onAction;
  final Future<void> Function(int) onReject;

  @override
  Widget build(BuildContext context) {
    final state = order['estado']?.toString() ?? '';
    final id = (order['id'] as num).toInt();
    final seals = (order['comprador_logros'] as List<dynamic>? ?? const [])
        .map((b) => b['nombre'])
        .join(' · ');
    final notes = order['notas']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: BarrioColors.marino, width: 2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: Text('Pedido $id',
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: BarrioColors.marino))),
          Text(formatMoney(order['total_minor'] ?? 0),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: BarrioColors.marino)),
        ]),
        if (_estado[state] != null)
          Text(_estado[state]!,
              style: const TextStyle(fontSize: 15, color: BarrioColors.gris)),
        const SizedBox(height: 6),
        for (final item in (order['items'] as List<dynamic>? ?? const []))
          Text('${item['cantidad']} × ${item['nombre']}',
              style: const TextStyle(fontSize: 17, color: BarrioColors.tinta)),
        if (notes.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Nota: $notes',
                  style: const TextStyle(color: BarrioColors.tinta))),
        if (seals.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Sellos de tu cliente: $seals',
                  style: const TextStyle(
                      color: BarrioColors.teal, fontWeight: FontWeight.w700))),
        if (state == 'pendiente') ...[
          const SizedBox(height: 12),
          AppButton(
              label: busy ? 'Un momento…' : 'Aceptar pedido',
              onPressed: busy ? null : () => onAction(id, 'accept')),
          TextButton(
              onPressed: busy ? null : () => onReject(id),
              child: const Text('Rechazar pedido')),
        ],
        if (state == 'pagada') ...[
          const SizedBox(height: 12),
          AppButton(
              label: busy ? 'Un momento…' : 'Marcar listo',
              onPressed: busy ? null : () => onAction(id, 'ready')),
        ],
      ]),
    );
  }
}

class _CouponsTab extends StatelessWidget {
  const _CouponsTab(
      {required this.coupons, required this.onCreate, required this.onRemove});
  final List<dynamic> coupons;
  final VoidCallback onCreate;
  final Future<void> Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final active = coupons
        .where((c) =>
            c['activo'] == true &&
            DateTime.parse(c['vence'].toString()).isAfter(DateTime.now()))
        .toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      AppButton(label: 'Crear promoción', onPressed: onCreate),
      const SizedBox(height: 16),
      if (active.isEmpty)
        const Text('Sin promociones activas.',
            style: TextStyle(fontSize: 17, color: BarrioColors.tinta)),
      for (final coupon in active)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: BarrioColors.marino, width: 2))),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coupon['titulo'].toString(),
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: BarrioColors.marino)),
                    Text(
                        coupon['codigo'] == null
                            ? 'Se aplica sola a quien ya te compró'
                            : 'Código ${coupon['codigo']}',
                        style: const TextStyle(color: BarrioColors.gris)),
                  ]),
            ),
            TextButton(
                onPressed: () => onRemove((coupon['id'] as num).toInt()),
                child: const Text('Quitar')),
          ]),
        ),
    ]);
  }
}

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
    final percent = int.tryParse(_value.text.trim()) ?? 0;
    final error = _title.text.trim().length < 3
        ? 'Escribe un título corto.'
        : _type == 'porcentaje' && (percent < 1 || percent > 100)
            ? 'Escribe un porcentaje de 1 a 100.'
            : _type == 'producto_gratis' && _gift == null
                ? 'Elige el producto que regalas.'
                : null;
    if (error != null) {
      setState(() => _error = error);
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
            'value': _type == 'porcentaje' ? percent : 1,
            if (_type == 'producto_gratis') 'free_product': _gift,
            if (_code.text.trim().isNotEmpty) 'code': _code.text.trim(),
            'min_amount_minor': (int.tryParse(_min.text.trim()) ?? 0) * 100,
            'expires_at': DateTime.now()
                .add(Duration(days: _days))
                .toUtc()
                .toIso8601String(),
          },
          token: context.read<AppState>().accessToken);
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
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Nueva promoción',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: BarrioColors.marino)),
            const SizedBox(height: 16),
            TextField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej. 10% en tu siguiente compra')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                value: _type,
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
                  value: _gift,
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
                        'Sin código, se aplica sola a quien ya te compró.')),
            const SizedBox(height: 12),
            TextField(
                controller: _min,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Compra mínima en pesos (opcional)',
                    hintText: 'Ej. 100')),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
                value: _days,
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
                label: _busy ? 'Creando…' : 'Crear promoción',
                onPressed: _busy ? null : _save),
          ])));
}
