import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../watchlist/presentation/widgets/watchlist_icon_button.dart';
import '../../domain/entities/movie.dart';
import '../providers/search_provider.dart';
import '../widgets/movie_list_skeleton.dart';
import '../widgets/movie_list_tile.dart';
import 'movie_details_screen.dart';

/// Dedicated search experience with debounced queries and explicit states.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Open the keyboard as soon as the screen appears so the user can type.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onClear() {
    _controller.clear();
    ref.read(searchProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  void _openDetails(Movie movie) {
    _focusNode.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          onChanged: ref.read(searchProvider.notifier).onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search movies',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: _onClear,
                );
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: () => _focusNode.unfocus(),
          behavior: HitTestBehavior.opaque,
          child: _buildBody(state),
        ),
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    return switch (state) {
      SearchInitial() => const MessageView(
        icon: Icons.search,
        title: 'Search for movies',
        message: 'Find films by title and open them for full details.',
      ),
      SearchLoading() => const MovieListSkeleton(),
      SearchError(:final failure) => MessageView(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to search right now.',
        message: messageForError(failure),
        onRetry: () => ref.read(searchProvider.notifier).retry(),
      ),
      SearchEmpty(:final query) => MessageView(
        icon: Icons.movie_filter_outlined,
        title: 'No results for "$query"',
        message: 'Try a different title or check your spelling.',
      ),
      SearchResults(:final movies) => ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: movies.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return MovieListTile(
            movie: movie,
            trailing: WatchlistIconButton(movie: movie),
            onTap: () => _openDetails(movie),
          );
        },
      ),
    };
  }
}
