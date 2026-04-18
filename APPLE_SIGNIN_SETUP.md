# Apple Sign-In with Firebase - Setup and Verification Guide

## ✅ Implementation Status

The Apple Sign-In implementation in `lib/services/auth_service.dart` follows the correct authentication flow:

### 1. **Secure Nonce Generation** ✅
- Generates a secure random 32-character nonce using `Random.secure()`
- SHA256 hashes the nonce before sending to Apple
- Uses the original (unhashed) nonce for Firebase credential creation

### 2. **Apple Credential Request** ✅
- Uses `SignInWithApple.getAppleIDCredential` with:
  - `scopes: [email, fullName]` - requests email and full name
  - `nonce: hashedNonce` - sends SHA256 hashed nonce to Apple

### 3. **Identity Token Handling** ✅
- Validates that `identityToken` is not null or empty
- Logs token length for debugging
- Uses the identity token for Firebase authentication

### 4. **Firebase OAuth Credential** ✅
- Creates credential using: `OAuthProvider('apple.com').credential(idToken: identityToken, rawNonce: rawNonce)`
- Correctly passes the original (unhashed) nonce to Firebase
- Signs in using `FirebaseAuth.instance.signInWithCredential(credential)`

### 5. **Error Handling** ✅
- Catches `SignInWithAppleAuthorizationException` for Apple-specific errors
- Catches `FirebaseAuthException` for Firebase-specific errors
- Provides user-friendly error messages
- Logs detailed error information with emojis for easy debugging

### 6. **Platform Checks** ✅
- Validates platform is iOS or macOS
- Checks if Apple Sign-In is available on the device
- Provides clear error messages for unsupported platforms

### 7. **User Data Handling** ✅
- Extracts user's given name and family name from Apple response
- Updates Firebase user profile with display name
- Stores user data in SharedPreferences
- Creates/updates user in Firestore

## 🔧 Required iOS Configuration

### 1. **Apple Developer Account Setup**
- [ ] Enable "Sign in with Apple" capability for your App ID in Apple Developer Console
- [ ] Ensure Bundle ID matches: `com.anamaya.girgo`
- [ ] Create a Services ID if needed
- [ ] Configure return URLs to point to your Firebase auth handler

### 2. **Firebase Console Configuration**
- [ ] Go to Firebase Console → Authentication → Sign-in method
- [ ] Enable Apple sign-in provider
- [ ] Fill in:
  - **Service ID**: Your Apple Services ID
  - **Team ID**: Your Apple Developer Team ID
  - **Key ID**: Your Apple Sign-In Key ID
  - **Private Key**: Upload the .p8 private key from Apple Developer

### 3. **iOS Project Configuration**
- [ ] `ios/Runner/Runner.entitlements` contains:
  ```xml
  <key>com.apple.developer.applesignin</key>
  <array>
      <string>Default</string>
  </array>
  ```
- [ ] Bundle ID in `ios/Runner/Info.plist` matches Firebase: `com.anamaya.girgo`
- [ ] Build number updated to 22 ✅

### 4. **Flutter Dependencies**
- [ ] `sign_in_with_apple: ^7.0.1` ✅
- [ ] `crypto: ^3.0.6` ✅
- [ ] `firebase_auth: ^5.0.0` ✅

## 🧪 Testing on Real iOS Device

**Important**: Apple Sign-In does NOT work on iOS Simulator. You must test on a physical device.

### Testing Steps:
1. Connect a real iPhone/iPad with iOS 13+
2. Build and run the app on the device
3. Tap the Apple Sign-In button
4. Check the console logs for the following sequence:
   ```
   🍎 Starting Apple Sign-In flow...
   ✅ Platform check passed: ios
   ✅ Apple Sign-In is available
   🔐 Generated raw nonce: ********...
   🔐 Hashed nonce: ****************...
   📱 Requesting Apple ID credential...
   ✅ Apple credential received
   📧 Email: user@example.com
   👤 Given Name: John
   👤 Family Name: Doe
   🆔 User ID: 001234.abcd1234...
   ✅ Identity token received (length: 1234)
   🔑 Creating Firebase OAuth credential...
   ✅ Firebase OAuth credential created
   🔐 Signing in with Firebase...
   ✅ Firebase sign-in successful
   👤 User UID: abc123...
   📧 User Email: user@example.com
   🎉 Apple Sign-In completed successfully
   ```

## 🐛 Common Issues and Solutions

### Issue: "Apple Sign-In is not available on this device"
**Solution**: 
- You must test on a real iOS device (not simulator)
- Ensure iOS version is 13+
- Check that "Sign in with Apple" capability is enabled in Apple Developer Console

### Issue: "Apple did not return an identity token"
**Solution**:
- Verify Runner.entitlements has the Sign in with Apple capability
- Clean and rebuild the iOS project: `flutter clean && flutter pub get && cd ios && pod install && cd ..`
- Ensure Bundle ID matches between Apple Developer and Firebase

### Issue: "operation-not-allowed" from Firebase
**Solution**:
- Enable Apple sign-in in Firebase Console → Authentication → Sign-in method
- Verify all required fields (Service ID, Team ID, Key ID, .p8 key) are filled correctly

### Issue: "invalid-credential" from Firebase
**Solution**:
- Ensure the nonce flow is correct (SHA256 hashed to Apple, original to Firebase)
- Verify Apple Services ID configuration in Apple Developer Console
- Check that return URLs match between Apple and Firebase

### Issue: Email not provided on subsequent sign-ins
**Expected Behavior**: Apple only provides the email on the FIRST sign-in. Subsequent sign-ins will not include the email for privacy reasons. The email is stored in Firebase and can be retrieved from the user object.

## 📝 Debug Logging

The implementation includes comprehensive logging with emojis:
- 🍎 Apple Sign-In flow start
- ✅ Success checkpoints
- ❌ Error conditions
- 🔐 Security operations (nonce generation)
- 📱 Apple credential requests
- 🔑 Firebase credential creation
- 👤 User data handling
- 💾 Storage operations
- 🎉 Successful completion

Monitor the console output during testing to identify any issues quickly.

## 🔐 Security Notes

1. **Nonce Security**: The nonce is generated using `Random.secure()` and is SHA256 hashed before being sent to Apple. The original nonce is only used locally for Firebase credential creation.

2. **Token Handling**: The identity token from Apple is validated before being used with Firebase.

3. **Error Messages**: Error messages are designed to be user-friendly while logging detailed technical information for debugging.

## 📦 Build Configuration

- **Version**: 1.0.0+22
- **iOS Build Number**: 22
- **Bundle ID**: com.anamaya.girgo

## ✅ Checklist for Deployment

- [ ] Test on real iOS device (not simulator)
- [ ] Verify Apple Sign-In works for new users
- [ ] Verify Apple Sign-In works for returning users
- [ ] Check that email is captured on first sign-in
- [ ] Verify user data is stored in Firestore
- [ ] Test error handling (cancel sign-in, network issues)
- [ ] Ensure Firebase Console has Apple sign-in enabled
- [ ] Verify Apple Developer Console has Sign in with Apple enabled
- [ ] Confirm Bundle ID matches across all platforms
- [ ] Update build number for each release

## 📞 Support

If issues persist:
1. Check console logs for error messages with emojis
2. Verify all configurations in Apple Developer Console
3. Verify all configurations in Firebase Console
4. Ensure you're testing on a real iOS device with iOS 13+
5. Clean and rebuild the project
