import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Displays a movie poster/backdrop with graceful loading, error and missing
/// image handling so the UI never shows a broken-image glyph or distorts art.
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.iconSize = 32,
    this.memCacheWidth,
  });

  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final double iconSize;

  /// Target decode width in pixels. Decoding the bitmap at the size it will
  /// actually be drawn (rather than full resolution) makes images appear
  /// faster and dramatically cuts memory, which keeps scrolling smooth.
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null) return _placeholder(context);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (context, _) => _loading(context),
      errorWidget: (context, _, _) => _placeholder(context),
    );
  }

  Widget _loading(BuildContext context) {
    // A soft vertical gradient reads as a calm "surface" while the artwork
    // decodes, instead of a flat dark block flashing in during scroll.
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surfaceContainerHighest,
            Color.alphaBlend(
              Colors.black.withValues(alpha: 0.18),
              scheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: iconSize,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
