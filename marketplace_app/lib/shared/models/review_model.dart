import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

@JsonSerializable()
class ReviewModel extends Equatable {
  final String id;
  final int rating;
  final String? comment;
  final String userId;
  final UserModel? user;
  final String productId;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.userId,
    this.user,
    required this.productId,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    id: json['id'] ?? '',
    rating: json['rating'] ?? 0,
    comment: json['comment'],
    userId: json['userId'] ?? '',
    user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    productId: json['productId'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'rating': rating,
    'comment': comment,
  };

  @override
  List<Object?> get props => [id, rating, comment, userId, user, productId, createdAt];
}
