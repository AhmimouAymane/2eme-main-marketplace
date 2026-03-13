import ky from 'ky';
import { API_URL } from '../theme/constants';
import { useAuthStore } from '../store/authStore';

export const apiClient = ky.create({
    prefixUrl: API_URL,
    retry: {
        limit: 2,
        methods: ['get'],
        statusCodes: [408, 413, 429, 500, 502, 503, 504]
    },
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
                const { token, refreshToken, logout, setToken } = useAuthStore.getState();

                // If 401 and we have a refresh token, try to refresh
                if (response.status === 401 && !request.url.includes('auth/login') && !request.url.includes('auth/refresh') && refreshToken) {
                    try {
                        const refreshResponse: any = await ky.post(`${API_URL}auth/refresh`, {
                            json: { refreshToken }
                        }).json();

                        const newToken = refreshResponse.accessToken;
                        if (newToken) {
                            setToken(newToken);
                            
                            // Retry original request
                            request.headers.set('Authorization', `Bearer ${newToken}`);
                            return ky(request);
                        }
                    } catch (error) {
                        console.error('Token refresh failed:', error);
                        logout();
                        window.location.href = '/login';
                    }
                }

                // Normal 401 handling
                if (response.status === 401 && !request.url.includes('auth/login')) {
                    logout();
                    window.location.href = '/login';
                }
            },
        ],
    },
});
