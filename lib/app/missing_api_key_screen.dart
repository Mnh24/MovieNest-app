import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';

/// Shown when the app is launched without a TMDB configuration so the failure
/// mode is clear and actionable rather than a stream of network errors.
class MissingApiKeyScreen extends StatelessWidget {
  const MissingApiKeyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.key_off_outlined,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'TMDB not configured',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Point the app at the backend proxy (recommended):\n\n'
                  'flutter run\n'
                  '  --dart-define=TMDB_PROXY_URL=your_proxy_url\n\n'
                  'or, for local dev, pass a TMDB key directly:\n\n'
                  'flutter run --dart-define=TMDB_API_KEY=your_key',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
