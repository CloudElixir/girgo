# Fix Redirect URI Mismatch Error (Error 400)

## Problem
You're seeing `Error 400: redirect_uri_mismatch` when trying to sign in. This happens because Firebase Auth uses specific redirect URIs that must be authorized in your OAuth client.

## Solution

### Step 1: Go to Google Cloud Console
1. Open [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **girgo-prod**
3. Navigate to **APIs & Services** > **Credentials**
4. Find your OAuth 2.0 Client ID: `220181038206-01h7sld5sb34d47ce5nc00ud84rnemmq.apps.googleusercontent.com`
5. Click **Edit** (pencil icon)

### Step 2: Add Authorized Redirect URIs
Add these **exact** redirect URIs to the "Authorized redirect URIs" section:

**For Localhost Development:**
```
http://localhost:PORT/__/auth/handler
http://127.0.0.1:PORT/__/auth/handler
```

**⚠️ IMPORTANT:** Replace `PORT` with your **current** Flutter dev server port. 
- Check the port in your browser's address bar (e.g., `localhost:45165`)
- The port changes each time you restart Flutter, so you may need to add multiple ports
- Common ports: `32951`, `40095`, `44027`, `45165`, etc.

**For Firebase Hosting (Production):**
```
https://girgo-prod.firebaseapp.com/__/auth/handler
https://girgo-prod.web.app/__/auth/handler
```

**Important:** The `__/auth/handler` path is required by Firebase Auth for popup-based sign-in.

### Step 3: Add Authorized JavaScript Origins
Make sure these are in "Authorized JavaScript origins":

**For Localhost:**
```
http://localhost
http://localhost:PORT
http://127.0.0.1:PORT
```

**For Production:**
```
https://girgo-prod.firebaseapp.com
https://girgo-prod.web.app
```

### Step 4: Save and Wait
1. Click **Save**
2. Wait 5-10 minutes for changes to propagate
3. Try signing in again

## Quick Fix for Development
If you're testing locally and the port changes frequently, you can add:
- `http://localhost:*` (wildcard - if supported)
- Or add multiple ports: `http://localhost:32951`, `http://localhost:45511`, etc.

## Verify Firebase Console
Also check Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select **girgo-prod** project
3. Go to **Authentication** > **Settings** > **Authorized domains**
4. Make sure `localhost` is listed (it should be by default)

## Still Having Issues?
If the error persists:
1. Clear browser cache and cookies
2. Try in an incognito/private window
3. Check the browser console for the exact redirect URI being used
4. Make sure the OAuth client ID matches in both Firebase Console and your code

