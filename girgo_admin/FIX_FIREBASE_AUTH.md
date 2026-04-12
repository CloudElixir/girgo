# Fix Firebase Auth "configuration-not-found" Error

The error `[firebase_auth/configuration-not-found]` means Firebase Auth isn't properly configured for web.

## Steps to Fix:

1. **Enable Firebase Authentication:**
   - Go to: https://console.firebase.google.com/project/girgo-prod/authentication
   - Make sure "Authentication" is enabled
   - If not, click "Get started" to enable it

2. **Enable Google Sign-In Provider:**
   - In the Authentication page, go to "Sign-in method" tab
   - Find "Google" in the list
   - Click on it
   - Enable it if it's disabled
   - Make sure the OAuth client IDs are configured:
     - Web client ID: `220181038206-chfg2f5piqf13drecuel5t6gg7pun6gb.apps.googleusercontent.com`
   - Click "Save"

3. **Verify Authorized Domains:**
   - Still in Authentication > Settings
   - Scroll to "Authorized domains"
   - Make sure `localhost` is listed (it should be by default)
   - If not, click "Add domain" and add `localhost`

4. **Check Firebase Console Web App:**
   - Go to: https://console.firebase.google.com/project/girgo-prod/settings/general
   - Find your web app (app ID: `1:220181038206:web:f5586bf78ee227ee4a042f`)
   - Make sure it's properly configured

5. **Restart Your App:**
   ```bash
   flutter run -d chrome
   ```

## If Still Not Working:

Try clearing Flutter web cache:
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

The configuration should work after enabling Firebase Auth and Google Sign-In provider in Firebase Console.

