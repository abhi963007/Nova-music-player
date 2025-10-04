import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/playlist_model.dart';
import '../../../data/repositories/music_repository.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/song_list_item.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final _repository = Get.find<MusicRepository>();
  final _playerController = Get.find<PlayerController>();
  
  PlaylistModel? _playlist;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final playlistId = Get.parameters['id'];
    
    print('🎵 Loading playlist with ID: $playlistId');
    
    if (playlistId == null) {
      setState(() {
        _error = 'No playlist ID provided';
        _isLoading = false;
      });
      return;
    }

    try {
      final playlist = await _repository.getPlaylist(playlistId);
      
      print('🎵 Playlist loaded: ${playlist?.title ?? "NULL"}');
      print('🎵 Song count: ${playlist?.songs.length ?? 0}');
      
      setState(() {
        _playlist = playlist;
        // Show debug info in UI if no songs
        if (playlist != null && playlist.songs.isEmpty) {
          _error = 'DEBUG: Playlist loaded but has 0 songs.\nTitle: ${playlist.title}\nID: $playlistId\nCheck terminal for API response.';
        }
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading playlist: $e');
      print('Stack: $stackTrace');
      setState(() {
        _error = 'Failed to load playlist: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _playlist == null
                  ? const Center(child: Text('Playlist not found'))
                  : CustomScrollView(
                      slivers: [
                        // Header with playlist info
                        SliverAppBar(
                          expandedHeight: 300,
                          pinned: true,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_playlist!.thumbnail.isNotEmpty)
                                  CachedNetworkImage(
                                    imageUrl: _playlist!.thumbnail,
                                    fit: BoxFit.cover,
                                  ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        theme.scaffoldBackgroundColor,
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _playlist!.title,
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${_playlist!.songCount} songs',
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Play all button
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: FilledButton.icon(
                              onPressed: _playlist!.songs.isNotEmpty
                                  ? () => _playerController.playQueue(_playlist!.songs)
                                  : null,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Play All'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ),

                        // Songs list
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = _playlist!.songs[index];
                              return SongListItem(
                                song: song,
                                onTap: () => _playerController.playSong(song),
                              );
                            },
                            childCount: _playlist!.songs.length,
                          ),
                        ),
                      ],
                    ),
    );
  }
}
