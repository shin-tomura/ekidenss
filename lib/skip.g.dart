// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skip.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SkipAdapter extends TypeAdapter<Skip> {
  @override
  final int typeId = 5;

  @override
  Skip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Skip()
      ..skipflag = fields[0] as int
      ..skipyear = fields[1] as int
      ..skipmonth = fields[2] as int
      ..skipday = fields[3] as int
      ..totaltime_jap_all = (fields[4] as List).cast<double>()
      ..totaltime_jap_13pundai = (fields[5] as List).cast<double>()
      ..totaltime_jap_14pun00dai = (fields[6] as List).cast<double>()
      ..totaltime_jap_14pun10dai = (fields[7] as List).cast<double>()
      ..totaltime_jap_14pun20dai = (fields[8] as List).cast<double>()
      ..totaltime_jap_14pun30dai = (fields[9] as List).cast<double>()
      ..totaltime_jap_14pun40dai = (fields[10] as List).cast<double>()
      ..totaltime_jap_14pun50dai = (fields[11] as List).cast<double>()
      ..totaltime_jap_15pundai = (fields[12] as List).cast<double>()
      ..count_jap_all = (fields[13] as List).cast<int>()
      ..count_jap_13pundai = (fields[14] as List).cast<int>()
      ..count_jap_14pun00dai = (fields[15] as List).cast<int>()
      ..count_jap_14pun10dai = (fields[16] as List).cast<int>()
      ..count_jap_14pun20dai = (fields[17] as List).cast<int>()
      ..count_jap_14pun30dai = (fields[18] as List).cast<int>()
      ..count_jap_14pun40dai = (fields[19] as List).cast<int>()
      ..count_jap_14pun50dai = (fields[20] as List).cast<int>()
      ..count_jap_15pundai = (fields[21] as List).cast<int>()
      ..totaltime_ryuugakusei = (fields[22] as List).cast<double>()
      ..count_ryuugakusei = (fields[23] as List).cast<int>()
      ..besttime_ryuugakusei = (fields[24] as List).cast<double>()
      ..besttime_jap_all = (fields[25] as List).cast<double>()
      ..besttime_jap_13pundai = (fields[26] as List).cast<double>()
      ..besttime_jap_14pun00dai = (fields[27] as List).cast<double>()
      ..besttime_jap_14pun10dai = (fields[28] as List).cast<double>()
      ..besttime_jap_14pun20dai = (fields[29] as List).cast<double>()
      ..besttime_jap_14pun30dai = (fields[30] as List).cast<double>()
      ..besttime_jap_14pun40dai = (fields[31] as List).cast<double>()
      ..besttime_jap_14pun50dai = (fields[32] as List).cast<double>()
      ..besttime_jap_15pundai = (fields[33] as List).cast<double>();
  }

  @override
  void write(BinaryWriter writer, Skip obj) {
    writer
      ..writeByte(34)
      ..writeByte(0)
      ..write(obj.skipflag)
      ..writeByte(1)
      ..write(obj.skipyear)
      ..writeByte(2)
      ..write(obj.skipmonth)
      ..writeByte(3)
      ..write(obj.skipday)
      ..writeByte(4)
      ..write(obj.totaltime_jap_all)
      ..writeByte(5)
      ..write(obj.totaltime_jap_13pundai)
      ..writeByte(6)
      ..write(obj.totaltime_jap_14pun00dai)
      ..writeByte(7)
      ..write(obj.totaltime_jap_14pun10dai)
      ..writeByte(8)
      ..write(obj.totaltime_jap_14pun20dai)
      ..writeByte(9)
      ..write(obj.totaltime_jap_14pun30dai)
      ..writeByte(10)
      ..write(obj.totaltime_jap_14pun40dai)
      ..writeByte(11)
      ..write(obj.totaltime_jap_14pun50dai)
      ..writeByte(12)
      ..write(obj.totaltime_jap_15pundai)
      ..writeByte(13)
      ..write(obj.count_jap_all)
      ..writeByte(14)
      ..write(obj.count_jap_13pundai)
      ..writeByte(15)
      ..write(obj.count_jap_14pun00dai)
      ..writeByte(16)
      ..write(obj.count_jap_14pun10dai)
      ..writeByte(17)
      ..write(obj.count_jap_14pun20dai)
      ..writeByte(18)
      ..write(obj.count_jap_14pun30dai)
      ..writeByte(19)
      ..write(obj.count_jap_14pun40dai)
      ..writeByte(20)
      ..write(obj.count_jap_14pun50dai)
      ..writeByte(21)
      ..write(obj.count_jap_15pundai)
      ..writeByte(22)
      ..write(obj.totaltime_ryuugakusei)
      ..writeByte(23)
      ..write(obj.count_ryuugakusei)
      ..writeByte(24)
      ..write(obj.besttime_ryuugakusei)
      ..writeByte(25)
      ..write(obj.besttime_jap_all)
      ..writeByte(26)
      ..write(obj.besttime_jap_13pundai)
      ..writeByte(27)
      ..write(obj.besttime_jap_14pun00dai)
      ..writeByte(28)
      ..write(obj.besttime_jap_14pun10dai)
      ..writeByte(29)
      ..write(obj.besttime_jap_14pun20dai)
      ..writeByte(30)
      ..write(obj.besttime_jap_14pun30dai)
      ..writeByte(31)
      ..write(obj.besttime_jap_14pun40dai)
      ..writeByte(32)
      ..write(obj.besttime_jap_14pun50dai)
      ..writeByte(33)
      ..write(obj.besttime_jap_15pundai);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
