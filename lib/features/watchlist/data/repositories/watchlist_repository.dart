import '../../../../core/utils/tmdb_images.dart';
import '../../../movies/domain/entities/movie.dart';
import '../datasources/watchlist_image_store.dart';
import '../datasources/watchlist_local_datasource.dart';

/// Manages the persistent watchlist, using the TMDB movie id as stable
/// identity and preventing duplicate entries.
class WatchlistRepository {
  const WatchlistRepository(this._local, this._images);

  final WatchlistLocalDataSource _local;
  final WatchlistImageStore _images;

  List<Movie> getAll() => _local.readAll();

  /// Adds [movie] to the front of the watchlist if not already present and
  /// returns the resulting list. Also pre-caches the poster so it stays
  /// available offline.
  Future<List<Movie>> add(Movie movie) async {
    final current = _local.readAll();
    if (current.any((m) => m.id == movie.id)) return current;
    final updated = [movie, ...current];
    await _local.writeAll(updated);
    await _images.save(TmdbImages.poster(movie.posterPath));
    return updated;
  }

  /// Removes the movie with [id] and returns the resulting list, dropping its
  /// cached poster too.
  Future<List<Movie>> remove(int id) async {
    final current = _local.readAll();
    Movie? removed;
    for (final m in current) {
      if (m.id == id) {
        removed = m;
        break;
      }
    }
    if (removed == null) return current;
    final updated = current.where((m) => m.id != id).toList();
    await _local.writeAll(updated);
    await _images.remove(TmdbImages.poster(removed.posterPath));
    return updated;
  }
}
