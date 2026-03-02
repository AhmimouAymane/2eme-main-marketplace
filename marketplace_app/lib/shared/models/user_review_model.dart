import 'package:equatable/equatable.dart';
import 'user_model.dart';

class UserReviewModel extends Equatable {
  final String id;
  final int rating;
  final String? comment;
  final String reviewerId;
  final UserModel? reviewer;
  final String targetUserId;
  final String orderId;
  final DateTime createdAt;

  const UserReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.reviewerId,
    this.reviewer,
    required this.targetUserId,
    required this.orderId,
    required this.createdAt,
  });

  factory UserReviewModel.fromJson(Map<String, dynamic> json) => UserReviewModel(
        id: json['id'] ?? '',
        rating: json['rating'] ?? 0,
        comment: json['comment'],
        reviewerId: json['reviewerId'] ?? '',
        reviewer: json['reviewer'] != null ? UserModel.fromJson(json['reviewer']) : null,
        targetUserId: json['targetUserId'] ?? '',
        orderId: json['orderId'] ?? '',
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rating': rating,
        'comment': comment,
        'reviewerId': reviewerId,
        'targetUserId': targetUserId,
        'orderId': orderId,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, rating, comment, reviewerId, reviewer, targetUserId, orderId, createdAt];
}
