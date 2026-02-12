import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class OptionalAuthGuard extends AuthGuard('jwt') {
    handleRequest(err: any, user: any, info: any) {
        // If there's an error or no user, just return null instead of throwing
        if (err || !user) {
            return null;
        }
        return user;
    }
}
