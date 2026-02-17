import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/shared/models/category_model.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/features/products/presentation/widgets/product_card.dart';
import 'package:marketplace_app/core/routes/app_routes.dart';
import 'package:marketplace_app/shared/widgets/clovi_bottom_nav.dart';

/// Écran de recherche et filtrage des produits
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  int _selectedIndex = 1; // Onglet Recherche

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(productFilterProvider);
    _searchController.text = currentFilters.search ?? '';

    // Request focus on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        try {
          ref.read(productFilterProvider.notifier).clearPriceRange();
        } catch (e) {}
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 1) return; // Déjà sur recherche

    switch (index) {
      case 0:
        context.go(AppRoutes.home);
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
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppColors.cloviBeige,
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.cloviGreen,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cloviGreen),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche stylisée (identique à l'accueil)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.cloviGreen,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(productFilterProvider.notifier)
                                .clearSearch();
                            _focusNode.requestFocus();
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {});
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    ref
                        .read(productFilterProvider.notifier)
                        .updateSearch(value);
                  });
                },
              ),
            ),
          ),

          // Filtres stylisés
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterButton(
                  onPressed: () => _showCategoryFilter(),
                  icon: Icons.category_outlined,
                  label: ref
                      .watch(categoriesProvider)
                      .maybeWhen(
                        data: (categories) {
                          final selectedId = ref
                              .watch(productFilterProvider)
                              .categoryId;
                          if (selectedId == null) return 'Category';
                          return categories
                              .firstWhere(
                                (c) => c.id == selectedId,
                                orElse: () => categories.first,
                              )
                              .name;
                        },
                        orElse: () => 'Categories',
                      ),
                  isActive: ref.watch(productFilterProvider).categoryId != null,
                ),
                const SizedBox(width: 12),
                _buildFilterButton(
                  onPressed: () => _showPriceFilter(),
                  icon: Icons.tune_rounded,
                  label: 'Price',
                  isActive: ref.watch(productFilterProvider).minPrice != null,
                ),
              ],
            ),
          ),

          // Résultats
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: AppColors.cloviGreen.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No results found',
                          style: TextStyle(
                            color: AppColors.cloviGreen,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      productId: product.id,
                      imageUrl: product.fullMainImageUrl,
                      title: product.title,
                      price: product.price,
                      isFavorite: product.isFavorite,
                      onTap: () {
                        _focusNode.unfocus();
                        context.push('/product/${product.id}');
                      },
                      onFavoriteToggle: () {
                        ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(product);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.cloviGreen),
              ),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CloviBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildFilterButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isActive = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.cloviGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : AppColors.cloviGreen,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? Colors.white : AppColors.cloviGreen,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    ref
        .read(categoriesProvider)
        .maybeWhen(
          data: (categories) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                final selectedId = ref.watch(productFilterProvider).categoryId;
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cloviGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              title: const Text('All'),
                              trailing: selectedId == null
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.cloviGreen,
                                    )
                                  : null,
                              onTap: () {
                                Navigator.pop(context);
                                Future.microtask(
                                  () => ref
                                      .read(productFilterProvider.notifier)
                                      .updateCategory(null),
                                );
                              },
                            ),
                            ...categories.map((CategoryModel category) {
                              return ListTile(
                                title: Text(category.name),
                                trailing: selectedId == category.id
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.cloviGreen,
                                      )
                                    : null,
                                onTap: () {
                                  final categoryId = category.id;
                                  Navigator.pop(context);
                                  Future.microtask(
                                    () => ref
                                        .read(productFilterProvider.notifier)
                                        .updateCategory(categoryId),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          orElse: () {},
        );
  }

  void _showPriceFilter() {
    final filters = ref.read(productFilterProvider);
    final minController = TextEditingController(
      text: filters.minPrice != null
          ? filters.minPrice!.round().toString()
          : '',
    );
    final maxController = TextEditingController(
      text: filters.maxPrice != null
          ? filters.maxPrice!.round().toString()
          : '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Prix (DH)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.cloviGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saisissez le prix minimum et maximum',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min',
                      hintText: '0',
                      suffixText: 'DH',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.cloviGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '–',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max',
                      hintText: '1000',
                      suffixText: 'DH',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.cloviGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Future.microtask(
                      () => ref
                          .read(productFilterProvider.notifier)
                          .clearPriceRange(),
                    );
                  },
                  child: const Text('Effacer'),
                ),
                const Spacer(),
                SizedBox(
                  child: ElevatedButton(
                    onPressed: () {
                      final minStr = minController.text.trim();
                      final maxStr = maxController.text.trim();
                      if (minStr.isEmpty && maxStr.isEmpty) {
                        Navigator.pop(context);
                        Future.microtask(
                          () => ref
                              .read(productFilterProvider.notifier)
                              .clearPriceRange(),
                        );
                        return;
                      }
                      final min = minStr.isEmpty
                          ? 0.0
                          : (double.tryParse(minStr) ?? 0.0);
                      final max = maxStr.isEmpty
                          ? 99999.0
                          : (double.tryParse(maxStr) ?? 99999.0);
                      if (min > max) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Le prix min ne peut pas être supérieur au max.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      Future.microtask(
                        () => ref
                            .read(productFilterProvider.notifier)
                            .updatePriceRange(min, max),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cloviGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).then((_) {
      minController.dispose();
      maxController.dispose();
    });
  }
}
