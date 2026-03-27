// lib/services/notification_push_service.dart
//
// Initialises Firebase Messaging, requests permission, shows heads-up
// notifications when the app is in the foreground, and registers the
// FCM token with your backend so it can send pushes.
//
// Call once from main.dart:
//   await NotificationPushService().init();

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

  final _fcm    = FirebaseMessaging.instance;
  final _local  = FlutterLocalNotificationsPlugin();
  final _api    = ApiClient();

  static const _channelId   = 'speedonet_channel';
  static const _channelName = 'Speedonet Notifications';
  static const _channelDesc = 'Plan activations, wallet updates and support alerts';

  // ── Public init — call from main.dart ─────────────────────────────────────

  Future<void> init() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // 2. Request permission
    final settings = await _fcm.requestPermission(
      alert:         true,
      badge:         true,
      sound:         true,
      provisional:   false,
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

    // 5. Show heads-up banner when app is FOREGROUND
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6. Handle notification tap when app was in BACKGROUND (not killed)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

    // 7. Handle notification tap when app was KILLED
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleDeepLink(initial.data);

    // 8. Register token with backend
    await _registerToken();

    // 9. Refresh token if FCM rotates it
    _fcm.onTokenRefresh.listen(_saveTokenToBackend);
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
      debugPrint('[FCM] Tapped — deep link: $deepLink');
      // TODO: wire up your navigator here when you add deep linking
    }
  }

  // ── App opened from background via notification ───────────────────────────

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
      if (token == null) return;
      debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
      await _saveTokenToBackend(token);
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      // Only save if user is logged in
      if (!StorageService().hasToken) return;
      await _api.post('/fcm/token', data: {'token': token});
      debugPrint('[FCM] Token saved to backend ✓');
    } catch (e) {
      debugPrint('[FCM] Could not save token to backend: $e');
    }
  }


  Future<void> registerTokenAfterLogin() async {
    await _registerToken();
  }

  // ── Call on logout to stop receiving notifications ────────────────────────

  Future<void> clearToken() async {
    try {
      await _fcm.deleteToken();
      // Also clear on backend
      await _api.post('/fcm/token', data: {'token': ''});
    } catch (_) {}
  }
}