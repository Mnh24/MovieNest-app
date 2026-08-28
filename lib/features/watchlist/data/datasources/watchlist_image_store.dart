import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Stores watchlist poster images in a dedicated, long-lived on-device cache so
/// saved titles keep their artwork offline.
///
/// Ordinary posters are cached by `cached_network_image` in the default store,
/// which evicts freely as the user browses — so a saved poster could vanish by
/// the time the device is offline. Keeping watchlist posters in their own store
/// (long stale period, generous object count) means artwork the user explicitly
/// saved survives until the title is removed.
class WatchlistImageStore {
  const WatchlistImageStore();

  static final CacheManager _cache = CacheManager(
    Config(
      'watchlistPosterCache',
      stalePeriod: const Duration(days: 365),
      maxNrOfCacheObjects: 1000,
    ),
  );

  /// The cache manager the watchlist UI reads posters from, so it hits the same
  /// long-lived store this class writes to.
  CacheManager get cacheManager => _cache;

  /// Pre-downloads [url] into the watchlist store when a title is saved. Runs
  /// best-effort: a failure (e.g. saving while briefly offline) must never
  /// block adding the movie, so the poster simply isn't pre-cached.
  Future<void> save(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _cache.downloadFile(url);
    } catch (_) {
      // Best-effort: keep the watchlist write successful regardless.
    }
  }

  /// Drops a poster from the store when its title is removed, so unsaved
  /// artwork does not linger on disk.
  Future<void> remove(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      await _cache.removeFile(url);
    } catch (_) {
      // The file may already be gone; nothing to do.
    }
  }
}
