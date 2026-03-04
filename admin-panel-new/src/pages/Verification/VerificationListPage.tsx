import React, { useEffect, useState } from 'react';
import { Table, Tag, Space, Button, message, Image, Typography, Modal, Input, Row, Col, Descriptions, Card, Badge, Tabs } from 'antd';
import { RefreshCw, CheckCircle, XCircle, Eye } from 'lucide-react';
import { apiClient } from '../../api/api-client';

const { Title, Text } = Typography;

interface User {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
    isSellerVerified: boolean;
    sellerStatus: 'NOT_SUBMITTED' | 'PENDING' | 'APPROVED' | 'REJECTED';
    verificationDocuments: {
        id: string;
        fileType: 'ID_CARD' | 'ID_CARD_FRONT' | 'ID_CARD_BACK' | 'BANK_CERTIFICATE';
        fileName: string;
    }[];
    verificationComment?: string;
}

const SecurePreview: React.FC<{ docId: string; title: string }> = ({ docId, title }) => {
    const [blobUrl, setBlobUrl] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const [mimeType, setMimeType] = useState<string>('');

    useEffect(() => {
        const fetchDoc = async () => {
            try {
                const response = await apiClient.get(`seller-verification/document/${docId}`);
                const blob = await response.blob();
                const url = URL.createObjectURL(blob);
                setBlobUrl(url);
                setMimeType(blob.type);
            } catch (error) {
                console.error('Error fetching document', error);
            } finally {
                setLoading(false);
            }
        };

        fetchDoc();
        return () => {
            if (blobUrl) URL.revokeObjectURL(blobUrl);
        };
    }, [docId]);

    if (loading) return <Badge status="processing" text="Chargement..." />;
    if (!blobUrl) return <Badge status="error" text="Erreur de chargement" />;

    const isPdf = mimeType === 'application/pdf';

    return (
        <Card title={title} bordered={false} className="doc-card" size="small">
            {isPdf ? (
                <div style={{ height: 400, display: 'flex', flexDirection: 'column', gap: 8 }}>
                    <iframe src={blobUrl} style={{ width: '100%', height: '100%', border: 'none' }} title={title} />
                    <Button type="link" href={blobUrl} target="_blank" download={title}>
                        Ouvrir/Télécharger le PDF
                    </Button>
                </div>
            ) : (
                <Image src={blobUrl} alt={title} style={{ width: '100%', borderRadius: 8 }} />
            )}
        </Card>
    );
};

const VerificationListPage: React.FC = () => {
    const [users, setUsers] = useState<User[]>([]);
    const [activeTab, setActiveTab] = useState('PENDING');
    const [loading, setLoading] = useState(false);
    const [rejectModalVisible, setRejectModalVisible] = useState(false);
    const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
    const [rejectionReason, setRejectionReason] = useState('');
    const [submitting, setSubmitting] = useState(false);
    const [detailsModalVisible, setDetailsModalVisible] = useState(false);
    const [selectedUser, setSelectedUser] = useState<User | null>(null);

    const fetchVerifications = async (status: string) => {
        setLoading(true);
        try {
            const data: any = await apiClient.get(`seller-verification/list?status=${status}`).json();
            setUsers(data);
        } catch (error) {
            message.error('Échec du chargement des demandes de vérification');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchVerifications(activeTab);
    }, [activeTab]);

    const handleApprove = async (id: string) => {
        try {
            await apiClient.patch(`seller-verification/${id}/approve`).json();
            message.success('Vendeur approuvé avec succès');
            fetchVerifications(activeTab);
        } catch (error) {
            message.error('Échec de l\'approbation');
        }
    };

    const handleReject = async () => {
        if (!selectedUserId || !rejectionReason) {
            message.warning('Veuillez fournir un motif de rejet');
            return;
        }
        setSubmitting(true);
        try {
            await apiClient.patch(`seller-verification/${selectedUserId}/reject`, {
                json: { comment: rejectionReason }
            }).json();
            message.success('Demande rejetée');
            setRejectModalVisible(false);
            fetchVerifications(activeTab);
        } catch (error) {
            message.error('Échec du rejet');
        } finally {
            setSubmitting(false);
        }
    };

    const showRejectModal = (id: string) => {
        setSelectedUserId(id);
        setRejectionReason('');
        setRejectModalVisible(true);
    };

    const showDetailsModal = (user: User) => {
        setSelectedUser(user);
        setDetailsModalVisible(true);
    };

    const columns = [
        {
            title: 'Utilisateur',
            key: 'user',
            render: (_: any, record: User) => (
                <div>
                    <div style={{ fontWeight: 'bold' }}>{record.firstName} {record.lastName}</div>
                    <Text type="secondary" style={{ fontSize: 12 }}>{record.email}</Text>
                </div>
            )
        },
        {
            title: 'Statut actuel',
            dataIndex: 'sellerStatus',
            key: 'status',
            render: (status: string, record: User) => {
                const colors: any = {
                    PENDING: 'orange',
                    APPROVED: 'green',
                    REJECTED: 'red',
                    NOT_SUBMITTED: 'default'
                };
                // Fallback for old data where only isSellerVerified might be set
                const displayStatus = status || (record.isSellerVerified ? 'APPROVED' : 'NOT_SUBMITTED');
                return <Tag color={colors[displayStatus] || 'default'}>{displayStatus}</Tag>;
            }
        },
        {
            title: 'ID Vendeur',
            dataIndex: 'id',
            key: 'id',
            render: (id: string) => <Text copyable style={{ fontSize: 12 }}>{id}</Text>
        },
        {
            title: 'Actions',
            key: 'actions',
            width: 300,
            render: (_: any, record: User) => (
                <Space>
                    {record.sellerStatus === 'PENDING' && (
                        <>
                            <Button
                                type="primary"
                                size="small"
                                icon={<CheckCircle size={14} />}
                                onClick={() => handleApprove(record.id)}
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
                        {record.sellerStatus === 'PENDING' ? 'Voir Documents' : 'Consulter Docs'}
                    </Button>
                </Space>
            )
        }
    ];

    return (
        <div style={{ padding: 24, backgroundColor: '#fff', borderRadius: 12 }}>
            <div style={{ marginBottom: 24, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Title level={2} style={{ margin: 0 }}>Vérification des Vendeurs</Title>
                <Button
                    icon={<RefreshCw size={16} />}
                    onClick={() => fetchVerifications(activeTab)}
                    loading={loading}
                    style={{ display: 'flex', alignItems: 'center', gap: 8 }}
                >
                    Rafraîchir
                </Button>
            </div>

            <Tabs
                activeKey={activeTab}
                onChange={setActiveTab}
                items={[
                    { key: 'PENDING', label: 'En attente' },
                    { key: 'APPROVED', label: 'Vérifiés' },
                    { key: 'REJECTED', label: 'Refusés' },
                ]}
                style={{ marginBottom: 16 }}
            />

            <Table
                columns={columns}
                dataSource={users}
                rowKey="id"
                loading={loading}
                pagination={{ pageSize: 15 }}
                locale={{
                    emptyText: activeTab === 'PENDING'
                        ? 'Aucune demande de vérification en attente'
                        : activeTab === 'APPROVED'
                            ? 'Aucun vendeur vérifié trouvé'
                            : 'Aucune demande refusée'
                }}
            />

            <Modal
                title="Rejeter la vérification"
                open={rejectModalVisible}
                onOk={handleReject}
                onCancel={() => setRejectModalVisible(false)}
                confirmLoading={submitting}
                okText="Confirmer le rejet"
                okButtonProps={{ danger: true }}
            >
                <p>Veuillez fournir une raison pour le rejet de cette vérification. Le vendeur pourra voir ce motif.</p>
                <Input.TextArea
                    rows={4}
                    placeholder="Ex: Documents illisibles, certificat non conforme..."
                    value={rejectionReason}
                    onChange={(e) => setRejectionReason(e.target.value)}
                />
            </Modal>

            <Modal
                title={`Documents de vérification - ${selectedUser?.firstName} ${selectedUser?.lastName}`}
                open={detailsModalVisible}
                onCancel={() => setDetailsModalVisible(false)}
                footer={[
                    selectedUser?.sellerStatus === 'PENDING' && (
                        <Button key="reject" danger onClick={() => { setDetailsModalVisible(false); showRejectModal(selectedUser!.id); }}>
                            Rejeter
                        </Button>
                    ),
                    selectedUser?.sellerStatus === 'PENDING' && (
                        <Button key="approve" type="primary" style={{ backgroundColor: '#52c41a' }} onClick={() => { setDetailsModalVisible(false); handleApprove(selectedUser!.id); }}>
                            Approuver
                        </Button>
                    ),
                    <Button key="close" onClick={() => setDetailsModalVisible(false)}>
                        Fermer
                    </Button>
                ]}
                width={1000}
            >
                {selectedUser && (
                    <Row gutter={[24, 24]}>
                        <Col span={12}>
                            {selectedUser.verificationDocuments.find(d => d.fileType === 'ID_CARD_FRONT' || d.fileType === 'ID_CARD') ? (
                                <SecurePreview
                                    docId={selectedUser.verificationDocuments.find(d => d.fileType === 'ID_CARD_FRONT' || d.fileType === 'ID_CARD')!.id}
                                    title="Pièce d'identité (Recto / Unique)"
                                />
                            ) : (
                                <Card title="Pièce d'identité (Recto)" bordered={false} className="doc-card">
                                    <Badge status="error" text="Aucun document fourni" />
                                </Card>
                            )}
                        </Col>
                        <Col span={12}>
                            {selectedUser.verificationDocuments.find(d => d.fileType === 'ID_CARD_BACK') ? (
                                <SecurePreview
                                    docId={selectedUser.verificationDocuments.find(d => d.fileType === 'ID_CARD_BACK')!.id}
                                    title="Pièce d'identité (Verso)"
                                />
                            ) : (
                                <Card title="Pièce d'identité (Verso)" bordered={false} className="doc-card">
                                    <Badge status="warning" text="Pas de verso (Ancien format?)" />
                                </Card>
                            )}
                        </Col>
                        <Col span={24}>
                            {selectedUser.verificationDocuments.find(d => d.fileType === 'BANK_CERTIFICATE') ? (
                                <SecurePreview
                                    docId={selectedUser.verificationDocuments.find(d => d.fileType === 'BANK_CERTIFICATE')!.id}
                                    title="Certificat Bancaire (RIB)"
                                />
                            ) : (
                                <Card title="Certificat Bancaire (RIB)" bordered={false} className="doc-card">
                                    <Badge status="error" text="Aucun document fourni" />
                                </Card>
                            )}
                        </Col>
                        <Col span={24}>
                            <Descriptions title="Détails Utilisateur" bordered column={2}>
                                <Descriptions.Item label="Prénom">{selectedUser.firstName}</Descriptions.Item>
                                <Descriptions.Item label="Nom">{selectedUser.lastName}</Descriptions.Item>
                                <Descriptions.Item label="Email">{selectedUser.email}</Descriptions.Item>
                                <Descriptions.Item label="ID Utilisateur">{selectedUser.id}</Descriptions.Item>
                            </Descriptions>
                        </Col>
                    </Row>
                )}
            </Modal>
        </div>
    );
};

export default VerificationListPage;
