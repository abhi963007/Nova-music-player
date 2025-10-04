import 'package:get/get.dart';
import '../../data/services/youtube_music_service.dart';
import '../../data/services/stream_service.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/repositories/music_repository.dart';
import '../../presentation/controllers/home_controller.dart';
import '../../presentation/controllers/player_controller.dart';
import '../../presentation/controllers/search_controller.dart';

Future<void> setupServiceLocator() async {
  // Services
  Get.put(YoutubeMusicService(), permanent: true);
  Get.put(StreamService(), permanent: true);
  Get.put(AudioPlayerService(), permanent: true);

  // Repositories
  Get.put(MusicRepository(), permanent: true);

  // Controllers (using permanent: false to allow proper disposal)
  Get.put(HomeController(), permanent: false);
  Get.put(PlayerController(), permanent: false);
  Get.put(SearchController(), permanent: false);
}
