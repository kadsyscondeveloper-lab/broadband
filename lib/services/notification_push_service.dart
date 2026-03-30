// lib/services/notification_push_service.dart
//
// Changes vs your existing file:
//   1. clearToken() now calls DELETE /fcm/token instead of POST with empty token
//   2. _saveTokenToBackend() uses POST with data: (not data:) — Dio fix
//   3. registerTokenAfterLogin() calls init() if not yet initialized, then registers
//   4. Added _initialized flag to avoid double-init

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';

// ── Background handler (must be a top-level function) ────────────────────────
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class NotificationPushService {
  static final NotificationPushService _i = NotificationPushService._();
  factory NotificationPushService() => _i;
  NotificationPushService._();

  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  final _api   = ApiClient();

  bool _initialized = false;

  static const _channelId   = 'speedonet_channel';
  static const _channelName = 'Speedonet Notifications';
  static const _channelDesc = 'Plan activations, wallet updates and support alerts';

  // ── Public init — call from _AuthGateState._initNotifications() ───────────

  Future<void> init() async {
    if (_initialized) {
      // Already initialized — just re-register the token in case it changed
      await _registerToken();
      return;
    }

    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // 2. Request permission
    final settings = await _fcm.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 3. Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance:  Importance.high,
      playSound:   true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Initialise flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS:     DarwinInitializationSettings(),
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 5. Foreground messages → show local notification banner
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6. App opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

    // 7. App was killed — opened via notification tap
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleDeepLink(initial.data);

    // 8. Register current token with backend
    await _registerToken();

    // 9. Auto-refresh token when Firebase rotates it
    _fcm.onTokenRefresh.listen(_saveTokenToBackend);

    _initialized = true;
    debugPrint('[FCM] NotificationPushService initialized ✓');
  }

  // ── Called by AuthService._persist() right after login/signup ────────────

  Future<void> registerTokenAfterLogin() async {
    // If init() hasn't been called yet (e.g. fresh login, not app restart),
    // just register the token directly — no need to re-request permissions.
    await _registerToken();
  }

  // ── Foreground message → show local notification ──────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    debugPrint('[FCM] Foreground: ${n.title}');

    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance:         Importance.high,
          priority:           Priority.high,
          icon:               '@mipmap/ic_launcher',
          playSound:          true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['deep_link'],
    );
  }

  // ── Notification tapped (local notification) ──────────────────────────────

  void _onNotificationTap(NotificationResponse response) {
    final deepLink = response.payload;
    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('[FCM] Tapped deep link: $deepLink');
      // TODO: wire up navigator when you add deep linking
    }
  }

  // ── App opened from background ────────────────────────────────────────────

  void _onNotificationOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Opened from background: ${message.notification?.title}');
    _handleDeepLink(message.data);
  }

  void _handleDeepLink(Map<String, dynamic> data) {
    final deepLink = data['deep_link'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('[FCM] Deep link: $deepLink');
      // TODO: navigate when you add deep linking
    }
  }

  // ── Token management ──────────────────────────────────────────────────────

  Future<void> _registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) {
        debugPrint('[FCM] Could not get token from Firebase');
        return;
      }
      debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
      await _saveTokenToBackend(token);
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      if (!StorageService().hasToken) {
        debugPrint('[FCM] Not logged in — skipping token save');
        return;
      }
      // ✅ FIX: use data: (named param) not positional
      await _api.post('/fcm/token', data: {'token': token});
      debugPrint('[FCM] Token saved to backend ✓');
    } catch (e) {
      debugPrint('[FCM] Could not save token to backend: $e');
    }
  }

  // ── Call on logout — stops push notifications for this device ────────────

  Future<void> clearToken() async {
    try {
      // ✅ FIX: call DELETE /fcm/token, not POST with empty string
      await _api.delete('/fcm/token');
      debugPrint('[FCM] Token cleared from backend ✓');
    } catch (e) {
      debugPrint('[FCM] Could not clear token: $e');
    }

    try {
      // Also delete from Firebase so this device stops receiving pushes
      // entirely until the next login + token registration
      await _fcm.deleteToken();
      debugPrint('[FCM] Firebase token deleted ✓');
    } catch (e) {
      debugPrint('[FCM] Could not delete Firebase token: $e');
    }
  }
}