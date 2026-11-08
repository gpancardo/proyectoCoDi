import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../i18n.dart';
import '../../state/app_state.dart';
import '../shared/app_button.dart';
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
    final photo = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (photo != null && mounted) setState(() => _photoPath = photo.path);
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Completa este dato.' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              Center(
                child: InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(56),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundImage: _photoPath == null ? null : FileImage(File(_photoPath!)),
                        child: _photoPath == null ? const Icon(Icons.add_a_photo_outlined, size: 30) : null,
                      ),
                      const SizedBox(height: 8),
                      const Text('Agrega tu foto (opcional)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(I18n.onboardingTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(I18n.onboardingSubtitle, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 28),
              ProfileFormFields.text(field: ProfileField.name, controller: _name, validator: _required),
              const SizedBox(height: 16),
              ProfileFormFields.text(
                field: ProfileField.phone,
                controller: _phone,
                validator: (value) => value != null && RegExp(r'^\d{10}$').hasMatch(value)
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
              ProfileFormFields.text(field: ProfileField.neighborhood, controller: _neighborhood, validator: _required),
              const SizedBox(height: 12),
              Text('Tu zona nos ayuda a encontrar negocios cercanos.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              AppButton(label: I18n.continueLabel, onPressed: _saving ? null : _continue),
            ],
          ),
        ),
      ),
    );
  }
}
