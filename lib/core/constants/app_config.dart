/// Application-wide configuration values.
///
/// The TMDB API key is provided at build/run time via a compile-time
/// environment define so that no secret is ever committed to source control:
///
/// ```
/// flutter run --dart-define=TMDB_API_KEY=your_key_here
/// ```
class AppConfig {
  const AppConfig._();

  /// TMDB API key injected via `--dart-define`.
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  /// Whether a non-empty API key has been provided.
  static bool get hasApiKey => tmdbApiKey.isNotEmpty;

  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

  /// Image sizes chosen to match how each image is used in the UI.
  static const String posterSize = 'w500';
  static const String backdropSize = 'w780';
}
