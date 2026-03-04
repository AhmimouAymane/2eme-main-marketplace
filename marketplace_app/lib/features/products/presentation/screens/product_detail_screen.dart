import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:marketplace_app/shared/providers/system_settings_provider.dart';
import 'package:marketplace_app/shared/models/system_settings_model.dart';
import 'package:marketplace_app/shared/widgets/full_screen_image_viewer.dart';

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
          error: (error, stack) {
            String errorMessage = 'Une erreur est survenue';
            bool is404 = false;

            if (error is DioException) {
              if (error.response?.statusCode == 404) {
                errorMessage = 'Cette annonce n\'est plus disponible (supprimée ou vendue).';
                is404 = true;
              } else {
                errorMessage = error.message ?? errorMessage;
              }
            } else {
              errorMessage = error.toString();
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Annonce indisponible'),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        is404 ? Icons.search_off : Icons.error_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Retour'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
                      return GestureDetector(
                        onTap: () {
                          if (images.isNotEmpty) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FullScreenImageViewer(
                                  imageUrls: images,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          color: Colors.grey[200],
                          child: images.isEmpty
                              ? Icon(
                                  Icons.image_outlined,
                                  size: 80,
                                  color: Colors.grey[400],
                                )
                              : Hero(
                                  tag: 'product_image_$index',
                                  child: Image.network(images[index],
                                      fit: BoxFit.cover),
                                ),
                        ),
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
                              color: AppColors.cloviGreen,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final isFavorite = ref.watch(isFavoriteProvider(product.id));
                          return IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? AppColors.error : null,
                            ),
                            onPressed: () {
                              ref
                                  .read(favoritesProvider.notifier)
                                  .toggleFavorite(product);
                            },
                          );
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
                   if (product.sellerCity != null)
                     _buildInfoRow('Ville', product.sellerCity!),
                   const SizedBox(height: 16),

                  // Vendeur
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.cloviGreen,
                        backgroundImage: product.sellerAvatarUrl != null && product.sellerAvatarUrl!.isNotEmpty
                            ? NetworkImage(product.sellerAvatarUrl!)
                            : null,
                        child: product.sellerAvatarUrl == null || product.sellerAvatarUrl!.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(product.sellerName ?? 'Vendeur anonyme'),
                       subtitle: Text(
                        'Membre depuis ${Formatters.date(product.createdAt)}${product.sellerCity != null ? ' • ${product.sellerCity}' : ''}',
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
                    product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Reviews section
                  _buildReviewsSection(product, isOwner),
                  const SizedBox(height: 24),

                  // Comments section
                  _buildCommentsSection(product, isOwner),
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
              if (!isOwner) ...[
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
                              backgroundColor: AppColors.error,
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
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.message_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: product.isAvailable
                        ? () => _showOfferDialog(context, product)
                        : null,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Faire une offre'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: product.isAvailable
                        ? () => _showPurchaseDialog(context, product)
                        : null,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(product.isAvailable ? 'Acheter' : 'Vendu'),
                    ),
                  ),
                ),
              ] else ...[
                if (product.isEditable)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.createProduct,
                        extra: product,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier mon annonce'),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Modification impossible (commande en cours)',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsSection(ProductModel product, bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avis (${product.reviews.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (!isOwner)
              TextButton(
                onPressed: () => _showAddReviewDialog(product),
                child: const Text('Donner mon avis'),
              ),
          ],
        ),
        if (product.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucun avis pour le moment',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: product.reviews.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final review = product.reviews[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.cloviGreen,
                          backgroundImage: review.user?.avatarUrl != null &&
                                  review.user!.avatarUrl!.isNotEmpty
                              ? NetworkImage(review.user!.avatarUrl!)
                              : null,
                          child: review.user?.avatarUrl == null ||
                                  review.user!.avatarUrl!.isEmpty
                              ? const Icon(Icons.person, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.user?.fullName ?? 'Utilisateur',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    Icons.star,
                                    size: 14,
                                    color: starIndex < review.rating
                                        ? Colors.amber
                                        : Colors.grey[300],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Formatters.date(review.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (review.comment != null && review.comment!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 36),
                        child: Text(
                          review.comment!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommentsSection(ProductModel product, bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Questions (${product.comments.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (!isOwner)
              TextButton(
                onPressed: () => _showAddCommentDialog(product),
                child: const Text('Poser une question'),
              ),
          ],
        ),
        if (product.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucune question pour le moment',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: product.comments.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final comment = product.comments[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.cloviGreen,
                          backgroundImage: comment.user?.avatarUrl != null &&
                                  comment.user!.avatarUrl!.isNotEmpty
                              ? NetworkImage(comment.user!.avatarUrl!)
                              : null,
                          child: comment.user?.avatarUrl == null ||
                                  comment.user!.avatarUrl!.isEmpty
                              ? const Icon(Icons.person, size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            comment.user?.fullName ?? 'Utilisateur',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          Formatters.relativeTime(comment.createdAt),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 32),
                      child: Text(comment.content, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddReviewDialog(ProductModel product) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Donner votre avis'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      Icons.star,
                      size: 32,
                      color: index < rating ? Colors.amber : Colors.grey[300],
                    ),
                    onPressed: () => setState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Votre commentaire (optionnel)',
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
                try {
                  await ref
                      .read(productsServiceProvider)
                      .addReview(
                        product.id,
                        rating,
                        commentController.text.trim(),
                      );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ref.invalidate(productDetailProvider(product.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Avis ajouté !')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCommentDialog(ProductModel product) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Poser une question'),
        content: TextField(
          controller: commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Écrivez votre question ici...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = commentController.text.trim();
              if (content.isEmpty) return;
              try {
                await ref
                    .read(productsServiceProvider)
                    .addComment(product.id, content);
                if (!mounted) return;
                Navigator.pop(context);
                ref.invalidate(productDetailProvider(product.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question envoyée !')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, ProductModel product) {
    showDialog<void>(
      context: context,
        builder: (dialogContext) => _CheckoutDialog(
        product: product,
        onConfirm: (shippingAddress, serviceFee, shippingFee, totalPrice) =>
            _createOrderAfterCheckout(
          context,
          dialogContext,
          product,
          shippingAddress,
          OrderStatus.awaitingSellerConfirmation,
          serviceFee: serviceFee,
          shippingFee: shippingFee,
          totalPrice: totalPrice,
        ),
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  void _showOfferDialog(BuildContext context, ProductModel product) {
    final offerController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Prix actuel : ${Formatters.price(product.price)}'),
            const SizedBox(height: 16),
            TextField(
              controller: offerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Votre offre (DH)',
                border: OutlineInputBorder(),
                prefixText: 'DH ',
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
            onPressed: () {
              final val = double.tryParse(offerController.text.trim());
              if (val == null || val <= 0) return;

              Navigator.pop(context);
              showDialog<void>(
                context: context,
                builder: (dialogContext) => _CheckoutDialog(
                  product: product.copyWith(price: val),
                  onConfirm:
                      (shippingAddress, serviceFee, shippingFee, totalPrice) =>
                          _createOrderAfterCheckout(
                    context,
                    dialogContext,
                    product.copyWith(price: val),
                    shippingAddress,
                    OrderStatus.offerMade,
                    serviceFee: serviceFee,
                    shippingFee: shippingFee,
                    totalPrice: totalPrice,
                  ),
                  onCancel: () => Navigator.pop(dialogContext),
                ),
              );
            },
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrderAfterCheckout(
    BuildContext context,
    BuildContext dialogContext,
    ProductModel product,
    String shippingAddress,
    OrderStatus status, {
    required double serviceFee,
    required double shippingFee,
    required double totalPrice,
  }) async {
    Navigator.pop(dialogContext);
    try {
      await ref.read(ordersServiceProvider).createOrder(
            OrderModel(
              id: '',
              productId: product.id,
              buyerId: '',
              sellerId: product.sellerId,
              totalPrice: totalPrice,
              serviceFee: serviceFee,
              shippingFee: shippingFee,
              status: status,
              shippingAddress: shippingAddress.trim(),
              createdAt: DateTime.now(),
              updatedAt: null,
              deliveredAt: null,
            ),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == OrderStatus.offerMade
                ? 'Offre envoyée au vendeur !'
                : 'Commande créée. Paiement à la livraison.',
          ),
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
  final void Function(
    String shippingAddress,
    double serviceFee,
    double shippingFee,
    double totalPrice,
  ) onConfirm;
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
    final userAsync = ref.watch(userIdProvider);


    return ref.watch(systemSettingsProvider).when(
      data: (settings) {
        final double serviceFee = (product.price * (settings.serviceFeePercentage / 100)).ceilToDouble();
        final double shippingFee = settings.shippingFee;
        final double totalPayable = product.price + serviceFee + shippingFee;

        return AlertDialog(
          title: const Text(
            'Vérifier votre commande',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Card
                  _buildSectionCard(
                    context,
                    'Résumé du paiement',
                    Column(
                      children: [
                        _buildSummaryRow('Prix du produit', product.price),
                        _buildSummaryRow(
                          'Frais de service (${settings.serviceFeePercentage.toStringAsFixed(1)}%)',
                          serviceFee,
                        ),
                        _buildSummaryRow('Frais de livraison', shippingFee),
                        const Divider(height: 20),
                        _buildSummaryRow('Total à payer', totalPayable, isBold: true),
                      ],
                    ),
                  ),

              const SizedBox(height: 16),

              // Address Section
              userAsync.when(
                data: (userId) {
                  if (userId == null) return const Text('Non connecté');
                  return ref.watch(userAddressesProvider(userId)).when(
                        data: (addrs) {
                          if (addrs.isEmpty) {
                            return _buildSectionCard(
                              context,
                              'Adresse de livraison',
                              Column(
                                children: [
                                  const Text(
                                    'Aucune adresse enregistrée.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => context.push(AppRoutes.addresses),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Ajouter une adresse'),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Auto-select once
                          if (_selectedAddress == null) {
                            _selectedAddress = addrs.firstWhere(
                              (a) => a.isDefault,
                              orElse: () => addrs.first,
                            );
                            if (_selectedAddress?.phone != null && _phoneController.text.isEmpty) {
                              _phoneController.text = _selectedAddress!.phone!;
                            }
                          }

                          return _buildSectionCard(
                            context,
                            'Adresse de livraison',
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Indiquez où le livreur livrera le colis :',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<AddressModel>(
                                        value: _selectedAddress,
                                        decoration: InputDecoration(
                                          labelText: 'Adresse de livraison',
                                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: addrs
                                            .map((a) => DropdownMenuItem(
                                                  value: a,
                                                  child: Text(a.label, style: const TextStyle(fontSize: 14)),
                                                ))
                                            .toList(),
                                        onChanged: (a) {
                                          setState(() {
                                            _selectedAddress = a;
                                            if (a?.phone != null) {
                                              _phoneController.text = a!.phone!;
                                            }
                                          });
                                        },
                                        validator: (a) => a == null ? 'Requis' : null,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => context.push(AppRoutes.addresses),
                                      icon: const Icon(Icons.add_circle_outline, color: AppColors.cloviGreen),
                                      tooltip: 'Ajouter une adresse',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Téléphone de contact',
                                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(10),
                                  ],
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Requis pour le livreur'
                                      : (v.length < 10 ? 'Numéro invalide' : null),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Erreur: $e'),
                      );
                },
                loading: () => const SizedBox(height: 100),
                error: (e, _) => Text('Erreur: $e'),
              ),
              
              const SizedBox(height: 16),
              
              // Payment info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Paiement à la livraison.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
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
          onPressed: widget.onCancel,
          child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: _selectedAddress == null
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final addressText =
                        '${_selectedAddress!.street}, ${_selectedAddress!.postal} ${_selectedAddress!.city}';
                    final phone = _phoneController.text.trim();
                    var payload = addressText;
                    if (phone.isNotEmpty) {
                      payload = '$payload — Tél: $phone';
                    }
                    widget.onConfirm(payload, serviceFee, shippingFee, totalPayable);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cloviGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Confirmer'),
        ),
      ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur settings: $e')),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.cloviGreen : Colors.grey[700],
            ),
          ),
          Text(
            Formatters.price(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.cloviGreen : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, Widget content) {
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
}
