import 'package:get/get.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/search/search_screen.dart';
import '../../presentation/screens/player/player_screen.dart';
import '../../presentation/screens/album/album_screen.dart';
import '../../presentation/screens/artist/artist_screen.dart';
import '../../presentation/screens/playlist/playlist_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String search = '/search';
  static const String player = '/player';
  static const String album = '/album';
  static const String artist = '/artist';
  static const String playlist = '/playlist';

  static final routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: search,
      page: () => const SearchScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: player,
      page: () => const PlayerScreen(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: album,
      page: () => const AlbumScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: artist,
      page: () => const ArtistScreen(),
      transition: Transition.cupertino,
    ),
    GetPage(
      name: playlist,
      page: () => const PlaylistScreen(),
      transition: Transition.cupertino,
    ),
  ];
}
