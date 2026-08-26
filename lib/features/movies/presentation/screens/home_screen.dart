import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/tmdb_images.dart';
import '../../../../core/widgets/poster_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../watchlist/presentation/providers/watchlist_provider.dart';
import '../../domain/entities/movie.dart';
import '../providers/movie_details_provider.dart';
import '../providers/trending_provider.dart';
import 'movie_details_screen.dart';
import 'search_screen.dart';

/// The landing screen: a full-bleed hero for this week's top trending movie
/// with a poster strip of the rest of the list beneath it, styled after a
/// cinema-app "now showing" hero header.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _focusedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final trending = ref.watch(trendingProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () => ref.read(trendingProvider.notifier).refresh(),
        child: trending.when(
          loading: () => const _HomeSkeleton(),
          error: (error, _) => SafeArea(
            child: _RefreshableMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load movies.',
              message: messageForError(error),
              onRetry: () => ref.read(trendingProvider.notifier).refresh(),
            ),
          ),
          data: (movies) {
            if (movies.isEmpty) {
              return const SafeArea(
                child: _RefreshableMessage(
                  icon: Icons.movie_filter_outlined,
                  title: 'No trending movies right now.',
                  message: 'Pull down to refresh and try again.',
                ),
              );
            }

            final focused = movies[_focusedIndex.clamp(0, movies.length - 1)];
            // RootShell's nav bar floats over the body (extendBody: true), so
            // reserve enough bottom space that the poster strip's captions
            // don't sit behind it.
            final navBarClearance =
                MediaQuery.paddingOf(context).bottom + 96;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _HeroHeader(movie: focused),
                const SizedBox(height: AppSpacing.xl),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Text(
                    'Trending now',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _PosterStrip(
                  movies: movies,
                  focusedIndex: _focusedIndex.clamp(0, movies.length - 1),
                  onFocusChanged: (i) => setState(() => _focusedIndex = i),
                  onTap: (movie, heroTag) => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          MovieDetailsScreen(movie: movie, heroTag: heroTag),
                    ),
                  ),
                ),
                SizedBox(height: navBarClearance),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Full-bleed backdrop hero for the focused movie: top bar, title block,
/// info pills, genre line and a primary call-to-action, mirroring a cinema
/// app's "now showing" header.
class _HeroHeader extends ConsumerWidget {
  const _HeroHeader({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefer the portrait poster so the hero fills a tall, cinematic frame
    // with the subject, rather than stretching a wide backdrop into a box
    // that leaves large empty areas. Fall back to the backdrop when no
    // poster is available.
    final heroUrl =
        TmdbImages.poster(movie.posterPath) ??
        TmdbImages.backdrop(movie.backdropPath);
    final details = ref.watch(movieDetailsProvider(movie.id)).valueOrNull;
    final rating = movie.formattedRating;
    final year = movie.releaseYear;
    final genres = details?.genres.take(3).map((g) => g.name).join(', ');
    final topPadding = MediaQuery.paddingOf(context).top;

    // Let the hero own most of the viewport so the artwork dominates the
    // first screen, clamped so it stays cinematic on short and very tall
    // devices alike.
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.82).clamp(520.0, 760.0).toDouble();

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'home-hero-${movie.id}',
            child: PosterImage(
              url: heroUrl,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.35),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0, 0.32, 0.6, 1],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: topPadding + AppSpacing.sm,
            child: const _HomeTopBar(),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'NEW · MOVIE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFC94D),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  movie.title.toUpperCase(),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.02,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: _GlassBadge(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                'Populer with friends',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _GlassBadge(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Text(
                        '18+',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _GlassBadge(
                        color: const Color(0xFFFFC94D),
                        child: Text(
                          '$rating/10',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  [
                    if (year != null) year,
                    if (genres != null && genres.isNotEmpty) genres,
                  ].join('  •  '),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  height: 1,
                  width: 220,
                  color: const Color(0xFFE23744).withValues(alpha: 0.6),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MovieDetailsScreen(
                        movie: movie,
                        heroTag: 'home-hero-${movie.id}',
                      ),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE23744),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxl,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: const Text(
                    'VIEW DETAILS',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          tooltip: 'Menu',
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.lg * 2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search Movies...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  Icon(Icons.search_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A small liquid-glass pill used for badges over the hero art.
class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg * 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.lg * 2),
          ),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
  }
}

/// A horizontally scrolling strip of poster thumbnails beneath the hero;
/// tapping one updates the focused (hero) movie, mirroring how a "now
/// showing" carousel drives the header above it.
class _PosterStrip extends ConsumerWidget {
  const _PosterStrip({
    required this.movies,
    required this.focusedIndex,
    required this.onFocusChanged,
    required this.onTap,
  });

  final List<Movie> movies;
  final int focusedIndex;
  final ValueChanged<int> onFocusChanged;
  final void Function(Movie movie, Object heroTag) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 244,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          final focused = index == focusedIndex;
          final saved = ref.watch(isInWatchlistProvider(movie.id));
          final rating = movie.formattedRating;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onTap: () {
                if (focused) {
                  onTap(movie, 'home-hero-${movie.id}');
                } else {
                  onFocusChanged(index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: focused ? 152 : 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.lg * 1.25),
                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFE23744,
                                    ).withValues(alpha: 0.45),
                                    blurRadius: 28,
                                    spreadRadius: -6,
                                    offset: const Offset(0, 14),
                                  ),
                                ]
                              : const [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppRadius.lg * 1.25,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 260),
                                opacity: focused ? 1 : 0.6,
                                child: PosterImage(
                                  url: TmdbImages.poster(movie.posterPath),
                                ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.65),
                                    ],
                                    stops: const [0.55, 1],
                                  ),
                                ),
                              ),
                              if (focused)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE23744),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg * 1.25,
                                    ),
                                  ),
                                ),
                              Positioned(
                                right: AppSpacing.sm,
                                top: AppSpacing.sm,
                                child: _MiniGlassButton(
                                  icon: saved
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: saved
                                      ? Colors.redAccent
                                      : Colors.white,
                                  onTap: () => ref
                                      .read(watchlistProvider.notifier)
                                      .toggle(movie),
                                ),
                              ),
                              if (rating != null)
                                Positioned(
                                  left: AppSpacing.sm,
                                  bottom: AppSpacing.sm,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: Color(0xFFFFC94D),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        rating,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: focused ? Colors.white : Colors.white70,
                        fontWeight: focused ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A compact circular glass button (watchlist toggle) shown over poster art.
class _MiniGlassButton extends StatelessWidget {
  const _MiniGlassButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.black.withValues(alpha: 0.28),
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white24, width: 1),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: 16, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton placeholder mirroring the hero + strip layout.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.82)
        .clamp(520.0, 760.0)
        .toDouble();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        Container(height: heroHeight, color: base),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Container(width: 140, height: 20, color: base),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 244,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: 4,
            itemBuilder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg * 1.25),
                child: Container(width: 120, height: 210, color: base),
              ),
            ),
          ),
        ),
      ],
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
