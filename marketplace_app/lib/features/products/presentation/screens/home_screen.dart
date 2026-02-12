import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/shared/models/category_model.dart';
import '../widgets/product_card.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';

/// Écran d'accueil avec liste de produits
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 0) {
      // Si on clique sur Accueil, on réinitialise les filtres
      ref.read(productFilterProvider.notifier).clearAll();
    }
    
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        // Déjà sur home
        break;
      case 1:
        context.push(AppRoutes.search);
        break;
      case 2:
        context.push(AppRoutes.createProduct);
        break;
      case 3:
        context.push(AppRoutes.orders);
        break;
      case 4:
        context.push(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => context.push(AppRoutes.favorites),
          ),
          conversationsAsync.when(
            data: (conversations) {
              final currentUserIdAsync = ref.watch(userIdProvider);
              final currentUserId = currentUserIdAsync.maybeWhen(
                data: (id) => id,
                orElse: () => null,
              );
              int totalUnread = 0;
              if (currentUserId != null) {
                for (final conv in conversations) {
                  totalUnread += conv.messages
                      .where((m) =>
                          m.senderId != currentUserId && !m.isRead)
                      .length;
                }
              }

              if (totalUnread > 0) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.message_outlined),
                      onPressed: () =>
                          context.push(AppRoutes.conversations),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            totalUnread > 9 ? '9+' : '$totalUnread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return IconButton(
                icon: const Icon(Icons.message_outlined),
                onPressed: () => context.push(AppRoutes.conversations),
              );
            },
            loading: () => IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: () => context.push(AppRoutes.conversations),
            ),
            error: (_, __) => IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: () => context.push(AppRoutes.conversations),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(homeProductsProvider.future),
        child: CustomScrollView(
          slivers: [
            // Categories horizontales
            ref.watch(categoriesProvider).maybeWhen(
              data: (categories) {
                final selectedCategoryId = ref.watch(productFilterProvider).categoryId;
                
                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        _buildCategoryChip(
                          'Tous',
                          selectedCategoryId == null,
                          onSelected: (_) {
                            print('HomeScreen: Selected category: Tous');
                            ref.read(productFilterProvider.notifier).updateCategory(null);
                          },
                        ),
                        ...categories.take(10).map((CategoryModel category) => _buildCategoryChip(
                          category.name,
                          selectedCategoryId == category.id,
                          onSelected: (_) {
                            print('HomeScreen: Selected category: ${category.name} (id: ${category.id})');
                            ref.read(productFilterProvider.notifier).updateCategory(category.id);
                          },
                        )),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Grille de produits
            ref.watch(homeProductsProvider).when(
              data: (products) => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = products[index];
                      return ProductCard(
                        productId: product.id,
                        imageUrl: product.fullMainImageUrl,
                        title: product.title,
                        price: product.price,
                        isFavorite: product.isFavorite,
                        onTap: () => context.push('/product/${product.id}'),
                        onFavoriteToggle: () {
                          ref.read(favoritesProvider.notifier).toggleFavorite(product);
                        },
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              ),
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: Center(
                  child: Text('Erreur: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Recherche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Vendre',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createProduct),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, {required Function(bool) onSelected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
