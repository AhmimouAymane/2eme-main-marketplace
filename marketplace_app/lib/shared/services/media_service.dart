import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

/// Service pour gérer les uploads de fichiers
class MediaService {
  final Dio _dio;

  MediaService(this._dio);

  /// Upload une seule image
  Future<String> uploadImage(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.name; // Utiliser file.name au lieu de décoder le path
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dio.post(
        '/media/upload',
        data: formData,
      );

      if (response.statusCode == 201) {
        return response.data['url'] as String;
      }
      throw Exception('Failed to upload image');
    } catch (e) {
      rethrow;
    }
  }

  /// Upload plusieurs images
  Future<List<String>> uploadImages(List<XFile> files) async {
    try {
      final formData = FormData();
      
      for (var file in files) {
        final bytes = await file.readAsBytes();
        final fileName = file.name;
        formData.files.add(
          MapEntry(
            'files',
            MultipartFile.fromBytes(bytes, filename: fileName),
          ),
        );
      }

      final response = await _dio.post(
        '/media/upload-multiple',
        data: formData,
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data;
        return data.map((item) => item['url'] as String).toList();
      }
      throw Exception('Failed to upload images');
    } catch (e) {
      rethrow;
    }
  }
}
