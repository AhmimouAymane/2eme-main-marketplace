import 'package:equatable/equatable.dart';
import 'user_model.dart';

class UserReviewModel extends Equatable {
  final String id;
  final int rating;
  final String? comment;
  final String reviewerId;
  final UserModel? reviewer;
  final String targetUserId;
  final UserModel? targetUser;
  final String orderId;
  final DateTime createdAt;

  const UserReviewModel({
    required this.id,
    required this.rating,
    this.comment,
    required this.reviewerId,
    this.reviewer,
    required this.targetUserId,
    this.targetUser,
    required this.orderId,
    required this.createdAt,
  });

  factory UserReviewModel.fromJson(Map<String, dynamic> json) => UserReviewModel(
        id: json['id'] ?? '',
        rating: json['rating'] ?? 0,
        comment: json['comment'],
        reviewerId: json['reviewerId'] ?? '',
        targetUserId: json['targetUserId'] ?? '',
        orderId: json['orderId'] ?? '',
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        reviewer: json['reviewer'] != null ? UserModel.fromJson(json['reviewer']) : null,
        targetUser: json['targetUser'] != null ? UserModel.fromJson(json['targetUser']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'rating': rating,
        'comment': comment,
        'reviewerId': reviewerId,
        'targetUserId': targetUserId,
        'orderId': orderId,
        'createdAt': createdAt.toIso8601String(),
        'reviewer': reviewer?.toJson(),
        'targetUser': targetUser?.toJson(),
      };

  @override
  List<Object?> get props => [id, rating, comment, reviewerId, reviewer, targetUser, targetUserId, orderId, createdAt];
}
