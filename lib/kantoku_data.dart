import 'package:hive/hive.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート

part 'kantoku_data.g.dart'; // このファイル名に合わせてください

@HiveType(typeId: 8) // ユニークなtypeIdを指定
class KantokuData extends HiveObject {
  //[0~29監督、30~59コーチ1、60~89コーチ2]
  @HiveField(0)
  List<int> rid = List.filled(TEISUU.UNIVSUU * 3, 0); //Senshu_R_Dataのidを格納、0なら不在
  @HiveField(1)
  List<int> yobiint0 = List.filled(TEISUU.UNIVSUU * 3, 0); //プレイヤーが任命したフラグ
  @HiveField(2)
  List<int> yobiint1 = List.filled(TEISUU.UNIVSUU * 3, 0); //異動ありフラグ、4月上旬の表示に使う(「指導陣に異動がありました」などで)
  @HiveField(3)
  List<int> yobiint2 = List.filled(TEISUU.UNIVSUU * 3, 0); //[0]難易度極設定フラグ、[1]目標達成フラグ、[2]調子適用率、[3]区間エントリー時ピーキング成功確率、[4]ピーキング失敗からの当日復活確率、[5]当日突発的体調不良確率、[6]区間エントリー時突発的体調不良確率、[7]4年生安定感最低保証値、[8]3年生安定感最低保証値、[9]2年生安定感最低保証値、[10]コンピュータ選手には調子補正しないフラグ、[11]体調不良タイム悪化パーセント、[12]金銀支給量倍率、[13]長距離タイム全体抑制値、[14]記録会時期設定9月にするフラグ、[15]趣味非表示フラグ、[16]強化練習強度、[17]箱庭モードフラグ、[18]最初の画面を表示するためのモード、[19]夏のTT全大学やるフラグ、[20]選手画面レーダーチャートパネル非表示フラグ、[21]コンピュータの大学も体調不良発生するフラグ、[22]区間配置がうまくいかなかったので最適解区間配置を使わない方法ですべて再配置しなおしたフラグ、[23]フリーメモ画面で初期画面となるメモ番号、[24]から[32]レース分析画面のドロップダウンの項目を保持

  @HiveField(4)
  List<int> yobiint3 = List.filled(TEISUU.UNIVSUU * 3, 0); //[0から9]大会記録樹立時の各区間終了時点の経過タイム比較用
  @HiveField(5)
  List<int> yobiint4 = List.filled(TEISUU.UNIVSUU * 3, 0); //[0]から[9]従来全体区間記録、[10]から[19]従来学内区間記録、[20]従来全体大会記録、[21]従来学内大会記録、[30から39]10月駅伝での大会記録樹立時の各区間終了時点の経過タイム記録用、[40から49]11月駅伝、[50から59]正月駅伝、[80から89]カスタム駅伝
  @HiveField(6)
  List<int> yobiint5 = List.filled(TEISUU.UNIVSUU * 3, 0); //[0]から[29](数字はunivid)大学の個性(各能力ごとの実力発揮度合いを圧縮して格納)、[30から39]10月駅伝区間ごとタイム調整、[40から49]11月駅伝区間ごとタイム調整、[50から59]正月駅伝区間ごとタイム調整、[60]全体タイム調整、[80から89]カスタム駅伝区間ごとタイム調整

  // コンストラクタ (Swiftのinit()に対応)
  KantokuData(); // 引数なしのコンストラクタ

  // ★★★ 新規追加: toJson() - すべてのフィールドをMapにシリアライズ ★★★
  Map<String, dynamic> toJson() {
    return {
      'rid': rid,
      'yobiint0': yobiint0,
      'yobiint1': yobiint1,
      'yobiint2': yobiint2,
      'yobiint3': yobiint3,
      'yobiint4': yobiint4,
      'yobiint5': yobiint5,
    };
  }

  // ★★★ 新規追加: fromJson - jsonから新しいインスタンスを作成 ★★★
  factory KantokuData.fromJson(Map<String, dynamic> json) {
    return KantokuData()
      ..rid = (json['rid'] as List).cast<int>()
      ..yobiint0 = (json['yobiint0'] as List).cast<int>()
      ..yobiint1 = (json['yobiint1'] as List).cast<int>()
      ..yobiint2 = (json['yobiint2'] as List).cast<int>()
      ..yobiint3 = (json['yobiint3'] as List).cast<int>()
      ..yobiint4 = (json['yobiint4'] as List).cast<int>()
      ..yobiint5 = (json['yobiint5'] as List).cast<int>();
  }
}
