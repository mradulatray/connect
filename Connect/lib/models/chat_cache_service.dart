// lib/services/cache/chat_cache_service.dart
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_models.dart';
import '../../models/UserLogin/user_login_model.dart'; // for your API models if needed

class ChatCacheService {
  static const _privateChatsBox = 'privateChatsBox';
  static const _groupsBox = 'groupsBox';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(101)) Hive.registerAdapter(HSenderAdapter());
    if (!Hive.isAdapterRegistered(102)) Hive.registerAdapter(HLastMessageAdapter());
    if (!Hive.isAdapterRegistered(103)) Hive.registerAdapter(HChatAdapter());
    if (!Hive.isAdapterRegistered(104)) Hive.registerAdapter(HGroupAdapter());

    await Hive.openBox<HChat>(_privateChatsBox);
    await Hive.openBox<HGroup>(_groupsBox);
    _initialized = true;
  }

  // ---------- PRIVATE CHATS ----------
  Future<List<HChat>> getCachedPrivateChats() async {
    final box = Hive.box<HChat>(_privateChatsBox);
    final items = box.values.toList();

    // sort: unread desc, then updatedAt desc
    items.sort((a, b) {
      final unread = b.unread.compareTo(a.unread);
      if (unread != 0) return unread;
      return b.updatedAtMillis.compareTo(a.updatedAtMillis);
    });
    return items;
  }

  Future<void> upsertPrivateChats(List<HChat> chats) async {
    final box = Hive.box<HChat>(_privateChatsBox);
    await box.clear(); // replace snapshot (simpler & consistent with backend)
    for (final c in chats) {
      await box.put(c.id, c);
    }
  }

  // ---------- GROUPS ----------
  Future<List<HGroup>> getCachedGroups() async {
    final box = Hive.box<HGroup>(_groupsBox);
    final items = box.values.toList();

    items.sort((a, b) {
      final unread = b.unreadCount.compareTo(a.unreadCount);
      if (unread != 0) return unread;
      return b.updatedAtMillis.compareTo(a.updatedAtMillis);
    });
    return items;
  }

  Future<void> upsertGroups(List<HGroup> groups) async {
    final box = Hive.box<HGroup>(_groupsBox);
    await box.clear();
    for (final g in groups) {
      await box.put(g.id, g);
    }
  }

  // Handy streams if you want UI to auto-refresh when cache changes
  Stream<List<HChat>> watchPrivateChats() {
    final box = Hive.box<HChat>(_privateChatsBox);
    return box.watch().map((_) => getCachedPrivateChats()).asyncMap((f) => f);
  }

  Stream<List<HGroup>> watchGroups() {
    final box = Hive.box<HGroup>(_groupsBox);
    return box.watch().map((_) => getCachedGroups()).asyncMap((f) => f);
  }
}