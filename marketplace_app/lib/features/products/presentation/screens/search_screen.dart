import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/shared/models/category_model.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/features/products/presentation/widgets/product_card.dart';

/// Écran de recherche et filtrage des produits
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  RangeValues _priceRange = const RangeValues(0, 1000);
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Réinitialiser la plage de prix locale pour le Slider
    _priceRange = const RangeValues(0, 1000);
    
    // Initialiser le texte avec la valeur actuelle du provider
    final currentFilters = ref.read(productFilterProvider);
    _searchController.text = currentFilters.search ?? '';
    
    // Réinitialiser le filtre de prix du côté backend à chaque fois qu'on entre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          ref.read(productFilterProvider.notifier).clearPriceRange();
        } catch (e) {
          // Ignorer si déjà disposed pendant le post frame
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    print('SearchScreen: Manually cleared search');
                    ref.read(productFilterProvider.notifier).clearSearch();
                  },
                ),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  print('SearchScreen: Debounced search text: $value');
                  ref.read(productFilterProvider.notifier).updateSearch(value);
                });
              },
            ),
          ),

          // Filtres
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCategoryFilter(),
                    icon: const Icon(Icons.category_outlined),
                    label: Text(
                      ref.watch(categoriesProvider).maybeWhen(
                        data: (List<CategoryModel> categories) {
                          final selectedId = ref.watch(productFilterProvider).categoryId;
                          if (selectedId == null) return 'Tous';
                          final category = categories.firstWhere(
                            (CategoryModel c) => c.id == selectedId, 
                            orElse: () => categories.first
                          );
                          return category.name;
                        },
                        orElse: () => 'Catégorie',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPriceFilter(),
                    icon: const Icon(Icons.euro_outlined),
                    label: const Text('Prix'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Résultats
          Expanded(
            child: ref.watch(productsProvider).when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Aucun produit trouvé', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
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
                      onTap: () => context.push('/product/${product.id}'),
                      onFavoriteToggle: () {
                        ref.read(favoritesProvider.notifier).toggleFavorite(product);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilter() {
    ref.read(categoriesProvider).maybeWhen(
      data: (categories) {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            final selectedId = ref.watch(productFilterProvider).categoryId;
            return ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('Tous'),
                  trailing: selectedId == null ? Icon(Icons.check, color: AppColors.primary) : null,
                  onTap: () {
                    print('SearchScreen: Selected category: Tous');
                    ref.read(productFilterProvider.notifier).updateCategory(null);
                    Navigator.pop(context);
                  },
                ),
                ...categories.map((CategoryModel category) {
                  return ListTile(
                    title: Text(category.name),
                    trailing: selectedId == category.id ? Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () {
                      print('SearchScreen: Selected category: ${category.name} (id: ${category.id})');
                      ref.read(productFilterProvider.notifier).updateCategory(category.id);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            );
          },
        );
      },
      orElse: () {},
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fourchette de prix',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000,
                divisions: 100,
                labels: RangeLabels(
                  '${_priceRange.start.round()}€',
                  '${_priceRange.end.round()}€',
                ),
                onChanged: (values) {
                  setModalState(() => _priceRange = values);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_priceRange.start.round()}€'),
                  Text('${_priceRange.end.round()}€'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    print('SearchScreen: Applying price range: [${_priceRange.start}-${_priceRange.end}]');
                    ref.read(productFilterProvider.notifier).updatePriceRange(
                      _priceRange.start,
                      _priceRange.end,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
