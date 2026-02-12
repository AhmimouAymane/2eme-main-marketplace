import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'product_model.dart';

enum UserRole {
  @JsonValue('USER')
  user,
  @JsonValue('ADMIN')
  admin,
}

/// Modèle de données pour un utilisateur
@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final List<ProductModel>? products;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.products,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });
  
  // Getters
  String get fullName => '$firstName $lastName';
  
  // JSON serialization
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      UserModel(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        products: json['products'] != null
            ? (json['products'] as List)
                .map((p) => ProductModel.fromJson(p))
                .toList()
            : null,
        role: _roleFromString(json['role'] as String? ?? 'USER'),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
        updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
      );
  
  static UserRole _roleFromString(String role) {
    if (role == 'ADMIN') return UserRole.admin;
    return UserRole.user;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'bio': bio,
        'role': role.name.toUpperCase(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };
  
  // CopyWith
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phone,
        avatarUrl,
        bio,
        products,
        createdAt,
        updatedAt,
      ];
}
