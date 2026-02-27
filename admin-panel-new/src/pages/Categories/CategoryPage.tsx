import React, { useEffect, useState } from 'react';
import { Table, Button, Space, message, Modal, Form, Input, Select, Tag, Tooltip } from 'antd';
import { RefreshCw, Plus, Edit, Trash2 } from 'lucide-react';
import { apiClient } from '../../api/api-client';

const CategoryPage: React.FC = () => {
    const [categories, setCategories] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [modalVisible, setModalVisible] = useState(false);
    const [editingCategory, setEditingCategory] = useState<any>(null);
    const [form] = Form.useForm();
    const [sizes, setSizes] = useState<string[]>([]);
    const [sizeInput, setSizeInput] = useState('');

    const fetchCategories = async () => {
        setLoading(true);
        try {
            const response: any = await apiClient.get('categories?flat=true').json();
            setCategories(Array.isArray(response) ? response : response.data || []);
        } catch (error) {
            message.error('Failed to fetch categories');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchCategories();
    }, []);

    const handleAddSize = () => {
        if (sizeInput && !sizes.includes(sizeInput)) {
            setSizes([...sizes, sizeInput]);
            setSizeInput('');
        }
    };

    const handleRemoveSize = (removedSize: string) => {
        setSizes(sizes.filter(size => size !== removedSize));
    };

    const showModal = (category?: any) => {
        if (category) {
            setEditingCategory(category);
            form.setFieldsValue({
                ...category,
                parentId: category.parentId || undefined
            });
            setSizes(category.possibleSizes || []);
        } else {
            setEditingCategory(null);
            form.resetFields();
            setSizes([]);
        }
        setModalVisible(true);
    };

    const handleSave = async () => {
        try {
            const values = await form.validateFields();
            const data = { ...values, possibleSizes: sizes };

            if (editingCategory) {
                await apiClient.patch(`categories/${editingCategory.id}`, { json: data }).json();
                message.success('Category updated');
            } else {
                await apiClient.post('categories', { json: data }).json();
                message.success('Category created');
            }

            setModalVisible(false);
            fetchCategories();
        } catch (error) {
            message.error('Failed to save category');
        }
    };

    const handleDelete = async (id: string) => {
        Modal.confirm({
            title: 'Are you sure you want to delete this category?',
            content: 'This action cannot be undone.',
            okText: 'Yes, Delete',
            okType: 'danger',
            onOk: async () => {
                try {
                    await apiClient.delete(`categories/${id}`).json();
                    message.success('Category deleted');
                    fetchCategories();
                } catch (error) {
                    message.error('Failed to delete category');
                }
            }
        });
    };

    const columns = [
        {
            title: 'Name',
            dataIndex: 'name',
            key: 'name',
            render: (text: string, record: any) => (
                <span style={{ marginLeft: record.level * 20 }}>
                    {record.level > 0 ? '↳ ' : ''}{text}
                </span>
            )
        },
        {
            title: 'Slug',
            dataIndex: 'slug',
            key: 'slug',
        },
        {
            title: 'Level',
            dataIndex: 'level',
            key: 'level',
        },
        {
            title: 'Sizes',
            dataIndex: 'possibleSizes',
            key: 'sizes',
            render: (sizes: string[]) => (
                <>
                    {sizes?.map(size => (
                        <Tag key={size} color="blue">{size}</Tag>
                    ))}
                </>
            )
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, record: any) => (
                <Space>
                    <Button icon={<Edit size={14} />} size="small" onClick={() => showModal(record)}>Edit</Button>
                    <Button icon={<Trash2 size={14} />} size="small" danger onClick={() => handleDelete(record.id)}>Delete</Button>
                </Space>
            )
        }
    ];

    return (
        <div>
            <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <h2 style={{ margin: 0 }}>Category Management</h2>
                <Space>
                    <Button icon={<RefreshCw size={16} />} onClick={fetchCategories} loading={loading}>
                        Refresh
                    </Button>
                    <Button type="primary" icon={<Plus size={16} />} onClick={() => showModal()}>
                        Add Category
                    </Button>
                </Space>
            </div>

            <Table
                columns={columns}
                dataSource={categories}
                rowKey="id"
                loading={loading}
                pagination={false}
            />

            <Modal
                title={editingCategory ? "Edit Category" : "Add Category"}
                open={modalVisible}
                onOk={handleSave}
                onCancel={() => setModalVisible(false)}
                width={600}
            >
                <Form form={form} layout="vertical">
                    <Form.Item name="name" label="Name" rules={[{ required: true }]}>
                        <Input placeholder="e.g. Shoes" />
                    </Form.Item>
                    <Form.Item name="slug" label="Slug" rules={[{ required: true }]}>
                        <Input placeholder="e.g. shoes" />
                    </Form.Item>
                    <Form.Item name="level" label="Level" rules={[{ required: true }]}>
                        <Select options={[
                            { label: 'Level 0 (Genre)', value: 0 },
                            { label: 'Level 1 (Category)', value: 1 },
                            { label: 'Level 2 (Sub-category)', value: 2 },
                        ]} />
                    </Form.Item>
                    <Form.Item name="parentId" label="Parent Category">
                        <Select showSearch allowClear placeholder="Select parent" optionFilterProp="children">
                            {categories.map(c => (
                                <Select.Option key={c.id} value={c.id}>{c.name} (L{c.level})</Select.Option>
                            ))}
                        </Select>
                    </Form.Item>

                    <div style={{ marginBottom: 8, fontWeight: 500 }}>Sizes (Possible Sizes)</div>
                    <div style={{ marginBottom: 16 }}>
                        <Space wrap style={{ marginBottom: 8 }}>
                            {sizes.map(size => (
                                <Tag key={size} closable onClose={() => handleRemoveSize(size)}>
                                    {size}
                                </Tag>
                            ))}
                        </Space>
                        <div style={{ display: 'flex', gap: 8 }}>
                            <Input
                                placeholder="Enter size (e.g. XL, 42, 6 months)"
                                value={sizeInput}
                                onChange={e => setSizeInput(e.target.value)}
                                onPressEnter={(e) => { e.preventDefault(); handleAddSize(); }}
                            />
                            <Button type="dashed" onClick={handleAddSize}>Add size</Button>
                        </div>
                    </div>
                </Form>
            </Modal>
        </div>
    );
};

export default CategoryPage;
