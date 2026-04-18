// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Shuudansou.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShuudansouAdapter extends TypeAdapter<Shuudansou> {
  @override
  final int typeId = 4;

  @override
  Shuudansou read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Shuudansou()
      ..sisoutime = (fields[0] as List).cast<double>()
      ..setteitime = (fields[1] as List).cast<double>()
      ..sijioption_fun = (fields[2] as List).cast<int>()
      ..sijioption_byou = (fields[3] as List).cast<int>();
  }

  @override
  void write(BinaryWriter writer, Shuudansou obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.sisoutime)
      ..writeByte(1)
      ..write(obj.setteitime)
      ..writeByte(2)
      ..write(obj.sijioption_fun)
      ..writeByte(3)
      ..write(obj.sijioption_byou);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShuudansouAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
