// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HSenderAdapter extends TypeAdapter<HSender> {
  @override
  final int typeId = 101;

  @override
  HSender read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HSender(
      id: fields[0] as String,
      name: fields[1] as String,
      avatar: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HSender obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatar);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HSenderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HLastMessageAdapter extends TypeAdapter<HLastMessage> {
  @override
  final int typeId = 102;

  @override
  HLastMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HLastMessage(
      content: fields[0] as String?,
      sentAtMillis: fields[1] as int?,
      senderName: fields[2] as String?,
      messageType: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HLastMessage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.sentAtMillis)
      ..writeByte(2)
      ..write(obj.senderName)
      ..writeByte(3)
      ..write(obj.messageType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HLastMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HChatAdapter extends TypeAdapter<HChat> {
  @override
  final int typeId = 103;

  @override
  HChat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HChat(
      id: fields[0] as String,
      name: fields[1] as String,
      avatar: fields[2] as String?,
      lastMessage: fields[3] as HLastMessage?,
      updatedAtMillis: fields[4] as int,
      unread: fields[5] as int,
      isGroup: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HChat obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatar)
      ..writeByte(3)
      ..write(obj.lastMessage)
      ..writeByte(4)
      ..write(obj.updatedAtMillis)
      ..writeByte(5)
      ..write(obj.unread)
      ..writeByte(6)
      ..write(obj.isGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HGroupAdapter extends TypeAdapter<HGroup> {
  @override
  final int typeId = 104;

  @override
  HGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HGroup(
      id: fields[0] as String,
      name: fields[1] as String,
      groupAvatar: fields[2] as String?,
      lastMessage: fields[3] as HLastMessage?,
      updatedAtMillis: fields[4] as int,
      unreadCount: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HGroup obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.groupAvatar)
      ..writeByte(3)
      ..write(obj.lastMessage)
      ..writeByte(4)
      ..write(obj.updatedAtMillis)
      ..writeByte(5)
      ..write(obj.unreadCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
