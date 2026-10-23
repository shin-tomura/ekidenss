import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/shushou.dart' show shushouSotsugyouGyou;

// ------------------------------------------------------------
// 卒業直前の選手を、プレイヤーが自分でアルバムに足す(2.1.4で、選手画面のボタンの処理をここにまとめた)
//
// ・足せるのは3月25日の、自分の大学の4年生だけ(選手画面の「この選手をアルバムに追加」と、
//   学内メディアの卒業生特集の選手ごとのボタン(screens/album_tsuika_botan.dart)。どちらも同じ日・同じ選手)
// ・アルバムの番号は「枠の番号+今の年×1000」。3月25日の年は卒業する年なので、卒業の処理(RetireNew)で
//   作る卒業生の番号と同じになり、卒業の処理は、もうある番号の選手を作り直さない(自分で足した印を残すため)
// ・自分で足した印(sijiseikouflag=100)の選手は、年を取ってもアルバムから消さない(RetireNew)
// ・経歴の最初には、卒業の処理と同じく、主将を務めた年度を書く(2.1.4から。それまでは空にしていたので、
//   自分で足した選手には主将の年度が出なかった)。終わる年度は、卒業の処理と同じく「今の年−1」
// ・取り消すと、自分で足した印の選手だけを消す(足さなかったときと同じになり、卒業の処理でいつもどおり扱う)
// ------------------------------------------------------------

/// 選手[s]を今日アルバムに足したときの番号(枠の番号+今の年×1000)
int albumTsuikaBangou(Ghensuu gh, SenshuData s) => s.id + gh.year * 1000;

/// 今日、選手[s]をアルバムに足せるか(3月25日の、自分の大学の4年生)
bool albumTsuikaDekiru(Ghensuu gh, SenshuData s) =>
    gh.month == 3 && gh.day == 25 && s.gakunen == 4 && s.univid == gh.MYunivid;

/// 選手[s]を、もう自分でアルバムに足しているか
bool albumTsuikaZumi(Ghensuu gh, SenshuData s) {
  if (!Hive.isBoxOpen('retiredSenshuBox')) return false;
  final Senshu_R_Data? r =
      Hive.box<Senshu_R_Data>('retiredSenshuBox').get(albumTsuikaBangou(gh, s));
  return r != null && r.sijiseikouflag == 100;
}

/// 選手[s]をアルバムに足す(もういれば上書きする)。足した卒業生のデータを返す
Future<Senshu_R_Data> albumNiTsuika(Ghensuu gh, SenshuData s) async {
  final Box<Senshu_R_Data> retiredSenshuBox = Hive.box<Senshu_R_Data>('retiredSenshuBox');
  // 現役選手データを卒業選手データに変換 (fromSenshuDataファクトリを使用)
  final Senshu_R_Data retiredSenshu = Senshu_R_Data.fromSenshuData(s);
  // sijiflag（卒業年）idを設定
  final int currentYear = gh.year;
  retiredSenshu.sijiflag = currentYear;
  retiredSenshu.id += currentYear * 1000;
  retiredSenshu.string_racesetumei = _shushouGyou(s, currentYear - 1);
  retiredSenshu.sijiseikouflag = 100; //プレイヤーが自分でアルバムに追加した印
  // Hive Boxに保存
  await retiredSenshuBox.put(retiredSenshu.id, retiredSenshu);
  return retiredSenshu;
}

/// 自分でアルバムに足した選手[s]を取り消す(自分で足した印のない選手は消さない)
Future<void> albumKaraTorikesu(Ghensuu gh, SenshuData s) async {
  if (!albumTsuikaZumi(gh, s)) return;
  await Hive.box<Senshu_R_Data>('retiredSenshuBox').delete(albumTsuikaBangou(gh, s));
}

/// 経歴の最初の、主将を務めた年度の行(主将でなければ空。卒業の処理と同じ。分からなければ空)
String _shushouGyou(SenshuData s, int owattaNendo) {
  try {
    if (!Hive.isBoxOpen('kantokuBox') || !Hive.isBoxOpen('univBox')) return '';
    final KantokuData? kantoku = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
    if (kantoku == null) return '';
    UnivData? u;
    for (final UnivData x in Hive.box<UnivData>('univBox').values) {
      if (x.id == s.univid) {
        u = x;
        break;
      }
    }
    return shushouSotsugyouGyou(kantoku, s, owattaNendo, u?.name ?? '');
  } catch (_) {
    return '';
  }
}
