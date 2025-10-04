import 'package:get/get.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/models/song_model.dart';
import '../../data/models/album_model.dart';
import '../../data/models/playlist_model.dart';

class HomeController extends GetxController {
  final MusicRepository _repository = Get.find<MusicRepository>();

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  final RxList<SongModel> trendingSongs = <SongModel>[].obs;
  final RxList<SongModel> malayalamTrending = <SongModel>[].obs;
  final RxList<SongModel> tamilTrending = <SongModel>[].obs;
  final RxList<SongModel> englishTrending = <SongModel>[].obs;
  final RxList<AlbumModel> newAlbums = <AlbumModel>[].obs;
  final RxList<PlaylistModel> featuredPlaylists = <PlaylistModel>[].obs;

  final RxInt selectedTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadHomeContent();
  }

  Future<void> loadHomeContent() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Load main home content
      final content = await _repository.getHomeContent();

      // Process songs
      if (content['songs'] != null) {
        trendingSongs.clear();
        trendingSongs.addAll(
          (content['songs'] as List).map((item) => item as SongModel).toList(),
        );
      }

      // Process albums
      if (content['albums'] != null) {
        newAlbums.clear();
        newAlbums.addAll(
          (content['albums'] as List).map((item) => item as AlbumModel).toList(),
        );
      }

      // Process playlists
      if (content['playlists'] != null) {
        featuredPlaylists.clear();
        featuredPlaylists.addAll(
          (content['playlists'] as List).map((item) => item as PlaylistModel).toList(),
        );
      }

      // Load language-specific trending songs
      _loadLanguageTrending();
    } catch (e) {
      error.value = 'Failed to load content: $e';
      print('Error loading home content: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLanguageTrending() async {
    // Get current year for latest songs
    final currentYear = DateTime.now().year;
    
    // Load Malayalam trending with multiple search terms for variety
    try {
      final malayalamQueries = [
        'malayalam songs $currentYear latest',
        'malayalam hits trending now',
        'new malayalam songs 2024 2025',
        'malayalam romantic songs latest',
        'malayalam movie songs new'
      ];
      
      final malayalamSongs = <SongModel>[];
      for (final query in malayalamQueries) {
        final results = await _repository.search(query, filter: 'songs');
        if (results['songs'] != null) {
          malayalamSongs.addAll(
            (results['songs'] as List).take(8).map((item) => item as SongModel).toList(),
          );
        }
      }
      malayalamTrending.clear();
      malayalamTrending.addAll(malayalamSongs.take(40).toList());
      print('✅ Loaded ${malayalamTrending.length} Malayalam songs');
    } catch (e) {
      print('Error loading Malayalam trending: $e');
    }

    // Load Tamil trending with multiple search terms
    try {
      final tamilQueries = [
        'tamil songs $currentYear latest',
        'tamil hits trending now',
        'new tamil songs 2024 2025',
        'tamil romantic songs latest',
        'tamil movie songs new'
      ];
      
      final tamilSongs = <SongModel>[];
      for (final query in tamilQueries) {
        final results = await _repository.search(query, filter: 'songs');
        if (results['songs'] != null) {
          tamilSongs.addAll(
            (results['songs'] as List).take(8).map((item) => item as SongModel).toList(),
          );
        }
      }
      tamilTrending.clear();
      tamilTrending.addAll(tamilSongs.take(40).toList());
      print('✅ Loaded ${tamilTrending.length} Tamil songs');
    } catch (e) {
      print('Error loading Tamil trending: $e');
    }

    // Load English trending with multiple search terms
    try {
      final englishQueries = [
        'english songs $currentYear latest hits',
        'english pop songs trending',
        'new english songs 2024 2025',
        'english romantic songs latest',
        'top english hits now'
      ];
      
      final englishSongs = <SongModel>[];
      for (final query in englishQueries) {
        final results = await _repository.search(query, filter: 'songs');
        if (results['songs'] != null) {
          englishSongs.addAll(
            (results['songs'] as List).take(8).map((item) => item as SongModel).toList(),
          );
        }
      }
      englishTrending.clear();
      englishTrending.addAll(englishSongs.take(40).toList());
      print('✅ Loaded ${englishTrending.length} English songs');
    } catch (e) {
      print('Error loading English trending: $e');
    }
  }

  Future<void> refreshContent() async {
    await loadHomeContent();
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }
}
