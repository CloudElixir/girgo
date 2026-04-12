# Fix OAuth "invalid_client" Error

The error "OAuth client was not found" means the OAuth client needs to be configured with authorized origins.

## Steps to Fix:

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/apis/credentials?project=girgo-prod

2. **Find Your OAuth Client:**
   - Look for the Client ID: `331078095373-sI5fh9d9igI3fg9ggtpsql5o5efpps1`
   - Click on it to edit

3. **Add Authorized JavaScript Origins:**
   - Click "ADD URI"
   - Add these URLs:
     - `http://localhost` (for development)
     - `http://localhost:8080`
     - `http://localhost:40831` (or whatever port Flutter uses)
     - `http://127.0.0.1`
     - `http://127.0.0.1:8080`
   - For production, add your actual domain:
     - `https://your-admin-domain.com`

4. **Add Authorized Redirect URIs:**
   - Click "ADD URI" under "Authorized redirect URIs"
   - Add:
     - `http://localhost`
     - `http://localhost:8080`
     - `http://localhost:40831`
     - `http://127.0.0.1`
     - For production:
     - `https://your-admin-domain.com`

5. **Save Changes:**
   - Click "SAVE" at the bottom

6. **Wait a few minutes:**
   - Changes may take 1-2 minutes to propagate

7. **Restart your Flutter app:**
   ```bash
   flutter run -d chrome
   ```

## Alternative: Use Firebase Console

1. Go to: https://console.firebase.google.com/project/girgo-prod/settings/general
2. Scroll to "Your apps" → Web app
3. Click on the OAuth client ID link
4. This will take you to Google Cloud Console where you can configure it

## Note:
- The Client ID is already set in the code
- You just need to authorize `localhost` as an origin
- This is a one-time setup

