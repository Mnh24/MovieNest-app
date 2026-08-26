import '../entities/cast_member.dart';
import '../entities/movie.dart';
import '../entities/movie_details.dart';

/// Contract for fetching movie data, decoupling presentation from the concrete
/// TMDB implementation and easing testing.
abstract interface class MovieRepository {
  Future<List<Movie>> getTrending();
  Future<List<Movie>> getPopular();
  Future<List<Movie>> getTopRated();
  Future<List<Movie>> getNowPlaying();
  Future<List<Movie>> searchMovies(String query);
  Future<MovieDetails> getMovieDetails(int id);
  Future<List<CastMember>> getCredits(int id);
}
