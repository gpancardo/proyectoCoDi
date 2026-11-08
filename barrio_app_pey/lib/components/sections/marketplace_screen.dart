import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../shared/barrio_surface.dart';
import 'business_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  List<Map<String, dynamic>> _sections = const [];
  String _query = '';
  bool _loading = true;
  String? _problem;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _problem = null;
    });
    try {
      // con sesión, la API ordena según tus compras y promociones
      final data = await context
          .read<BarrioApi>()
          .get('/discovery', token: context.read<AppState>().accessToken);
      if (!mounted) return;
      setState(() {
        _sections =
            ((data as Map<String, dynamic>)['sections'] as List<dynamic>? ??
                    const [])
                .whereType<Map<String, dynamic>>()
                .toList();
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _problem = mensajeDe(error);
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> section) => (section[
              'items'] as List<dynamic>? ??
          const [])
      .whereType<Map<String, dynamic>>()
      .where((business) =>
          _query.isEmpty ||
          '${business['nombre']} ${business['categoria']} ${business['productos']}'
              .toLowerCase()
              .contains(_query))
      .toList();
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: BarrioColors.crema,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: BarrioColors.marino))
          : _problem != null
              ? BarrioProblema(message: _problem!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                      const Text('Descubrir',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: BarrioColors.marino)),
                      const SizedBox(height: 4),
                      const Text('Negocios abiertos para resolver hoy.',
                          style: TextStyle(color: BarrioColors.gris)),
                      const SizedBox(height: 16),
                      TextField(
                          onChanged: (value) =>
                              setState(() => _query = value.toLowerCase()),
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Busca tacos, pan, farmacia…')),
                      const SizedBox(height: 20),
                      if (_sections.every((s) => _items(s).isEmpty))
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                                'Por ahora no hay negocios abiertos con eso. Prueba otra palabra.',
                                style: TextStyle(
                                    fontSize: 17, color: BarrioColors.tinta))),
                      for (final section in _sections)
                        if (_items(section).isNotEmpty) ...[
                          Text(section['title'].toString(),
                              style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  color: BarrioColors.marino)),
                          const SizedBox(height: 10),
                          SizedBox(
                              height: 210,
                              child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _items(section).length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (_, index) => _BusinessTile(
                                      business: _items(section)[index]))),
                          const SizedBox(height: 28)
                        ],
                    ]));
}

class _BusinessTile extends StatelessWidget {
  const _BusinessTile({required this.business});
  final Map<String, dynamic> business;
  @override
  Widget build(BuildContext c) {
    final products = business['productos'] as List<dynamic>? ?? const [];
    final from = products.isEmpty
        ? ''
        : 'Desde ${formatMoney((products.map((p) => p['precio'] as num).reduce((a, b) => a < b ? a : b) * 100).round())}';
    return SizedBox(
        width: 244,
        child: InkWell(
            onTap: () => Navigator.push(
                c,
                MaterialPageRoute(
                    builder: (_) => BusinessScreen(
                        businessId: (business['id'] as num).toInt()))),
            borderRadius: BorderRadius.circular(6),
            child: BarrioPanel(
                padding: EdgeInsets.zero,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BarrioToldo(),
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(business['nombre'].toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: BarrioColors.marino)),
                                    const SizedBox(height: 6),
                                    Text(
                                        '${business['categoria']} · ${business['colonia']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: BarrioColors.gris)),
                                    const Spacer(),
                                    Text(from,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: BarrioColors.marino))
                                  ])))
                    ]))));
  }
}
