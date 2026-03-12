import React, { useEffect, useState, useCallback } from 'react';
import {
    Table, Tag, Modal, Typography, Avatar, Descriptions, Spin, Button, Space, Alert
} from 'antd';
import { FlagOutlined, UserOutlined, ShoppingOutlined, MessageOutlined, EyeOutlined } from '@ant-design/icons';
import { apiClient } from '../../api/api-client';

const { Title, Text } = Typography;

const REASON_CONFIG: Record<string, { color: string; label: string }> = {
    SPAM: { color: 'orange', label: 'Spam' },
    INAPPROPRIATE_CONTENT: { color: 'red', label: 'Contenu inapproprié' },
    FRAUD: { color: 'volcano', label: 'Fraude' },
    HARASSMENT: { color: 'purple', label: 'Harcèlement' },
    OTHER: { color: 'default', label: 'Autre' },
};

interface Report {
    id: string;
    reason: string;
    description?: string;
    createdAt: string;
    reporter: { id: string; firstName: string; lastName: string; avatarUrl?: string };
    reportedUser?: { id: string; firstName: string; lastName: string; avatarUrl?: string };
    reportedProduct?: { id: string; title: string };
    reportedComment?: { id: string; content: string };
}

const ReportsPage: React.FC = () => {
    const [reports, setReports] = useState<Report[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [selectedReport, setSelectedReport] = useState<Report | null>(null);

    const fetchReports = useCallback(async () => {
        try {
            setLoading(true);
            setError(null);
            const data = await apiClient.get('moderation/reports').json<Report[]>();
            setReports(data);
        } catch (err: any) {
            setError(err?.response?.data?.message || 'Erreur lors du chargement des signalements.');
        } finally {
            setLoading(false);
        }
    }, []);

    useEffect(() => {
        fetchReports();
    }, [fetchReports]);

    const getObjectType = (report: Report) => {
        if (report.reportedUser) return <Tag icon={<UserOutlined />} color="blue">Utilisateur</Tag>;
        if (report.reportedProduct) return <Tag icon={<ShoppingOutlined />} color="cyan">Produit</Tag>;
        if (report.reportedComment) return <Tag icon={<MessageOutlined />} color="geekblue">Commentaire</Tag>;
        return <Tag>Inconnu</Tag>;
    };

    const getObjectName = (report: Report) => {
        if (report.reportedUser) return `${report.reportedUser.firstName} ${report.reportedUser.lastName}`;
        if (report.reportedProduct) return report.reportedProduct.title;
        if (report.reportedComment) return `"${report.reportedComment.content.substring(0, 60)}..."`;
        return '—';
    };

    const columns = [
        {
            title: 'Date',
            dataIndex: 'createdAt',
            key: 'createdAt',
            render: (v: string) => new Date(v).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }),
            sorter: (a: Report, b: Report) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
        },
        {
            title: 'Signalé par',
            dataIndex: 'reporter',
            key: 'reporter',
            render: (r: Report['reporter']) => (
                <Space>
                    <Avatar src={r.avatarUrl} icon={<UserOutlined />} size="small" />
                    <Text>{r.firstName} {r.lastName}</Text>
                </Space>
            ),
        },
        {
            title: 'Raison',
            dataIndex: 'reason',
            key: 'reason',
            render: (reason: string) => {
                const cfg = REASON_CONFIG[reason] ?? { color: 'default', label: reason };
                return <Tag color={cfg.color}>{cfg.label}</Tag>;
            },
            filters: Object.entries(REASON_CONFIG).map(([k, v]) => ({ text: v.label, value: k })),
            onFilter: (value: any, record: Report) => record.reason === value,
        },
        {
            title: 'Objet signalé',
            key: 'object',
            render: (_: any, record: Report) => (
                <Space>
                    {getObjectType(record)}
                    <Text type="secondary" style={{ fontSize: 12 }}>{getObjectName(record)}</Text>
                </Space>
            ),
        },
        {
            title: 'Description',
            dataIndex: 'description',
            key: 'description',
            render: (d?: string) => d ? <Text type="secondary" ellipsis style={{ maxWidth: 200 }}>{d}</Text> : <Text type="secondary" italic>—</Text>,
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, record: Report) => (
                <Button icon={<EyeOutlined />} size="small" onClick={() => setSelectedReport(record)}>
                    Détails
                </Button>
            ),
        },
    ];

    return (
        <>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <Title level={3} style={{ margin: 0 }}>
                    <FlagOutlined style={{ marginRight: 8, color: '#ff4d4f' }} />
                    Signalements ({reports.length})
                </Title>
                <Button onClick={fetchReports} loading={loading}>Rafraîchir</Button>
            </div>

            {error && <Alert type="error" message={error} style={{ marginBottom: 16 }} />}

            <Spin spinning={loading}>
                <Table
                    dataSource={reports}
                    columns={columns}
                    rowKey="id"
                    pagination={{ pageSize: 25, showSizeChanger: true }}
                    locale={{ emptyText: 'Aucun signalement pour le moment.' }}
                />
            </Spin>

            <Modal
                open={!!selectedReport}
                title={<><FlagOutlined style={{ color: '#ff4d4f', marginRight: 8 }} />Détails du signalement</>}
                footer={<Button onClick={() => setSelectedReport(null)}>Fermer</Button>}
                onCancel={() => setSelectedReport(null)}
                width={600}
            >
                {selectedReport && (
                    <Descriptions bordered column={1} size="small">
                        <Descriptions.Item label="ID">{selectedReport.id}</Descriptions.Item>
                        <Descriptions.Item label="Date">
                            {new Date(selectedReport.createdAt).toLocaleString('fr-FR')}
                        </Descriptions.Item>
                        <Descriptions.Item label="Raison">
                            {(() => {
                                const cfg = REASON_CONFIG[selectedReport.reason] ?? { color: 'default', label: selectedReport.reason };
                                return <Tag color={cfg.color}>{cfg.label}</Tag>;
                            })()}
                        </Descriptions.Item>
                        <Descriptions.Item label="Description">
                            {selectedReport.description || <Text italic type="secondary">Aucune description fournie</Text>}
                        </Descriptions.Item>
                        <Descriptions.Item label="Signalé par">
                            <Space>
                                <Avatar src={selectedReport.reporter.avatarUrl} icon={<UserOutlined />} />
                                <Text strong>{selectedReport.reporter.firstName} {selectedReport.reporter.lastName}</Text>
                                <Text type="secondary" copyable>({selectedReport.reporter.id})</Text>
                            </Space>
                        </Descriptions.Item>
                        {selectedReport.reportedUser && (
                            <Descriptions.Item label="Utilisateur signalé">
                                <Space>
                                    <Avatar src={selectedReport.reportedUser.avatarUrl} icon={<UserOutlined />} />
                                    <Text strong>{selectedReport.reportedUser.firstName} {selectedReport.reportedUser.lastName}</Text>
                                    <Text type="secondary" copyable>({selectedReport.reportedUser.id})</Text>
                                </Space>
                            </Descriptions.Item>
                        )}
                        {selectedReport.reportedProduct && (
                            <Descriptions.Item label="Produit signalé">
                                <Text strong>{selectedReport.reportedProduct.title}</Text>
                                <Text type="secondary" copyable style={{ marginLeft: 8 }}>({selectedReport.reportedProduct.id})</Text>
                            </Descriptions.Item>
                        )}
                        {selectedReport.reportedComment && (
                            <Descriptions.Item label="Commentaire signalé">
                                <Text italic>« {selectedReport.reportedComment.content} »</Text>
                            </Descriptions.Item>
                        )}
                    </Descriptions>
                )}
            </Modal>
        </>
    );
};

export default ReportsPage;
