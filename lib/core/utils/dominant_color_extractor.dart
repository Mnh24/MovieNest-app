import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

/// Estimates a poster's dominant colour by downsampling it and averaging
/// pixels, skipping near-black, near-white and low-saturation ones so the
/// result reads as a real accent colour rather than a washed-out grey.
///
/// This intentionally avoids a third-party palette package: the sampling
/// need only be good enough for an ambient background tint, not pixel-exact
/// palette extraction, so a small hand-rolled pass keeps the dependency
/// surface minimal.
class DominantColorExtractor {
  const DominantColorExtractor._();

  /// Side length of the downsampled grid used for averaging. Small enough to
  /// be cheap, large enough to avoid a single stray pixel dominating.
  static const int _sampleSize = 16;

  static Future<Color?> extract(String imageUrl) async {
    try {
      final provider = CachedNetworkImageProvider(imageUrl);
      final descriptor = await ui.ImageDescriptor.encoded(
        await ui.ImmutableBuffer.fromUint8List(await _loadBytes(provider)),
      );
      final codec = await descriptor.instantiateCodec(
        targetWidth: _sampleSize,
        targetHeight: _sampleSize,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      image.dispose();
      codec.dispose();
      if (byteData == null) return null;
      return _averageVibrantColor(byteData);
    } catch (_) {
      // Extraction is a purely cosmetic enhancement; any failure (network,
      // decode, unsupported format) just means no dynamic tint is shown.
      return null;
    }
  }

  static Future<Uint8List> _loadBytes(ImageProvider provider) {
    final completer = Completer<Uint8List>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) async {
        final byteData = await info.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        stream.removeListener(listener);
        if (byteData == null) {
          completer.completeError(StateError('Failed to encode image'));
        } else {
          completer.complete(byteData.buffer.asUint8List());
        }
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        completer.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  static Color? _averageVibrantColor(ByteData rgba) {
    var rSum = 0.0, gSum = 0.0, bSum = 0.0, weightSum = 0.0;
    final pixelCount = rgba.lengthInBytes ~/ 4;

    for (var i = 0; i < pixelCount; i++) {
      final offset = i * 4;
      final r = rgba.getUint8(offset);
      final g = rgba.getUint8(offset + 1);
      final b = rgba.getUint8(offset + 2);
      final a = rgba.getUint8(offset + 3);
      if (a < 200) continue;

      final maxC = [r, g, b].reduce((x, y) => x > y ? x : y);
      final minC = [r, g, b].reduce((x, y) => x < y ? x : y);
      final lightness = (maxC + minC) / 2 / 255;
      final saturation = maxC == minC
          ? 0.0
          : (maxC - minC) / (255 - (2 * lightness * 255 - 255).abs());

      // Skip near-black/near-white/greyscale pixels — they wash the average
      // toward grey instead of the poster's actual accent colour.
      if (lightness < 0.08 || lightness > 0.92 || saturation < 0.15) continue;

      final weight = saturation;
      rSum += r * weight;
      gSum += g * weight;
      bSum += b * weight;
      weightSum += weight;
    }

    if (weightSum == 0) return null;
    return Color.fromARGB(
      255,
      (rSum / weightSum).round().clamp(0, 255),
      (gSum / weightSum).round().clamp(0, 255),
      (bSum / weightSum).round().clamp(0, 255),
    );
  }
}
