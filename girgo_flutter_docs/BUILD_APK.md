# Build Android APK for Girgo App

## Quick Build Command

Run this command in your terminal from the `girgo_flutter` directory:

```bash
cd /home/godfather/Desktop/Girgo/girgo_flutter
flutter build apk --release
```

## Output Location

After building, your APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

## Build Options

### Standard APK (for most devices):
```bash
flutter build apk --release
```

### Split APKs by ABI (smaller file sizes):
```bash
flutter build apk --split-per-abi --release
```
This creates separate APKs for:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

### Debug APK (for testing):
```bash
flutter build apk --debug
```

## Installation

1. Transfer the APK to your Android device
2. Enable "Install from Unknown Sources" in Android settings
3. Tap the APK file to install

## Troubleshooting

If you get build errors:
1. Make sure you have Android SDK installed
2. Run `flutter doctor` to check setup
3. Clean build: `flutter clean && flutter pub get`
4. Try building again

## Notes

- The release APK is signed with debug keys (for testing)
- For Play Store, use `flutter build appbundle --release` instead
- APK size will be around 20-50MB depending on assets

