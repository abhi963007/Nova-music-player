import 'package:get/get.dart';
import '../services/youtube_music_service.dart';
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';

class MusicRepository extends GetxService {
  final YoutubeMusicService _musicService = Get.find<YoutubeMusicService>();

  Future<Map<String, List<dynamic>>> getHomeContent() async {
    return await _musicService.getHome();
  }

  Future<Map<String, List<dynamic>>> search(String query, {String? filter}) async {
    return await _musicService.search(query, filter: filter);
  }

  Future<AlbumModel?> getAlbum(String browseId) async {
    return await _musicService.getAlbum(browseId);
  }

  Future<ArtistModel?> getArtist(String browseId) async {
    return await _musicService.getArtist(browseId);
  }

  Future<PlaylistModel?> getPlaylist(String playlistId) async {
    return await _musicService.getPlaylist(playlistId);
  }

  Future<List<SongModel>> getRadio(String videoId) async {
    return await _musicService.getRadio(videoId);
  }

  Future<Map<String, dynamic>> getWatchPlaylist({
    String videoId = "",
    String? playlistId,
    int limit = 25,
    bool radio = false,
    String? additionalParamsNext,
  }) async {
    return await _musicService.getWatchPlaylist(
      videoId: videoId,
      playlistId: playlistId,
      limit: limit,
      radio: radio,
      additionalParamsNext: additionalParamsNext,
    );
  }
}
