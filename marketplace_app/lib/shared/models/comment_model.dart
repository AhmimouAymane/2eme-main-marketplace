import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

@JsonSerializable()
class CommentModel extends Equatable {
  final String id;
  final String content;
  final String userId;
  final UserModel? user;
  final String productId;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.content,
    required this.userId,
    this.user,
    required this.productId,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: json['id'] ?? '',
    content: json['content'] ?? '',
    userId: json['userId'] ?? '',
    user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    productId: json['productId'] ?? '',
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'content': content,
  };

  @override
  List<Object?> get props => [id, content, userId, user, productId, createdAt];
}
