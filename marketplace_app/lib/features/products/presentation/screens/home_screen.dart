import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import '../widgets/product_card.dart';
import 'package:marketplace_app/shared/widgets/clovi_logo.dart';
import 'package:marketplace_app/shared/widgets/clovi_drawer.dart';
import 'package:marketplace_app/shared/models/product_model.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import '../../../profile/data/user_reviews_service.dart';

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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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

                        // Trending Categories
                        _buildCategoriesSection(),
                        const SizedBox(height: 32),

                        // Top Sellers
                        _buildTopSellersSection(),
                        const SizedBox(height: 32),

                        // Fresh Arrivals
                        _buildFreshArrivalsSection(),
                        const SizedBox(height: 32),

                        // Community Activity
                        _buildCommunityActivitySection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            icon: ref.watch(userAvatarUrlProvider).maybeWhen(
                  data: (url) {
                    if (url != null && url.isNotEmpty) {
                      final fullUrl = url.startsWith('http')
                          ? url
                          : '${AppConstants.mediaBaseUrl}$url';
                      return CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(fullUrl),
                      );
                    }
                    return _buildDefaultAvatar();
                  },
                  orElse: () => _buildDefaultAvatar(),
                ),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 28),
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
                            hintText: 'Chercher un article...',
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

  Widget _buildSafetyCarousel() {
    final tips = [
      {
        'icon': Icons.security,
        'title': 'Safety First',
        'desc': 'Meet in public places for transactions.',
        'color': AppColors.cloviGreen
      },
      {
        'icon': Icons.visibility,
        'title': 'Inspect Items',
        'desc': 'Check items thoroughly before paying.',
        'color': AppColors.cloviDarkGreen
      },
      {
        'icon': Icons.payments,
        'title': 'Cash on Delivery',
        'desc': 'Pay only after receiving your item.',
        'color': Colors.brown[400]
      },
    ];

    return SizedBox(
      height: 120,
      child: PageView.builder(
        itemCount: tips.length,
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (tip['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (tip['color'] as Color).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(tip['icon'] as IconData,
                    size: 40, color: tip['color'] as Color),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['title'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tip['color'] as Color,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        tip['desc'] as String,
                        style: TextStyle(
                          color: (tip['color'] as Color).withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: categoriesAsync.when(
            data: (categories) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(productFilterProvider.notifier)
                        .updateCategory(cat.id);
                    context.push(AppRoutes.search);
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: AppColors.cloviGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cloviGreen.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getCategoryIcon(cat.name),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('homme') || name.contains('men')) return Icons.man;
    if (name.contains('femme') || name.contains('women')) return Icons.woman;
    if (name.contains('enfant') || name.contains('kid')) return Icons.child_care;
    if (name.contains('chaussure')) return Icons.directions_run;
    if (name.contains('accessoire')) return Icons.watch;
    return Icons.category;
  }

  Widget _buildTopSellersSection() {
    final topSellersAsync = ref.watch(topSellersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Vendeurs à la une',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: topSellersAsync.when(
            data: (sellers) => ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sellers.length,
              itemBuilder: (context, index) {
                final seller = sellers[index];
                final avatarUrl = seller['avatarUrl'] as String?;
                final fullName = '${seller['firstName']} ${seller['lastName']}';
                final rating = (seller['averageRating'] as num).toDouble();
                final reviewCount = seller['reviewCount'] as int;

                return GestureDetector(
                  onTap: () => context.push('/seller/${seller['id']}'),
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cloviGreen.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl.startsWith('http')
                                        ? avatarUrl
                                        : '${AppConstants.mediaBaseUrl}$avatarUrl')
                                    : null,
                                child: avatarUrl == null
                                    ? const Icon(Icons.person, color: Colors.grey)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 10),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fullName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$reviewCount avis',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildFreshArrivalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Juste arrivé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cloviGreen,
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.search),
                child: const Text('voir tout'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ref.watch(homeProductsProvider).when(
                data: (products) {
                  if (products.isEmpty) return const SizedBox();
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length > 5 ? 5 : products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Container(
                        width: 150,
                        margin: const EdgeInsets.only(right: 16),
                        child: ProductCard(
                          productId: product.id,
                          imageUrl: product.fullMainImageUrl,
                          title: product.title,
                          price: product.price,
                          product: product,
                          onTap: () => context.push('/product/${product.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const SizedBox(),
              ),
        ),
      ],
    );
  }

  Widget _buildCommunityActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Derniers échanges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ref.watch(homeProductsProvider).when(
              data: (products) {
                // Flatten all comments from all products for "Recent Activity"
                final allComments = products
                    .expand((p) => p.comments.map((c) => {'comment': c, 'product': p}))
                    .toList();
                
                allComments.sort((a, b) => (b['comment'] as dynamic).createdAt.compareTo((a['comment'] as dynamic).createdAt));

                if (allComments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('No recent activity', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allComments.length > 3 ? 3 : allComments.length,
                  itemBuilder: (context, index) {
                    final item = allComments[index];
                    final comment = item['comment'] as dynamic;
                    final product = item['product'] as ProductModel;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(product.fullMainImageUrl),
                        ),
                        title: Text(
                          '${comment.user?.fullName ?? 'Someone'} commented on ${product.title}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          comment.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => context.push('/product/${product.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const SizedBox(),
              error: (e, _) => const SizedBox(),
            ),
      ],
    );
  }
}


