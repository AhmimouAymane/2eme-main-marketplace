import { Provider } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';

export const FirebaseAdminProvider: Provider = {
    provide: 'FIREBASE_ADMIN',
    useFactory: () => {
        if (admin.apps.length === 0) {
            const serviceAccountVar = process.env.FIREBASE_SERVICE_ACCOUNT;

            if (serviceAccountVar) {
                try {
                    const serviceAccount = JSON.parse(serviceAccountVar);
                    admin.initializeApp({
                        credential: admin.credential.cert(serviceAccount),
                    });
                    console.log('Firebase Admin initialized from environment variable');
                } catch (error) {
                    console.error('Failed to parse FIREBASE_SERVICE_ACCOUNT env var:', error);
                }
            } else {
                const serviceAccountPath = path.resolve(process.cwd(), 'firebase-service-account.json');
                try {
                    admin.initializeApp({
                        credential: admin.credential.cert(serviceAccountPath),
                    });
                    console.log('Firebase Admin initialized from local file');
                } catch (error) {
                    console.warn('Firebase service account file not found and env var missing. Social login may not work.');
                }
            }
        }
        return admin;
    },
};
