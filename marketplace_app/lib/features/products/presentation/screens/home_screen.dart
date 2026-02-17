import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import '../widgets/product_card.dart';
import 'package:marketplace_app/shared/widgets/clovi_logo.dart';
import 'package:marketplace_app/shared/widgets/clovi_bottom_nav.dart';
import 'package:marketplace_app/shared/widgets/clovi_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Écran d'accueil avec liste de produits
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Reinitialiser les filtres quand on arrive sur l'accueil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('DEBUG: HomeScreen.initState - Clearing filters');
        ref.read(productFilterProvider.notifier).clearAll();
      }
    });
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        // Déjà sur home : refresh
        ref.read(productFilterProvider.notifier).clearAll();
        ref.invalidate(homeProductsProvider);
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        ref.read(productFilterProvider.notifier).clearAll();
        context.go(AppRoutes.search);
        break;
      case 2:
        context.push(AppRoutes.createProduct);
        break;
      case 3:
        context.go(AppRoutes.conversations);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.cloviBeige,
      drawer: const CloviDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top Bar
            _buildTopBar(),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  print(
                    'DEBUG: HomeScreen.onRefresh - Clearing filters and refreshing products',
                  );
                  ref.read(productFilterProvider.notifier).clearAll();
                  await ref.refresh(homeProductsProvider.future);
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Section
                      _buildSearchSection(),
                      const SizedBox(height: 24),

                      // Trending Products
                      _buildTrendingProductsSection(),
                      const SizedBox(height: 32),

                      // Trending Categories
                      _buildTrendingCategoriesSection(),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CloviBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, size: 28, color: AppColors.cloviGreen),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          const CloviLogo(size: 30, fontSize: 24),
          IconButton(
            icon: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                ref.read(productFilterProvider.notifier).clearAll();
                await context.push(AppRoutes.search);
                // Au retour de la recherche, on s'assure que l'accueil est propre
                print('DEBUG: Returning from Search - Resetting Home');
                ref.read(productFilterProvider.notifier).clearAll();
                ref.invalidate(homeProductsProvider);
              },
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.cloviGreen),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.push(AppRoutes.favorites),
            child: Container(
              height: 45,
              width: 45,
              decoration: const BoxDecoration(
                color: AppColors.cloviDarkGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cloviGreen,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  ref.read(productFilterProvider.notifier).clearAll();
                  await context.push(AppRoutes.search);
                  ref.read(productFilterProvider.notifier).clearAll();
                  ref.invalidate(homeProductsProvider);
                },
                child: const Row(
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.cloviGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: AppColors.cloviGreen),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ref
              .watch(homeProductsProvider)
              .when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'No trending products found',
                        style: TextStyle(color: AppColors.cloviGreen),
                      ),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 16),
                        child: ProductCard(
                          productId: product.id,
                          imageUrl: product.fullMainImageUrl,
                          title: product.title,
                          price: product.price,
                          isFavorite: product.isFavorite,
                          onTap: () => context.push('/product/${product.id}'),
                          onFavoriteToggle: () {
                            ref
                                .read(favoritesProvider.notifier)
                                .toggleFavorite(product);
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
        ),
      ],
    );
  }

  Widget _buildTrendingCategoriesSection() {
    // Fetch categories from backend instead of hardcoding IDs
    final categoriesAsync = ref.watch(categoriesProvider);

    final categoryImages = [
      'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?q=80&w=500&auto=format&fit=crop', // Children
      'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=500&auto=format&fit=crop', // Women
      'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?q=80&w=500&auto=format&fit=crop', // Men
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trending',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cloviGreen,
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.cloviGreen, size: 28),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(
                  child: Text(
                    'No categories available',
                    style: TextStyle(color: AppColors.cloviGreen),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final catImage =
                      categoryImages[index % categoryImages.length];

                  return GestureDetector(
                    onTap: () async {
                      print(
                        'DEBUG: Clicked category - ID: ${cat.id}, Name: ${cat.name}',
                      );
                      ref
                          .read(productFilterProvider.notifier)
                          .updateCategory(cat.id);
                      print('DEBUG: Filter updated to categoryId: ${cat.id}');
                      await context.push(AppRoutes.search);
                      // Reset après retour de la recherche
                      ref.read(productFilterProvider.notifier).clearAll();
                      ref.invalidate(homeProductsProvider);
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: catImage,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: [
                                AppColors.cloviGreen,
                                AppColors.cloviDarkGreen,
                                Colors.brown[300] ?? Colors.brown,
                              ][index % 3].withOpacity(0.1),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.cloviGreen,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 14,
                                    color: AppColors.cloviGreen,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error loading categories: $e')),
          ),
        ),
      ],
    );
  }
}
