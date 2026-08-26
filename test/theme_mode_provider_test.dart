import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movienest/core/providers.dart';
import 'package:movienest/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> buildContainer() async {
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('defaults to dark mode when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await buildContainer();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('reads a persisted system mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'system'});
    final container = await buildContainer();

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('reads a persisted mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final container = await buildContainer();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('setThemeMode updates and persists the selection', () async {
    SharedPreferences.setMockInitialValues({});
    final container = await buildContainer();

    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.light);

    expect(container.read(themeModeProvider), ThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });
}
