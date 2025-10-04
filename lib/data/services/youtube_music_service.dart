import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/album_model.dart';
import '../models/artist_model.dart';
import '../models/playlist_model.dart';

class YoutubeMusicService {
  static const String domain = 'https://music.youtube.com';
  static const String baseUrl = 'https://music.youtube.com/youtubei/v1/';
  static const String fixedParams = '?key=AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30&prettyPrint=false';
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  late Dio _dio;
  String? _visitorId;

  final Map<String, String> _headers = {
    'user-agent': userAgent,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': domain,
    'cookie': 'CONSENT=YES+1',
  };

  final Map<String, dynamic> _context = {
    'context': {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.20230213.01.00',
      },
      'user': {}
    }
  };

  YoutubeMusicService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    // Don't call async in constructor
  }

  Future<void> _ensureVisitorId() async {
    if (_visitorId != null) return;
    
    final prefs = await SharedPreferences.getInstance();
    _visitorId = prefs.getString('visitor_id');
    
    if (_visitorId == null || _visitorId!.isEmpty) {
      _visitorId = await _generateVisitorId();
      if (_visitorId != null) {
        await prefs.setString('visitor_id', _visitorId!);
      }
    }
  }

  Future<String?> _generateVisitorId() async {
    try {
      final response = await _dio.get(domain, options: Options(headers: _headers));
      
      final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
      final matches = reg.firstMatch(response.data.toString());
      
      if (matches != null) {
        final ytcfg = json.decode(matches.group(1).toString());
        return ytcfg['VISITOR_DATA']?.toString();
      }
    } catch (e) {
      print('Error generating visitor ID: $e');
    }
    return null;
  }

  Future<Response> _sendRequest(String action, Map<dynamic, dynamic> data) async {
    // Ensure visitor ID is initialized before making requests
    await _ensureVisitorId();
    
    if (_visitorId != null) {
      data['context']['user'] = {'lockedSafetyMode': false};
    }
    
    try {
      final response = await _dio.post(
        '$baseUrl$action$fixedParams',
        options: Options(headers: _headers),
        data: json.encode(data),
      );
      return response;
    } catch (e) {
      print('API Request Error: $e');
      rethrow;
    }
  }

  // Get Home Feed
  Future<Map<String, List<dynamic>>> getHome() async {
    try {
      final data = Map<String, dynamic>.from(_context);
      data['browseId'] = 'FEmusic_home';
      
      final response = await _sendRequest('browse', data);
      return _parseMixedContent(response.data);
    } catch (e) {
      print('Error fetching home: $e');
      return {};
    }
  }

  // Search
  Future<Map<String, List<dynamic>>> search(String query, {String? filter}) async {
    try {
      final data = Map<String, dynamic>.from(_context);
      data['query'] = query;
      if (filter != null) {
        data['params'] = filter; // 'songs', 'albums', 'artists', 'playlists'
      }
      
      final response = await _sendRequest('search', data);
      return _parseSearchResults(response.data);
    } catch (e) {
      print('Error searching: $e');
      return {};
    }
  }

  // Get Album Details
  Future<AlbumModel?> getAlbum(String browseId) async {
    try {
      final data = Map<String, dynamic>.from(_context);
      data['browseId'] = browseId;
      
      final response = await _sendRequest('browse', data);
      return _parseAlbum(response.data);
    } catch (e) {
      print('Error fetching album: $e');
      return null;
    }
  }

  // Get Artist Details
  Future<ArtistModel?> getArtist(String browseId) async {
    try {
      final data = Map<String, dynamic>.from(_context);
      data['browseId'] = browseId;
      
      final response = await _sendRequest('browse', data);
      return _parseArtist(response.data);
    } catch (e) {
      print('Error fetching artist: $e');
      return null;
    }
  }

  // Get Playlist Details
  Future<PlaylistModel?> getPlaylist(String playlistId) async {
    try {
      final data = Map<String, dynamic>.from(_context);
      
      // Auto-generated playlists (RD...) use 'next' endpoint via getWatchPlaylist
      // Regular playlists use 'browse' endpoint
      if (playlistId.startsWith('RD')) {
        print('🎵 Fetching auto-generated playlist: $playlistId (using next endpoint)');
        return await _getWatchPlaylist(playlistId);
      }
      
      final browseId = playlistId.startsWith('VL') ? playlistId : 'VL$playlistId';
      data['browseId'] = browseId;
      
      print('🎵 Fetching playlist with browseId: $browseId');
      
      final response = await _sendRequest('browse', data);
      
      return _parsePlaylist(response.data);
    } catch (e) {
      print('Error fetching playlist: $e');
      return null;
    }
  }
  
  // Get watch playlist for auto-generated playlists (RD...)
  Future<PlaylistModel?> _getWatchPlaylist(String playlistId) async {
    try {
      final data = Map<String, dynamic>.from(_context);
      data['playlistId'] = playlistId;
      data['isAudioOnly'] = true;
      
      final response = await _sendRequest('next', data);
      final responseData = response.data;
      
      // Parse from next endpoint response
      final watchNextRenderer = responseData['contents']
          ?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']
          ?['watchNextTabbedResultsRenderer'];
      
      if (watchNextRenderer == null) {
        print('⚠️ No watchNextRenderer found');
        return null;
      }
      
      final results = watchNextRenderer['tabs']?[0]?['tabRenderer']?['content']
          ?['musicQueueRenderer']?['content']?['playlistPanelRenderer'];
      
      if (results == null) {
        print('⚠️ No playlistPanelRenderer found');
        return null;
      }
      
      final List<SongModel> songs = [];
      final contents = results['contents'] ?? [];
      
      for (var item in contents) {
        if (item.containsKey('playlistPanelVideoRenderer')) {
          final renderer = item['playlistPanelVideoRenderer'];
          final videoId = renderer['videoId'] ?? '';
          
          if (videoId.isEmpty) continue;
          
          final title = renderer['title']?['runs']?[0]?['text'] ?? 'Unknown';
          final artists = renderer['longBylineText']?['runs'] ?? [];
          final artist = artists.isNotEmpty ? artists[0]['text'] ?? 'Unknown Artist' : 'Unknown Artist';
          
          final thumbnails = renderer['thumbnail']?['thumbnails'] ?? [];
          final thumbnail = thumbnails.isNotEmpty ? thumbnails.last['url'] ?? '' : '';
          
          songs.add(SongModel(
            id: videoId,
            title: title,
            artist: artist,
            thumbnail: thumbnail,
            duration: '',
          ));
          
          print('✅ Added: $title ($videoId)');
        }
      }
      
      print('✅ Parsed watch playlist with ${songs.length} songs');
      
      return PlaylistModel(
        id: playlistId,
        title: 'Mix Playlist',
        description: '',
        thumbnail: songs.isNotEmpty ? songs[0].thumbnail : '',
        songCount: songs.length,
        songs: songs,
      );
    } catch (e) {
      print('Error fetching watch playlist: $e');
      return null;
    }
  }

  // Radio/Watch playlist functionality (based on reference implementation)
  Future<Map<String, dynamic>> getWatchPlaylist({
    String videoId = "",
    String? playlistId,
    int limit = 25,
    bool radio = false,
    bool shuffle = false,
    String? additionalParamsNext,
  }) async {
    try {
      final data = Map.from(_context);
      data['enablePersistentPlaylistPanel'] = true;
      data['isAudioOnly'] = true;
      data['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';

      if (videoId.isNotEmpty) {
        data['videoId'] = videoId;
        playlistId ??= "RDAMVM$videoId"; // Radio playlist ID format
      }

      if (playlistId != null) {
        data['playlistId'] = playlistId;
      }

      // Radio mode parameters
      if (radio) {
        data['params'] = "wAEB"; // YouTube Music radio parameter
      }

      // Add continuation parameters if provided
      if (additionalParamsNext != null) {
        data.addAll(_parseContinuationParams(additionalParamsNext));
      }

      final response = await _sendRequest('next', data);
      
      if (response.data == null) {
        throw Exception('No data received from YouTube Music');
      }

      return _parseWatchPlaylistResponse(response.data, limit);
    } catch (e) {
      print('Error getting watch playlist: $e');
      return {
        'tracks': <SongModel>[],
        'playlistId': playlistId,
        'additionalParamsForNext': null,
      };
    }
  }

  // Parse watch playlist response and extract songs
  Map<String, dynamic> _parseWatchPlaylistResponse(dynamic response, int limit) {
    final tracks = <SongModel>[];
    String? additionalParamsForNext;
    String? currentPlaylistId;

    try {
      // Navigate to contents
      final contents = response['contents']?['singleColumnMusicWatchNextResultsRenderer']?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];
      
      if (contents != null && contents.isNotEmpty) {
        final tabContent = contents[0]['tabRenderer']?['content']?['musicQueueRenderer']?['content']?['playlistPanelRenderer'];
        
        if (tabContent != null) {
          currentPlaylistId = tabContent['playlistId'];
          
          // Parse songs from playlist items
          final playlistItems = tabContent['contents'] as List?;
          if (playlistItems != null) {
            for (final item in playlistItems.take(limit)) {
              final song = _parseWatchPlaylistSong(item);
              if (song != null) {
                tracks.add(song);
              }
            }
          }

          // Look for continuation parameters
          final continuations = tabContent['continuations'];
          if (continuations != null && continuations.isNotEmpty) {
            final continuation = continuations[0]['nextContinuationData']?['continuation'];
            if (continuation != null) {
              additionalParamsForNext = "&ctoken=$continuation&continuation=$continuation";
            }
          }
        }
      }

      print('✅ Parsed watch playlist: ${tracks.length} songs');
    } catch (e) {
      print('Error parsing watch playlist response: $e');
    }

    return {
      'tracks': tracks,
      'playlistId': currentPlaylistId,
      'additionalParamsForNext': additionalParamsForNext,
    };
  }

  // Parse individual song from watch playlist
  SongModel? _parseWatchPlaylistSong(dynamic item) {
    try {
      final playlistItemData = item['playlistPanelVideoRenderer'];
      if (playlistItemData == null) return null;

      final videoId = playlistItemData['videoId'];
      if (videoId == null || videoId.isEmpty) return null;

      // Extract title from runs
      final title = playlistItemData['title']?['runs']?[0]?['text'] ?? 
                    playlistItemData['title']?['simpleText'] ?? 
                    'Unknown Title';
      
      // Extract artist from longBylineText
      String artist = 'Unknown Artist';
      final longBylineText = playlistItemData['longBylineText'];
      if (longBylineText != null && longBylineText['runs'] != null) {
        final runs = longBylineText['runs'] as List;
        artist = runs.map((run) => run['text'] ?? '').join('');
      }

      // Extract thumbnail
      String thumbnail = '';
      final thumbnails = playlistItemData['thumbnail']?['thumbnails'];
      if (thumbnails != null && thumbnails.isNotEmpty) {
        thumbnail = thumbnails.last['url'] ?? '';
      }

      return SongModel(
        id: videoId,
        title: title,
        artist: artist,
        thumbnail: thumbnail,
        duration: '0:00',
      );
    } catch (e) {
      print('Error parsing watch playlist song: $e');
      return null;
    }
  }

  // Parse continuation parameters
  Map<String, dynamic> _parseContinuationParams(String params) {
    final result = <String, dynamic>{};
    final pairs = params.split('&');
    
    for (final pair in pairs) {
      if (pair.isNotEmpty) {
        final parts = pair.split('=');
        if (parts.length == 2) {
          result[parts[0]] = parts[1];
        }
      }
    }
    
    return result;
  }

  // Get Song Radio (backward compatibility)
  Future<List<SongModel>> getRadio(String videoId) async {
    try {
      final result = await getWatchPlaylist(videoId: videoId, radio: true);
      return result['tracks'] as List<SongModel>;
    } catch (e) {
      print('Error getting radio: $e');
      return [];
    }
  }

  // Parse Methods
  Map<String, List<dynamic>> _parseMixedContent(Map<String, dynamic> data) {
    final Map<String, List<dynamic>> result = {
      'songs': [],
      'albums': [],
      'playlists': [],
    };

    try {
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']
          ?['sectionListRenderer']?['contents'] ?? [];

      for (var section in contents) {
        final shelfContents = section['musicCarouselShelfRenderer']?['contents'] ?? [];
        
        for (var item in shelfContents) {
          if (item.containsKey('musicTwoRowItemRenderer')) {
            final itemData = item['musicTwoRowItemRenderer'];
            final navigationEndpoint = itemData['navigationEndpoint'];
            
            if (navigationEndpoint?['browseEndpoint'] != null) {
              final browseId = navigationEndpoint['browseEndpoint']['browseId'];
              if (browseId.startsWith('MPREb_')) {
                result['albums']!.add(_parseAlbumFromItem(itemData));
              } else if (browseId.startsWith('VL')) {
                result['playlists']!.add(_parsePlaylistFromItem(itemData));
              }
            }
          } else if (item.containsKey('musicResponsiveListItemRenderer')) {
            result['songs']!.add(_parseSongFromItem(item['musicResponsiveListItemRenderer']));
          }
        }
      }
    } catch (e) {
      print('Error parsing mixed content: $e');
    }

    return result;
  }

  Map<String, List<dynamic>> _parseSearchResults(Map<String, dynamic> data) {
    final Map<String, List<dynamic>> result = {
      'songs': [],
      'albums': [],
      'artists': [],
      'playlists': [],
    };

    try {
      final contents = data['contents']?['tabbedSearchResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']
          ?['sectionListRenderer']?['contents'] ?? [];

      for (var section in contents) {
        final items = section['musicShelfRenderer']?['contents'] ?? [];
        
        for (var item in items) {
          if (item.containsKey('musicResponsiveListItemRenderer')) {
            final itemData = item['musicResponsiveListItemRenderer'];
            final category = _getItemCategory(itemData);
            
            switch (category) {
              case 'song':
                result['songs']!.add(_parseSongFromItem(itemData));
                break;
              case 'album':
                result['albums']!.add(_parseAlbumFromItem(itemData));
                break;
              case 'artist':
                result['artists']!.add(_parseArtistFromItem(itemData));
                break;
              case 'playlist':
                result['playlists']!.add(_parsePlaylistFromItem(itemData));
                break;
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing search results: $e');
    }

    return result;
  }

  String _getItemCategory(Map<String, dynamic> item) {
    final flexColumns = item['flexColumns'] ?? [];
    if (flexColumns.length > 1) {
      final secondColumn = flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs']?[0]?['text'] ?? '';
      
      if (secondColumn.toLowerCase().contains('song')) return 'song';
      if (secondColumn.toLowerCase().contains('album')) return 'album';
      if (secondColumn.toLowerCase().contains('artist')) return 'artist';
      if (secondColumn.toLowerCase().contains('playlist')) return 'playlist';
    }
    return 'song'; // Default
  }

  SongModel _parseSongFromItem(Map<String, dynamic> item) {
    final flexColumns = item['flexColumns'] ?? [];
    String title = 'Unknown';
    if (flexColumns.isNotEmpty) {
      title = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs']?[0]?['text'] ?? 'Unknown';
    }
    
    String artist = 'Unknown Artist';
    if (flexColumns.length > 1) {
      artist = flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs']?[0]?['text'] ?? 'Unknown Artist';
    }

    // Try multiple paths to extract video ID
    String videoId = '';
    
    // Path 1: playlistItemData
    videoId = item['playlistItemData']?['videoId'] ?? '';
    
    // Path 2: overlay -> musicPlayButtonRenderer
    if (videoId.isEmpty) {
      videoId = item['overlay']?['musicItemThumbnailOverlayRenderer']
          ?['content']?['musicPlayButtonRenderer']
          ?['playNavigationEndpoint']?['watchEndpoint']?['videoId'] ?? '';
    }
    
    // Path 3: navigationEndpoint
    if (videoId.isEmpty) {
      videoId = item['navigationEndpoint']?['watchEndpoint']?['videoId'] ?? '';
    }
    
    // Path 4: flexColumns -> text -> runs -> navigationEndpoint
    if (videoId.isEmpty && flexColumns.isNotEmpty) {
      final runs = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs'] ?? [];
      if (runs.isNotEmpty) {
        videoId = runs[0]['navigationEndpoint']?['watchEndpoint']?['videoId'] ?? '';
      }
    }
    
    // Path 5: doubleTapCommand
    if (videoId.isEmpty) {
      videoId = item['doubleTapCommand']?['watchEndpoint']?['videoId'] ?? '';
    }

    final thumbnails = item['thumbnail']?['musicThumbnailRenderer']
        ?['thumbnail']?['thumbnails'] ?? [];
    final thumbnail = thumbnails.isNotEmpty ? thumbnails.last['url'] : '';

    // Debug logging
    if (videoId.isEmpty) {
      print('⚠️ Warning: Empty video ID for song: $title by $artist');
      print('Item keys: ${item.keys.toList()}');
    } else {
      print('✅ Parsed song: $title (ID: $videoId)');
    }

    return SongModel(
      id: videoId,
      title: title,
      artist: artist,
      thumbnail: thumbnail,
      duration: '',
    );
  }

  // Parse playlist items - matching reference project's parsePlaylistItems()
  SongModel? _parsePlaylistSong(Map<String, dynamic> item) {
    try {
      // CRITICAL: playlistItemData contains the direct videoId - this is the primary source
      final String videoId = item['playlistItemData']?['videoId'] ?? '';
      
      if (videoId.isEmpty) {
        print('⚠️ No videoId in playlistItemData for item');
        print('Available keys: ${item.keys.toList()}');
        return null;
      }
      
      // Extract title and artist from flex columns
      final flexColumns = item['flexColumns'] ?? [];
      String title = 'Unknown';
      String artist = 'Unknown Artist';
      
      if (flexColumns.isNotEmpty) {
        final firstColumn = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer'];
        final runs = firstColumn?['text']?['runs'] ?? [];
        if (runs.isNotEmpty) {
          title = runs[0]['text'] ?? 'Unknown';
        }
      }
      
      if (flexColumns.length > 1) {
        final secondColumn = flexColumns[1]['musicResponsiveListItemFlexColumnRenderer'];
        final runs = secondColumn?['text']?['runs'] ?? [];
        if (runs.isNotEmpty) {
          artist = runs[0]['text'] ?? 'Unknown Artist';
        }
      }
      
      // Extract thumbnail
      final thumbnails = item['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] ?? [];
      final thumbnail = thumbnails.isNotEmpty ? thumbnails.last['url'] ?? '' : '';
      
      return SongModel(
        id: videoId,
        title: title,
        artist: artist,
        thumbnail: thumbnail,
        duration: '',
      );
    } catch (e) {
      print('❌ Error parsing playlist song: $e');
      return null;
    }
  }

  AlbumModel _parseAlbumFromItem(Map<String, dynamic> item) {
    final title = item['title']?['runs']?[0]?['text'] ?? 'Unknown Album';
    final subtitle = item['subtitle']?['runs']?[0]?['text'] ?? 'Unknown Artist';
    final browseId = item['navigationEndpoint']?['browseEndpoint']?['browseId'] ?? '';
    final thumbnails = item['thumbnailRenderer']?['musicThumbnailRenderer']
        ?['thumbnail']?['thumbnails'] ?? [];
    final thumbnail = thumbnails.isNotEmpty ? thumbnails.last['url'] : '';

    return AlbumModel(
      id: browseId,
      title: title,
      artist: subtitle,
      thumbnail: thumbnail,
      year: '',
      songs: [],
    );
  }

  ArtistModel _parseArtistFromItem(Map<String, dynamic> item) {
    final name = item['flexColumns']?[0]['musicResponsiveListItemFlexColumnRenderer']
        ?['text']?['runs']?[0]?['text'] ?? 'Unknown Artist';
    final browseId = item['navigationEndpoint']?['browseEndpoint']?['browseId'] ?? '';
    final thumbnails = item['thumbnail']?['musicThumbnailRenderer']
        ?['thumbnail']?['thumbnails'] ?? [];
    final thumbnail = thumbnails.isNotEmpty ? thumbnails.last['url'] : '';

    return ArtistModel(
      id: browseId,
      name: name,
      thumbnail: thumbnail,
      subscribers: '',
    );
  }

  PlaylistModel _parsePlaylistFromItem(Map<String, dynamic> item) {
    final title = item['title']?['runs']?[0]?['text'] ?? 'Unknown Playlist';
    final subtitle = item['subtitle']?['runs']?[0]?['text'] ?? '';
    final browseId = item['navigationEndpoint']?['browseEndpoint']?['browseId'] ?? '';
    final playlistId = browseId.replaceFirst('VL', '');
    final thumbnails = item['thumbnailRenderer']?['musicThumbnailRenderer']
        ?['thumbnail']?['thumbnails'] ?? [];
    final thumbnail = thumbnails.isNotEmpty ? thumbnails.last['url'] : '';

    return PlaylistModel(
      id: playlistId,
      title: title,
      description: subtitle,
      thumbnail: thumbnail,
      songCount: 0,
      songs: [],
    );
  }

  AlbumModel? _parseAlbum(Map<String, dynamic> data) {
    // Implementation for parsing full album details
    return null;
  }

  ArtistModel? _parseArtist(Map<String, dynamic> data) {
    // Implementation for parsing full artist details
    return null;
  }

  PlaylistModel? _parsePlaylist(Map<String, dynamic> data) {
    try {
      // Parse header - matching reference project approach
      final header = data['header']?['musicDetailHeaderRenderer'] ?? 
                    data['header']?['musicEditablePlaylistDetailHeaderRenderer'] ??
                    data['contents']?['twoColumnBrowseResultsRenderer']?['tabs']?[0]
                        ?['tabRenderer']?['content']?['sectionListRenderer']?['contents']
                        ?[0]?['musicResponsiveHeaderRenderer'];
      
      final String title = header?['title']?['runs']?[0]?['text'] ?? 
                           header?['title']?['simpleText'] ??
                           'Unknown Playlist';
      
      final description = header?['description']?['runs']?[0]?['text'] ?? 
                         header?['subtitle']?['runs']?[0]?['text'] ?? '';
      
      final thumbnails = header?['thumbnail']?['croppedSquareThumbnailRenderer']
          ?['thumbnail']?['thumbnails'] ?? 
          header?['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] ?? [];
      final thumbnail = thumbnails.isNotEmpty ? thumbnails.last['url'] ?? '' : '';
      
      // Parse songs - matching reference project structure
      final List<SongModel> songs = [];
      
      // Path 1: musicPlaylistShelfRenderer (most common for playlists)
      var results = data['contents']?['twoColumnBrowseResultsRenderer']
          ?['secondaryContents']?['sectionListRenderer']?['contents']?[0]
          ?['musicPlaylistShelfRenderer'];
      
      // Path 2: singleColumnBrowseResultsRenderer
      if (results == null) {
        results = data['contents']?['singleColumnBrowseResultsRenderer']
            ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
            ?['contents']?[0]?['musicPlaylistShelfRenderer'];
      }
      
      // Path 3: Direct musicShelfRenderer
      if (results == null) {
        results = data['contents']?['singleColumnBrowseResultsRenderer']
            ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
            ?['contents']?[0]?['musicShelfRenderer'];
      }
      
      if (results != null && results['contents'] != null) {
        for (var item in results['contents']) {
          if (item.containsKey('musicResponsiveListItemRenderer')) {
            final song = _parsePlaylistSong(item['musicResponsiveListItemRenderer']);
            if (song != null && song.id.isNotEmpty) {
              songs.add(song);
              print('✅ Added: ${song.title} (${song.id})');
            }
          }
        }
      }
      
      print('✅ Parsed playlist: $title with ${songs.length} songs');
      
      return PlaylistModel(
        id: results?['playlistId'] ?? '',
        title: title,
        description: description,
        thumbnail: thumbnail,
        songCount: songs.length,
        songs: songs,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing playlist: $e');
      print('Stack: $stackTrace');
      return null;
    }
  }

  List<SongModel> _parseRadioSongs(Map<String, dynamic> data) {
    // Implementation for parsing radio songs
    return [];
  }
}
