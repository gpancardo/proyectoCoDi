import 'package:flutter/material.dart';

enum ProfileField { name, phone, neighborhood }

extension ProfileFieldDetails on ProfileField {
  String get label => switch (this) {
        ProfileField.name => '¿Cómo te llamas?',
        ProfileField.phone => 'Tu celular',
        ProfileField.neighborhood => 'Colonia',
      };

  String get hint => switch (this) {
        ProfileField.name => 'Tu nombre',
        ProfileField.phone => '10 dígitos',
        ProfileField.neighborhood => 'Ej. Del Valle',
      };

  TextInputType get keyboard => switch (this) {
        ProfileField.phone => TextInputType.phone,
        _ => TextInputType.text,
      };

  int? get maxLength => switch (this) {
        ProfileField.phone => 10,
        _ => null,
      };
}

class ProfileFormFields {
  const ProfileFormFields._();

  static Widget text({
    required ProfileField field,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: field.keyboard,
        maxLength: field.maxLength,
        textCapitalization:
            field == ProfileField.name || field == ProfileField.neighborhood
                ? TextCapitalization.words
                : TextCapitalization.none,
        decoration:
            InputDecoration(labelText: field.label, hintText: field.hint),
        validator: validator,
      );

  static Widget zone({
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<String> options,
  }) =>
      DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(labelText: 'Alcaldía'),
        items: options
            .map((zone) => DropdownMenuItem(value: zone, child: Text(zone)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Elige tu alcaldía.' : null,
      );
}
