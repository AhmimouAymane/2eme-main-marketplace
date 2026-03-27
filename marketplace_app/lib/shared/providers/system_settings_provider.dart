import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:marketplace_app/shared/models/system_settings_model.dart';


final systemSettingsProvider = FutureProvider.autoDispose<SystemSettingsModel>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('settings');
  return SystemSettingsModel.fromJson(response.data);
});
