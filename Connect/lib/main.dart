// main.dart (updated)
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:connectapp/firebase_options.dart';
import 'package:connectapp/models/message_cache_service.dart';
import 'package:connectapp/repository/fcm_manager.dart';
import 'package:connectapp/res/color/app_colors.dart';
import 'package:connectapp/res/routes/routes_name.dart';
import 'package:connectapp/utils/notification_mute_manager.dart';
import 'package:connectapp/view/message/badge_manager.dart';
import 'package:connectapp/view_models/controller/signup/signup_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'models/chat_cache_service.dart';
import 'res/constant/myconst.dart';
import 'res/getx_localization/language.dart';
import 'res/routes/routes.dart';
import 'view/message/applifecycle.dart';
import 'view/message/backgroundservice.dart';
import 'view/message/notificationservice.dart';
import 'view_models/controller/language/language_controller.dart';
import 'view_models/controller/notification/notification_controller.dart';
import 'view_models/controller/themeController/theme_controller.dart';
import 'view_models/controller/userPreferences/user_preferences_screen.dart';
import 'view_models/controller/useravatar/user_avatar_controller.dart';

/// Global captured initial message (set before runApp)
RemoteMessage? gInitialFcmMessage;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('[MAIN] Background FCM received');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
bool isDeepLinkHandled = false;
bool isInitialNavigationComplete = false;
Timer? _initialNavTimer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  log('[MAIN] Widgets binding initialized');

  final prefs = await SharedPreferences.getInstance();
  // final savedBadge = prefs.getInt('badge_total') ?? 0;
  // if (Platform.isIOS) {
  //   log('[MAIN] Applying saved badge on iOS → $savedBadge');
  //   await NotificationService().updateBadge(savedBadge: savedBadge);
  // }

  await FcmManager.initPreApp();
  log('[MAIN] FCM pre-app init done');

  Get.put(prefs);
  Get.put(NotificationController());
  Get.lazyPut<UserAvatarController>(() => UserAvatarController(), fenix: true);
  Get.lazyPut<LanguageController>(() => LanguageController(), fenix: true);
  Get.lazyPut<ThemeController>(() => ThemeController(), fenix: true);
  log('[MAIN] GetX dependencies registered');

  String? languageCode = prefs.getString('language_code');
  String? countryCode = prefs.getString('country_code');
  Locale savedLocale = (countryCode != null && languageCode != null)
      ? Locale(languageCode, countryCode)
      : const Locale('en', 'US');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  log('[MAIN] Firebase initialized');

  await GetStorage.init();
  await NotificationMuteUtil.init();
  log('[MAIN] GetStorage and NotificationMuteUtil initialized');

  if (Myconst.publicKey.isNotEmpty) {
    Stripe.publishableKey = Myconst.publicKey;
    await Stripe.instance.applySettings();
    log('[MAIN] Stripe initialized');
  }

  await ChatCacheService.init();
  await MessageCacheService.init();
  log('[MAIN] Cache services initialized');

  // capture initial message if app launched from terminated via FCM
  try {
    gInitialFcmMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (gInitialFcmMessage != null) {
      log('[MAIN] 🔔 Captured initial FCM message for killed state navigation');
    }
  } catch (e) {
    log('[MAIN] Failed to capture initial FCM message: $e');
  }

  await NotificationService().initPreApp();

  log('[APP] Current Firebase config: ${DefaultFirebaseOptions.currentPlatform}');

  final isMuted = await NotificationMuteUtil.isMuted();
  if (isMuted) {
    log('🔇 NOTIFICATIONS ARE MUTED LOCALLY - THIS BLOCKS ALL NOTIFICATIONS');
  }

  runApp(MyApp(savedLocale));
  log('[MAIN] runApp completed');

  final BadgeManager badgeManager = BadgeManager();

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await badgeManager.initialize();
  });
}
//
// void navigateFromMessage(RemoteMessage message) {
//   try {
//     if (isDeepLinkHandled) {
//       log("[NAV] ❌ Skipping FCM navigation — deep link already handled");
//       return;
//     }
//
//     final data = message.data;
//     log('[NAV] 📦 Processing message data: $data');
//
//     // Extract common parameters
//     final type = (data['type'] ?? '').toLowerCase();
//     final chatId = (data['chatId'] ?? '').trim();
//     final fromUserId = (data['fromUserId'] ?? '').trim();
//     final clipId = (data['clipId'] ?? '').trim();
//
//     isDeepLinkHandled = true;
//     isInitialNavigationComplete = true;
//
//     // Cancel any pending navigation timer
//     _initialNavTimer?.cancel();
//
//     // Handle different message types
//     if (type == 'chat' && chatId.isNotEmpty) {
//       log('[NAV] 💬 Navigating to chat: $chatId');
//       _navigateToChat(chatId, data);
//     }
//     else if (type == 'social') {
//       log('[NAV] 👥 Handling social notification');
//       _handleSocialNotification(data, fromUserId, clipId);
//     }
//     else {
//       log('[NAV] 🏠 Default navigation to home');
//       _navigateToHome();
//     }
//
//   } catch (e, stack) {
//     log('[NAV] ❌ Navigation error: $e\n$stack');
//     _navigateToHome(); // Fallback
//   }
// }

void navigateFromMessage(RemoteMessage message) {
  try {
    if (isDeepLinkHandled) {
      log("[NAV] ❌ Skipping FCM navigation — deep link already handled");
      return;
    }

    final data = message.data;
    final payloadData = jsonDecode(data['payload']);
    log('[NAV] 📦 Processing message data: $data');

    // Extract common parameters
    // final type = (data['type'] ?? '').toLowerCase();
    final type = (payloadData['type']).toString().toLowerCase();
    final chatId = (payloadData['chat_id'])
        .toString()
        .trim(); //(data['chatId'] ?? '').trim();
    final fromUserId = (data['fromUserId'] ?? '').trim();
    final clipId = (data['clipId'] ?? '').trim();

    isDeepLinkHandled = true;
    isInitialNavigationComplete = true;

    // Cancel any pending navigation timer
    _initialNavTimer?.cancel();

    // Handle different message types
    if (type == 'chat') {
      final senderId = (payloadData['sender_id'])
          .toString()
          .trim(); //(data['chatId'] ?? '').trim();
      final groupName = (payloadData['groupName'])
          .toString()
          .trim(); //(data['groupName'] ?? '').trim();
      if (senderId.isNotEmpty) {
        Get.offAllNamed(RouteName.bottomNavbar, arguments: {
          'chatId': chatId,
          'isfromnoticlick': true,
          'open_tab': 1,
        });
      } else if (groupName.isNotEmpty) {
        Get.offAllNamed(RouteName.bottomNavbar, arguments: {
          'chatId': chatId,
          'isfromnoticlick': true,
          'open_tab': 1,
        });
      }
      isDeepLinkHandled = false;
      return;
    }

    if (type == 'social') {
      log('[NAV] 👥 Handling social notification');
      _handleSocialNotification(data, fromUserId, clipId);
    } else {
      log('[NAV] 🏠 Default navigation to home');
      _navigateToHome();
    }
  } catch (e, stack) {
    log('[NAV] ❌ Navigation error: $e\n$stack');
    _navigateToHome(); // Fallback
  }
}

// ✅ NEW: Dedicated chat navigation
void _navigateToChat(String chatId, Map<String, dynamic> data) {
  try {
    Get.offAllNamed(RouteName.chatscreen, arguments: {
      'chatId': chatId,
      'isfromnoticlick': true,
      'notificationData': data,
    });
    log('[NAV] ✅ Successfully navigated to chat: $chatId');
  } catch (e) {
    log('[NAV] ❌ Chat navigation failed: $e');
    _navigateToHome();
  }
}

void _handleSocialNotification(
    Map<String, dynamic> data, String fromUserId, String clipId) {
  final title = (data['title'] ?? '').toLowerCase();
  final msg = (data['message'] ?? '').toLowerCase();

  if (title.contains('follower') || msg.contains('started following you')) {
    if (fromUserId.isNotEmpty) {
      Get.offAllNamed(RouteName.clipProfieScreen, arguments: fromUserId);
    } else {
      _navigateToHomeWithSnackbar('Follower details not available');
    }
  } else if (title.contains('comment') || msg.contains('commented')) {
    if (clipId.isNotEmpty) {
      Get.offAllNamed(RouteName.clipPlayScreen, arguments: clipId);
    } else {
      _navigateToHomeWithSnackbar('Clip details not found');
    }
  } else {
    _navigateToHome();
  }
}

// ✅ NEW: Home navigation with snackbar
void _navigateToHomeWithSnackbar(String message) {
  Get.offAllNamed(RouteName.homeScreen);
  // Show snackbar after navigation completes
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Get.snackbar('Info', message);
  });
}

// ✅ NEW: Simple home navigation
void _navigateToHome() {
  Get.offAllNamed(RouteName.homeScreen);
}

class MyApp extends StatefulWidget {
  final Locale initialLocale;

  const MyApp(this.initialLocale, {super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late FirebaseMessaging messaging;
  StreamSubscription<Uri?>? _sub;
  bool _initialUriHandled = false;

  @override
  void initState() {
    super.initState();
    log('[APP] _MyAppState initState');

    WidgetsBinding.instance.addObserver(this);
    AppLifecycleService().initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      log('[APP] Post-frame callback running');
      await FcmManager.bindAfterRunApp(navKey: navKey);
      BackgroundService.initialize();
      await _initDeepLinks();

      // ✅ IMPROVED: Handle initial FCM with proper timing
      _handleInitialFcmMessage();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  // ✅ NEW: Dedicated initial FCM handler
  Future<void> _handleInitialFcmMessage() async {
    if (gInitialFcmMessage == null || isDeepLinkHandled) {
      log('[APP] No initial FCM message or already handled');
      return;
    }

    log('[APP] 🚀 Processing initial FCM message from killed state');

    // Wait for essential services to initialize
    await Future.delayed(const Duration(milliseconds: 1500));

    try {
      // Ensure user preferences are loaded
      if (!Get.isRegistered<UserPreferencesViewmodel>()) {
        await Get.putAsync(() async {
          final u = UserPreferencesViewmodel();
          await u.init();
          return u;
        });
      }

      // Double-check we haven't already handled navigation
      if (!isDeepLinkHandled && gInitialFcmMessage != null) {
        log('[APP] ✅ Navigating from killed state FCM message');
        navigateFromMessage(gInitialFcmMessage!);
      } else {
        log('[APP] ⚠️ Initial FCM already handled by another process');
      }
    } catch (e, st) {
      log('[APP] ❌ Error handling initial FCM: $e\n$st');
      _navigateToHome(); // Fallback
    } finally {
      gInitialFcmMessage = null; // Clear to prevent reuse
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      log('[APP] 🔄 App resumed - syncing badge');
      _syncBadgeOnResume();
    }
  }

  // ✅ NEW: Badge sync on app resume
  Future<void> _syncBadgeOnResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBadge = prefs.getInt('badge_total') ?? 0;

      log('[APP] 🔄 Syncing badge on resume: $savedBadge');

      // Also sync with native iOS
      if (Platform.isIOS) {
        final MethodChannel badgeChannel =
            MethodChannel('com.connect/iosBadge');
        final nativeBadge = await badgeChannel.invokeMethod<int>('getBadge');
        log('[APP] 📱 Native badge count: $nativeBadge');

        // If there's a discrepancy, use the higher value
        if (nativeBadge != null && nativeBadge != savedBadge) {
          final correctBadge =
              nativeBadge > savedBadge ? nativeBadge : savedBadge;
          await prefs.setInt('badge_total', correctBadge);
          await NotificationService().updateBadge(savedBadge: savedBadge);
          log('[APP] 🔄 Corrected badge count: $correctBadge');
        }
      }
    } catch (e) {
      log('[APP] ❌ Error syncing badge on resume: $e');
    }
  }

  Future<void> _initDeepLinks() async {
    if (_initialUriHandled) return;
    _initialUriHandled = true;
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) _handleIncomingLink(initialUri);
    } on PlatformException {
      log('[APP] Failed to get initial URI');
    } on FormatException catch (err) {
      log('[APP] Malformed initial URI: $err');
    }

    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) _handleIncomingLink(uri);
    }, onError: (err) => log('[APP] Error in deep link stream: $err'));
  }

  void _handleIncomingLink(Uri uri) {
    try {
      log('🔗 Incoming deep link: $uri');
      final signupCtrl = Get.put(SignupController(), permanent: true);

      if (uri.path.startsWith('/app/register')) {
        final refCode = uri.queryParameters['ref']?.trim();
        Get.toNamed(
          RouteName.signupScreen,
          arguments:
              refCode?.isNotEmpty == true ? {'referralCode': refCode} : null,
        );
        if (refCode?.isNotEmpty == true) signupCtrl.saveReferralCode(refCode!);
      } else if (uri.path.startsWith('/course') ||
          uri.path.startsWith('/course-details')) {
        final courseId =
            uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        if (courseId?.isNotEmpty == true) {
          Get.toNamed(RouteName.viewDetailsOfCourses,
              arguments: {'courseId': courseId});
        }
      } else if (uri.path.startsWith('/clip') ||
          uri.path.startsWith('/clips')) {
        final clipId =
            uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        if (clipId?.isNotEmpty == true) {
          Get.toNamed(RouteName.clipPlayScreen, arguments: {'clipId': clipId});
        }
      } else if (uri.path.startsWith('/chats') ||
          uri.path.startsWith('/chat')) {
        final chatId = uri.queryParameters['chatId']?.trim();
        final userId = uri.queryParameters['userId']?.trim();
        if (chatId?.isNotEmpty == true) {
          Get.toNamed(RouteName.chatscreen, arguments: {'chatId': chatId});
        } else if (userId?.isNotEmpty == true) {
          Get.toNamed(RouteName.chatProfileScreen,
              arguments: {'userId': userId});
        }
      } else if (uri.path.startsWith('/others')) {
        final spaceId = uri.queryParameters['spaceId']?.trim();
        if (spaceId?.isNotEmpty == true) {
          Get.toNamed(RouteName.joinMeeting, arguments: {'spaceId': spaceId});
        }
      } else {
        log('⚠️ Unrecognized deep link path: ${uri.path}');
      }
    } catch (e, st) {
      log('❌ Error handling deep link: $e\n$st');
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(const SnackBar(
          content: Text('Failed to open deep link'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = Get.find<ThemeController>();
    final LanguageController lang = Get.find<LanguageController>();

    return Obx(() => GetMaterialApp(
          translations: Language(),
          locale: lang.currentLocale.value,
          fallbackLocale: const Locale('en', 'US'),
          debugShowCheckedModeBanner: false,
          getPages: AppRoutes.appRoutes(),
          theme: theme.lightTheme,
          navigatorKey: navKey,
          darkTheme: theme.darkTheme,
          themeMode: theme.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
        ));
  }

  void _handleNotificationTapFromPayload(Map<String, dynamic> data) async {
    log('[APP] 🔍 Handling payload: $data');
    await Future.delayed(const Duration(milliseconds: 300));

    if (!Get.isRegistered<UserPreferencesViewmodel>()) {
      await Get.putAsync(() async {
        final u = UserPreferencesViewmodel();
        await u.init();
        return u;
      });
    }

    if (data.containsKey('chatId')) {
      final chatId = data['chatId'];
      Get.offAllNamed(RouteName.chatscreen, arguments: {'chatId': chatId});
      return;
    }

    Get.offAllNamed(RouteName.homeScreen);
  }
}
