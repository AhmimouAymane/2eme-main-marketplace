import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';
import 'review_model.dart';
import 'comment_model.dart';

// part 'product_model.g.dart';
/// Statut d'un produit (Synchronisé avec le backend)
enum ProductStatus {
  @JsonValue('PENDING_APPROVAL')
  pendingApproval,
  @JsonValue('FOR_SALE')
  forSale,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('RESERVED')
  reserved,
  @JsonValue('SOLD')
  sold,
}

/// Condition d'un produit (Synchronisé avec le backend)
enum ProductCondition {
  @JsonValue('NEW_WITH_TAGS')
  newWithTags,
  @JsonValue('NEW_WITHOUT_TAGS')
  newWithoutTags,
  @JsonValue('VERY_GOOD')
  veryGood,
  @JsonValue('GOOD')
  good,
  @JsonValue('FAIR')
  fair,
}

/// Modèle de données pour un produit
@JsonSerializable()
class ProductModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final ProductCondition condition;
  final ProductStatus status;
  final String? moderationComment;
  final String category;
  final String categoryId;
  final String size;
  final String brand;
  final List<String> imageUrls;
  final String sellerId;
  final String? sellerName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
  final List<ReviewModel> reviews;
  final List<CommentModel> comments;
  final String? sellerCity;
  
  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.condition,
    required this.status,
    this.moderationComment,
    required this.category,
    this.categoryId = '',
    required this.size,
    required this.brand,
    required this.imageUrls,
    required this.sellerId,
    this.sellerName,
    required this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
    this.reviews = const [],
    this.comments = const [],
    this.sellerCity,
  });
  
  // Getters
  String get mainImageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  
  List<String> get fullImageUrls => imageUrls.map((url) {
    if (url.startsWith('http')) return url;
    return '${AppConstants.mediaBaseUrl}$url';
  }).toList();

  String get fullMainImageUrl {
    if (imageUrls.isEmpty) return '';
    final url = imageUrls.first;
    if (url.startsWith('http')) return url;
    return '${AppConstants.mediaBaseUrl}$url';
  }

  bool get isAvailable => status == ProductStatus.forSale;
  
  // JSON serialization
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Le backend renvoie { images: [{ url: '...' }] }
    final List<dynamic> imagesJson = json['images'] ?? [];
    final List<String> imageUrls = imagesJson
        .map((img) => img['url'] as String)
        .toList();

    // Le backend peut renvoyer l'objet seller
    final seller = json['seller'];
    final String? sellerName = seller != null 
        ? '${seller['firstName']} ${seller['lastName']}'
        : json['sellerName'];

    // Le backend peut renvoyer l'objet category
    final categoryData = json['category'];
    final String categoryName = categoryData is Map 
        ? (categoryData['name'] ?? '') 
        : (categoryData ?? '');
    final String categoryId = categoryData is Map
        ? (categoryData['id'] ?? json['categoryId'] ?? '')
        : (json['categoryId'] ?? '');

    return ProductModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      condition: _conditionFromString(json['condition'] ?? ''),
      status: _statusFromString(json['status'] ?? ''),
      moderationComment: json['moderationComment'],
      category: categoryName,
      categoryId: categoryId,
      size: json['size'] ?? '',
      brand: json['brand'] ?? '',
      imageUrls: imageUrls,
      sellerId: json['sellerId'] ?? '',
      sellerName: sellerName,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      isFavorite: json['isFavorite'] ?? false,
      reviews: (json['reviews'] as List?)?.map((r) => ReviewModel.fromJson(r)).toList() ?? [],
      comments: (json['comments'] as List?)?.map((c) => CommentModel.fromJson(c)).toList() ?? [],
      sellerCity: _extractCity(json['seller']),
    );
  }

  static String? _extractCity(Map<String, dynamic>? seller) {
    if (seller == null || seller['addresses'] == null) return null;
    final addresses = seller['addresses'] as List;
    if (addresses.isEmpty) return null;
    
    // Try to find default address first, else take the first one
    final defaultAddress = addresses.firstWhere(
      (a) => a['isDefault'] == true,
      orElse: () => addresses.first,
    );
    return defaultAddress['city'] as String?;
  }
  
  static ProductCondition _conditionFromString(String value) {
    return ProductCondition.values.firstWhere(
      (e) => e.toString().split('.').last.toUpperCase() == value.replaceAll('_', ''),
      orElse: () => ProductCondition.veryGood,
    );
  }

  static ProductStatus _statusFromString(String value) {
    return ProductStatus.values.firstWhere(
      (e) => e.name.replaceAll(RegExp(r'(?=[A-Z])'), '_').toUpperCase() == value.toUpperCase(),
      orElse: () => ProductStatus.forSale,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'price': price,
    // 'category': category, // Don't send category string to backend, use categoryId
    'categoryId': categoryId,
    'size': size,
    'brand': brand,
    'condition': _conditionToString(condition),
    'status': _statusToString(status),
    'images': imageUrls,
  };
  
  static String _conditionToString(ProductCondition condition) {
    switch (condition) {
      case ProductCondition.newWithTags: return 'NEW_WITH_TAGS';
      case ProductCondition.newWithoutTags: return 'NEW_WITHOUT_TAGS';
      case ProductCondition.veryGood: return 'VERY_GOOD';
      case ProductCondition.good: return 'GOOD';
      case ProductCondition.fair: return 'FAIR';
    }
  }

  static String _statusToString(ProductStatus status) {
    switch (status) {
      case ProductStatus.pendingApproval: return 'PENDING_APPROVAL';
      case ProductStatus.forSale: return 'FOR_SALE';
      case ProductStatus.rejected: return 'REJECTED';
      case ProductStatus.reserved: return 'RESERVED';
      case ProductStatus.sold: return 'SOLD';
    }
  }
  
  // CopyWith
  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    ProductCondition? condition,
    ProductStatus? status,
    String? moderationComment,
    String? category,
    String? categoryId,
    String? size,
    String? brand,
    List<String>? imageUrls,
    String? sellerId,
    String? sellerName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    List<ReviewModel>? reviews,
    List<CommentModel>? comments,
    String? sellerCity,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      status: status ?? this.status,
      moderationComment: moderationComment ?? this.moderationComment,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      reviews: reviews ?? this.reviews,
      comments: comments ?? this.comments,
      sellerCity: sellerCity ?? this.sellerCity,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        title,
        description,
        price,
        condition,
        status,
        moderationComment,
        category,
        categoryId,
        size,
        brand,
        imageUrls,
        sellerId,
        sellerName,
        createdAt,
        updatedAt,
        isFavorite,
        reviews,
        comments,
      ];
}
