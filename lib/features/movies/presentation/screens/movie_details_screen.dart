import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/tmdb_images.dart';
import '../../../../core/widgets/poster_image.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../watchlist/presentation/providers/watchlist_provider.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_details.dart';
import '../providers/movie_details_provider.dart';

/// Full movie detail screen.
///
/// The base [movie] (from the previous list) is always shown immediately, which
/// also means saved movies remain viewable offline. Extended fields (runtime,
/// genres, tagline) are loaded from the network and degrade gracefully when
/// unavailable.
class MovieDetailsScreen extends ConsumerStatefulWidget {
  const MovieDetailsScreen({super.key, required this.movie});

  final Movie movie;

  @override
  ConsumerState<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends ConsumerState<MovieDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  static const double _expandedHeight = 240;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// The backdrop is expanded until the app bar collapses onto the surface
  /// colour; icon and status-bar contrast are flipped at that threshold so
  /// they stay legible over both the artwork and the solid bar.
  void _onScroll() {
    const threshold = _expandedHeight - kToolbarHeight;
    final collapsed =
        _scrollController.hasClients && _scrollController.offset > threshold;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final details = ref.watch(movieDetailsProvider(movie.id));

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _BackdropAppBar(
            movie: movie,
            expandedHeight: _expandedHeight,
            isCollapsed: _isCollapsed,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(movie: movie),
                  const SizedBox(height: AppSpacing.lg),
                  _WatchlistButton(movie: movie),
                  const SizedBox(height: AppSpacing.xl),
                  details.when(
                    loading: () => const _DetailsExtras.loading(),
                    error: (error, _) =>
                        _DetailsExtras.unavailable(messageForError(error)),
                    data: (data) => _DetailsExtras(details: data),
                  ),
                  _Overview(movie: movie),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropAppBar extends StatelessWidget {
  const _BackdropAppBar({
    required this.movie,
    required this.expandedHeight,
    required this.isCollapsed,
  });

  final Movie movie;
  final double expandedHeight;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Expanded: icons sit over dark artwork, so force light. Collapsed: they
    // sit over the surface colour, so follow the theme's brightness.
    final onSurfaceContent = isCollapsed ? scheme.onSurface : Colors.white;
    final overlayStyle = isCollapsed
        ? (theme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
        : SystemUiOverlayStyle.light;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: scheme.surface,
      foregroundColor: onSurfaceContent,
      systemOverlayStyle: overlayStyle,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PosterImage(
              url:
                  TmdbImages.backdrop(movie.backdropPath) ??
                  TmdbImages.poster(movie.posterPath),
              iconSize: 48,
            ),
            // Scrim keeps the status bar icons and title legible over art.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    scheme.surface.withValues(alpha: 0.9),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = movie.releaseYear;
    final rating = movie.formattedRating;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: 96,
            height: 144,
            child: PosterImage(url: TmdbImages.poster(movie.posterPath)),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                movie.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (year != null)
                    _MetaChip(icon: Icons.calendar_today_outlined, label: year),
                  if (rating != null)
                    _MetaChip(
                      icon: Icons.star_rounded,
                      label: rating,
                      iconColor: theme.colorScheme.tertiary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WatchlistButton extends ConsumerWidget {
  const _WatchlistButton({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isInWatchlistProvider(movie.id));

    return SizedBox(
      width: double.infinity,
      child: saved
          ? OutlinedButton.icon(
              onPressed: () =>
                  ref.read(watchlistProvider.notifier).remove(movie.id),
              icon: const Icon(Icons.bookmark_added_rounded),
              label: const Text('Saved to Watchlist'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: () => ref.read(watchlistProvider.notifier).add(movie),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Add to Watchlist'),
            ),
    );
  }
}

/// The network-backed extended details: tagline, genres, runtime, status.
class _DetailsExtras extends StatelessWidget {
  const _DetailsExtras({required this.details})
    : _loading = false,
      _errorMessage = null;

  const _DetailsExtras.loading()
    : details = null,
      _loading = true,
      _errorMessage = null;

  const _DetailsExtras.unavailable(String message)
    : details = null,
      _loading = false,
      _errorMessage = message;

  final MovieDetails? details;
  final bool _loading;
  final String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 180, height: 14),
            SizedBox(height: AppSpacing.md),
            SkeletonBox(width: 120, height: 28, radius: AppRadius.sm),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Additional details unavailable. $_errorMessage',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final data = details!;
    final chips = <Widget>[
      if (data.formattedRuntime != null)
        _InfoPill(icon: Icons.schedule, label: data.formattedRuntime!),
      for (final genre in data.genres) _InfoPill(label: genre.name),
      if (data.status != null && data.status != 'Released')
        _InfoPill(label: data.status!),
    ];

    if (data.tagline == null && chips.isEmpty) {
      return const SizedBox(height: AppSpacing.xs);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.tagline != null) ...[
            Text(
              data.tagline!,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (chips.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: chips,
            ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overview = movie.overview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          (overview == null || overview.isEmpty)
              ? 'No overview is available for this movie.'
              : overview,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: overview == null ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}
