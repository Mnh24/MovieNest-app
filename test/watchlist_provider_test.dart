import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_app/core/providers.dart';
import 'package:movie_app/features/movies/domain/entities/movie.dart';
import 'package:movie_app/features/watchlist/presentation/providers/watchlist_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movie _movie(int id, [String title = 'Movie']) => Movie(id: id, title: title);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
  });

  test('toggling adds then removes a movie', () async {
    final notifier = container.read(watchlistProvider.notifier);
    final movie = _movie(1);

    await notifier.toggle(movie);
    expect(container.read(watchlistProvider).length, 1);
    expect(container.read(isInWatchlistProvider(1)), isTrue);

    await notifier.toggle(movie);
    expect(container.read(watchlistProvider), isEmpty);
    expect(container.read(isInWatchlistProvider(1)), isFalse);
  });

  test('isInWatchlistProvider reflects current state', () async {
    expect(container.read(isInWatchlistProvider(5)), isFalse);

    await container.read(watchlistProvider.notifier).add(_movie(5));

    expect(container.read(isInWatchlistProvider(5)), isTrue);
  });
}
