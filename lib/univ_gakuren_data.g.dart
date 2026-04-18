// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'univ_gakuren_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnivGakurenDataAdapter extends TypeAdapter<UnivGakurenData> {
  @override
  final int typeId = 11;

  @override
  UnivGakurenData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnivGakurenData(
      id: fields[0] as int,
      r: fields[1] as int,
      name: fields[2] as String,
      name_tanshuku: fields[3] as String,
      meisei_total: fields[4] as int,
      meisei_yeargoto: (fields[5] as List?)?.cast<int>(),
      meiseijuni: fields[6] as int,
      ikuseiryoku: fields[7] as int,
      mokuhyojuni: (fields[8] as List?)?.cast<int>(),
      inkarepoint: (fields[9] as List?)?.cast<int>(),
      time_taikai_total: (fields[10] as List?)?.cast<double>(),
      kukanjuni_taikai: (fields[11] as List?)?.cast<int>(),
      tuukajuni_taikai: (fields[12] as List?)?.cast<int>(),
      mokuhyojuniwositamawatteruflag: (fields[13] as List?)?.cast<int>(),
      juni_race: (fields[14] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      time_race: (fields[15] as List?)
          ?.map((dynamic e) => (e as List).cast<double>())
          ?.toList(),
      time_univtaikaikiroku: (fields[16] as List?)
          ?.map((dynamic e) => (e as List).cast<double>())
          ?.toList(),
      year_univtaikaikiroku: (fields[17] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      month_univtaikaikiroku: (fields[18] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      time_univkukankiroku: (fields[19] as List?)
          ?.map((dynamic e) => (e as List)
              .map((dynamic e) => (e as List).cast<double>())
              .toList())
          ?.toList(),
      year_univkukankiroku: (fields[20] as List?)
          ?.map((dynamic e) =>
              (e as List).map((dynamic e) => (e as List).cast<int>()).toList())
          ?.toList(),
      month_univkukankiroku: (fields[21] as List?)
          ?.map((dynamic e) =>
              (e as List).map((dynamic e) => (e as List).cast<int>()).toList())
          ?.toList(),
      name_univkukankiroku: (fields[22] as List?)
          ?.map((dynamic e) => (e as List)
              .map((dynamic e) => (e as List).cast<String>())
              .toList())
          ?.toList(),
      gakunen_univkukankiroku: (fields[23] as List?)
          ?.map((dynamic e) =>
              (e as List).map((dynamic e) => (e as List).cast<int>()).toList())
          ?.toList(),
      taikaientryflag: (fields[24] as List?)?.cast<int>(),
      taikaiseedflag: (fields[25] as List?)?.cast<int>(),
      taikaibetusaikoujuni: (fields[26] as List?)?.cast<int>(),
      taikaibetushutujoukaisuu: (fields[27] as List?)?.cast<int>(),
      taikaibetujunibetukaisuu: (fields[28] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      time_univkojinkiroku: (fields[29] as List?)
          ?.map((dynamic e) => (e as List).cast<double>())
          ?.toList(),
      year_univkojinkiroku: (fields[30] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      month_univkojinkiroku: (fields[31] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      name_univkojinkiroku: (fields[32] as List?)
          ?.map((dynamic e) => (e as List).cast<String>())
          ?.toList(),
      gakunen_univkojinkiroku: (fields[33] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      chokuzentaikai_zentaitaikaisinflag: fields[34] as int,
      chokuzentaikai_univtaikaisinflag: fields[35] as int,
      sankankaisuu: fields[36] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UnivGakurenData obj) {
    writer
      ..writeByte(37)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.r)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.name_tanshuku)
      ..writeByte(4)
      ..write(obj.meisei_total)
      ..writeByte(5)
      ..write(obj.meisei_yeargoto)
      ..writeByte(6)
      ..write(obj.meiseijuni)
      ..writeByte(7)
      ..write(obj.ikuseiryoku)
      ..writeByte(8)
      ..write(obj.mokuhyojuni)
      ..writeByte(9)
      ..write(obj.inkarepoint)
      ..writeByte(10)
      ..write(obj.time_taikai_total)
      ..writeByte(11)
      ..write(obj.kukanjuni_taikai)
      ..writeByte(12)
      ..write(obj.tuukajuni_taikai)
      ..writeByte(13)
      ..write(obj.mokuhyojuniwositamawatteruflag)
      ..writeByte(14)
      ..write(obj.juni_race)
      ..writeByte(15)
      ..write(obj.time_race)
      ..writeByte(16)
      ..write(obj.time_univtaikaikiroku)
      ..writeByte(17)
      ..write(obj.year_univtaikaikiroku)
      ..writeByte(18)
      ..write(obj.month_univtaikaikiroku)
      ..writeByte(19)
      ..write(obj.time_univkukankiroku)
      ..writeByte(20)
      ..write(obj.year_univkukankiroku)
      ..writeByte(21)
      ..write(obj.month_univkukankiroku)
      ..writeByte(22)
      ..write(obj.name_univkukankiroku)
      ..writeByte(23)
      ..write(obj.gakunen_univkukankiroku)
      ..writeByte(24)
      ..write(obj.taikaientryflag)
      ..writeByte(25)
      ..write(obj.taikaiseedflag)
      ..writeByte(26)
      ..write(obj.taikaibetusaikoujuni)
      ..writeByte(27)
      ..write(obj.taikaibetushutujoukaisuu)
      ..writeByte(28)
      ..write(obj.taikaibetujunibetukaisuu)
      ..writeByte(29)
      ..write(obj.time_univkojinkiroku)
      ..writeByte(30)
      ..write(obj.year_univkojinkiroku)
      ..writeByte(31)
      ..write(obj.month_univkojinkiroku)
      ..writeByte(32)
      ..write(obj.name_univkojinkiroku)
      ..writeByte(33)
      ..write(obj.gakunen_univkojinkiroku)
      ..writeByte(34)
      ..write(obj.chokuzentaikai_zentaitaikaisinflag)
      ..writeByte(35)
      ..write(obj.chokuzentaikai_univtaikaisinflag)
      ..writeByte(36)
      ..write(obj.sankankaisuu);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnivGakurenDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
