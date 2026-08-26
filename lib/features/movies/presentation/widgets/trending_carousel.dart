import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/tmdb_images.dart';
import '../../../../core/widgets/poster_image.dart';
import '../../../watchlist/presentation/providers/watchlist_provider.dart';
import '../../domain/entities/movie.dart';
import '../providers/dominant_color_provider.dart';

/// A horizontally paged, fanned stack of movie posters used to showcase the
/// week's trending titles. The centred page sits largest and flattest; the
/// neighbours shrink, fade and tilt away, animating continuously as the user
/// swipes.
///
/// Sizing is derived from the available width via [LayoutBuilder] rather than
/// fixed pixel values, so the fan scales sensibly from small phones up to
/// tablets.
class TrendingCarousel extends StatefulWidget {
  const TrendingCarousel({
    super.key,
    required this.movies,
    required this.onTap,
    this.onPageChanged,
  });

  final List<Movie> movies;

  /// Called with the tapped movie and the Hero tag its poster was rendered
  /// with, so the caller can pass the same tag to the details screen.
  final void Function(Movie movie, Object heroTag) onTap;
  final ValueChanged<int>? onPageChanged;

  @override
  State<TrendingCarousel> createState() => _TrendingCarouselState();
}

class _TrendingCarouselState extends State<TrendingCarousel> {
  late final PageController _pageController = PageController(
    viewportFraction: 0.72,
  );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = math.min(constraints.maxWidth * 1.15, 480.0);
        return SizedBox(
          height: height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.movies.length,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, index) {
              final movie = widget.movies[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  final page = _currentPage();
                  final delta = (page - index).clamp(-1.0, 1.0);
                  final scale = 1 - (delta.abs() * 0.18);
                  final angle = delta * -0.28;
                  final dy = delta.abs() * 24;

                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.rotate(
                      angle: angle,
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: _TrendingCard(
                    movie: movie,
                    rank: index + 1,
                    onTap: () => widget.onTap(movie, 'home-poster-${movie.id}'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  double _currentPage() {
    if (!_pageController.hasClients ||
        _pageController.position.viewportDimension == 0) {
      return _pageController.initialPage.toDouble();
    }
    return _pageController.page ?? _pageController.initialPage.toDouble();
  }
}

/// A trending poster card: full-bleed art, a "#N Trending" glass badge, a
/// glass watchlist toggle, and an info panel with the movie's title, rating
/// and year — all sourced from data the trending list already carries, so
/// nothing here is fabricated or requires extra network calls per card.
class _TrendingCard extends ConsumerWidget {
  const _TrendingCard({
    required this.movie,
    required this.rank,
    required this.onTap,
  });

  final Movie movie;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isInWatchlistProvider(movie.id));
    final rating = movie.formattedRating;
    final year = movie.releaseYear;
    final accentUrl = TmdbImages.poster(movie.posterPath);
    final accent = accentUrl == null
        ? null
        : ref.watch(dominantColorProvider(accentUrl)).valueOrNull;
    final glowColor = accent ?? Colors.black;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.4),
                  blurRadius: 32,
                  spreadRadius: -4,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'home-poster-${movie.id}',
                  child: PosterImage(url: TmdbImages.poster(movie.posterPath)),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0, 0.5, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: _GlassBadge(
                    child: Text(
                      '#$rank Trending',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  child: _GlassIconButton(
                    icon: saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    iconColor: saved ? const Color(0xFFB9A6FF) : Colors.white,
                    tooltip: saved
                        ? 'Remove from watchlist'
                        : 'Add to watchlist',
                    onTap: () =>
                        ref.read(watchlistProvider.notifier).toggle(movie),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          if (rating != null) ...[
                            _GlassBadge(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Color(0xFFFFC94D),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          if (year != null)
                            _GlassBadge(
                              child: Text(
                                year,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ],
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

/// A small liquid-glass pill: lightly blurred, nearly transparent, with a
/// bright rim highlight, used for badges over the card art.
class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A circular liquid-glass icon button, used for the watchlist toggle.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white24, width: 1),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
