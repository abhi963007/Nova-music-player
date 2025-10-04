# 🎵 Harmony Music Autoplay/Similar Song Implementation Analysis

## 📋 Overview

This document provides a comprehensive analysis of how Harmony Music implements intelligent autoplay and similar song suggestions using YouTube Music's API. The implementation creates seamless, continuous playback similar to Spotify's Radio feature.

## 🔧 Core Architecture

### Key Files:
1. **`lib/services/music_service.dart`** - YouTube Music API integration
2. **`lib/ui/player/player_controller.dart`** - Player logic and radio mode management
3. **`lib/services/audio_handler.dart`** - Queue management and playback control
4. **`lib/services/continuations.dart`** - Pagination and continuation handling

## 🎯 Radio/Autoplay Implementation

### 1. Radio Mode Trigger (`player_controller.dart`)

```dart
// Key variables for radio functionality
bool isRadioModeOn = false;
String? radioContinuationParam;
dynamic radioInitiatorItem;

// Main method to start radio mode
Future<void> startRadio(MediaItem? mediaItem, {String? playlistid}) async {
  radioInitiatorItem = mediaItem ?? playlistid;
  await pushSongToQueue(mediaItem, playlistid: playlistid, radio: true);
}

// Push song to queue with radio functionality
Future<void> pushSongToQueue(MediaItem? mediaItem,
    {String? playlistid, bool radio = false}) async {
  
  // Set radio mode flag
  isRadioModeOn = radio;
  
  // Call YouTube Music API for watch playlist
  final content = await _musicServices.getWatchPlaylist(
      videoId: mediaItem?.id ?? "", 
      radio: radio, 
      playlistId: playlistid);
      
  // Store continuation parameter for fetching more songs
  radioContinuationParam = content['additionalParamsForNext'];
  
  // Update queue with returned tracks
  await _audioHandler.updateQueue(List<MediaItem>.from(content['tracks']));
}
```

### 2. Automatic Continuation Detection

```dart
// Detects when to load more similar songs
if (isRadioModeOn && (currentSong.value!.id == currentQueue.last.id)) {
  await _addRadioContinuation(radioInitiatorItem!);
}

// Fetches additional radio songs
Future<void> _addRadioContinuation(dynamic item) async {
  final isSong = item.runtimeType.toString() == "MediaItem";
  final content = await _musicServices.getWatchPlaylist(
      videoId: isSong ? item.id : "",
      radio: true,
      limit: 24,  // Fetches 24 more songs
      playlistId: isSong ? null : item,
      additionalParamsNext: radioContinuationParam);
      
  // Update continuation parameter for next batch
  radioContinuationParam = content['additionalParamsForNext'];
  
  // Add new songs to queue
  await enqueueSongList(List<MediaItem>.from(content['tracks']));
}
```

## 🌐 YouTube Music API Integration

### 3. Core API Method (`music_service.dart`)

```dart
Future<Map<String, dynamic>> getWatchPlaylist(
    {String videoId = "",
    String? playlistId,
    int limit = 25,
    bool radio = false,  // Key parameter for similar songs
    bool shuffle = false,
    String? additionalParamsNext,
    bool onlyRelated = false}) async {

  final data = Map.from(_context);
  data['enablePersistentPlaylistPanel'] = true;
  data['isAudioOnly'] = true;
  data['tunerSettingValue'] = 'AUTOMIX_SETTING_NORMAL';
  
  if (videoId != "") {
    data['videoId'] = videoId;
    playlistId ??= "RDAMVM$videoId";  // Radio playlist ID format
  }
  
  // Radio mode parameters
  if (radio) {
    data['params'] = "wAEB";  // YouTube Music radio parameter
  }
  
  // API endpoint: YouTube Music "next" endpoint
  final response = (await _sendRequest("next", data)).data;
  
  // Parse response and extract tracks
  tracks.addAll(parseWatchPlaylist(results['contents']));
  
  return {
    'tracks': tracks,
    'playlistId': playlist,
    'lyrics': lyricsBrowseId,
    'related': relatedBrowseId,
    'additionalParamsForNext': additionalParamsForNext  // For continuation
  };
}
```

### 4. API Parameters & Endpoints

**Key API Details:**
- **Endpoint**: `/youtubei/v1/next` (YouTube Music internal API)
- **Radio Parameter**: `"wAEB"` - Enables radio/similar song mode
- **Playlist ID Format**: `"RDAMVM{videoId}"` - Radio playlist based on video
- **Context**: Uses `WEB_REMIX` client (YouTube Music web client)
- **Continuation**: Uses `additionalParamsForNext` for pagination

**Request Headers:**
```dart
final Map<String, String> _headers = {
  'user-agent': userAgent,
  'accept': '*/*',
  'accept-encoding': 'gzip, deflate',
  'content-type': 'application/json',
  'content-encoding': 'gzip',
  'origin': domain,
  'cookie': 'CONSENT=YES+1',
  'X-Goog-Visitor-Id': visitorId,  // Generated visitor ID
};
```

**Request Context:**
```dart
final Map<String, dynamic> _context = {
  'context': {
    'client': {
      "clientName": "WEB_REMIX",
      "clientVersion": "1.20230213.01.00",
      'hl': languageCode,  // User's language preference
    },
    'user': {}
  },
  'playbackContext': {
    'contentPlaybackContext': {
      'signatureTimestamp': signatureTimestamp
    }
  }
};
```

## 🔄 Continuation Logic (`continuations.dart`)

### 5. Pagination System

```dart
// Handles fetching more songs when queue is running low
Future<List<dynamic>> getContinuations(
    dynamic results,
    String continuationType,
    int limit,
    Future<dynamic> Function(String additionalParams) requestFunc,
    dynamic Function(Map<String, dynamic> continuationContents) parseFunc,
    {String ctokenPath = "",
    bool isAdditionparamReturnReq = false}) async {
    
  while (results.containsKey('continuations') && items.length < limit) {
    final String additionalParams = getContinuationParams(results, 
        ctokenPath: ctokenPath);
    
    final response = await requestFunc(additionalParams);
    // Parse and add more items
    items.addAll(contents);
  }
  
  return isAdditionparamReturnReq ? [items, additionalParam] : items;
}

// Generates continuation parameters
String getContinuationParams(dynamic results, {String ctokenPath = ''}) {
  final ctoken = nav(results, [
    'continuations', 0, 'next${ctokenPath}ContinuationData', 'continuation'
  ]);
  return "&ctoken=$ctoken&continuation=$ctoken";
}
```

**Continuation Constants:**
```dart
const CONTINUATION_TOKEN = [
  "continuationItemRenderer",
  "continuationEndpoint", 
  "continuationCommand",
  "token"
];

const CONTINUATION_ITEMS = [
  "onResponseReceivedActions",
  0,
  "appendContinuationItemsAction", 
  "continuationItems"
];
```

## 🎮 Queue Management (`audio_handler.dart`)

### 6. Queue Logic

```dart
// Determines next song in queue
int _getNextSongIndex() {
  if (shuffleModeEnabled) {
    // Handle shuffle mode
    if (currentShuffleIndex + 1 >= shuffledQueue.length) {
      shuffledQueue.shuffle();
      currentShuffleIndex = 0;
    } else {
      currentShuffleIndex += 1;
    }
    return queue.value.indexWhere(
        (item) => item.id == shuffledQueue[currentShuffleIndex]);
  }

  if (queue.value.length > currentIndex + 1) {
    return currentIndex + 1;
  } else if (queueLoopModeEnabled) {
    return 0;  // Loop back to start
  } else {
    return currentIndex;  // Stay on current song
  }
}

// Queue management methods
Future<void> addQueueItems(List<MediaItem> mediaItems) async {
  final newQueue = queue.value..addAll(mediaItems);
  queue.add(newQueue);
  
  if (shuffleModeEnabled) {
    final mediaItemsIds = mediaItems.map((item) => item.id).toList();
    final notPlayedshuffledQueue = shuffledQueue.sublist(currentShuffleIndex + 1);
    notPlayedshuffledQueue.addAll(mediaItemsIds);
    notPlayedshuffledQueue.shuffle();
    shuffledQueue.replaceRange(currentShuffleIndex, shuffledQueue.length, 
        notPlayedshuffledQueue);
  }
}
```

## 🚀 Complete Autoplay Flow

### Implementation Flow:

1. **User Action**: User taps "Start Radio" or plays a song
2. **API Call**: `getWatchPlaylist()` called with `radio: true`
3. **Queue Population**: Initial batch of similar songs loaded (25 songs)
4. **Playback**: Songs play normally through the queue
5. **Detection**: When reaching last song in queue, trigger continuation
6. **Continuation**: `_addRadioContinuation()` fetches 24 more similar songs
7. **Seamless Flow**: Process repeats indefinitely for continuous playback

### Flow Diagram:

```
User Plays Song
       ↓
Start Radio Mode (isRadioModeOn = true)
       ↓
Call getWatchPlaylist(radio: true)
       ↓
YouTube Music API (/next endpoint)
       ↓
Parse Response → Extract 25 Similar Songs
       ↓
Update Audio Queue
       ↓
Play Songs Sequentially
       ↓
Detect Last Song in Queue
       ↓
Call _addRadioContinuation()
       ↓
Fetch 24 More Similar Songs
       ↓
Add to Queue → Continue Playing
       ↓
Repeat Continuation Process
```

## 🎯 Key Parameters Sent to YouTube Music

### Core Request Parameters:

```dart
{
  'videoId': 'currentSongId',           // Base song for similarity
  'playlistId': 'RDAMVM{videoId}',      // Radio playlist format
  'params': 'wAEB',                     // Radio mode parameter
  'isAudioOnly': true,                  // Audio-only content
  'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',  // Mixing algorithm
  'enablePersistentPlaylistPanel': true // Enables continuation
}
```

### Parameter Explanations:

- **`wAEB`**: YouTube Music's internal parameter for radio mode
- **`RDAMVM{videoId}`**: Radio playlist ID format based on seed song
- **`AUTOMIX_SETTING_NORMAL`**: YouTube's recommendation algorithm setting
- **`enablePersistentPlaylistPanel`**: Allows continuous song loading

## 🔧 Smart Features

### Pre-loading Strategy:
- **Initial Load**: 25 songs to start radio
- **Continuation**: 24 additional songs when queue runs low
- **Trigger Point**: When current song is the last in queue

### Context Awareness:
- **Language**: Uses user's language preference (`hl` parameter)
- **Region**: Respects geographic content restrictions
- **Quality**: Maintains audio quality preferences
- **History**: Considers user's listening patterns

### Error Handling:
```dart
// Network error handling
try {
  final content = await _musicServices.getWatchPlaylist(...);
  radioContinuationParam = content['additionalParamsForNext'];
} catch (e) {
  // Fallback to local queue or retry logic
  printERROR("Radio continuation failed: $e");
}
```

### Memory Management:
- **Queue Size**: Maintains optimal queue length
- **Cleanup**: Removes old songs to prevent memory bloat
- **Caching**: Caches continuation tokens for efficiency

## 🎮 User Experience Features

### Seamless Transitions:
- **No Interruptions**: Songs flow continuously without gaps
- **Smart Mixing**: YouTube's algorithm ensures good variety
- **Context Preservation**: Maintains mood and genre consistency

### User Controls:
- **Skip Forward**: Moves to next suggested song
- **Skip Backward**: Returns to previous songs in radio
- **Stop Radio**: Exits radio mode, returns to normal queue
- **Shuffle**: Can be combined with radio for more variety

### Visual Feedback:
```dart
// UI indicators for radio mode
playinfrom.value = PlaylingFrom(
    type: PlaylingFromType.SELECTION,
    name: radio ? "randomRadio".tr : "randomSelection".tr);
```

## 🛠️ Implementation Tips for Your App

### 1. YouTube Music API Setup:
```dart
// Essential headers for API access
final headers = {
  'user-agent': 'Mozilla/5.0 (compatible; YTMusic/1.0)',
  'X-Goog-Visitor-Id': generateVisitorId(),
  'content-type': 'application/json',
  'origin': 'https://music.youtube.com',
};

// Generate visitor ID for session
Future<String?> generateVisitorId() async {
  final response = await dio.get('https://music.youtube.com');
  final regex = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)');
  final match = regex.firstMatch(response.data);
  if (match != null) {
    final ytcfg = json.decode(match.group(1));
    return ytcfg['VISITOR_DATA'];
  }
  return null;
}
```

### 2. Queue Management Best Practices:
- **Monitor Queue Size**: Keep 20-30 songs ahead
- **Trigger Threshold**: Load more when 3-5 songs remain
- **Batch Size**: 20-25 songs per API call for optimal performance
- **Memory Cleanup**: Remove played songs older than 10-15 items

### 3. Error Handling:
```dart
// Robust error handling for API failures
Future<void> handleRadioContinuation() async {
  int retryCount = 0;
  const maxRetries = 3;
  
  while (retryCount < maxRetries) {
    try {
      await _addRadioContinuation(radioInitiatorItem);
      break;
    } catch (e) {
      retryCount++;
      if (retryCount >= maxRetries) {
        // Fallback: disable radio mode or use cached songs
        isRadioModeOn = false;
        showErrorToUser("Radio mode temporarily unavailable");
      }
      await Future.delayed(Duration(seconds: retryCount * 2));
    }
  }
}
```

### 4. Performance Optimization:
- **Lazy Loading**: Only fetch URLs when songs are about to play
- **Caching**: Cache continuation tokens and song metadata
- **Background Processing**: Load songs in background threads
- **Network Efficiency**: Batch API requests when possible

### 5. User Preferences:
```dart
// Respect user settings for radio behavior
final radioSettings = {
  'explicitContent': userPrefs.allowExplicit,
  'preferredGenres': userPrefs.favoriteGenres,
  'skipThreshold': userPrefs.autoSkipAfterSeconds,
  'maxQueueSize': userPrefs.maxRadioQueueSize,
};
```

## 🔍 Debugging and Monitoring

### Logging Strategy:
```dart
// Comprehensive logging for radio functionality
void logRadioEvent(String event, Map<String, dynamic> data) {
  printINFO("RADIO_$event: ${json.encode(data)}");
}

// Usage examples:
logRadioEvent("STARTED", {"songId": mediaItem.id, "mode": "radio"});
logRadioEvent("CONTINUATION", {"songsAdded": tracks.length, "queueSize": currentQueue.length});
logRadioEvent("ERROR", {"error": e.toString(), "context": "continuation"});
```

### Performance Metrics:
- **API Response Time**: Monitor YouTube Music API latency
- **Queue Health**: Track queue size and refill frequency
- **User Engagement**: Measure skip rates and listening duration
- **Error Rates**: Monitor API failures and fallback usage

## 📱 Platform Considerations

### Android:
- **Background Playback**: Use `audio_service` for background operation
- **Media Controls**: Implement media session for lock screen controls
- **Battery Optimization**: Handle doze mode and battery optimization

### iOS:
- **Background Audio**: Configure audio session for background playback
- **Control Center**: Integrate with iOS media controls
- **App Store Guidelines**: Ensure compliance with streaming policies

### Desktop:
- **System Tray**: Provide system tray controls for radio
- **Keyboard Shortcuts**: Global hotkeys for radio control
- **Window Management**: Handle minimized state gracefully

## 🚀 Advanced Features

### Machine Learning Enhancement:
```dart
// Potential ML integration for better recommendations
class SmartRadioEngine {
  // Analyze user behavior patterns
  Future<List<String>> getPersonalizedSeeds(String currentSong) async {
    final userHistory = await getUserListeningHistory();
    final similarUsers = await findSimilarUsers(userHistory);
    return generateSmartSeeds(currentSong, userHistory, similarUsers);
  }
  
  // Improve recommendations over time
  void recordUserFeedback(String songId, UserAction action) {
    // Track skips, likes, replays for ML training
  }
}
```

### Cross-Platform Sync:
```dart
// Sync radio state across devices
class RadioStateSync {
  Future<void> syncRadioState() async {
    final state = {
      'isRadioOn': isRadioModeOn,
      'currentSeed': radioInitiatorItem,
      'queuePosition': currentSongIndex.value,
      'continuationToken': radioContinuationParam,
    };
    await cloudSync.saveRadioState(state);
  }
}
```

## 📚 References

### YouTube Music API Documentation:
- **Internal API**: Based on reverse engineering of YouTube Music web client
- **Endpoints**: `/youtubei/v1/next`, `/youtubei/v1/browse`, `/youtubei/v1/search`
- **Authentication**: Visitor ID based authentication system

### Related Libraries:
- **`just_audio`**: Audio playback engine
- **`audio_service`**: Background audio service
- **`get`**: State management and dependency injection
- **`dio`**: HTTP client for API requests

### Community Resources:
- **ytmusicapi**: Python library for YouTube Music API
- **YouTube Music Protocol**: Community documentation of API endpoints
- **Audio Service Examples**: Flutter audio service implementations

---

## 📄 License

This analysis is based on the open-source Harmony Music project. Implementation details are provided for educational purposes and should comply with YouTube's Terms of Service when used in production applications.

---

**Last Updated**: October 2024  
**Version**: 1.0  
**Author**: Based on Harmony Music v1.12.0 codebase analysis
