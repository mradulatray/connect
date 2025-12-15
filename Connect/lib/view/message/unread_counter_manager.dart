import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UnreadCounterManager {
  static final UnreadCounterManager _instance = UnreadCounterManager._internal();
  factory UnreadCounterManager() => _instance;
  UnreadCounterManager._internal();

  static const String _storageKey = 'chat_unread_counts';
  static const String _totalBadgeKey = 'total_app_badge';
  final MethodChannel _iosBadgeChannel = MethodChannel('com.connect/iosBadge');

  Map<String, int> _unreadCounts = {};
  int _totalUnread = 0;

  // Callbacks for UI updates
  Function(Map<String, int>)? _onCountsUpdated;
  Function(int)? _onTotalUpdated;

  void setUpdateCallbacks({
    Function(Map<String, int>)? onCountsUpdated,
    Function(int)? onTotalUpdated,
  }) {
    _onCountsUpdated = onCountsUpdated;
    _onTotalUpdated = onTotalUpdated;
  }

  Future<void> initialize() async {
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load per-chat counts
      final String? countsJson = prefs.getString(_storageKey);
      if (countsJson != null) {
        final Map<String, dynamic> decoded = json.decode(countsJson);
        _unreadCounts = decoded.map((key, value) =>
            MapEntry(key, (value as num).toInt())
        );
      }

      // Load total badge
      _totalUnread = prefs.getInt(_totalBadgeKey) ?? 0;

      _triggerUpdates();
    } catch (e) {
      print('Error loading unread counts: $e');
      _unreadCounts = {};
      _totalUnread = 0;
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save per-chat counts
      final String countsJson = json.encode(_unreadCounts);
      await prefs.setString(_storageKey, countsJson);

      // Save total badge
      await prefs.setInt(_totalBadgeKey, _totalUnread);

      // Update native badge
      updateNativeBadge();
    } catch (e) {
      print('Error saving unread counts: $e');
    }
  }

  Future<void> updateNativeBadge() async {
      try {
        // iOS
        if (Platform.isIOS) {
          await _iosBadgeChannel.invokeMethod('updateBadge', {'count': _totalUnread});
          developer.log('[BADGE] ✅ iOS badge synced: $_totalUnread');
        }

        if (Platform.isAndroid && await FlutterAppBadger.isAppBadgeSupported()) {
          if (_totalUnread <= 0) {
            FlutterAppBadger.removeBadge();
          } else {
            FlutterAppBadger.updateBadgeCount(_totalUnread);
          }
          developer.log('[BADGE] ✅ Android badge synced: $_totalUnread');
        }
      } catch (e) {
        developer.log('[BADGE] ❌ Native sync error: $e');
      }
    }

  void _triggerUpdates() {
    _onCountsUpdated?.call(Map.from(_unreadCounts));
    _onTotalUpdated?.call(_totalUnread);
  }

  // Public methods
  int getUnreadCount(String chatId) {
    return _unreadCounts[chatId] ?? 0;
  }

  int getTotalUnread() {
    return _totalUnread;
  }

  Map<String, int> getAllCounts() {
    return Map.from(_unreadCounts);
  }

  void incrementUnreadCount(String chatId, {int by = 1}) {
    final current = _unreadCounts[chatId] ?? 0;
    _unreadCounts[chatId] = current + by;
    _totalUnread += by;
    _triggerUpdates();
    _saveToStorage();
  }

  void decrementUnreadCount(String chatId, {int by = 1}) {
    final current = _unreadCounts[chatId] ?? 0;
    final newCount = current - by;
    if (newCount <= 0) {
      _totalUnread -= current;
      _unreadCounts.remove(chatId);
    } else {
      _unreadCounts[chatId] = newCount;
      _totalUnread -= by;
    }
    _triggerUpdates();
    _saveToStorage();
  }

  void resetUnreadCount(String chatId) {
    final current = _unreadCounts[chatId] ?? 0;
    if (current > 0) {
      _unreadCounts.remove(chatId);
      _totalUnread -= current;
      _triggerUpdates();
      _saveToStorage();
    }
  }

  void setUnreadCount(String chatId, int count) {
    final oldCount = _unreadCounts[chatId] ?? 0;

    if (count <= 0) {
      if (_unreadCounts.containsKey(chatId)) {
        _unreadCounts.remove(chatId);
        _totalUnread -= oldCount;
      }
    } else {
      _unreadCounts[chatId] = count;
      _totalUnread += (count - oldCount);
    }

    _triggerUpdates();
    _saveToStorage();
  }

  void clearAllCounts() {
    _unreadCounts.clear();
    _totalUnread = 0;
    _triggerUpdates();
    _saveToStorage();
  }

  void updateFromServer(Map<String, int> serverCounts) {
    int newTotal = 0;

    // Merge server counts with local counts
    for (final entry in serverCounts.entries) {
      final chatId = entry.key;
      final serverCount = entry.value;
      final localCount = _unreadCounts[chatId] ?? 0;

      // Use the maximum of server and local counts (to avoid missing messages)
      final finalCount = serverCount > localCount ? serverCount : localCount;

      if (finalCount > 0) {
        _unreadCounts[chatId] = finalCount;
        newTotal += finalCount;
      }
    }

    // Remove chats that don't exist on server (optional)
    // final serverChatIds = serverCounts.keys.toSet();
    // _unreadCounts.removeWhere((key, _) => !serverChatIds.contains(key));

    _totalUnread = newTotal;
    _triggerUpdates();
    _saveToStorage();
  }
}