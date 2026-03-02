import React, { useEffect, useState } from 'react';
import { Table, Typography, message, Button, Space, Tag, Modal, Descriptions, Divider, Avatar } from 'antd';
const { Title, Text } = Typography;
import { apiClient } from '../../api/api-client';
import { Order, OrderStatus } from '../../types';
import { API_URL } from '../../theme/constants';

const OrderListPage: React.FC = () => {
    const [orders, setOrders] = useState<Order[]>([]);
    const [loading, setLoading] = useState(false);
    const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);
    const [isModalVisible, setIsModalVisible] = useState(false);

    const MEDIA_URL = API_URL.replace('/api/v1', '/uploads/');

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
                    <Button
                        type="primary"
                        size="small"
                        onClick={() => {
                            setSelectedOrder(record);
                            setIsModalVisible(true);
                        }}
                    >
                        Détails
                    </Button>
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

            <Modal
                title={`Détails de la commande #${selectedOrder?.id.substring(0, 8)}`}
                open={isModalVisible}
                onCancel={() => setIsModalVisible(false)}
                footer={[
                    <Button key="close" onClick={() => setIsModalVisible(false)}>
                        Fermer
                    </Button>
                ]}
                width={800}
            >
                {selectedOrder && (
                    <div style={{ padding: '10px 0' }}>
                        <Descriptions title="Informations Produit" bordered column={1}>
                            <Descriptions.Item label="Produit">
                                <Space>
                                    <Avatar
                                        shape="square"
                                        size={64}
                                        src={selectedOrder.product?.images?.[0]?.url.startsWith('http')
                                            ? selectedOrder.product.images[0].url
                                            : `${MEDIA_URL}${selectedOrder.product?.images?.[0]?.url}`}
                                    />
                                    <div>
                                        <div style={{ fontWeight: 'bold' }}>{selectedOrder.product?.title}</div>
                                        <Tag color="green">{selectedOrder.product?.price} MAD</Tag>
                                    </div>
                                </Space>
                            </Descriptions.Item>
                            <Descriptions.Item label="Prix de la transaction">
                                <span style={{ fontWeight: 'bold', color: '#10b981' }}>{selectedOrder.totalPrice} MAD</span>
                            </Descriptions.Item>
                        </Descriptions>

                        <Divider />

                        <Descriptions title="Acteurs" bordered column={2}>
                            <Descriptions.Item label="Acheteur">
                                {selectedOrder.buyer?.firstName} {selectedOrder.buyer?.lastName}<br />
                                <small style={{ color: '#888' }}>{selectedOrder.buyer?.email}</small>
                            </Descriptions.Item>
                            <Descriptions.Item label="Vendeur">
                                {selectedOrder.seller?.firstName} {selectedOrder.seller?.lastName}<br />
                                <small style={{ color: '#888' }}>{selectedOrder.seller?.email}</small>
                            </Descriptions.Item>
                        </Descriptions>

                        <Divider />

                        <Descriptions title="Logistique" bordered column={1}>
                            <Descriptions.Item label="Adresse de livraison (Acheteur)">
                                {selectedOrder.shippingAddress || 'Non spécifiée'}
                            </Descriptions.Item>
                            <Descriptions.Item label="Adresse de ramassage (Vendeur)">
                                {selectedOrder.pickupAddress || 'En attente de confirmation'}
                            </Descriptions.Item>
                        </Descriptions>

                        <Divider />

                        <Descriptions title="Statut & Historique" bordered column={2}>
                            <Descriptions.Item label="Statut Actuel">
                                <Tag color="blue">{selectedOrder.status.replace(/_/g, ' ')}</Tag>
                            </Descriptions.Item>
                            <Descriptions.Item label="Date de création">
                                {new Date(selectedOrder.createdAt).toLocaleString()}
                            </Descriptions.Item>
                            {selectedOrder.rejectionReason && (
                                <Descriptions.Item label="Raison du rejet" span={2}>
                                    <Text type="danger">{selectedOrder.rejectionReason}</Text>
                                </Descriptions.Item>
                            )}
                            {selectedOrder.cancellationReason && (
                                <Descriptions.Item label="Raison de l'annulation" span={2}>
                                    <Text type="danger">{selectedOrder.cancellationReason}</Text>
                                </Descriptions.Item>
                            )}
                        </Descriptions>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default OrderListPage;
