import 'package:hive/hive.dart';

part 'message_hive_models.g.dart';

@HiveType(typeId: 105)
class HMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String chatId; // or groupId

  @HiveField(2)
  String senderId;

  @HiveField(3)
  String content;

  @HiveField(4)
  int timestamp;

  @HiveField(5)
  String messageType;

  @HiveField(6)
  bool isGroup;

  @HiveField(7)
  bool isRead;

  HMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.messageType,
    required this.isGroup,
    this.isRead = false,
  });
}