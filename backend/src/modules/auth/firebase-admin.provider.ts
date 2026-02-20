import { Provider } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as path from 'path';

export const FirebaseAdminProvider: Provider = {
    provide: 'FIREBASE_ADMIN',
    useFactory: () => {
        const serviceAccountPath = path.resolve(process.cwd(), 'firebase-service-account.json');

        // Check if initialization is already done
        if (admin.apps.length === 0) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccountPath),
            });
        }

        return admin;
    },
};
