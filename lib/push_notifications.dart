import 'dart:convert';

import 'package:deliq_delivery/Routes/routes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:deliq_delivery/main.dart';

class PushNotifications {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // request notification permission
  static Future init() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    getFCMToken();
  }

// get the fcm device token
  static Future getFCMToken({int maxRetires = 3}) async {
    try {
      String? token;
      if (kIsWeb) {
        // get the device fcm token
        token = await _firebaseMessaging.getToken(
            vapidKey:
                "BJzRufH-VxRc7wLunA6WOaf-gVurFKhDluPRFB8644PQHw6OfWH8uzybtYsFBTA326_yy3PEG-L7OK_ojVsMmrI");
        print("for web device token: $token");
      } else {
        // get the device fcm token
        token = await _firebaseMessaging.getToken();
        print("for android device token: $token");
      }
      return token;
    } catch (e) {
      print("failed to get device token");
      if (maxRetires > 0) {
        print("try after 10 sec");
        await Future.delayed(Duration(seconds: 10));
        return getFCMToken(maxRetires: maxRetires - 1);
      } else {
        return null;
      }
    }
  }

// initalize local notifications
  static Future localNotiInit() async {
    final platform =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Channel untuk order dengan custom sound
    await platform?.createNotificationChannel(const AndroidNotificationChannel(
        'order_channel', 'Order Notifications',
        description: 'This channel is used for order notifications.',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notifscifi'),
        enableLights: true));

    // Channel untuk notifikasi umum dengan default sound
    await platform?.createNotificationChannel(const AndroidNotificationChannel(
      'default_channel',
      'Default Notifications',
      description: 'This channel is used for general notifications.',
      importance: Importance.max,
      playSound: true,
    ));

    // Inisialisasi normal tetap sama
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification: (id, title, body, payload) => null);

    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
            linux: initializationSettingsLinux);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: onNotificationTap);
  }

  // on tap local notification in foreground
  static void onNotificationTap(NotificationResponse notificationResponse) {
    try {
      Map<String, dynamic> payload =
          jsonDecode(notificationResponse.payload ?? '');
      if (payload['type'] == 'order') {
        navigatorKey.currentState!.pushNamed(PageRoutes.newDeliveryPage);
      }
    } catch (e) {
      print('Error parsing payload: $e');
    }
  }

  // show a simple notification
  static Future showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    // Parse payload untuk mendapatkan type
    Map<String, dynamic> payloadData = jsonDecode(payload);
    String notificationType = payloadData['type'] ?? 'default';

    // Buat notification details berdasarkan type
    late AndroidNotificationDetails androidNotificationDetails;

    if (notificationType == 'order') {
      androidNotificationDetails = const AndroidNotificationDetails(
          'order_channel', 'Order Notifications',
          channelDescription: 'This channel is used for order notifications.',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notifscifi'),
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category:
              AndroidNotificationCategory.call, // Gunakan call untuk bypass DND
          audioAttributesUsage:
              AudioAttributesUsage.notification, // Ini membantu volume
          visibility: NotificationVisibility.public);
    } else {
      androidNotificationDetails = const AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        channelDescription: 'This channel is used for general notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
    }

    final notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin
        .show(0, title, body, notificationDetails, payload: payload);
  }
}
