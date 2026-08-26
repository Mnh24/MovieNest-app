import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../domain/entities/movie.dart';

/// Loads trending movies for the week.
///
/// [AsyncValue] naturally models the loading / success / error states, while an
/// empty success list represents the empty state. [refresh] re-runs the fetch
/// for pull-to-refresh and retry.
class TrendingNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() {
    return ref.watch(movieRepositoryProvider).getTrending();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(movieRepositoryProvider).getTrending(),
    );
  }
}

final trendingProvider = AsyncNotifierProvider<TrendingNotifier, List<Movie>>(
  TrendingNotifier.new,
);

/// Catalog rows shown beneath the hero on the home screen. Each is a simple
/// one-shot fetch; Riverpod caches the result so switching tabs doesn't refetch,
/// and [ref.invalidate] (wired to pull-to-refresh) re-runs them on demand.
final popularProvider = FutureProvider<List<Movie>>((ref) {
  return ref.watch(movieRepositoryProvider).getPopular();
});

final topRatedProvider = FutureProvider<List<Movie>>((ref) {
  return ref.watch(movieRepositoryProvider).getTopRated();
});

final nowPlayingProvider = FutureProvider<List<Movie>>((ref) {
  return ref.watch(movieRepositoryProvider).getNowPlaying();
});
