import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Persists and exposes the user's selected [ThemeMode].
///
/// The choice is stored in shared preferences so it survives restarts, and read
/// synchronously on start so the app never flashes the wrong theme.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _key = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return _decode(stored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }

  ThemeMode _decode(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      // Default before the user has ever chosen: the app is designed
      // dark-first (cinematic glass), so open in dark rather than following
      // the OS.
      _ => ThemeMode.dark,
    };
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
