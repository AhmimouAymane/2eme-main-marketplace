import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_app/shared/models/notification_model.dart';
import 'package:marketplace_app/features/notifications/data/notifications_service.dart';

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final service = ref.watch(notificationsServiceProvider);
  return service.getNotifications();
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ref.watch(notificationsServiceProvider);
  return service.getUnreadCount();
});
