import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import 'firestore_service.dart';

/// Web OAuth client from Firebase (used so Google returns an ID token Firebase accepts on iOS/Android).
const String _kGoogleServerClientId =
    '220181038206-01h7sld5sb34d47ce5nc00ud84rnemmq.apps.googleusercontent.com';

/// iOS OAuth client (must match `CLIENT_ID` in `GoogleService-Info.plist`).
const String _kGoogleIosClientId =
    '220181038206-v1drfeu8rk5p20v44i6jg99emfdui9uf.apps.googleusercontent.com';

String _generateNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

String _sha256OfString(String input) {
  final bytes = utf8.encode(input);
  return sha256.convert(bytes).toString();
}

class AuthService {
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _kGoogleServerClientId,
    clientId: io.Platform.isIOS ? _kGoogleIosClientId : null,
  );

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (FirebaseService.auth == null) {
        // Fallback for platforms without Firebase (Linux desktop)
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', googleUser.id);
        await prefs.setString('userEmail', googleUser.email);
        await prefs.setString('userName', googleUser.displayName ?? '');
        await prefs.setString('userPhoto', googleUser.photoUrl ?? '');
        return null; // No Firebase credential on Linux
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message:
              'Google Sign-In did not return an ID token. On iOS, confirm GIDClientID and URL scheme in Info.plist match Firebase.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseService.auth!.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final user = userCredential.user!;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', user.uid);
        await prefs.setString('userEmail', user.email ?? '');
        await prefs.setString('userName', user.displayName ?? '');
        await prefs.setString('userPhoto', user.photoURL ?? '');
        
        // Create or update user in Firestore
        try {
          await FirestoreService.createOrUpdateUser(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            photoURL: user.photoURL,
          );
          print('✅ User created/updated in Firestore');
        } catch (e) {
          print('⚠️ Failed to create user in Firestore: $e');
          // Don't fail sign-in if Firestore update fails
        }
      }

      return userCredential;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    try {
      if (FirebaseService.auth == null) {
        // Fallback for platforms without Firebase (Linux desktop)
        // Store locally in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', email); // Use email as ID for local storage
        await prefs.setString('userEmail', email);
        if (name != null) {
          await prefs.setString('userName', name);
        }
        if (phone != null) {
          await prefs.setString('userMobile', phone);
        }
        return null; // No Firebase credential on Linux
      }

      // Create user with Firebase Auth
      final userCredential = await FirebaseService.auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // Update display name if provided
        if (name != null && name.isNotEmpty) {
          await user.updateDisplayName(name);
          await user.reload();
        }

        // Store in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', user.uid);
        await prefs.setString('userEmail', user.email ?? email);
        if (name != null) {
          await prefs.setString('userName', name);
        }
        if (phone != null) {
          await prefs.setString('userMobile', phone);
        }

        // Create or update user in Firestore
        try {
          await FirestoreService.createOrUpdateUser(
            uid: user.uid,
            email: user.email ?? email,
            name: name ?? user.displayName,
            phone: phone,
          );
          print('✅ User created/updated in Firestore: ${user.uid}');
        } catch (e) {
          print('⚠️ Failed to create user in Firestore: $e');
          // Don't fail sign-up if Firestore update fails
        }
      }

      return userCredential;
    } catch (e) {
      print('Email Sign-Up Error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      if (FirebaseService.auth == null) {
        // Fallback for platforms without Firebase (Linux desktop)
        // Check if user exists in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final storedEmail = prefs.getString('userEmail');
        if (storedEmail == email) {
          // User exists locally
          return null; // No Firebase credential on Linux
        } else {
          throw Exception('User not found. Please sign up first.');
        }
      }

      // Sign in with Firebase Auth
      final userCredential = await FirebaseService.auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // Store in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', user.uid);
        await prefs.setString('userEmail', user.email ?? email);
        if (user.displayName != null) {
          await prefs.setString('userName', user.displayName!);
        }

        // Update user in Firestore (in case profile was updated elsewhere)
        try {
          await FirestoreService.createOrUpdateUser(
            uid: user.uid,
            email: user.email ?? email,
            name: user.displayName,
            photoURL: user.photoURL,
          );
          print('✅ User updated in Firestore: ${user.uid}');
        } catch (e) {
          print('⚠️ Failed to update user in Firestore: $e');
          // Don't fail sign-in if Firestore update fails
        }
      }

      return userCredential;
    } catch (e) {
      print('Email Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Google
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('Google Sign Out Error (may not be available on Linux): $e');
      }
      
      // Sign out from Firebase if available
      if (FirebaseService.auth != null) {
        try {
          await FirebaseService.auth!.signOut();
        } catch (e) {
          print('Firebase Sign Out Error: $e');
        }
      }
      
      // Clear SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        // Clear user-related keys specifically
        await prefs.remove('user');
        await prefs.remove('userEmail');
        await prefs.remove('userName');
        await prefs.remove('userPhoto');
        // Also clear all for good measure
        await prefs.clear();
      } catch (e) {
        print('SharedPreferences Clear Error: $e');
        // Don't rethrow - clearing prefs is not critical
      }
    } catch (e) {
      print('Sign Out Error: $e');
      // Don't rethrow - we want to clear local state even if remote signout fails
    }
  }

  User? getCurrentUser() {
    return FirebaseService.auth?.currentUser;
  }

  Stream<User?> get authStateChanges {
    if (FirebaseService.auth == null) {
      // Return empty stream for platforms without Firebase
      return const Stream<User?>.empty();
    }
    return FirebaseService.auth!.authStateChanges();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (FirebaseService.auth == null) {
      throw Exception('Password reset requires Firebase support.');
    }
    await FirebaseService.auth!.sendPasswordResetEmail(email: email);
  }

  /// Permanently delete the current user's account and all associated data.
  /// Throws Exception with message containing 'recent' if re-authentication is needed.
  Future<void> deleteAccount() async {
    if (FirebaseService.auth == null) {
      await signOut();
      throw Exception('Account deletion requires Firebase. Your local data has been cleared.');
    }

    final user = FirebaseService.auth!.currentUser;
    if (user == null) {
      throw Exception('No user signed in.');
    }

    final uid = user.uid;

    try {
      // 1. Delete Firestore data first
      await FirestoreService.deleteAllUserData(uid);

      // 2. Delete Firebase Auth user
      await user.delete();

      // 3. Sign out and clear local state
      await signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'For security, please sign out and sign in again, then try deleting your account.',
        );
      }
      rethrow;
    }
  }

  /// Sign in with Apple (iOS/macOS only)
  Future<UserCredential?> signInWithApple() async {
    try {
      if (FirebaseService.auth == null) {
        throw Exception('Apple Sign-In requires Firebase support.');
      }

      // Check platform - Apple Sign-In only works on iOS and macOS
      if (!io.Platform.isIOS && !io.Platform.isMacOS) {
        throw Exception('Apple Sign-In is only available on iOS and macOS.');
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256OfString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      if (appleCredential.identityToken == null ||
          appleCredential.identityToken!.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message:
              'Apple did not return an identity token. Enable Sign In with Apple for this App ID and rebuild with the Runner.entitlements file.',
        );
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await FirebaseService.auth!.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // Get full name from Apple credential
        String displayName = '';
        if (appleCredential.givenName != null || appleCredential.familyName != null) {
          displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        }

        // Update display name if we got it from Apple
        if (displayName.isNotEmpty && user.displayName != displayName) {
          await user.updateDisplayName(displayName);
          await user.reload();
        }

        // Store in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', user.uid);
        await prefs.setString('userEmail', user.email ?? '');
        if (displayName.isNotEmpty) {
          await prefs.setString('userName', displayName);
        }
        if (user.photoURL != null) {
          await prefs.setString('userPhoto', user.photoURL!);
        }

        // Create or update user in Firestore
        try {
          await FirestoreService.createOrUpdateUser(
            uid: user.uid,
            email: user.email ?? '',
            name: displayName.isNotEmpty ? displayName : user.displayName,
            photoURL: user.photoURL,
          );
          print('✅ User created/updated in Firestore via Apple Sign-In');
        } catch (e) {
          print('⚠️ Failed to create user in Firestore: $e');
          // Don't fail sign-in if Firestore update fails
        }
      }

      return userCredential;
    } catch (e) {
      print('Apple Sign-In Error: $e');
      rethrow;
    }
  }
}

