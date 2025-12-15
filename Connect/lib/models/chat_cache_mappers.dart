// lib/services/cache/chat_cache_mappers.dart
import 'hive_models.dart';

// ---- Helpers to safely read millisecond timestamps ----
int _toMillisFromMaybeMillisOrIso(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    // attempt parse ISO
    final dt = DateTime.tryParse(value);
    return dt?.millisecondsSinceEpoch ?? 0;
  }
  return 0;
}

// ---- GroupData -> HGroup ----
HGroup hGroupFromGroupData(dynamic groupData) {
  // groupData is your GroupData model
  final last = groupData.lastMessage;
  final lastSentAt = (last is Map && last['sentAt'] != null)
      ? _toMillisFromMaybeMillisOrIso(last['sentAt'])
      : 0;

  final updatedAt = _toMillisFromMaybeMillisOrIso(groupData.updatedAt ?? groupData.createdAt);

  return HGroup(
    id: groupData.id ?? '',
    name: groupData.name ?? '',
    groupAvatar: groupData.groupAvatar,
    lastMessage: (last is Map)
        ? HLastMessage(
      content: last['content']?.toString(),
      sentAtMillis: lastSentAt,
      senderName: (last['sender'] is Map)
          ? (last['sender']['fullName'] ?? last['sender']['name'])
          : null,
      messageType: last['messageType']?.toString(),
    )
        : null,
    updatedAtMillis: updatedAt,
    unreadCount: groupData.unreadCount ?? 0,
  );
}

// ---- Chat -> HChat ----
HChat hChatFromChat(dynamic chat) {
  // chat is your Chat model
  final last = chat.lastMessage;
  int lastSentAt = 0;

  if (last is Map) {
    final raw = last['sentAt'] ?? last['createdAt'];
    lastSentAt = _toMillisFromMaybeMillisOrIso(raw);
  }

  final updatedAt = chat.timestamp.millisecondsSinceEpoch;

  return HChat(
    id: chat.id,
    name: chat.name,
    avatar: chat.avatar,
    lastMessage: (last is Map)
        ? HLastMessage(
      content: last['content']?.toString(),
      sentAtMillis: lastSentAt,
      senderName: (last['sender'] is Map)
          ? (last['sender']['fullName'] ?? last['sender']['name'])
          : null,
      messageType: last['messageType']?.toString(),
    )
        : null,
    updatedAtMillis: updatedAt,
    unread: chat.unread,
    isGroup: chat.isGroup,
  );
}