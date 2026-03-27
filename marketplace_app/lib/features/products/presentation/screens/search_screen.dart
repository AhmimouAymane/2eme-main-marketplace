import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/shared/models/category_model.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/features/products/presentation/widgets/product_card.dart';
import 'package:marketplace_app/shared/models/user_model.dart';

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

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(productFilterProvider);
    _searchController.text = currentFilters.search ?? '';

    // Request focus on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
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

  @override
  Widget build(BuildContext context) {
    final searchMode = ref.watch(searchModeProvider);
    final productsAsync = ref.watch(productsProvider);
    final usersAsync = ref.watch(userSearchProvider);

    return Scaffold(
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
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildModeTab(
                  label: 'Articles',
                  isActive: searchMode == SearchMode.articles,
                  onTap: () {
                    ref.read(searchModeProvider.notifier).state = SearchMode.articles;
                  },
                ),
                const SizedBox(width: 12),
                _buildModeTab(
                  label: 'Membres',
                  isActive: searchMode == SearchMode.members,
                  onTap: () {
                    ref.read(searchModeProvider.notifier).state = SearchMode.members;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche stylisée
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
                  hintText: searchMode == SearchMode.articles ? 'Search items...' : 'Search members...',
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

          // Filtres stylisés (uniquement pour les articles)
          if (searchMode == SearchMode.articles)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterButton(
                    onPressed: () => _showCategoryFilter(),
                    icon: Icons.category_outlined,
                    label: ref.watch(categoriesProvider).maybeWhen(
                          data: (categories) {
                            final selectedId = ref.watch(productFilterProvider).categoryId;
                            if (selectedId == null) return 'Category';
                            
                            // Helper for recursive search in SearchScreen
                            CategoryModel? findById(List<CategoryModel> cats, String id) {
                              for (var c in cats) {
                                if (c.id == id) return c;
                                if (c.children.isNotEmpty) {
                                  var found = findById(c.children, id);
                                  if (found != null) return found;
                                }
                              }
                              return null;
                            }

                            return findById(categories, selectedId)?.name ?? 'Category';
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
            child: searchMode == SearchMode.articles
                ? productsAsync.when(
                    data: (products) {
                      if (products.isEmpty) {
                        return _buildEmptyState('No results found');
                      }
                      return GridView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
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
                              ref.read(favoritesProvider.notifier).toggleFavorite(product);
                            },
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.cloviGreen),
                    ),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                  )
                : usersAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        if (_searchController.text.isEmpty) {
                          return _buildEmptyState('Type a name to search members');
                        }
                        return _buildEmptyState('No members found');
                      }
                      return ListView.separated(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return _buildUserTile(context, user);
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

  void _showCategoryFilter() async {
    FocusScope.of(context).unfocus();

    final categoriesState = ref.read(categoriesProvider);
    if (!categoriesState.hasValue) return;

    final categories = categoriesState.value!;
    final selectedId = ref.read(productFilterProvider).categoryId;

    final String? result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CategoryFilterSheet(
        categories: categories,
        selectedId: selectedId,
      ),
    );

    if (result != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final categoryId = result == "" ? null : result;
      ref.read(productFilterProvider.notifier).updateCategory(categoryId);
    }
  }

  void _showPriceFilter() async {
    FocusScope.of(context).unfocus();

    final filters = ref.read(productFilterProvider);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PriceFilterSheet(
        initialMin: filters.minPrice,
        initialMax: filters.maxPrice,
      ),
    );

    if (result != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      if (result['action'] == 'clear') {
        ref.read(productFilterProvider.notifier).clearPriceRange();
      } else if (result['action'] == 'apply') {
        ref
            .read(productFilterProvider.notifier)
            .updatePriceRange(result['min'], result['max']);
      }
    }
  }

  Widget _buildModeTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.cloviGreen : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isActive ? AppColors.cloviGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
          Text(
            message,
            style: const TextStyle(
              color: AppColors.cloviGreen,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserModel user) {
    return ListTile(
      onTap: () {
        _focusNode.unfocus();
        context.push('/seller/${user.id}');
      },
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.grey[200],
        backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
      title: Text(
        user.fullName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('Membre Clovi'),
      trailing: const Icon(Icons.chevron_right),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      tileColor: Colors.white,
    );
  }
}

class _CategoryFilterSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final String? selectedId;

  const _CategoryFilterSheet({
    required this.categories,
    required this.selectedId,
  });

  @override
  State<_CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<_CategoryFilterSheet> {
  late List<CategoryModel> _currentDisplayList;
  final List<List<CategoryModel>> _navigationStack = [];
  final List<String?> _parentIds = [];
  final List<String?> _parentNames = [];

  @override
  void initState() {
    super.initState();
    _currentDisplayList = widget.categories;
  }

  void _navigateDeeper(CategoryModel category) {
    if (category.children.isNotEmpty) {
      setState(() {
        _navigationStack.add(_currentDisplayList);
        _parentIds.add(category.id);
        _parentNames.add(category.name);
        _currentDisplayList = category.children;
      });
    } else {
      Navigator.pop(context, category.id);
    }
  }

  void _navigateBack() {
    if (_navigationStack.isNotEmpty) {
      setState(() {
        _currentDisplayList = _navigationStack.removeLast();
        _parentIds.removeLast();
        _parentNames.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentParentId = _parentIds.isEmpty ? null : _parentIds.last;
    final currentParentName = _parentNames.isEmpty ? null : _parentNames.last;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_navigationStack.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: _navigateBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppColors.cloviGreen,
                ),
              if (_navigationStack.isNotEmpty) const SizedBox(width: 8),
              Text(
                currentParentName ?? 'Catégories',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cloviGreen,
                ),
              ),
              const Spacer(),
              if (_navigationStack.isEmpty)
                TextButton(
                  onPressed: () => Navigator.pop(context, ""),
                  child: const Text('Toutes'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _currentDisplayList.length + (_navigationStack.isNotEmpty ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // If we are in a sub-category, add the "Tout [Parent]" item first
                if (_navigationStack.isNotEmpty && index == 0) {
                  final isSelected = widget.selectedId == currentParentId;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Tout $currentParentName',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                        color: isSelected ? AppColors.cloviGreen : AppColors.cloviGreen,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.cloviGreen, size: 20)
                        : null,
                    onTap: () => Navigator.pop(context, currentParentId),
                  );
                }

                // Adjust index if we added the "Tout" item
                final categoryIndex = _navigationStack.isNotEmpty ? index - 1 : index;
                final category = _currentDisplayList[categoryIndex];
                final hasChildren = category.children.isNotEmpty;
                final isSelected = widget.selectedId == category.id;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.cloviGreen : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check, color: AppColors.cloviGreen, size: 20),
                      if (hasChildren)
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ],
                  ),
                  onTap: () {
                    if (hasChildren) {
                      _navigateDeeper(category);
                    } else {
                      Navigator.pop(context, category.id);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceFilterSheet extends StatefulWidget {
  final double? initialMin;
  final double? initialMax;

  const _PriceFilterSheet({
    this.initialMin,
    this.initialMax,
  });

  @override
  State<_PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<_PriceFilterSheet> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.initialMin != null
          ? widget.initialMin!.round().toString()
          : '',
    );
    _maxController = TextEditingController(
      text: widget.initialMax != null
          ? widget.initialMax!.round().toString()
          : '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          const Text(
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
                  controller: _minController,
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
                  controller: _maxController,
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
                onPressed: () => Navigator.pop(context, {'action': 'clear'}),
                child: const Text('Effacer'),
              ),
              const Spacer(),
              SizedBox(
                child: ElevatedButton(
                  onPressed: () {
                    final minStr = _minController.text.trim();
                    final maxStr = _maxController.text.trim();

                    if (minStr.isEmpty && maxStr.isEmpty) {
                      Navigator.pop(context, {'action': 'clear'});
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

                    Navigator.pop(context, {
                      'action': 'apply',
                      'min': min,
                      'max': max,
                    });
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
    );
  }
}
