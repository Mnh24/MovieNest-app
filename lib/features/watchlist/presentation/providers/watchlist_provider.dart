import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../../movies/domain/entities/movie.dart';

/// Holds the current watchlist in memory, backed by local persistence.
///
/// Reads are synchronous (the data is small and already on disk), so the UI can
/// render the watchlist instantly and entirely offline. Mutations write through
/// to storage and update state immediately for a responsive feel.
class WatchlistNotifier extends Notifier<List<Movie>> {
  @override
  List<Movie> build() {
    return ref.watch(watchlistRepositoryProvider).getAll();
  }

  bool contains(int id) => state.any((m) => m.id == id);

  Future<void> add(Movie movie) async {
    state = await ref.read(watchlistRepositoryProvider).add(movie);
  }

  Future<void> remove(int id) async {
    state = await ref.read(watchlistRepositoryProvider).remove(id);
  }

  Future<void> toggle(Movie movie) async {
    if (contains(movie.id)) {
      await remove(movie.id);
    } else {
      await add(movie);
    }
  }
}

final watchlistProvider = NotifierProvider<WatchlistNotifier, List<Movie>>(
  WatchlistNotifier.new,
);

/// Convenience provider to observe whether a specific movie is saved.
final isInWatchlistProvider = Provider.family<bool, int>((ref, id) {
  return ref.watch(watchlistProvider).any((m) => m.id == id);
});
