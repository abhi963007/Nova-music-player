# 🎵 Nova Music Player

A beautiful music streaming app powered by YouTube Music API with Material Design 3.

[![GitHub](https://img.shields.io/badge/GitHub-Nova--Music--Player-blue?logo=github)](https://github.com/abhi963007/Nova-music-player)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ Features

- 🎵 **Stream Music** - Access YouTube Music's entire catalog without login
- 🔍 **Smart Search** - Search for songs, albums, artists, and playlists
- 🎧 **Advanced Player** - Full-featured audio player with queue management
- 📻 **Radio Mode** - Discover new music based on your current song
- 🎭 **Dark/Light Theme** - Automatic theme switching based on system preferences
- ⚡ **Fast & Responsive** - Smooth animations and optimized performance

## 🏗️ Architecture

This app uses the same architecture documented in `HOW_YT_MUSIC_WORKS_WITHOUT_LOGIN.md`:

- **YouTube Music API** - Mimics web client to access public endpoints
- **Stream Extraction** - Uses youtube-explode-dart for audio URL extraction
- **Audio Playback** - just_audio for high-quality audio streaming
- **State Management** - GetX for reactive state management
- **Clean Architecture** - Separation of concerns with data, domain, and presentation layers

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code
- Android SDK (API 24+)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/abhi963007/Nova-music-player.git
cd Nova-music-player
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs per ABI (smaller size)
flutter build apk --split-per-abi
```

The APK will be generated at: `build/app/outputs/flutter-apk/`

## 📁 Project Structure

```
lib/
├── core/
│   ├── routes/          # Navigation routes
│   ├── services/        # Service locator
│   └── theme/           # Material Design 3 theme
├── data/
│   ├── models/          # Data models
│   ├── repositories/    # Data repositories
│   └── services/        # API & audio services
└── presentation/
    ├── controllers/     # GetX controllers
    ├── screens/         # UI screens
    └── widgets/         # Reusable widgets
```

## 🎨 Material Design 3

The app implements Material Design 3 (Material You) with:

- Dynamic color schemes (light/dark)
- Elevated cards with rounded corners
- Modern navigation bar
- Smooth transitions and animations
- Adaptive layouts for different screen sizes

## 🔧 Technologies Used

- **Flutter** - UI framework
- **GetX** - State management & navigation
- **Dio** - HTTP client for API requests
- **youtube_explode_dart** - Stream URL extraction
- **just_audio** - Audio playback
- **Hive** - Local storage
- **Material Design 3** - UI/UX design system

## ⚠️ Legal Notice

This app is for educational and personal use only. It uses public YouTube Music API endpoints and does not require authentication. However:

- ✅ Uses official, public APIs
- ✅ No authentication bypass or hacking
- ⚠️ May violate YouTube's Terms of Service
- ❌ Not for commercial distribution

**Disclaimer**: This project is not sponsored or affiliated with YouTube. All content belongs to respective copyright owners.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- YouTube Music for the API structure
- Material Design team for design guidelines
- Flutter community for amazing packages
- youtube-explode-dart for stream extraction

---

**Made with ❤️ using Flutter**
