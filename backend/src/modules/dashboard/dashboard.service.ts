import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ProductStatus, OrderStatus } from '@prisma/client';

@Injectable()
export class DashboardService {
    constructor(private readonly prisma: PrismaService) { }

    async getStats() {
        const [
            totalRevenueData,
            activeListings,
            totalUsers,
            pendingModeration,
            recentProducts,
            recentOrders,
        ] = await Promise.all([
            // Total Revenue (Completed Orders)
            this.prisma.order.aggregate({
                where: { status: OrderStatus.COMPLETED },
                _sum: { totalPrice: true },
            }),
            // Active Listings (Published)
            this.prisma.product.count({
                where: { status: ProductStatus.PUBLISHED },
            }),
            // Total Users
            this.prisma.user.count(),
            // Pending Moderation (Pending Approval)
            this.prisma.product.count({
                where: { status: ProductStatus.PENDING_APPROVAL },
            }),
            // Recent Activities - Products
            this.prisma.product.findMany({
                take: 3,
                orderBy: { createdAt: 'desc' },
                include: { seller: true },
            }),
            // Recent Activities - Orders
            this.prisma.order.findMany({
                take: 3,
                orderBy: { createdAt: 'desc' },
                include: { buyer: true, product: true },
            }),
        ]);

        // Format recent activities
        const activities = [
            ...recentProducts.map((p) => ({
                id: `p-${p.id}`,
                user: `${p.seller?.firstName || 'User'} ${p.seller?.lastName || ''}`.trim(),
                action: 'a créé une nouvelle annonce',
                item: p.title,
                time: p.createdAt,
                status: p.status === 'PUBLISHED' ? 'SUCCESS' : 'PENDING',
            })),
            ...recentOrders.map((o) => ({
                id: `o-${o.id}`,
                user: `${o.buyer?.firstName || 'User'} ${o.buyer?.lastName || ''}`.trim(),
                action: o.status === 'COMPLETED' ? 'a terminé un achat' : 'a passé une commande',
                item: o.product?.title || 'Produit',
                time: o.createdAt,
                status: o.status === 'COMPLETED' ? 'SUCCESS' : 'PENDING',
            })),
        ].sort((a, b) => b.time.getTime() - a.time.getTime()).slice(0, 5);

        // Sales Growth (Last 12 months)
        const now = new Date();
        const months = Array.from({ length: 12 }, (_, i) => {
            const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
            return {
                start: d,
                end: new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59),
                label: d.toLocaleString('fr-FR', { month: 'short' }),
            };
        }).reverse();

        const salesGrowth = [];
        for (const m of months) {
            const result = await this.prisma.order.aggregate({
                where: {
                    status: OrderStatus.COMPLETED,
                    createdAt: {
                        gte: m.start,
                        lte: m.end,
                    },
                },
                _sum: { totalPrice: true },
            });
            salesGrowth.push({
                month: m.label,
                value: result._sum.totalPrice || 0,
            });
        }

        // Trends (Mocked for now as we don't have historical snapshots easily, 
        // but we could compare with last month if needed)

        return {
            stats: [
                { title: 'Chiffre d\'affaires', value: `${(totalRevenueData._sum.totalPrice || 0).toLocaleString()} MAD`, icon: 'DollarSign', color: '#6366f1', trend: '+12.5%' },
                { title: 'Annonces Actives', value: activeListings.toString(), icon: 'ShoppingBag', color: '#10b981', trend: '+5.2%' },
                { title: 'Utilisateurs Totaux', value: totalUsers.toString(), icon: 'Users', color: '#f59e0b', trend: '+18.4%' },
                { title: 'En Attente de Modération', value: pendingModeration.toString(), icon: 'AlertCircle', color: '#ef4444', trend: (pendingModeration > 0 ? `+${pendingModeration}` : '0') },
            ],
            activities,
            salesGrowth,
            pendingCount: pendingModeration,
        };
    }
}
