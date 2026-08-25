import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/movies/data/datasources/tmdb_remote_datasource.dart';
import '../features/movies/data/repositories/movie_repository_impl.dart';
import '../features/movies/domain/repositories/movie_repository.dart';
import '../features/watchlist/data/datasources/watchlist_local_datasource.dart';
import '../features/watchlist/data/repositories/watchlist_repository.dart';
import 'network/dio_client.dart';

/// Provides the [SharedPreferences] instance. Overridden in `main` once the
/// async instance has been created so the rest of the app can read it
/// synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final dioProvider = Provider<Dio>((ref) {
  final dio = DioClient.create();
  ref.onDispose(dio.close);
  return dio;
});

final tmdbRemoteDataSourceProvider = Provider<TmdbRemoteDataSource>((ref) {
  return TmdbRemoteDataSource(ref.watch(dioProvider));
});

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepositoryImpl(ref.watch(tmdbRemoteDataSourceProvider));
});

final watchlistLocalDataSourceProvider = Provider<WatchlistLocalDataSource>((
  ref,
) {
  return WatchlistLocalDataSource(ref.watch(sharedPreferencesProvider));
});

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository(ref.watch(watchlistLocalDataSourceProvider));
});
