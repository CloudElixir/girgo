import 'dart:io';
import 'package:flutter/foundation.dart';
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
      return; // Already initialized
    }

    try {
      // For Linux/Windows/macOS, use web options as fallback
      FirebaseOptions? options;
      try {
        options = DefaultFirebaseOptions.currentPlatform;
      } catch (e) {
        // If platform not configured, use web options
        if (kDebugMode) {
          print('Platform not configured, using web options');
        }
        options = DefaultFirebaseOptions.web;
      }
      
      await Firebase.initializeApp(options: options);
      _initialized = true;
      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
    } catch (e) {
      _initialized = false;
      if (kDebugMode) {
        print('❌ Firebase initialization failed: $e');
      }
      rethrow; // Re-throw so migration screen can catch it
    }
  }

  static FirebaseAuth? get auth => _initialized ? FirebaseAuth.instance : null;
  static FirebaseMessaging? get messaging => _initialized ? FirebaseMessaging.instance : null;
}

