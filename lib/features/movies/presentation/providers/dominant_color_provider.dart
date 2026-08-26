import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/dominant_color_extractor.dart';

/// Extracts and caches a poster's dominant colour, keyed by its image URL.
///
/// Kept alive (no `.autoDispose`) so re-focusing an already-seen carousel
/// card doesn't re-run the extraction — the result set is small (one entry
/// per trending movie shown this session) and cheap to retain.
final dominantColorProvider = FutureProvider.family<Color?, String>((
  ref,
  imageUrl,
) {
  return DominantColorExtractor.extract(imageUrl);
});
