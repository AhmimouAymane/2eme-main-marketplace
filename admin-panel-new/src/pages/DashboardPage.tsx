import React from 'react';
import { Card, Row, Col, Typography, Tag, List, Avatar, Space, Button, Alert } from 'antd';
import {
    TrendingUp,
    Users,
    ShoppingBag,
    DollarSign,
    Clock,
    CheckCircle2,
    AlertCircle,
    ArrowUpRight
} from 'lucide-react';
import { apiClient } from '../api/api-client';
import { DashboardStats } from '../types';
import { useNavigate } from 'react-router-dom';

const { Title, Text } = Typography;

const IconMap: Record<string, React.ReactNode> = {
    'DollarSign': <DollarSign size={20} />,
    'ShoppingBag': <ShoppingBag size={20} />,
    'Users': <Users size={20} />,
    'AlertCircle': <AlertCircle size={20} />,
};

const DashboardPage: React.FC = () => {
    const [data, setData] = React.useState<DashboardStats | null>(null);
    const [loading, setLoading] = React.useState(true);
    const [error, setError] = React.useState<string | null>(null);
    const navigate = useNavigate();

    React.useEffect(() => {
        const fetchStats = async () => {
            try {
                setLoading(true);
                setError(null);
                const response = await apiClient.get('dashboard/stats').json<DashboardStats>();
                setData(response);
            } catch (err: any) {
                console.error('Failed to fetch dashboard stats:', err);
                setError(err?.response?.status === 403 ? 'Accès refusé. Droits admin requis.' : 'Échec du chargement des statistiques.');
            } finally {
                setLoading(false);
            }
        };

        fetchStats();
    }, []);

    if (loading) {
        return <div style={{ padding: 40, textAlign: 'center' }}><Card loading bordered={false} className="glass-card" /></div>;
    }

    const { stats = [], activities = [], salesGrowth = [], pendingCount = 0 } = data || {};

    return (
        <div className="animate-fade-in">
            <div style={{ marginBottom: 32 }}>
                <Title level={2} style={{ margin: 0 }}>
                    Welcome back, <span className="gradient-text">Admin</span>
                </Title>
                <Text type="secondary">Here's what's happening with Clovi today.</Text>
            </div>

            {error && <Alert message={error} type="error" showIcon closable style={{ marginBottom: 24 }} />}

            {/* Stats Overview */}
            <Row gutter={[24, 24]}>
                {stats.map((stat, index) => (
                    <Col xs={24} sm={12} lg={6} key={index}>
                        <Card className="glass-card" bordered={false} bodyStyle={{ padding: 24 }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                <div style={{
                                    padding: 10,
                                    borderRadius: 12,
                                    backgroundColor: `${stat.color}15`,
                                    color: stat.color,
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center'
                                }}>
                                    {IconMap[stat.icon] || <ShoppingBag size={20} />}
                                </div>
                                <Tag color={stat.trend.startsWith('+') ? 'success' : 'error'} bordered={false} style={{ borderRadius: 20 }}>
                                    {stat.trend}
                                </Tag>
                            </div>
                            <div style={{ marginTop: 16 }}>
                                <Text type="secondary" strong style={{ fontSize: 13, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                                    {stat.title}
                                </Text>
                                <Title level={3} style={{ margin: '4px 0 0 0', fontWeight: 700 }}>{stat.value}</Title>
                            </div>
                        </Card>
                    </Col>
                ))}
            </Row>

            <Row gutter={[24, 24]} style={{ marginTop: 24 }}>
                {/* Visual Chart Placeholder (Static SVG) */}
                <Col xs={24} lg={16}>
                    <Card title="Sales Growth" className="glass-card" bordered={false} extra={<Button type="link" size="small">View Report</Button>}>
                        <div style={{ height: 300, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', padding: '0 10px' }}>
                            {/* Simple CSS/SVG Mock Chart */}
                            <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', height: '100%', gap: 12 }}>
                                {salesGrowth.map((val, i) => (
                                    <div key={i} style={{
                                        flex: 1,
                                        height: `${Math.max((val.value / (Math.max(...salesGrowth.map(sg => sg.value)) || 1)) * 100, 5)}%`,
                                        background: i === salesGrowth.length - 1 ? 'var(--primary-color)' : 'rgba(99, 102, 241, 0.1)',
                                        borderRadius: '4px 4px 0 0',
                                        transition: 'height 1s ease-in-out'
                                    }} />
                                ))}
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 12 }}>
                                {salesGrowth.map(sg => (
                                    <Text key={sg.month} type="secondary" style={{ fontSize: 11 }}>{sg.month}</Text>
                                ))}
                            </div>
                        </div>
                    </Card>
                </Col>

                {/* Recent Activity */}
                <Col xs={24} lg={8}>
                    <Card title="Recent Activity" className="glass-card" bordered={false} bodyStyle={{ padding: 0 }}>
                        <List
                            itemLayout="horizontal"
                            dataSource={activities}
                            renderItem={(item) => (
                                <List.Item style={{ padding: '16px 24px', borderBottom: '1px solid #f1f5f9' }}>
                                    <List.Item.Meta
                                        avatar={<Avatar style={{ backgroundColor: '#f1f5f9', color: '#6366f1' }} icon={<Users size={14} />} />}
                                        title={<Text strong>{item.user}</Text>}
                                        description={
                                            <Space direction="vertical" size={0}>
                                                <Text type="secondary" style={{ fontSize: 12 }}>{item.action} <Text strong>{item.item}</Text></Text>
                                                <Space style={{ marginTop: 4 }}>
                                                    <Clock size={12} style={{ color: '#94a3b8' }} />
                                                    <Text style={{ fontSize: 11, color: '#94a3b8' }}>{new Date(item.time).toLocaleDateString()} {new Date(item.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</Text>
                                                </Space>
                                            </Space>
                                        }
                                    />
                                </List.Item>
                            )}
                        />
                        <div style={{ padding: 16, textAlign: 'center' }}>
                            <Button type="link" icon={<ArrowUpRight size={14} />}>View All Activity</Button>
                        </div>
                    </Card>
                </Col>
            </Row>

            <Row gutter={[24, 24]} style={{ marginTop: 24 }}>
                <Col span={24}>
                    <Card className="glass-card" style={{ background: 'linear-gradient(135deg, #4f46e5 0%, #10b981 100%)', border: 'none' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: '#fff' }}>
                            <div>
                                <Title level={4} style={{ color: '#fff', margin: 0 }}>Prêt à modérer ?</Title>
                                <Text style={{ color: 'rgba(255,255,255,0.8)' }}>Il y a {pendingCount} produits en attente de votre approbation.</Text>
                            </div>
                            <Button ghost size="large" style={{ borderRadius: 8, fontWeight: 600 }} onClick={() => navigate('/products')}>Aller à la Modération</Button>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div>
    );
};

export default DashboardPage;
