enum NotificationType {
  productApproved,
  productRejected,
  productPending,
  similarProductPosted,
  messageReceived,
  messageRead,
  conversationReply,
  orderConfirmed,
  orderShipped,
  orderDelivered,
  newOrderReceived,
  paymentReceived,
  ratingRequest,
  welcome,
  securityAlert,
  promotion,
  sellerVerified,
  sellerRejected,
  newReviewReceived,
  newCommentReceived,
  commentReplyReceived,
  system;

  String toJson() => name.toUpperCase();
  static NotificationType fromJson(String json) {
    // Nettoyer la chaîne (enlever les underscores, tout mettre en minuscule)
    final cleanJson = json.toLowerCase().replaceAll('_', '');
    try {
      return NotificationType.values.firstWhere(
        (e) => e.name.toLowerCase() == cleanJson,
      );
    } catch (_) {
      // Fallbacks pour les anciens types ou types inconnus
      if (cleanJson.contains('order')) return NotificationType.newOrderReceived;
      if (cleanJson.contains('message')) return NotificationType.messageReceived;
      return NotificationType.system;
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.fromJson(json['type']),
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      isRead: json['isRead'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toJson(),
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
