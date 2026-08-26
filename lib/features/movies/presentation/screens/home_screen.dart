import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/tmdb_images.dart';
import '../../../../core/widgets/poster_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../watchlist/presentation/providers/watchlist_provider.dart';
import '../../../watchlist/presentation/screens/watchlist_screen.dart';
import '../../domain/entities/movie.dart';
import '../providers/dominant_color_provider.dart';
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
  List<Movie>? _precachedFor;

  /// Warms the image cache for the trending posters at hero resolution once,
  /// so switching the focused movie (or the initial hero) appears instantly
  /// instead of flashing a placeholder while the large image downloads.
  void _precacheHeroArt(List<Movie> movies) {
    if (identical(_precachedFor, movies)) return;
    _precachedFor = movies;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final movie in movies.take(8)) {
        final url =
            TmdbImages.posterLarge(movie.posterPath) ??
            TmdbImages.backdropLarge(movie.backdropPath);
        if (url != null) {
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(popularProvider);
    ref.invalidate(topRatedProvider);
    ref.invalidate(nowPlayingProvider);
    await ref.read(trendingProvider.notifier).refresh();
  }

  void _openDetails(Movie movie, Object heroTag) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MovieDetailsScreen(movie: movie, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trending = ref.watch(trendingProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _refresh,
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

            _precacheHeroArt(movies);
            final focused = movies[_focusedIndex.clamp(0, movies.length - 1)];
            final bottomClearance =
                MediaQuery.paddingOf(context).bottom + AppSpacing.xl;

            // The focused movie's dominant colour drives an ambient tint
            // behind the content (white-based in light mode, dark in dark
            // mode), so the whole page subtly takes on the active poster.
            final focusedPoster = TmdbImages.posterSmall(focused.posterPath);
            final dominant = focusedPoster == null
                ? null
                : ref.watch(dominantColorProvider(focusedPoster)).valueOrNull;

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final base = isDark ? const Color(0xFF0D0A1C) : Colors.white;
            final tint =
                dominant ??
                (isDark ? const Color(0xFF241A44) : const Color(0xFFDCCCFA));
            // The colour the ambient background starts with at the top. The
            // hero fades its bottom edge into exactly this colour so there is
            // no visible seam between the hero and the section below it.
            final ambientTop = Color.alphaBlend(
              tint.withValues(alpha: isDark ? 0.55 : 0.5),
              base,
            );

            return Stack(
              children: [
                Positioned.fill(
                  child: _AmbientBackground(top: ambientTop, base: base),
                ),
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _HeroHeader(movie: focused, fadeColor: ambientTop),
                    const SizedBox(height: AppSpacing.lg),
                    // The featured poster strip sits directly beneath the hero
                    // (no section label), mirroring the reference's "now
                    // showing" carousel that drives the header above it.
                    _PosterStrip(
                      movies: movies,
                      focusedIndex: _focusedIndex.clamp(0, movies.length - 1),
                      onFocusChanged: (i) => setState(() => _focusedIndex = i),
                      onTap: _openDetails,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _MovieRail(
                      title: 'Popular',
                      provider: popularProvider,
                      onTap: _openDetails,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _MovieRail(
                      title: 'Top rated',
                      provider: topRatedProvider,
                      onTap: _openDetails,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _MovieRail(
                      title: 'New releases',
                      provider: nowPlayingProvider,
                      onTap: _openDetails,
                    ),
                    SizedBox(height: bottomClearance),
                  ],
                ),
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
  const _HeroHeader({required this.movie, required this.fadeColor});

  final Movie movie;

  /// The colour the hero's bottom edge fades into — the same colour the
  /// section below starts with — so there is no visible seam between them.
  final Color fadeColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefer the portrait poster so the hero fills a tall, cinematic frame
    // with the subject, rather than stretching a wide backdrop into a box
    // that leaves large empty areas. Fall back to the backdrop when no
    // poster is available.
    final heroUrl =
        TmdbImages.posterLarge(movie.posterPath) ??
        TmdbImages.backdropLarge(movie.backdropPath);
    final details = ref.watch(movieDetailsProvider(movie.id)).valueOrNull;
    final rating = movie.formattedRating;
    final year = movie.releaseYear;
    final genres = details?.genres.take(3).map((g) => g.name).join(', ');
    final topPadding = MediaQuery.paddingOf(context).top;

    // Let the hero own most of the viewport so the artwork dominates the
    // first screen, clamped so it stays cinematic on short and very tall
    // devices alike.
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = (screenHeight * 0.64).clamp(460.0, 620.0).toDouble();

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
              memCacheWidth: 780,
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
                  Colors.black.withValues(alpha: 0.35),
                  fadeColor.withValues(alpha: 0.85),
                  fadeColor,
                ],
                stops: const [0, 0.3, 0.62, 0.9, 1],
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
            left: 0,
            right: 0,
            bottom: AppSpacing.xl,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'NEW · MOVIE',
                        textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFF2C94C),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  movie.title.toUpperCase(),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: 1.5,
                    fontSize: 44,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Flexible(
                      child: _HeroPill(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: const Text(
                          'Populer with friends',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _HeroPill(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: const Text(
                        '18+',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (rating != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      _HeroPill(
                        color: const Color(0xFFF2C94C),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: rating,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const TextSpan(
                                text: '/10',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ],
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
                    'Datasat, Dolby Digital',
                  ].join('  •  '),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  height: 1,
                  width: 200,
                  color: const Color(0xFFF5261E).withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.xl),
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
                    backgroundColor: const Color(0xFFF5261E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 44,
                      vertical: 18,
                    ),
                  ),
                  child: const Text(
                    'BUY TICKET',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontSize: 15,
                    ),
                  ),
                ),
                    ],
                  ),
                ),
              ),
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
        // Dark/light theme toggle, in the same glass tile as the search field.
        const _ThemeToggleButton(),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Search Movies...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Saved-list (watchlist) shortcut, replacing the old bottom nav.
        _GlassIconTile(
          icon: Icons.bookmark_rounded,
          tooltip: 'Watchlist',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const WatchlistScreen()),
          ),
        ),
      ],
    );
  }
}

/// A rounded-square translucent glass tile holding a single icon button, used
/// for the top bar's menu and watchlist shortcuts.
class _GlassIconTile extends StatelessWidget {
  const _GlassIconTile({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            // A darker scrim (not translucent white) so the white icon stays
            // legible even over bright areas of the hero artwork.
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Tooltip(
                message: tooltip,
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                    shadows: const [
                      Shadow(blurRadius: 6, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Top-bar button that toggles between light and dark themes, showing the
/// icon of the mode it will switch to.
class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _GlassIconTile(
      icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
      tooltip: isDark ? 'Switch to light' : 'Switch to dark',
      onTap: () => ref
          .read(themeModeProvider.notifier)
          .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}

/// A full-width liquid-glass bar spanning the bottom of the active poster;
/// tapping it opens the movie's details. Only one is on screen at a time (the
/// focused card), so its real blur is inexpensive. Its bottom corners are
/// clipped to the card's rounded corners by the parent [ClipRRect].
class _GlassArrowBar extends StatelessWidget {
  const _GlassArrowBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'View details',
      // ClipRect confines the backdrop blur to the bar's own bounds — without
      // it, BackdropFilter blurs the whole card (its nearest ancestor clip).
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.white.withValues(alpha: 0.18),
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen ambient backdrop tinted by the active movie's dominant colour.
///
/// In light mode the base is white and the tint fades into it from the top;
/// in dark mode the base is near-black. The gradient animates whenever the
/// active movie (and therefore the colour) changes.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.top, required this.base});

  final Color top;
  final Color base;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Hold the tint through the hero/section seam (~0.66 of the
          // viewport, where the hero's faded bottom lands) so the two meet in
          // the same colour, then ease down to the base further below.
          colors: [top, top, base],
          stops: const [0, 0.66, 1],
        ),
      ),
    );
  }
}

/// A rounded-rectangle info pill used beneath the hero title (metadata and
/// rating), matching the reference's moderate corner radius rather than a
/// fully rounded stadium.
class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(widthFactor: 1, child: child),
    );
  }
}

/// A horizontally scrolling strip of poster thumbnails beneath the hero;
/// tapping one updates the focused (hero) movie, mirroring how a "now
/// showing" carousel drives the header above it.
class _PosterStrip extends ConsumerStatefulWidget {
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
  ConsumerState<_PosterStrip> createState() => _PosterStripState();
}

class _PosterStripState extends ConsumerState<_PosterStrip> {
  final ScrollController _controller = ScrollController();

  // All cards share one size — the active card is distinguished by brightness,
  // a dominant-colour glow and its arrow bar, not by a different size.
  static const double _cardWidth = 132;
  static const double _gap = AppSpacing.md;
  static const double _lead = AppSpacing.lg;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Horizontally scrolls the strip (never the page) so the item at [index]
  /// — which is becoming the focused, wider card — is centred in the viewport.
  void _centerOn(int index) {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final leftEdge = _lead + index * (_cardWidth + _gap);
    final itemCentre = leftEdge + _cardWidth / 2;
    final target = (itemCentre - position.viewportDimension / 2).clamp(
      0.0,
      position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final movies = widget.movies;
    final focusedIndex = widget.focusedIndex;

    return SizedBox(
      height: 244,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          final focused = index == focusedIndex;

          // The active card glows in its poster's dominant colour.
          Color? glow;
          if (focused) {
            final url = TmdbImages.posterSmall(movie.posterPath);
            if (url != null) {
              glow = ref.watch(dominantColorProvider(url)).valueOrNull;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onTap: () {
                if (focused) {
                  widget.onTap(movie, 'home-hero-${movie.id}');
                } else {
                  widget.onFocusChanged(index);
                  // Centre the tapped poster within the strip only — a
                  // horizontal scroll, so the whole page never moves.
                  _centerOn(index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                width: _cardWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: focused
                              ? Border.all(
                                  color: (glow ?? Colors.white).withValues(
                                    alpha: 0.9,
                                  ),
                                  width: 2,
                                )
                              : null,
                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                    color: (glow ?? Colors.black).withValues(
                                      alpha: glow != null ? 0.7 : 0.55,
                                    ),
                                    blurRadius: 34,
                                    spreadRadius: -2,
                                    offset: const Offset(0, 14),
                                  ),
                                ]
                              : const [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 260),
                                opacity: focused ? 1 : 0.42,
                                child: PosterImage(
                                  url: TmdbImages.posterSmall(movie.posterPath),
                                  memCacheWidth: 342,
                                ),
                              ),
                              // Darken inactive cards so the active one stands
                              // out clearly.
                              if (!focused)
                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0x40000000),
                                  ),
                                ),
                              // Active card: a full-width glass bar across the
                              // bottom whose arrow opens the movie's details.
                              if (focused)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: _GlassArrowBar(
                                    onTap: () => widget.onTap(
                                      movie,
                                      'home-hero-${movie.id}',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Builder(
                      builder: (context) {
                        final onSurface = Theme.of(
                          context,
                        ).colorScheme.onSurface;
                        return Text(
                          movie.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: focused
                                    ? onSurface
                                    : onSurface.withValues(alpha: 0.45),
                                fontWeight: focused
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                letterSpacing: focused ? 1.5 : 0.5,
                              ),
                        );
                      },
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

/// A compact circular translucent button (watchlist toggle) shown over poster
/// art. Deliberately avoids [BackdropFilter]: real blur per card multiplies
/// GPU cost across every rail and is a common cause of dropped/blank frames
/// while scrolling on web, so a solid translucent scrim is used instead.
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
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
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
    );
  }
}

/// A left-aligned section title used above each horizontal rail.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// A titled, horizontally scrolling rail of premium poster cards backed by an
/// async catalog provider (Popular / Top rated / New releases). While loading
/// it shows a skeleton; on error or an empty result the whole rail (title
/// included) collapses so the layout never shows an empty labelled band.
class _MovieRail extends ConsumerWidget {
  const _MovieRail({
    required this.title,
    required this.provider,
    required this.onTap,
  });

  final String title;
  final ProviderListenable<AsyncValue<List<Movie>>> provider;
  final void Function(Movie movie, Object heroTag) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(provider);

    return movies.when(
      loading: () => _scaffold(const _RailSkeleton()),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return _scaffold(
          ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final movie = list[index];
              final heroTag = '$title-${movie.id}';
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: _RailCard(
                  movie: movie,
                  heroTag: heroTag,
                  onTap: () => onTap(movie, heroTag),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _scaffold(Widget rail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: AppSpacing.md),
        SizedBox(height: 232, child: rail),
      ],
    );
  }
}

/// A single premium poster card used in the catalog rails: portrait art with a
/// bottom gradient, an inline rating, a watchlist toggle, a title beneath, and
/// a subtle press-scale for tactile feedback.
class _RailCard extends ConsumerWidget {
  const _RailCard({
    required this.movie,
    required this.heroTag,
    required this.onTap,
  });

  final Movie movie;
  final Object heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isInWatchlistProvider(movie.id));
    final rating = movie.formattedRating;

    return SizedBox(
      width: 132,
      child: _PressableScale(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg * 1.125),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: heroTag,
                      child: PosterImage(
                        url: TmdbImages.posterSmall(movie.posterPath),
                        memCacheWidth: 342,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                          stops: const [0.55, 1],
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
                        color: saved ? Colors.redAccent : Colors.white,
                        onTap: () =>
                            ref.read(watchlistProvider.notifier).toggle(movie),
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
                                  Shadow(blurRadius: 4, color: Colors.black54),
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps a tappable card with a subtle scale-down while pressed.
class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1;

  void _set(double value) {
    if (mounted) setState(() => _scale = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(0.96),
      onTapUp: (_) => _set(1),
      onTapCancel: () => _set(1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Placeholder poster boxes shown while a rail's catalog is loading.
class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: 4,
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg * 1.125),
          child: Container(width: 132, height: 204, color: base),
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
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.64)
        .clamp(460.0, 620.0)
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
