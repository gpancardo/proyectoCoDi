import 'dart:io';

import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../services/openai_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';

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
      final result = await context.read<OpenAIService>().search(
            query,
            zone: context.read<AppState>().zone,
          );
      if (!mounted) return;
      setState(() {
        _answer = result.answer;
        _businesses = result.businesses;
      });
    } on Exception catch (exception) {
      if (!mounted) return;
      setState(() {
        _answer = exception is OpenAIServiceException
            ? exception.message
            : 'Sin señal. Revisa tu conexión e inténtalo de nuevo.';
        _businesses = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final name = appState.name;
    final photoPath = appState.photoPath;
    final hasPhoto = photoPath.isNotEmpty && File(photoPath).existsSync();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: BarrioColors.crema,
        title: const Text('Barrio', style: TextStyle(fontWeight: FontWeight.w800, color: BarrioColors.marino)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: BarrioColors.marino,
              foregroundColor: BarrioColors.crema,
              backgroundImage: hasPhoto ? FileImage(File(photoPath)) : null,
              child: hasPhoto ? null : Text(name.isEmpty ? 'B' : name.substring(0, 1).toUpperCase()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 16),
                  Text(I18n.chatGreeting, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Pregunta por comida y negocios cerca de ti.'),
                  if (_answer != null) ...[
                    const SizedBox(height: 28),
                    _MessageCard(text: _answer!),
                    for (final business in _businesses) _BusinessCard(business: business),
                  ],
                  if (_answer == null) ...[
                    const SizedBox(height: 28),
                    const _SuggestionChip(label: 'Se me antojan unos tacos'),
                    const SizedBox(height: 10),
                    const _SuggestionChip(label: '¿Qué hay abierto cerca?'),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _query,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(hintText: I18n.chatHint),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Dictar búsqueda',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(I18n.voiceNotReady)),
                    ),
                    style: IconButton.styleFrom(backgroundColor: BarrioColors.mango, foregroundColor: BarrioColors.marino, minimumSize: const Size(52, 52)),
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: 'Buscar',
                    onPressed: _loading ? null : _search,
                    style: IconButton.styleFrom(backgroundColor: BarrioColors.marino, foregroundColor: BarrioColors.blanco, minimumSize: const Size(52, 52)),
                    icon: _loading
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2, color: BarrioColors.blanco))
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: const Icon(Icons.search_rounded, size: 18),
        label: Text(label),
        onPressed: () {
          final state = context.findAncestorStateOfType<_ChatScreenState>();
          state?._query.text = label;
          state?._search();
        },
      );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
      );
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({required this.business});
  final Map<String, dynamic> business;

  @override
  Widget build(BuildContext context) {
    final title = business['nombre'] ?? business['name'] ?? 'Negocio cercano';
    final category = business['categoria'] ?? business['category'] ?? '';
    final neighborhood = business['colonia'] ?? '';
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: BarrioColors.niebla, child: Icon(Icons.storefront_rounded, color: BarrioColors.marino)),
        title: Text('$title', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text([category, neighborhood].where((part) => '$part'.isNotEmpty).join(' · ')),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
