# 🔧 Build Instructions

## Fix the Android v1 Embedding Error

Run these commands in order:

### 1. Clean the project
```powershell
cd C:\Users\Abhiram\Desktop\harmony\Harmony-Music
flutter clean
```

### 2. Get dependencies
```powershell
flutter pub get
```

### 3. Clean Android build
```powershell
cd android
./gradlew clean
cd ..
```

### 4. Check if everything is ready
```powershell
flutter doctor
```

### 5. Run the app
```powershell
# Make sure your device/emulator is connected
flutter devices

# Run the app
flutter run
```

## Alternative: Build APK directly

### Debug APK (for testing)
```powershell
flutter build apk --debug
```

### Release APK (optimized)
```powershell
flutter build apk --release
```

### Split APKs (smaller file size)
```powershell
flutter build apk --split-per-abi --release
```

APKs will be in: `build\app\outputs\flutter-apk\`

## Troubleshooting

### If Gradle fails:
```powershell
cd android
./gradlew clean
./gradlew build --info
cd ..
```

### If plugins are missing:
```powershell
flutter pub cache repair
flutter pub get
```

### If still having issues:
```powershell
# Delete build folders
Remove-Item -Path build -Recurse -Force
Remove-Item -Path android\.gradle -Recurse -Force
Remove-Item -Path android\app\build -Recurse -Force

# Rebuild
flutter clean
flutter pub get
flutter run
```

## First Time Setup

1. **Install Flutter SDK**: https://flutter.dev/docs/get-started/install/windows
2. **Install Android Studio**: https://developer.android.com/studio
3. **Setup Android SDK** (API 34)
4. **Enable USB Debugging** on your phone or create an AVD emulator
5. **Run flutter doctor** and fix any issues

## Running on Physical Device

1. Enable **Developer Options** on your phone
2. Enable **USB Debugging**
3. Connect via USB
4. Run: `flutter devices` to verify connection
5. Run: `flutter run`

## Running on Emulator

1. Open Android Studio
2. Go to **Tools** → **AVD Manager**
3. Create a new Virtual Device (Pixel 6 recommended)
4. Start the emulator
5. Run: `flutter run`

## Hot Reload Tips

- Press `r` to hot reload (keeps app state)
- Press `R` to hot restart (resets app state)
- Press `q` to quit
- Press `h` for help

## Build Variants

- **Debug**: Fast build, includes debugging info, larger size
- **Profile**: Performance analysis, optimized but debuggable
- **Release**: Production build, fully optimized, smallest size

---

**Note**: The first build may take 5-10 minutes. Subsequent builds are much faster!
