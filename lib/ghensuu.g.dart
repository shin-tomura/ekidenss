// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ghensuu.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GhensuuAdapter extends TypeAdapter<Ghensuu> {
  @override
  final int typeId = 2;

  @override
  Ghensuu read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ghensuu()
      ..goldenballsuu = fields[0] as int
      ..last_goldenballkakutokusuu = fields[1] as int
      ..silverballsuu = fields[2] as int
      ..last_silverballkakutokusuu = fields[3] as int
      ..nouryokumieruflag = (fields[4] as List).cast<int>()
      ..SijiSelectedOption = (fields[5] as List).cast<int>()
      ..SenshuSelectedOption = (fields[6] as List).cast<int>()
      ..SenshuSelectedOption2 = (fields[7] as List).cast<int>()
      ..hyojisenshunum = fields[8] as int
      ..hyojiunivnum = fields[9] as int
      ..hyojiracebangou = fields[10] as int
      ..mode = fields[11] as int
      ..gamenflag = fields[12] as int
      ..year = fields[13] as int
      ..month = fields[14] as int
      ..day = fields[15] as int
      ..MYunivid = fields[16] as int
      ..ondoflag = fields[17] as int
      ..kazeflag = fields[18] as int
      ..name_mae = (fields[19] as List).cast<String>()
      ..name_ato = (fields[20] as List).cast<String>()
      ..spurtryokuseichousisuu1 = fields[21] as int
      ..spurtryokuseichousisuu2 = fields[22] as int
      ..spurtryokuseichousisuu3 = fields[23] as int
      ..spurtryokuseichousisuu4 = fields[24] as int
      ..spurtryokuseichousisuu5 = fields[25] as int
      ..seichouryoku_type_gakunen = (fields[26] as List)
          .map((dynamic e) => (e as List).cast<int>())
          .toList()
      ..seichouryoku_type_sentakuritu = (fields[27] as List).cast<int>()
      ..nowracecalckukan = fields[28] as int
      ..kukansuu_taikaigoto = (fields[29] as List).cast<int>()
      ..kyori_taikai_kukangoto = (fields[30] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList()
      ..heikinkoubainobori_taikai_kukangoto = (fields[31] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList()
      ..heikinkoubaikudari_taikai_kukangoto = (fields[32] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList()
      ..kyoriwariainobori_taikai_kukangoto = (fields[33] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList()
      ..kyoriwariaikudari_taikai_kukangoto = (fields[34] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList()
      ..noborikudarikirikaekaisuu_taikai_kukangoto = (fields[35] as List)
          .map((dynamic e) => (e as List).cast<int>())
          .toList()
      ..time_zentaitaikaikiroku = (fields[36] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList()
      ..year_zentaitaikaikiroku = (fields[37] as List)
          .map((dynamic e) => (e as List).cast<int>())
          .toList()
      ..month_zentaitaikaikiroku = (fields[38] as List)
          .map((dynamic e) => (e as List).cast<int>())
          .toList()
      ..univname_zentaitaikaikiroku = (fields[39] as List)
          .map((dynamic e) => (e as List).cast<String>())
          .toList()
      ..time_zentaikukankiroku = (fields[40] as List)
          .map((dynamic e) => (e as List)
              .map((dynamic e) => (e as List).cast<double>())
              .toList())
          .toList()
      ..year_zentaikukankiroku = (fields[41] as List)
          .map((dynamic e) =>
              (e as List).map((dynamic e) => (e as List).cast<int>()).toList())
          .toList()
      ..month_zentaikukankiroku = (fields[42] as List)
          .map((dynamic e) =>
              (e as List).map((dynamic e) => (e as List).cast<int>()).toList())
          .toList()
      ..univname_zentaikukankiroku = (fields[43] as List)
          .map((dynamic e) => (e as List)
              .map((dynamic e) => (e as List).cast<String>())
              .toList())
          .toList()
      ..name_zentaikukankiroku = (fields[44] as List)
          .map((dynamic e) => (e as List)
              .map((dynamic e) => (e as List).cast<String>())
              .toList())
          .toList()
      ..gakunen_zentaikukankiroku = (fields[45] as List)
          .map((dynamic e) =>
              (e as List).map((dynamic e) => (e as List).cast<int>()).toList())
          .toList()
      ..time_zentaikojinkiroku = (fields[46] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList()
      ..year_zentaikojinkiroku = (fields[47] as List)
          .map((dynamic e) => (e as List).cast<int>())
          .toList()
      ..month_zentaikojinkiroku = (fields[48] as List)
          .map((dynamic e) => (e as List).cast<int>())
          .toList()
      ..univname_zentaikojinkiroku = (fields[49] as List)
          .map((dynamic e) => (e as List).cast<String>())
          .toList()
      ..name_zentaikojinkiroku = (fields[50] as List)
          .map((dynamic e) => (e as List).cast<String>())
          .toList()
      ..gakunen_zentaikojinkiroku = (fields[51] as List)
          .map((dynamic e) => (e as List).cast<int>())
          .toList()
      ..scoutChances = fields[52] as int;
  }

  @override
  void write(BinaryWriter writer, Ghensuu obj) {
    writer
      ..writeByte(53)
      ..writeByte(0)
      ..write(obj.goldenballsuu)
      ..writeByte(1)
      ..write(obj.last_goldenballkakutokusuu)
      ..writeByte(2)
      ..write(obj.silverballsuu)
      ..writeByte(3)
      ..write(obj.last_silverballkakutokusuu)
      ..writeByte(4)
      ..write(obj.nouryokumieruflag)
      ..writeByte(5)
      ..write(obj.SijiSelectedOption)
      ..writeByte(6)
      ..write(obj.SenshuSelectedOption)
      ..writeByte(7)
      ..write(obj.SenshuSelectedOption2)
      ..writeByte(8)
      ..write(obj.hyojisenshunum)
      ..writeByte(9)
      ..write(obj.hyojiunivnum)
      ..writeByte(10)
      ..write(obj.hyojiracebangou)
      ..writeByte(11)
      ..write(obj.mode)
      ..writeByte(12)
      ..write(obj.gamenflag)
      ..writeByte(13)
      ..write(obj.year)
      ..writeByte(14)
      ..write(obj.month)
      ..writeByte(15)
      ..write(obj.day)
      ..writeByte(16)
      ..write(obj.MYunivid)
      ..writeByte(17)
      ..write(obj.ondoflag)
      ..writeByte(18)
      ..write(obj.kazeflag)
      ..writeByte(19)
      ..write(obj.name_mae)
      ..writeByte(20)
      ..write(obj.name_ato)
      ..writeByte(21)
      ..write(obj.spurtryokuseichousisuu1)
      ..writeByte(22)
      ..write(obj.spurtryokuseichousisuu2)
      ..writeByte(23)
      ..write(obj.spurtryokuseichousisuu3)
      ..writeByte(24)
      ..write(obj.spurtryokuseichousisuu4)
      ..writeByte(25)
      ..write(obj.spurtryokuseichousisuu5)
      ..writeByte(26)
      ..write(obj.seichouryoku_type_gakunen)
      ..writeByte(27)
      ..write(obj.seichouryoku_type_sentakuritu)
      ..writeByte(28)
      ..write(obj.nowracecalckukan)
      ..writeByte(29)
      ..write(obj.kukansuu_taikaigoto)
      ..writeByte(30)
      ..write(obj.kyori_taikai_kukangoto)
      ..writeByte(31)
      ..write(obj.heikinkoubainobori_taikai_kukangoto)
      ..writeByte(32)
      ..write(obj.heikinkoubaikudari_taikai_kukangoto)
      ..writeByte(33)
      ..write(obj.kyoriwariainobori_taikai_kukangoto)
      ..writeByte(34)
      ..write(obj.kyoriwariaikudari_taikai_kukangoto)
      ..writeByte(35)
      ..write(obj.noborikudarikirikaekaisuu_taikai_kukangoto)
      ..writeByte(36)
      ..write(obj.time_zentaitaikaikiroku)
      ..writeByte(37)
      ..write(obj.year_zentaitaikaikiroku)
      ..writeByte(38)
      ..write(obj.month_zentaitaikaikiroku)
      ..writeByte(39)
      ..write(obj.univname_zentaitaikaikiroku)
      ..writeByte(40)
      ..write(obj.time_zentaikukankiroku)
      ..writeByte(41)
      ..write(obj.year_zentaikukankiroku)
      ..writeByte(42)
      ..write(obj.month_zentaikukankiroku)
      ..writeByte(43)
      ..write(obj.univname_zentaikukankiroku)
      ..writeByte(44)
      ..write(obj.name_zentaikukankiroku)
      ..writeByte(45)
      ..write(obj.gakunen_zentaikukankiroku)
      ..writeByte(46)
      ..write(obj.time_zentaikojinkiroku)
      ..writeByte(47)
      ..write(obj.year_zentaikojinkiroku)
      ..writeByte(48)
      ..write(obj.month_zentaikojinkiroku)
      ..writeByte(49)
      ..write(obj.univname_zentaikojinkiroku)
      ..writeByte(50)
      ..write(obj.name_zentaikojinkiroku)
      ..writeByte(51)
      ..write(obj.gakunen_zentaikojinkiroku)
      ..writeByte(52)
      ..write(obj.scoutChances);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GhensuuAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
