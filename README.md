# Movies

A polished Flutter application for discovering films with The Movie Database
(TMDB). Browse what's trending, search the full catalogue, dive into movie
details, and keep a personal watchlist that works completely offline.

## Features

- **Trending** — browse the week's trending movies with poster, title, release
  year and rating.
- **Search** — debounced, responsive search with clear, empty, no-results and
  error states.
- **Details** — backdrop, poster, rating, runtime, genres, tagline and overview,
  with graceful fallbacks for missing data.
- **Watchlist** — add/remove movies, persisted locally and fully usable offline.
- **Theming** — Light, Dark and System modes, remembered across restarts.

## Requirements

- Flutter `>=3.32.0`
- Dart `>=3.8.0`
- A free TMDB API key — create one at
  [themoviedb.org](https://www.themoviedb.org/settings/api).

## TMDB API key setup

The API key is **never** committed to the repository. It is supplied at build
time through a Dart compile-time environment variable
(`String.fromEnvironment('TMDB_API_KEY')`).

Run the app with:

```bash
flutter run --dart-define=TMDB_API_KEY=your_api_key_here
```

Build a release the same way:

```bash
flutter build apk --dart-define=TMDB_API_KEY=your_api_key_here
```

If no key is provided, the app shows a clear message explaining how to supply
one instead of failing with network errors.

## Running

```bash
flutter pub get
flutter run --dart-define=TMDB_API_KEY=your_api_key_here
```

## Architecture

The project uses a feature-oriented, layered structure with a clear separation
between networking, data, domain and presentation.

```
lib/
  app/                     App root, theming wiring, entry screens
  core/
    constants/             App configuration (base URLs, API key access)
    errors/                Typed Failure hierarchy
    network/               Dio client and error mapping
    theme/                 Material 3 themes, spacing scale, theme provider
    utils/                 JSON parsing and image URL helpers
    widgets/               Shared UI (poster image, skeletons, state views)
    providers.dart         Dependency wiring (Dio, repositories, storage)
  features/
    movies/
      data/                Models and TMDB data source + repository impl
      domain/              Entities and repository contract
      presentation/        Providers, screens and widgets
    watchlist/
      data/                Local data source (SharedPreferences) + repository
      presentation/        Providers, screens and widgets
  main.dart
```

Data flows one way: **UI → provider → repository → data source**. HTTP requests
live only in the TMDB data source; widgets never call the network directly.
Raw JSON is converted into typed entities at the data layer so no `dynamic`
API data leaks into the UI.

## State management

State is managed with **Riverpod**. Each concern has a dedicated provider:

- `trendingProvider` — `AsyncNotifier` exposing loading/success/error for the
  trending list, with pull-to-refresh and retry.
- `searchProvider` — an auto-disposing notifier that debounces input (400 ms),
  cancels stale results and exposes explicit `initial / loading / results /
  empty / error` states.
- `movieDetailsProvider` — an auto-disposing `FutureProvider.family` keyed by
  movie id.
- `watchlistProvider` — a `Notifier` backed by local storage for instant,
  offline reads and immediate optimistic updates.
- `themeModeProvider` — a `Notifier` that persists the selected theme.

`AsyncValue` (and the explicit search state) model the required Initial,
Loading, Success, Empty and Error states throughout.

## Offline watchlist

The watchlist is persisted with **SharedPreferences** as a compact JSON array
of movies, keyed by the stable TMDB movie id (duplicates are prevented). Only
the fields needed to render a saved movie are stored, keeping the payload small.

Because the list and each saved movie's core information come from local
storage, the watchlist — and opening a saved movie's details — works with no
network connection. On the details screen the base movie renders immediately
from cached data; extended fields that require the network degrade gracefully
with an inline note if unavailable.

## Theming

Both light and dark themes are built from a shared seed colour with Material 3,
each intentionally tuned for contrast rather than a naive inversion. Component
styling (app bar, cards, inputs, buttons, chips, dividers) is centralized in
`AppTheme`, and spacing/radius scales live in `AppSpacing`/`AppRadius`. The
selected mode (`light` / `dark` / `system`) is persisted and restored on launch.

## Testing

```bash
flutter test
```

Tests cover model parsing (including null/missing fields), watchlist
persistence and add/remove/duplicate behaviour, the theme mode notifier, and
key widget states (empty watchlist and search initial state).

## Static analysis & formatting

```bash
dart format .
flutter analyze
```
