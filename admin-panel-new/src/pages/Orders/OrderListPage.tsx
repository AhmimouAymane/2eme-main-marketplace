import React, { useEffect, useState } from 'react';
import { Table, Typography, message, Button, Space, Tag } from 'antd';
import { apiClient } from '../../api/api-client';
import { Order, OrderStatus } from '../../types';

const { Title } = Typography;

const OrderListPage: React.FC = () => {
    const [orders, setOrders] = useState<Order[]>([]);
    const [loading, setLoading] = useState(false);

    const fetchOrders = async () => {
        setLoading(true);
        try {
            const response: any = await apiClient.get('orders').json();
            const data = Array.isArray(response) ? response : response.data || [];
            setOrders(data);
        } catch (error) {
            message.error('Failed to load orders');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchOrders();
    }, []);

    const columns = [
        {
            title: 'Order ID',
            dataIndex: 'id',
            key: 'id',
            render: (id: string) => <code>{id.substring(0, 8)}...</code>
        },
        {
            title: 'Product',
            dataIndex: 'product',
            key: 'product',
            render: (product: any) => product?.title || '-'
        },
        {
            title: 'Price',
            dataIndex: 'totalPrice',
            key: 'totalPrice',
            render: (price: number) => `${price} MAD`
        },
        {
            title: 'Buyer',
            dataIndex: 'buyer',
            key: 'buyer',
            render: (buyer: any) => `${buyer?.firstName} ${buyer?.lastName}`
        },
        {
            title: 'Seller',
            dataIndex: 'seller',
            key: 'seller',
            render: (seller: any) => `${seller?.firstName} ${seller?.lastName}`
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            render: (status: OrderStatus) => {
                const colors: Record<OrderStatus, string> = {
                    [OrderStatus.OFFER_MADE]: 'blue',
                    [OrderStatus.AWAITING_SELLER_CONFIRMATION]: 'gold',
                    [OrderStatus.CONFIRMED]: 'cyan',
                    [OrderStatus.SHIPPED]: 'purple',
                    [OrderStatus.DELIVERED]: 'green',
                    [OrderStatus.RETURN_WINDOW_48H]: 'lime',
                    [OrderStatus.RETURN_REQUESTED]: 'orange',
                    [OrderStatus.RETURNED]: 'volcano',
                    [OrderStatus.CANCELLED]: 'red',
                    [OrderStatus.COMPLETED]: 'geekblue',
                };
                return <Tag color={colors[status] || 'default'}>{status ? status.replace(/_/g, ' ') : 'UNKNOWN'}</Tag>;
            }
        },
        {
            title: 'Date',
            dataIndex: 'createdAt',
            key: 'createdAt',
            render: (date: string) => new Date(date).toLocaleDateString()
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, record: Order) => (
                <Space>
                    <Button type="link" onClick={() => message.info(`Details for order ${record.id}`)}>Details</Button>
                </Space>
            )
        }
    ];

    return (
        <div>
            <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Title level={2} style={{ margin: 0 }}>Orders</Title>
                <Button onClick={fetchOrders} loading={loading}>Refresh</Button>
            </div>
            <Table
                columns={columns}
                dataSource={orders}
                rowKey="id"
                loading={loading}
            />
        </div>
    );
};

export default OrderListPage;
