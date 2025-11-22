import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:usdtmining/services/notification_service.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.ensureInitialized();
  final notification = message.notification;
  if (notification != null) {
    await NotificationService.showNotification(
      id: notification.hashCode,
      title: notification.title ?? 'New message',
      body: notification.body ?? '',
    );
  }
}

class MessagingService {
  MessagingService()
      : _messaging = FirebaseMessaging.instance,
        _inAppMessaging = FirebaseInAppMessaging.instance;

  final FirebaseMessaging _messaging;
  final FirebaseInAppMessaging _inAppMessaging;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.setAutoInitEnabled(true);
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      announcement: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        debugPrint('🔔 FCM token: $token');
      }
    } else {
      if (kDebugMode) {
        debugPrint(
          '🔕 Push notifications disabled: ${settings.authorizationStatus}',
        );
      }
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }

    await _inAppMessaging.setAutomaticDataCollectionEnabled(true);
    await _inAppMessaging.setMessagesSuppressed(false);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await NotificationService.ensureInitialized();
      await NotificationService.showNotification(
        id: notification.hashCode,
        title: notification.title ?? 'New message',
        body: notification.body ?? '',
      );
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('📬 Notification opened: ${message.data}');
    }
    final campaign = message.data['campaign'];
    if (campaign != null && campaign is String && campaign.isNotEmpty) {
      _inAppMessaging.triggerEvent(campaign);
    }
  }
}

