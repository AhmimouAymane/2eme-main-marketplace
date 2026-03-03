import React, { useEffect, useState } from 'react';
import { Card, Form, InputNumber, Button, Typography, message, Space, Spin } from 'antd';
import { SaveOutlined, SettingOutlined } from '@ant-design/icons';
import { apiClient } from '../../api/api-client';

const { Title, Text } = Typography;

interface SystemSettings {
    serviceFeePercentage: number;
    shippingFee: number;
}

const SettingsPage: React.FC = () => {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        fetchSettings();
    }, []);

    const fetchSettings = async () => {
        try {
            setLoading(true);
            const data = await apiClient.get('settings').json<SystemSettings>();
            form.setFieldsValue(data);
        } catch (error) {
            console.error('Failed to fetch settings:', error);
            message.error('Erreur lors de la récupération des paramètres');
        } finally {
            setLoading(false);
        }
    };

    const onFinish = async (values: SystemSettings) => {
        try {
            setSaving(true);
            await apiClient.patch('settings', { json: values }).json();
            message.success('Paramètres mis à jour avec succès');
        } catch (error) {
            console.error('Failed to update settings:', error);
            message.error('Erreur lors de la mise à jour des paramètres');
        } finally {
            setSaving(false);
        }
    };

    if (loading) {
        return (
            <div style={{ textAlign: 'center', padding: '50px' }}>
                <Spin size="large" />
            </div>
        );
    }

    return (
        <div style={{ maxWidth: 800, margin: '0 auto' }}>
            <Title level={2}>
                <SettingOutlined /> Paramètres du Système
            </Title>
            <Text type="secondary">
                Configurez les frais de service et les tarifs de livraison appliqués à l'ensemble de la plateforme.
            </Text>

            <Card style={{ marginTop: 24 }}>
                <Form
                    form={form}
                    layout="vertical"
                    onFinish={onFinish}
                    initialValues={{ serviceFeePercentage: 5, shippingFee: 25 }}
                >
                    <Form.Item
                        label="Frais de service (%)"
                        name="serviceFeePercentage"
                        extra="Pourcentage prélevé sur le prix de l'article (ex: 5.0)"
                        rules={[{ required: true, message: 'Veuillez saisir le pourcentage' }]}
                    >
                        <InputNumber
                            min={0}
                            max={100}
                            step={0.1}
                            style={{ width: '100%' }}
                            formatter={(value) => `${value}%`}
                            parser={(value) => value!.replace('%', '') as any}
                        />
                    </Form.Item>

                    <Form.Item
                        label="Frais de livraison fixes (MAD)"
                        name="shippingFee"
                        extra="Montant fixe ajouté à chaque commande (ex: 25.0)"
                        rules={[{ required: true, message: 'Veuillez saisir les frais de livraison' }]}
                    >
                        <InputNumber
                            min={0}
                            style={{ width: '100%' }}
                            formatter={(value) => `${value} MAD`}
                            parser={(value) => value!.replace(' MAD', '') as any}
                        />
                    </Form.Item>

                    <Form.Item>
                        <Space>
                            <Button
                                type="primary"
                                htmlType="submit"
                                icon={<SaveOutlined />}
                                loading={saving}
                            >
                                Enregistrer les modifications
                            </Button>
                        </Space>
                    </Form.Item>
                </Form>
            </Card>
        </div>
    );
};

export default SettingsPage;
