import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../i18n.dart';
import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../shared/app_button.dart';
import '../shared/barrio_icon.dart';
import '../shared/barrio_surface.dart';
import '../shared/profile_form_fields.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _neighborhood = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _zone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>();
    _name.text = profile.name;
    _phone.text = profile.phone;
    _zone = I18n.alcaldiasCdmx.contains(profile.zone) ? profile.zone : null;
    _neighborhood.text = profile.neighborhood;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _neighborhood.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Completa este dato.' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final profile = context.read<AppState>();
    try {
      await context.read<BarrioApi>().post(
          '/me',
          {
            'nombre': _name.text.trim(),
            'telefono': _phone.text.trim(),
            'zona': _zone,
            'colonia': _neighborhood.text.trim(),
          },
          token: profile.accessToken);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeDe(error))));
      }
      return;
    }
    await profile.updateProfile(
      name: _name.text,
      phone: _phone.text,
      zone: _zone!,
      neighborhood: _neighborhood.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listo, guardamos tus cambios.')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _changePhoto() async {
    final photo = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;
    await context.read<AppState>().updatePhoto(photo.path);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>();
    final photoPath = profile.photoPath;
    final hasPhoto = photoPath.isNotEmpty && File(photoPath).existsSync();

    return Scaffold(
      body: BarrioBackdrop(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Regresar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back,
                          color: BarrioColors.marino),
                    ),
                    const SizedBox(width: 14),
                    Text('Tu perfil',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                const SizedBox(height: 22),
                BarrioPanel(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _changePhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 43,
                              backgroundColor: BarrioColors.niebla,
                              backgroundImage:
                                  hasPhoto ? FileImage(File(photoPath)) : null,
                              child: hasPhoto
                                  ? null
                                  : Text(
                                      profile.name.isEmpty
                                          ? 'B'
                                          : profile.name
                                              .substring(0, 1)
                                              .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: BarrioColors.marino,
                                      ),
                                    ),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: BarrioColors.mango,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: BarrioColors.crema, width: 2),
                              ),
                              child:
                                  const BarrioIcon(asset: 'camera', size: 17),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Tu espacio en Barrio',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      const Text(
                        'Mantén tus datos al día para encontrar lo que queda cerca.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: BarrioColors.gris),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                BarrioPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeading(
                        eyebrow: 'TUS DATOS',
                        title: '¿Cómo te encontramos?',
                        icon: 'marketplace',
                      ),
                      const SizedBox(height: 20),
                      ProfileFormFields.text(
                        field: ProfileField.name,
                        controller: _name,
                        validator: _required,
                      ),
                      const SizedBox(height: 16),
                      ProfileFormFields.text(
                        field: ProfileField.phone,
                        controller: _phone,
                        validator: (value) =>
                            value != null && RegExp(r'^\d{10}$').hasMatch(value)
                                ? null
                                : 'Escribe 10 dígitos.',
                      ),
                      const SizedBox(height: 22),
                      const _SectionHeading(
                        eyebrow: 'TU DIRECCIÓN',
                        title: 'Tu zona de siempre',
                        icon: 'location',
                      ),
                      const SizedBox(height: 14),
                      ProfileFormFields.zone(
                        value: _zone,
                        options: I18n.alcaldiasCdmx,
                        onChanged: (value) => setState(() => _zone = value),
                      ),
                      const SizedBox(height: 16),
                      ProfileFormFields.text(
                        field: ProfileField.neighborhood,
                        controller: _neighborhood,
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Usamos alcaldía y colonia para acercarte negocios de tu zona.',
                        style:
                            TextStyle(fontSize: 14, color: BarrioColors.gris),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppButton(
                  label: _saving ? 'Guardando…' : 'Guardar cambios',
                  onPressed: _saving ? null : _save,
                  iconAsset: 'check',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Usamos estos datos solo para mostrarte opciones y enviarte tu cobro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: BarrioColors.gris),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(
      {required this.eyebrow, required this.title, required this.icon});
  final String eyebrow;
  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          BarrioIcon(asset: icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow,
                    style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        color: BarrioColors.gris)),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: BarrioColors.marino)),
              ],
            ),
          ),
        ],
      );
}
