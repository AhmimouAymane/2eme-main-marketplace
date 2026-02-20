import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import 'package:marketplace_app/shared/models/user_model.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String userId;

  const SellerProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(sellerProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.cloviBeige,
      appBar: AppBar(
        title: const Text('Profil du vendeur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: sellerAsync.when(
        data: (seller) => CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: AppColors.cloviGreen.withOpacity(0.1),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.cloviGreen,
                        backgroundImage: seller.avatarUrl != null 
                            ? NetworkImage(seller.avatarUrl!) 
                            : null,
                        child: seller.avatarUrl == null 
                            ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      seller.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (seller.bio != null && seller.bio!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          seller.bio!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStat(seller.salesCount.toString(), 'Ventes'),
                        _buildVerticalDivider(),
                        _buildStat(seller.products?.length.toString() ?? '0', 'Articles'),
                        _buildVerticalDivider(),
                        _buildStat(
                          seller.averageRating == 0 ? '—' : seller.averageRating.toStringAsFixed(1), 
                          'Note',
                          isRating: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildRatingButton(context, ref, seller),
                  ],
                ),
              ),
            ),

            // Products Section Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ses annonces',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Products Grid
            if (seller.products == null || seller.products!.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Aucune annonce pour le moment'),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = seller.products![index];
                      return GestureDetector(
                        onTap: () => context.push('/product/${product.id}'),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: product.fullImageUrls.isNotEmpty
                                      ? Image.network(
                                          product.fullImageUrls.first,
                                          fit: BoxFit.cover,
                                        )
                                      : Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.price(product.price),
                                      style: const TextStyle(
                                        color: AppColors.cloviGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: seller.products!.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur : $e')),
      ),
    );
  }

  static Widget _buildStat(String value, String label, {bool isRating = false}) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cloviGreen,
                ),
              ),
              if (isRating && value != '—') ...[
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildRatingButton(BuildContext context, WidgetRef ref, UserModel seller) {
    return SizedBox(
      width: 200,
      child: OutlinedButton(
        onPressed: () => _showRatingDialog(context, ref, seller),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cloviGreen,
          side: const BorderSide(color: AppColors.cloviGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline_rounded, size: 20),
            SizedBox(width: 8),
            Text('Laisser un avis', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _showRatingDialog(BuildContext context, WidgetRef ref, UserModel seller) async {
    int rating = 0;
    final commentController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Évaluer ${seller.firstName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: index < rating ? Colors.amber : Colors.grey,
                      size: 32,
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
              onPressed: rating == 0 ? null : () async {
                try {
                  await ref.read(usersServiceProvider).rateUser(
                    seller.id,
                    rating,
                    commentController.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Merci pour votre avis !')),
                    );
                    ref.invalidate(sellerProfileProvider(seller.id));
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
                foregroundColor: Colors.white,
              ),
              child: const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}
