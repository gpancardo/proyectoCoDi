import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n.dart';
import '../../services/barrio_api.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/money.dart';
import '../shared/app_button.dart';
import '../shared/barrio_surface.dart';

/// Pesos del campo de precio; null si no sirve. El total lo sigue calculando la API.
double? parsePrecio(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value == null || value <= 0 || value > 100000 ? null : value;
}

/// Lista de productos con su precio. Sirve en el alta y en el menú del negocio.
class ProductsEditor extends StatelessWidget {
  const ProductsEditor(
      {super.key, required this.products, required this.onChanged});
  final List<Map<String, dynamic>> products;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  Future<void> _edit(BuildContext context, int? index) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BarrioColors.crema,
      builder: (_) => _ProductSheet(
        product: index == null ? null : products[index],
        takenNames: [
          for (var i = 0; i < products.length; i++)
            if (i != index) products[i]['nombre'].toString().toLowerCase()
        ],
      ),
    );
    if (result == null) return;
    final next = [...products];
    if (result == false) {
      next.removeAt(index!);
    } else if (index == null) {
      next.add(result as Map<String, dynamic>);
    } else {
      next[index] = result as Map<String, dynamic>;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < products.length; i++)
            InkWell(
              onTap: () => _edit(context, i),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: BarrioColors.marino, width: 2))),
                child: Row(children: [
                  Expanded(
                      child: Text(products[i]['nombre'].toString(),
                          style: const TextStyle(
                              fontSize: 17, color: BarrioColors.tinta))),
                  Text(
                      formatMoney(
                          ((products[i]['precio'] as num) * 100).round()),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: BarrioColors.marino)),
                ]),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
              onPressed:
                  products.length >= 60 ? null : () => _edit(context, null),
              child: const Text('Agregar producto')),
        ],
      );
}

class _ProductSheet extends StatefulWidget {
  const _ProductSheet({required this.product, required this.takenNames});
  final Map<String, dynamic>? product;
  final List<String> takenNames;
  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  late final _name =
      TextEditingController(text: widget.product?['nombre']?.toString());
  late final _price =
      TextEditingController(text: widget.product?['precio']?.toString());
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final price = parsePrecio(_price.text);
    final error = name.isEmpty || name.length > 60
        ? 'Escribe el nombre del producto.'
        : widget.takenNames.contains(name.toLowerCase())
            ? 'Ya tienes un producto con ese nombre.'
            : price == null
                ? 'Escribe un precio mayor a 0.'
                : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, <String, dynamic>{'nombre': name, 'precio': price});
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 20, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  widget.product == null ? 'Nuevo producto' : 'Editar producto',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: BarrioColors.marino)),
              const SizedBox(height: 16),
              TextField(
                  controller: _name,
                  autofocus: widget.product == null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: 'Nombre',
                      hintText: 'Ej. Cuaderno profesional')),
              const SizedBox(height: 12),
              TextField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Precio en pesos', hintText: 'Ej. 38')),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                    liveRegion: true,
                    child: Text(_error!,
                        style: const TextStyle(
                            color: BarrioColors.rojo,
                            fontWeight: FontWeight.w700))),
              ],
              const SizedBox(height: 16),
              AppButton(label: 'Guardar producto', onPressed: _save),
              if (widget.product != null)
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Quitar del menú')),
            ],
          ),
        ),
      );
}

/// Alta del negocio en una sola pantalla; al guardar queda activo.
class BusinessSetup extends StatefulWidget {
  const BusinessSetup({super.key, required this.onCreated});
  final VoidCallback onCreated;
  @override
  State<BusinessSetup> createState() => _BusinessSetupState();
}

class _BusinessSetupState extends State<BusinessSetup> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  late final _phone =
      TextEditingController(text: context.read<AppState>().phone);
  late final _neighborhood =
      TextEditingController(text: context.read<AppState>().neighborhood);
  late String? _zone =
      I18n.alcaldiasCdmx.contains(context.read<AppState>().zone)
          ? context.read<AppState>().zone
          : null;
  String? _category;
  List<Map<String, dynamic>> _products = const [];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _neighborhood.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _form.currentState!.validate();
    if (!valid) return;
    if (_products.isEmpty) {
      setState(() => _error = 'Agrega al menos un producto con su precio.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<BarrioApi>().post(
          '/businesses',
          {
            'nombre': _name.text.trim(),
            'telefono': _phone.text.trim(),
            'zona': _zone,
            'colonia': _neighborhood.text.trim(),
            'direccion': _address.text.trim(),
            'categoria': _category,
            'productos': _products,
          },
          token: context.read<AppState>().accessToken);
      if (mounted) widget.onCreated();
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = mensajeDe(error);
        });
      }
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Completa este dato.' : null;

  @override
  Widget build(BuildContext context) => Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const Text('Registra tu negocio',
                style: TextStyle(
                    fontSize: 30,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: BarrioColors.marino)),
            const SizedBox(height: 6),
            const Text('Con esto ya puedes recibir pedidos.',
                style: TextStyle(fontSize: 16, color: BarrioColors.gris)),
            const SizedBox(height: 20),
            TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Nombre del negocio',
                    hintText: 'Ej. Papelería Miranda'),
                validator: (v) => (v ?? '').trim().length < 2
                    ? 'Escribe el nombre de tu negocio.'
                    : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Tipo de negocio'),
                items: [
                  for (final giro in I18n.giros)
                    DropdownMenuItem(value: giro, child: Text(giro))
                ],
                validator: _required,
                onChanged: (v) => setState(() => _category = v)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                value: _zone,
                decoration: const InputDecoration(labelText: 'Alcaldía'),
                items: [
                  for (final zona in I18n.alcaldiasCdmx)
                    DropdownMenuItem(value: zona, child: Text(zona))
                ],
                validator: _required,
                onChanged: (v) => setState(() => _zone = v)),
            const SizedBox(height: 12),
            TextFormField(
                controller: _neighborhood,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Colonia', hintText: 'Ej. Narvarte'),
                validator: _required),
            const SizedBox(height: 12),
            TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Dirección donde te recogen',
                    hintText: 'Ej. Av. Universidad 340'),
                validator: (v) => (v ?? '').trim().length < 5
                    ? 'Escribe calle y número.'
                    : null),
            const SizedBox(height: 12),
            TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                    labelText: 'Celular del negocio', hintText: '10 dígitos'),
                validator: (v) => RegExp(r'^\d{10}$').hasMatch((v ?? '').trim())
                    ? null
                    : 'Escribe 10 dígitos, sin +52.'),
            const SizedBox(height: 16),
            const Text('Tu menú',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BarrioColors.marino)),
            const SizedBox(height: 4),
            ProductsEditor(
                products: _products,
                onChanged: (next) => setState(() => _products = next)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Semantics(
                  liveRegion: true,
                  child: Text(_error!,
                      style: const TextStyle(
                          color: BarrioColors.rojo,
                          fontWeight: FontWeight.w700))),
            ],
            const SizedBox(height: 16),
            AppButton(
                label: _saving ? 'Registrando…' : 'Registrar mi negocio',
                onPressed: _saving ? null : _save),
          ],
        ),
      );
}
