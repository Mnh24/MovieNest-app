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

            // Build a rich, dark "stage" colour from the focused movie's
            // dominant colour. The hero fades its bottom into this colour and
            // the poster strip sits on it, so the movie's own colour frames the
            // featured section stylishly (never washing the artwork out to the
            // page background) before easing into the page below.
            final focusedPoster = TmdbImages.posterSmall(focused.posterPath);
            final dominant = focusedPoster == null
                ? null
                : ref.watch(dominantColorProvider(focusedPoster)).valueOrNull;

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final base = isDark
                ? const Color(0xFF0C0C10)
                : const Color(0xFFE7E8EE);
            // The hero fades its bottom into the tinted base so it melts into
            // the full-screen liquid-glass wash of the active movie's colour.
            final fadeColor = dominant == null
                ? base
                : Color.alphaBlend(
                    dominant.withValues(alpha: isDark ? 0.35 : 0.68),
                    base,
                  );

            return Stack(
              children: [
                // The active movie's colour washes across the whole screen as
                // soft, liquid-glass orbs (iOS-style), over the neutral studio
                // backdrop painted by AppBackground.
                Positioned.fill(
                  child: _DominantGlass(color: dominant, isDark: isDark),
                ),
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _HeroHeader(movie: focused, fadeColor: fadeColor),
                    const SizedBox(height: AppSpacing.lg),
                    _PosterStrip(
                      movies: movies,
                      focusedIndex: _focusedIndex.clamp(0, movies.length - 1),
                      onFocusChanged: (i) =>
                          setState(() => _focusedIndex = i),
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
                  Colors.black.withValues(alpha: 0.22),
                  fadeColor.withValues(alpha: 0.7),
                  fadeColor,
                ],
                // Keep the artwork vivid: the fade into the page colour is
                // compressed into the bottom ~15% so only a thin strip washes
                // out rather than a heavy gradient over the lower third.
                stops: const [0, 0.35, 0.85, 0.96, 1],
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

/// A "stage" behind the featured poster strip: filled with the active movie's
/// dark stage colour at the top (meeting the hero's faded bottom seamlessly)
/// and fading to transparent at the bottom so it melts into the page below.
/// Because it lives in the scroll content, the stage travels with the strip,
/// and its colour cross-fades whenever the active movie changes.
/// A full-screen wash of the active movie's colour rendered as soft, liquid
/// "glass" orbs bleeding in from three points, so the whole screen takes on the
/// featured movie's hue over the neutral studio backdrop. The base is left
/// transparent so [AppBackground]'s canvas shows through, and the colour
/// cross-fades whenever the active movie changes.
class _DominantGlass extends StatelessWidget {
  const _DominantGlass({required this.color, required this.isDark});

  final Color? color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final dominant = color;
    if (dominant == null) return const SizedBox.shrink();
    // Light mode needs a stronger wash than dark to read as coloured glass
    // against the pale backdrop.
    final strong = dominant.withValues(alpha: isDark ? 0.34 : 0.62);
    final soft = dominant.withValues(alpha: isDark ? 0.24 : 0.46);

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -150,
                right: -120,
                child: _GlassOrb(color: strong, size: 540),
              ),
              Positioned(
                top: h * 0.32,
                left: -160,
                child: _GlassOrb(color: soft, size: 460),
              ),
              Positioned(
                bottom: -180,
                right: -110,
                child: _GlassOrb(color: strong, size: 520),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A soft radial glow disc: fades from [color] at its centre to transparent.
/// Its colour animates so a change of active movie flows rather than jumps.
class _GlassOrb extends StatelessWidget {
  const _GlassOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0), Colors.transparent],
          stops: const [0, 0.72, 1],
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

  // True while a tap-driven centring animation runs, so the scroll listener
  // doesn't flicker the active card through every poster it passes.
  bool _programmatic = false;

  @override
  void initState() {
    super.initState();
    // Manual horizontal scrolling makes whichever card is under the strip's
    // centre the active one.
    _controller.addListener(_syncActiveToCentre);
  }

  @override
  void dispose() {
    _controller.removeListener(_syncActiveToCentre);
    _controller.dispose();
    super.dispose();
  }

  /// Horizontally scrolls the strip (never the page) so the item at [index]
  /// is centred in the viewport.
  void _centerOn(int index) {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final target = (_centreOffsetFor(index) - position.viewportDimension / 2)
        .clamp(0.0, position.maxScrollExtent);
    _programmatic = true;
    _controller
        .animateTo(
          target,
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() => _programmatic = false);
  }

  double _centreOffsetFor(int index) =>
      _lead + index * (_cardWidth + _gap) + _cardWidth / 2;

  /// Picks the card nearest the strip's horizontal centre and makes it active.
  void _syncActiveToCentre() {
    if (_programmatic || !_controller.hasClients || widget.movies.isEmpty) {
      return;
    }
    final centreX = _controller.offset + _controller.position.viewportDimension / 2;
    final index = (((centreX - _lead - _cardWidth / 2) / (_cardWidth + _gap))
            .round())
        .clamp(0, widget.movies.length - 1);
    if (index != widget.focusedIndex) {
      widget.onFocusChanged(index);
    }
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
                                    : onSurface.withValues(alpha: 0.5),
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
        SizedBox(height: 250, child: rail),
      ],
    );
  }
}

/// A clean catalog-rail poster card matching the featured strip's style:
/// rounded artwork lifted by a soft shadow, with the title and a small rating
/// · year line beneath — no overlays on the poster itself.
class _RailCard extends StatelessWidget {
  const _RailCard({
    required this.movie,
    required this.heroTag,
    required this.onTap,
  });

  final Movie movie;
  final Object heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rating = movie.formattedRating;
    final year = movie.releaseYear;
    final metaStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    return SizedBox(
      width: 132,
      child: _PressableScale(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 18,
                      spreadRadius: -6,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Hero(
                    tag: heroTag,
                    child: PosterImage(
                      url: TmdbImages.posterSmall(movie.posterPath),
                      memCacheWidth: 342,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (rating != null) ...[
                  const Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: Color(0xFFFFC94D),
                  ),
                  const SizedBox(width: 3),
                  Text(rating, style: metaStyle),
                ],
                if (rating != null && year != null)
                  Text('  ·  ', style: metaStyle),
                if (year != null) Text(year, style: metaStyle),
              ],
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
