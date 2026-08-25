import '../../../movies/domain/entities/movie.dart';
import '../datasources/watchlist_local_datasource.dart';

/// Manages the persistent watchlist, using the TMDB movie id as stable
/// identity and preventing duplicate entries.
class WatchlistRepository {
  const WatchlistRepository(this._local);

  final WatchlistLocalDataSource _local;

  List<Movie> getAll() => _local.readAll();

  /// Adds [movie] to the front of the watchlist if not already present and
  /// returns the resulting list.
  Future<List<Movie>> add(Movie movie) async {
    final current = _local.readAll();
    if (current.any((m) => m.id == movie.id)) return current;
    final updated = [movie, ...current];
    await _local.writeAll(updated);
    return updated;
  }

  /// Removes the movie with [id] and returns the resulting list.
  Future<List<Movie>> remove(int id) async {
    final current = _local.readAll();
    final updated = current.where((m) => m.id != id).toList();
    if (updated.length == current.length) return current;
    await _local.writeAll(updated);
    return updated;
  }
}
