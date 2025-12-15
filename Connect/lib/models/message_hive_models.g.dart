// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HMessageAdapter extends TypeAdapter<HMessage> {
  @override
  final int typeId = 105;

  @override
  HMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HMessage(
      id: fields[0] as String,
      chatId: fields[1] as String,
      senderId: fields[2] as String,
      content: fields[3] as String,
      timestamp: fields[4] as int,
      messageType: fields[5] as String,
      isGroup: fields[6] as bool,
      isRead: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HMessage obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.messageType)
      ..writeByte(6)
      ..write(obj.isGroup)
      ..writeByte(7)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
