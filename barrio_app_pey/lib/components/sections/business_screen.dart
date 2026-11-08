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
  const BusinessScreen({super.key, required this.businessId}); final int businessId;
  @override State<BusinessScreen> createState() => _BusinessScreenState();
}
class _BusinessScreenState extends State<BusinessScreen> {
  Map<String, dynamic>? _business; final Map<String, int> _quantities = {}; bool _loading = true, _sending = false;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final b = await context.read<BarrioApi>().get('/businesses/${widget.businessId}') as Map<String, dynamic>; if (mounted) setState(() { _business = b; _loading = false; }); } on BarrioApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); } }
  Future<void> _review() async {
    final token = context.read<AppState>().accessToken; final business = _business!;
    if (token == null) return;
    final items = _quantities.entries.where((x) => x.value > 0).map((x) => {'nombre': x.key, 'cantidad': x.value}).toList();
    if (items.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un producto.'))); return; }
    setState(() => _sending = true);
    try { final quote = await context.read<BarrioApi>().post('/orders/quotes', {'business_id': business['id'], 'items': items}, token: token) as Map<String, dynamic>;
      if (!mounted) return; await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (context) => _Ticket(quote: quote, onConfirm: () async {
        final order = await this.context.read<BarrioApi>().post('/orders', {'quote_id': quote['quote_id'], 'confirmed_total_minor': quote['total_minor']}, token: token, idempotencyKey: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(999999)}');
        if (context.mounted) Navigator.pop(context); if (mounted) Navigator.of(this.context).pushReplacement(MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: (order['id'] as num).toInt())));
      }));
    } on BarrioApiException catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message))); } finally { if (mounted) setState(() => _sending = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: BarrioBackdrop(child: SafeArea(child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(16), children: [
    Text(_business!['nombre'].toString(), style: Theme.of(context).textTheme.headlineMedium), Text('${_business!['categoria']} · ${_business!['direccion']}', style: const TextStyle(color: BarrioColors.gris)), const SizedBox(height: 20),
    const _Awning(),
    for (final p in (_business!['productos'] as List<dynamic>? ?? const [])) _ProductRow(product: p as Map<String, dynamic>, quantity: _quantities[p['nombre']] ?? 0, onChange: (delta) => setState(() => _quantities[p['nombre'].toString()] = max(0, (_quantities[p['nombre']] ?? 0) + delta))),
    const SizedBox(height: 20), AppButton(label: _sending ? 'Armando tu cuenta…' : 'Ver mi cuenta', onPressed: _sending ? null : _review),
  ]))));
}
class _Awning extends StatelessWidget { const _Awning(); @override Widget build(BuildContext c) => Container(height: 16, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BarrioColors.marino, width: 2)), gradient: LinearGradient(colors: [BarrioColors.mango, BarrioColors.mango, BarrioColors.blanco, BarrioColors.blanco], stops: [0,.5,.5,1]))); }
class _ProductRow extends StatelessWidget { const _ProductRow({required this.product, required this.quantity, required this.onChange}); final Map<String,dynamic> product; final int quantity; final ValueChanged<int> onChange; @override Widget build(BuildContext c) => Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: BarrioColors.marino, width: 2))), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product['nombre'].toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)), Text(formatMoney(((product['precio'] as num) * 100).round()), style: const TextStyle(color: BarrioColors.gris))])), IconButton(onPressed: () => onChange(-1), icon: const Icon(Icons.remove)), Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w700)), IconButton(onPressed: () => onChange(1), icon: const Icon(Icons.add))])); }
class _Ticket extends StatelessWidget { const _Ticket({required this.quote, required this.onConfirm}); final Map<String,dynamic> quote; final Future<void> Function() onConfirm; @override Widget build(BuildContext c) => SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: BarrioPanel(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Tu cuenta', style: TextStyle(fontSize: 24,fontWeight: FontWeight.w800,color: BarrioColors.marino)), const Divider(), for (final item in (quote['items'] as List<dynamic>? ?? const [])) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${item['cantidad']} × ${item['nombre']}  ${formatMoney((item['precio_minor'] as num) * (item['cantidad'] as num))}')), const Divider(), Text('Total ${formatMoney(quote['total_minor'])}', style: const TextStyle(fontSize: 26,fontWeight: FontWeight.w800,color: BarrioColors.marino)), const SizedBox(height: 8), const Text('Revisa los productos y el total antes de confirmar.', style: TextStyle(color: BarrioColors.gris)), const SizedBox(height: 16), AppButton(label: 'Confirmar pedido', onPressed: () => onConfirm())])))); }
