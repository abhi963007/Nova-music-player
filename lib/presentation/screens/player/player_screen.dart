import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../controllers/player_controller.dart';
import '../../widgets/blur_background.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<PlayerController>();
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              _showOptionsBottomSheet(context, controller);
            },
          ),
        ],
      ),
      body: Obx(() {
        final song = controller.currentSong.value;
        
        if (song == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off_rounded,
                  size: 80,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No song playing',
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            // Blurred Background
            BlurBackground(imageUrl: song.thumbnail),
            
            // Content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  
                  // Album Art
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Hero(
                      tag: 'song_${song.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
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
                                    size: 120,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Song Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        Text(
                          song.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.artist,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Progress Bar
                  const _ProgressBar(),
                  
                  const SizedBox(height: 24),
                  
                  // Controls
                  const _PlayerControls(),
                  
                  const SizedBox(height: 24),
                  
                  // Secondary Controls
                  const _SecondaryControls(),
                  
                  const Spacer(),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, PlayerController controller) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: const Text('View Queue'),
                onTap: () {
                  Get.back();
                  _showQueueBottomSheet(context, controller);
                },
              ),
              ListTile(
                leading: const Icon(Icons.radio_rounded),
                title: const Text('Start Radio'),
                onTap: () {
                  Get.back();
                  controller.playRadio();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () {
                  Get.back();
                  // Implement share functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQueueBottomSheet(BuildContext context, PlayerController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Queue',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          controller.clearQueue();
                          Get.back();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: controller.queue.length,
                      itemBuilder: (context, index) {
                        final song = controller.queue[index];
                        final isPlaying = controller.currentIndex.value == index;
                        
                        return ListTile(
                          leading: isPlaying
                              ? const Icon(Icons.play_circle_filled_rounded)
                              : Text('${index + 1}'),
                          title: Text(
                            song.title,
                            style: TextStyle(
                              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(song.artist),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => controller.removeFromQueue(index),
                          ),
                          onTap: () {
                            controller.skipToQueueItem(index);
                            Get.back();
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<PlayerController>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: StreamBuilder(
        stream: controller.progressStream,
        builder: (context, snapshot) {
          final progress = snapshot.data;
          final position = progress?.position ?? Duration.zero;
          final duration = progress?.duration ?? Duration.zero;
          
          return Column(
            children: [
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.3),
                ),
                child: Slider(
                  value: position.inMilliseconds.toDouble().clamp(
                    0.0,
                    duration.inMilliseconds.toDouble(),
                  ),
                  max: duration.inMilliseconds.toDouble() == 0
                      ? 1.0
                      : duration.inMilliseconds.toDouble(),
                  onChanged: (value) {
                    controller.seekTo(Duration(milliseconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _PlayerControls extends StatelessWidget {
  const _PlayerControls();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    
    return Obx(() {
      final isPlaying = controller.isPlaying.value;
      final isLoading = controller.isLoading.value;
      
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Shuffle
            IconButton(
              iconSize: 28,
              icon: Icon(
                Icons.shuffle_rounded,
                color: controller.isShuffled.value
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
              onPressed: controller.toggleShuffle,
            ),
            
            // Previous
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
              onPressed: controller.skipToPrevious,
            ),
            
            // Play/Pause
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  : IconButton(
                      iconSize: 40,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black87,
                      ),
                      onPressed: controller.togglePlayPause,
                    ),
            ),
            
            // Next
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
              onPressed: controller.skipToNext,
            ),
            
            // Repeat
            IconButton(
              iconSize: 28,
              icon: Icon(
                controller.loopMode.value == LoopMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                color: controller.loopMode.value != LoopMode.off
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
              onPressed: controller.toggleLoopMode,
            ),
          ],
        ),
      );
    });
  }
}

class _SecondaryControls extends StatelessWidget {
  const _SecondaryControls();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PlayerController>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.favorite_border_rounded,
              color: Colors.white.withOpacity(0.8),
            ),
            onPressed: () {
              // Implement favorite functionality
            },
          ),
          IconButton(
            icon: Icon(
              Icons.playlist_add_rounded,
              color: Colors.white.withOpacity(0.8),
            ),
            onPressed: () {
              // Implement add to playlist functionality
            },
          ),
        ],
      ),
    );
  }
}
