import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/shop_providers.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/address_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Écran de détail d'une commande
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.cloviBeige,
      appBar: AppBar(
        title: const Text(
          'Détail de la commande',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          orderAsync.maybeWhen(
            data: (order) => IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => _navigateToChat(context, ref, order),
              tooltip: 'Contacter',
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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
              const SizedBox(height: 16),
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

  Future<void> _navigateToChat(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final conversation = await chatService.createOrGetOrderConversation(order.id);
      if (context.mounted) {
        context.push('/chat/${conversation.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ouverture du chat: $e')),
        );
      }
    }
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, OrderModel order) {
    final currentUserId = ref
        .watch(userIdProvider)
        .maybeWhen(data: (id) => id, orElse: () => null);
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
                    color: AppColors.cloviGreen,
                  ),
                ),
                const SizedBox(height: 20),
                if (order.rejectionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.status == OrderStatus.cancelled
                                      ? 'Motif de l\'annulation'
                                      : 'Motif du refus',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.rejectionReason!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildStatusStep('Commandé', true, order.createdAt),
                if (order.status == OrderStatus.offerPending)
                  _buildStatusStep('Offre en attente', true, order.createdAt),
                if (order.status == OrderStatus.offerRejected)
                  _buildStatusStep('Offre rejetée', true, order.updatedAt),
                _buildStatusStep(
                  'Confirmé',
                  order.status != OrderStatus.pending &&
                      order.status != OrderStatus.offerPending &&
                      order.status != OrderStatus.offerRejected &&
                      order.status != OrderStatus.cancelled,
                  (order.status != OrderStatus.pending &&
                          order.status != OrderStatus.offerPending)
                      ? (order.updatedAt ?? order.createdAt)
                      : null,
                ),
                _buildStatusStep(
                  'Expédié',
                  order.status == OrderStatus.shipped ||
                      order.status == OrderStatus.delivered,
                  order.status == OrderStatus.shipped ||
                          order.status == OrderStatus.delivered
                      ? (order.updatedAt)
                      : null,
                ),
                _buildStatusStep(
                  'Livré',
                  order.status == OrderStatus.delivered,
                  order.deliveredAt,
                ),
                if (order.status == OrderStatus.cancelled)
                  _buildStatusStep('Annulé', true, order.updatedAt),
                if (order.status == OrderStatus.returnRequested)
                  _buildStatusStep('Retour demandé', true, order.updatedAt),
              ],
            ),
          ),
        ),
        if (order.status == OrderStatus.delivered && !isSeller)
          _buildReturnWindowInfo(order),
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
                    color: AppColors.cloviGreen,
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
                                image: NetworkImage(
                                  order.product!.fullMainImageUrl,
                                ),
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
                            'Prix: ${Formatters.price(order.totalPrice)}',
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
                    color: AppColors.cloviGreen,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow('Prix du produit', order.totalPrice),
                _buildSummaryRow(
                  'Frais de service (inclus)',
                  0.0,
                ), // Pour l'instant on garde ça simple
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
                    color: AppColors.cloviGreen,
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
          _buildInfoCard(
            context,
            'Adresse de récupération (Vendeur)',
            [
              Text(
                order.pickupAddress!,
                style: const TextStyle(height: 1.5, fontSize: 14),
              ),
            ],
          ),
        const SizedBox(height: 24),

        // Contact Section
        _buildInfoCard(
          context,
          isSeller ? 'Acheteur' : 'Vendeur',
          [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.cloviGreen.withOpacity(0.1),
                  child: Icon(Icons.person, color: AppColors.cloviGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSeller
                            ? (order.buyer?.fullName ?? 'Acheteur')
                            : (order.seller?.fullName ?? 'Vendeur'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        isSeller ? 'Acheteur du produit' : 'Vendeur du produit',
                        style: TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _navigateToChat(context, ref, order),
                  icon: Icon(Icons.chat_bubble_outline, color: AppColors.cloviGreen),
                  tooltip: 'Discuter',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Actions
        if (isSeller &&
            (order.status == OrderStatus.pending ||
                order.status == OrderStatus.offerPending))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () => _showConfirmDialog(context, ref, order),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.cloviGreen,
                  ),
                  child: Text(
                    order.status == OrderStatus.offerPending
                        ? 'Accepter l\'offre'
                        : 'Confirmer la commande',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _showRejectDialog(context, ref, order),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: Text(
                    order.status == OrderStatus.offerPending
                        ? 'Rejeter l\'offre'
                        : 'Refuser la commande',
                  ),
                ),
              ],
            ),
          )
        else if (!isSeller && order.canCancel)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(context, ref, order),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Annuler la commande'),
            ),
          )
        else if (!isSeller && order.status == OrderStatus.shipped)
          _buildConfirmReceiptAction(context, ref, order)
        else if (!isSeller && order.status == OrderStatus.delivered)
          _buildReturnAction(context, ref, order),
      ],
    );
  }

  Widget _buildConfirmReceiptAction(BuildContext context, WidgetRef ref, OrderModel order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: () => _showConfirmReceiptDialog(context, ref, order),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Confirmer la réception'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.cloviGreen,
        ),
      ),
    );
  }

  void _showConfirmReceiptDialog(BuildContext context, WidgetRef ref, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la réception ?'),
        content: const Text(
          'En confirmant la réception, vous indiquez avoir bien reçu le colis. '
          'La commande passera en statut "Livré" et vous aurez 48h pour signaler un problème.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Pas encore'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(ordersServiceProvider).updateOrderStatus(
                      order.id,
                      OrderStatus.delivered,
                    );
                ref.invalidate(orderDetailProvider(order.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Réception confirmée !')),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cloviGreen),
            child: const Text('Oui, j\'ai reçu le colis'),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnWindowInfo(OrderModel order) {
    if (order.deliveredAt == null) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final difference = now.difference(order.deliveredAt!);
    final remainingHours = 48 - difference.inHours;
    final isExpired = remainingHours <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isExpired ? Colors.grey.shade100 : AppColors.cloviGreen.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpired ? Colors.grey.shade300 : AppColors.cloviGreen.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
              color: isExpired ? Colors.grey : AppColors.cloviGreen,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isExpired
                    ? 'Le délai de retour de 48h est expiré.'
                    : 'Il vous reste ${remainingHours.clamp(0, 48)} heures pour demander un retour.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isExpired ? Colors.grey : AppColors.cloviGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnAction(BuildContext context, WidgetRef ref, OrderModel order) {
    if (order.deliveredAt == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final difference = now.difference(order.deliveredAt!);
    if (difference.inHours >= 48) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: () => _showReturnDialog(context, ref, order),
        icon: const Icon(Icons.assignment_return_outlined),
        label: const Text('Demander un retour (48h)'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    AddressModel? selectedAddress;
    final phoneController = TextEditingController();
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
              const Text(
                'Veuillez indiquer l\'adresse où le livreur pourra récupérer le colis :',
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  return ref
                      .watch(userAddressesProvider(order.sellerId))
                      .when(
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
                            initialValue: selectedAddress,
                            decoration: const InputDecoration(
                              labelText: 'Adresse de collecte *',
                              border: OutlineInputBorder(),
                            ),
                            items: addresses
                                .map(
                                  (a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(a.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => selectedAddress = val,
                            validator: (val) => val == null
                                ? 'L\'adresse est obligatoire'
                                : null,
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Erreur: $e'),
                      );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone de contact *',
                  hintText: 'Pour coordonner la remise',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Le téléphone est obligatoire'
                    : null,
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

              final phone = phoneController.text.trim();
              final addressStr =
                  '${selectedAddress!.street}, ${selectedAddress!.postal} ${selectedAddress!.city} — Tél: $phone';

              Navigator.pop(context);
              try {
                await ref
                    .read(ordersServiceProvider)
                    .updateOrderStatus(
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(order.status == OrderStatus.offerPending
            ? 'Rejeter l\'offre ?'
            : 'Refuser la commande ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Veuillez indiquer la raison du refus pour informer l\'acheteur :',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex: Produit non disponible, prix trop bas...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir une raison')),
                );
                return;
              }

              Navigator.pop(context);
              try {
                final status = order.status == OrderStatus.offerPending
                    ? OrderStatus.offerRejected
                    : OrderStatus.cancelled;

                await ref.read(ordersServiceProvider).updateOrderStatus(
                      order.id,
                      status,
                      rejectionReason: reason,
                    );
                ref.invalidate(orderDetailProvider(order.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Action effectuée')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voulez-vous vraiment annuler cette commande ? Veuillez indiquer une raison :',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex: Changement d\'avis, erreur d\'adresse...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir une raison')),
                );
                return;
              }

              Navigator.pop(context);
              try {
                await ref.read(ordersServiceProvider).updateOrderStatus(
                      order.id,
                      OrderStatus.cancelled,
                      rejectionReason: reason,
                    );
                ref.invalidate(orderDetailProvider(order.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Commande annulée')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmer l\'annulation'),
          ),
        ],
      ),
    );
  }

  void _showReturnDialog(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander un retour (48h)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conformément à notre politique, vous avez 48h après la livraison pour signaler un problème.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Veuillez indiquer le motif de votre demande :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ex: Taille incorrecte, article non conforme...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir un motif')),
                );
                return;
              }

              Navigator.pop(context);
              try {
                await ref.read(ordersServiceProvider).updateOrderStatus(
                      order.id,
                      OrderStatus.returnRequested,
                      rejectionReason: reason,
                    );
                ref.invalidate(orderDetailProvider(order.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande de retour envoyée')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
              color: isCompleted ? AppColors.cloviGreen : Colors.grey[300],
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
                    fontWeight: isCompleted
                        ? FontWeight.w600
                        : FontWeight.normal,
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
              color: isBold ? AppColors.cloviGreen : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.cloviGreen,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
