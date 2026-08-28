/// Application-wide configuration values.
///
/// There are two ways to reach TMDB, chosen at build/run time:
///
/// 1. **Backend proxy (recommended for release/TestFlight).** Point the app at
///    a Cloud Functions proxy that holds the TMDB key server-side, so the
///    secret never ships inside the binary. The proxy URL is *not* a secret:
///
///    ```
///    flutter build ipa --dart-define=TMDB_PROXY_URL=https://<region>-<project>.cloudfunctions.net/tmdb
///    ```
///
/// 2. **Direct key (local development only).** Inject the TMDB key straight
///    into the app. Convenient for local runs, but the key is embedded in the
///    binary and can be extracted, so don't use this for public builds:
///
///    ```
///    flutter run --dart-define=TMDB_API_KEY=your_key_here
///    ```
///
/// If both are provided the proxy wins. See SETUP_FIREBASE.md for the backend.
class AppConfig {
  const AppConfig._();

  /// TMDB proxy base URL injected via `--dart-define` (preferred path).
  static const String tmdbProxyUrl = String.fromEnvironment('TMDB_PROXY_URL');

  /// TMDB API key injected via `--dart-define` (direct/dev path only).
  static const String tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');

  /// TMDB API Read Access Token (v4 Bearer token) injected via `--dart-define`.
  static const String tmdbReadAccessToken = String.fromEnvironment(
    'TMDB_READ_ACCESS_TOKEN',
  );

  /// Whether the app should route TMDB calls through the backend proxy.
  static bool get useProxy => tmdbProxyUrl.isNotEmpty;

  /// Whether the app has a usable TMDB configuration (proxy, direct key, or access token).
  static bool get isConfigured =>
      useProxy || tmdbApiKey.isNotEmpty || tmdbReadAccessToken.isNotEmpty;

  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';

  /// Base URL the REST client talks to: the proxy when configured, otherwise
  /// TMDB directly (dev path). Both expose the same `/movie/...` route shape.
  static String get apiBaseUrl => useProxy ? tmdbProxyUrl : tmdbBaseUrl;

  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

  /// Image sizes chosen to match how each image is used in the UI.
  ///
  /// Smaller sizes are requested for small thumbnails so they download and
  /// decode quickly; larger sizes are reserved for the full-bleed hero where
  /// quality matters. TMDB serves each width from its CDN, so picking the
  /// right one per surface keeps images crisp without over-fetching.
  static const String posterSizeSmall = 'w342';
  static const String posterSize = 'w500';
  static const String posterSizeLarge = 'w780';
  static const String backdropSize = 'w780';
  static const String backdropSizeLarge = 'w1280';
  static const String profileSize = 'w185';
}
