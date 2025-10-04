import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/search_controller.dart' as app;
import '../../controllers/player_controller.dart';
import '../../widgets/song_list_item.dart';
import '../../widgets/album_card.dart';
import '../../widgets/artist_card.dart';
import '../../widgets/playlist_card.dart';
import '../../widgets/mini_player.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<app.SearchController>();
    final playerController = Get.find<PlayerController>();
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller.searchTextController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search songs, albums, artists...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          style: theme.textTheme.titleMedium,
          textInputAction: TextInputAction.search,
          onSubmitted: controller.search,
        ),
        actions: [
          Obx(() {
            if (controller.query.value.isNotEmpty) {
              return IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: controller.clearSearch,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
        // Show loading
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show recent searches when no query
        if (controller.query.value.isEmpty) {
          return _RecentSearches(controller: controller);
        }

        // Show error
        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Show results
        return Column(
          children: [
            // Filter Chips
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _FilterChip(
                    label: 'All',
                    value: 'all',
                    controller: controller,
                  ),
                  _FilterChip(
                    label: 'Songs',
                    value: 'songs',
                    controller: controller,
                  ),
                  _FilterChip(
                    label: 'Albums',
                    value: 'albums',
                    controller: controller,
                  ),
                  _FilterChip(
                    label: 'Artists',
                    value: 'artists',
                    controller: controller,
                  ),
                  _FilterChip(
                    label: 'Playlists',
                    value: 'playlists',
                    controller: controller,
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: _SearchResults(
                controller: controller,
                playerController: playerController,
              ),
            ),
          ],
        );
            }),
          ),
          // Mini Player
          const MiniPlayer(),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  final app.SearchController controller;

  const _RecentSearches({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Obx(() {
      if (controller.recentSearches.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_rounded,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Search for music',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find songs, albums, artists, and playlists',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: controller.clearRecentSearches,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...controller.recentSearches.map((search) {
            return ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(search),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => controller.deleteRecentSearch(search),
              ),
              onTap: () {
                controller.searchTextController.text = search;
                controller.search(search);
              },
            );
          }),
        ],
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final app.SearchController controller;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              controller.setFilter(value);
            }
          },
        ),
      );
    });
  }
}

class _SearchResults extends StatelessWidget {
  final app.SearchController controller;
  final PlayerController playerController;

  const _SearchResults({
    required this.controller,
    required this.playerController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = controller.selectedFilter.value;

    // Check if there are no results
    final hasNoResults = controller.songs.isEmpty &&
        controller.albums.isEmpty &&
        controller.artists.isEmpty &&
        controller.playlists.isEmpty;

    if (hasNoResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      children: [
        // Songs
        if ((filter == 'all' || filter == 'songs') && controller.songs.isNotEmpty) ...[
          _ResultHeader(title: 'Songs (${controller.songs.length})'),
          ...controller.songs.map((song) {
            return SongListItem(
              song: song,
              onTap: () {
                // Auto-open full player first
                Get.toNamed('/player');
                // Then start playing
                playerController.playSong(song);
              },
            );
          }),
          const SizedBox(height: 24),
        ],

        // Albums
        if ((filter == 'all' || filter == 'albums') && controller.albums.isNotEmpty) ...[
          _ResultHeader(title: 'Albums (${controller.albums.length})'),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.albums.length,
              itemBuilder: (context, index) {
                final album = controller.albums[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AlbumCard(album: album),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Artists
        if ((filter == 'all' || filter == 'artists') && controller.artists.isNotEmpty) ...[
          _ResultHeader(title: 'Artists (${controller.artists.length})'),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.artists.length,
              itemBuilder: (context, index) {
                final artist = controller.artists[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ArtistCard(artist: artist),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Playlists
        if ((filter == 'all' || filter == 'playlists') && controller.playlists.isNotEmpty) ...[
          _ResultHeader(title: 'Playlists (${controller.playlists.length})'),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.playlists.length,
              itemBuilder: (context, index) {
                final playlist = controller.playlists[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: PlaylistCard(playlist: playlist),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final String title;

  const _ResultHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
