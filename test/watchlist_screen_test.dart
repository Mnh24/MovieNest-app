import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_app/core/providers.dart';
import 'package:movie_app/features/movies/domain/entities/movie.dart';
import 'package:movie_app/features/watchlist/presentation/providers/watchlist_provider.dart';
import 'package:movie_app/features/watchlist/presentation/screens/watchlist_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> _app(SharedPreferences prefs) async {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const MaterialApp(home: WatchlistScreen()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the empty state when nothing is saved', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(await _app(prefs));

    expect(find.text('No movies saved yet'), findsOneWidget);
  });

  testWidgets('lists a saved movie', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final widget = await _app(prefs);
    await tester.pumpWidget(widget);

    final element = tester.element(find.byType(WatchlistScreen));
    final container = ProviderScope.containerOf(element);
    await container
        .read(watchlistProvider.notifier)
        .add(const Movie(id: 1, title: 'Saved Movie'));
    await tester.pump();

    expect(find.text('Saved Movie'), findsOneWidget);
    expect(find.text('No movies saved yet'), findsNothing);
  });
}
