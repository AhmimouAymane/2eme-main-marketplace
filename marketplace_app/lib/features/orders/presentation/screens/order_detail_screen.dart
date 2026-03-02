import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/shop_providers.dart';
import '../../../../shared/models/order_model.dart';
import '../../../../shared/models/address_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import '../../../profile/data/user_reviews_service.dart';


/// Écran de détail d'une commande
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    final userIdAsync = ref.watch(userIdProvider);

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
        data: (order) => userIdAsync.when(
          data: (userId) => _buildContent(context, ref, order, userId),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _buildContent(context, ref, order, null),
        ),
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

  Widget _buildContent(BuildContext context, WidgetRef ref, OrderModel order, String? currentUserId) {
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
                if (order.returnReason != null)
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
                          const Icon(Icons.assignment_return_outlined, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Motif du retour',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.returnReason!,
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
                if (order.cancellationReason != null)
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
                          const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Motif de l\'annulation',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.cancellationReason!,
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
                _buildStatusStep(
                  'Offre faite',
                  order.status != OrderStatus.awaitingSellerConfirmation && 
                  order.status != OrderStatus.offerMade,
                  order.status == OrderStatus.offerMade ? order.createdAt : null,
                ),
                _buildStatusStep(
                  'Confirmé',
                  order.confirmedAt != null,
                  order.confirmedAt,
                ),
                _buildStatusStep(
                  'Expédié',
                  order.shippedAt != null,
                  order.shippedAt,
                ),
                _buildStatusStep(
                  'Livré',
                  order.deliveredAt != null,
                  order.deliveredAt,
                ),
                if (order.status == OrderStatus.returnWindow48h)
                  _buildStatusStep('Période de retour (48h)', true, order.deliveredAt),
                if (order.status == OrderStatus.returnRequested)
                  _buildStatusStep('Retour demandé', true, order.returnRequestedAt),
                if (order.status == OrderStatus.returned)
                  _buildStatusStep('Retourné', true, order.returnedAt),
                if (order.status == OrderStatus.completed)
                  _buildStatusStep('Terminé', true, order.completedAt),
                if (order.status == OrderStatus.cancelled)
                  _buildStatusStep(
                    'Annulé', 
                    true, 
                    order.updatedAt,
                  ),
              ],
            ),
          ),
        ),
        if (order.isDelivered)
          _buildReturnWindowInfo(order, isSeller),
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
        // Actions basees sur le role et le statut
        if (isSeller)
          _buildSellerActions(context, ref, order, currentUserId)
        else
          _buildBuyerActions(context, ref, order, currentUserId),
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

  Widget _buildReturnWindowInfo(OrderModel order, bool isSeller) {
    if (order.deliveredAt == null) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final difference = now.difference(order.deliveredAt!);
    final remaining = const Duration(hours: 48) - difference;
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final timeStr = h > 0 ? '${h}h ${m}m' : '${m}min';
    final isExpired = remaining.isNegative;

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
                    ? (isSeller 
                        ? 'Le délai de 48h est expiré. La commande va être clôturée.' 
                        : 'Le délai de retour de 48h est expiré.')
                    : (isSeller
                        ? 'Il reste $timeStr avant la validation automatique de la vente.'
                        : 'Il vous reste $timeStr pour demander un retour.'),
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
    String? currentUserId,
  ) {
    AddressModel? selectedAddress;
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final parentMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Confirmer la commande',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Summary (Card)
                _buildDialogSection(
                  context,
                  'Produit à confirmer',
                  Row(
                    children: [
                      if (order.product?.fullMainImageUrl != null)
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(order.product!.fullMainImageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.product?.title ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              Formatters.price(order.totalPrice),
                              style: TextStyle(color: AppColors.cloviGreen, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Address Section
                _buildDialogSection(
                  context,
                  'Lieu de ramassage',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Indiquez où le livreur récupérera le colis :',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, child) {
                          return ref.watch(userAddressesProvider(order.sellerId)).when(
                                data: (addresses) {
                                  if (addresses.isEmpty) {
                                    return Column(
                                      children: [
                                        const Text(
                                          'Aucune adresse enregistrée.',
                                          style: TextStyle(color: AppColors.error, fontSize: 12),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => context.push(AppRoutes.addresses),
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Gérer mes adresses'),
                                        ),
                                      ],
                                    );
                                  }

                                  selectedAddress ??= addresses.firstWhere(
                                    (a) => a.isDefault,
                                    orElse: () => addresses.first,
                                  );
                                  
                                  // Pre-fill phone if available and current length is 0
                                  if (selectedAddress?.phone != null && phoneController.text.isEmpty) {
                                    phoneController.text = selectedAddress!.phone!;
                                  }

                                  return DropdownButtonFormField<AddressModel>(
                                    value: selectedAddress,
                                    decoration: InputDecoration(
                                      labelText: 'Adresse de collecte',
                                      prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: addresses
                                        .map((a) => DropdownMenuItem(
                                              value: a,
                                              child: Text(a.label, style: const TextStyle(fontSize: 14)),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      selectedAddress = val;
                                      if (val?.phone != null) {
                                        phoneController.text = val!.phone!;
                                      }
                                    },
                                    validator: (val) => val == null ? 'Requis' : null,
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (e, _) => Text('Erreur: $e'),
                              );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: 'Téléphone de contact',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Requis pour le livreur'
                            : (val.length < 10 ? 'Numéro invalide' : null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          Consumer(
            builder: (consumerContext, consumerRef, child) {
              final addressesAsync = consumerRef.watch(userAddressesProvider(order.sellerId));
              final ordersService = consumerRef.read(ordersServiceProvider);
              return ElevatedButton(
                onPressed: addressesAsync.maybeWhen(
                  data: (addrs) => addrs.isEmpty
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          if (selectedAddress == null) return;

                          final phone = phoneController.text.trim();
                          final addressStr =
                              '${selectedAddress!.street}, ${selectedAddress!.postal} ${selectedAddress!.city} — Tél: $phone';

                          Navigator.pop(dialogContext);
                          try {
                            await ordersService.updateOrderStatus(
                              order.id,
                              OrderStatus.confirmed,
                              pickupAddress: addressStr,
                            );
                            ref.invalidate(orderDetailProvider(order.id));
                            ref.invalidate(productsProvider);
                            ref.invalidate(homeProductsProvider);
                            parentMessenger.showSnackBar(
                              const SnackBar(content: Text('Commande confirmée !')),
                            );
                          } catch (e) {
                            parentMessenger.showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                        },
                  orElse: () => null,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cloviGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirmer'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDialogSection(BuildContext context, String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
    String? currentUserId,
  ) {
    final reasonController = TextEditingController();
    // Capture the parent scaffold messenger BEFORE opening the dialog
    final parentMessenger = ScaffoldMessenger.of(context);
    final ordersService = ref.read(ordersServiceProvider);
    final isSeller = order.sellerId == currentUserId;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(order.status == OrderStatus.offerMade
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                parentMessenger.showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir une raison')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              try {
                print('[REJECT] Sending rejection: orderId=${order.id}, isSeller=$isSeller, reason=$reason');
                await ordersService.updateOrderStatus(
                      order.id,
                      OrderStatus.cancelled,
                      rejectionReason: isSeller ? reason : null,
                      cancellationReason: !isSeller ? reason : null,
                    );
                print('[REJECT] Success!');
                ref.invalidate(orderDetailProvider(order.id));
                ref.invalidate(productsProvider);
                ref.invalidate(homeProductsProvider);
                parentMessenger.showSnackBar(
                  const SnackBar(content: Text('Offre rejetée avec succès')),
                );
              } catch (e) {
                print('[REJECT] Error: $e');
                parentMessenger.showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
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
    String? currentUserId,
  ) {
    final reasonController = TextEditingController();
    final parentMessenger = ScaffoldMessenger.of(context);
    final ordersService = ref.read(ordersServiceProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                parentMessenger.showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir une raison')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              try {
                await ordersService.updateOrderStatus(
                      order.id,
                      OrderStatus.cancelled,
                      cancellationReason: reason,
                    );
                ref.invalidate(orderDetailProvider(order.id));
                ref.invalidate(productsProvider);
                ref.invalidate(homeProductsProvider);
                parentMessenger.showSnackBar(
                  const SnackBar(content: Text('Commande annulée')),
                );
              } catch (e) {
                print('[CANCEL] Error: $e');
                parentMessenger.showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
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
    final parentMessenger = ScaffoldMessenger.of(context);
    final ordersService = ref.read(ordersServiceProvider);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                parentMessenger.showSnackBar(
                  const SnackBar(content: Text('Veuillez saisir un motif')),
                );
                return;
              }

              Navigator.pop(dialogContext);
              try {
                await ordersService.updateOrderStatus(
                      order.id,
                      OrderStatus.returnRequested,
                      returnReason: reason,
                    );
                ref.invalidate(orderDetailProvider(order.id));
                parentMessenger.showSnackBar(
                  const SnackBar(content: Text('Demande de retour envoyée')),
                );
              } catch (e) {
                print('[RETURN] Error: $e');
                parentMessenger.showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
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

  Widget _buildSellerActions(BuildContext context, WidgetRef ref, OrderModel order, String? currentUserId) {
    if (order.status == OrderStatus.offerMade || 
        order.status == OrderStatus.awaitingSellerConfirmation) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _showConfirmDialog(context, ref, order, currentUserId),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.cloviGreen,
              ),
              child: Text(
                order.status == OrderStatus.offerMade
                    ? 'Accepter l\'offre'
                    : 'Confirmer la commande',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showRejectDialog(context, ref, order, currentUserId),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: Text(
                order.status == OrderStatus.offerMade
                    ? 'Rejeter l\'offre'
                    : 'Refuser la commande',
              ),
            ),
          ],
        ),
      );
    }

    if (order.status == OrderStatus.confirmed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton.icon(
          onPressed: () => _handleMarkAsShipped(context, ref, order),
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Marquer comme expédié'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.cloviGreen,
          ),
        ),
      );
    }

    if (order.status == OrderStatus.returnRequested) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _handleAcceptReturn(context, ref, order),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.cloviGreen,
          ),
          child: const Text('Confirmer la réception du retour'),
        ),
      );
    }

    if (order.status == OrderStatus.completed) {
      return _buildCompletedAction(context, ref, order, isBuyer: false);
    }

    return const SizedBox.shrink();
  }

  Widget _buildBuyerActions(BuildContext context, WidgetRef ref, OrderModel order, String? currentUserId) {
    if (order.canCancel) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          onPressed: () => _showCancelDialog(context, ref, order, currentUserId),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          child: const Text('Annuler la commande'),
        ),
      );
    }

    if (order.status == OrderStatus.shipped) {
      return _buildConfirmReceiptAction(context, ref, order);
    }

    if (order.status == OrderStatus.delivered || 
        order.status == OrderStatus.returnWindow48h) {
      return _buildReturnAction(context, ref, order);
    }

    if (order.status == OrderStatus.completed) {
      return _buildCompletedAction(context, ref, order, isBuyer: true);
    }

    return const SizedBox.shrink();
  }

  Future<void> _handleMarkAsShipped(BuildContext context, WidgetRef ref, OrderModel order) async {
    try {
      await ref.read(ordersServiceProvider).updateOrderStatus(
        order.id,
        OrderStatus.shipped,
      );
      ref.invalidate(orderDetailProvider(order.id));
      ref.invalidate(productsProvider);
      ref.invalidate(homeProductsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Colis marqué comme expédié !')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Widget _buildCompletedAction(BuildContext context, WidgetRef ref, OrderModel order, {required bool isBuyer}) {
    // Check if user already rated
    final myReviewAsync = ref.watch(FutureProvider.autoDispose((ref) {
      return ref.watch(userReviewsServiceProvider).getMyReviewForOrder(order.id);
    }));

    return myReviewAsync.when(
      data: (review) {
        if (review != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cloviGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   const Icon(Icons.check_circle, color: AppColors.cloviGreen),
                   const SizedBox(width: 12),
                   Text(
                     'Avis laissé (${review.rating}/5)',
                     style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.cloviGreen),
                   ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton.icon(
            onPressed: () => _showReviewDialog(context, ref, order, isBuyer: isBuyer),
            icon: const Icon(Icons.star_outline),
            label: Text(isBuyer ? 'Évaluer le vendeur' : 'Évaluer l\'acheteur'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.cloviGreen,
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref, OrderModel order, {required bool isBuyer}) {
    int rating = 5;
    final commentController = TextEditingController();
    final userReviewsService = ref.read(userReviewsServiceProvider);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isBuyer ? 'Évaluer le vendeur' : 'Évaluer l\'acheteur',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBuyer 
                  ? 'Comment s\'est déroulée votre expérience avec ${order.seller?.firstName ?? 'le vendeur'} ?'
                  : 'Comment s\'est déroulée votre expérience avec ${order.buyer?.firstName ?? 'l\'acheteur'} ?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Laissez un commentaire sur la transaction...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                Navigator.pop(context);
                
                try {
                  await userReviewsService.createReview(
                    orderId: order.id,
                    rating: rating,
                    comment: comment.isEmpty ? null : comment,
                  );
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Merci pour votre avis !'),
                        backgroundColor: AppColors.cloviGreen,
                      ),
                    );
                    // Refresh view
                    ref.invalidate(orderDetailProvider(order.id));
                    ref.invalidate(sellerProfileProvider(order.sellerId));
                    ref.invalidate(topSellersProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cloviGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAcceptReturn(BuildContext context, WidgetRef ref, OrderModel order) async {
    try {
      await ref.read(ordersServiceProvider).updateOrderStatus(
            order.id,
            OrderStatus.returned,
          );
      ref.invalidate(orderDetailProvider(order.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retour réceptionné. Le produit est à nouveau disponible.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}
