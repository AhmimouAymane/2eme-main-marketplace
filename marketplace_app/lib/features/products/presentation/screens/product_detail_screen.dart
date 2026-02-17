import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/utils/formatters.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/models/address_model.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/shared/models/order_model.dart';
import 'package:marketplace_app/shared/models/product_model.dart';

/// Écran de détail d'un produit
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(productDetailProvider(widget.productId))
        .when(
          data: (product) => _buildContent(context, product),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Erreur: $error')),
          ),
        );
  }

  Widget _buildContent(BuildContext context, ProductModel product) {
    final images = product.fullImageUrls;
    final currentUserIdAsync = ref.watch(userIdProvider);
    final currentUserId = currentUserIdAsync.maybeWhen(
      data: (id) => id,
      orElse: () => null,
    );
    final isOwner = currentUserId != null && currentUserId == product.sellerId;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec images
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.isEmpty ? 1 : images.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        color: Colors.grey[200],
                        child: images.isEmpty
                            ? Icon(
                                Icons.image_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              )
                            : Image.network(images[index], fit: BoxFit.cover),
                      );
                    },
                  ),
                  // Indicateur de page
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix et titre
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.price(product.price),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: Icon(
                          product.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product.isFavorite ? AppColors.error : null,
                        ),
                        onPressed: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .toggleFavorite(product);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Informations produit
                  _buildInfoRow(
                    'Marque',
                    product.brand.isEmpty ? 'Non spécifiée' : product.brand,
                  ),
                  _buildInfoRow(
                    'Taille',
                    product.size.isEmpty ? 'Non spécifiée' : product.size,
                  ),
                  _buildInfoRow('État', product.condition.name.toUpperCase()),
                  _buildInfoRow('Catégorie', product.category.toUpperCase()),
                  const SizedBox(height: 16),

                  // Vendeur
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(product.sellerName ?? 'Vendeur anonyme'),
                      subtitle: Text(
                        'Membre depuis ${Formatters.date(product.createdAt)}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push('/seller/${product.sellerId}');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 80), // Espace pour le bouton fixe
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (!isOwner)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () async {
                      try {
                        final dio = ref.read(dioProvider);
                        final response = await dio.post(
                          '/conversations/product/${product.id}',
                        );

                        if (!mounted) return;

                        final conversationId = response.data['id'] as String?;
                        if (conversationId == null || conversationId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Erreur lors de l\'ouverture de la conversation',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        context.push('/chat/$conversationId');
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Impossible d\'ouvrir la messagerie: $e',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.message_outlined),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: product.isAvailable
                      ? () => _showPurchaseDialog(context, product)
                      : null,
                  child: Text(product.isAvailable ? 'Acheter' : 'Vendu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, ProductModel product) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _CheckoutDialog(
        product: product,
        onConfirm: (shippingAddress) => _createOrderAfterCheckout(
          context,
          dialogContext,
          product,
          shippingAddress,
        ),
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  Future<void> _createOrderAfterCheckout(
    BuildContext context,
    BuildContext dialogContext,
    ProductModel product,
    String shippingAddress,
  ) async {
    Navigator.pop(dialogContext);
    try {
      await ref
          .read(ordersServiceProvider)
          .createOrder(
            OrderModel(
              id: '',
              productId: product.id,
              buyerId: '',
              sellerId: product.sellerId,
              totalPrice: product.price,
              status: OrderStatus.pending,
              shippingAddress: shippingAddress.trim(),
              createdAt: DateTime.now(),
              updatedAt: null,
              deliveredAt: null,
            ),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande créée. Paiement à la livraison.'),
        ),
      );
      ref.invalidate(productsProvider);
      ref.invalidate(productDetailProvider(product.id));
    } catch (e) {
      if (!context.mounted) return;
      final message = e is DioException && (e.response?.data is Map)
          ? (e.response!.data as Map)['message']?.toString() ?? e.toString()
          : e.toString();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $message')));
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Dialog de checkout : paiement à la livraison + adresse de livraison
class _CheckoutDialog extends ConsumerStatefulWidget {
  final ProductModel product;
  final void Function(String shippingAddress) onConfirm;
  final VoidCallback onCancel;

  const _CheckoutDialog({
    required this.product,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  ConsumerState<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<_CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  AddressModel? _selectedAddress;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return AlertDialog(
      title: const Text('Paiement à la livraison'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.price(product.price),
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.amber.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vous réglerez en espèces à la livraison.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // address selector
              Builder(
                builder: (ctx) {
                  final userAsync = ref.watch(userIdProvider);
                  return userAsync.when(
                    data: (userId) {
                      if (userId == null) {
                        return const Text('Utilisateur non connecté');
                      }
                      return ref
                          .watch(userAddressesProvider(userId))
                          .when(
                            data: (addrs) {
                              if (addrs.isEmpty) {
                                return Column(
                                  children: [
                                    const Text(
                                      'Aucune adresse trouvée. Ajoutez-en une dans votre profil.',
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          context.push(AppRoutes.addresses),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Gérer mes adresses'),
                                    ),
                                  ],
                                );
                              }
                              // set default selection on first build
                              if (_selectedAddress == null) {
                                _selectedAddress = addrs.firstWhere(
                                  (a) => a.isDefault,
                                  orElse: () => addrs.first,
                                );
                              }
                              return DropdownButtonFormField<AddressModel>(
                                value: _selectedAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Adresse de livraison *',
                                  border: OutlineInputBorder(),
                                ),
                                items: addrs
                                    .map(
                                      (a) => DropdownMenuItem(
                                        value: a,
                                        child: Text(a.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (a) =>
                                    setState(() => _selectedAddress = a),
                                validator: (v) =>
                                    v == null ? 'Sélectionnez une adresse' : null,
                              );
                            },
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('Erreur: $e'),
                          );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Erreur: $e'),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone (optionnel)',
                  hintText: 'Pour le livreur',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final addressText = _selectedAddress != null
                  ? '${_selectedAddress!.street}, ${_selectedAddress!.postal} ${_selectedAddress!.city}'
                  : '';
              final phone = _phoneController.text.trim();
              var payload = addressText;
              if (phone.isNotEmpty) {
                payload = '$payload — Tél: $phone';
              }
              widget.onConfirm(payload);
            }
          },
          child: const Text('Confirmer la commande'),
        ),
      ],
    );
  }
}
