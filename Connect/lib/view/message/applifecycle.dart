import 'package:connectapp/res/routes/routes_name.dart';
import 'package:connectapp/view/message/notificationservice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

class AppLifecycleService with WidgetsBindingObserver {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  /// Global flag to detect if deep link navigation is happening
  static bool isDeepLinkActive = false;

  /// Initialize lifecycle observer
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
    log('🔄 [AppLifecycle] Service initialized');
  }

  /// Dispose lifecycle observer
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    log('🧹 [AppLifecycle] Service disposed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _updateLastActiveTime(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
        
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      default:
        break;
    }
  }

  /// Save last active time for presence tracking or analytics
  Future<void> _updateLastActiveTime(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_active_time', DateTime.now().millisecondsSinceEpoch);
      log('🕓 [AppLifecycle] Updated last active time');
    }
  }

  /// Handle app inactive event (transitioning to background)
  Future<void> _onAppInactive() async {
    log('⏸️ [AppLifecycle] App inactive');

    // await NotificationService.syncBadgeWithNative();
    // Don't increment badge here - it's incremented when notification is received
  }

  /// Handle app resume event
  Future<void> _onAppResumed() async {
    log('📱 [AppLifecycle] App resumed');

    // Restore badge count from persistent storage
    final prefs = await SharedPreferences.getInstance();
    final savedBadge = prefs.getInt('badge_total') ?? 0;

    log('🔢 [AppLifecycle] Restoring badge count: $savedBadge');
    await NotificationService().updateBadge(savedBadge: savedBadge);
    // await NotificationService.syncBadgeWithNative();

    // Check current route
    final currentRoute = Get.currentRoute;
    log('📍 [AppLifecycle] Current route: $currentRoute');

    // Don't redirect if deep link is active or user is on specific screens
    if (isDeepLinkActive ||
        currentRoute == RouteName.clipPlayScreen ||
        currentRoute == RouteName.chatscreen) {
      log('⚠️ [AppLifecycle] Skipping auto-navigation');
      return;
    }

    // Optional: Clear badge if user is on home screen
    if (currentRoute == RouteName.homeScreen) {
      log('🏠 [AppLifecycle] On home screen, consider clearing badge');
      // Uncomment if you want to auto-clear badge when user returns to home
      // await NotificationService().clearBadgeCount();
    }
  }

  /// Handle app paused (background) event
  Future<void> _onAppPaused() async {
    log('🌙 [AppLifecycle] App paused - background notifications enabled');
    // await NotificationService.getNativeBadgeCount();
  }

  /// Handle app detached (closed or killed)
  Future<void> _onAppDetached() async {
    log('🛑 [AppLifecycle] App detached');
  }
}