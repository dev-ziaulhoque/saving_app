import 'dart:io';

import 'package:dio/dio.dart';

import '../../app/app_config/app_config.dart';
import '../../core/utils/app_logger.dart';

class CloudinaryService {
  CloudinaryService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  static Future<String> uploadAvatar(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    AppLogger.request('cloudinary.uploadAvatar', {
      'file_name': fileName,
      'bytes': await file.length(),
    });
    final formData = FormData.fromMap({
      'upload_preset': AppConfig.cloudinaryAvatarPreset,
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'https://api.cloudinary.com/v1_1/'
        '${AppConfig.cloudinaryCloudName}/image/upload',
        data: formData,
      );
      final secureUrl = response.data?['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw StateError('Cloudinary did not return an image URL');
      }
      AppLogger.success('cloudinary.uploadAvatar', {
        'status_code': response.statusCode,
        'secure_url': secureUrl,
      });
      return secureUrl;
    } catch (error) {
      AppLogger.error('cloudinary.uploadAvatar', error);
      rethrow;
    }
  }
}
