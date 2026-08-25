import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../features/movies/presentation/screens/home_screen.dart';
import 'missing_api_key_screen.dart';

/// Root widget wiring the Material 3 themes, persisted theme mode, and home.
class MovieApp extends ConsumerWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Movies',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: AppConfig.hasApiKey
          ? const HomeScreen()
          : const MissingApiKeyScreen(),
    );
  }
}
