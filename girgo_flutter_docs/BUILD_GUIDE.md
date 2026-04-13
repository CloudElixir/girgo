# Girgo App - Build & Export Guide

## Quick Build Commands

### 🌐 Web (Recommended for quick deployment)
```bash
flutter build web --release
```
Output: `build/web/` folder (deploy to any web server)

### 📱 Android APK (for direct installation)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### 📦 Android App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### 🍎 iOS (requires macOS and Xcode)
```bash
flutter build ios --release
```
Then open `ios/Runner.xcworkspace` in Xcode to archive and export.

### 🪟 Windows
```bash
flutter build windows --release
```
Output: `build/windows/x64/runner/Release/`

### 🐧 Linux
```bash
flutter build linux --release
```
Output: `build/linux/x64/release/bundle/`

### 🍎 macOS
```bash
flutter build macos --release
```
Output: `build/macos/Build/Products/Release/`

## Deployment Options

### Web Deployment
1. **Firebase Hosting** (Recommended):
   ```bash
   firebase deploy --only hosting
   ```

2. **Netlify/Vercel**:
   - Upload the `build/web/` folder
   - Or connect your Git repo

3. **Any Web Server**:
   - Copy `build/web/` contents to your server
   - Configure server to serve `index.html` for all routes

### Android Deployment
- **APK**: Share the `.apk` file directly
- **Play Store**: Upload the `.aab` file to Google Play Console

### iOS Deployment
- Use Xcode to archive and upload to App Store Connect

## Pre-Build Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Configure Firebase for production
- [ ] Set up signing keys (Android/iOS)
- [ ] Test on target devices
- [ ] Update app icons and splash screens
- [ ] Configure environment variables if needed

## Notes

- Web builds are optimized and minified automatically
- Android APK can be installed directly on devices
- iOS requires Apple Developer account for distribution
- All builds are production-ready with optimizations enabled

