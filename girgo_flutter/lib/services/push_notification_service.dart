import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Firebase Cloud Messaging + local notifications (foreground).
/// Saves FCM token to `users/{uid}.fcmToken` for your backend / Cloud Functions.
///
/// Example HTTP v1 / Admin SDK payload (tap opens Orders in app):
/// `notification: { title, body }`, `data: { route: '/orders' }`, `token: <fcmToken>`.
class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState>? _navigatorKey;
  static int _notificationId = 0;

  static const _androidChannel = AndroidNotificationChannel(
    'girgo_orders',
    'Orders & updates',
    description: 'Order status, delivery, and Girgo alerts',
    importance: Importance.high,
  );

  static bool get _nativeSupported {
    if (kIsWeb) return false;
    final p = defaultTargetPlatform;
    return p == TargetPlatform.android || p == TargetPlatform.iOS;
  }

  static Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;

    if (!_nativeSupported) {
      debugPrint('Girgo: Push FCM skipped (web/desktop)');
      return;
    }

    if (Firebase.apps.isEmpty) {
      debugPrint('Girgo: Push skipped (Firebase not initialized)');
      return;
    }

    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _local
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _persistToken(user.uid);
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && token.isNotEmpty) {
        try {
          await FirestoreService.saveUserFcmToken(uid, token);
        } catch (_) {}
      }
    });

    FirebaseMessaging.onMessage.listen(_onForegroundRemoteMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handlePayload(m.data));

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handlePayload(initial.data);
      });
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await _persistToken(uid);
    }
  }

  static Future<void> _persistToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await FirestoreService.saveUserFcmToken(uid, token);
        if (kDebugMode) {
          debugPrint('FCM token registered in Firestore');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM token error: $e');
      }
    }
  }

  static void _onForegroundRemoteMessage(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? (message.data['title'] as String?) ?? 'Girgo';
    final body = n?.body ?? (message.data['body'] as String?) ?? '';
    if (title.isEmpty && body.isEmpty) return;
    _showLocalNotification(title, body, message.data);
  }

  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    final route = data['route'] as String? ?? '';
    final android = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _local.show(
      _notificationId++,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: route.isNotEmpty ? route : null,
    );
  }

  static void _onLocalTap(NotificationResponse response) {
    final p = response.payload;
    if (p != null && p.isNotEmpty) {
      _handlePayload({'route': p});
    }
  }

  static void _handlePayload(Map<String, dynamic> data) {
    final route = (data['route'] as String?) ?? '';
    final normalized = route.replaceFirst('/', '');
    if (normalized == 'orders') {
      _navigatorKey?.currentState?.pushNamed('/orders');
    }
  }
}
