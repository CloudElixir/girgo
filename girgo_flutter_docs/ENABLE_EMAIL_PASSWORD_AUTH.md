# Enable Email/Password Authentication in Firebase

## Error Message
If you see this error:
```
[firebase_auth/operation-not-allowed] The given sign-in provider is disabled for this Firebase project.
```

This means **Email/Password authentication is not enabled** in your Firebase Console.

## Steps to Enable Email/Password Authentication

### 1. Go to Firebase Console
- Open [Firebase Console](https://console.firebase.google.com/)
- Select your project (Girgo)

### 2. Navigate to Authentication
- In the left sidebar, click on **"Authentication"** (or **"Build" > "Authentication"**)
- If you haven't set up Authentication yet, click **"Get started"**

### 3. Enable Email/Password Sign-in Method
- Click on the **"Sign-in method"** tab (or it may be at the top)
- You'll see a list of sign-in providers
- Find **"Email/Password"** in the list
- Click on it

### 4. Enable the Provider
- Toggle the **"Enable"** switch to **ON**
- Optionally, you can also enable **"Email link (passwordless sign-in)"** if you want passwordless authentication
- Click **"Save"**

### 5. Verify
- You should now see **"Email/Password"** with a green checkmark indicating it's enabled
- The status should show as **"Enabled"**

## Additional Configuration (Optional)

### Authorized Domains
- Make sure your localhost domain is authorized:
  - Go to **Authentication** > **Settings** > **Authorized domains**
  - `localhost` should already be there by default
  - For production, add your actual domain

### Password Requirements
- Firebase has default password requirements (minimum 6 characters)
- You can customize this in **Authentication** > **Settings** > **Password policy**

## Testing
After enabling Email/Password authentication:
1. Refresh your Flutter web app
2. Try signing up with email and password again
3. The error should be gone and users should be created successfully

## Troubleshooting

### Still seeing the error?
1. **Wait a few seconds** - Firebase changes can take a moment to propagate
2. **Clear browser cache** and refresh
3. **Restart your Flutter app** if running locally
4. **Check Firebase project** - Make sure you're using the correct Firebase project

### Users still not showing in Admin Panel?
- Make sure Firestore is enabled in your Firebase project
- Check that the `users` collection exists in Firestore
- Verify Firestore security rules allow writes (for development, you can temporarily allow all writes)

## Security Rules (Development)
For development/testing, you can use these Firestore rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

**Note:** For production, use more restrictive rules based on your needs.

