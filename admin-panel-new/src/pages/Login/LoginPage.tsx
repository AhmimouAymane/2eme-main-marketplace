import React, { useState } from 'react';
import { Form, Input, Button, Card, Typography, message, Layout } from 'antd';
import { UserOutlined, LockOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { apiClient } from '../../api/api-client';
import { useAuthStore } from '../../store/authStore';
import { APP_NAME } from '../../theme/constants';

const { Title, Text } = Typography;

const LoginPage: React.FC = () => {
    const [loading, setLoading] = useState(false);
    const setAuth = useAuthStore((state) => state.setAuth);
    const navigate = useNavigate();

    const onFinish = async (values: any) => {
        console.log('Login attempt started:', values.email);
        setLoading(true);
        try {
            console.log('Requesting auth/login...');
            const response: any = await apiClient.post('auth/login', { json: values }).json();
            console.log('Login response:', response);

            const token = response.token || response.accessToken;
            const user = response.user || { name: 'Admin', role: 'USER' };

            if (token) {
                if (user.role !== 'ADMIN') {
                    console.error('Login denied: User is not an admin', user.role);
                    message.error('Access denied: You do not have administrator privileges.');
                    setLoading(false);
                    return;
                }

                console.log('Login success! Redirecting...');
                setAuth(token, user);
                message.success('Welcome back, Admin!');
                navigate('/');
            } else {
                console.error('Login error: No token in response');
                message.error('Invalid response from server (missing token)');
            }
        } catch (error: any) {
            console.error('Login failed error:', error);
            let errorMsg = 'Login failed: Invalid credentials or server error';

            if (error.response) {
                try {
                    const body = await error.response.json();
                    console.error('Error body:', body);
                    errorMsg = body.message || errorMsg;
                } catch (e) {
                    console.error('Failed to parse error body');
                }
            }

            message.error(errorMsg);
        } finally {
            setLoading(false);
            console.log('Login flow finished');
        }
    };

    return (
        <Layout style={{ minHeight: '100vh', justifyContent: 'center', alignItems: 'center', backgroundColor: '#f0f2f5' }}>
            <Card style={{ width: 400, boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}>
                <div style={{ textAlign: 'center', marginBottom: 24 }}>
                    <Title level={2} style={{ margin: 0 }}>{APP_NAME}</Title>
                    <Text type="secondary">Sign in to manage your marketplace</Text>
                </div>

                <Form
                    name="login"
                    initialValues={{ email: 'admin@clovi.com', password: 'password' }}
                    onFinish={onFinish}
                    layout="vertical"
                >
                    <Form.Item
                        name="email"
                        rules={[{ required: true, message: 'Please input your Email!' }, { type: 'email' }]}
                    >
                        <Input prefix={<UserOutlined />} placeholder="Email" size="large" />
                    </Form.Item>

                    <Form.Item
                        name="password"
                        rules={[{ required: true, message: 'Please input your Password!' }]}
                    >
                        <Input.Password prefix={<LockOutlined />} placeholder="Password" size="large" />
                    </Form.Item>

                    <Form.Item>
                        <Button type="primary" htmlType="submit" size="large" block loading={loading}>
                            Log in
                        </Button>
                    </Form.Item>
                </Form>
            </Card>
        </Layout>
    );
};

export default LoginPage;
