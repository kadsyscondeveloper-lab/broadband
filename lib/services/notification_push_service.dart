// lib/services/notification_push_service.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/api_client.dart';
import '../core/storage_service.dart';

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class NotificationPushService {
  static final NotificationPushService _i = NotificationPushService._();
  factory NotificationPushService() => _i;
  NotificationPushService._();

  static void Function()? onAvailabilityConfirmed;
  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  final _api   = ApiClient();

  bool    _initialized  = false;
  String? _currentToken; // cached so clearToken can send it to backend

  static const _channelId   = 'speedonet_channel';
  static const _channelName = 'Speedonet Notifications';
  static const _channelDesc = 'Plan activations, wallet updates and support alerts';

  // ── Public init ───────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) {
      // Already set up — just re-register token (may have changed)
      await _registerToken();
      return;
    }

    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    final settings = await _fcm.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    const channel = AndroidNotificationChannel(
      _channelId, _channelName,
      description: _channelDesc,
      importance:  Importance.high,
      playSound:   true,
    );
    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS:     DarwinInitializationSettings(),
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationOpenedApp);

    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleDeepLink(initial.data);

    await _registerToken();

    // Auto re-register if Firebase rotates the token
    _fcm.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      _saveTokenToBackend(newToken);
    });

    _initialized = true;
    debugPrint('[FCM] NotificationPushService initialized ✓');
  }

  // Called by AuthService._persist() after every login/signup
  Future<void> registerTokenAfterLogin() async {
    await _registerToken();
  }

  // ── Foreground message → show banner ─────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final n = message.notification;

    final type = message.data['inquiry_status'] ?? message.data['type'];

    if (type == 'available' || message.data['inquiry_status'] == 'available') {
      onAvailabilityConfirmed?.call();
    }
    if (n == null) return;

    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
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

  void _onNotificationTap(NotificationResponse response) {
    final deepLink = response.payload;
    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('[FCM] Tapped deep link: $deepLink');
      // TODO: wire up navigator
    }
  }

  void _onNotificationOpenedApp(RemoteMessage message) {
    _handleDeepLink(message.data);
  }

  void _handleDeepLink(Map<String, dynamic> data) {
    final deepLink = data['deep_link'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('[FCM] Deep link: $deepLink');
      // TODO: navigate
    }
  }

  // ── Token management ──────────────────────────────────────────────────────

  Future<void> _registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      _currentToken = token;
      debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
      await _saveTokenToBackend(token);
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      if (!StorageService().hasToken) return;
      await _api.post('/fcm/token', data: {'token': token});
      debugPrint('[FCM] Token saved to backend ✓');
    } catch (e) {
      debugPrint('[FCM] Could not save token: $e');
    }
  }

  // ── Logout — removes only THIS device's token ─────────────────────────────
  // Other devices logged into the same account keep receiving notifications.

  Future<void> clearToken() async {
    try {
      // POST /fcm/token/clear with the current token
      // so backend removes only this device's row from dbo.fcm_tokens
      await _api.post('/fcm/token/clear', data: {'token': _currentToken});
      debugPrint('[FCM] Token cleared from backend ✓');
    } catch (e) {
      debugPrint('[FCM] Could not clear token from backend: $e');
    }

    try {
      // Delete from Firebase so this device stops receiving pushes
      await _fcm.deleteToken();
      _currentToken = null;
      debugPrint('[FCM] Firebase token deleted ✓');
    } catch (e) {
      debugPrint('[FCM] Could not delete Firebase token: $e');
    }
  }
}