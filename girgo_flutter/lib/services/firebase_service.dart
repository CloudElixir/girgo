import 'package:flutter/foundation.dart' show debugPrint;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;
  // Firebase works on all platforms including Linux, Windows, macOS
  static bool get isSupported => true;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      return;
    }

    try {
      FirebaseOptions? options;
      try {
        options = DefaultFirebaseOptions.currentPlatform;
      } catch (e) {
        debugPrint('Girgo: Firebase options fallback (platform not configured): $e');
        options = DefaultFirebaseOptions.web;
      }

      await Firebase.initializeApp(options: options);
      _initialized = true;
      debugPrint('Girgo: FirebaseService initialized');
    } catch (e) {
      _initialized = false;
      debugPrint('Girgo: FirebaseService initialization failed: $e');
    }
  }

  static FirebaseAuth? get auth => _initialized ? FirebaseAuth.instance : null;
  static FirebaseMessaging? get messaging => _initialized ? FirebaseMessaging.instance : null;
}

