# App Store Publishing Guide - Girgo App

## ✅ Razorpay Compatibility

### **YES, Razorpay works on BOTH Android AND iOS!**

The `razorpay_flutter` package you're using (version 1.3.2) supports:
- ✅ **Android** - Full support
- ✅ **iOS** - Full support
- ✅ **Web** - Full support

**Current Status:**
- Your app already has Razorpay integrated
- Package: `razorpay_flutter: ^1.3.2`
- Location: `lib/services/payment_service.dart`

### What You Need to Do:

1. **Get Razorpay Account:**
   - Sign up at https://razorpay.com
   - Get your **Key ID** and **Key Secret**
   - Enable both Android and iOS in Razorpay Dashboard

2. **Update Payment Service:**
   - Replace `YOUR_RAZORPAY_KEY_ID` in `lib/services/payment_service.dart`
   - Use your actual Razorpay Key ID

3. **Test on Both Platforms:**
   - Test payments on Android device
   - Test payments on iOS device
   - Both will work with the same integration!

---

## 📱 Publishing to Google Play Store (Android)

### Prerequisites:
1. Google Play Developer Account ($25 one-time fee)
2. App signing key (for production)
3. App Bundle (AAB file) - NOT APK

### Steps:

#### 1. **Create App Signing Key**
```bash
cd android
keytool -genkey -v -keystore ~/girgo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias girgo
```

#### 2. **Configure Signing in build.gradle.kts**
Update `android/app/build.gradle.kts`:
```kotlin
android {
    ...
    signingConfigs {
        release {
            keyAlias = 'girgo'
            keyPassword = 'YOUR_KEY_PASSWORD'
            storeFile = file('~/girgo-release-key.jks')
            storePassword = 'YOUR_STORE_PASSWORD'
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

#### 3. **Build App Bundle**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

#### 4. **Upload to Play Console**
1. Go to https://play.google.com/console
2. Create new app
3. Fill app details:
   - App name: "Girgo"
   - Default language: English
   - App or game: App
   - Free or paid: Your choice
4. Upload AAB file
5. Fill store listing:
   - App icon (512x512)
   - Feature graphic (1024x500)
   - Screenshots (at least 2)
   - Short description (80 chars)
   - Full description (4000 chars)
6. Set content rating
7. Set pricing & distribution
8. Submit for review

### Required Assets:
- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Screenshots: At least 2 (phone, tablet if applicable)
- Privacy policy URL (required)

---

## 🍎 Publishing to Apple App Store (iOS)

### Prerequisites:
1. Apple Developer Account ($99/year)
2. macOS computer with Xcode
3. iOS device for testing (recommended)

### Steps:

#### 1. **Configure App in Xcode**
```bash
# Open iOS project
open ios/Runner.xcworkspace
```

In Xcode:
1. Select Runner project
2. Go to "Signing & Capabilities"
3. Select your Team (Apple Developer account)
4. Enable "Automatically manage signing"
5. Update Bundle Identifier (e.g., `com.yourcompany.girgo`)

#### 2. **Update App Info**
- Update `ios/Runner/Info.plist`:
  - App name
  - Bundle identifier
  - Version number
  - Build number

#### 3. **Configure Razorpay for iOS**
Add to `ios/Runner/Info.plist`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>razorpay</string>
</array>
```

#### 4. **Build for iOS**
```bash
flutter build ios --release
```

#### 5. **Archive in Xcode**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as target
3. Product → Archive
4. Wait for archive to complete
5. Click "Distribute App"
6. Choose "App Store Connect"
7. Follow wizard to upload

#### 6. **Submit in App Store Connect**
1. Go to https://appstoreconnect.apple.com
2. Create new app:
   - Name: "Girgo"
   - Primary language: English
   - Bundle ID: (from Xcode)
   - SKU: Unique identifier
3. Fill app information:
   - App icon (1024x1024)
   - Screenshots (various sizes)
   - Description
   - Keywords
   - Support URL
   - Privacy policy URL (required)
4. Set pricing
5. Submit for review

### Required Assets:
- App icon: 1024x1024 PNG (no transparency)
- Screenshots:
  - iPhone 6.7": 1290x2796
  - iPhone 6.5": 1242x2688
  - iPhone 5.5": 1242x2208
  - iPad Pro 12.9": 2048x2732
- Privacy policy URL (required)

---

## 🔐 Important Security Notes

### Razorpay Configuration:

1. **Never commit keys to Git:**
   - Use environment variables
   - Or use `flutter_dotenv` package
   - Keep keys in secure storage

2. **Use different keys for:**
   - Development/Testing
   - Production

3. **Backend Integration:**
   - Always verify payments on your backend
   - Never trust client-side payment verification
   - Use Razorpay webhooks for payment confirmation

---

## 📋 Pre-Publishing Checklist

### Both Platforms:
- [ ] Replace Razorpay test key with production key
- [ ] Test payment flow on real devices
- [ ] Update app version in `pubspec.yaml`
- [ ] Test all features (login, cart, checkout, payments)
- [ ] Add privacy policy URL
- [ ] Prepare app screenshots
- [ ] Write app description
- [ ] Test on multiple device sizes
- [ ] Remove debug code
- [ ] Test offline functionality
- [ ] Verify Firebase configuration
- [ ] Test push notifications

### Android Specific:
- [ ] Create signing key
- [ ] Build App Bundle (AAB)
- [ ] Test on multiple Android versions
- [ ] Verify Google Sign-In works
- [ ] Check app size (should be < 100MB)

### iOS Specific:
- [ ] Configure signing in Xcode
- [ ] Test on real iOS device
- [ ] Verify Apple Sign-In (if using)
- [ ] Check app size
- [ ] Test on different iOS versions
- [ ] Verify App Store guidelines compliance

---

## 🚀 Quick Commands

### Android:
```bash
# Build App Bundle for Play Store
flutter build appbundle --release

# Build APK for direct distribution
flutter build apk --release
```

### iOS:
```bash
# Build iOS app
flutter build ios --release

# Then open in Xcode and Archive
open ios/Runner.xcworkspace
```

---

## 💰 Costs

- **Google Play Store:** $25 one-time registration fee
- **Apple App Store:** $99/year subscription
- **Razorpay:** Transaction fees (check their pricing)

---

## 📞 Support

- Razorpay Docs: https://razorpay.com/docs/payments/mobile/flutter/
- Flutter Publishing: https://docs.flutter.dev/deployment
- Play Console: https://support.google.com/googleplay/android-developer
- App Store Connect: https://developer.apple.com/support/app-store-connect/

---

## ✅ Summary

**Razorpay works on BOTH platforms!** Your current integration will work on:
- ✅ Android (Google Play Store)
- ✅ iOS (Apple App Store)
- ✅ Web (if you deploy web version)

Just update the Razorpay Key ID in `payment_service.dart` and you're good to go!

