import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../movies/domain/entities/movie.dart';
import '../providers/watchlist_provider.dart';

/// A compact bookmark toggle for movie cards. Reflects and updates watchlist
/// state immediately when tapped.
class WatchlistIconButton extends ConsumerWidget {
  const WatchlistIconButton({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isInWatchlistProvider(movie.id));
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () => ref.read(watchlistProvider.notifier).toggle(movie),
      tooltip: saved ? 'Remove from watchlist' : 'Add to watchlist',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          key: ValueKey(saved),
          color: saved ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
