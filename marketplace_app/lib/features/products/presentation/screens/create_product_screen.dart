/// Écran de création d'annonce
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/core/utils/validators.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'dart:io';

import 'package:marketplace_app/shared/models/product_model.dart';
//import 'package:marketplace_app/features/products/data/products_service.dart';
//import 'package:marketplace_app/shared/services/media_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_app/shared/providers/shop_providers.dart';
import 'package:marketplace_app/shared/services/categories_service.dart';
import 'package:marketplace_app/shared/models/category_model.dart';


class CreateProductScreen extends ConsumerStatefulWidget {
  final ProductModel? productToEdit;

  const CreateProductScreen({super.key, this.productToEdit});

  @override
  ConsumerState<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends ConsumerState<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  
  // Hierarchical categories state
  CategoryModel? _selectedGenre;
  CategoryModel? _selectedCategory;
  CategoryModel? _selectedSubCategory;

  String _selectedSize = '';
  String _selectedCondition = 'VERY_GOOD'; 
  bool _isLoading = false;
  bool _categoriesInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      final product = widget.productToEdit!;
      _titleController.text = product.title;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _brandController.text = product.brand;
      // Note: mapping back from saved category to hierarchy is tricky without full path
      // logic to pre-select categories would go here if we had the full path or IDs
      // For now we might need to rely on the user re-selecting or fetch the full category object
      
      _selectedSize = product.size;
      _selectedCondition = _conditionToString(product.condition);
      _existingImageUrls.addAll(product.imageUrls);
    }
  }

  String _conditionToString(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.newWithTags: return 'NEW_WITH_TAGS';
      case ProductCondition.newWithoutTags: return 'NEW_WITHOUT_TAGS';
      case ProductCondition.veryGood: return 'VERY_GOOD';
      case ProductCondition.good: return 'GOOD';
      case ProductCondition.fair: return 'FAIR';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length + _existingImageUrls.length >= AppConstants.maxImageUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${AppConstants.maxImageUpload} images'),
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          images.take(AppConstants.maxImageUpload - _selectedImages.length - _existingImageUrls.length),
        );
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie complète')),
      );
      return;
    }
    
    if (_selectedSize.isEmpty && _selectedSubCategory?.sizeType != 'ONE_SIZE') {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une taille')),
      );
      return;
    }

    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une photo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mediaService = ref.read(mediaServiceProvider);
      final productsService = ref.read(productsServiceProvider);
      
      // Upload new images
      List<String> newImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        newImageUrls = await mediaService.uploadImages(_selectedImages);
      }

      final allImageUrls = [..._existingImageUrls, ...newImageUrls];
      final sizeToSend = _selectedSubCategory?.sizeType == 'ONE_SIZE' ? 'Taille Unique' : _selectedSize;

      if (widget.productToEdit != null) {
        // Update existing product
        await productsService.updateProduct(widget.productToEdit!.id, {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'categoryId': _selectedSubCategory!.id,
          'size': sizeToSend,
          'brand': _brandController.text,
          'condition': _selectedCondition,
          'imageUrls': allImageUrls,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produit mis à jour avec succès !')),
          );
          
          // Invalider les providers pour rafraîchir les listes
          ref.invalidate(homeProductsProvider);
          ref.invalidate(productsProvider);
          ref.invalidate(userProductsProvider);
          if (widget.productToEdit != null) {
            ref.invalidate(productDetailProvider(widget.productToEdit!.id));
          }
        }
      } else {
        // Create new product
        final product = ProductModel(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          category: _selectedSubCategory!.name, // Temporary display name
          categoryId: _selectedSubCategory!.id,
          size: sizeToSend,
          brand: _brandController.text,
          condition: _conditionFromBackendString(_selectedCondition),
          status: ProductStatus.pendingApproval,
          imageUrls: allImageUrls,
          sellerId: '',
          createdAt: DateTime.now(),
        );

        await productsService.createProduct(product);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produit créé avec succès !')),
          );
          
          // Invalider les providers pour rafraîchir les listes immédiatement
          ref.invalidate(homeProductsProvider);
          ref.invalidate(productsProvider);
          ref.invalidate(userProductsProvider);
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    }
  }

  ProductCondition _conditionFromBackendString(String value) {
    switch (value) {
      case 'NEW_WITH_TAGS': return ProductCondition.newWithTags;
      case 'NEW_WITHOUT_TAGS': return ProductCondition.newWithoutTags;
      case 'VERY_GOOD': return ProductCondition.veryGood;
      case 'GOOD': return ProductCondition.good;
      case 'FAIR': return ProductCondition.fair;
      default: return ProductCondition.veryGood;
    }
  }

  void _initializeCategories(List<CategoryModel> genres) {
    if (_categoriesInitialized || widget.productToEdit == null) return;

    final targetId = widget.productToEdit!.categoryId;
    print('DEBUG: Initializing categories for $targetId');
    
    for (var genre in genres) {
      for (var category in genre.children) {
        for (var sub in category.children) {
          if (sub.id == targetId) {
            setState(() {
              _selectedGenre = genre;
              _selectedCategory = category;
              _selectedSubCategory = sub;
              _categoriesInitialized = true;
            });
            print('DEBUG: Found category hierarchy: ${genre.name} > ${category.name} > ${sub.name}');
            return;
          }
        }
      }
    }
    _categoriesInitialized = true;
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.cloviGreen,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCategorySelectors(List<CategoryModel> genres) {
    // Tenter d'initialiser si on est en mode édition
    _initializeCategories(genres);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genre
        DropdownButtonFormField<CategoryModel>(
          initialValue: _selectedGenre,
          decoration: const InputDecoration(labelText: 'Genre'),
          items: genres.map((genre) => DropdownMenuItem(
            value: genre,
            child: Text(genre.name),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGenre = value;
              _selectedCategory = null;
              _selectedSubCategory = null;
              _selectedSize = '';
            });
          },
        ),
        const SizedBox(height: 16),

        // Category
        if (_selectedGenre != null)
          DropdownButtonFormField<CategoryModel>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            items: _selectedGenre!.children.map((category) => DropdownMenuItem(
              value: category,
              child: Text(category.name),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _selectedSubCategory = null;
                _selectedSize = '';
              });
            },
          ),
        if (_selectedGenre != null) const SizedBox(height: 16),

        // SubCategory
        if (_selectedCategory != null)
          DropdownButtonFormField<CategoryModel>(
            initialValue: _selectedSubCategory,
            decoration: const InputDecoration(labelText: 'Sous-catégorie'),
            items: _selectedCategory!.children.map((sub) => DropdownMenuItem(
              value: sub,
              child: Text(sub.name),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSubCategory = value;
                _selectedSize = '';
              });
            },
          ),
      ],
    );
  }

  Widget _buildSizeSelector() {
    if (_selectedSubCategory == null) return const SizedBox.shrink();

    final sizes = _selectedSubCategory!.possibleSizes ?? [];
    
    if (sizes.isEmpty) {
      if (_selectedSubCategory!.sizeType == 'ONE_SIZE') {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Chip(label: const Text('Taille Unique')),
        );
      }
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Taille',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sizes.map((size) {
            final isSelected = _selectedSize == size;
            return GestureDetector(
              onTap: () => setState(() => _selectedSize = size),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.cloviGreen : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.cloviGreen : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesTreeProvider);

    return Scaffold(
      backgroundColor: AppColors.cloviBeige,
      appBar: AppBar(
        title: Text(
          widget.productToEdit != null ? 'Modifier l\'annonce' : 'Vendre un article',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.cloviGreen,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Section Photos
            _buildSection(
              title: 'Photos',
              children: [
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppColors.cloviBeige,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.cloviGreen.withOpacity(0.3),
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                color: AppColors.cloviGreen,
                                size: 32,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ajouter',
                                style: TextStyle(
                                  color: AppColors.cloviGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ..._existingImageUrls.map((url) => _buildImageThumbnail(url, isNetwork: true)),
                      ..._selectedImages.map((file) => _buildImageThumbnail(file.path, isNetwork: false)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ajoutez jusqu\'à ${AppConstants.maxImageUpload} photos pour mieux vendre.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Details Section
            _buildSection(
              title: 'Détails de l\'article',
              children: [
                TextFormField(
                  controller: _titleController,
                  validator: Validators.productTitle,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    hintText: 'Ex: T-shirt Nike blanc taille M',
                    prefixIcon: Icon(Icons.title_rounded, color: AppColors.cloviGreen),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  validator: Validators.productDescription,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Décrivez votre article (matière, défauts...)',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description_rounded, color: AppColors.cloviGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _brandController,
                  validator: (v) => Validators.required(v, fieldName: 'La marque'),
                  decoration: const InputDecoration(
                    labelText: 'Marque',
                    hintText: 'Ex: Nike, Zara, Vintage...',
                    prefixIcon: Icon(Icons.sell_rounded, color: AppColors.cloviGreen),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCondition,
                  decoration: const InputDecoration(
                    labelText: 'État',
                    prefixIcon: Icon(Icons.star_rounded, color: AppColors.cloviGreen),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'NEW_WITH_TAGS', child: Text('Neuf avec étiquette')),
                    DropdownMenuItem(value: 'NEW_WITHOUT_TAGS', child: Text('Neuf sans étiquette')),
                    DropdownMenuItem(value: 'VERY_GOOD', child: Text('Très bon état')),
                    DropdownMenuItem(value: 'GOOD', child: Text('Bon état')),
                    DropdownMenuItem(value: 'FAIR', child: Text('État correct')),
                  ],
                  onChanged: (value) => setState(() => _selectedCondition = value!),
                ),
              ],
            ),

            // Catégorie Section
            _buildSection(
              title: 'Catégorie & Taille',
              children: [
                categoriesAsync.when(
                  data: (genres) => _buildCategorySelectors(genres),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('Erreur: $err'),
                ),
                _buildSizeSelector(),
              ],
            ),

            // Pricing Section
            _buildSection(
              title: 'Prix',
              children: [
                TextFormField(
                  controller: _priceController,
                  validator: Validators.price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Votre prix de vente',
                    suffixText: AppConstants.currencySymbol,
                    suffixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    prefixIcon: const Icon(Icons.money, color: AppColors.cloviGreen),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cloviGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.cloviGreen, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Les frais d\'envoi s\'ajoutent au prix.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.cloviGreen.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cloviGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        widget.productToEdit != null ? 'Enregistrer les modifications' : 'Publier l\'annonce',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String path, {required bool isNetwork}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          isNetwork
              ? Image.network(
                  path.startsWith('http') ? path : '${AppConstants.mediaBaseUrl}$path',
                  fit: BoxFit.cover,
                )
              : (kIsWeb 
                  ? Image.network(path, fit: BoxFit.cover) 
                  : Image.file(File(path), fit: BoxFit.cover)),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isNetwork) {
                    _existingImageUrls.remove(path);
                  } else {
                    _selectedImages.removeWhere((f) => f.path == path);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

