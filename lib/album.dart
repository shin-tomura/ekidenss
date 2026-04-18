import 'package:hive/hive.dart';
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート

part 'album.g.dart'; // このファイル名に合わせてください

@HiveType(typeId: 7) // ユニークなtypeIdを指定
class Album extends HiveObject {
  @HiveField(0)
  int tourokusuu_total = 0; //使わないことにしたのでこれも流用可能→最適解区間配置確率にした
  @HiveField(1)
  int hyojisenshunum = 0;
  @HiveField(2)
  int yobiint0 = 0; //学内記録の表示種類用(0個人記録、110月駅伝、211月駅伝、3正月駅伝、4カスタム駅伝)
  @HiveField(3)
  int yobiint1 = 0; //全体記録の表示種類用(0個人記録、110月駅伝、211月駅伝、3正月駅伝、4カスタム駅伝)
  @HiveField(4)
  int yobiint2 = 0; //記録画面の表示タブのindex保存用
  @HiveField(5)
  int yobiint3 = 0; //senshu_r_screenで、0自分の大学の卒業選手表示、2000以上だと選手画面の監督・コーチをタップして表示される単体表示用のrid
  @HiveField(6)
  int yobiint4 = 0; //学連選抜モチベーション低下補正、0補正なし、1から3補正ありで数字が大きいほど補正値が大きくなる
  @HiveField(7)
  int yobiint5 = 0; //学連選抜1区の選手のタイム補正用の本戦出場大学の1区のペースメーカのタイムを無理やりint型で保存

  // コンストラクタ (Swiftのinit()に対応)
  Album(); // 引数なしのコンストラクタ

  // ★★★ 新規追加: toJson() - すべてのフィールドをMapにシリアライズ ★★★
  Map<String, dynamic> toJson() {
    return {
      'tourokusuu_total': tourokusuu_total,
      'hyojisenshunum': hyojisenshunum,
      'yobiint0': yobiint0,
      'yobiint1': yobiint1,
      'yobiint2': yobiint2,
      'yobiint3': yobiint3,
      'yobiint4': yobiint4,
      'yobiint5': yobiint5,
    };
  }

  // ★★★ 新規追加: fromJson - jsonから新しいインスタンスを作成 ★★★
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album()
      ..tourokusuu_total = json['tourokusuu_total'] as int
      ..hyojisenshunum = json['hyojisenshunum'] as int
      ..yobiint0 = json['yobiint0'] as int
      ..yobiint1 = json['yobiint1'] as int
      ..yobiint2 = json['yobiint2'] as int
      ..yobiint3 = json['yobiint3'] as int
      ..yobiint4 = json['yobiint4'] as int
      ..yobiint5 = json['yobiint5'] as int;
  }
}
