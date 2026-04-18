// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shareable_senshu_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShareableSenshuData _$ShareableSenshuDataFromJson(Map<String, dynamic> json) =>
    ShareableSenshuData(
      gakunen: (json['gakunen'] as num).toInt(),
      name: json['name'] as String,
      magicnumber: (json['magicnumber'] as num).toDouble(),
      a: (json['a'] as num).toDouble(),
      b: (json['b'] as num).toDouble(),
      sositu: (json['sositu'] as num).toInt(),
      sositu_bonus: (json['sositu_bonus'] as num).toInt(),
      seichoutype: (json['seichoutype'] as num).toInt(),
      genkaitoppakaisuu: (json['genkaitoppakaisuu'] as num).toInt(),
      seichoukaisuu: (json['seichoukaisuu'] as num).toInt(),
      genkaichokumenkaisuu: (json['genkaichokumenkaisuu'] as num).toInt(),
      mokuhyo_b: (json['mokuhyo_b'] as num).toInt(),
      rirontime5000: (json['rirontime5000'] as num).toDouble(),
      rirontime10000: (json['rirontime10000'] as num).toDouble(),
      rirontimehalf: (json['rirontimehalf'] as num).toDouble(),
      kiroku_nyuugakuji_5000:
          (json['kiroku_nyuugakuji_5000'] as num).toDouble(),
      time_bestkiroku: (json['time_bestkiroku'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      year_bestkiroku: (json['year_bestkiroku'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      month_bestkiroku: (json['month_bestkiroku'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      konjou: (json['konjou'] as num).toInt(),
      heijousin: (json['heijousin'] as num).toInt(),
      choukyorinebari: (json['choukyorinebari'] as num).toInt(),
      spurtryoku: (json['spurtryoku'] as num).toInt(),
      kegaflag: (json['kegaflag'] as num).toInt(),
      hirou: (json['hirou'] as num).toInt(),
      kaifukuryoku: (json['kaifukuryoku'] as num).toInt(),
      anteikan: (json['anteikan'] as num).toInt(),
      chousi: (json['chousi'] as num).toInt(),
      karisuma: (json['karisuma'] as num).toInt(),
      kazetaisei: (json['kazetaisei'] as num).toInt(),
      atusataisei: (json['atusataisei'] as num).toInt(),
      samusataisei: (json['samusataisei'] as num).toInt(),
      noboritekisei: (json['noboritekisei'] as num).toInt(),
      kudaritekisei: (json['kudaritekisei'] as num).toInt(),
      noborikudarikirikaenouryoku:
          (json['noborikudarikirikaenouryoku'] as num).toInt(),
      tandokusou: (json['tandokusou'] as num).toInt(),
      paceagesagetaiouryoku: (json['paceagesagetaiouryoku'] as num).toInt(),
    );

Map<String, dynamic> _$ShareableSenshuDataToJson(
        ShareableSenshuData instance) =>
    <String, dynamic>{
      'gakunen': instance.gakunen,
      'name': instance.name,
      'magicnumber': instance.magicnumber,
      'a': instance.a,
      'b': instance.b,
      'sositu': instance.sositu,
      'sositu_bonus': instance.sositu_bonus,
      'seichoutype': instance.seichoutype,
      'genkaitoppakaisuu': instance.genkaitoppakaisuu,
      'seichoukaisuu': instance.seichoukaisuu,
      'genkaichokumenkaisuu': instance.genkaichokumenkaisuu,
      'mokuhyo_b': instance.mokuhyo_b,
      'rirontime5000': instance.rirontime5000,
      'rirontime10000': instance.rirontime10000,
      'rirontimehalf': instance.rirontimehalf,
      'kiroku_nyuugakuji_5000': instance.kiroku_nyuugakuji_5000,
      'time_bestkiroku': instance.time_bestkiroku,
      'year_bestkiroku': instance.year_bestkiroku,
      'month_bestkiroku': instance.month_bestkiroku,
      'konjou': instance.konjou,
      'heijousin': instance.heijousin,
      'choukyorinebari': instance.choukyorinebari,
      'spurtryoku': instance.spurtryoku,
      'kegaflag': instance.kegaflag,
      'hirou': instance.hirou,
      'kaifukuryoku': instance.kaifukuryoku,
      'anteikan': instance.anteikan,
      'chousi': instance.chousi,
      'karisuma': instance.karisuma,
      'kazetaisei': instance.kazetaisei,
      'atusataisei': instance.atusataisei,
      'samusataisei': instance.samusataisei,
      'noboritekisei': instance.noboritekisei,
      'kudaritekisei': instance.kudaritekisei,
      'noborikudarikirikaenouryoku': instance.noborikudarikirikaenouryoku,
      'tandokusou': instance.tandokusou,
      'paceagesagetaiouryoku': instance.paceagesagetaiouryoku,
    };
