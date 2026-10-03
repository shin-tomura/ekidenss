import 'package:ekiden/kantoku_data.dart';

// ------------------------------------------------------------
// 能力のタイムへの影響度(1.8.2。「能力のタイムへの影響度設定」の画面で全大学共通に設定する)
//
// KantokuData.yobiint2 の
//   [68] 長距離粘り  [69] スパート力  [70] 登り適性  [71] 下り適性
//   [72] アップダウン対応力  [73] ロード適性  [74] ペース変動対応力
// 値は0なら100%(初期値)、1〜31なら(値−1)×10%(0%〜300%)
//
// ・能力50を基準に、能力の差を影響度の割合に広げたり縮めたりした値(小数)で補正を計算する
//   (補正はどれも能力の値に比例する形なので、「能力50のときの補正+影響度×(補正−能力50のときの補正)」と同じ)
//   0%なら全員が能力50と同じ補正になり、平均的なタイムの水準は変わらない
// ・初期値(100%)では元の能力の値と全く同じ値になるので、計算結果は変わらない
// ・駅伝と駅伝予選(大会番号0〜5)のレースの計算(RaceCalc.dart・RaceCalc_gakuren.dart)と
//   試走タイム(TrialTime.dart)で使う。記録会などのタイム(持ちタイム)には関係しない
// ・コンピュータスカウトの方針が「自動」の大学は、能力点の重みにもこの影響度を掛ける(scout_com.dart)
// ・大学の個性(実力発揮度)で増減した能力の値に対してかける
// ------------------------------------------------------------

const int nouryokuEikyodoNebariIndex = 68;
const int nouryokuEikyodoSpurtIndex = 69;
const int nouryokuEikyodoNoboriIndex = 70;
const int nouryokuEikyodoKudariIndex = 71;
const int nouryokuEikyodoUpdownIndex = 72;
const int nouryokuEikyodoRoadIndex = 73;
const int nouryokuEikyodoPaceIndex = 74;

/// 影響度の上限(%)
const int nouryokuEikyodoSaidai = 300;

/// 影響度(%)を読む。値が0なら100%(初期値)、1〜31なら(値−1)×10%
int nouryokuEikyodoPercent(KantokuData kantoku, int index) {
  if (kantoku.yobiint2.length <= index) return 100;
  final int v = kantoku.yobiint2[index];
  if (v < 1 || v > nouryokuEikyodoSaidai ~/ 10 + 1) return 100;
  return (v - 1) * 10;
}

/// yobiint2に保存する影響度の値として正しいか(0〜31。QRコードの読み込みで使う)
bool nouryokuEikyodoAtaiTadashii(int atai) {
  return atai >= 0 && atai <= nouryokuEikyodoSaidai ~/ 10 + 1;
}

/// 影響度(%)を、yobiint2に保存する値にする(100%は0、それ以外は%÷10+1)
int nouryokuEikyodoAtai(int percent) {
  int p = percent ~/ 10 * 10;
  if (p < 0) p = 0;
  if (p > nouryokuEikyodoSaidai) p = nouryokuEikyodoSaidai;
  if (p == 100) return 0;
  return p ~/ 10 + 1;
}

/// 7つの能力の影響度(1.0が100%)
class NouryokuEikyodo {
  final double nebari; // 長距離粘り
  final double spurt; // スパート力
  final double nobori; // 登り適性
  final double kudari; // 下り適性
  final double updown; // アップダウン対応力
  final double road; // ロード適性
  final double pace; // ペース変動対応力

  const NouryokuEikyodo({
    this.nebari = 1.0,
    this.spurt = 1.0,
    this.nobori = 1.0,
    this.kudari = 1.0,
    this.updown = 1.0,
    this.road = 1.0,
    this.pace = 1.0,
  });

  /// 設定(yobiint2[68]〜[74])から読む
  factory NouryokuEikyodo.fromKantoku(KantokuData kantoku) {
    double yomu(int index) => nouryokuEikyodoPercent(kantoku, index) / 100.0;
    return NouryokuEikyodo(
      nebari: yomu(nouryokuEikyodoNebariIndex),
      spurt: yomu(nouryokuEikyodoSpurtIndex),
      nobori: yomu(nouryokuEikyodoNoboriIndex),
      kudari: yomu(nouryokuEikyodoKudariIndex),
      updown: yomu(nouryokuEikyodoUpdownIndex),
      road: yomu(nouryokuEikyodoRoadIndex),
      pace: yomu(nouryokuEikyodoPaceIndex),
    );
  }

  /// 駅伝と駅伝予選(大会番号0〜5)なら設定から読み、それ以外のレースは初期値(100%)
  factory NouryokuEikyodo.forRace(KantokuData kantoku, int racebangou) {
    if (racebangou >= 0 && racebangou <= 5) {
      return NouryokuEikyodo.fromKantoku(kantoku);
    }
    return const NouryokuEikyodo();
  }

  /// 7つとも100%(初期値)か
  bool get shokiti =>
      nebari == 1.0 &&
      spurt == 1.0 &&
      nobori == 1.0 &&
      kudari == 1.0 &&
      updown == 1.0 &&
      road == 1.0 &&
      pace == 1.0;
}

/// 影響度を反映した能力の値(小数)。能力50を基準に、差を影響度の割合にする
/// 影響度1.0(100%)なら元の値と全く同じ値になる
double eikyodoNouryoku(int nouryoku, double eikyodo) {
  return 50.0 + eikyodo * (nouryoku - 50);
}
