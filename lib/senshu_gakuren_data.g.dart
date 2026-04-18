// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'senshu_gakuren_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SenshuGakurenDataAdapter extends TypeAdapter<Senshu_Gakuren_Data> {
  @override
  final int typeId = 10;

  @override
  Senshu_Gakuren_Data read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Senshu_Gakuren_Data(
      id: fields[0] as int,
      univid: fields[1] as int,
      gakunen: fields[2] as int,
      name: fields[3] as String,
      name_tanshuku: fields[4] as String,
      magicnumber: fields[5] as double,
      a: fields[6] as double,
      b: fields[7] as double,
      sositu: fields[8] as int,
      sositu_bonus: fields[9] as int,
      seichoutype: fields[10] as int,
      genkaitoppakaisuu: fields[11] as int,
      seichoukaisuu: fields[12] as int,
      genkaichokumenkaisuu: fields[13] as int,
      mokuhyo_b: fields[14] as int,
      rirontime5000: fields[15] as double,
      rirontime10000: fields[16] as double,
      rirontimehalf: fields[17] as double,
      kiroku_nyuugakuji_5000: fields[18] as double,
      time_bestkiroku: (fields[19] as List?)?.cast<double>(),
      year_bestkiroku: (fields[20] as List?)?.cast<int>(),
      month_bestkiroku: (fields[21] as List?)?.cast<int>(),
      zentaijuni_bestkiroku: (fields[22] as List?)?.cast<int>(),
      gakunaijuni_bestkiroku: (fields[23] as List?)?.cast<int>(),
      konjou: fields[24] as int,
      heijousin: fields[25] as int,
      choukyorinebari: fields[26] as int,
      spurtryoku: fields[27] as int,
      kegaflag: fields[28] as int,
      hirou: fields[29] as int,
      kaifukuryoku: fields[30] as int,
      anteikan: fields[31] as int,
      chousi: fields[32] as int,
      karisuma: fields[33] as int,
      kazetaisei: fields[34] as int,
      atusataisei: fields[35] as int,
      samusataisei: fields[36] as int,
      noboritekisei: fields[37] as int,
      kudaritekisei: fields[38] as int,
      noborikudarikirikaenouryoku: fields[39] as int,
      tandokusou: fields[40] as int,
      paceagesagetaiouryoku: fields[41] as int,
      entrykukan_race: (fields[42] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      kukanjuni_race: (fields[43] as List?)
          ?.map((dynamic e) => (e as List).cast<int>())
          ?.toList(),
      kukantime_race: (fields[44] as List?)
          ?.map((dynamic e) => (e as List).cast<double>())
          ?.toList(),
      time_taikai_total: fields[45] as double,
      speed: fields[46] as double,
      sijiflag: fields[47] as int,
      sijiseikouflag: fields[48] as int,
      startchokugotobidasiflag: fields[49] as int,
      startchokugotobidasiseikouflag: fields[50] as int,
      racechuukakuseiflag: fields[51] as int,
      kukannaijuni: (fields[52] as List?)?.cast<int>(),
      temp_juni: fields[53] as int,
      chokuzentaikai_pbflag: fields[54] as int,
      chokuzentaikai_kojinrekidaisinflag: fields[55] as int,
      chokuzentaikai_kojinunivsinflag: fields[56] as int,
      chokuzentaikai_zentaikukansinflag: fields[57] as int,
      chokuzentaikai_univkukansinflag: fields[58] as int,
      string_racesetumei: fields[59] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Senshu_Gakuren_Data obj) {
    writer
      ..writeByte(60)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.univid)
      ..writeByte(2)
      ..write(obj.gakunen)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.name_tanshuku)
      ..writeByte(5)
      ..write(obj.magicnumber)
      ..writeByte(6)
      ..write(obj.a)
      ..writeByte(7)
      ..write(obj.b)
      ..writeByte(8)
      ..write(obj.sositu)
      ..writeByte(9)
      ..write(obj.sositu_bonus)
      ..writeByte(10)
      ..write(obj.seichoutype)
      ..writeByte(11)
      ..write(obj.genkaitoppakaisuu)
      ..writeByte(12)
      ..write(obj.seichoukaisuu)
      ..writeByte(13)
      ..write(obj.genkaichokumenkaisuu)
      ..writeByte(14)
      ..write(obj.mokuhyo_b)
      ..writeByte(15)
      ..write(obj.rirontime5000)
      ..writeByte(16)
      ..write(obj.rirontime10000)
      ..writeByte(17)
      ..write(obj.rirontimehalf)
      ..writeByte(18)
      ..write(obj.kiroku_nyuugakuji_5000)
      ..writeByte(19)
      ..write(obj.time_bestkiroku)
      ..writeByte(20)
      ..write(obj.year_bestkiroku)
      ..writeByte(21)
      ..write(obj.month_bestkiroku)
      ..writeByte(22)
      ..write(obj.zentaijuni_bestkiroku)
      ..writeByte(23)
      ..write(obj.gakunaijuni_bestkiroku)
      ..writeByte(24)
      ..write(obj.konjou)
      ..writeByte(25)
      ..write(obj.heijousin)
      ..writeByte(26)
      ..write(obj.choukyorinebari)
      ..writeByte(27)
      ..write(obj.spurtryoku)
      ..writeByte(28)
      ..write(obj.kegaflag)
      ..writeByte(29)
      ..write(obj.hirou)
      ..writeByte(30)
      ..write(obj.kaifukuryoku)
      ..writeByte(31)
      ..write(obj.anteikan)
      ..writeByte(32)
      ..write(obj.chousi)
      ..writeByte(33)
      ..write(obj.karisuma)
      ..writeByte(34)
      ..write(obj.kazetaisei)
      ..writeByte(35)
      ..write(obj.atusataisei)
      ..writeByte(36)
      ..write(obj.samusataisei)
      ..writeByte(37)
      ..write(obj.noboritekisei)
      ..writeByte(38)
      ..write(obj.kudaritekisei)
      ..writeByte(39)
      ..write(obj.noborikudarikirikaenouryoku)
      ..writeByte(40)
      ..write(obj.tandokusou)
      ..writeByte(41)
      ..write(obj.paceagesagetaiouryoku)
      ..writeByte(42)
      ..write(obj.entrykukan_race)
      ..writeByte(43)
      ..write(obj.kukanjuni_race)
      ..writeByte(44)
      ..write(obj.kukantime_race)
      ..writeByte(45)
      ..write(obj.time_taikai_total)
      ..writeByte(46)
      ..write(obj.speed)
      ..writeByte(47)
      ..write(obj.sijiflag)
      ..writeByte(48)
      ..write(obj.sijiseikouflag)
      ..writeByte(49)
      ..write(obj.startchokugotobidasiflag)
      ..writeByte(50)
      ..write(obj.startchokugotobidasiseikouflag)
      ..writeByte(51)
      ..write(obj.racechuukakuseiflag)
      ..writeByte(52)
      ..write(obj.kukannaijuni)
      ..writeByte(53)
      ..write(obj.temp_juni)
      ..writeByte(54)
      ..write(obj.chokuzentaikai_pbflag)
      ..writeByte(55)
      ..write(obj.chokuzentaikai_kojinrekidaisinflag)
      ..writeByte(56)
      ..write(obj.chokuzentaikai_kojinunivsinflag)
      ..writeByte(57)
      ..write(obj.chokuzentaikai_zentaikukansinflag)
      ..writeByte(58)
      ..write(obj.chokuzentaikai_univkukansinflag)
      ..writeByte(59)
      ..write(obj.string_racesetumei);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SenshuGakurenDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
