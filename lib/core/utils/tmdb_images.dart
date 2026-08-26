import '../constants/app_config.dart';

/// Builds full TMDB image URLs from the relative paths returned by the API.
class TmdbImages {
  const TmdbImages._();

  static String? posterSmall(String? path) =>
      _url(path, AppConfig.posterSizeSmall);

  static String? poster(String? path) => _url(path, AppConfig.posterSize);

  static String? posterLarge(String? path) =>
      _url(path, AppConfig.posterSizeLarge);

  static String? backdrop(String? path) => _url(path, AppConfig.backdropSize);

  static String? backdropLarge(String? path) =>
      _url(path, AppConfig.backdropSizeLarge);

  static String? profile(String? path) => _url(path, AppConfig.profileSize);

  static String? _url(String? path, String size) {
    if (path == null || path.isEmpty) return null;
    return '${AppConfig.tmdbImageBaseUrl}/$size$path';
  }
}
