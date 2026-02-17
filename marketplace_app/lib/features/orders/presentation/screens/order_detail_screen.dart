import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/shop_providers.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/address_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Écran de détail d'une commande
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la commande'),
      ),
      body: orderAsync.when(
        data: (order) => _buildContent(context, ref, order),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $err'),
              ElevatedButton(
                onPressed: () => ref.invalidate(orderDetailProvider(orderId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, OrderModel order) {
    final currentUserId = ref.watch(userIdProvider).maybeWhen(
      data: (id) => id,
      orElse: () => null,
    );
    final isSeller = currentUserId == order.sellerId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Statut de la commande
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statut',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildStatusStep('Commandé', true, order.createdAt),
                _buildStatusStep(
                  'Confirmé', 
                  order.status != OrderStatus.pending && order.status != OrderStatus.cancelled, 
                  order.status != OrderStatus.pending ? (order.updatedAt ?? order.createdAt) : null
                ),
                _buildStatusStep(
                  'Expédié', 
                  order.status == OrderStatus.shipped || order.status == OrderStatus.delivered, 
                  order.status == OrderStatus.shipped || order.status == OrderStatus.delivered ? (order.updatedAt) : null
                ),
                _buildStatusStep(
                  'Livré', 
                  order.status == OrderStatus.delivered, 
                  order.deliveredAt
                ),
                if (order.status == OrderStatus.cancelled)
                  _buildStatusStep('Annulé', true, order.updatedAt),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Produit
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produit',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        image: order.product?.mainImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(order.product!.fullMainImageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: order.product?.mainImageUrl == null
                          ? Icon(Icons.image_outlined, color: Colors.grey[400])
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.product?.title ?? 'Produit inconnu',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (order.product?.size != null)
                            Text(
                              'Taille: ${order.product!.size}',
                              style: TextStyle(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          Text(
                            'Prix: ${Formatters.price(order.product?.price ?? 0)}',
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Résumé
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Résumé',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Prix du produit', order.product?.price ?? order.totalPrice),
                _buildSummaryRow('Frais de service (inclus)', 0.0), // Pour l'instant on garde ça simple
                const Divider(height: 24),
                _buildSummaryRow('Total payé', order.totalPrice, isBold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Adresse de livraison
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adresse de livraison',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  order.shippingAddress ?? 'Aucune adresse renseignée',
                  style: const TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Adresse de récupération (Seller)
        if (order.pickupAddress != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adresse de récupération (Vendeur)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.pickupAddress!,
                    style: const TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 32),

        // Actions
        if (isSeller && order.status == OrderStatus.pending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () => _showConfirmDialog(context, ref, order),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.success,
              ),
              child: const Text('Confirmer la commande'),
            ),
          ),
      ],
    );
  }

  void _showConfirmDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    AddressModel? selectedAddress;
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la commande'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Veuillez indiquer l\'adresse où le livreur pourra récupérer le colis :'),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  return ref.watch(userAddressesProvider(order.sellerId)).when(
                    data: (addresses) {
                      if (addresses.isEmpty) {
                        return const Text(
                          'Aucune adresse enregistrée. Veuillez en ajouter une dans votre profil.',
                          style: TextStyle(color: AppColors.error),
                        );
                      }
                      
                      selectedAddress ??= addresses.firstWhere(
                        (a) => a.isDefault,
                        orElse: () => addresses.first,
                      );

                      return DropdownButtonFormField<AddressModel>(
                        value: selectedAddress,
                        decoration: const InputDecoration(
                          labelText: 'Adresse de collecte *',
                          border: OutlineInputBorder(),
                        ),
                        items: addresses.map((a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.label),
                        )).toList(),
                        onChanged: (val) => selectedAddress = val,
                        validator: (val) => val == null ? 'L\'adresse est obligatoire' : null,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Erreur: $e'),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              
              final addressStr = '${selectedAddress!.street}, ${selectedAddress!.postal} ${selectedAddress!.city}';
              
              Navigator.pop(context);
              try {
                await ref.read(ordersServiceProvider).updateOrderStatus(
                  order.id, 
                  OrderStatus.confirmed,
                  pickupAddress: addressStr,
                );
                ref.invalidate(orderDetailProvider(order.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Commande confirmée')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String label, bool isCompleted, DateTime? date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? AppColors.success : Colors.grey[300],
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (date != null)
                  Text(
                    Formatters.dateTime(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            Formatters.price(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              color: isBold ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
