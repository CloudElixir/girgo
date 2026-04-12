# Girgo Flutter App

A dairy and grocery delivery mobile app built with Flutter.

## Features

- 🔐 Google Sign-In Authentication
- 🛒 Product Catalog with Categories
- 🛍️ Shopping Cart & Checkout
- 💳 Payment Integration (Razorpay)
- 📦 Order Tracking
- 🔄 Subscription Management
- 🔔 Push Notifications
- 👤 User Profile & Settings

## Setup

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Configure Firebase:
   - Update `lib/services/firebase_service.dart` with your Firebase config
   - Add `google-services.json` for Android
   - Add `GoogleService-Info.plist` for iOS

3. Configure Payment:
   - Update `lib/services/payment_service.dart` with your Razorpay Key ID

4. Configure API:
   - Update `lib/services/api_service.dart` with your backend API URL

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── constants/
│   ├── theme.dart          # Colors, fonts, spacing
│   └── products.dart       # Product catalog
├── models/
│   └── product.dart        # Product model
├── providers/
│   ├── auth_provider.dart  # Authentication state
│   └── cart_provider.dart  # Cart state
├── screens/
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── product_detail_screen.dart
│   ├── cart_screen.dart
│   ├── checkout_screen.dart
│   ├── orders_screen.dart
│   ├── order_detail_screen.dart
│   ├── subscriptions_screen.dart
│   └── profile_screen.dart
├── services/
│   ├── firebase_service.dart
│   ├── auth_service.dart
│   ├── cart_service.dart
│   ├── api_service.dart
│   └── payment_service.dart
└── main.dart
```

## Products Included

- Milk (1L, ½L, Trial Pack)
- Ghee (250ml to 10L)
- Gomutra (1L)
- Pachagavya (1L)
- Cowdung Diyas
- Dhoopa (1 piece, 15 pieces combo)
- Paneer (250g, 500g)

## Building for Production

### Android:
```bash
flutter build apk --release
```

### iOS:
```bash
flutter build ios --release
```

## Notes

- Update all placeholder values with your actual credentials
- Add product images to `assets/images/` folder
- Configure push notifications for production
- Set up your backend API endpoints
- Test payment integration in sandbox mode first
