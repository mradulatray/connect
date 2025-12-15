import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../res/api_urls/api_urls.dart';
import '../../res/routes/routes_name.dart';
import '../../view/message/notificationservice.dart';
import '../controller/userPreferences/user_preferences_screen.dart';
import '../../../main.dart';

class SplashServices {
  final UserPreferencesViewmodel userPreferencesViewmodel =
  UserPreferencesViewmodel();

  late AppLinks _appLinks;

  // Initialize and check everything
  void initSplash() async {
    log('[SPLASH] Initializing splash services');

    // ✅ CRITICAL: Don't interfere if we have an initial FCM message
    if (gInitialFcmMessage != null) {
      log('[SPLASH] ⏸️ Initial FCM message detected - pausing splash navigation');
      // Wait a bit to see if MyApp handles the navigation
      await Future.delayed(const Duration(seconds: 3));

      // If navigation still didn't happen, proceed with normal flow
      if (!isDeepLinkHandled) {
        log('[SPLASH] 🚨 FCM navigation failed, falling back to normal flow');
        await isLogin();
      } else {
        log('[SPLASH] ✅ FCM navigation handled by MyApp');
      }
      return;
    }

    // Normal splash flow for non-FCM launches
    await _handleDeepLinks();
    await isLogin();
  }

  // Handle deep links (moved from main.dart)
  Future<void> _handleDeepLinks() async {
    if (isDeepLinkHandled) {
      log('[SPLASH] Deep link already handled, skipping initialization');
      return;
    }

    try {
      log('[SPLASH] Initializing AppLinks');
      _appLinks = AppLinks();

      // Terminated app deep link
      final initialUri = await _appLinks.getLatestAppLink();
      if (initialUri != null) {
        log('[SPLASH] 🔗 Initial deep link: $initialUri');
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigateFromUri(initialUri);
        });
        return; // Don't proceed to login check
      }

      // Foreground deep link
      _appLinks.uriLinkStream.listen((uri) {
        log('[SPLASH] 🔗 Deep link received: $uri');
        _navigateFromUri(uri);
      }, onError: (err) {
        log('[SPLASH] Deep link stream error: $err');
      });
    } catch (e) {
      log('[SPLASH] Deep link init error: $e');
    }
  }

  // Navigate based on URI
  void _navigateFromUri(Uri uri) {
    if (isDeepLinkHandled) {
      log('[SPLASH] Deep link already handled, skipping');
      return;
    }

    try {
      log('[SPLASH] Navigating from URI: $uri');
      if (uri.scheme == 'https' || uri.scheme == 'http') {
        if (uri.pathSegments.isNotEmpty) {
          final segments = uri.pathSegments.map((s) => s.toLowerCase()).toList();

          String? idFromPath;

          if (segments.length >= 1) {
            final last = segments.last;

            if (!['course', 'course-details', 'courses', 'details',
              'clip', 'clips', 'clip-details']
                .contains(last)) {
              idFromPath = last;
            }
          }

          final idFromQuery = uri.queryParameters['id'];

          final id = idFromPath ?? idFromQuery;

          if (id != null) {
            final type = segments.first;

            if (['course', 'course-details', 'courses', 'details']
                .contains(type)) {
              log('[SPLASH] Navigating to course details: $id');
              isDeepLinkHandled = true;
              Get.offAllNamed(RouteName.viewDetailsOfCourses, arguments: id);
              return;
            }

            if (['clip', 'clips', 'clip-details']
                .contains(type)) {
              log('[SPLASH] Navigating to clip: $id');
              isDeepLinkHandled = true;
              Get.offAllNamed(RouteName.clipPlayScreen, arguments: id);
              return;
            }
          }
        }
      }

      if (uri.scheme == 'connectapp') {
        final host = uri.host.toLowerCase();
        final idFromQuery = uri.queryParameters['id'];
        final segments = uri.pathSegments;

        final idFromPath = segments.isNotEmpty ? segments.last : null;

        final id = idFromQuery ?? idFromPath;

        if (id != null) {
          if (['course', 'course-details', 'courses', 'details']
              .contains(host)) {

            log('[SPLASH] Navigating (custom scheme) to course: $id');
            isDeepLinkHandled = true;
            Get.offAllNamed(RouteName.viewDetailsOfCourses, arguments: id);
            return;
          }

          // CLIP TYPES
          if (['clip', 'clips', 'clip-details']
              .contains(host)) {

            log('[SPLASH] Navigating (custom scheme) to clip: $id');
            isDeepLinkHandled = true;
            Get.offAllNamed(RouteName.clipPlayScreen, arguments: id);
            return;
          }
        }
      }


      log('[SPLASH] No matching deep link route found');
    } catch (e) {
      log('[SPLASH] Deep link navigation error: $e');
    }
  }

  // Login + role check
  Future<void> isLogin() async {
    // Don't proceed if navigation already happened
    if (isDeepLinkHandled) {
      log('[SPLASH] Navigation already handled, skipping login check');
      return;
    }

    try {
      log('[SPLASH] Checking user login state');
      final user = await userPreferencesViewmodel.getUser();

      if (user == null || user.token.isEmpty) {
        log('[SPLASH] User not found or token empty. Redirecting to login');
        Timer(const Duration(seconds: 1), () {
          if (!isDeepLinkHandled) {
            Get.offAllNamed(RouteName.loginScreen);
          }
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken') ?? user.token;
      log('[SPLASH] Fetched token: ${token.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse('${ApiUrls.baseUrl}/connect/v1/api/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      log('[SPLASH] Profile fetch status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final role = jsonResponse['role'];

        log('[SPLASH] User role: $role');

        Timer(const Duration(seconds: 1), () {
          // Double check no navigation happened during API call
          if (!isDeepLinkHandled) {
            if (role == 'Creator') {
              log('[SPLASH] Navigating to Creator BottomBar');
              Get.offAllNamed(RouteName.creatorBottomBar);
            } else {
              log('[SPLASH] Navigating to BottomNavbar');
              Get.offAllNamed(RouteName.bottomNavbar);
            }
          }
        });
      } else {
        log('[SPLASH] Profile fetch failed. Navigating to login');
        Timer(const Duration(seconds: 1), () {
          if (!isDeepLinkHandled) {
            Get.offAllNamed(RouteName.loginScreen);
          }
        });
      }
    } catch (e) {
      log('[SPLASH] Error during login check: $e');
      Timer(const Duration(seconds: 2), () {
        if (!isDeepLinkHandled) {
          Get.offAllNamed(RouteName.loginScreen);
        }
      });
    }
  }
}