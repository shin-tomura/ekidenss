// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kantoku_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KantokuDataAdapter extends TypeAdapter<KantokuData> {
  @override
  final int typeId = 8;

  @override
  KantokuData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KantokuData()
      ..rid = (fields[0] as List).cast<int>()
      ..yobiint0 = (fields[1] as List).cast<int>()
      ..yobiint1 = (fields[2] as List).cast<int>()
      ..yobiint2 = (fields[3] as List).cast<int>()
      ..yobiint3 = (fields[4] as List).cast<int>()
      ..yobiint4 = (fields[5] as List).cast<int>()
      ..yobiint5 = (fields[6] as List).cast<int>();
  }

  @override
  void write(BinaryWriter writer, KantokuData obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.rid)
      ..writeByte(1)
      ..write(obj.yobiint0)
      ..writeByte(2)
      ..write(obj.yobiint1)
      ..writeByte(3)
      ..write(obj.yobiint2)
      ..writeByte(4)
      ..write(obj.yobiint3)
      ..writeByte(5)
      ..write(obj.yobiint4)
      ..writeByte(6)
      ..write(obj.yobiint5);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KantokuDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
