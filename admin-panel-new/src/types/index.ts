export enum ProductStatus {
    PENDING_APPROVAL = 'PENDING_APPROVAL',
    PUBLISHED = 'PUBLISHED',
    REJECTED = 'REJECTED',
    RESERVED = 'RESERVED',
    CONFIRMED = 'CONFIRMED',
    SOLD = 'SOLD',
}

export interface User {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    role: string;
    avatarUrl?: string;
}

export interface Category {
    id: string;
    name: string;
    slug: string;
    level: number;
    parentId?: string;
    sizeType?: string;
    possibleSizes?: string[];
}

export interface ProductImage {
    id: string;
    url: string;
    isMain: boolean;
}

export interface Product {
    id: string;
    title: string;
    description: string;
    price: number;
    status: ProductStatus;
    category: Category;
    seller: User;
    images: ProductImage[];
    createdAt: string;
}

export enum OrderStatus {
    OFFER_MADE = 'OFFER_MADE',
    AWAITING_SELLER_CONFIRMATION = 'AWAITING_SELLER_CONFIRMATION',
    CONFIRMED = 'CONFIRMED',
    SHIPPED = 'SHIPPED',
    DELIVERED = 'DELIVERED',
    RETURN_WINDOW_48H = 'RETURN_WINDOW_48H',
    RETURN_REQUESTED = 'RETURN_REQUESTED',
    RETURNED = 'RETURNED',
    CANCELLED = 'CANCELLED',
    COMPLETED = 'COMPLETED',
}

export interface Order {
    id: string;
    totalPrice: number;
    status: OrderStatus;
    createdAt: string;
    buyer: User;
    seller: User;
    product: Product;
}
