# Girgo Admin Panel

Separate admin panel for managing the Girgo app. This is a web-based Flutter application that can be hosted independently.

## Features

- 🔐 **Admin Authentication** - Google Sign-In with admin verification
- 📦 **Products Management** - View, enable/disable, and delete products
- 📋 **Orders Management** - View and update order statuses
- 🔄 **Subscriptions Management** - Manage user subscriptions (Active, Pause, Cancel)
- 👥 **Users Management** - View users and grant/revoke admin access
- 🎯 **Home Offers Management** - Manage promotional offers on the home screen
- 📊 **Dashboard Overview** - Real-time statistics

## Setup

1. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

2. **Firebase Configuration:**
   - The app uses the same Firebase project (`girgo-prod`) as the main app
   - Firebase options are already configured in `lib/firebase_options.dart`

3. **Run Locally:**
   ```bash
   flutter run -d chrome
   ```

## Building for Web Hosting

### Build for Production:
```bash
flutter build web --release
```

The built files will be in `build/web/` directory.

### Hosting Options:

1. **Firebase Hosting** (Recommended):
   ```bash
   # Install Firebase CLI if not already installed
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Initialize Firebase Hosting (if not already done)
   firebase init hosting
   
   # Build the app
   flutter build web --release
   
   # Deploy
   firebase deploy --only hosting
   ```

2. **Other Hosting Services:**
   - Upload the contents of `build/web/` to any static hosting service:
     - Netlify
     - Vercel
     - GitHub Pages
     - AWS S3 + CloudFront
     - Any web server

## Admin Access

- Only users with `isAdmin: true` or `role: 'admin'` in Firestore `users` collection can access the admin panel
- To grant admin access, update the user document in Firestore:
  ```javascript
  {
    "isAdmin": true,
    "role": "admin"
  }
  ```

## Project Structure

```
lib/
├── main.dart                    # App entry point with auth wrapper
├── firebase_options.dart        # Firebase configuration
├── services/
│   ├── auth_service.dart       # Authentication service
│   └── firestore_service.dart  # Firestore operations
└── screens/
    ├── login_screen.dart        # Login page
    ├── admin_dashboard_screen.dart  # Main dashboard
    └── views/
        ├── products_admin_view.dart
        ├── orders_admin_view.dart
        ├── subscriptions_admin_view.dart
        ├── users_admin_view.dart
        └── home_offers_admin_view.dart
```

## Notes

- All changes made in the admin panel are reflected immediately in the user app through Firestore
- The admin panel is completely separate from the user app (`girgo_flutter`)
- You can submit the user app to clients without any admin code
- Host the admin panel separately for your management needs
