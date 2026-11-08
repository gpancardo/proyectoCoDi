import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../i18n.dart';
import '../../apis/models/api_models.dart';
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
  final _speech = SpeechToText();
  bool _loading = false;
  bool _listening = false;
  bool _speechReady = false;
  String _localeId = 'es_MX';
  String? _voiceNote;
  String? _answer;
  List<BusinessApiModel> _businesses = const [];

  @override
  void dispose() {
    _speech.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _voiceNote = null;
    });
    try {
      final response = await context.read<BarrioApi>().searchAgent(
          query: query,
          zone: context.read<AppState>().zone,
          token: context.read<AppState>().accessToken);
      if (!mounted) return;
      setState(() {
        _answer = response.meta?.answer ??
            (response.data.isEmpty
                ? 'No encontré algo abierto con eso. Prueba con otra palabra.'
                : 'Esto encontré cerca de ti.');
        _businesses = response.data;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _answer = mensajeDe(error);
        _businesses = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _say(String message) {
    if (mounted) setState(() => _voiceNote = message);
  }

  /// speech_to_text avisa de los fallos con un código; cada uno tiene salida.
  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() => _listening = false);
    switch (error.errorMsg) {
      case 'error_permission':
        _speechReady = false;
        _say('Sin permiso para el micrófono. Actívalo en los ajustes del '
            'teléfono o escribe tu búsqueda.');
      case 'error_no_match':
      case 'error_speech_timeout':
        _say('No te escuché bien, ¿me lo escribes?');
      case 'error_network':
      case 'error_network_timeout':
        _say('Sin señal para entenderte. Escribe tu búsqueda.');
      default:
        _say('No pude escucharte. Revisa el micrófono o escribe tu búsqueda.');
    }
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            setState(() => _listening = false);
          }
        },
        onError: _onSpeechError,
      );
      if (_speechReady) {
        // Español de México si el teléfono lo tiene; si no, otro español.
        final locales = await _speech.locales();
        final ids = locales.map((l) => l.localeId.replaceAll('-', '_'));
        _localeId = ids.contains('es_MX')
            ? 'es_MX'
            : ids.firstWhere((id) => id.startsWith('es'), orElse: () => '');
      }
    }
    if (!_speechReady) {
      _say('Activa el micrófono y el reconocimiento de voz para dictar, '
          'o escribe tu búsqueda.');
      return;
    }
    _query.clear();
    setState(() {
      _voiceNote = null;
      _listening = true;
    });
    await _speech.listen(
      onResult: _onSpeech,
      listenOptions: SpeechListenOptions(
        localeId: _localeId.isEmpty ? null : _localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
      ),
    );
  }

  void _onSpeech(SpeechRecognitionResult result) {
    _query.value = _query.value.copyWith(
        text: result.recognizedWords,
        selection:
            TextSelection.collapsed(offset: result.recognizedWords.length));
    if (!result.finalResult) return;
    setState(() => _listening = false);
    if (result.recognizedWords.trim().isEmpty) {
      _say('No te escuché bien, ¿me lo escribes?');
    } else {
      _search(); // al terminar el dictado, la búsqueda sale sola
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
                      'Lo que buscas está a la vuelta.',
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
                                label: 'Una papelería abierta',
                                onTap: _searchWith),
                          ],
                        ),
                      ),
                    ],
                    if (_answer != null) ...[
                      const SizedBox(height: 24),
                      _MessageCard(text: _answer!),
                      for (final business in _businesses)
                        _BusinessCard(
                          business: business,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  BusinessScreen(businessId: business.id),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_listening || _voiceNote != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _listening ? 'Te escucho…' : _voiceNote!,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _listening
                                    ? BarrioColors.teal
                                    : BarrioColors.rojo),
                          ),
                        ),
                      ),
                    BarrioPanel(
                      padding: const EdgeInsets.all(9),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _query,
                              minLines: 1,
                              maxLines: 3,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _search(),
                              decoration: const InputDecoration(
                                hintText: I18n.chatHint,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ComposerButton(
                            icon: 'microphone',
                            color: _listening
                                ? BarrioColors.marino
                                : BarrioColors.mango,
                            label: _listening
                                ? 'Dejar de dictar'
                                : 'Dictar búsqueda',
                            selected: _listening,
                            onTap: _loading ? null : _toggleVoice,
                          ),
                          const SizedBox(width: 7),
                          _ComposerButton(
                            icon: _loading ? 'loading' : 'send',
                            color: BarrioColors.marino,
                            label: _loading ? 'Buscando' : 'Buscar',
                            onTap: _loading ? null : _search,
                          ),
                        ],
                      ),
                    ),
                  ],
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
  final BusinessApiModel business;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = business.nombre;
    final category = business.categoria;
    final neighborhood = business.colonia ?? '';
    final reasons = business.matchReasons.take(3).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: BarrioPanel(
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
                      Text(title,
                          style: const TextStyle(
                              color: BarrioColors.marino,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                          [category, neighborhood]
                              .where((part) => part.isNotEmpty)
                              .join(' · '),
                          style: const TextStyle(color: BarrioColors.gris)),
                      if (reasons.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(reasons,
                            style: const TextStyle(
                                color: BarrioColors.teal,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ],
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
    this.selected = false,
  });
  final String icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        toggled: selected ? true : null,
        enabled: onTap != null,
        label: label,
        child: Material(
          color: color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: BarrioColors.marino, width: 2)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: SizedBox.square(
              dimension: 52,
              child: BarrioIcon(asset: icon, size: 25),
            ),
          ),
        ),
      );
}
