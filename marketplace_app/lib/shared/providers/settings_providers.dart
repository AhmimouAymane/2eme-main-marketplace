import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace_app/core/constants/app_constants.dart';

/// Saved theme from disk (loaded once at app start)
final savedThemeProvider = FutureProvider<ThemeMode>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final s = prefs.getString(AppConstants.keyThemeMode);
  if (s == 'dark') return ThemeMode.dark;
  if (s == 'light') return ThemeMode.light;
  return ThemeMode.system;
});

/// User's current theme choice (overrides saved once set in this session)
class CurrentThemeNotifier extends StateNotifier<ThemeMode?> {
  CurrentThemeNotifier() : super(null);

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyThemeMode,
      mode == ThemeMode.dark ? 'dark' : (mode == ThemeMode.light ? 'light' : 'system'),
    );
  }
}

final currentThemeProvider = StateNotifierProvider<CurrentThemeNotifier, ThemeMode?>((ref) => CurrentThemeNotifier());

/// Resolved theme: current override or saved, else system
final themeModeProvider = Provider<ThemeMode>((ref) {
  final current = ref.watch(currentThemeProvider);
  if (current != null) return current;
  final saved = ref.watch(savedThemeProvider);
  return saved.when(
    data: (t) => t,
    loading: () => ThemeMode.system,
    error: (_, __) => ThemeMode.system,
  );
});

const String _keyNotifications = 'notifications_enabled';

final notificationsEnabledProvider = StateNotifierProvider<NotificationsNotifier, bool>((ref) => NotificationsNotifier());

class NotificationsNotifier extends StateNotifier<bool> {
  NotificationsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_keyNotifications) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, value);
  }
}
