// lib/repository/fcm_manager.dart
import 'dart:developer';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/navigator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../data/FcmService/fcm_service.dart';
import '../res/routes/routes_name.dart';
import '../view_models/controller/userPreferences/user_preferences_screen.dart';
import 'package:flutter/scheduler.dart';

import '../main.dart';
import '../view/message/notificationservice.dart';

class FcmManager {
  static bool _bound = false;
  static bool _navLocked = false;
  static String? _lastMsgId;

  // ---------- Phase A: pre–runApp ----------
  static Future<void> initPreApp() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await NotificationService().initPreApp();
    log('[FCM] ✅ Pre-app initialization complete');
    // Background handler
    FirebaseMessaging.onBackgroundMessage(_bgHandler);
    checkAPNSEnvironment();
  }

  @pragma('vm:entry-point')
  static Future<void> _bgHandler(RemoteMessage m) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('isBackgoundNotificaitonComing', "yesfirst");
    log('[FCM] 🌙 Background message received: ${m.messageId}');
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Increment badge for background notification
    await NotificationService().incrementBadge();
    await NotificationService().showNotification(m);
  }

  // ---------- Phase B: post–runApp ----------
  // static Future<void> bindAfterRunApp({required GlobalKey<NavigatorState> navKey}) async {
  //   if (_bound) return;
  //   _bound = true;
  //
  //   log('[FCM] 🔧 Binding after runApp');
  //
  //   // 1) Request notification permissions (iOS shows dialog)
  //   final settings = await FirebaseMessaging.instance.requestPermission(
  //       alert: true,
  //       badge: true,
  //       sound: true
  //   );
  //   log('[FCM] 📱 Notification permission: ${settings.authorizationStatus}');
  //
  //   // 2) Enable iOS foreground notification presentation
  //   await NotificationService().enableIOSForegroundPresentation();
  //
  //   // 3) Register FCM token with backend
  //   final userPrefs = UserPreferencesViewmodel();
  //   await userPrefs.init();
  //   final user = await userPrefs.getUser();
  //   final authToken = user?.token;
  //
  //   final token = await FirebaseMessaging.instance.getToken();
  //   if (authToken != null && token != null) {
  //     log('[FCM] 📲 Registering FCM token');
  //     await FCMService.registerFCMToken(token, authToken);
  //   }
  //
  //   // Listen for token refresh
  //   FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
  //     log('[FCM] 🔄 Token refreshed');
  //     if (authToken != null) {
  //       await FCMService.registerFCMToken(t, authToken);
  //     }
  //   });
  //
  //   // 4) Subscribe to topic
  //   await FirebaseMessaging.instance.subscribeToTopic('ConnectApp');
  //   log('[FCM] 📢 Subscribed to ConnectApp topic');
  //
  //   // 5) Handle foreground messages (app is open)
  //   FirebaseMessaging.onMessage.listen((m) async {
  //     log('[FCM] 📨 Foreground message received: ${m.messageId}');
  //
  //     // De-duplicate messages
  //     if (m.messageId != null && m.messageId == _lastMsgId) {
  //       log('[FCM] ⚠️ Duplicate message, skipping');
  //       return;
  //     }
  //     _lastMsgId = m.messageId;
  //
  //     // Show notification
  //     await NotificationService().showNotification(m);
  //   });
  //
  //   // Note: onMessageOpenedApp and getInitialMessage are handled in main.dart
  //   // to ensure proper navigation timing with the widget tree
  //
  //   log('[FCM] ✅ Post-app binding complete');
  // }

  static Future<void> bindAfterRunApp(
      {required GlobalKey<NavigatorState> navKey}) async {
    if (_bound) return;
    _bound = true;

    log('[FCM] 🔧 Binding after runApp');

    // 1) Request notification permissions
    final settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
    log('[FCM] 📱 Notification permission: ${settings.authorizationStatus}');

    // 2) Enable iOS foreground notification presentation
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final userPrefs = UserPreferencesViewmodel();
    await userPrefs.init();
    final user = await userPrefs.getUser();
    final authToken = user?.token;

    final token = await FirebaseMessaging.instance.getToken();
    if (authToken != null && token != null) {
      log('[FCM] 📲 Registering FCM token');
      await FCMService.registerFCMToken(token, authToken);
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      log('[FCM] 🔄 Token refreshed');
      if (authToken != null) {
        await FCMService.registerFCMToken(t, authToken);
      }
    });

    // 3) Handle foreground messages
    FirebaseMessaging.onMessage.listen((m) async {
      log('[FCM] 📨 Foreground message received: ${m.messageId}');

      // De-duplicate messages
      if (m.messageId != null && m.messageId == _lastMsgId) {
        log('[FCM] ⚠️ Duplicate message, skipping');
        return;
      }
      _lastMsgId = m.messageId;

      // ✅ Use unified badge increment
      // await NotificationService().incrementBadge();

      await NotificationService().syncFromNative();

      // Show notification
      await NotificationService().showNotification(m);
    });

    // 4) Handle background messages that are delivered when app is in foreground
    FirebaseMessaging.onMessageOpenedApp.listen((m) async {
      log('[FCM] 📲 App opened from background via notification');

      // Handle navigation
      _navigateFromMessage(m);
    });

    log('[FCM] ✅ Post-app binding complete');
  }

  static Future<void> checkAPNSEnvironment() async {
    if (Platform.isIOS) {
      try {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        log('[FCM] 🍎 APNS Token: $apnsToken');

        if (apnsToken == null) {
          log('[FCM] ❌ NO APNS TOKEN - Check certificate and provisioning profile');
        } else {
          log('[FCM] ✅ APNS Token obtained successfully');

          log('[FCM] 🔍 Token length: ${apnsToken.length}');
        }
      } catch (e) {
        log('[FCM] ❌ Error getting APNS token: $e');
      }
    }
  }

  // ---------- Navigation Helper ----------
  // This is kept here for consistency but actual navigation
  static Future<void> _navigateFromMessage(RemoteMessage m) async {
    if (_navLocked) {
      log('[FCM] ⚠️ Navigation locked, skipping');
      return;
    }
    _navLocked = true;

    try {
      // Ensure auth is loaded
      final userPrefs = UserPreferencesViewmodel();
      await userPrefs.init();
      final user = await userPrefs.getUser();
      final token = user?.token;

      if (token == null || token.isEmpty) {
        log('[FCM] ⚠️ No auth token, redirecting to login');
        Get.offAllNamed(RouteName.loginScreen);
        _navLocked = false;
        return;
      }

      // Use the central global navigator function
      navigateFromMessage(m);
    } catch (e, st) {
      log('[FCM] ❌ Navigation error: $e\n$st');
      Get.toNamed(RouteName.homeScreen);
    } finally {
      _navLocked = false;
    }
  }
}
