import React from 'react';
import { Card, Row, Col, Typography, Tag, List, Avatar, Space, Button } from 'antd';
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

const { Title, Text } = Typography;

const DashboardPage: React.FC = () => {
    // Static Mock Data
    const stats = [
        { title: 'Total Revenue', value: '128,430 MAD', icon: <DollarSign size={20} />, color: '#6366f1', trend: '+12.5%' },
        { title: 'Active Listings', value: '1,240', icon: <ShoppingBag size={20} />, color: '#10b981', trend: '+5.2%' },
        { title: 'Total Users', value: '8,520', icon: <Users size={20} />, color: '#f59e0b', trend: '+18.4%' },
        { title: 'Pending Moderation', value: '14', icon: <AlertCircle size={20} />, color: '#ef4444', trend: '-2' },
    ];

    const activities = [
        { id: 1, user: 'Ahmed L.', action: 'created a new listing', item: 'Nike Air Jordan 1', time: '5 mins ago', status: 'PENDING' },
        { id: 2, user: 'Sara M.', action: 'completed a purchase', item: 'Vintage Zara Coat', time: '12 mins ago', status: 'SUCCESS' },
        { id: 3, user: 'Admin', action: 'rejected listing', item: 'Used Battery', time: '45 mins ago', status: 'REJECTED' },
        { id: 4, user: 'Yassine K.', action: 'registered', item: '', time: '1 hour ago', status: 'SUCCESS' },
    ];

    return (
        <div className="animate-fade-in">
            <div style={{ marginBottom: 32 }}>
                <Title level={2} style={{ margin: 0 }}>
                    Welcome back, <span className="gradient-text">Admin</span>
                </Title>
                <Text type="secondary">Here's what's happening with Clovi today.</Text>
            </div>

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
                                    {stat.icon}
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
                                {[40, 65, 45, 80, 55, 90, 70, 85, 60, 95, 100, 85].map((val, i) => (
                                    <div key={i} style={{
                                        flex: 1,
                                        height: `${val}%`,
                                        background: i === 10 ? 'var(--primary-color)' : 'rgba(99, 102, 241, 0.1)',
                                        borderRadius: '4px 4px 0 0',
                                        transition: 'height 1s ease-in-out'
                                    }} />
                                ))}
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 12 }}>
                                {['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'].map(m => (
                                    <Text key={m} type="secondary" style={{ fontSize: 11 }}>{m}</Text>
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
                                                    <Text style={{ fontSize: 11, color: '#94a3b8' }}>{item.time}</Text>
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
                                <Title level={4} style={{ color: '#fff', margin: 0 }}>Ready to moderate?</Title>
                                <Text style={{ color: 'rgba(255,255,255,0.8)' }}>There are 14 products waiting for your approval.</Text>
                            </div>
                            <Button ghost size="large" style={{ borderRadius: 8, fontWeight: 600 }}>Go to Moderation</Button>
                        </div>
                    </Card>
                </Col>
            </Row>
        </div>
    );
};

export default DashboardPage;
