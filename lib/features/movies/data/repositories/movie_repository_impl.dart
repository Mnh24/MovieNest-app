import '../../domain/entities/cast_member.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/movie_details.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/tmdb_remote_datasource.dart';

/// Default [MovieRepository] backed by the TMDB remote data source.
class MovieRepositoryImpl implements MovieRepository {
  const MovieRepositoryImpl(this._remote);

  final TmdbRemoteDataSource _remote;

  @override
  Future<List<Movie>> getTrending() => _remote.getTrending();

  @override
  Future<List<Movie>> getPopular() => _remote.getPopular();

  @override
  Future<List<Movie>> getTopRated() => _remote.getTopRated();

  @override
  Future<List<Movie>> getNowPlaying() => _remote.getNowPlaying();

  @override
  Future<List<Movie>> searchMovies(String query) => _remote.searchMovies(query);

  @override
  Future<MovieDetails> getMovieDetails(int id) => _remote.getMovieDetails(id);

  @override
  Future<List<CastMember>> getCredits(int id) => _remote.getCredits(id);
}
