import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';

// ------------------------------------------------------------
// 学連選抜用の写しへの反映(1.8.8)
//
// 学連選抜の選手は、正月駅伝のエントリーの処理で、所属大学の選手データ(SenshuData)とは別に
// 学連選抜用の写し(Senshu_Gakuren_Data。gakurenSenshuBox に、同じ id で入る)が作られ、
// 正月駅伝の学連選抜のタイムと、区間配置確認などの学連選抜の表示は、この写しで計算する。
// 箱庭モードの能力編集・名前の編集・選手のQRコードの読み込みは、元の選手データだけを書き換えていたため、
// 写しを作ったあと(学連選抜編成の画面やレースの途中)に編集しても、学連選抜の走りに届かなかった。
// そこで、これらで選手データを書き換えたときに、写しがあれば同じ値を写しにも書く。
// ・写すのは、名前・基本走力(a・b・上限)・能力値・安定感・調子・年間強化練習メニュー
//   (箱庭モードで直接編集したものなので、学連選抜用に引き直した調子より、編集した値を優先する)
// ・区間や指示・レースの結果など、学連選抜用の項目は変えない
// ・去年の写しが残っていても、同じ選手なら書いて差し支えない(次の正月駅伝のエントリーで作り直す)
// ------------------------------------------------------------

/// 選手[s]の学連選抜用の写しがあれば、編集できる項目を写しにも書いて保存する
Future<void> gakurenUtsushiNiHanei(SenshuData s) async {
  final Box<Senshu_Gakuren_Data> box = Hive.box<Senshu_Gakuren_Data>(
    'gakurenSenshuBox',
  );
  final Senshu_Gakuren_Data? g = box.get(s.id);
  if (g == null || g.id != s.id) return;
  g
    ..name = s.name
    ..a = s.a
    ..b = s.b
    ..magicnumber = s.magicnumber
    ..kaifukuryoku = s.kaifukuryoku
    ..chousi = s.chousi
    ..anteikan = s.anteikan
    ..konjou = s.konjou
    ..heijousin = s.heijousin
    ..choukyorinebari = s.choukyorinebari
    ..spurtryoku = s.spurtryoku
    ..karisuma = s.karisuma
    ..noboritekisei = s.noboritekisei
    ..kudaritekisei = s.kudaritekisei
    ..noborikudarikirikaenouryoku = s.noborikudarikirikaenouryoku
    ..tandokusou = s.tandokusou
    ..paceagesagetaiouryoku = s.paceagesagetaiouryoku;
  await g.save();
}
