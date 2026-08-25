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
