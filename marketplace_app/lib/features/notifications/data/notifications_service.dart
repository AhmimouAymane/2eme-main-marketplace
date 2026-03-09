import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_app/shared/models/notification_model.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';

final notificationsServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationsService(dio);
});

class NotificationsService {
  final Dio _dio;
  NotificationsService(this._dio);

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get('notifications');
      return (response.data as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('notifications/unread-count');
      // Safely parse count as it might come as a String or int
      return int.tryParse(response.data.toString()) ?? 0;
    } catch (e) {
      print('DEBUG: Error in getUnreadCount: $e');
      return 0;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _dio.patch('notifications/$id/read');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch('notifications/read-all');
    } catch (e) {
      rethrow;
    }
  }
}
