import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movienest/features/movies/domain/entities/movie.dart';
import 'package:movienest/features/watchlist/data/datasources/watchlist_image_store.dart';
import 'package:movienest/features/watchlist/data/datasources/watchlist_local_datasource.dart';
import 'package:movienest/features/watchlist/data/repositories/watchlist_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Movie _movie(int id, [String title = 'Movie']) =>
    Movie(id: id, title: title, posterPath: '/p$id.jpg');

class FakeWatchlistImageStore implements WatchlistImageStore {
  @override
  CacheManager get cacheManager => throw UnimplementedError();

  @override
  Future<void> save(String? url) async {}

  @override
  Future<void> remove(String? url) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WatchlistRepository repository;

  Future<WatchlistRepository> buildRepository() async {
    final prefs = await SharedPreferences.getInstance();
    return WatchlistRepository(
      WatchlistLocalDataSource(prefs),
      FakeWatchlistImageStore(),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = await buildRepository();
  });

  test('starts empty', () {
    expect(repository.getAll(), isEmpty);
  });

  test('adds a movie', () async {
    final result = await repository.add(_movie(1, 'Dune'));

    expect(result.length, 1);
    expect(result.single.title, 'Dune');
    expect(repository.getAll().single.id, 1);
  });

  test('prevents duplicate entries by id', () async {
    await repository.add(_movie(1));
    final result = await repository.add(_movie(1, 'Different title'));

    expect(result.length, 1);
    expect(result.single.title, 'Movie');
  });

  test('removes a movie', () async {
    await repository.add(_movie(1));
    await repository.add(_movie(2));

    final result = await repository.remove(1);

    expect(result.length, 1);
    expect(result.single.id, 2);
  });

  test('removing an unknown id is a no-op', () async {
    await repository.add(_movie(1));
    final result = await repository.remove(999);

    expect(result.length, 1);
  });

  test('persists across repository instances', () async {
    await repository.add(_movie(1, 'Persisted'));

    final reopened = await buildRepository();

    expect(reopened.getAll().single.title, 'Persisted');
  });

  test('newly added movies appear first', () async {
    await repository.add(_movie(1, 'First'));
    final result = await repository.add(_movie(2, 'Second'));

    expect(result.first.title, 'Second');
  });
}
