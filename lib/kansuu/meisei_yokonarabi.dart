import 'dart:math';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';

// ------------------------------------------------------------
// 名声上位の横並び(スカウトのとき)(2.0.2)
//
// 名声1位の大学がスカウトで抜け出して独走しやすいので、設定で、名声の上位K校(2〜29校)を、
// 新入生のスカウトの計算では同じ名声として扱えるようにする(入学時名声影響度設定の画面の、別の項目)。
// ・そろえ方は2つ(どちらも上位K校の中は横並びになる):
//   ・平均(初期値): 上位K校の平均にそろえる。上位K校の合計の取り分は変わらず、K+1位より下の大学には影響しない
//   ・名声1位: 名声1位の値にそろえる。上位K校がみな1位並みに強くなり、その分、K+1位より下の大学は選ばれにくくなる
// ・30校(全校)はない(平均にそろえると、抽選の重みはレベル0(完全ランダム)と同じになるため)
// ・効かせるところ(スカウトの計算だけ。名声の表示・目標順位・獲得名声などは変えない):
//   ・抽選の重み(ShozokusakiKettei_By_Univmeisei.dart の shozokuChuusenOmomi。コンピュータスカウトOFFの振り分け・
//     最後の志望・地区めぐり(声かけ)の争奪戦・地区めぐりの成功率の下限): 名声の順位ごとの倍率を掛けたあとの重みを
//     そろえる(yokonarabiOmomi)
//   ・名声そのもの(scout_com.dart の交渉の成功率と、全国一斉・地区めぐり(交渉)の争奪戦。コンピュータスカウトOFFの
//     交渉の成功率(9000Freshmankakutoku.dart)): 上位K校の名声をそろえる(scoutMeiseiMap)
//   ・強化プロジェクト・監督の母校パイプの「名声N位並み」は、そろえたあとの値で見る
// ・上位K校の並びは、名声の高い順(同じなら大学idの小さい順)。「名声1位の値」は、この並びの最初の大学の値
// ・保存: KantokuData.yobiint3[86] = 校数 + 100×そろえ方(校数は0=なし(初期値)・2〜29、
//   そろえ方は0=平均(初期値)・1=名声1位。新しいゲームでは0に戻る)
// ・各種設定のQRコードに含める(古いQRコードに含まれていなければ、今の設定のまま)
// ------------------------------------------------------------

/// KantokuData.yobiint3 の使用番号: 名声上位の横並び(校数 + 100×そろえ方)
const int yokonarabiIndex = 86;

/// 横並びにできる校数の下限と上限
const int yokonarabiSaishou = 2;
const int yokonarabiSaidai = 29;

/// そろえ方: 平均(初期値)・名声1位
const int yokonarabiHeikin = 0;
const int yokonarabiIchii = 1;

/// 校数として正しいか(0はなし)
bool _suuTadashii(int suu) =>
    suu == 0 || (suu >= yokonarabiSaishou && suu <= yokonarabiSaidai);

/// 保存する値として正しいか(QRコードの読み込みで使う)
bool yokonarabiTadashii(int v) =>
    v >= 0 &&
    _suuTadashii(v % 100) &&
    (v ~/ 100 == yokonarabiHeikin || v ~/ 100 == yokonarabiIchii);

/// 保存してある値(正しくなければ0)
int yokonarabiAtai(KantokuData? k) {
  if (k == null || k.yobiint3.length <= yokonarabiIndex) return 0;
  final int v = k.yobiint3[yokonarabiIndex];
  return yokonarabiTadashii(v) ? v : 0;
}

/// 保存する値を入れる(正しくない値は0。保存(save)は呼び出し側で行う)
void yokonarabiAtaiIreru(KantokuData k, int v) {
  if (k.yobiint3.length <= yokonarabiIndex) return;
  k.yobiint3[yokonarabiIndex] = yokonarabiTadashii(v) ? v : 0;
}

/// 名声上位の何校を横並びにするか(0はなし。監督のデータが読めなければ0)
int yokonarabiSuu(KantokuData? k) => yokonarabiAtai(k) % 100;

/// そろえ方(yokonarabiHeikin・yokonarabiIchii)
int yokonarabiHouhou(KantokuData? k) => yokonarabiAtai(k) ~/ 100;

/// 校数を変える(そろえ方はそのまま。正しくない値は0。保存(save)は呼び出し側で行う)
void yokonarabiIreru(KantokuData k, int suu) {
  yokonarabiAtaiIreru(
    k,
    (_suuTadashii(suu) ? suu : 0) + 100 * yokonarabiHouhou(k),
  );
}

/// そろえ方を変える(校数はそのまま。保存(save)は呼び出し側で行う)
void yokonarabiHouhouIreru(KantokuData k, int houhou) {
  final int h = houhou == yokonarabiIchii ? yokonarabiIchii : yokonarabiHeikin;
  yokonarabiAtaiIreru(k, yokonarabiSuu(k) + 100 * h);
}

/// 画面に出す名前(校数)
String yokonarabiMei(int suu) {
  if (suu == 2) return '上位2校(一騎打ち)';
  if (suu == 3) return '上位3校(三つ巴)';
  if (suu >= 4) return '上位$suu校';
  return 'なし';
}

/// 画面に出す名前(そろえ方)
String yokonarabiHouhouMei(int houhou) =>
    houhou == yokonarabiIchii ? '名声1位にそろえる' : '平均にそろえる';

/// スカウトの計算で使う、名声上位の横並びの設定(校数と、名声1位にそろえるか)
class YokonarabiSettei {
  /// 横並びにする校数(0はなし)
  final int suu;

  /// trueなら名声1位の値にそろえる(falseなら平均)
  final bool ichii;

  const YokonarabiSettei(this.suu, this.ichii);

  /// 横並びなし
  static const YokonarabiSettei nashi = YokonarabiSettei(0, false);

  /// 監督のデータから読む(読めなければなし)
  static YokonarabiSettei yomu(KantokuData? k) =>
      YokonarabiSettei(yokonarabiSuu(k), yokonarabiHouhou(k) == yokonarabiIchii);

  /// 効くか
  bool get kiku => suu >= yokonarabiSaishou;
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

/// [ids] の値([atai] の位置)をそろえる値(平均か、最初(名声1位)の値)
int _soroeru(List<int> ids, int Function(int id) atai, bool ichii) {
  if (ichii) return atai(ids.first);
  int goukei = 0;
  for (final int id in ids) {
    goukei += atai(id);
  }
  return (goukei / ids.length).round();
}

/// スカウトで使う名声(大学id → 名声)。横並びの設定なら、名声の上位K校を、平均か名声1位の名声にそろえる
/// (効かない設定なら、どの大学ももとの名声)
Map<int, int> scoutMeiseiMap(List<UnivData> univs, YokonarabiSettei s) {
  final Map<int, int> m = {for (final UnivData u in univs) u.id: u.meisei_total};
  if (!s.kiku || univs.length < 2) return m;
  final List<int> ids = _jouiIds(univs, min(s.suu, univs.length));
  final int atai = _soroeru(ids, (int id) => m[id] ?? 0, s.ichii);
  for (final int id in ids) {
    m[id] = atai;
  }
  return m;
}

/// 抽選の重み([omomi] は大学idの位置。shozokuChuusenOmomi)のうち、名声の上位K校の重みを、
/// 平均か名声1位の重みにそろえる(効かない設定なら何もしない)
void yokonarabiOmomi(List<int> omomi, List<UnivData> univs, YokonarabiSettei s) {
  if (!s.kiku || univs.length < 2) return;
  final List<int> ids = [
    for (final int id in _jouiIds(univs, min(s.suu, univs.length)))
      if (id >= 0 && id < omomi.length) id,
  ];
  if (ids.length < 2) return;
  final int atai = _soroeru(ids, (int id) => omomi[id], s.ichii);
  for (final int id in ids) {
    omomi[id] = atai;
  }
}
