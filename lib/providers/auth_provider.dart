import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isAuthenticated = false;

  User? get user => _user;

  bool get isAuthenticated => _user != null || _isAuthenticated;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _user = _authService.getCurrentUser();
    
    // Only authenticate when Firebase has an active session. Guests browse
    // without signing in; sign-in is prompted from cart/checkout/account flows.
    _isAuthenticated = _user != null;
    
    notifyListeners();
    
    _authService.authStateChanges.listen((user) {
      _user = user;
      _isAuthenticated = user != null;
      notifyListeners();
    });
  }

  Future<void> signInWithGoogle() async {
    try {
      final userCredential = await _authService.signInWithGoogle();
      _user = userCredential?.user;
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;
      print('AuthProvider Google currentUser: ${FirebaseAuth.instance.currentUser}');
      
      // For Linux desktop, check SharedPreferences after login attempt
      if (_user == null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user');
        _isAuthenticated = userId != null && userId.isNotEmpty;
      } else {
        _isAuthenticated = true;
      }
      
      // Mark "just logged in" so UI can show non-blocking prompts.
      try {
        final prefs = await SharedPreferences.getInstance();
        final uid = prefs.getString('user') ?? _user?.uid;
        if (uid != null && uid.isNotEmpty) {
          await prefs.setString('justLoggedInUid', uid);
        }
      } catch (_) {}

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      final userCredential = await _authService.signInWithApple();
      _user = userCredential?.user;
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;
      print('AuthProvider Apple currentUser: ${FirebaseAuth.instance.currentUser}');
      
      // For platforms that support Apple Sign-In
      if (_user == null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user');
        _isAuthenticated = userId != null && userId.isNotEmpty;
      } else {
        _isAuthenticated = true;
      }
      
      // Mark "just logged in" so UI can show non-blocking prompts.
      try {
        final prefs = await SharedPreferences.getInstance();
        final uid = prefs.getString('user') ?? _user?.uid;
        if (uid != null && uid.isNotEmpty) {
          await prefs.setString('justLoggedInUid', uid);
        }
      } catch (_) {}

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Method to handle guest login (for Linux)
  Future<void> signInAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user');
    _isAuthenticated = userId != null && userId.isNotEmpty;
    notifyListeners();
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    try {
      final userCredential = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      _user = userCredential?.user;
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;
      print('AuthProvider SignUp currentUser: ${FirebaseAuth.instance.currentUser}');
      
      // For Linux desktop, check SharedPreferences after signup attempt
      if (_user == null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user');
        _isAuthenticated = userId != null && userId.isNotEmpty;
      } else {
        _isAuthenticated = true;
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      _user = userCredential?.user;
      await _user?.reload();
      _user = FirebaseAuth.instance.currentUser;
      print('AuthProvider Email currentUser: ${FirebaseAuth.instance.currentUser}');
      
      // For Linux desktop, check SharedPreferences after signin attempt
      if (_user == null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user');
        _isAuthenticated = userId != null && userId.isNotEmpty;
      } else {
        _isAuthenticated = true;
      }
      
      // Mark "just logged in" so UI can show non-blocking prompts.
      try {
        final prefs = await SharedPreferences.getInstance();
        final uid = prefs.getString('user') ?? _user?.uid;
        if (uid != null && uid.isNotEmpty) {
          await prefs.setString('justLoggedInUid', uid);
        }
      } catch (_) {}

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      // Even if signOut fails, clear local state
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }
}

