import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';

/// Écran permettant à l'utilisateur de voir et gérer ses adresses
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes adresses')),
      body: _buildBody(context, ref),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final userAsync = ref.watch(userIdProvider);
          final addressesAsync = userAsync.maybeWhen(
            data: (userId) => userId != null ? ref.watch(userAddressesProvider(userId)) : null,
            orElse: () => null,
          );

          final count = addressesAsync?.maybeWhen(
            data: (addrs) => addrs.length,
            orElse: () => 0,
          ) ?? 0;

          return FloatingActionButton(
            backgroundColor: count >= 5 ? Colors.grey : null,
            onPressed: count >= 5
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vous ne pouvez pas ajouter plus de 5 adresses.'),
                      ),
                    );
                  }
                : () => context.push(AppRoutes.addressForm, extra: null),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userIdProvider);
    return userAsync.when(
      data: (userId) {
        if (userId == null) {
          return const Center(child: Text('Utilisateur non connecté'));
        }
        return ref
            .watch(userAddressesProvider(userId))
            .when(
              data: (addresses) {
                if (addresses.isEmpty) {
                  return Center(
                    child: Text(
                      'Vous n\'avez aucune adresse enregistrée.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final addr = addresses[idx];
                    return ListTile(
                      title: Text(addr.label),
                      subtitle: Text('${addr.street}, ${addr.city}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (addr.isDefault)
                            const Icon(Icons.check, color: Colors.green),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              context.push(AppRoutes.addressForm, extra: addr);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Supprimer l\'adresse ?'),
                                  content: const Text(
                                      'Voulez-vous vraiment supprimer cette adresse ?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Annuler'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Supprimer',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await ref
                                    .read(addressesServiceProvider)
                                    .deleteAddress(userId, addr.id);
                                ref.invalidate(userAddressesProvider(userId));
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        // set as default when tapped
                        await ref
                            .read(addressesServiceProvider)
                            .setDefaultAddress(userId, addr.id);
                        ref.invalidate(userAddressesProvider(userId));
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
    );
  }
}
