import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'product_model.dart';
import 'user_model.dart';

/// Statut d'une commande (Synchronisé avec le backend)
enum OrderStatus {
  @JsonValue('OFFER_PENDING')
  offerPending,
  @JsonValue('OFFER_REJECTED')
  offerRejected,
  @JsonValue('PENDING')
  pending,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('SHIPPED')
  shipped,
  @JsonValue('DELIVERED')
  delivered,
  @JsonValue('CANCELLED')
  cancelled,
  returnRequested,
}

/// Modèle de données pour une commande
@JsonSerializable()
class OrderModel extends Equatable {
  final String id;
  final String productId;
  final ProductModel? product;
  final String buyerId;
  final UserModel? buyer;
  final String sellerId;
  final UserModel? seller;
  final double totalPrice;
  final OrderStatus status;
  final String? shippingAddress;
  final String? pickupAddress;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String? rejectionReason;

  const OrderModel({
    required this.id,
    required this.productId,
    this.product,
    required this.buyerId,
    this.buyer,
    required this.sellerId,
    this.seller,
    required this.totalPrice,
    required this.status,
    this.shippingAddress,
    this.pickupAddress,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.rejectionReason,
  });

  // Getters
  bool get isOffer => status == OrderStatus.offerPending;
  bool get isPending => status == OrderStatus.pending;
  bool get isCompleted => status == OrderStatus.delivered;
  bool get isRejected => status == OrderStatus.offerRejected;
  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed || status == OrderStatus.offerPending;

  // JSON serialization
  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'] ?? '',
    productId: json['productId'] ?? '',
    product: json['product'] != null
        ? ProductModel.fromJson(json['product'])
        : null,
    buyerId: json['buyerId'] ?? '',
    buyer: json['buyer'] != null ? UserModel.fromJson(json['buyer']) : null,
    sellerId: json['sellerId'] ?? '',
    seller: json['seller'] != null ? UserModel.fromJson(json['seller']) : null,
    totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
    status: _statusFromString(json['status'] ?? 'PENDING'),
    shippingAddress: json['shippingAddress'],
    pickupAddress: json['pickupAddress'],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : null,
    deliveredAt: json['deliveredAt'] != null
        ? DateTime.parse(json['deliveredAt'])
        : null,
    rejectionReason: json['rejectionReason'],
  );

  static OrderStatus _statusFromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) {
        // Mapping convention: offerPending -> OFFER_PENDING
        final enumName = e.name.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)}',
        ).toUpperCase();
        return enumName == status || e.name.toUpperCase() == status;
      },
      orElse: () => OrderStatus.pending,
    );
  }

  /// Payload pour la création de commande (le backend définit status lui-même)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'productId': productId,
      'totalPrice': totalPrice,
    };

    if (status != OrderStatus.pending) {
       // Only send status if it's explicitly set (like for offers)
       final enumName = status.name.replaceAllMapped(
         RegExp(r'([A-Z])'),
         (match) => '_${match.group(1)}',
       ).toUpperCase();
       
       if (status == OrderStatus.offerPending || status == OrderStatus.offerRejected) {
         map['status'] = enumName;
       }
    }

    if (shippingAddress != null) {
      map['shippingAddress'] = shippingAddress;
    }
    if (pickupAddress != null) {
      map['pickupAddress'] = pickupAddress;
    }

    return map;
  }

  // CopyWith
  OrderModel copyWith({
    String? id,
    String? productId,
    ProductModel? product,
    String? buyerId,
    UserModel? buyer,
    String? sellerId,
    UserModel? seller,
    double? totalPrice,
    OrderStatus? status,
    String? shippingAddress,
    String? pickupAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    String? rejectionReason,
  }) {
    return OrderModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      buyerId: buyerId ?? this.buyerId,
      buyer: buyer ?? this.buyer,
      sellerId: sellerId ?? this.sellerId,
      seller: seller ?? this.seller,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    product,
    buyerId,
    buyer,
    sellerId,
    seller,
    totalPrice,
    status,
    shippingAddress,
    pickupAddress,
    createdAt,
    updatedAt,
    deliveredAt,
    rejectionReason,
  ];
}
