import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/movie.dart';

/// Maps the TMDB movie summary payload to the [Movie] entity and back.
///
/// The `toJson` form is intentionally compact — only the fields required to
/// render a saved movie offline are persisted for the watchlist.
class MovieModel {
  const MovieModel._();

  static Movie fromJson(Map<String, dynamic> json) {
    return Movie(
      id: asIntOrNull(json['id']) ?? 0,
      title:
          asStringOrNull(json['title']) ??
          asStringOrNull(json['name']) ??
          'Untitled',
      posterPath: asStringOrNull(json['poster_path']),
      backdropPath: asStringOrNull(json['backdrop_path']),
      releaseDate: asStringOrNull(json['release_date']),
      voteAverage: asDoubleOrNull(json['vote_average']),
      overview: asStringOrNull(json['overview']),
    );
  }

  static Map<String, dynamic> toJson(Movie movie) {
    return {
      'id': movie.id,
      'title': movie.title,
      'poster_path': movie.posterPath,
      'backdrop_path': movie.backdropPath,
      'release_date': movie.releaseDate,
      'vote_average': movie.voteAverage,
      'overview': movie.overview,
    };
  }
}
