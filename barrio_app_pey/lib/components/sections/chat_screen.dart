import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n.dart';
import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../shared/barrio_icon.dart';
import '../shared/barrio_surface.dart';
import 'profile_screen.dart';
import 'business_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _query = TextEditingController();
  bool _loading = false;
  String? _answer;
  List<Map<String, dynamic>> _businesses = const [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty || _loading) return;
    setState(() => _loading = true);
    try {
      final data = await context.read<BarrioApi>().post('/search/agent', {
        'query': query,
        'filters': {'zone': context.read<AppState>().zone},
      }, token: context.read<AppState>().accessToken);
      if (!mounted) return;
      setState(() {
        _answer = 'Estas opciones coinciden con lo que buscas.';
        _businesses = (data as List<dynamic>).whereType<Map<String, dynamic>>().toList();
      });
    } on Exception catch (exception) {
      if (!mounted) return;
      setState(() {
        _answer = exception is BarrioApiException
            ? exception.message
            : 'Sin señal. Revisa tu conexión e inténtalo de nuevo.';
        _businesses = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) => const ProfileScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>();
    final photoPath = profile.photoPath;
    final hasPhoto = photoPath.isNotEmpty && File(photoPath).existsSync();
    final location = [profile.neighborhood, profile.zone]
        .where((part) => part.isNotEmpty)
        .join(', ');

    return Scaffold(
      body: BarrioBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const BarrioMark(size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Barrio',
                              style: TextStyle(
                                  color: BarrioColors.marino,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5)),
                          Text(
                            location.isEmpty
                                ? 'Cerca de ti, lo bueno'
                                : location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: BarrioColors.gris, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Semantics(
                      button: true,
                      label: 'Abrir tu perfil',
                      child: GestureDetector(
                        key: const ValueKey('profileAction'),
                        onTap: _openProfile,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: BarrioColors.mango, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: BarrioColors.marino,
                            foregroundColor: BarrioColors.crema,
                            backgroundImage:
                                hasPhoto ? FileImage(File(photoPath)) : null,
                            child: hasPhoto
                                ? null
                                : Text(profile.name.isEmpty
                                    ? 'B'
                                    : profile.name
                                        .substring(0, 1)
                                        .toUpperCase()),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  children: [
                    const Text(I18n.chatGreeting,
                        style: TextStyle(
                            color: BarrioColors.marino,
                            fontSize: 27,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.6)),
                    const SizedBox(height: 8),
                    const Text(
                      'Lo rico y lo bueno están a la vuelta.',
                      style: TextStyle(color: BarrioColors.gris, fontSize: 16),
                    ),
                    if (_answer == null) ...[
                      const SizedBox(height: 24),
                      BarrioPanel(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                BarrioIcon(asset: 'sun', size: 21),
                                SizedBox(width: 8),
                                Text('¿Qué se te antoja?',
                                    style: TextStyle(
                                        color: BarrioColors.marino,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 17)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _SuggestionChip(
                                label: 'Unos tacos por aquí',
                                onTap: _searchWith),
                            const SizedBox(height: 8),
                            _SuggestionChip(
                                label: 'Algo abierto para desayunar',
                                onTap: _searchWith),
                          ],
                        ),
                      ),
                    ],
                    if (_answer != null) ...[
                      const SizedBox(height: 24),
                      _MessageCard(text: _answer!),
                      for (final business in _businesses)
                        _BusinessCard(business: business, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BusinessScreen(businessId: (business['id'] as num).toInt())))),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: BarrioPanel(
                  padding: const EdgeInsets.all(9),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _query,
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _search(),
                          decoration: const InputDecoration(
                            hintText: I18n.chatHint,
                            filled: true,
                            fillColor: BarrioColors.blanco,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                              borderSide: BorderSide(color: BarrioColors.borde),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                              borderSide: BorderSide(color: BarrioColors.borde),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                              borderSide: BorderSide(
                                  color: BarrioColors.marino, width: 1.6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ComposerButton(
                        icon: 'microphone',
                        color: BarrioColors.mango,
                        label: 'Dictar búsqueda',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(I18n.voiceNotReady)),
                        ),
                      ),
                      const SizedBox(width: 7),
                      _ComposerButton(
                        icon: _loading ? 'loading' : 'send',
                        color: BarrioColors.marino,
                        label: 'Buscar',
                        onTap: _loading ? null : _search,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _searchWith(String query) {
    _query.text = query;
    _search();
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => onTap(label),
        child: Ink(
          decoration: BoxDecoration(
            color: BarrioColors.crema.withOpacity(.75),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: BarrioColors.marino, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const BarrioIcon(asset: 'search', size: 20),
                const SizedBox(width: 9),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(color: BarrioColors.tinta))),
                const BarrioIcon(asset: 'chevron-right', size: 17),
              ],
            ),
          ),
        ),
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => BarrioPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BarrioMark(size: 38),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: BarrioColors.tinta, fontSize: 16, height: 1.4))),
          ],
        ),
      );
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business, required this.onTap});
  final Map<String, dynamic> business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = business['nombre'] ?? business['name'] ?? 'Negocio cercano';
    final category = business['categoria'] ?? business['category'] ?? '';
    final neighborhood = business['colonia'] ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6), child: BarrioPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: BarrioColors.crema,
                  borderRadius: BorderRadius.circular(6)),
              child: const BarrioIcon(asset: 'marketplace', size: 31),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$title',
                      style: const TextStyle(
                          color: BarrioColors.marino,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      [category, neighborhood]
                          .where((part) => '$part'.isNotEmpty)
                          .join(' · '),
                      style: const TextStyle(color: BarrioColors.gris)),
                ],
              ),
            ),
            const BarrioIcon(asset: 'chevron-right', size: 23),
          ],
        ),
      )),
    );
  }
}

class _ComposerButton extends StatelessWidget {
  const _ComposerButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final String icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 48,
              child: BarrioIcon(asset: icon, size: 25),
            ),
          ),
        ),
      );
}
