import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';

/// A glass icon button that opens a compact glass segmented control for
/// switching between light, dark and system theme — replaces a stock
/// [PopupMenuButton] so the control matches the rest of the app's liquid
/// glass language instead of a flat Material menu.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Theme',
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: CircleBorder(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _openPicker(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(_iconFor(mode), color: scheme.onSurface, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ThemeModeSheet(),
    );
  }

  IconData _iconFor(ThemeMode mode) => switch (mode) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_outlined,
  };
}

class _ThemeModeSheet extends ConsumerWidget {
  const _ThemeModeSheet();

  static const _options = [
    (mode: ThemeMode.light, icon: Icons.light_mode_rounded, label: 'Light'),
    (mode: ThemeMode.dark, icon: Icons.dark_mode_rounded, label: 'Dark'),
    (
      mode: ThemeMode.system,
      icon: Icons.brightness_auto_rounded,
      label: 'System',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottomInset + AppSpacing.lg,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final option in _options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ThemeOptionTile(
                      icon: option.icon,
                      label: option.label,
                      selected: option.mode == mode,
                      onTap: () {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(option.mode);
                        Navigator.of(context).pop();
                      },
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

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : null,
                ),
              ),
              const Spacer(),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
