import 'package:hive_flutter/hive_flutter.dart';
import 'message_hive_models.dart';

class MessageCacheService {
  static const _boxName = 'messagesBox';
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(105)) {
      Hive.registerAdapter(HMessageAdapter());
    }
    await Hive.openBox<HMessage>(_boxName);
    _initialized = true;
  }

  final _box = Hive.box<HMessage>(_boxName);

  Future<void> cacheMessage(HMessage message) async {
    await _box.put(message.id, message);
  }

  Future<void> cacheMessages(List<HMessage> messages) async {
    final map = {for (var m in messages) m.id: m};
    await _box.putAll(map);
  }

  List<HMessage> getMessagesForChat(String chatId) {
    return _box.values
        .where((msg) => msg.chatId == chatId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> deleteMessage(String messageId) async {
    await _box.delete(messageId);
  }

  Future<void> clearChat(String chatId) async {
    final toDelete = _box.values.where((m) => m.chatId == chatId).toList();
    for (final msg in toDelete) {
      await msg.delete();
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}