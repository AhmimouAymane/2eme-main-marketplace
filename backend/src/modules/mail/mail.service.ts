import { Injectable } from '@nestjs/common';
import { MailerService } from '@nestjs-modules/mailer';

@Injectable()
export class MailService {
    constructor(private mailerService: MailerService) { }

    async sendVerificationCode(email: string, code: string) {
        try {
            await this.mailerService.sendMail({
                to: email,
                subject: 'Votre code de vérification Clovi',
                html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
            <h2 style="color: #42C67E; text-align: center;">Bienvenue chez Clovi !</h2>
            <p>Voici votre code de vérification pour finaliser votre inscription ou réinitialiser votre mot de passe :</p>
            <div style="background: #f9f9f9; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #333; border-radius: 5px; margin: 20px 0;">
              ${code}
            </div>
            <p>Ce code est valable pendant 15 minutes.</p>
            <p style="font-size: 12px; color: #888;">Si vous n'avez pas demandé ce code, vous pouvez ignorer cet email en toute sécurité.</p>
            <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
            <p style="text-align: center; color: #42C67E; font-weight: bold;">L'équipe Clovi</p>
          </div>
        `,
            });
            console.log(`[MailService] Verification code sent to ${email}`);
        } catch (error) {
            console.error(`[MailService] Failed to send email to ${email}:`, error);
            // We don't throw here to avoid blocking the whole process in dev
            // but in prod we might want to know.
        }
    }
}
