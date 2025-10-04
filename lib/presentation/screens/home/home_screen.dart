import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/player_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/song_model.dart';
import '../../widgets/song_list_item.dart';
import '../../widgets/album_card.dart';
import '../../widgets/playlist_card.dart';
import '../../widgets/mini_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomeTab(),
          LibraryTab(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player
          const MiniPlayer(),
          
          // Navigation Bar
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music_rounded),
                label: 'Library',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<HomeController>();
    
    return RefreshIndicator(
      onRefresh: controller.refreshContent,
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar.large(
            title: Text(
              'Harmony Music',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: controller.refreshContent,
                tooltip: 'Refresh latest songs',
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  Get.toNamed(AppRoutes.search);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

        // Content
        Obx(() {
          if (controller.isLoading.value) {
            return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.error.value.isNotEmpty) {
            return SliverFillRemaining(
              child: Center(
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
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: controller.loadHomeContent,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildListDelegate([
              // Malayalam Trending
              if (controller.malayalamTrending.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Malayalam Trending (${controller.malayalamTrending.length} songs)',
                  icon: Icons.trending_up_rounded,
                  subtitle: 'Latest Malayalam hits • Updated daily',
                ),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.malayalamTrending.length,
                    itemBuilder: (context, index) {
                      final song = controller.malayalamTrending[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SongCard(
                          song: song,
                          allSongs: controller.malayalamTrending,
                          songIndex: index,
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Tamil Trending
              if (controller.tamilTrending.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Tamil Trending (${controller.tamilTrending.length} songs)',
                  icon: Icons.trending_up_rounded,
                  subtitle: 'Latest Tamil hits • Updated daily',
                ),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.tamilTrending.length,
                    itemBuilder: (context, index) {
                      final song = controller.tamilTrending[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SongCard(
                          song: song,
                          allSongs: controller.tamilTrending,
                          songIndex: index,
                        ),
                      );
                    },
                  ),
                ),
              ],

              // English Trending
              if (controller.englishTrending.isNotEmpty) ...[
                _SectionHeader(
                  title: 'English Trending (${controller.englishTrending.length} songs)',
                  icon: Icons.trending_up_rounded,
                  subtitle: 'Latest English hits • Updated daily',
                ),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.englishTrending.length,
                    itemBuilder: (context, index) {
                      final song = controller.englishTrending[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SongCard(
                          song: song,
                          allSongs: controller.englishTrending,
                          songIndex: index,
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Global Trending
              if (controller.trendingSongs.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Trending Now (${controller.trendingSongs.length} songs)',
                  icon: Icons.trending_up_rounded,
                  subtitle: 'Global trending music • All languages',
                ),
                SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.trendingSongs.length,
                    itemBuilder: (context, index) {
                      final song = controller.trendingSongs[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SongCard(
                          song: song,
                          allSongs: controller.trendingSongs,
                          songIndex: index,
                        ),
                      );
                    },
                  ),
                ),
              ],

              // New Albums
              if (controller.newAlbums.isNotEmpty) ...[
                _SectionHeader(
                  title: 'New Albums',
                  icon: Icons.album_rounded,
                ),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.newAlbums.length,
                    itemBuilder: (context, index) {
                      final album = controller.newAlbums[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: AlbumCard(album: album),
                      );
                    },
                  ),
                ),
              ],

              // Featured Playlists
              if (controller.featuredPlaylists.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Featured Playlists',
                  icon: Icons.queue_music_rounded,
                ),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.featuredPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = controller.featuredPlaylists[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: PlaylistCard(playlist: playlist),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 100), // Bottom padding
            ]),
          );
        }),
        ],
      ),
    );
  }
}

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(
            'Your Library',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_music_outlined,
                  size: 80,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Library',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your saved songs, albums, and playlists\nwill appear here',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SongCard extends StatelessWidget {
  final dynamic song;
  final List<dynamic>? allSongs;
  final int? songIndex;

  const SongCard({
    super.key, 
    required this.song,
    this.allSongs,
    this.songIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerController = Get.find<PlayerController>();
    
    return GestureDetector(
      onTap: () {
        // Auto-open full player first
        Get.toNamed(AppRoutes.player);
        
        // Then start playing
        if (allSongs != null && songIndex != null) {
          playerController.playQueue(
            allSongs!.cast<SongModel>(),
            startIndex: songIndex!,
          );
        } else {
          playerController.playSong(song);
        }
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  song.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      song.artist,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
