import React, { useEffect, useState } from 'react';
import { Table, Tag, Space, Button, message, Select, Image, Typography, Modal, Input } from 'antd';
import { RefreshCw, CheckCircle, XCircle } from 'lucide-react';
import { apiClient } from '../../api/api-client';
import { Product, ProductStatus } from '../../types';
import { APP_NAME } from '../../theme/constants';

const { Title } = Typography;

const ProductListPage: React.FC = () => {
    const [products, setProducts] = useState<Product[]>([]);
    const [loading, setLoading] = useState(false);
    const [total, setTotal] = useState(0);
    const [rejectModalVisible, setRejectModalVisible] = useState(false);
    const [selectedProductId, setSelectedProductId] = useState<string | null>(null);
    const [rejectionReason, setRejectionReason] = useState('');
    const [submitting, setSubmitting] = useState(false);

    const fetchProducts = async () => {
        setLoading(true);
        try {
            const response: any = await apiClient.get('products', {
                searchParams: { isAdminView: 'true' }
            }).json();
            const data = Array.isArray(response) ? response : response.data || [];
            const count = response.total !== undefined ? response.total : data.length;

            setProducts(data);
            setTotal(count);
        } catch (error) {
            message.error('Failed to load products');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchProducts();
    }, []);

    const handleStatusChange = async (id: string, status: ProductStatus, moderationComment?: string) => {
        try {
            await apiClient.patch(`products/${id}/status`, {
                json: { status, moderationComment }
            }).json();
            message.success(`Product status updated to ${status}`);
            fetchProducts();
        } catch (error) {
            message.error('Failed to update product status');
        }
    };

    const showRejectModal = (id: string) => {
        setSelectedProductId(id);
        setRejectionReason('');
        setRejectModalVisible(true);
    };

    const handleRejectSubmit = async () => {
        if (!selectedProductId) return;
        setSubmitting(true);
        await handleStatusChange(selectedProductId, ProductStatus.REJECTED, rejectionReason);
        setSubmitting(false);
        setRejectModalVisible(false);
    };

    const [detailsModalVisible, setDetailsModalVisible] = useState(false);
    const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);

    const showDetailsModal = (product: Product) => {
        setSelectedProduct(product);
        setDetailsModalVisible(true);
    };

    const columns = [
        {
            title: 'Image',
            dataIndex: 'images',
            key: 'image',
            render: (_: any, record: Product) => {
                const imageUrls = record.imageUrls || record.images?.map(img => img.url) || [];
                const mainImage = imageUrls[0];
                return <Image src={mainImage} width={50} height={50} style={{ width: 50, height: 50, objectFit: 'cover', borderRadius: 4 }} fallback="https://via.placeholder.com/50" />;
            }
        },
        {
            title: 'Title',
            dataIndex: 'title',
            key: 'title',
            render: (text: string) => <strong>{text}</strong>
        },
        {
            title: 'Price',
            dataIndex: 'price',
            key: 'price',
            render: (price: number) => `${price} MAD`
        },
        {
            title: 'Seller',
            dataIndex: 'seller',
            key: 'seller',
            render: (seller: any) => seller ? `${seller.firstName} ${seller.lastName}` : '-'
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            render: (status: ProductStatus) => {
                const colors = {
                    PENDING_APPROVAL: 'orange',
                    PUBLISHED: 'green',
                    SOLD: 'blue',
                    RESERVED: 'cyan',
                    CONFIRMED: 'purple',
                    REJECTED: 'red',
                };
                return <Tag color={colors[status] || 'default'}>{status ? status.replace('_', ' ') : 'UNKNOWN'}</Tag>;
            }
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, record: Product) => (
                <Space>
                    {record.status === ProductStatus.PENDING_APPROVAL && (
                        <>
                            <Button
                                type="primary"
                                size="small"
                                icon={<CheckCircle size={14} />}
                                onClick={() => handleStatusChange(record.id, ProductStatus.PUBLISHED)}
                                style={{ backgroundColor: '#52c41a', display: 'flex', alignItems: 'center', gap: 4 }}
                            >
                                Approve
                            </Button>
                            <Button
                                danger
                                size="small"
                                icon={<XCircle size={14} />}
                                onClick={() => showRejectModal(record.id)}
                                style={{ display: 'flex', alignItems: 'center', gap: 4 }}
                            >
                                Reject
                            </Button>
                        </>
                    )}
                    <Button type="link" size="small" onClick={() => showDetailsModal(record)}>Details</Button>
                </Space>
            )
        }
    ];

    return (
        <div>
            <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Title level={2} style={{ margin: 0 }}>Products</Title>
                <Button onClick={fetchProducts} loading={loading}>Refresh</Button>
            </div>
            <Table
                columns={columns}
                dataSource={products}
                rowKey="id"
                loading={loading}
                pagination={{ total, pageSize: 15 }}
            />

            <Modal
                title="Reject Product"
                open={rejectModalVisible}
                onOk={handleRejectSubmit}
                onCancel={() => setRejectModalVisible(false)}
                confirmLoading={submitting}
                okText="Reject Product"
                okButtonProps={{ danger: true }}
            >
                <div style={{ marginBottom: 16 }}>
                    <p>Please provide a reason for rejecting this product. This will be sent to the seller.</p>
                    <Input.TextArea
                        rows={4}
                        placeholder="e.g. Photo quality too low, inappropriate content, etc."
                        value={rejectionReason}
                        onChange={(e) => setRejectionReason(e.target.value)}
                    />
                </div>
            </Modal>

            <Modal
                title="Product Details"
                open={detailsModalVisible}
                onCancel={() => setDetailsModalVisible(false)}
                footer={[
                    <Button key="close" onClick={() => setDetailsModalVisible(false)}>
                        Close
                    </Button>
                ]}
                width={800}
            >
                {selectedProduct && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
                        <div style={{ display: 'flex', overflowX: 'auto', gap: 10, paddingBottom: 10 }}>
                            {(selectedProduct.imageUrls || (selectedProduct as any).images?.map((img: any) => img.url) || []).map((url: string, index: number) => (
                                <Image
                                    key={index}
                                    src={url}
                                    width={150}
                                    height={150}
                                    style={{ objectFit: 'cover', borderRadius: 8 }}
                                />
                            ))}
                        </div>

                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
                            <div>
                                <Title level={4}>{selectedProduct.title}</Title>
                                <p><strong>Price:</strong> {selectedProduct.price} MAD</p>
                                <p><strong>Brand:</strong> {selectedProduct.brand}</p>
                                <p><strong>Size:</strong> {selectedProduct.size}</p>
                                <p><strong>Condition:</strong> {selectedProduct.condition.replace('_', ' ')}</p>
                                <p><strong>Status:</strong> <Tag color="blue">{selectedProduct.status}</Tag></p>
                            </div>
                            <div>
                                <Title level={4}>Seller Information</Title>
                                {selectedProduct.seller ? (
                                    <>
                                        <p><strong>Name:</strong> {selectedProduct.seller.firstName} {selectedProduct.seller.lastName}</p>
                                        <p><strong>Email:</strong> {selectedProduct.seller.email}</p>
                                    </>
                                ) : (
                                    <p>Seller information not available</p>
                                )}
                            </div>
                        </div>

                        <div>
                            <Title level={4}>Description</Title>
                            <div style={{ whiteSpace: 'pre-wrap', backgroundColor: '#f5f5f5', padding: 15, borderRadius: 8 }}>
                                {selectedProduct.description}
                            </div>
                        </div>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default ProductListPage;
