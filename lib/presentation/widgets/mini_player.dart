import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/player_controller.dart';
import '../../core/routes/app_routes.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.find<PlayerController>();
    
    return Obx(() {
      final song = controller.currentSong.value;
      
      if (song == null) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: () {
          Get.toNamed(AppRoutes.player);
        },
        child: Container(
          height: 72,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                child: Image.network(
                  song.thumbnail,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 72,
                      height: 72,
                      color: theme.colorScheme.surface,
                      child: Icon(
                        Icons.music_note_rounded,
                        color: theme.colorScheme.onSurface,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Song Info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
              
              // Play/Pause Button
              IconButton(
                icon: Icon(
                  controller.isPlaying.value
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                onPressed: controller.togglePlayPause,
              ),
              
              // Next Button
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: controller.skipToNext,
              ),
              
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
    });
  }
}
