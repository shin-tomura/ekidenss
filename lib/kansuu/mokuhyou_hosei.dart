import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';

// ------------------------------------------------------------
// 目標順位を下回ったときの「前半突っ込み」の補正(1.7.9で差に比例する形に変更)
//
// ・襷を受けた時点(前の区間の終了時点)の通過順位が目標順位より下のとき、
//   指示なしの選手はタイムが悪くなる
// ・悪くなる割合 = 0.8% × (目標順位の大学とのタイム差 ÷ 最大の損になる差)、最大0.8%
//   最大の損になる差 = 1kmあたり3秒 × これから走る区間の距離(km)
//   (長い区間なら挽回できると考えて焦りにくい)
//   例: 20kmの区間なら60秒差以上で0.8%(今までと同じ)、30秒差なら0.4%、1秒差なら0.013%ほど
//   (1.7.8までは差に関係なく一律0.8%)
// ・目標順位を上回っているときの「ほっと一息」の補正は今まで通り(上回っている順位の数に応じる)
//
// 目標順位を下回ったときの「前半抑え」の指示の失敗(1.8.0で変更)
// ・前半抑えは上の「前半突っ込み」の悪化を消すための指示なので、失敗したときの悪化は
//   指示なしの場合の悪化の1.5倍にする(最大0.8%×1.5=1.2%で、前半突っ込みの指示の失敗の1.5%より小さい)
// ・ただし最小は0.5%(目標順位ちょうどで襷を受けたときの前半抑えの失敗と同じ。
//   差が小さいときに、目標順位ちょうどのときより失敗の損が小さくならないように)
//   例: 20kmの区間なら、25秒差までは0.5%、30秒差なら0.6%、60秒差以上で1.2%
//   (1.7.9までは差に関係なく一律1.5%)
// ・成功したときは今まで通り(0.1%良くなる)
//
// 指示(前半突っ込み・前半抑え)の成否と「ほっと一息」の倍率(1.8.1でここにまとめた。
// 1.8.2から、下の「補正の強さ」の設定を掛ける。以下の数値は初期値(強さ100%)のもの)
// ・RaceCalc.dart と「指示ごとの損得予測」の画面(siji_sontoku.dart)の両方から使う
//   (数値を変えるときはここだけを変えれば、画面の表示も一緒に変わる)
// ・前半突っ込み: 成功(確率は駅伝男の値%)で1%良くなり、失敗で1.5%悪くなる(順位に関係なし)
// ・前半抑え(確率は平常心の値%):
//   目標順位を下回って襷を受けたとき 成功で0.1%良くなり、失敗は上の通り
//   目標順位ちょうどか上回って襷を受けたとき 成功で0.3%良くなり、
//   失敗はほっと一息の悪化+0.1%(最小0.5%)
// ・ほっと一息(目標順位を上回って襷を受けた、指示なしの選手): 0.1%+上回った順位の数×0.02%悪くなる
// ------------------------------------------------------------

/// 最大の悪化割合(1.7.8までの一律の値)
const double mokuhyouTsukkomiSaidai = 0.008;

/// 最大の損になる差(1kmあたりの秒)
const double mokuhyouTsukkomiByouPerKm = 3.0;

/// 前半抑えの失敗の悪化は、指示なしの場合の悪化の何倍か
const double mokuhyouOsaeShippaiKeisuu = 1.5;

/// 前半抑えの失敗の最小の悪化割合(目標順位ちょうどのときの前半抑えの失敗と同じ)
const double mokuhyouOsaeShippaiSaishou = 0.005;

/// 「前半突っ込み」の指示に成功したときに良くなる割合
const double sijiTsukkomiSeikouWariai = 0.01;

/// 「前半突っ込み」の指示に失敗したときに悪くなる割合
const double sijiTsukkomiShippaiWariai = 0.015;

/// 目標順位を下回って襷を受けたときに「前半抑え」の指示に成功したときに良くなる割合
const double sijiOsaeSeikouShitamawariWariai = 0.001;

/// 目標順位ちょうどか上回って襷を受けたときに「前半抑え」の指示に成功したときに良くなる割合
const double sijiOsaeSeikouWariai = 0.003;

/// ほっと一息の悪化割合の基本(上回った順位の数が0のときの値)
const double mokuhyouHitoikiKihonWariai = 0.001;

/// ほっと一息の、上回った順位の数1つあたりの悪化割合
const double mokuhyouHitoikiKeisuu = 0.0002;

// ------------------------------------------------------------
// 補正の強さ(1.8.2。「目標順位・指示の補正設定」の画面で全大学共通に設定する)
//
// KantokuData.yobiint2 の
//   [64] 目標順位を下回ったときの悪化の強さ
//   [65] 目標順位を上回ったときのほっと一息の強さ
//   [66] 指示(前半突っ込み・前半抑え)が成功したときの効果の強さ
//   [67] 指示(前半突っ込み・前半抑え)が失敗したときの損の強さ
// 値は0なら100%(初期値)、1〜31なら(値−1)×10%(0%〜300%)
// ・上の割合に強さを掛ける
// ・前半抑えの失敗は、目標順位の補正の強さを反映した値(下回り時は指示なしの悪化の1.5倍、
//   ちょうど・上回り時はほっと一息+0.1%。どちらも最小0.5%)に、失敗の強さを掛ける
// ・駅伝の2区以降の補正だけにかかる(1区の飛び出しや駅伝予選の指示には関係しない)
// ・コンピュータの大学がどの選手に指示を出すか(駅伝男・平常心で決まる)は変わらない
// ------------------------------------------------------------

const int hoseiTsuyosaShitamawariIndex = 64;
const int hoseiTsuyosaHitoikiIndex = 65;
const int hoseiTsuyosaSeikouIndex = 66;
const int hoseiTsuyosaShippaiIndex = 67;

/// 補正の強さの上限(%)
const int hoseiTsuyosaSaidai = 300;

/// 補正の強さ(%)を読む。値が0なら100%(初期値)、1〜31なら(値−1)×10%
int hoseiTsuyosaPercent(KantokuData kantoku, int index) {
  if (kantoku.yobiint2.length <= index) return 100;
  final int v = kantoku.yobiint2[index];
  if (v < 1 || v > hoseiTsuyosaSaidai ~/ 10 + 1) return 100;
  return (v - 1) * 10;
}

/// yobiint2に保存する補正の強さの値として正しいか(0〜31。QRコードの読み込みで使う)
bool hoseiTsuyosaAtaiTadashii(int atai) {
  return atai >= 0 && atai <= hoseiTsuyosaSaidai ~/ 10 + 1;
}

/// 補正の強さ(%)を、yobiint2に保存する値にする(100%は0、それ以外は%÷10+1)
int hoseiTsuyosaAtai(int percent) {
  int p = percent ~/ 10 * 10;
  if (p < 0) p = 0;
  if (p > hoseiTsuyosaSaidai) p = hoseiTsuyosaSaidai;
  if (p == 100) return 0;
  return p ~/ 10 + 1;
}

/// 4つの補正の強さ(1.0が100%)
class HoseiTsuyosa {
  /// 目標順位を下回ったときの悪化の強さ
  final double shitamawari;

  /// ほっと一息の強さ
  final double hitoiki;

  /// 指示が成功したときの効果の強さ
  final double seikou;

  /// 指示が失敗したときの損の強さ
  final double shippai;

  const HoseiTsuyosa({
    this.shitamawari = 1.0,
    this.hitoiki = 1.0,
    this.seikou = 1.0,
    this.shippai = 1.0,
  });

  /// 設定(yobiint2[64]〜[67])から読む
  factory HoseiTsuyosa.fromKantoku(KantokuData kantoku) {
    return HoseiTsuyosa(
      shitamawari:
          hoseiTsuyosaPercent(kantoku, hoseiTsuyosaShitamawariIndex) / 100.0,
      hitoiki: hoseiTsuyosaPercent(kantoku, hoseiTsuyosaHitoikiIndex) / 100.0,
      seikou: hoseiTsuyosaPercent(kantoku, hoseiTsuyosaSeikouIndex) / 100.0,
      shippai: hoseiTsuyosaPercent(kantoku, hoseiTsuyosaShippaiIndex) / 100.0,
    );
  }

  /// 4つとも100%(初期値)か
  bool get shokiti =>
      shitamawari == 1.0 && hitoiki == 1.0 && seikou == 1.0 && shippai == 1.0;
}

/// 「前半突っ込み」の指示に成功したときのタイムの倍率(初期値0.99)
double sijiTsukkomiSeikouBairitsu(HoseiTsuyosa tsuyosa) {
  return 1.0 - sijiTsukkomiSeikouWariai * tsuyosa.seikou;
}

/// 「前半突っ込み」の指示に失敗したときのタイムの倍率(初期値1.015)
double sijiTsukkomiShippaiBairitsu(HoseiTsuyosa tsuyosa) {
  return 1.0 + sijiTsukkomiShippaiWariai * tsuyosa.shippai;
}

/// 目標順位を下回って襷を受けたときに「前半抑え」の指示に成功したときのタイムの倍率(初期値0.999)
double sijiOsaeSeikouShitamawariBairitsu(HoseiTsuyosa tsuyosa) {
  return 1.0 - sijiOsaeSeikouShitamawariWariai * tsuyosa.seikou;
}

/// 目標順位ちょうどか上回って襷を受けたときに「前半抑え」の指示に成功したときのタイムの倍率(初期値0.997)
double sijiOsaeSeikouBairitsu(HoseiTsuyosa tsuyosa) {
  return 1.0 - sijiOsaeSeikouWariai * tsuyosa.seikou;
}

/// 目標順位を上回って襷を受けたときの「ほっと一息」の悪化割合
/// [uwamawariJunisuu] 目標順位を上回っている順位の数
double mokuhyouHitoikiWariai(int uwamawariJunisuu, HoseiTsuyosa tsuyosa) {
  return (mokuhyouHitoikiKihonWariai +
          mokuhyouHitoikiKeisuu * uwamawariJunisuu) *
      tsuyosa.hitoiki;
}

/// 目標順位を上回って襷を受けたときの「ほっと一息」のタイムの倍率
/// [uwamawariJunisuu] 目標順位を上回っている順位の数
double mokuhyouHitoikiBairitsu(int uwamawariJunisuu, HoseiTsuyosa tsuyosa) {
  return 1.0 + mokuhyouHitoikiWariai(uwamawariJunisuu, tsuyosa);
}

/// 目標順位ちょうど(0)か上回って([uwamawariJunisuu]の数だけ)襷を受けたときに
/// 「前半抑え」の指示に失敗したときのタイムの倍率
/// ほっと一息の悪化+0.1%(ただし最小0.5%で、目標順位ちょうどのときはこの値)に、失敗の強さを掛ける
double mokuhyouOsaeShippaiUwamawariBairitsu(
  int uwamawariJunisuu,
  HoseiTsuyosa tsuyosa,
) {
  final double hitoiki = mokuhyouHitoikiWariai(uwamawariJunisuu, tsuyosa);
  final double akka = hitoiki < mokuhyouOsaeShippaiSaishou
      ? mokuhyouOsaeShippaiSaishou
      : hitoiki + 0.001;
  return 1.0 + akka * tsuyosa.shippai;
}

/// 最大の損になる差(秒)。[kyoriMeter] はこれから走る区間の距離(m)
double mokuhyouTsukkomiSaidaiSa(double kyoriMeter) {
  return mokuhyouTsukkomiByouPerKm * kyoriMeter / 1000.0;
}

/// 目標順位を下回ったときの「前半突っ込み」の悪化割合(初期値では0〜0.8%)
/// [timeSa] 襷を受けた時点の、目標順位の大学とのタイム差(秒)
/// [kyoriMeter] これから走る区間の距離(m)
double mokuhyouTsukkomiWariai({
  required double timeSa,
  required double kyoriMeter,
  required HoseiTsuyosa tsuyosa,
}) {
  if (timeSa <= 0) return 0.0;
  final double saidaiSa = mokuhyouTsukkomiSaidaiSa(kyoriMeter);
  final double wariai = saidaiSa <= 0
      ? 1.0
      : (timeSa / saidaiSa).clamp(0.0, 1.0);
  return mokuhyouTsukkomiSaidai * wariai * tsuyosa.shitamawari;
}

/// 目標順位を下回ったときの「前半突っ込み」のタイムの倍率(初期値では1.0〜1.008)
/// [timeSa] 襷を受けた時点の、目標順位の大学とのタイム差(秒)
/// [kyoriMeter] これから走る区間の距離(m)
double mokuhyouTsukkomiBairitsu({
  required double timeSa,
  required double kyoriMeter,
  required HoseiTsuyosa tsuyosa,
}) {
  return 1.0 +
      mokuhyouTsukkomiWariai(
        timeSa: timeSa,
        kyoriMeter: kyoriMeter,
        tsuyosa: tsuyosa,
      );
}

/// 目標順位を下回ったときに「前半抑え」の指示に失敗したときのタイムの倍率(初期値では1.005〜1.012)
/// 指示なしの場合の悪化の1.5倍(ただし最小0.5%)に、失敗の強さを掛ける
/// [timeSa] 襷を受けた時点の、目標順位の大学とのタイム差(秒)
/// [kyoriMeter] これから走る区間の距離(m)
double mokuhyouOsaeShippaiBairitsu({
  required double timeSa,
  required double kyoriMeter,
  required HoseiTsuyosa tsuyosa,
}) {
  final double akka =
      mokuhyouTsukkomiWariai(
        timeSa: timeSa,
        kyoriMeter: kyoriMeter,
        tsuyosa: tsuyosa,
      ) *
      mokuhyouOsaeShippaiKeisuu;
  return 1.0 +
      (akka < mokuhyouOsaeShippaiSaishou ? mokuhyouOsaeShippaiSaishou : akka) *
          tsuyosa.shippai;
}

/// 襷を受けた時点(区間[kukan]の前の区間の終了時点)の、目標順位の大学とのタイム差(秒)
/// [jibunTime] 自分のチームのその時点の通算タイム
/// [mokuhyou] 目標順位(0が1位)
/// 目標順位の大学が見つからない場合はnull
double? mokuhyouJuniTimeSa({
  required List<UnivData> univs,
  required double jibunTime,
  required int mokuhyou,
  required int kukan,
}) {
  if (kukan <= 0) return null;
  final int idx = kukan - 1;
  for (final UnivData u in univs) {
    if (u.tuukajuni_taikai.length > idx &&
        u.time_taikai_total.length > idx &&
        u.tuukajuni_taikai[idx] == mokuhyou) {
      return jibunTime - u.time_taikai_total[idx];
    }
  }
  return null;
}

/// 補正の根拠に付ける、目標順位の大学とのタイム差の文(例: 3位と32.0秒差)
/// 目標順位を下回っていないときや、差が分からないときは空文字
String mokuhyouSaBun({
  required List<UnivData> univs,
  required UnivData univ,
  required int racebangou,
  required int kukan,
}) {
  if (kukan <= 0) return '';
  final int idx = kukan - 1;
  if (univ.mokuhyojuni.length <= racebangou ||
      univ.time_taikai_total.length <= idx ||
      univ.tuukajuni_taikai.length <= idx) {
    return '';
  }
  final int mokuhyou = univ.mokuhyojuni[racebangou];
  if (univ.tuukajuni_taikai[idx] <= mokuhyou) return '';
  final double? sa = mokuhyouJuniTimeSa(
    univs: univs,
    jibunTime: univ.time_taikai_total[idx],
    mokuhyou: mokuhyou,
    kukan: kukan,
  );
  if (sa == null) return '';
  return '${mokuhyou + 1}位と${sa.toStringAsFixed(1)}秒差';
}
