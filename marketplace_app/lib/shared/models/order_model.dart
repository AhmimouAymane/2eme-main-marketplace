import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'product_model.dart';
import 'user_model.dart';

/// Statut d'une commande (Synchronisé avec le backend)
enum OrderStatus {
  @JsonValue('OFFER_MADE')
  offerMade,
  @JsonValue('AWAITING_SELLER_CONFIRMATION')
  awaitingSellerConfirmation,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('SHIPPED')
  shipped,
  @JsonValue('DELIVERED')
  delivered,
  @JsonValue('RETURN_WINDOW_48H')
  returnWindow48h,
  @JsonValue('RETURN_REQUESTED')
  returnRequested,
  @JsonValue('RETURNED')
  returned,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('COMPLETED')
  completed,
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
  final String? rejectionReason;
  final String? cancellationReason;
  final String? returnReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? returnRequestedAt;
  final DateTime? returnedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;

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
    this.rejectionReason,
    this.cancellationReason,
    this.returnReason,
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.returnRequestedAt,
    this.returnedAt,
    this.completedAt,
    this.expiresAt,
  });

  // Getters
  bool get isOffer => status == OrderStatus.offerMade;
  bool get isAwaitingConfirmation => status == OrderStatus.awaitingSellerConfirmation;
  bool get isConfirmed => status == OrderStatus.confirmed;
  bool get isShipped => status == OrderStatus.shipped;
  bool get isDelivered => status == OrderStatus.delivered || status == OrderStatus.returnWindow48h;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
  bool get canCancel =>
      status == OrderStatus.awaitingSellerConfirmation || status == OrderStatus.confirmed || status == OrderStatus.offerMade;
  bool get isInReturnWindow => status == OrderStatus.returnWindow48h;

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
    status: _statusFromString(json['status'] ?? 'AWAITING_SELLER_CONFIRMATION'),
    shippingAddress: json['shippingAddress'],
    pickupAddress: json['pickupAddress'],
    rejectionReason: json['rejectionReason'],
    cancellationReason: json['cancellationReason'],
    returnReason: json['returnReason'],
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : null,
    confirmedAt: json['confirmedAt'] != null
        ? DateTime.parse(json['confirmedAt'])
        : null,
    shippedAt: json['shippedAt'] != null
        ? DateTime.parse(json['shippedAt'])
        : null,
    deliveredAt: json['deliveredAt'] != null
        ? DateTime.parse(json['deliveredAt'])
        : null,
    returnRequestedAt: json['returnRequestedAt'] != null
        ? DateTime.parse(json['returnRequestedAt'])
        : null,
    returnedAt: json['returnedAt'] != null
        ? DateTime.parse(json['returnedAt'])
        : null,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
    expiresAt: json['expiresAt'] != null
        ? DateTime.parse(json['expiresAt'])
        : null,
  );

  static OrderStatus _statusFromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) {
        // Convert camelCase (e.g. returnWindow48h) to SCREAMING_SNAKE_CASE (e.g. RETURN_WINDOW_48_H)
        // Note: Backend has RETURN_WINDOW_48H, our previous logic gave RETURN_WINDOW48_H
        final enumName = e.name
            .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)}')
            .replaceAllMapped(RegExp(r'(\d+)'), (match) => '_${match.group(1)}')
            .toUpperCase();
            
        return enumName == status || 
               e.name.toUpperCase() == status || 
               // Also check for cases where the digit doesn't have an underscore (flexible matching)
               enumName.replaceAll('_', '') == status.replaceAll('_', '');
      },
      orElse: () => OrderStatus.awaitingSellerConfirmation,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'productId': productId,
      'totalPrice': totalPrice,
    };

    final enumName = status.name.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)}',
    ).toUpperCase();
    
    map['status'] = enumName;

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
    String? rejectionReason,
    String? cancellationReason,
    String? returnReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? returnRequestedAt,
    DateTime? returnedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
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
      rejectionReason: rejectionReason ?? this.rejectionReason,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      returnReason: returnReason ?? this.returnReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      returnRequestedAt: returnRequestedAt ?? this.returnRequestedAt,
      returnedAt: returnedAt ?? this.returnedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
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
    rejectionReason,
    cancellationReason,
    returnReason,
    createdAt,
    updatedAt,
    confirmedAt,
    shippedAt,
    deliveredAt,
    returnRequestedAt,
    returnedAt,
    completedAt,
    expiresAt,
  ];
}
