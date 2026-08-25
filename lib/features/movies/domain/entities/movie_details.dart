import 'genre.dart';
import 'movie.dart';

/// The full detail view of a movie, extending the base [Movie] with the extra
/// fields shown on the details screen.
class MovieDetails {
  const MovieDetails({
    required this.movie,
    this.runtime,
    this.tagline,
    this.genres = const [],
    this.status,
  });

  final Movie movie;
  final int? runtime;
  final String? tagline;
  final List<Genre> genres;
  final String? status;

  int get id => movie.id;
  String get title => movie.title;

  /// Runtime formatted as e.g. "2h 14m", or null when unavailable.
  String? get formattedRuntime {
    final minutes = runtime;
    if (minutes == null || minutes <= 0) return null;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }
}
