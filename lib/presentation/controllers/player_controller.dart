import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/models/song_model.dart';
import '../../data/repositories/music_repository.dart';

class PlayerController extends GetxController {
  final AudioPlayerService _playerService = Get.find<AudioPlayerService>();
  final MusicRepository _repository = Get.find<MusicRepository>();

  // Getters from player service
  Rx<SongModel?> get currentSong => _playerService.currentSong;
  RxList<SongModel> get queue => _playerService.queue;
  RxInt get currentIndex => _playerService.currentIndex;
  RxBool get isPlaying => _playerService.isPlaying;
  RxBool get isLoading => _playerService.isLoading;
  RxBool get isShuffled => _playerService.isShuffled;
  Rx<LoopMode> get loopMode => _playerService.loopMode;

  Stream<ProgressState> get progressStream => _playerService.progressStream;

  // Play a song
  Future<void> playSong(SongModel song) async {
    try {
      await _playerService.playSong(song);
    } catch (e) {
      Get.snackbar(
        'Playback Error',
        'Failed to play song: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Play a list of songs
  Future<void> playQueue(List<SongModel> songs, {int startIndex = 0}) async {
    try {
      await _playerService.playQueue(songs, startIndex: startIndex);
    } catch (e) {
      Get.snackbar(
        'Playback Error',
        'Failed to play queue: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Playback controls
  void togglePlayPause() {
    _playerService.togglePlayPause();
  }

  void play() {
    _playerService.play();
  }

  void pause() {
    _playerService.pause();
  }

  void seekTo(Duration position) {
    _playerService.seek(position);
  }

  void skipToNext() {
    _playerService.skipToNext();
  }

  void skipToPrevious() {
    _playerService.skipToPrevious();
  }

  void skipToQueueItem(int index) {
    _playerService.skipToQueueItem(index);
  }

  // Queue management
  void addToQueue(SongModel song) {
    _playerService.addToQueue(song);
    Get.snackbar(
      'Added to Queue',
      song.title,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void removeFromQueue(int index) {
    _playerService.removeFromQueue(index);
  }

  void clearQueue() {
    _playerService.clearQueue();
  }

  // Loop and shuffle
  void toggleLoopMode() {
    _playerService.toggleLoopMode();
    
    String message;
    switch (loopMode.value) {
      case LoopMode.off:
        message = 'Loop: Off';
        break;
      case LoopMode.all:
        message = 'Loop: All';
        break;
      case LoopMode.one:
        message = 'Loop: One';
        break;
    }
    
    Get.snackbar(
      'Loop Mode',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void toggleShuffle() {
    _playerService.toggleShuffle();
    Get.snackbar(
      'Shuffle',
      isShuffled.value ? 'Enabled' : 'Disabled',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  // Load radio based on current song
  Future<void> playRadio() async {
    final song = currentSong.value;
    if (song == null) return;

    try {
      await _playerService.startRadio(song);
      Get.snackbar(
        'Radio Started',
        'Playing songs similar to ${song.title}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load radio',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Start radio from a specific song (for single song plays)
  Future<void> startRadioFrom(SongModel song) async {
    try {
      await _playerService.startRadio(song);
    } catch (e) {
      Get.snackbar(
        'Radio Error',
        'Failed to start radio: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
