import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:deliq_delivery/Routes/routes.dart';
import 'package:deliq_delivery/main.dart';

@pragma('vm:entry-point')
Future<void> backgroundMessageHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  await Firebase.initializeApp();

  // Karena dari Laravel hanya kirim objek 'notification', kita ambil dari message.notification
  if (message.notification != null) {
    await NotificationService.instance.showNotification(
      title: message.notification!.title ?? 'New Message',
      body: message.notification!.body ?? '',
      payload: message.data, // Tetap passing jika ada data tambahan nanti
    );
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  // KUNCI UTAMA: Ubah ID channel menjadi fcm_fallback_notification_channel
  static const String _defaultChannelId = 'fcm_fallback_notification_channel';

  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _initializeAwesomeNotifications();
    await _requestPermissions();
    _configureFirebaseListeners();
  }

  Future<void> _initializeAwesomeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: _defaultChannelId,
          channelName: 'Default Notifications',
          channelDescription: 'Notifications for general info and orders.',
          defaultColor: const Color(0xFF9D50BB),
          ledColor: Colors.white,
          importance: NotificationImportance
              .Max, // Set Max agar pop-up muncul di atas layar
          playSound: true,
          soundSource: 'resource://raw/custom_sound', // Suara kustom Anda
          criticalAlerts: true,
        ),
      ],
      debug: !kReleaseMode,
    );

    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    );
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  void _configureFirebaseListeners() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleAppOpenedMessage);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');

    // Ambil data dari objek notification FCM
    await showNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
      payload: message.data,
    );
  }

  Future<void> _handleAppOpenedMessage(RemoteMessage message) async {
    debugPrint('Handling app opened message: ${message.messageId}');
    // Default action jika notifikasi diklik saat app mati/background lewat FCM langsung
    navigatorKey.currentState?.pushNamed(PageRoutes.newDeliveryPage);
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    final Map<String, String> stringPayload = payload.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _defaultChannelId, // Selalu gunakan channel fallback
        title: title,
        body: body,
        payload: stringPayload,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<String?> getFcmToken({int maxRetries = 3}) async {
    try {
      if (kIsWeb) {
        return await _firebaseMessaging.getToken(vapidKey: "YOUR-VAPID-KEY");
      }
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      if (maxRetries > 0) {
        await Future.delayed(const Duration(seconds: 10));
        return getFcmToken(maxRetries: maxRetries - 1);
      }
      return null;
    }
  }
}

class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    try {
      // Karena tidak ada pengecekan type 'order', setiap notifikasi di-klik akan langsung ke halaman delivery
      navigatorKey.currentState?.pushNamed(PageRoutes.newDeliveryPage);
    } catch (e) {
      debugPrint('Error handling notification action: $e');
    }
  }
}
