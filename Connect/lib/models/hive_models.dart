import 'package:hive/hive.dart';

part 'hive_models.g.dart';

/// IMPORTANT: Keep typeIds unique in your app.
/// If you already use some ids, change these to free ids.
@HiveType(typeId: 101)
class HSender extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String? avatar;

  HSender({required this.id, required this.name, this.avatar});
}

@HiveType(typeId: 102)
class HLastMessage extends HiveObject {
  /// minimal normalized payload for cache
  @HiveField(0) String? content;
  @HiveField(1) int? sentAtMillis; // epoch millis
  @HiveField(2) String? senderName;
  @HiveField(3) String? messageType;

  HLastMessage({this.content, this.sentAtMillis, this.senderName, this.messageType});
}

@HiveType(typeId: 103)
class HChat extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String? avatar;
  @HiveField(3) HLastMessage? lastMessage;
  @HiveField(4) int updatedAtMillis;
  @HiveField(5) int unread;
  @HiveField(6) bool isGroup;

  HChat({
    required this.id,
    required this.name,
    this.avatar,
    this.lastMessage,
    required this.updatedAtMillis,
    required this.unread,
    required this.isGroup,
  });
}

@HiveType(typeId: 104)
class HGroup extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String? groupAvatar;
  @HiveField(3) HLastMessage? lastMessage;
  @HiveField(4) int updatedAtMillis;
  @HiveField(5) int unreadCount;

  HGroup({
    required this.id,
    required this.name,
    this.groupAvatar,
    this.lastMessage,
    required this.updatedAtMillis,
    required this.unreadCount,
  });
}