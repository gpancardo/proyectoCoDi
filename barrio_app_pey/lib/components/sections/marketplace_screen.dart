import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/barrio_api.dart';
import '../../theme.dart';
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
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<BarrioApi>().get('/discovery')
          as Map<String, dynamic>;
      if (mounted)
        setState(() {
          _sections = (data['sections'] as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .toList();
          _loading = false;
        });
    } on BarrioApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
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
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Busca tacos, pan, farmacia…')),
                  const SizedBox(height: 20),
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
        : 'Desde \$${(products.first['precio'] as num).toStringAsFixed(0)}';
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
                      const _Awning(),
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

class _Awning extends StatelessWidget {
  const _Awning();
  @override
  Widget build(BuildContext c) => Container(
      height: 16,
      decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: BarrioColors.marino, width: 2)),
          gradient: LinearGradient(colors: [
            BarrioColors.mango,
            BarrioColors.mango,
            BarrioColors.blanco,
            BarrioColors.blanco
          ], stops: [
            0,
            .5,
            .5,
            1
          ])));
}
