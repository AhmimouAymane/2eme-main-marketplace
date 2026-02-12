import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:marketplace_app/shared/models/product_model.dart';
import 'package:marketplace_app/shared/models/user_model.dart';

/// Modèle pour un message de conversation
@JsonSerializable()
class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        createdAt,
        isRead,
      ];
}

/// Modèle pour une conversation
@JsonSerializable()
class ConversationModel extends Equatable {
  final String id;
  final String productId;
  final ProductModel? product;
  final String buyerId;
  final UserModel? buyer;
  final String sellerId;
  final UserModel? seller;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;
  final List<MessageModel> messages;

  const ConversationModel({
    required this.id,
    required this.productId,
    this.product,
    required this.buyerId,
    this.buyer,
    required this.sellerId,
    this.seller,
    required this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
    this.messages = const [],
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      product:
          json['product'] != null ? ProductModel.fromJson(json['product']) : null,
      buyerId: json['buyerId'] ?? '',
      buyer: json['buyer'] != null ? UserModel.fromJson(json['buyer']) : null,
      sellerId: json['sellerId'] ?? '',
      seller:
          json['seller'] != null ? UserModel.fromJson(json['seller']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      messages: (json['messages'] as List<dynamic>? ?? [])
          .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
          .toList(),
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
        createdAt,
        updatedAt,
        lastMessageAt,
        messages,
      ];
}

