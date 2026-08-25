import '../../../../core/utils/json_parsing.dart';
import '../../domain/entities/genre.dart';
import '../../domain/entities/movie_details.dart';
import 'movie_model.dart';

/// Maps the TMDB movie detail payload to the [MovieDetails] entity.
class MovieDetailsModel {
  const MovieDetailsModel._();

  static MovieDetails fromJson(Map<String, dynamic> json) {
    final genres = (json['genres'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(
          (g) => Genre(
            id: asIntOrNull(g['id']) ?? 0,
            name: asStringOrNull(g['name']) ?? '',
          ),
        )
        .where((g) => g.name.isNotEmpty)
        .toList();

    return MovieDetails(
      movie: MovieModel.fromJson(json),
      runtime: asIntOrNull(json['runtime']),
      tagline: asStringOrNull(json['tagline']),
      status: asStringOrNull(json['status']),
      genres: genres,
    );
  }
}
