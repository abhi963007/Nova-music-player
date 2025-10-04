import 'package:flutter/material.dart';
import '../../data/models/song_model.dart';

class SongListItem extends StatelessWidget {
  final SongModel song;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  const SongListItem({
    super.key,
    required this.song,
    this.onTap,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          song.thumbnail,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 56,
              height: 56,
              color: theme.colorScheme.surfaceVariant,
              child: Icon(
                Icons.music_note_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ),
      title: Text(
        song.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_rounded),
        onPressed: onMore ?? () {
          _showSongOptions(context);
        },
      ),
      onTap: onTap,
    );
  }

  void _showSongOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: const Text('Add to Queue'),
                onTap: () {
                  Navigator.pop(context);
                  // Add to queue functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  // Add to playlist functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.radio_rounded),
                title: const Text('Start Radio'),
                onTap: () {
                  Navigator.pop(context);
                  // Start radio functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // Share functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
