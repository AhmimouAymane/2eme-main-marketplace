import React from 'react';
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom';
import MainLayout from './components/MainLayout';
import LoginPage from './pages/Login/LoginPage';
import ProductListPage from './pages/Products/ProductListPage';
import OrderListPage from './pages/Orders/OrderListPage';
import DashboardPage from './pages/DashboardPage';
import { useAuthStore } from './store/authStore';

import CategoryPage from './pages/Categories/CategoryPage';

// Protected Route Guard
const ProtectedRoute = () => {
    const { token, user } = useAuthStore();

    if (!token || user?.role !== 'ADMIN') {
        return <Navigate to="/login" replace />;
    }

    return <Outlet />;
};

function App() {
    return (
        <BrowserRouter>
            <Routes>
                <Route path="/login" element={<LoginPage />} />

                <Route element={<ProtectedRoute />}>
                    <Route element={<MainLayout />}>
                        <Route path="/" element={<DashboardPage />} />
                        <Route path="/products" element={<ProductListPage />} />
                        <Route path="/orders" element={<OrderListPage />} />
                        <Route path="/categories" element={<CategoryPage />} />
                    </Route>
                </Route>

                <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
        </BrowserRouter>
    );
}

export default App;
