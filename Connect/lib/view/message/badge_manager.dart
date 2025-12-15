// badge_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class BadgeManager {
  static final BadgeManager _instance = BadgeManager._internal();
  factory BadgeManager() => _instance;
  BadgeManager._internal();

  static const String _badgeKey = 'badge_total_count';
  static const String _unreadCountsKey = 'unread_counts_calculated';
  static const String _lastSyncTimeKey = 'badge_last_sync_time';

  final MethodChannel _iosBadgeChannel = MethodChannel('com.connect/iosBadge');
  final Map<String, int> _unreadCounts = {};
  bool _isInitialized = false;
  Completer<void>? _initializationCompleter;

  // Add this for server sync
  final Map<String, DateTime> _lastReadTimes = {};

  // Public interface
  Map<String, int> get unreadCounts => Map.from(_unreadCounts);

  Future<void> initialize() async {
    if (_isInitialized) return;

    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();

    try {
      await _loadUnreadCounts();
      // Only sync badge if it's been more than 5 minutes since last sync
      // This prevents overwriting fresh counts with stale data
      if (await _shouldSyncWithServer()) {
        await _syncWithServer();
      } else {
        await _syncBadgeWithUnreadCounts();
      }
      _isInitialized = true;
      _initializationCompleter!.complete();
      developer.log('[BADGE] ✅ BadgeManager initialized with ${_unreadCounts.length} chats');
    } catch (e) {
      _initializationCompleter!.completeError(e);
      developer.log('[BADGE] ❌ Error initializing BadgeManager: $e');
    }
  }

  Future<void> syncWithServer() async {
    if (!_isInitialized) await initialize();

    try {
      // TODO: Call your API to get actual unread counts from server
      // This should replace the local counts with server counts
      // Example:
      // final serverCounts = await ChatApi.getUnreadCounts();
      // _unreadCounts.clear();
      // _unreadCounts.addAll(serverCounts);
      // await _saveUnreadCounts();
      // await _syncBadgeWithUnreadCounts();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncTimeKey, DateTime.now().millisecondsSinceEpoch);

      developer.log('[BADGE] 🔄 Synced unread counts with server');
    } catch (e) {
      developer.log('[BADGE] ❌ Error syncing with server: $e');
    }
  }

  Future<void> updateUnreadCount(String chatId, int newCount, {bool fromServer = false}) async {
    if (!_isInitialized) await initialize();

    final oldCount = _unreadCounts[chatId] ?? 0;
    _unreadCounts[chatId] = newCount;

    // If marking as read (newCount = 0), record the time
    if (newCount == 0 && oldCount > 0) {
      _lastReadTimes[chatId] = DateTime.now();
    }

    await _saveUnreadCounts();

    // Only sync badge if not from server (to avoid loops)
    if (!fromServer) {
      await _syncBadgeWithUnreadCounts();
    }

    developer.log('[BADGE] 🔢 Unread count updated for $chatId: $oldCount → $newCount');
  }

  Future<void> incrementUnreadCount(String chatId, {int by = 1}) async {
    if (!_isInitialized) await initialize();

    final current = _unreadCounts[chatId] ?? 0;
    await updateUnreadCount(chatId, current + by);
  }

  Future<void> syncUnreadCountsFromServer(Map<String, int> serverCounts) async {
    try {
      // Clear current counts
      _unreadCounts.clear();

      // Update with server counts
      _unreadCounts.addAll(serverCounts);

      // Save to local storage
      await _saveUnreadCounts();

      // Sync badge with native
      await _syncBadgeWithUnreadCounts();

      developer.log('[BADGE] ✅ Synced unread counts from server: ${serverCounts.length} chats');
    } catch (e) {
      developer.log('[BADGE] ❌ Error syncing from server: $e');
    }
  }

  Future<void> resetUnreadCount(String chatId) async {
    await updateUnreadCount(chatId, 0);
  }

  int getUnreadCount(String chatId) {
    return _unreadCounts[chatId] ?? 0;
  }

  int getTotalUnreadCount() {
    int total = 0;
    _unreadCounts.forEach((chatId, count) {
      total += count;
    });
    return total;
  }

  Future<void> updateBadge(int newCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_badgeKey, newCount);
      developer.log('[BADGE] 🔢 Badge updated: $newCount');

      await _syncToNative(newCount);
    } catch (e) {
      developer.log('[BADGE] ❌ Error updating badge: $e');
    }
  }

  Future<void> incrementBadge({int by = 1}) async {
    final current = await getCurrentBadge();
    await updateBadge(current + by);
  }

  Future<void> decrementBadge({int by = 1, bool removeAtZero = true}) async {
    final current = await getCurrentBadge();
    final newCount = current > 0 ? current - by : 0;

    if (newCount <= 0 && removeAtZero) {
      await resetBadge();
    } else {
      await updateBadge(newCount);
    }
  }

  Future<void> resetBadge() async {
    await updateBadge(0);
    developer.log('[BADGE] 🔁 Badge reset to 0');
  }

  Future<int> getCurrentBadge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_badgeKey) ?? 0;
    } catch (e) {
      developer.log('[BADGE] ❌ Error getting badge: $e');
      return 0;
    }
  }

  // NEW: Clear all unread counts (on logout, etc.)
  Future<void> clearAllUnreadCounts() async {
    _unreadCounts.clear();
    await _saveUnreadCounts();
    await resetBadge();
    developer.log('[BADGE] 🗑️ Cleared all unread counts');
  }

  // Private methods
  Future<void> _syncBadgeWithUnreadCounts() async {
    try {
      final totalUnread = getTotalUnreadCount();
      await updateBadge(totalUnread);
      developer.log('[BADGE] 🔄 Badge synced with unread counts: $totalUnread');
    } catch (e) {
      developer.log('[BADGE] ❌ Error syncing badge: $e');
    }
  }

  Future<void> _syncToNative(int count) async {
    try {
      // iOS
      if (Platform.isIOS) {
        await _iosBadgeChannel.invokeMethod('updateBadge', {'count': count});
        developer.log('[BADGE] ✅ iOS badge synced: $count');
      }

      if (Platform.isAndroid && await FlutterAppBadger.isAppBadgeSupported()) {
        if (count <= 0) {
          FlutterAppBadger.removeBadge();
        } else {
          FlutterAppBadger.updateBadgeCount(count);
        }
        developer.log('[BADGE] ✅ Android badge synced: $count');
      }
    } catch (e) {
      developer.log('[BADGE] ❌ Native sync error: $e');
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unreadCountsJson = prefs.getString(_unreadCountsKey);

      if (unreadCountsJson != null) {
        final Map<String, dynamic> decoded = json.decode(unreadCountsJson);
        _unreadCounts.clear();
        decoded.forEach((key, value) {
          final intValue = value is int ? value : int.tryParse(value.toString()) ?? 0;
          _unreadCounts[key] = intValue;
        });
        developer.log('[BADGE] ✅ Loaded unread counts: ${_unreadCounts.length} chats');
      }
    } catch (e) {
      developer.log('[BADGE] ❌ Error loading unread counts: $e');
      _unreadCounts.clear();
    }
  }

  Future<void> _saveUnreadCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_unreadCountsKey, json.encode(_unreadCounts));
      developer.log('[BADGE] 💾 Saved unread counts: ${_unreadCounts.length} chats');
    } catch (e) {
      developer.log('[BADGE] ❌ Error saving unread counts: $e');
    }
  }

  Future<bool> _shouldSyncWithServer() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getInt(_lastSyncTimeKey);
    if (lastSync == null) return true;

    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime);

    // Sync if last sync was more than 5 minutes ago
    return difference.inMinutes > 5;
  }

  Future<void> _syncWithServer() async {
    // TODO: Implement actual server sync
    // For now, just sync badge with current counts
    await _syncBadgeWithUnreadCounts();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<int> getNativeBadge() async {
    if (!Platform.isIOS) return 0;
    try {
      final MethodChannel badgeChannel = MethodChannel('com.connect/iosBadge');
      final nativeBadge = await badgeChannel.invokeMethod<int>('getBadge');
      return nativeBadge ?? 0;
    } catch (e) {
      developer.log('[BADGE] ❌ Error getting native badge: $e');
      return 0;
    }
  }
}