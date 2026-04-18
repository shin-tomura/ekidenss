// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'riji_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RijiDataAdapter extends TypeAdapter<RijiData> {
  @override
  final int typeId = 9;

  @override
  RijiData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RijiData()
      ..rid_riji = (fields[0] as List).cast<int>()
      ..meishou = (fields[1] as List).cast<String>();
  }

  @override
  void write(BinaryWriter writer, RijiData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.rid_riji)
      ..writeByte(1)
      ..write(obj.meishou);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RijiDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
