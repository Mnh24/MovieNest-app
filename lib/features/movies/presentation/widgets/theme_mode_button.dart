import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';

/// App bar action that opens a menu to switch between light, dark and system
/// themes. The current selection is checked and persisted on change.
class ThemeModeButton extends ConsumerWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      icon: Icon(_iconFor(mode)),
      onSelected: (value) =>
          ref.read(themeModeProvider.notifier).setThemeMode(value),
      itemBuilder: (context) => [
        _item(
          context,
          ThemeMode.light,
          'Light',
          Icons.light_mode_outlined,
          mode,
        ),
        _item(context, ThemeMode.dark, 'Dark', Icons.dark_mode_outlined, mode),
        _item(
          context,
          ThemeMode.system,
          'System',
          Icons.brightness_auto_outlined,
          mode,
        ),
      ],
    );
  }

  PopupMenuItem<ThemeMode> _item(
    BuildContext context,
    ThemeMode value,
    String label,
    IconData icon,
    ThemeMode current,
  ) {
    return PopupMenuItem<ThemeMode>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          if (value == current)
            Icon(
              Icons.check,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }

  IconData _iconFor(ThemeMode mode) => switch (mode) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_outlined,
  };
}
