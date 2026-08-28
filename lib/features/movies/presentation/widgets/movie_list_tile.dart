import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/tmdb_images.dart';
import '../../../../core/widgets/poster_image.dart';
import '../../domain/entities/movie.dart';

/// A horizontal movie card showing poster, title, release year and rating.
/// Used by the trending, search and watchlist lists for a consistent look —
/// a liquid-glass panel over the poster's own colours, matching the trending
/// carousel's treatment rather than a flat Material card.
class MovieListTile extends StatelessWidget {
  const MovieListTile({
    super.key,
    required this.movie,
    required this.onTap,
    this.trailing,
    this.heroTag,
    this.cacheManager,
  });

  final Movie movie;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Optional dedicated cache for the poster. The watchlist passes its
  /// long-lived store so saved artwork renders offline.
  final BaseCacheManager? cacheManager;

  /// When set, wraps the poster in a [Hero] so tapping into the details
  /// screen morphs the artwork instead of cutting to it. Pass a value unique
  /// to this movie's occurrence on screen (e.g. `'poster-${movie.id}'`).
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final year = movie.releaseYear;
    final rating = movie.formattedRating;

    final poster = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 72,
        height: 104,
        child: PosterImage(
          url: TmdbImages.poster(movie.posterPath),
          cacheManager: cacheManager,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.32 : 0.55,
          ),
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  heroTag == null ? poster : Hero(tag: heroTag!, child: poster),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          movie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            if (rating != null) ...[
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: theme.colorScheme.tertiary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                rating,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (year != null)
                                const SizedBox(width: AppSpacing.md),
                            ],
                            if (year != null)
                              Text(
                                year,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
