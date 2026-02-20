import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_app/core/theme/app_colors.dart';
import 'package:marketplace_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:marketplace_app/shared/models/notification_model.dart';
import 'package:marketplace_app/features/notifications/data/notifications_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.cloviBeige,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.cloviGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () async {
              await ref.read(notificationsServiceProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            },
            tooltip: 'Tout marquer comme lu',
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucune notification pour le moment', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationTile(notification: notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: notification.isRead ? Colors.transparent : AppColors.cloviGreen.withOpacity(0.05),
      child: ListTile(
        leading: _buildIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM HH:mm').format(notification.createdAt),
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        onTap: () async {
          if (!notification.isRead) {
            await ref.read(notificationsServiceProvider).markAsRead(notification.id);
            ref.invalidate(notificationsProvider);
            ref.invalidate(unreadNotificationsCountProvider);
          }
          _handleNavigation(context, notification);
        },
      ),
    );
  }

  Widget _buildIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.productApproved:
        iconData = Icons.check_circle_outline_rounded;
        color = AppColors.cloviGreen;
        break;
      case NotificationType.productRejected:
        iconData = Icons.error_outline_rounded;
        color = Colors.red;
        break;
      case NotificationType.messageReceived:
      case NotificationType.conversationReply:
      case NotificationType.messageRead:
        iconData = Icons.chat_bubble_outline_rounded;
        color = Colors.blue;
        break;
      case NotificationType.orderConfirmed:
      case NotificationType.newOrderReceived:
      case NotificationType.paymentReceived:
        iconData = Icons.shopping_bag_outlined;
        color = Colors.orange;
        break;
      case NotificationType.orderShipped:
      case NotificationType.orderDelivered:
        iconData = Icons.local_shipping_outlined;
        color = Colors.blueGrey;
        break;
      case NotificationType.ratingRequest:
        iconData = Icons.star_outline_rounded;
        color = Colors.amber;
        break;
      case NotificationType.welcome:
        iconData = Icons.person_outline_rounded;
        color = Colors.teal;
        break;
      case NotificationType.securityAlert:
        iconData = Icons.security_rounded;
        color = Colors.deepOrange;
        break;
      case NotificationType.promotion:
        iconData = Icons.campaign_outlined;
        color = Colors.purple;
        break;
      case NotificationType.system:
      default:
        iconData = Icons.notifications_none_rounded;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  void _handleNavigation(BuildContext context, NotificationModel notification) {
    final data = notification.data;
    if (data == null || data['screen'] == null) return;

    final screen = data['screen'];

    switch (screen) {
      case 'chat':
        final conversationId = data['conversationId'];
        if (conversationId != null) {
          context.push('/chat/$conversationId');
        }
        break;
      case 'product_detail':
        final productId = data['productId'];
        if (productId != null) {
          context.push('/product/$productId');
        }
        break;
      case 'order_detail':
        final orderId = data['orderId'];
        if (orderId != null) {
          context.push('/order/$orderId');
        }
        break;
      case 'my_products':
        context.push('/my-products');
        break;
      case 'notifications':
        // Déjà sur l'écran notifications
        break;
      default:
        break;
    }
  }
}
