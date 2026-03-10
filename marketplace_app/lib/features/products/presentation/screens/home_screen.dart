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
import 'package:marketplace_app/shared/models/category_model.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/features/notifications/presentation/providers/notifications_provider.dart';
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
    // Initialize socket connection globally to receive real-time updates for red dots
    ref.watch(chatSocketProvider);
    
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

                        // Section Bijoux
                        _buildCategoryProductSection(
                          title: 'Bijoux Étincelants',
                          provider: jewelryProductsProvider,
                          slug: 'femme-accessoires-bijoux',
                        ),
                        const SizedBox(height: 32),

                        // Section Chaussures Femme
                        _buildCategoryProductSection(
                          title: 'Chaussures Femme',
                          provider: womenShoesProductsProvider,
                          slug: 'femme-chaussures',
                        ),
                        const SizedBox(height: 32),

                        // Section Sacs & Accessoires
                        _buildCategoryProductSection(
                          title: 'Sacs & Accessoires',
                          provider: bagsProductsProvider,
                          slug: 'femme-accessoires-sacs',
                        ),
                        const SizedBox(height: 32),

                        // Community Activity
                        _buildCommunityActivitySection(),
                        const SizedBox(height: 32),

                        // All Products Grid (Requested: 2x2 vertical)
                        _buildAllProductsGrid(),
                        const SizedBox(height: 100),
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
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);
    final hasUnread = unreadCountAsync.maybeWhen(
      data: (count) {
        print('DEBUG: unreadCount = $count');
        return count > 0;
      },
      orElse: () => false,
    );

    return Container(
      height: 70, // Slightly taller for better spacing
      padding: EdgeInsets.zero, // Remove padding for absolute centering
      child: Stack(
        children: [
          // Left: Menu
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, size: 28, color: AppColors.cloviDarkGreen),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  if (hasUnread)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Center: Logo
          const Align(
            alignment: Alignment.center,
            child: CloviLogo(size: 32, fontSize: 26),
          ),

          // Right: Notifications & Profile
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, size: 28, color: AppColors.cloviDarkGreen),
                        onPressed: () => context.push(AppRoutes.notifications),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                    onPressed: () => context.go(AppRoutes.profile),
                  ),
                ],
              ),
            ),
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
              onTap: () {
                ref.read(productFilterProvider.notifier).clearAll();
                context.go(AppRoutes.search);
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
            'Catégories',
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
            data: (categories) {
              // Liste ordonnée demandée par l'utilisateur
              final targetNames = ['enfant', 'homme', 'femme', 'bijoux', 'montre', 'activewear'];
              final List<CategoryModel> displayedCategories = [];

              void collectTargetCategories(List<CategoryModel> cats) {
                for (var cat in cats) {
                  final nameLower = cat.name.toLowerCase();
                  // On cherche si le nom contient un des mots-clés cibles
                  if (targetNames.any((target) => nameLower.contains(target))) {
                    displayedCategories.add(cat);
                  }
                  if (cat.children.isNotEmpty) {
                    collectTargetCategories(cat.children);
                  }
                }
              }

              collectTargetCategories(categories);

              // Dédoublonnage par nom (ex: éviter plusieurs "Activewear")
              final uniqueCategories = <String, CategoryModel>{};
              for (var cat in displayedCategories) {
                // On normalise le nom pour le dédoublonnage
                String key = cat.name.toLowerCase();
                if (key.contains('enfant')) key = 'enfant';
                if (key.contains('homme')) key = 'homme';
                if (key.contains('femme')) key = 'femme';
                
                if (!uniqueCategories.containsKey(key)) {
                  uniqueCategories[key] = cat;
                }
              }
              
              final finalList = uniqueCategories.values.toList();

              // Tri selon l'ordre des targetNames
              finalList.sort((a, b) {
                int getIndex(CategoryModel c) {
                  final name = c.name.toLowerCase();
                  for (int i = 0; i < targetNames.length; i++) {
                    if (name.contains(targetNames[i])) return i;
                  }
                  return targetNames.length;
                }
                return getIndex(a).compareTo(getIndex(b));
              });

              if (finalList.isEmpty) return const SizedBox.shrink();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: finalList.length,
                itemBuilder: (context, index) {
                  return _buildCategoryItem(finalList[index]);
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

  Widget _buildCategoryItem(CategoryModel cat) {
    return GestureDetector(
      onTap: () {
        ref.read(productFilterProvider.notifier).updateCategory(cat.id);
        context.go(AppRoutes.search);
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
                color: AppColors.cloviGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(cat.name),
                color: AppColors.cloviGreen,
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
  }

  IconData _getCategoryIcon(String name) {
  name = name.toLowerCase();

  // Genres & Types
  if (name.contains('fille')) return Icons.face_3_outlined;
  if (name.contains('garcon') || name.contains('garçon')) return Icons.face_6_outlined;
  if (name.contains('enfant')) return Icons.child_care_outlined;
  if (name.contains('femme')) return Icons.woman_2_outlined;
  if (name.contains('homme')) return Icons.man_2_outlined;

  // Chaussures
    // more shoe-like silhouette
  if (name.contains('talon') || name.contains('escarpin')) return Icons.hiking_outlined;
  if (name.contains('botte')) return Icons.do_not_step_outlined;
  if (name.contains('basket') || name.contains('sneaker')) return Icons.directions_run_outlined;
  if (name.contains('sandale')) return Icons.beach_access_outlined;

  // Vêtements
  if (name.contains('vêtement') || name.contains('vetement')) return Icons.checkroom_outlined;
  if (name.contains('hauts') || name.contains('haut') || name.contains('chemise') || name.contains('blouse')) return Icons.dry_cleaning_outlined;
  if (name.contains('robe') || name.contains('robes')) return Icons.accessibility_new_outlined;
  if (name.contains('jean') || name.contains('pantalon')) return Icons.airline_seat_legroom_normal_outlined;
  if (name.contains('manteau') || name.contains('veste') || name.contains('blouson')) return Icons.umbrella_outlined;
  if (name.contains('pull') || name.contains('sweat')) return Icons.self_improvement_outlined;
  if (name.contains('jupe')) return Icons.interests_outlined;

  // Sacs
  if (name.contains('sac à dos') || name.contains('sac a dos')) return Icons.backpack_outlined;
  if (name.contains('sac à main') || name.contains('sac a main')) return Icons.shopping_bag_outlined;
  if (name.contains('portefeuille') || name.contains('pochette')) return Icons.account_balance_wallet_outlined;
  if (name.contains('sac')) return Icons.luggage_outlined;

  // Bijoux & Accessoires
  if (name.contains('collier') || name.contains('pendentif')) return Icons.diamond_outlined;
  if (name.contains('bague') || name.contains('bracelet')) return Icons.circle_outlined;
  if (name.contains('boucle') || name.contains('earring')) return Icons.radio_button_unchecked_outlined;
  if (name.contains('bijoux')) return Icons.diamond_outlined;
  if (name.contains('montre')) return Icons.watch_outlined;
  if (name.contains('lunettes')) return Icons.remove_red_eye_outlined;
  if (name.contains('chapeau') || name.contains('casquette')) return Icons.emoji_people_outlined;
  if (name.contains('écharpe') || name.contains('echarpe') || name.contains('foulard')) return Icons.air_outlined;
  if (name.contains('ceinture')) return Icons.horizontal_rule_outlined;
  if (name.contains('accessoire')) return Icons.watch_outlined;

  // Catégories spéciales
  if (name.contains('traditionnel')) return Icons.auto_awesome_outlined;
  if (name.contains('lingerie')) return Icons.favorite_border_outlined;
  if (name.contains('pyjama') || name.contains('nuit')) return Icons.bedtime_outlined;
  if (name.contains('sport') || name.contains('activewear')) return Icons.sports_gymnastics_outlined;
  if (name.contains('maillot') || name.contains('bain')) return Icons.pool_outlined;
  if (name.contains('mariage') || name.contains('soirée') || name.contains('soiree')) return Icons.celebration_outlined;
  if (name.contains('enfant') || name.contains('bébé') || name.contains('bebe')) return Icons.child_friendly_outlined;

  // Fallback
  return Icons.category_outlined;
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
                                  color: Colors.grey.withOpacity(0.3),
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
                onPressed: () => context.go(AppRoutes.search),
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

  Widget _buildCategoryProductSection({
    required String title,
    required AutoDisposeFutureProvider<List<ProductModel>> provider,
    required String slug,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cloviDarkGreen,
                ),
              ),
              TextButton(
                onPressed: () {
                  final id = ref.read(categoryBySlugProvider(slug));
                  if (id != null) {
                    ref.read(productFilterProvider.notifier).updateCategory(id);
                    context.push(AppRoutes.search);
                  }
                },
                child: const Text('voir tout'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ref.watch(provider).when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun produit trouvé dans cette catégorie',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
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

  Widget _buildAllProductsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tous les articles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ref.watch(homeProductsProvider).when(
              data: (products) {
                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Aucun article disponible pour le moment.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72, // Adjust based on ProductCard height
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        productId: product.id,
                        imageUrl: product.fullMainImageUrl,
                        title: product.title,
                        price: product.price,
                        product: product,
                        onTap: () => context.push('/product/${product.id}'),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => const SizedBox(),
            ),
      ],
    );
  }
}


