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
  });

  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;
    if (imageUrl == null) return _placeholder(context);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (context, _) => _loading(context),
      errorWidget: (context, _, _) => _placeholder(context),
    );
  }

  Widget _loading(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
