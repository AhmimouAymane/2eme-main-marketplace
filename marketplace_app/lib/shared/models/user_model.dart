import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'product_model.dart';
import 'address_model.dart';
import 'user_review_model.dart';

enum UserRole {
  @JsonValue('USER')
  user,
  @JsonValue('ADMIN')
  admin,
}

enum SellerStatus {
  @JsonValue('NOT_SUBMITTED')
  notSubmitted,
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
}

@JsonSerializable()
class VerificationDocumentModel extends Equatable {
  final String id;
  final String fileType;
  final String fileName;
  final DateTime createdAt;

  const VerificationDocumentModel({
    required this.id,
    required this.fileType,
    required this.fileName,
    required this.createdAt,
  });

  factory VerificationDocumentModel.fromJson(Map<String, dynamic> json) =>
      VerificationDocumentModel(
        id: json['id'] as String? ?? '',
        fileType: json['fileType'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileType': fileType,
        'fileName': fileName,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, fileType, fileName, createdAt];
}

/// Modèle de données pour un utilisateur
@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final List<AddressModel>? addresses;
  final String? avatarUrl;
  final String? bio;
  final List<ProductModel>? products;
  final List<UserReviewModel>? receivedReviews;
  final int salesCount;
  final double averageRating;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSellerVerified;
  final SellerStatus sellerStatus;
  final String? verificationComment;
  final List<VerificationDocumentModel>? verificationDocuments;
  
  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.addresses,
    this.avatarUrl,
    this.bio,
    this.products,
    this.receivedReviews,
    this.salesCount = 0,
    this.averageRating = 0.0,
    required this.role,
    required this.createdAt,
    this.updatedAt,
    this.isSellerVerified = false,
    this.sellerStatus = SellerStatus.notSubmitted,
    this.verificationComment,
    this.verificationDocuments,
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
        addresses: json['addresses'] != null
            ? (json['addresses'] as List)
                .map((a) => AddressModel.fromJson(a as Map<String, dynamic>))
                .toList()
            : null,
        avatarUrl: json['avatarUrl'] as String?,
        bio: json['bio'] as String?,
        products: json['products'] != null
            ? (json['products'] as List)
                .map((p) => ProductModel.fromJson(p))
                .toList()
            : null,
        receivedReviews: json['receivedReviews'] != null
            ? (json['receivedReviews'] as List)
                .map((r) => UserReviewModel.fromJson(r as Map<String, dynamic>))
                .toList()
            : null,
        salesCount: json['salesCount'] as int? ?? 0,
        averageRating: (json['averageRating'] ?? 0.0).toDouble(),
        role: _roleFromString(json['role'] as String? ?? 'USER'),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
        updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
        isSellerVerified: json['isSellerVerified'] as bool? ?? false,
        sellerStatus: _sellerStatusFromString(json['sellerStatus'] as String? ?? 'NOT_SUBMITTED'),
        verificationComment: json['verificationComment'] as String?,
        verificationDocuments: json['verificationDocuments'] != null
            ? (json['verificationDocuments'] as List)
                .map((d) => VerificationDocumentModel.fromJson(d as Map<String, dynamic>))
                .toList()
            : null,
      );
  
  static UserRole _roleFromString(String role) {
    if (role == 'ADMIN') return UserRole.admin;
    return UserRole.user;
  }

  static SellerStatus _sellerStatusFromString(String status) {
    switch (status) {
      case 'PENDING': return SellerStatus.pending;
      case 'APPROVED': return SellerStatus.approved;
      case 'REJECTED': return SellerStatus.rejected;
      default: return SellerStatus.notSubmitted;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'addresses': addresses?.map((a) => a.toJson()).toList(),
        'avatarUrl': avatarUrl,
        'bio': bio,
        'salesCount': salesCount,
        'averageRating': averageRating,
        'role': role.name.toUpperCase(),
        'isSellerVerified': isSellerVerified,
        'sellerStatus': sellerStatus.name.toUpperCase(),
        'verificationComment': verificationComment,
        'verificationDocuments': verificationDocuments?.map((d) => d.toJson()).toList(),
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
    List<AddressModel>? addresses,
    String? avatarUrl,
    String? bio,
    List<ProductModel>? products,
    List<UserReviewModel>? receivedReviews,
    int? salesCount,
    double? averageRating,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSellerVerified,
    SellerStatus? sellerStatus,
    String? verificationComment,
    List<VerificationDocumentModel>? verificationDocuments,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      addresses: addresses ?? this.addresses,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      products: products ?? this.products,
      receivedReviews: receivedReviews ?? this.receivedReviews,
      salesCount: salesCount ?? this.salesCount,
      averageRating: averageRating ?? this.averageRating,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSellerVerified: isSellerVerified ?? this.isSellerVerified,
      sellerStatus: sellerStatus ?? this.sellerStatus,
      verificationComment: verificationComment ?? this.verificationComment,
      verificationDocuments: verificationDocuments ?? this.verificationDocuments,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phone,
        addresses,
        avatarUrl,
        bio,
        products,
        receivedReviews,
        createdAt,
        updatedAt,
        isSellerVerified,
        sellerStatus,
        verificationComment,
        verificationDocuments,
      ];
}
