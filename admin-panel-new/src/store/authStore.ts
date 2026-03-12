import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
    token: string | null;
    refreshToken: string | null;
    user: any | null;
    setAuth: (token: string, refreshToken: string, user: any) => void;
    setToken: (token: string) => void;
    logout: () => void;
    isAuthenticated: () => boolean;
}

export const useAuthStore = create<AuthState>()(
    persist(
        (set, get) => ({
            token: null,
            refreshToken: null,
            user: null,
            setAuth: (token, refreshToken, user) => set({ token, refreshToken, user }),
            setToken: (token) => set({ token }),
            logout: () => set({ token: null, refreshToken: null, user: null }),
            isAuthenticated: () => !!get().token,
        }),
        {
            name: 'clovi-admin-auth', // localStorage key
        }
    )
);
