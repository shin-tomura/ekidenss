// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlbumAdapter extends TypeAdapter<Album> {
  @override
  final int typeId = 7;

  @override
  Album read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Album()
      ..tourokusuu_total = fields[0] as int
      ..hyojisenshunum = fields[1] as int
      ..yobiint0 = fields[2] as int
      ..yobiint1 = fields[3] as int
      ..yobiint2 = fields[4] as int
      ..yobiint3 = fields[5] as int
      ..yobiint4 = fields[6] as int
      ..yobiint5 = fields[7] as int;
  }

  @override
  void write(BinaryWriter writer, Album obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.tourokusuu_total)
      ..writeByte(1)
      ..write(obj.hyojisenshunum)
      ..writeByte(2)
      ..write(obj.yobiint0)
      ..writeByte(3)
      ..write(obj.yobiint1)
      ..writeByte(4)
      ..write(obj.yobiint2)
      ..writeByte(5)
      ..write(obj.yobiint3)
      ..writeByte(6)
      ..write(obj.yobiint4)
      ..writeByte(7)
      ..write(obj.yobiint5);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
