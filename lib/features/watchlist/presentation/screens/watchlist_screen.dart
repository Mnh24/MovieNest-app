import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routes/glass_page_route.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../movies/domain/entities/movie.dart';
import '../../../movies/presentation/screens/movie_details_screen.dart';
import '../../../movies/presentation/widgets/movie_list_tile.dart';
import '../../../movies/presentation/widgets/staggered_list_item.dart';
import '../providers/watchlist_provider.dart';

/// Displays the locally persisted watchlist. Fully available offline since it
/// reads only from local storage.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(watchlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Watchlist',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: movies.isEmpty
            ? const MessageView(
                icon: Icons.bookmark_border_rounded,
                title: 'No movies saved yet',
                message:
                    "Add movies to your watchlist and they'll remain "
                    'available here even when you\'re offline.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: StaggeredListItem(
                      index: index,
                      child: _WatchlistTile(movie: movie),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _WatchlistTile extends ConsumerWidget {
  const _WatchlistTile({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroTag = 'watchlist-poster-${movie.id}';
    return MovieListTile(
      movie: movie,
      heroTag: heroTag,
      onTap: () => Navigator.of(context).push(
        GlassPageRoute<void>(
          builder: (_) => MovieDetailsScreen(movie: movie, heroTag: heroTag),
        ),
      ),
      trailing: IconButton(
        tooltip: 'Remove from watchlist',
        icon: const Icon(Icons.delete_outline_rounded),
        onPressed: () async {
          await ref.read(watchlistProvider.notifier).remove(movie.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Removed "${movie.title}"'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () =>
                      ref.read(watchlistProvider.notifier).add(movie),
                ),
              ),
            );
        },
      ),
    );
  }
}
