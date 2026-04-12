# Girgo Flutter App - Setup Guide

## Quick Start

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure Firebase:**
   - The Firebase config is already set in `lib/services/firebase_service.dart`
   - For Android: Add `google-services.json` to `android/app/`
   - For iOS: Add `GoogleService-Info.plist` to `ios/Runner/`

3. **Configure Google Sign-In:**
   - Update `lib/services/auth_service.dart` if needed
   - Configure OAuth credentials in Firebase Console

4. **Configure Payment:**
   - Update `lib/services/payment_service.dart` with your Razorpay Key ID

5. **Configure API:**
   - Update `lib/services/api_service.dart` with your backend API URL

6. **Run the app:**
   ```bash
   flutter run
   ```

## Project Structure

- **lib/constants/** - Theme colors, product catalog
- **lib/models/** - Data models
- **lib/providers/** - State management (Provider pattern)
- **lib/screens/** - All app screens
- **lib/services/** - Business logic and API calls

## Features Implemented

✅ Google Sign-In Authentication  
✅ Product Catalog with Search & Filters  
✅ Shopping Cart Management  
✅ Checkout with Address Form  
✅ Razorpay Payment Integration  
✅ Order Tracking  
✅ Subscription Management  
✅ User Profile & Settings  
✅ Push Notifications Setup  

## Building for Production

### Android APK:
```bash
flutter build apk --release
```

### Android App Bundle:
```bash
flutter build appbundle --release
```

### iOS:
```bash
flutter build ios --release
```

## Notes

- All product data is in `lib/constants/products.dart`
- State management uses Provider pattern
- Firebase is configured for authentication and messaging
- Payment integration uses Razorpay Flutter SDK
- The app follows Material Design 3

## Next Steps

1. Add product images to `assets/images/`
2. Set up your backend API
3. Configure push notifications
4. Test on physical devices
5. Build for production

