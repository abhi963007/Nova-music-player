import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/models/song_model.dart';
import '../../data/models/album_model.dart';
import '../../data/models/artist_model.dart';
import '../../data/models/playlist_model.dart';

class SearchController extends GetxController {
  final MusicRepository _repository = Get.find<MusicRepository>();

  final TextEditingController searchTextController = TextEditingController();
  
  final RxString query = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString selectedFilter = 'all'.obs; // all, songs, albums, artists, playlists

  final RxList<SongModel> songs = <SongModel>[].obs;
  final RxList<AlbumModel> albums = <AlbumModel>[].obs;
  final RxList<ArtistModel> artists = <ArtistModel>[].obs;
  final RxList<PlaylistModel> playlists = <PlaylistModel>[].obs;

  final RxList<String> recentSearches = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    // Load from shared preferences or local storage
    // For now, just initialize empty
  }

  Future<void> search(String searchQuery) async {
    if (searchQuery.trim().isEmpty) return;

    try {
      isLoading.value = true;
      error.value = '';
      query.value = searchQuery;

      // Add to recent searches
      if (!recentSearches.contains(searchQuery)) {
        recentSearches.insert(0, searchQuery);
        if (recentSearches.length > 10) {
          recentSearches.removeLast();
        }
      }

      // Determine filter parameter
      String? filterParam;
      switch (selectedFilter.value) {
        case 'songs':
          filterParam = 'EgWKAQIIAWoMEAMQBBAJEAoQBRAV';
          break;
        case 'albums':
          filterParam = 'EgWKAQIYAWoMEAMQBBAJEAoQBRAV';
          break;
        case 'artists':
          filterParam = 'EgWKAQIgAWoMEAMQBBAJEAoQBRAV';
          break;
        case 'playlists':
          filterParam = 'EgWKAQIoAWoMEAMQBBAJEAoQBRAV';
          break;
      }

      final results = await _repository.search(searchQuery, filter: filterParam);

      // Clear previous results
      songs.clear();
      albums.clear();
      artists.clear();
      playlists.clear();

      // Process results
      if (results['songs'] != null) {
        songs.addAll(
          (results['songs'] as List).map((item) => item as SongModel).toList(),
        );
      }

      if (results['albums'] != null) {
        albums.addAll(
          (results['albums'] as List).map((item) => item as AlbumModel).toList(),
        );
      }

      if (results['artists'] != null) {
        artists.addAll(
          (results['artists'] as List).map((item) => item as ArtistModel).toList(),
        );
      }

      if (results['playlists'] != null) {
        playlists.addAll(
          (results['playlists'] as List).map((item) => item as PlaylistModel).toList(),
        );
      }
    } catch (e) {
      error.value = 'Search failed: $e';
      print('Error searching: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    if (query.value.isNotEmpty) {
      search(query.value);
    }
  }

  void clearSearch() {
    query.value = '';
    searchTextController.clear();
    songs.clear();
    albums.clear();
    artists.clear();
    playlists.clear();
    error.value = '';
  }

  void deleteRecentSearch(String search) {
    recentSearches.remove(search);
  }

  void clearRecentSearches() {
    recentSearches.clear();
  }

  @override
  void onClose() {
    searchTextController.dispose();
    super.onClose();
  }
}
