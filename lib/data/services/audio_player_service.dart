import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart' as rx;
import '../models/song_model.dart';
import '../repositories/music_repository.dart';
import 'stream_service.dart';
import 'package:get/get.dart';

class AudioPlayerService extends GetxService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final StreamService _streamService = Get.find<StreamService>();
  
  // Flag to check if background audio is available
  static bool _backgroundAudioEnabled = false;
  
  static void setBackgroundAudioEnabled(bool enabled) {
    _backgroundAudioEnabled = enabled;
  }

  // Observables
  final Rx<SongModel?> currentSong = Rx<SongModel?>(null);
  final RxList<SongModel> queue = <SongModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isShuffled = false.obs;
  final Rx<LoopMode> loopMode = LoopMode.off.obs;
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;

  // Radio mode variables (based on reference implementation)
  bool isRadioModeOn = false;
  String? radioContinuationParam;
  SongModel? radioInitiatorSong;
  bool _autoplayTriggered = false;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  // Combined progress stream
  Stream<ProgressState> get progressStream {
    return rx.CombineLatestStream.combine3<Duration, Duration?, PlayerState, ProgressState>(
        _audioPlayer.positionStream,
        _audioPlayer.durationStream,
        _audioPlayer.playerStateStream,
        (position, duration, playerState) => ProgressState(
              position: position,
              duration: duration ?? Duration.zero,
              buffered: _audioPlayer.bufferedPosition,
            ));
  }

  @override
  void onInit() {
    super.onInit();
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      isLoading.value = state.processingState == ProcessingState.loading ||
                       state.processingState == ProcessingState.buffering;
    });

    // Listen to position stream for progress and autoplay detection
    _audioPlayer.positionStream.listen((position) {
      currentPosition.value = position;
      
      // Check if song is near completion for autoplay
      final duration = totalDuration.value;
      if (duration.inSeconds > 0) {
        final remainingSeconds = duration.inSeconds - position.inSeconds;
        // When 10 seconds remaining, prepare autoplay
        if (remainingSeconds == 10 && !_autoplayTriggered) {
          _prepareAutoplay();
        }
      }
    });

    // Listen to duration stream
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        totalDuration.value = duration;
      }
    });

    // Handle playback completion
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _autoplayTriggered = false; // Reset for next song
        
        if (loopMode.value == LoopMode.one) {
          seek(Duration.zero);
          play();
        } else if (currentIndex.value < queue.length - 1) {
          skipToNext();
        } else if (loopMode.value == LoopMode.all) {
          skipToQueueItem(0);
        } else if (isRadioModeOn) {
          // Radio mode: load more songs
          _addRadioContinuation();
        } else {
          // Playback ended
          isPlaying.value = false;
        }
      }
    });
  }

  // Legacy method - keep for compatibility but doesn't do anything
  Future<void> _prepareAutoplay() async {
    // Radio mode handles similar songs now
    _autoplayTriggered = true;
  }

  // Play a single song
  Future<void> playSong(SongModel song) async {
    try {
      isLoading.value = true;
      currentSong.value = song;
      queue.clear();
      queue.add(song);
      currentIndex.value = 0;

      // Fetch stream URL
      final streamProvider = await _streamService.fetchStreamUrl(song.id);
      if (streamProvider == null || streamProvider.audioStreams.isEmpty) {
        throw Exception('No stream URL found');
      }

      // Get best quality stream
      final bestStream = streamProvider.audioStreams.first;

      // Create audio source with metadata (only if background audio is enabled)
      final audioSource = _backgroundAudioEnabled
          ? AudioSource.uri(
              Uri.parse(bestStream.url),
              tag: MediaItem(
                id: song.id,
                title: song.title,
                artist: song.artist,
                artUri: song.thumbnail.isNotEmpty ? Uri.parse(song.thumbnail) : null,
                duration: streamProvider.duration,
              ),
            )
          : AudioSource.uri(Uri.parse(bestStream.url));

      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing song: $e');
      isLoading.value = false;
      rethrow;
    }
  }

  // Play a queue of songs - simplified approach
  Future<void> playQueue(List<SongModel> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;

    // Set up queue
    queue.clear();
    queue.addAll(songs);
    currentIndex.value = startIndex;
    
    // Play the first song using single song method
    await playSong(songs[startIndex]);
  }

  // Start radio mode based on reference implementation
  Future<void> startRadio(SongModel song) async {
    try {
      print('🎵 Starting radio for: ${song.title}');
      
      radioInitiatorSong = song;
      isRadioModeOn = true;
      
      // Get watch playlist with radio mode enabled
      final result = await Get.find<MusicRepository>().getWatchPlaylist(
        videoId: song.id,
        radio: true,
        limit: 25,
      );
      
      final tracks = result['tracks'] as List<SongModel>? ?? [];
      radioContinuationParam = result['additionalParamsForNext'];
      
      if (tracks.isNotEmpty) {
        queue.clear();
        queue.addAll(tracks);
        currentIndex.value = 0;
        
        await playSong(tracks[0]);
        print('✅ Radio started with ${tracks.length} songs');
      } else {
        print('⚠️ No radio songs found, playing original song');
        isRadioModeOn = false;
        await playSong(song);
      }
    } catch (e) {
      print('❌ Error starting radio: $e');
      isRadioModeOn = false;
      // Fallback: play the original song
      await playSong(song);
    }
  }

  // Add radio continuation when queue is running low
  Future<void> _addRadioContinuation() async {
    if (!isRadioModeOn || radioInitiatorSong == null) return;
    
    try {
      print('🎵 Loading more radio songs...');
      
      final result = await Get.find<MusicRepository>().getWatchPlaylist(
        videoId: radioInitiatorSong!.id,
        radio: true,
        limit: 24,
        additionalParamsNext: radioContinuationParam,
      );
      
      final tracks = result['tracks'] as List<SongModel>;
      radioContinuationParam = result['additionalParamsForNext'];
      
      if (tracks.isNotEmpty) {
        queue.addAll(tracks);
        print('✅ Added ${tracks.length} more radio songs');
      }
    } catch (e) {
      print('❌ Error loading radio continuation: $e');
    }
  }

  Future<void> _loadSongAtIndex(int index) async {
    if (index < 0 || index >= queue.length) return;

    currentIndex.value = index;
    currentSong.value = queue[index];
    
    final song = queue[index];
    final streamProvider = await _streamService.fetchStreamUrl(song.id);
    
    if (streamProvider == null || streamProvider.audioStreams.isEmpty) {
      throw Exception('No stream URL found');
    }

    final bestStream = streamProvider.audioStreams.first;
    final audioSource = _backgroundAudioEnabled
        ? AudioSource.uri(
            Uri.parse(bestStream.url),
            tag: MediaItem(
              id: song.id,
              title: song.title,
              artist: song.artist,
              artUri: song.thumbnail.isNotEmpty ? Uri.parse(song.thumbnail) : null,
              duration: streamProvider.duration,
            ),
          )
        : AudioSource.uri(Uri.parse(bestStream.url));

    // For concatenating source, add the song if it doesn't exist at this index
    if (_audioPlayer.audioSource is ConcatenatingAudioSource) {
      final concatenating = _audioPlayer.audioSource as ConcatenatingAudioSource;
      
      // If this index doesn't exist yet, add the song
      if (index >= concatenating.children.length) {
        await concatenating.add(audioSource);
      }
      
      // Seek to the song
      await _audioPlayer.seek(Duration.zero, index: index);
    } else {
      // Fallback for single audio source
      await _audioPlayer.setAudioSource(audioSource);
    }
  }

  Future<void> _preloadSongAtIndex(int index) async {
    if (index < 0 || index >= queue.length) return;

    try {
      final song = queue[index];
      final streamProvider = await _streamService.fetchStreamUrl(song.id);
      
      if (streamProvider != null && streamProvider.audioStreams.isNotEmpty) {
        final bestStream = streamProvider.audioStreams.first;
        final audioSource = _backgroundAudioEnabled
            ? AudioSource.uri(
                Uri.parse(bestStream.url),
                tag: MediaItem(
                  id: song.id,
                  title: song.title,
                  artist: song.artist,
                  artUri: song.thumbnail.isNotEmpty ? Uri.parse(song.thumbnail) : null,
                  duration: streamProvider.duration,
                ),
              )
            : AudioSource.uri(Uri.parse(bestStream.url));

        if (_audioPlayer.audioSource is ConcatenatingAudioSource) {
          final concatenating = _audioPlayer.audioSource as ConcatenatingAudioSource;
          if (index >= concatenating.children.length) {
            await concatenating.add(audioSource);
          }
        }
      }
    } catch (e) {
      print('Error preloading song at index $index: $e');
    }
  }

  // Playback controls
  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlayPause() async {
    if (isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> skipToNext() async {
    try {
      // Check if we're near the end of queue and need to load more radio songs
      if (isRadioModeOn && currentIndex.value >= queue.length - 5) {
        await _addRadioContinuation();
      }
      
      if (currentIndex.value < queue.length - 1) {
        // Skip to next song in queue
        currentIndex.value++;
        await playSong(queue[currentIndex.value]);
      } else if (isRadioModeOn) {
        // Radio mode: load more songs if possible
        await _addRadioContinuation();
        if (currentIndex.value < queue.length - 1) {
          currentIndex.value++;
          await playSong(queue[currentIndex.value]);
        }
      } else {
        // Not in radio mode: start radio based on current song
        final currentSongData = currentSong.value;
        if (currentSongData != null) {
          await startRadio(currentSongData);
        }
      }
    } catch (e) {
      print('❌ Error in skipToNext: $e');
    }
  }

  Future<void> skipToPrevious() async {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      await playSong(queue[currentIndex.value]);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < queue.length) {
      currentIndex.value = index;
      await playSong(queue[index]);
    }
  }

  // Queue management
  void addToQueue(SongModel song) {
    queue.add(song);
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < queue.length && index != currentIndex.value) {
      queue.removeAt(index);
    }
  }

  void clearQueue() {
    queue.clear();
    currentSong.value = null;
    currentIndex.value = 0;
    stop();
  }

  // Loop mode
  void toggleLoopMode() {
    switch (loopMode.value) {
      case LoopMode.off:
        loopMode.value = LoopMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        loopMode.value = LoopMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        loopMode.value = LoopMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
  }

  // Shuffle
  void toggleShuffle() {
    isShuffled.value = !isShuffled.value;
    if (isShuffled.value) {
      _audioPlayer.setShuffleModeEnabled(true);
    } else {
      _audioPlayer.setShuffleModeEnabled(false);
    }
  }

  // Stop playback
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}

class ProgressState {
  final Duration position;
  final Duration duration;
  final Duration buffered;

  ProgressState({
    required this.position,
    required this.duration,
    required this.buffered,
  });
}
