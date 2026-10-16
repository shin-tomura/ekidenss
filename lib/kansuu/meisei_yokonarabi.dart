import 'dart:math';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';

// ------------------------------------------------------------
// 名声上位の横並び(スカウトのとき)(2.0.2)
//
// 名声1位の大学がスカウトで抜け出して独走しやすいので、設定で、名声の上位K校(2〜10校)を、
// 新入生のスカウトの計算では同じ名声として扱えるようにする(入学時名声影響度設定の画面の、別の項目)。
// ・同じにする値は、上位K校の平均(上位K校の合計の取り分は変わらず、その中だけ横並びになる。
//   K+1位より下の大学には影響しない)
// ・効かせるところ(スカウトの計算だけ。名声の表示・目標順位・獲得名声などは変えない):
//   ・抽選の重み(ShozokusakiKettei_By_Univmeisei.dart の shozokuChuusenOmomi。コンピュータスカウトOFFの振り分け・
//     最後の志望・地区めぐり(声かけ)の争奪戦・地区めぐりの成功率の下限): 名声の順位ごとの倍率を掛けたあとの重みを、
//     上位K校の平均にそろえる(yokonarabiOmomi)
//   ・名声そのもの(scout_com.dart の交渉の成功率と、全国一斉・地区めぐり(交渉)の争奪戦。コンピュータスカウトOFFの
//     交渉の成功率(9000Freshmankakutoku.dart)): 上位K校の名声を平均にそろえる(scoutMeiseiMap)
//   ・強化プロジェクト・監督の母校パイプの「名声N位並み」は、そろえたあとの値で見る
// ・上位K校の並びは、名声の高い順(同じなら大学idの小さい順)
// ・保存: KantokuData.yobiint3[86](0=なし(初期値)、2〜10=上位何校か。新しいゲームでは0に戻る)
// ・各種設定のQRコードに含める(古いQRコードに含まれていなければ、今の設定のまま)
// ------------------------------------------------------------

/// KantokuData.yobiint3 の使用番号: 名声上位の横並び(0=なし、2〜10=上位何校か)
const int yokonarabiIndex = 86;

/// 横並びにできる校数の下限と上限
const int yokonarabiSaishou = 2;
const int yokonarabiSaidai = 10;

/// 設定の値として正しいか(QRコードの読み込みで使う)
bool yokonarabiTadashii(int v) =>
    v == 0 || (v >= yokonarabiSaishou && v <= yokonarabiSaidai);

/// 名声上位の何校を横並びにするか(0はなし。監督のデータが読めなければ0)
int yokonarabiSuu(KantokuData? k) {
  if (k == null || k.yobiint3.length <= yokonarabiIndex) return 0;
  final int v = k.yobiint3[yokonarabiIndex];
  return yokonarabiTadashii(v) ? v : 0;
}

/// 名声上位の何校を横並びにするかを変える(正しくない値は0。保存(save)は呼び出し側で行う)
void yokonarabiIreru(KantokuData k, int suu) {
  if (k.yobiint3.length <= yokonarabiIndex) return;
  k.yobiint3[yokonarabiIndex] = yokonarabiTadashii(suu) ? suu : 0;
}

/// 画面に出す名前
String yokonarabiMei(int suu) {
  if (suu == 2) return '上位2校(一騎打ち)';
  if (suu == 3) return '上位3校(三つ巴)';
  if (suu >= 4) return '上位$suu校';
  return 'なし';
}

/// 名声の上位[suu]校の大学id(名声の高い順、同じなら大学idの小さい順)
List<int> _jouiIds(List<UnivData> univs, int suu) {
  final List<UnivData> jun = List<UnivData>.of(univs)
    ..sort((a, b) {
      final int c = b.meisei_total.compareTo(a.meisei_total);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  return [for (final UnivData u in jun.take(suu)) u.id];
}

/// スカウトで使う名声(大学id → 名声)。横並びの設定なら、名声の上位[suu]校を、その平均にそろえる
/// ([suu] が2より小さければ、どの大学ももとの名声)
Map<int, int> scoutMeiseiMap(List<UnivData> univs, int suu) {
  final Map<int, int> m = {for (final UnivData u in univs) u.id: u.meisei_total};
  if (suu < yokonarabiSaishou || univs.length < 2) return m;
  final List<int> ids = _jouiIds(univs, min(suu, univs.length));
  int goukei = 0;
  for (final int id in ids) {
    goukei += m[id] ?? 0;
  }
  final int heikin = (goukei / ids.length).round();
  for (final int id in ids) {
    m[id] = heikin;
  }
  return m;
}

/// 抽選の重み([omomi] は大学idの位置。shozokuChuusenOmomi)のうち、名声の上位[suu]校の重みを、
/// その平均にそろえる([suu] が2より小さければ何もしない)
void yokonarabiOmomi(List<int> omomi, List<UnivData> univs, int suu) {
  if (suu < yokonarabiSaishou || univs.length < 2) return;
  final List<int> ids = [
    for (final int id in _jouiIds(univs, min(suu, univs.length)))
      if (id >= 0 && id < omomi.length) id,
  ];
  if (ids.length < 2) return;
  int goukei = 0;
  for (final int id in ids) {
    goukei += omomi[id];
  }
  final int heikin = (goukei / ids.length).round();
  for (final int id in ids) {
    omomi[id] = heikin;
  }
}
