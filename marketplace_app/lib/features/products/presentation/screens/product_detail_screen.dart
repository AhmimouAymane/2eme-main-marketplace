import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/utils/formatters.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/shared/models/order_model.dart';
import 'package:marketplace_app/shared/models/product_model.dart';

/// Écran de détail d'un produit
class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return ref.watch(productDetailProvider(widget.productId)).when(
      data: (product) => _buildContent(context, product),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
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
                            : Image.network(
                                images[index],
                                fit: BoxFit.cover,
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
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: Icon(
                          product.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: product.isFavorite ? AppColors.error : null,
                        ),
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(product);
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
                  _buildInfoRow('Marque', product.brand.isEmpty ? 'Non spécifiée' : product.brand),
                  _buildInfoRow('Taille', product.size.isEmpty ? 'Non spécifiée' : product.size),
                  _buildInfoRow('État', product.condition.name.toUpperCase()),
                  _buildInfoRow('Catégorie', product.category.toUpperCase()),
                  const SizedBox(height: 16),

                  // Vendeur
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
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
                              content: Text('Erreur lors de l\'ouverture de la conversation'),
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
                            content: Text('Impossible d\'ouvrir la messagerie: $e'),
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
                  onPressed: product.isAvailable ? () => _showPurchaseDialog(context, product) : null,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'achat'),
        content: Text('Voulez-vous acheter "${product.title}" pour ${Formatters.price(product.price)} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Créer la commande
                await ref.read(ordersServiceProvider).createOrder(
                  OrderModel(
                    id: '', // Le backend générera l'ID
                    productId: product.id,
                    buyerId: '', // Le backend utilisera l'ID de l'utilisateur connecté
                    sellerId: product.sellerId,
                    totalPrice: product.price,
                    status: OrderStatus.pending,
                    createdAt: DateTime.now(),
                  ),
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Achat réussi !')),
                );
                // Rafraîchir les produits
                ref.invalidate(productsProvider);
                ref.invalidate(productDetailProvider(product.id));
              } catch (e) {
                if (!context.mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur lors de l\'achat: $e')),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

}
