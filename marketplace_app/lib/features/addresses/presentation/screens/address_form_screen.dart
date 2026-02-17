import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/shared/models/address_model.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final AddressModel? initial;
  const AddressFormScreen({super.key, this.initial});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _postalController;
  late TextEditingController _countryController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _labelController = TextEditingController(text: a?.label);
    _streetController = TextEditingController(text: a?.street);
    _cityController = TextEditingController(text: a?.city);
    _postalController = TextEditingController(text: a?.postal);
    _countryController = TextEditingController(text: a?.country);
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = await ref.read(userIdProvider.future);
    if (userId == null) return;

    AddressModel address = AddressModel(
      id: widget.initial?.id ?? '',
      label: _labelController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      postal: _postalController.text.trim(),
      country: _countryController.text.trim(),
      isDefault: _isDefault,
    );

    if (widget.initial == null) {
      await ref.read(addressesServiceProvider).createAddress(userId, address);
    } else {
      await ref.read(addressesServiceProvider).updateAddress(userId, address);
    }

    if (_isDefault) {
      await ref
          .read(addressesServiceProvider)
          .setDefaultAddress(userId, address.id);
    }

    ref.invalidate(userAddressesProvider(userId));
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'adresse' : 'Nouvelle adresse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _labelController,
                decoration: const InputDecoration(labelText: 'Étiquette'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Rue / Adresse'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Ville'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _postalController,
                decoration: const InputDecoration(labelText: 'Code postal'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Pays'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v ?? false),
                  ),
                  const Text('Définir comme adresse par défaut'),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? 'Enregistrer' : 'Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
