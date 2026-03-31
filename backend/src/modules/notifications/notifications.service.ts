import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationType } from '@prisma/client';

@Injectable()
export class NotificationsService {
    constructor(
        private prisma: PrismaService,
        @Inject('FIREBASE_ADMIN') private firebaseAdmin: any,
    ) { }

    async findAll(userId: string) {
        return this.prisma.notification.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            take: 50,
        });
    }

    async create(notificationData: {
        userId: string;
        title: string;
        message: string;
        type: NotificationType;
        data?: any;
    }) {
        // 1. Save to database
        const notification = await this.prisma.notification.create({
            data: {
                userId: notificationData.userId,
                title: notificationData.title,
                message: notificationData.message,
                type: notificationData.type,
                data: notificationData.data || {},
            },
        });

        // 2. Send push notification if user has an fcmToken
        const user = await this.prisma.user.findUnique({
            where: { id: notificationData.userId },
            select: { fcmToken: true },
        });

        if (user?.fcmToken) {
            console.log(`DEBUG: [FCM] Sending push to user ${notificationData.userId} (Token: ${user.fcmToken.substring(0, 10)}...)`);
            try {
                const response = await this.firebaseAdmin.messaging().send({
                    token: user.fcmToken,
                    notification: {
                        title: notificationData.title,
                        body: notificationData.message,
                    },
                    // Android-specific configuration for popups
                    android: {
                        priority: 'high',
                        notification: {
                            channelId: 'high_importance_channel',
                            priority: 'high',
                            sound: 'default',
                        },
                    },
                    // iOS/APNS configuration for popups
                    apns: {
                        payload: {
                            aps: {
                                alert: {
                                    title: notificationData.title,
                                    body: notificationData.message,
                                },
                                sound: 'default',
                                badge: 1,
                            },
                        },
                    },
                    // Flutter read "data" as Map<String, dynamic>
                    // All values MUST be Strings for FCM data payload
                    data: {
                        type: notificationData.type,
                        targetUserId: notificationData.userId,
                        ...(notificationData.data ?
                            Object.entries(notificationData.data).reduce((acc, [k, v]) => ({
                                ...acc, [k]: String(v)
                            }), {}) : {}
                        ),
                    },
                });
                console.log('DEBUG: [FCM] Push sent successfully:', response);
            } catch (error) {
                console.error('DEBUG: [FCM] Push Error:', error);
            }
        } else {
            console.log(`DEBUG: [FCM] Skip push for user ${notificationData.userId}: No fcmToken found in database.`);
        }

        return notification;
    }

    async markAsRead(id: string, userId: string) {
        return this.prisma.notification.updateMany({
            where: { id, userId },
            data: { isRead: true },
        });
    }

    async markAllAsRead(userId: string) {
        return this.prisma.notification.updateMany({
            where: { userId, isRead: false },
            data: { isRead: true },
        });
    }

    async getUnreadCount(userId: string) {
        return this.prisma.notification.count({
            where: { userId, isRead: false },
        });
    }
}
