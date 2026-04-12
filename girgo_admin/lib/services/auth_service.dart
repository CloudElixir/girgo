import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firestore_service.dart';

/// Optional: set when running web admin on localhost only, e.g.
/// `flutter run -d chrome --dart-define=GIRGO_ALLOW_LOCAL_ADMIN_EMAIL=you@example.com`
/// Production builds should leave this unset (empty).
const String _kAllowLocalAdminEmail = String.fromEnvironment(
  'GIRGO_ALLOW_LOCAL_ADMIN_EMAIL',
  defaultValue: '',
);

/// Emails that may access the admin panel after successful Firebase Authentication
/// (Google or email/password), even without a Firestore `users/{uid}` admin document.
/// Add the account in Firebase Console → Authentication (Email/Password) to use password login.
const Set<String> _kBootstrapAdminEmails = {
  'webgirgoindia@gmail.com',
};

/// Short, actionable messages for SnackBars (avoids raw `[firebase_auth/...]` dumps).
String formatAuthErrorForUser(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Wrong email or password. Check spelling — admin login is '
            'webgirgoindia@gmail.com (g-i-r-g-o, not g-r-i-g-o). '
            'Reset the password in Firebase → Authentication if needed.';
      case 'invalid-email':
        return 'That email doesn’t look valid. Check for typos.';
      case 'user-disabled':
        return 'This account is disabled in Firebase.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a few minutes, then try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        final msg = e.message;
        if (msg != null && msg.isNotEmpty) return msg;
        return 'Sign-in failed (${e.code}).';
    }
  }
  return e.toString();
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // OAuth Client ID for web
    // Make sure this Client ID has localhost authorized in Google Cloud Console
    clientId: kIsWeb 
        ? '220181038206-01h7sld5sb34d47ce5nc00ud84rnemmq.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile', 'openid'],
  );

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Firestore `users/{uid}` must have `isAdmin: true` or `role: admin`, unless
  /// the signed-in email is in [_kBootstrapAdminEmails] or the localhost dart-define bypass is active.
  Future<bool> _hasAdminAccess(User user, String uid) async {
    if (await FirestoreService.isUserAdmin(uid)) return true;
    final email = user.email?.toLowerCase().trim();
    if (email != null && _kBootstrapAdminEmails.contains(email)) return true;
    if (_kAllowLocalAdminEmail.isEmpty) return false;
    if (!kIsWeb) return false;
    final host = Uri.base.host;
    if (host != 'localhost' && host != '127.0.0.1') return false;
    return email == _kAllowLocalAdminEmail.toLowerCase().trim();
  }

  /// Email/password via Firebase Auth. Enable "Email/Password" in Firebase Console and
  /// create the user there (password is never stored in app code).
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final trimmed = email.trim();
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: trimmed,
        password: password,
      );
      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw Exception('Sign-in failed. Please try again.');
      }
      final user = userCredential.user!;
      final isAdmin = await _hasAdminAccess(user, uid);
      if (!isAdmin) {
        await signOut();
        throw Exception('Access denied. Admin privileges required.');
      }
      return userCredential;
    } catch (e) {
      print('❌ Email sign-in error: $e');
      throw Exception(formatAuthErrorForUser(e));
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('🔐 Starting Google Sign-In...');
      
      if (kIsWeb) {
        // Use Firebase Auth popup directly on web (more reliable than custom JS interop).
        print('🌐 Using Firebase Auth signInWithPopup for web...');
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile')
          ..setCustomParameters({'prompt': 'select_account'});

        final userCredential = await _auth.signInWithPopup(provider);
        final uid = userCredential.user?.uid;
        if (uid == null) {
          throw Exception('Sign-in failed. Please try again.');
        }

        print('✅ Firebase popup sign-in successful: ${userCredential.user?.email}');
        final user = userCredential.user!;
        final isAdmin = await _hasAdminAccess(user, uid);
        if (!isAdmin) {
          await signOut();
          throw Exception('Access denied. Admin privileges required.');
        }
        return userCredential;
      } else {
        // For mobile platforms, use google_sign_in package
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        if (googleAuth.idToken == null) {
          throw Exception('Failed to get ID token from Google');
        }

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _completeSignIn(credential);
      }
    } catch (e) {
      print('❌ Sign-in error: $e');
      rethrow;
    }
  }

  Future<UserCredential> _completeSignIn(OAuthCredential credential) async {
    print('🔐 Signing in to Firebase...');
    final userCredential = await _auth.signInWithCredential(credential);
    print('✅ Firebase sign-in successful: ${userCredential.user?.uid}');
    
    // Check if user is admin
    if (userCredential.user != null) {
      print('🔍 Checking admin status...');
      final u = userCredential.user!;
      final isAdmin = await _hasAdminAccess(u, u.uid);
      if (!isAdmin) {
        print('❌ User is not an admin');
        await signOut();
        throw Exception('Access denied. Admin privileges required.');
      }
      print('✅ User is an admin');
    }

    return userCredential;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

