import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../watchlist/presentation/screens/watchlist_screen.dart';
import '../../../watchlist/presentation/widgets/watchlist_icon_button.dart';
import '../providers/trending_provider.dart';
import '../widgets/movie_list_skeleton.dart';
import '../widgets/movie_list_tile.dart';
import '../widgets/theme_mode_button.dart';
import 'movie_details_screen.dart';
import 'search_screen.dart';

/// The landing screen: shows a search entry point and the weekly trending list.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        actions: [
          IconButton(
            tooltip: 'Watchlist',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const WatchlistScreen()),
            ),
          ),
          const ThemeModeButton(),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _SearchEntryPoint(),
            const _SectionHeader(title: 'Trending this week'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(trendingProvider.notifier).refresh(),
                child: trending.when(
                  loading: () => const MovieListSkeleton(),
                  error: (error, _) => _RefreshableMessage(
                    icon: Icons.cloud_off_rounded,
                    title: 'Unable to load movies.',
                    message: messageForError(error),
                    onRetry: () =>
                        ref.read(trendingProvider.notifier).refresh(),
                  ),
                  data: (movies) {
                    if (movies.isEmpty) {
                      return const _RefreshableMessage(
                        icon: Icons.movie_filter_outlined,
                        title: 'No trending movies right now.',
                        message: 'Pull down to refresh and try again.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        final movie = movies[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: MovieListTile(
                            movie: movie,
                            trailing: WatchlistIconButton(movie: movie),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    MovieDetailsScreen(movie: movie),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A non-editable search field that navigates to the dedicated search screen.
class _SearchEntryPoint extends StatelessWidget {
  const _SearchEntryPoint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Search movies',
                  style: theme.textTheme.bodyLarge?.copyWith(
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Wraps a [MessageView] in an always-scrollable list so it fills the viewport
/// and still responds to the surrounding pull-to-refresh gesture.
class _RefreshableMessage extends StatelessWidget {
  const _RefreshableMessage({
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: MessageView(
                icon: icon,
                title: title,
                message: message,
                onRetry: onRetry,
              ),
            ),
          ],
        );
      },
    );
  }
}
