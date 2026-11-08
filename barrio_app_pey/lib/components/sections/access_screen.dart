import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../shared/app_button.dart';
import '../shared/barrio_surface.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});
  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _newAccount = false, _busy = false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final api = context.read<BarrioApi>();
      final data = _newAccount
          ? await api.signUp(
              _email.text.trim(), _password.text, _name.text.trim())
          : await api.signIn(_email.text.trim(), _password.text);
      final token = data['access_token']?.toString();
      final refresh = data['refresh_token']?.toString();
      if (token == null || refresh == null) {
        throw const BarrioApiException(
            'Revisa tu correo y confirma tu cuenta antes de entrar.');
      }
      if (!mounted) {
        return;
      }
      await context.read<AppState>().saveSession(token, refresh);
    } on BarrioApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: BarrioBackdrop(
          child: SafeArea(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            const SizedBox(height: 36),
                            const BarrioMark(size: 64),
                            const SizedBox(height: 24),
                            Text(
                                _newAccount
                                    ? 'Crea tu cuenta'
                                    : 'Entra a Barrio',
                                style:
                                    Theme.of(context).textTheme.headlineMedium),
                            const SizedBox(height: 8),
                            const Text(
                                'Con la misma cuenta puedes pedir y atender tu negocio.',
                                style: TextStyle(color: BarrioColors.gris)),
                            const SizedBox(height: 24),
                            BarrioPanel(
                                child: Form(
                                    key: _form,
                                    child: Column(children: [
                                      if (_newAccount)
                                        TextFormField(
                                            controller: _name,
                                            decoration: const InputDecoration(
                                                labelText: 'Tu nombre'),
                                            validator: (v) =>
                                                (v ?? '').trim().isEmpty
                                                    ? 'Escribe tu nombre.'
                                                    : null),
                                      if (_newAccount)
                                        const SizedBox(height: 16),
                                      TextFormField(
                                          controller: _email,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: const InputDecoration(
                                              labelText: 'Correo'),
                                          validator: (v) => (v ?? '')
                                                  .contains('@')
                                              ? null
                                              : 'Escribe un correo válido.'),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                          controller: _password,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                              labelText: 'Contraseña',
                                              helperText:
                                                  'Mínimo 8 caracteres.'),
                                          validator: (v) => (v ?? '').length >=
                                                  8
                                              ? null
                                              : 'Usa al menos 8 caracteres.'),
                                      const SizedBox(height: 24),
                                      AppButton(
                                          label: _busy
                                              ? 'Entrando…'
                                              : (_newAccount
                                                  ? 'Crear cuenta'
                                                  : 'Entrar'),
                                          onPressed: _busy ? null : _submit),
                                      TextButton(
                                          onPressed: _busy
                                              ? null
                                              : () => setState(() =>
                                                  _newAccount = !_newAccount),
                                          child: Text(_newAccount
                                              ? 'Ya tengo cuenta'
                                              : 'No tengo cuenta')),
                                    ]))),
                          ]))))));
}
