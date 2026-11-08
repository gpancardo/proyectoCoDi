import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../i18n.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../shared/app_button.dart';
import '../shared/barrio_surface.dart';
import '../shared/profile_form_fields.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _neighborhood = TextEditingController();
  String? _zone;
  String? _photoPath;
  bool _saving = false;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _neighborhood.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AppState>().saveProfile(
          name: _name.text,
          phone: _phone.text,
          zone: _zone!,
          neighborhood: _neighborhood.text,
          photoPath: _photoPath ?? '',
        );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickPhoto() async {
    final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (photo != null && mounted) setState(() => _photoPath = photo.path);
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Completa este dato.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BarrioBackdrop(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                const Row(
                  children: [
                    BarrioMark(size: 48),
                    SizedBox(width: 12),
                    Text('Barrio',
                        style: TextStyle(
                            color: BarrioColors.marino,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.5)),
                  ],
                ),
                const SizedBox(height: 26),
                const Text('Lo bueno empieza cerca',
                    style: TextStyle(
                        color: BarrioColors.marino,
                        fontSize: 29,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7)),
                const SizedBox(height: 8),
                const Text(
                  'Cuéntanos por dónde andas y te acercamos a lo de tu barrio.',
                  style: TextStyle(color: BarrioColors.gris, fontSize: 16),
                ),
                const SizedBox(height: 22),
                BarrioGlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: InkWell(
                          onTap: _pickPhoto,
                          borderRadius: BorderRadius.circular(56),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: BarrioColors.niebla,
                                backgroundImage: _photoPath == null
                                    ? null
                                    : FileImage(File(_photoPath!)),
                                child: _photoPath == null
                                    ? const Icon(Icons.add_a_photo_outlined,
                                        size: 28, color: BarrioColors.marino)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              const Text('Agrega tu foto (opcional)',
                                  style: TextStyle(
                                      color: BarrioColors.marino,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ProfileFormFields.text(
                          field: ProfileField.name,
                          controller: _name,
                          validator: _required),
                      const SizedBox(height: 16),
                      ProfileFormFields.text(
                        field: ProfileField.phone,
                        controller: _phone,
                        validator: (value) =>
                            value != null && RegExp(r'^\d{10}$').hasMatch(value)
                                ? null
                                : 'Escribe 10 dígitos.',
                      ),
                      const SizedBox(height: 16),
                      ProfileFormFields.zone(
                        value: _zone,
                        options: I18n.alcaldiasCdmx,
                        onChanged: (value) => setState(() => _zone = value),
                      ),
                      const SizedBox(height: 16),
                      ProfileFormFields.text(
                          field: ProfileField.neighborhood,
                          controller: _neighborhood,
                          validator: _required),
                      const SizedBox(height: 12),
                      const Text(
                        'Alcaldía y colonia nos ayudan a buscar por aquí cerca.',
                        style:
                            TextStyle(color: BarrioColors.gris, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                    label: I18n.continueLabel,
                    onPressed: _saving ? null : _continue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
