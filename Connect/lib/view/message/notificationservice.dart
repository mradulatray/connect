import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../main.dart';
import '../../res/routes/routes_name.dart';
import 'badge_manager.dart';

enum MediaType { image, video, document, audio, text }

class ProcessedMessage {
  final String displayText;
  final MediaType mediaType;
  final String? mediaUrl;
  ProcessedMessage(this.displayText, this.mediaType, this.mediaUrl);
}

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final BadgeManager badgeManager = BadgeManager();

  Future<void> initPreApp() async {
    if (_initialized) return;
    log('[NOTIFICATION] Initializing local notifications...');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    const init = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      init,
      onDidReceiveNotificationResponse: _onTapLocal,
      onDidReceiveBackgroundNotificationResponse: _onTapLocalBg,
    );

    await _createAndroidChannels();

    // Request permissions
    await requestNotificationPermissions();

    _initialized = true;
    log('[NOTIFICATION] Initialization complete.');
  }

  Future<void> initializeBadgeOnStart() async {
    try {
      final savedBadge = badgeManager.getCurrentBadge();

      log('[NOTIFICATION] 🔄 Initializing badge on before reset app start: $savedBadge');
      await badgeManager.resetBadge();
    } catch (e) {
      log('[NOTIFICATION] ❌ Error initializing badge: $e');
    }
  }

  Future<void> incrementBadge({int by = 1}) async {
    await badgeManager.incrementBadge(by: by);
  }

  Future<void> decrementBadge({int by = 1, bool removeAtZero = true}) async {
    await badgeManager.decrementBadge(by: by, removeAtZero: removeAtZero);
  }

  Future<void> resetBadge() async {
    await badgeManager.resetBadge();
  }

  Future<void> updateBadgeCount(int newCount) async {
    await badgeManager.updateBadge(newCount);
  }

  Future<int> getCurrentBadgeCount() async {
    return await badgeManager.getCurrentBadge();
  }

  Future<void> setupFirebaseListeners() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('[NOTIFICATION] 🔥 Foreground message received');
      showNotification(message);
    });

    // Background and terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('[NOTIFICATION] 🔥 App opened from background/terminated');
      navigateFromMessage(message);
    });

    // Get initial message when app is opened from terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      log('[NOTIFICATION] 🔥 Initial message found');
      navigateFromMessage(initialMessage);
    }

    // Configure settings
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
  }

  Future<int> getNativeBadgeCount() async {
    if (!Platform.isIOS) return 0;

    return badgeManager.getCurrentBadge();
  }

  Future<void> showNotification(RemoteMessage m) async {
    log('[NOTIFICATION] Showing notification for messageId: ${m.messageId}');
    final data = m.data;
    final title = m.notification?.title ?? data['title'] ?? 'Notification';
    final body = m.notification?.body ?? data['message'] ?? data['body'] ?? '';

    final payload = jsonEncode({
      ...data,
      'notificationId': m.messageId ?? '',
      'title': title,
      'body': body,
    });

    if (data['chatId'] != null) {
      log('[NOTIFICATION] Detected chat message. Showing chat notification.');
      await showMessageNotification(
        chatId: data['chatId'].toString(),
        senderName: data['senderName']?.toString() ?? title,
        message: body,
        isGroup: data['isGroup'] == true || data['isGroup'] == 'true',
        groupName: data['groupName']?.toString(),
        payload: payload,
      );
    } else {
      log('[NOTIFICATION] General notification.');
      await _showGeneralNotification(title, body, payload);
    }
  }

  Future<void> showMessageNotification({
    required String chatId,
    required String senderName,
    required String message,
    required bool isGroup,
    String? groupName,
    String? payload,
  }) async {
    final id = chatId.hashCode;
    final title = isGroup ? '$senderName in $groupName' : senderName;

    final processed = _process(message);
    final imagePath = await _downloadIfImage(processed);

    final android = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      styleInformation: imagePath != null
          ? BigPictureStyleInformation(FilePathAndroidBitmap(imagePath),
              contentTitle: title, summaryText: processed.displayText)
          : null,
    );

    final badge = (await _nextBadge());
    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: badge,
      subtitle: _subtitle(processed.mediaType),
    );

    log('[NOTIFICATION] Showing chat notification → $title');
    await _plugin.show(
      id,
      title,
      processed.displayText,
      NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }

  Future<void> requestNotificationPermissions() async {
    try {
      if (Platform.isIOS) {
        final bool? result = await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        log('[NOTIFICATION] iOS permission request result: $result');
      } else if (Platform.isAndroid) {
        // For Android 13+, you might need to request POST_NOTIFICATIONS permission
        // You can use permission_handler package for this
      }
    } catch (e) {
      log('[NOTIFICATION] Error requesting permissions: $e');
    }
  }

  Future<void> syncBadgeToNative(int count) async {
    try {
      log('[NOTIFICATION] 🔄 Syncing badge to native → $count');

      // Update native iOS via method channel
      if (Platform.isIOS) {
        badgeManager.updateBadge(count);
      }

      // For Android, use FlutterAppBadger if needed
      if (Platform.isAndroid && await FlutterAppBadger.isAppBadgeSupported()) {
        if (count <= 0) {
          FlutterAppBadger.removeBadge();
        } else {
          FlutterAppBadger.updateBadgeCount(count);
        }
        log('[NOTIFICATION] ✅ Android badge updated → $count');
      }
    } catch (e) {
      log('[NOTIFICATION] ❌ Error syncing badge to native: $e');
    }
  }

  Future<void> _showGeneralNotification(
      String title, String body, String payload) async {
    final processed = _process(body);
    final imagePath = await _downloadIfImage(processed);

    final android = AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      styleInformation: imagePath != null
          ? BigPictureStyleInformation(FilePathAndroidBitmap(imagePath),
              contentTitle: title, summaryText: body)
          : null,
    );

    final badge = (await _nextBadge());
    final ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: badge,
      subtitle: _subtitle(processed.mediaType),
    );

    log('[NOTIFICATION] Showing general notification → $title');
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      processed.displayText,
      NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }

  Future<void> clearChatNotifications(String chatId) async {
    log('[NOTIFICATION] Clearing chat notifications for chatId: $chatId');
    await _plugin.cancel(chatId.hashCode);
  }

  Future<void> syncFromNative() async {
    if (!Platform.isIOS) return;

    try {
      final nativeBadge = badgeManager.getCurrentBadge();

      log('[NOTIFICATION] 🔄 Synced from native iOS → $nativeBadge');
    } catch (e) {
      log('[NOTIFICATION] ❌ Error syncing from native: $e');
    }
  }

  static void initializeBadgeSync() {
    if (!Platform.isIOS) return;

    final MethodChannel badgeChannel = MethodChannel('com.connect/iosBadge');
    badgeChannel.setMethodCallHandler((call) async {
      if (call.method == 'syncBadgeFromNative') {
        try {
          final count = call.arguments['count'] as int;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('badge_total', count);
          log('[NOTIFICATION] 🔄 Badge synced FROM native → $count');
        } catch (e) {
          log('[NOTIFICATION] ❌ Error in syncBadgeFromNative: $e');
        }
      }
      return null;
    });
  }

  Future<int> _nextBadge() async {
    badgeManager.incrementBadge();

    return badgeManager.getCurrentBadge();
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    log('[NOTIFICATION] Creating Android notification channels');
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Notifications for chat messages',
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.high,
    ));
  }

  ProcessedMessage _process(String text) {
    final urlMatch = RegExp(r'(https?:\/\/[^\s]+)').firstMatch(text);
    final url = urlMatch?.group(0);
    MediaType t = MediaType.text;
    if (RegExp(r'\.(png|jpg|jpeg|gif|webp)\$', caseSensitive: false)
        .hasMatch(text))
      t = MediaType.image;
    else if (RegExp(r'\.(mp4|mov|mkv)\$', caseSensitive: false).hasMatch(text))
      t = MediaType.video;
    else if (RegExp(r'\.(pdf|docx?|xlsx?|pptx?)\$', caseSensitive: false)
        .hasMatch(text))
      t = MediaType.document;
    else if (RegExp(r'\.(mp3|wav|aac|m4a)\$', caseSensitive: false)
        .hasMatch(text)) t = MediaType.audio;

    String display = text;
    if (t == MediaType.image) display = '📷 Image';
    if (t == MediaType.video) display = '🎥 Video';
    if (t == MediaType.document) display = '📄 Document';
    if (t == MediaType.audio) display = '🎵 Audio';
    return ProcessedMessage(display, t, url);
  }

  Future<String?> _downloadIfImage(ProcessedMessage p) async {
    if (p.mediaType != MediaType.image || p.mediaUrl == null) return null;
    try {
      final res = await http.get(Uri.parse(p.mediaUrl!));
      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file =
            File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(res.bodyBytes);
        log('[NOTIFICATION] Image downloaded for notification');
        return file.path;
      }
    } catch (e) {
      log('[NOTIFICATION] Failed to download image: $e');
    }
    return null;
  }

  String _subtitle(MediaType t) {
    switch (t) {
      case MediaType.image:
        return 'Sent an image';
      case MediaType.video:
        return 'Sent a video';
      case MediaType.document:
        return 'Sent a document';
      case MediaType.audio:
        return 'Sent an audio';
      case MediaType.text:
        return 'New message';
    }
  }

  Future<void> updateBadge({required int savedBadge}) async {
    try {
      await syncBadgeToNative(savedBadge);
    } catch (e) {
      log('[NOTIFICATION] ❌ Error in updateBadge: $e');
    }
  }

  void _onTapLocal(NotificationResponse r) async {
    log('[NOTIFICATION] 📲 =============== FOREGROUND TAP ===============');
    log('[NOTIFICATION] 📲 Payload: ${r.payload}');

    try {
      await decrementBadge(); // ⬅️ CHANGED: was incBadge()

      if (r.payload == null || r.payload!.isEmpty) {
        log('[NOTIFICATION] ⚠️ Empty payload');
        navKey.currentState?.pushNamed(RouteName.homeScreen);
        return;
      }

      final data = Map<String, dynamic>.from(jsonDecode(r.payload!));
      final fakeMessage = RemoteMessage(data: data);

      await Future.delayed(const Duration(milliseconds: 800));

      log('[NOTIFICATION] 🚀 Calling navigateFromMessage...');
      navigateFromMessage(fakeMessage);
    } catch (e, st) {
      log('[NOTIFICATION] ❌ Error: $e\n$st');
      navKey.currentState?.pushNamed(RouteName.homeScreen);
    }
  }

  @pragma('vm:entry-point')
  static void _onTapLocalBg(NotificationResponse r) async {
    log('[NOTIFICATION] 📦 =============== BACKGROUND TAP ===============');
    log('[NOTIFICATION] 📦 Payload: ${r.payload}');

    try {
      if (r.payload == null || r.payload!.isEmpty) {
        log('[NOTIFICATION] ⚠️ Empty background payload');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_notification_payload', r.payload!);

      final data = Map<String, dynamic>.from(jsonDecode(r.payload!));
      log('[NOTIFICATION] 📦 Parsed data: $data');

      final fakeMessage = RemoteMessage(data: data);

      await Future.delayed(const Duration(milliseconds: 1200));

      log('[NOTIFICATION] 🚀 Calling navigateFromMessage...');
      navigateFromMessage(fakeMessage);
    } catch (e, st) {
      log('[NOTIFICATION] ❌ Error: $e\n$st');
    }
  }
}
