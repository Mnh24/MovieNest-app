import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../features/movies/presentation/screens/home_screen.dart';
import '../features/movies/presentation/screens/search_screen.dart';
import '../features/watchlist/presentation/screens/watchlist_screen.dart';

/// Hosts the three primary destinations (Home, Watchlist, Search) behind a
/// persistent bottom navigation bar, keeping each tab's scroll position and
/// state alive as the user switches between them.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.favorite_rounded, label: 'Watchlist'),
    (icon: Icons.search_rounded, label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), WatchlistScreen(), SearchScreen()],
      ),
      bottomNavigationBar: _NavBar(
        index: _index,
        destinations: _destinations,
        onSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.index,
    required this.destinations,
    required this.onSelected,
  });

  final int index;
  final List<({IconData icon, String label})> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        bottomInset + AppSpacing.md,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg * 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(
                alpha: isDark ? 0.55 : 0.8,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg * 2),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / destinations.length;
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      left: itemWidth * index,
                      width: itemWidth,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: itemWidth - AppSpacing.sm,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: [
                              BoxShadow(
                                color: scheme.primary.withValues(alpha: 0.5),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          SizedBox(
                            width: itemWidth,
                            child: _NavIcon(
                              icon: destinations[i].icon,
                              label: destinations[i].label,
                              selected: i == index,
                              onTap: () => onSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
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
    final color = selected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      )
                    : const SizedBox(width: 0, height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
