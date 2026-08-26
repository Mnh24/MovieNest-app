import 'package:flutter/material.dart';

import '../features/movies/presentation/screens/home_screen.dart';

/// The app's root. Navigation to Search and Watchlist happens from the home
/// screen's top bar (search field and saved-list icon), so there is no
/// persistent bottom navigation bar — the home screen owns the full viewport
/// for its cinematic, edge-to-edge layout.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
