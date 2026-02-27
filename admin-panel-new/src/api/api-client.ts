import ky from 'ky';
import { API_URL } from '../theme/constants';
import { useAuthStore } from '../store/authStore';

export const apiClient = ky.create({
    prefixUrl: API_URL,
    hooks: {
        beforeRequest: [
            (request) => {
                const token = useAuthStore.getState().token;
                if (token) {
                    request.headers.set('Authorization', `Bearer ${token}`);
                }
            },
        ],
        afterResponse: [
            async (request, _options, response) => {
                // Don't redirect if we're already trying to login and it fails
                if (response.status === 401 && !request.url.includes('auth/login')) {
                    useAuthStore.getState().logout();
                    window.location.href = '/login';
                }
            },
        ],
    },
});
