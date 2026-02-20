import { Module, Global } from '@nestjs/common';
import { FirebaseAdminProvider } from '../auth/firebase-admin.provider';

@Global()
@Module({
    providers: [FirebaseAdminProvider],
    exports: [FirebaseAdminProvider],
})
export class FirebaseModule { }
