import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/shared/services/cache_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart with an override');
});

final cacheServiceProvider = Provider((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CacheService(prefs);
});
