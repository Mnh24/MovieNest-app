import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/tmdb_images.dart';
import '../../../../core/widgets/poster_image.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../watchlist/presentation/providers/watchlist_provider.dart';
import '../../domain/entities/cast_member.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_details.dart';
import '../providers/movie_credits_provider.dart';
import '../providers/movie_details_provider.dart';
import 'cast_list_screen.dart';

/// Full movie detail screen.
///
/// Matches the home screen's hero-card vibe: a full-bleed image up top with
/// floating circular back/watchlist buttons, and a rounded card overlapping
/// its bottom edge that carries the title, rating, description and genre
/// info — capped by a fixed bottom action bar.
class MovieDetailsScreen extends ConsumerWidget {
  const MovieDetailsScreen({super.key, required this.movie, this.heroTag});

  final Movie movie;

  /// Must match the `heroTag` passed to the [Hero]-wrapped poster this
  /// screen was opened from, so the artwork morphs into the backdrop
  /// instead of cutting straight to it. Null when opened from a source that
  /// isn't Hero-wrapped (e.g. it appears on more than one simultaneously
  /// mounted screen and a stable unique tag isn't available).
  final Object? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(movieDetailsProvider(movie.id));
    final credits = ref.watch(movieCreditsProvider(movie.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                _HeroImage(movie: movie, heroTag: heroTag),
                Expanded(
                  child: _DetailsCard(
                    movie: movie,
                    details: details,
                    credits: credits,
                  ),
                ),
              ],
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              child: _TopBar(movie: movie),
            ),
          ],
        ),
      ),
    );
  }
}

/// The top ~44% of the screen: full-bleed backdrop art.
///
/// When [heroTag] is provided, the artwork morphs in from the poster it was
/// opened from rather than cutting straight to the full backdrop.
class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.movie, this.heroTag});

  final Movie movie;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final art = PosterImage(
      url:
          TmdbImages.backdrop(movie.backdropPath) ??
          TmdbImages.poster(movie.posterPath),
      fit: BoxFit.cover,
      iconSize: 48,
    );

    return SizedBox(
      height: 420,
      width: double.infinity,
      child: heroTag == null
          ? art
          : Hero(
              tag: heroTag!,
              flightShuttleBuilder: (_, animation, _, _, _) => FadeTransition(
                opacity: animation.drive(CurveTween(curve: Curves.easeIn)),
                child: art,
              ),
              child: art,
            ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isInWatchlistProvider(movie.id));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _FloatingIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Back',
          onTap: () => Navigator.of(context).maybePop(),
        ),
        _FloatingIconButton(
          icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: saved ? Colors.redAccent : Colors.white,
          tooltip: saved ? 'Remove from watchlist' : 'Add to watchlist',
          onTap: () => ref.read(watchlistProvider.notifier).toggle(movie),
        ),
      ],
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.black.withValues(alpha: 0.35),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single place the "trailers aren't available" message is shown, so every
/// trailer affordance on this screen stays consistent if the copy changes.
void showTrailerUnavailable(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Trailers are not available yet.')),
    );
}

/// The rounded card overlapping the hero image's bottom edge: eyebrow badge,
/// title, rating, overview, genre chips, an info row and (via its scrollable
/// body) the cast section — capped by the fixed bottom action bar.
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({
    required this.movie,
    required this.details,
    required this.credits,
  });

  final Movie movie;
  final AsyncValue<MovieDetails> details;
  final AsyncValue<List<CastMember>> credits;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Transform.translate(
      offset: const Offset(0, -28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg * 1.5),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                children: [
                  _EyebrowBadge(details: details),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    movie.title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RatingRow(movie: movie),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    (movie.overview == null || movie.overview!.isEmpty)
                        ? 'No overview is available for this movie.'
                        : movie.overview!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  details.when(
                    loading: () => const _CustomizeSectionSkeleton(),
                    error: (error, _) => _DetailsUnavailable(
                      message: messageForError(error),
                    ),
                    data: (data) => _CustomizeSection(details: data),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _CastSection(movie: movie, credits: credits),
                ],
              ),
            ),
            _BottomBar(movie: movie),
          ],
        ),
      ),
    );
  }
}

/// Small colour-accented pill above the title, echoing the reference's
/// "Spicy" badge — shows the movie's primary genre once loaded.
class _EyebrowBadge extends StatelessWidget {
  const _EyebrowBadge({required this.details});

  final AsyncValue<MovieDetails> details;

  @override
  Widget build(BuildContext context) {
    final label = details.valueOrNull?.genres.firstOrNull?.name ?? 'Movie';
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Star rating plus vote-style count, matching the reference's
/// "★ 4.8 (120)" line — TMDB doesn't expose a vote count on this lightweight
/// [Movie], so the release year fills that slot instead.
class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final rating = movie.formattedRating;
    final year = movie.releaseYear;
    final scheme = Theme.of(context).colorScheme;

    if (rating == null && year == null) return const SizedBox.shrink();

    return Row(
      children: [
        if (rating != null) ...[
          const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFC94D)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            rating,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (year != null)
          Text(
            '($year)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Replaces the reference's "Customize" block (size buttons + toggles) with
/// genre chips and a label/value info row, the closest real equivalents this
/// app's movie data offers.
class _CustomizeSection extends StatelessWidget {
  const _CustomizeSection({required this.details});

  final MovieDetails details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.genres.isNotEmpty) ...[
          Text(
            'Genres',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final genre in details.genres)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.lg * 2),
                  ),
                  child: Text(
                    genre.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _InfoRow(
          label: 'Release Date',
          value: movieReleaseDateLabel(details.movie.releaseDate),
        ),
        _InfoRow(label: 'Runtime', value: details.formattedRuntime ?? '—'),
        _InfoRow(label: 'Status', value: details.status ?? '—'),
      ],
    );
  }
}

/// Formats a raw `yyyy-MM-dd` release date as e.g. "Oct 4, 2019", or "—" when
/// unavailable — a small pure helper kept top-level so it's easy to test.
String movieReleaseDateLabel(String? releaseDate) {
  if (releaseDate == null || releaseDate.length < 10) return '—';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ]; // ignore: prefer_const_declarations
  final year = releaseDate.substring(0, 4);
  final month = int.tryParse(releaseDate.substring(5, 7));
  final day = int.tryParse(releaseDate.substring(8, 10));
  if (month == null || month < 1 || month > 12 || day == null) return '—';
  return '${months[month - 1]} $day, $year';
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomizeSectionSkeleton extends StatelessWidget {
  const _CustomizeSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 60, height: 16),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            SkeletonBox(width: 70, height: 32, radius: AppRadius.lg * 2),
            SizedBox(width: AppSpacing.sm),
            SkeletonBox(width: 70, height: 32, radius: AppRadius.lg * 2),
            SizedBox(width: AppSpacing.sm),
            SkeletonBox(width: 70, height: 32, radius: AppRadius.lg * 2),
          ],
        ),
      ],
    );
  }
}

class _DetailsUnavailable extends StatelessWidget {
  const _DetailsUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'Additional details unavailable. $message',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fixed bottom bar mirroring the reference's stepper + "Add to Cart" row:
/// a rounded watchlist toggle on the left, a wide "Watch Trailer" pill on
/// the right.
class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final saved = ref.watch(isInWatchlistProvider(movie.id));
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        bottomInset + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          _WatchlistToggle(movie: movie, saved: saved),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => showTrailerUnavailable(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text(
                'Watch Trailer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistToggle extends ConsumerWidget {
  const _WatchlistToggle({required this.movie, required this.saved});

  final Movie movie;
  final bool saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: saved ? 'Remove from watchlist' : 'Add to watchlist',
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => ref.read(watchlistProvider.notifier).toggle(movie),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Icon(
              saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: saved ? Colors.redAccent : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// The cast row: horizontally scrolling avatars with name and character,
/// built via [ListView.builder] since the list length is data-driven. A
/// "See all" link opens the full cast list when there's more to show.
class _CastSection extends StatelessWidget {
  const _CastSection({required this.movie, required this.credits});

  final Movie movie;
  final AsyncValue<List<CastMember>> credits;

  @override
  Widget build(BuildContext context) {
    return credits.when(
      loading: () => const _CastSectionSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (cast) {
        if (cast.isEmpty) return const SizedBox.shrink();
        final preview = cast.take(10).toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cast',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (cast.length > preview.length)
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            CastListScreen(movieTitle: movie.title, cast: cast),
                      ),
                    ),
                    child: const Text('See all'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 116,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: preview.length,
                itemBuilder: (context, index) {
                  final member = preview[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: _CastAvatar(member: member),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CastAvatar extends StatelessWidget {
  const _CastAvatar({required this.member});

  final CastMember member;

  @override
  Widget build(BuildContext context) {
    final profileUrl = TmdbImages.profile(member.profilePath);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 76,
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: 64,
              height: 64,
              child: profileUrl == null
                  ? ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.person_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : PosterImage(url: profileUrl),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            member.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (member.character != null)
            Text(
              member.character!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _CastSectionSkeleton extends StatelessWidget {
  const _CastSectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 60, height: 18),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
            itemBuilder: (_, _) => const Column(
              children: [
                SkeletonBox(width: 64, height: 64, radius: 32),
                SizedBox(height: AppSpacing.xs),
                SkeletonBox(width: 56, height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
