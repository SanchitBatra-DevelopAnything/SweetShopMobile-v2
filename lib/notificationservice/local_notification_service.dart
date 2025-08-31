import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          print("Router Payload: $payload");
          // Handle navigation if needed
        }
      },
    );

    await _requestPermissions();
  }

  Future<void> setupNotificationChannel() async {

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
  const channel = AndroidNotificationChannel(
    'Sweet-Shop-App-3', // 👈 must match channel_id from function
    'Sweet Shop Notifications',
    description: 'Sweet Shop order bell',
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('sound'),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

  static Future<void> _requestPermissions() async {
    // Android 13+ notifications permission
    if (await Permission.notification.isDenied ||
        await Permission.notification.isRestricted) {
      await Permission.notification.request();
    }

    // iOS Firebase permission
    await FirebaseMessaging.instance.requestPermission();
  }

  static Future<void> createAndDisplayNotification(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const androidDetails = AndroidNotificationDetails(
        'Sweet-Shop-App-3',
        'Sweet-Shop-App-3',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: RawResourceAndroidNotificationSound('sound'),
      );

      const notifDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id,
        message.notification?.title ?? '',
        message.notification?.body ?? '',
        notifDetails,
        payload: message.data['_id'] ?? '',
      );
    } catch (e) {
      print("Notification error: $e");
    }
  }
}
