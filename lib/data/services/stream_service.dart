import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/stream_provider_model.dart' as model;

class StreamService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<model.StreamProviderModel?> fetchStreamUrl(String videoId) async {
    try {
      print('Fetching stream URL for: $videoId');
      
      // Get stream manifest
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      // Get audio-only streams
      final audioStreams = manifest.audioOnly.toList();
      
      if (audioStreams.isEmpty) {
        print('No audio streams found for: $videoId');
        return null;
      }

      // Sort by bitrate (highest first)
      audioStreams.sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));

      // Get video details
      final video = await _yt.videos.get(videoId);
      
      print('Found ${audioStreams.length} audio streams for: ${video.title}');
      print('Best quality: ${audioStreams.first.bitrate.kiloBitsPerSecond} kbps');

      return model.StreamProviderModel(
        videoId: videoId,
        title: video.title,
        artist: video.author,
        thumbnail: video.thumbnails.highResUrl,
        duration: video.duration ?? Duration.zero,
        audioStreams: audioStreams.map((stream) => model.AudioStreamInfo(
          url: stream.url.toString(),
          bitrate: stream.bitrate.kiloBitsPerSecond.toInt(),
          codec: stream.audioCodec,
          size: stream.size.totalBytes,
        )).toList(),
      );
    } catch (e) {
      print('Error fetching stream URL: $e');
      return null;
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final suggestions = await _yt.search.getQuerySuggestions(query);
      return suggestions.take(10).toList();
    } catch (e) {
      print('Error fetching search suggestions: $e');
      return [];
    }
  }

  void dispose() {
    _yt.close();
  }
}
