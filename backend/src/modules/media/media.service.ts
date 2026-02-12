import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import { UploadApiResponse, UploadApiErrorResponse } from 'cloudinary';
import * as streamifier from 'streamifier';

@Injectable()
export class MediaService {
    constructor(private configService: ConfigService) {
        cloudinary.config({
            cloud_name: this.configService.get<string>('CLOUDINARY_CLOUD_NAME'),
            api_key: this.configService.get<string>('CLOUDINARY_API_KEY'),
            api_secret: this.configService.get<string>('CLOUDINARY_API_SECRET'),
        });
    }

    async uploadFile(file: Express.Multer.File): Promise<string> {
        return new Promise((resolve, reject) => {
            const uploadStream = cloudinary.uploader.upload_stream(
                {
                    folder: 'marketplace',
                },
                (error: UploadApiErrorResponse, result: UploadApiResponse) => {
                    if (error) {
                        console.error('Cloudinary Upload Error:', error);
                        return reject(new BadRequestException(`Cloudinary Error: ${error.message}`));
                    }
                    console.log('Cloudinary Upload Success:', result.secure_url);
                    resolve(result.secure_url);
                },
            );

            if (!file.buffer) {
                console.error('File buffer is undefined for file:', file.originalname);
                return reject(new BadRequestException('File buffer is empty'));
            }

            streamifier.createReadStream(file.buffer).pipe(uploadStream);
        });
    }

    async uploadFiles(files: Array<Express.Multer.File>): Promise<string[]> {
        const uploadPromises = files.map((file) => this.uploadFile(file));
        return Promise.all(uploadPromises);
    }

    async deleteFile(url: string): Promise<void> {
        try {
            // Extract public_id from URL
            // Example: https://res.cloudinary.com/cloud_name/image/upload/v1234567890/folder/public_id.jpg
            const splitUrl = url.split('/');
            const filename = splitUrl[splitUrl.length - 1];
            const publicId = filename.split('.')[0];
            const folder = 'marketplace'; // Assuming fixed folder for now
            const fullPublicId = `${folder}/${publicId}`;

            await cloudinary.uploader.destroy(fullPublicId);
        } catch (error) {
            console.error('Cloudinary Deletion Error:', error);
            // We don't throw here to avoid blocking the main operation if image deletion fails
        }
    }

    async deleteFiles(urls: string[]): Promise<void> {
        const deletePromises = urls.map((url) => this.deleteFile(url));
        await Promise.all(deletePromises);
    }
}
