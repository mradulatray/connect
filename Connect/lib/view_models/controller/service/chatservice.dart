// lib/services/chat_service.dart
import 'dart:convert';
import 'package:connectapp/view_models/controller/service/service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectapp/models/UserLogin/user_login_model.dart';
import 'package:connectapp/view_models/controller/userPreferences/user_preferences_screen.dart';
import '../../../models/chat_cache_mappers.dart';
import '../../../models/chat_cache_service.dart';
import '../../../models/hive_models.dart';
import '../../../res/api_urls/api_urls.dart';
import '../../../view/message/badge_manager.dart';

class ChatService {
  static String baseUrl = ApiUrls.baseUrl;
  final UserPreferencesViewmodel _userPreferences = UserPreferencesViewmodel();
  final ChatCacheService _cache = ChatCacheService();

  ChatService() {
    // Ensure cache is initialized
    ChatCacheService.init();
  }

  // ------------- GROUPS -------------

  /// Cached-first groups. If cache exists, return it immediately.
  /// Then caller can call [refreshMyGroups] to refresh from network.
  Future<List<GroupData>> getMyGroupsCached() async {
    final cached = await _cache.getCachedGroups();
    if (cached.isNotEmpty) {
      return cached.map(_groupFromHGroup).toList();
    }
    // if cache empty, fetch remote now:
    return await refreshMyGroups();
  }

  /// Always hit network, update cache, return fresh list.
  Future<List<GroupData>> refreshMyGroups() async {
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData?.token;
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/connect/v1/api/creator/course/get-my-chat-groups'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP error! status: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body);
    final groups = data.map<GroupData>((g) => GroupData.fromJson(g)).toList();

    // // ✅ CRITICAL: Immediately update BadgeManager with server unread counts
    // await _updateBadgeManagerWithGroups(groups);

    // sort unread desc, then by lastMessage.sentAt/updatedAt desc
    groups.sort(_groupSorter);

    // upsert cache (normalized)
    final normalized = groups.map(hGroupFromGroupData).toList();
    await _cache.upsertGroups(normalized);

    return groups;
  }

  // ------------- PRIVATE CHATS -------------

  Future<List<Chat>> getPrivateChatsCached(String currentUserId) async {
    final cached = await _cache.getCachedPrivateChats();
    if (cached.isNotEmpty) {
      return cached.map(_chatFromHChat).toList();
    }
    return await refreshPrivateChats(currentUserId);
  }

  Future<List<Chat>> refreshPrivateChats(String currentUserId) async {
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData?.token;
    if (token == null) throw Exception('No authentication token');

    final response = await http.get(
      Uri.parse('$baseUrl/connect/v1/api/chat/get-all-private-chats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP error! status: ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body);

    final List<Chat> chats = data.map<Chat>((chat) {
      final otherParticipant = (chat['participants'] as List)
          .firstWhere((p) => p['_id'] != currentUserId);

      return Chat(
        id: chat['_id'],
        name: otherParticipant['fullName'],
        avatar: otherParticipant['avatar']?['imageUrl'] ??
            otherParticipant['avatar'],
        lastMessage: chat['lastMessage'],
        timestamp: DateTime.tryParse(chat['updatedAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        unread: chat['unreadCount'] ?? 0,
        isGroup: false,
        participants: (chat['participants'] as List)
            .map((p) => Participant.fromJson(p))
            .toList(),
        pinnedMessages: chat['pinnedMessages'],
      );
    }).toList();

    // ✅ CRITICAL: Immediately update BadgeManager with server unread counts
    // await _updateBadgeManagerWithChats(chats);

    chats.sort(_chatSorter);

    // Upsert cache
    final normalized = chats.map(hChatFromChat).toList();
    await _cache.upsertPrivateChats(normalized);

    return chats;
  }

  Future<String?> translateText(String message) async {
    LoginResponseModel? userData = await _userPreferences.getUser();
    final token = userData?.token;
    if (token == null) throw Exception('No authentication token');

    // Create the request body
    final Map<String, dynamic> requestBody = {
      "text": message,
    };

    final response = await http.post(
      Uri.parse(ApiUrls.translateTextApi),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      debugPrint("Translated Text ==========> ${data["translatedText"]}");
      return data["translatedText"];
    } else {
      debugPrint("${response.statusCode} - ${response.body}");
      final Map<String, dynamic> errorData = json.decode(response.body);
      final String errorMessage =
          errorData["error"] ?? 'Translation requires Premium+ subscription';
      throw errorMessage;
    }
  }

  // ---------- NEW: BadgeManager Update Methods ----------

  /// Update BadgeManager with server unread counts for groups
  Future<void> _updateBadgeManagerWithGroups(List<GroupData> groups) async {
    try {
      // Initialize BadgeManager if needed
      final badgeManager = BadgeManager();
      await badgeManager.initialize();

      // Update BadgeManager for each group
      for (final group in groups) {
        if (group.id != null && group.unreadCount != null) {
          await badgeManager.updateUnreadCount(
            group.id!,
            group.unreadCount!,
            fromServer: true,
          );
          debugPrint(
              '[CHAT SERVICE] ✅ Updated BadgeManager for group ${group.id}: ${group.unreadCount}');
        }
      }

      // Update total badge count
      final totalUnread = badgeManager.getTotalUnreadCount();
      await badgeManager.updateBadge(totalUnread);

      debugPrint(
          '[CHAT SERVICE] 🔄 Total unread after groups update: $totalUnread');
    } catch (e) {
      debugPrint(
          '[CHAT SERVICE] ❌ Error updating BadgeManager with groups: $e');
    }
  }

  /// Update BadgeManager with server unread counts for chats
  Future<void> _updateBadgeManagerWithChats(List<Chat> chats) async {
    try {
      // Initialize BadgeManager if needed
      final badgeManager = BadgeManager();
      await badgeManager.initialize();

      // Update BadgeManager for each chat
      for (final chat in chats) {
        await badgeManager.updateUnreadCount(
          chat.id,
          chat.unread,
          fromServer: true,
        );
        debugPrint(
            '[CHAT SERVICE] ✅ Updated BadgeManager for chat ${chat.id}: ${chat.unread}');
      }

      // Update total badge count
      final totalUnread = badgeManager.getTotalUnreadCount();
      await badgeManager.updateBadge(totalUnread);

      debugPrint(
          '[CHAT SERVICE] 🔄 Total unread after chats update: $totalUnread');
    } catch (e) {
      debugPrint('[CHAT SERVICE] ❌ Error updating BadgeManager with chats: $e');
    }
  }

  // ---------- Helper Methods ----------

  /// Get all unread counts from BadgeManager (for chat screen to use)
  Future<Map<String, int>> getBadgeManagerUnreadCounts() async {
    try {
      final badgeManager = BadgeManager();
      await badgeManager.initialize();
      return Map.from(badgeManager.unreadCounts);
    } catch (e) {
      debugPrint('[CHAT SERVICE] ❌ Error getting BadgeManager counts: $e');
      return {};
    }
  }

  /// Get unread count for specific chat from BadgeManager
  Future<int> getUnreadCountFromBadgeManager(String chatId) async {
    try {
      final badgeManager = BadgeManager();
      await badgeManager.initialize();
      return badgeManager.getUnreadCount(chatId);
    } catch (e) {
      debugPrint(
          '[CHAT SERVICE] ❌ Error getting unread count from BadgeManager: $e');
      return 0;
    }
  }

  /// Mark a chat as read in BadgeManager
  Future<void> markChatAsReadInBadgeManager(String chatId) async {
    try {
      final badgeManager = BadgeManager();
      await badgeManager.initialize();
      await badgeManager.resetUnreadCount(chatId);
      debugPrint(
          '[CHAT SERVICE] ✅ Marked chat as read in BadgeManager: $chatId');
    } catch (e) {
      debugPrint('[CHAT SERVICE] ❌ Error marking chat as read: $e');
    }
  }

  /// Get groups with unread counts from BadgeManager
  Future<List<GroupData>> getGroupsWithBadgeManagerCounts() async {
    try {
      final groups = await getMyGroupsCached();
      final badgeManager = BadgeManager();
      await badgeManager.initialize();

      // Update each group with BadgeManager's unread count
      for (final group in groups) {
        if (group.id != null) {
          final currentUnread = badgeManager.getUnreadCount(group.id!);
          if (currentUnread != (group.unreadCount ?? 0)) {
            debugPrint(
                '[CHAT SERVICE] 🔄 Updating group ${group.id} unread: ${group.unreadCount} → $currentUnread');
          }
        }
      }

      return groups;
    } catch (e) {
      debugPrint('[CHAT SERVICE] ❌ Error getting groups with badge counts: $e');
      return [];
    }
  }

  /// Get private chats with unread counts from BadgeManager
  Future<List<Chat>> getPrivateChatsWithBadgeManagerCounts(
      String currentUserId) async {
    try {
      final chats = await getPrivateChatsCached(currentUserId);
      final badgeManager = BadgeManager();
      await badgeManager.initialize();

      // Update each chat with BadgeManager's unread count
      for (final chat in chats) {
        final currentUnread = badgeManager.getUnreadCount(chat.id);
        if (currentUnread != chat.unread) {
          debugPrint(
              '[CHAT SERVICE] 🔄 Updating chat ${chat.id} unread: ${chat.unread} → $currentUnread');
          // Note: We can't update chat.unread here since it's immutable
          // The ChatScreen will use BadgeManager directly
        }
      }

      return chats;
    } catch (e) {
      debugPrint('[CHAT SERVICE] ❌ Error getting chats with badge counts: $e');
      return [];
    }
  }

  // ---------- Sorters ----------
  int _chatSorter(Chat a, Chat b) {
    final unread = b.unread.compareTo(a.unread);
    if (unread != 0) return unread;
    return b.timestamp.compareTo(a.timestamp);
  }

  int _groupSorter(GroupData a, GroupData b) {
    final unread = (b.unreadCount ?? 0).compareTo(a.unreadCount ?? 0);
    if (unread != 0) return unread;

    final aSent = _safeGroupSortMillis(a);
    final bSent = _safeGroupSortMillis(b);
    return bSent.compareTo(aSent);
  }

  int _safeGroupSortMillis(GroupData g) {
    // prefer lastMessage.sentAt; fallback to updatedAt/createdAt
    final lm = g.lastMessage;
    if (lm is Map && lm['sentAt'] != null) {
      final s = lm['sentAt'];
      if (s is int) return s;
      if (s is String) {
        final dt = DateTime.tryParse(s);
        if (dt != null) return dt.millisecondsSinceEpoch;
      }
    }
    final up = g.updatedAt ?? g.createdAt;
    if (up != null) {
      final dt = DateTime.tryParse(up);
      if (dt != null) return dt.millisecondsSinceEpoch;
    }
    return 0;
  }

  // ---------- Mappers: Cache -> API Models ----------
  Chat _chatFromHChat(HChat h) {
    return Chat(
      id: h.id,
      name: h.name,
      avatar: h.avatar,
      lastMessage: (h.lastMessage == null)
          ? null
          : {
              'content': h.lastMessage!.content,
              'sentAt': h.lastMessage!.sentAtMillis,
              'sender': {'fullName': h.lastMessage!.senderName},
              'messageType': h.lastMessage!.messageType,
            },
      timestamp: DateTime.fromMillisecondsSinceEpoch(h.updatedAtMillis),
      unread: h.unread,
      isGroup: h.isGroup,
      participants: null,
      pinnedMessages: null,
      senderName: h.lastMessage?.senderName,
    );
  }

  GroupData _groupFromHGroup(HGroup g) {
    return GroupData(
      id: g.id,
      name: g.name,
      groupAvatar: g.groupAvatar,
      lastMessage: (g.lastMessage == null)
          ? null
          : {
              'content': g.lastMessage!.content,
              'sentAt': g.lastMessage!.sentAtMillis,
              'sender': {'fullName': g.lastMessage!.senderName},
              'messageType': g.lastMessage!.messageType,
            },
      unreadCount: g.unreadCount,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(g.updatedAtMillis)
          .toIso8601String(),
    );
  }
}
