import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/providers/shop_providers.dart';
import '../../../../shared/models/product_model.dart';

/// Widget card pour afficher un produit
class ProductCard extends ConsumerWidget {
  final String productId;
  final String imageUrl;
  final String title;
  final double price;
  final VoidCallback onTap;
  // Note: used for the heart icon logic if needed, but we now use the provider
  final ProductModel? product; 

  const ProductCard({
    super.key,
    required this.productId,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.onTap,
    this.product,
    @Deprecated('Use isFavoriteProvider instead') bool isFavorite = false,
    @Deprecated('Managed via favoritesProvider') VoidCallback? onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(productId));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: imageUrl.isEmpty
                        ? const Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.grey,
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.cloviGreen.withOpacity(0.3),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (product != null) {
                          ref.read(favoritesProvider.notifier).toggleFavorite(product!);
                        } else {
                          // Fallback for cases where only ID is provided
                          // We create a dummy product just for toggle logic
                          final dummy = ProductModel(
                            id: productId,
                            title: title,
                            description: '',
                            price: price,
                            category: '',
                            sellerId: '',
                            imageUrls: imageUrl.isEmpty ? [] : [imageUrl],
                            condition: ProductCondition.good,
                            status: ProductStatus.published,
                            isFavorite: isFavorite,
                            createdAt: DateTime.now(),
                            size: '',
                            brand: '',
                          );
                          ref.read(favoritesProvider.notifier).toggleFavorite(dummy);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorite ? Colors.red : AppColors.cloviGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title.toLowerCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      Formatters.price(price),
                      style: const TextStyle(
                        color: AppColors.cloviGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
