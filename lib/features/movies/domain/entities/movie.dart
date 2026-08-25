/// A lightweight movie used in trending, search and watchlist lists.
///
/// This entity intentionally stores only what a list/card needs to render,
/// which also keeps the persisted watchlist payload small and usable offline.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.voteAverage,
    this.overview,
  });

  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double? voteAverage;
  final String? overview;

  /// The four-digit release year, when a valid date is available.
  String? get releaseYear {
    final date = releaseDate;
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }

  /// Rating formatted to a single decimal, or null when unrated.
  String? get formattedRating {
    final rating = voteAverage;
    if (rating == null || rating <= 0) return null;
    return rating.toStringAsFixed(1);
  }

  @override
  bool operator ==(Object other) =>
      other is Movie && other.id == id && other.title == title;

  @override
  int get hashCode => Object.hash(id, title);
}
