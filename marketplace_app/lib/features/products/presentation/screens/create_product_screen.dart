/// Écran de création d'annonce
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:image_picker/image_picker.dart';
//import 'package:marketplace_app/core/theme/app_colors.dart';
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
          status: ProductStatus.forSale,
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

    final sizeType = _selectedSubCategory!.sizeType;
    List<String> sizes = [];

    switch (sizeType) {
      case 'ALPHA':
        sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
        break;
      case 'NUMERIC_SHOES':
        sizes = List.generate(11, (index) => (36 + index).toString()); // 36-46
        break;
      case 'NUMERIC_PANTS':
        sizes = List.generate(13, (index) => (36 + index).toString()); // 36-48
        break;
      case 'AGE':
        sizes = ['2 ans', '3 ans', '4 ans', '5 ans', '6 ans', '8 ans', '10 ans', '12 ans', '14 ans'];
        break;
      case 'ONE_SIZE':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Chip(label: const Text('Taille Unique')),
        );
      default:
        sizes = ['Taille Unique'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Taille', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sizes.map((size) {
            final isSelected = _selectedSize == size;
            return FilterChip(
              label: Text(size),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedSize = selected ? size : '');
              },
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
      appBar: AppBar(
        title: Text(widget.productToEdit != null ? 'Modifier l\'annonce' : 'Vendre un article'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photos
            Text(
              'Photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // ... (Image picker widget code remains similar, simplifying for this view)
             SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined),
                          Text('Ajouter'),
                        ],
                      ),
                    ),
                  ),
                   ..._existingImageUrls.map((url) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Image.network(url.startsWith('http') ? url : '${AppConstants.mediaBaseUrl}$url', width: 100, height: 100, fit: BoxFit.cover),
                  )),
                  ..._selectedImages.map((file) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: kIsWeb ? Image.network(file.path, width: 100, height: 100, fit: BoxFit.cover) : Image.file(File(file.path), width: 100, height: 100, fit: BoxFit.cover),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            TextFormField(
              controller: _titleController,
              validator: Validators.productTitle,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: T-shirt Nike blanc taille M',
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              validator: Validators.productDescription,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Décrivez votre article...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Prix
            TextFormField(
              controller: _priceController,
              validator: Validators.price,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Prix',
                suffixText: AppConstants.currencySymbol,
              ),
            ),
            const SizedBox(height: 16),

            // Marque
            TextFormField(
              controller: _brandController,
              validator: (v) => Validators.required(v, fieldName: 'La marque'),
              decoration: const InputDecoration(
                labelText: 'Marque',
              ),
            ),
            const SizedBox(height: 16),

            // CATEGORIES (Async)
            categoriesAsync.when(
              data: (genres) => _buildCategorySelectors(genres),
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('Erreur de chargement des catégories: $err'),
            ),
            
            // TAILLE (Dynamic)
            _buildSizeSelector(),
            
            const SizedBox(height: 16),

            // Condition
            DropdownButtonFormField<String>(
              initialValue: _selectedCondition,
              decoration: const InputDecoration(labelText: 'État'),
              items: const [
                DropdownMenuItem(value: 'NEW_WITH_TAGS', child: Text('Neuf avec étiquette')),
                DropdownMenuItem(value: 'NEW_WITHOUT_TAGS', child: Text('Neuf sans étiquette')),
                DropdownMenuItem(value: 'VERY_GOOD', child: Text('Très bon état')),
                DropdownMenuItem(value: 'GOOD', child: Text('Bon état')),
                DropdownMenuItem(value: 'FAIR', child: Text('État correct')),
              ],
              onChanged: (value) {
                setState(() => _selectedCondition = value!);
              },
            ),
            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.productToEdit != null ? 'Modifier l\'annonce' : 'Publier l\'annonce'),
            ),
          ],
        ),
      ),
    );
  }
}
