# Quick Fix for ID Token Issue

The ID token is still null. Follow these steps **in order**:

## Step 1: Configure OAuth Consent Screen (CRITICAL)

1. Go to: https://console.cloud.google.com/apis/credentials/consent?project=girgo-prod

2. **If you see "OAuth consent screen" not configured:**
   - Click "CONFIGURE CONSENT SCREEN"
   - Select "External" (unless you're using Google Workspace)
   - Click "CREATE"

3. **Fill in the required fields:**
   - App name: `Girgo Admin`
   - User support email: Your email
   - Developer contact: Your email
   - Click "SAVE AND CONTINUE"

4. **Scopes (IMPORTANT):**
   - Click "ADD OR REMOVE SCOPES"
   - Make sure these are added:
     - `email` (from Google)
     - `profile` (from Google)
     - `openid` (from Google)
   - Click "UPDATE"
   - Click "SAVE AND CONTINUE"

5. **Test users (if in Testing mode):**
   - Add your email: `webgirgoindia@gmail.com`
   - Click "ADD USERS"
   - Click "SAVE AND CONTINUE"

6. **Summary:**
   - Review and click "BACK TO DASHBOARD"

## Step 2: Verify OAuth Client

1. Go to: https://console.cloud.google.com/apis/credentials?project=girgo-prod

2. Click on "girgo_admin_web" (the one with `chfg...`)

3. **Authorized JavaScript origins** - MUST include:
   ```
   http://localhost
   http://localhost:39993
   http://127.0.0.1
   ```

4. **Authorized redirect URIs** - MUST include:
   ```
   http://localhost
   http://localhost:39993
   http://127.0.0.1
   ```

5. Click "SAVE"

## Step 3: Verify Firebase Console

1. Go to: https://console.firebase.google.com/project/girgo-prod/authentication/providers

2. Click on "Google"

3. **Web SDK configuration:**
   - Web client ID: `220181038206-chfg2f5piqf13drecuel5t6gg7pun6gb.apps.googleusercontent.com`
   - Web client secret: Leave blank

4. Click "SAVE"

## Step 4: Wait and Test

1. **Wait 3-5 minutes** for all changes to propagate

2. **Clear browser cache:**
   - Press `Ctrl+Shift+Delete` in Chrome
   - Clear cookies and cached images
   - Or use Incognito mode

3. **Restart Flutter app:**
   ```bash
   flutter run -d chrome
   ```

4. **Try signing in again**

## If Still Not Working:

The OAuth consent screen configuration is the most critical step. Make sure:
- ✅ OAuth consent screen is configured (not just enabled)
- ✅ Scopes include: `email`, `profile`, `openid`
- ✅ Your email is added as a test user (if in Testing mode)
- ✅ The app is published or you're using a test user account

