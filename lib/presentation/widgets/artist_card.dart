import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/artist_model.dart';
import '../../core/routes/app_routes.dart';

class ArtistCard extends StatelessWidget {
  final ArtistModel artist;

  const ArtistCard({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.artist, arguments: artist);
      },
      child: Container(
        width: 140,
        child: Column(
          children: [
            // Circular Thumbnail
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.surfaceVariant,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  artist.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Name
            Text(
              artist.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            
            if (artist.subscribers.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                artist.subscribers,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
