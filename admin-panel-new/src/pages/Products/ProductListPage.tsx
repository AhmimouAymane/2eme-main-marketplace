import React, { useEffect, useState } from 'react';
import { Table, Tag, Space, Button, message, Select, Image, Typography, Modal, Input, Form, InputNumber, Row, Col, Descriptions, Divider, Card } from 'antd';
import { RefreshCw, CheckCircle, XCircle, Search, Filter, Eye } from 'lucide-react';
import { apiClient } from '../../api/api-client';
import { Product, ProductStatus } from '../../types';
import { API_URL } from '../../theme/constants';

const { Title, Text } = Typography;

const ProductListPage: React.FC = () => {
    const [products, setProducts] = useState<Product[]>([]);
    const [categories, setCategories] = useState<any[]>([]);
    const [loading, setLoading] = useState(false);
    const [total, setTotal] = useState(0);
    const [rejectModalVisible, setRejectModalVisible] = useState(false);
    const [selectedProductId, setSelectedProductId] = useState<string | null>(null);
    const [rejectionReason, setRejectionReason] = useState('');
    const [submitting, setSubmitting] = useState(false);
    const [form] = Form.useForm();

    const fetchCategories = async () => {
        try {
            const data: any = await apiClient.get('categories').json();
            setCategories(data);
        } catch (error) {
            console.error('Failed to load categories');
        }
    };

    const fetchProducts = async (filters: any = {}) => {
        setLoading(true);
        try {
            const searchParams: any = {
                isAdminView: 'true',
                ...filters
            };

            // Clean up empty filters
            Object.keys(searchParams).forEach(key => {
                if (searchParams[key] === undefined || searchParams[key] === null || searchParams[key] === '') {
                    delete searchParams[key];
                }
            });

            const response: any = await apiClient.get('products', {
                searchParams
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
        fetchCategories();
    }, []);

    const onFilterFinish = (values: any) => {
        fetchProducts(values);
    };

    const handleStatusChange = async (id: string, status: ProductStatus, moderationComment?: string) => {
        try {
            await apiClient.patch(`products/${id}/status`, {
                json: { status, moderationComment }
            }).json();
            message.success(`Product status updated to ${status}`);
            fetchProducts(form.getFieldsValue());
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
            width: 80,
            render: (_: any, record: Product) => {
                const imageUrls = record.imageUrls || record.images?.map(img => img.url) || [];
                const mainImage = imageUrls[0];
                return <Image src={mainImage} width={50} height={50} style={{ width: 50, height: 50, objectFit: 'cover', borderRadius: 4 }} fallback="https://via.placeholder.com/50" />;
            }
        },
        {
            title: 'Titre & Marque',
            key: 'info',
            render: (_: any, record: Product) => (
                <div>
                    <div style={{ fontWeight: 'bold' }}>{record.title}</div>
                    <Text type="secondary" style={{ fontSize: 12 }}>{record.brand || 'Pas de marque'}</Text>
                </div>
            )
        },
        {
            title: 'Prix',
            dataIndex: 'price',
            key: 'price',
            width: 120,
            render: (price: number) => <span style={{ fontWeight: 'bold' }}>{price} MAD</span>
        },
        {
            title: 'Catégorie',
            dataIndex: ['category', 'name'],
            key: 'category',
            render: (name: string) => <Tag color="blue">{name || '-'}</Tag>
        },
        {
            title: 'État',
            dataIndex: 'condition',
            key: 'condition',
            render: (cond: string) => <Tag color="geekblue">{cond ? cond.replace(/_/g, ' ') : '-'}</Tag>
        },
        {
            title: 'Vendeur',
            dataIndex: 'seller',
            key: 'seller',
            render: (seller: any) => seller ? `${seller.firstName} ${seller.lastName}` : '-'
        },
        {
            title: 'Statut',
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
            width: 200,
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
                                Approuver
                            </Button>
                            <Button
                                danger
                                size="small"
                                icon={<XCircle size={14} />}
                                onClick={() => showRejectModal(record.id)}
                                style={{ display: 'flex', alignItems: 'center', gap: 4 }}
                            >
                                Rejeter
                            </Button>
                        </>
                    )}
                    <Button
                        type="default"
                        size="small"
                        icon={<Eye size={14} />}
                        onClick={() => showDetailsModal(record)}
                        style={{ display: 'flex', alignItems: 'center', gap: 4 }}
                    >
                        Détails
                    </Button>
                </Space>
            )
        }
    ];

    return (
        <div style={{ padding: 24, backgroundColor: '#fff', borderRadius: 12 }}>
            <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Title level={2} style={{ margin: 0 }}>Gestion des Produits</Title>
                <Button
                    icon={<RefreshCw size={16} />}
                    onClick={() => fetchProducts(form.getFieldsValue())}
                    loading={loading}
                    style={{ display: 'flex', alignItems: 'center', gap: 8 }}
                >
                    Rafraîchir
                </Button>
            </div>

            <Card style={{ marginBottom: 24, border: '1px solid #f0f0f0' }} bodyStyle={{ padding: 16 }}>
                <Form
                    form={form}
                    layout="vertical"
                    onFinish={onFilterFinish}
                    initialValues={{ status: undefined, categoryId: undefined }}
                >
                    <Row gutter={16}>
                        <Col xs={24} md={6}>
                            <Form.Item name="search" label="Recherche">
                                <Input prefix={<Search size={14} color="#bfbfbf" />} placeholder="Titre, marque..." allowClear />
                            </Form.Item>
                        </Col>
                        <Col xs={24} md={4}>
                            <Form.Item name="categoryId" label="Catégorie">
                                <Select
                                    placeholder="Toutes"
                                    allowClear
                                    showSearch
                                    optionFilterProp="children"
                                >
                                    {categories.map(c => (
                                        <Select.Option key={c.id} value={c.id}>{c.name}</Select.Option>
                                    ))}
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col xs={24} md={4}>
                            <Form.Item name="status" label="Statut">
                                <Select placeholder="Tous" allowClear>
                                    <Select.Option value="PENDING_APPROVAL">En attente</Select.Option>
                                    <Select.Option value="PUBLISHED">Publié</Select.Option>
                                    <Select.Option value="REJECTED">Rejeté</Select.Option>
                                    <Select.Option value="SOLD">Vendu</Select.Option>
                                    <Select.Option value="RESERVED">Réservé</Select.Option>
                                </Select>
                            </Form.Item>
                        </Col>
                        <Col xs={24} md={3}>
                            <Form.Item name="minPrice" label="Prix Min">
                                <InputNumber style={{ width: '100%' }} placeholder="Min" min={0} />
                            </Form.Item>
                        </Col>
                        <Col xs={24} md={3}>
                            <Form.Item name="maxPrice" label="Prix Max">
                                <InputNumber style={{ width: '100%' }} placeholder="Max" min={0} />
                            </Form.Item>
                        </Col>
                        <Col xs={24} md={4} style={{ display: 'flex', alignItems: 'flex-end', paddingBottom: 24 }}>
                            <Space>
                                <Button type="primary" htmlType="submit">Filtrer</Button>
                                <Button onClick={() => { form.resetFields(); fetchProducts(); }}>Réinitialiser</Button>
                            </Space>
                        </Col>
                    </Row>
                </Form>
            </Card>

            <Table
                columns={columns}
                dataSource={products}
                rowKey="id"
                loading={loading}
                pagination={{
                    total,
                    pageSize: 15,
                    showTotal: (total) => `Total ${total} produits`,
                    onChange: (page) => {
                        const start = (page - 1) * 15;
                        fetchProducts({ ...form.getFieldsValue(), _start: start, _end: start + 15 });
                    }
                }}
            />

            <Modal
                title="Rejeter le produit"
                open={rejectModalVisible}
                onOk={handleRejectSubmit}
                onCancel={() => setRejectModalVisible(false)}
                confirmLoading={submitting}
                okText="Confirmer le rejet"
                okButtonProps={{ danger: true }}
            >
                <div style={{ marginBottom: 16 }}>
                    <p>Veuillez fournir une raison pour le rejet de ce produit. Ce message sera envoyé au vendeur.</p>
                    <Input.TextArea
                        rows={4}
                        placeholder="Ex: Photos de mauvaise qualité, description incomplète, etc."
                        value={rejectionReason}
                        onChange={(e) => setRejectionReason(e.target.value)}
                    />
                </div>
            </Modal>

            <Modal
                title={`Détails du produit - ${selectedProduct?.title}`}
                open={detailsModalVisible}
                onCancel={() => setDetailsModalVisible(false)}
                footer={[
                    <Button key="close" onClick={() => setDetailsModalVisible(false)}>
                        Fermer
                    </Button>
                ]}
                width={900}
            >
                {selectedProduct && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                        <div style={{ display: 'flex', overflowX: 'auto', gap: 12, paddingBottom: 12, borderBottom: '1px solid #f0f0f0' }}>
                            {(selectedProduct.imageUrls || (selectedProduct as any).images?.map((img: any) => img.url) || []).map((url: string, index: number) => (
                                <Image
                                    key={index}
                                    src={url}
                                    width={180}
                                    height={180}
                                    style={{ objectFit: 'cover', borderRadius: 8, border: '1px solid #f0f0f0' }}
                                />
                            ))}
                        </div>

                        <Row gutter={32}>
                            <Col span={14}>
                                <Descriptions title="Informations Générales" bordered column={1}>
                                    <Descriptions.Item label="Prix">{selectedProduct.price} MAD</Descriptions.Item>
                                    <Descriptions.Item label="Catégorie">{selectedProduct.category?.name || '-'}</Descriptions.Item>
                                    <Descriptions.Item label="Marque">{selectedProduct.brand || '-'}</Descriptions.Item>
                                    <Descriptions.Item label="Taille">{selectedProduct.size || '-'}</Descriptions.Item>
                                    <Descriptions.Item label="État">{selectedProduct.condition.replace(/_/g, ' ')}</Descriptions.Item>
                                    <Descriptions.Item label="Statut">
                                        <Tag color="blue">{selectedProduct.status.replace(/_/g, ' ')}</Tag>
                                    </Descriptions.Item>
                                    <Descriptions.Item label="Date de création">
                                        {new Date(selectedProduct.createdAt).toLocaleString()}
                                    </Descriptions.Item>
                                </Descriptions>

                                <div style={{ marginTop: 24 }}>
                                    <Title level={5}>Description</Title>
                                    <div style={{
                                        whiteSpace: 'pre-wrap',
                                        backgroundColor: '#fafafa',
                                        padding: 16,
                                        borderRadius: 8,
                                        border: '1px solid #f0f0f0',
                                        fontSize: 14,
                                        color: '#555'
                                    }}>
                                        {selectedProduct.description}
                                    </div>
                                </div>
                            </Col>

                            <Col span={10}>
                                <Descriptions title="Vendeur" bordered column={1}>
                                    <Descriptions.Item label="Nom">
                                        {selectedProduct.seller?.firstName} {selectedProduct.seller?.lastName}
                                    </Descriptions.Item>
                                    <Descriptions.Item label="Email">
                                        {selectedProduct.seller?.email}
                                    </Descriptions.Item>
                                    <Descriptions.Item label="ID Vendeur">
                                        <Text copyable style={{ fontSize: 12 }}>{selectedProduct.seller?.id}</Text>
                                    </Descriptions.Item>
                                </Descriptions>

                                {selectedProduct.status === 'REJECTED' && selectedProduct.moderationComment && (
                                    <div style={{ marginTop: 24, padding: 16, backgroundColor: '#fff2f0', border: '1px solid #ffccc7', borderRadius: 8 }}>
                                        <Title level={5} type="danger">Motif du rejet</Title>
                                        <Text type="danger">{selectedProduct.moderationComment}</Text>
                                    </div>
                                )}
                            </Col>
                        </Row>
                    </div>
                )}
            </Modal>
        </div>
    );
};

export default ProductListPage;
