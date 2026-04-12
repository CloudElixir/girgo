# Setting Up Google Sign-In for Web

The admin panel requires a Google OAuth Client ID to work on web. Follow these steps:

## Steps to Get OAuth Client ID:

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Select your project: `girgo-prod`

2. **Navigate to Project Settings:**
   - Click the gear icon ⚙️ next to "Project Overview"
   - Select "Project settings"

3. **Find Your Web App:**
   - Scroll down to "Your apps" section
   - Find your web app (the one with app ID: `1:220181038206:web:f5586bf78ee227ee4a042f`)

4. **Get OAuth Client ID:**
   - In the web app section, you'll see "OAuth 2.0 Client IDs"
   - Copy the Client ID (it looks like: `220181038206-xxxxxxxxxxxxx.apps.googleusercontent.com`)

5. **Update the HTML file:**
   - Open `web/index.html`
   - Find the line: `<meta name="google-signin-client_id" content="220181038206-xxxxx.apps.googleusercontent.com">`
   - Replace `220181038206-xxxxx.apps.googleusercontent.com` with your actual Client ID

## Alternative: If you can't find it in Firebase Console

1. Go to Google Cloud Console: https://console.cloud.google.com/
2. Select project: `girgo-prod`
3. Navigate to: APIs & Services > Credentials
4. Look for "OAuth 2.0 Client IDs" under "Web client"
5. Copy the Client ID

## After updating:

1. Restart your Flutter app:
   ```bash
   flutter run -d chrome
   ```

2. The Google Sign-In should now work!

