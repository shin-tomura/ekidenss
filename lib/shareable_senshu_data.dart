// lib/shareable_senshu_data.dart
import 'package:json_annotation/json_annotation.dart';

// part 'shareable_senshu_data.g.dart';を追記
part 'shareable_senshu_data.g.dart';

@JsonSerializable() // 追加
class ShareableSenshuData {
  int gakunen;
  String name;
  double magicnumber;
  double a;
  double b;
  int sositu;
  int sositu_bonus;
  int seichoutype;
  int genkaitoppakaisuu;
  int seichoukaisuu;
  int genkaichokumenkaisuu;
  int mokuhyo_b;
  double rirontime5000;
  double rirontime10000;
  double rirontimehalf;
  double kiroku_nyuugakuji_5000;
  List<double> time_bestkiroku;
  List<int> year_bestkiroku;
  List<int> month_bestkiroku;
  int konjou;
  int heijousin;
  int choukyorinebari;
  int spurtryoku;
  int kegaflag;
  int hirou;
  int kaifukuryoku;
  int anteikan;
  int chousi;
  int karisuma;
  int kazetaisei;
  int atusataisei;
  int samusataisei;
  int noboritekisei;
  int kudaritekisei;
  int noborikudarikirikaenouryoku;
  int tandokusou;
  int paceagesagetaiouryoku;

  // コンストラクタ
  ShareableSenshuData({
    required this.gakunen,
    required this.name,
    required this.magicnumber,
    required this.a,
    required this.b,
    required this.sositu,
    required this.sositu_bonus,
    required this.seichoutype,
    required this.genkaitoppakaisuu,
    required this.seichoukaisuu,
    required this.genkaichokumenkaisuu,
    required this.mokuhyo_b,
    required this.rirontime5000,
    required this.rirontime10000,
    required this.rirontimehalf,
    required this.kiroku_nyuugakuji_5000,
    required this.time_bestkiroku,
    required this.year_bestkiroku,
    required this.month_bestkiroku,
    required this.konjou,
    required this.heijousin,
    required this.choukyorinebari,
    required this.spurtryoku,
    required this.kegaflag,
    required this.hirou,
    required this.kaifukuryoku,
    required this.anteikan,
    required this.chousi,
    required this.karisuma,
    required this.kazetaisei,
    required this.atusataisei,
    required this.samusataisei,
    required this.noboritekisei,
    required this.kudaritekisei,
    required this.noborikudarikirikaenouryoku,
    required this.tandokusou,
    required this.paceagesagetaiouryoku,
  });

  // JSONからインスタンスを作成するファクトリコンストラクタを追加
  factory ShareableSenshuData.fromJson(Map<String, dynamic> json) =>
      _$ShareableSenshuDataFromJson(json);

  // インスタンスをJSONに変換するメソッドを追加
  Map<String, dynamic> toJson() => _$ShareableSenshuDataToJson(this);
}
