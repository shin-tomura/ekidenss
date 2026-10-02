import 'package:ekiden/univ_data.dart';

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
// 指示(前半突っ込み・前半抑え)の成否と「ほっと一息」の倍率(1.8.1でここにまとめた)
// ・RaceCalc.dart と「指示ごとの損得」の画面(siji_sontoku.dart)の両方から使う
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

/// 「前半突っ込み」の指示に成功したときのタイムの倍率
const double sijiTsukkomiSeikouBairitsu = 0.99;

/// 「前半突っ込み」の指示に失敗したときのタイムの倍率
const double sijiTsukkomiShippaiBairitsu = 1.015;

/// 目標順位を下回って襷を受けたときに「前半抑え」の指示に成功したときのタイムの倍率
const double sijiOsaeSeikouShitamawariBairitsu = 0.999;

/// 目標順位ちょうどか上回って襷を受けたときに「前半抑え」の指示に成功したときのタイムの倍率
const double sijiOsaeSeikouBairitsu = 0.997;

/// ほっと一息の倍率の基本(上回った順位の数が0のときの値)
const double mokuhyouHitoikiKihon = 1.001;

/// ほっと一息の、上回った順位の数1つあたりの悪化割合
const double mokuhyouHitoikiKeisuu = 0.0002;

/// 目標順位を上回って襷を受けたときの「ほっと一息」のタイムの倍率
/// [uwamawariJunisuu] 目標順位を上回っている順位の数
double mokuhyouHitoikiBairitsu(int uwamawariJunisuu) {
  return mokuhyouHitoikiKihon + mokuhyouHitoikiKeisuu * uwamawariJunisuu;
}

/// 目標順位ちょうど(0)か上回って([uwamawariJunisuu]の数だけ)襷を受けたときに
/// 「前半抑え」の指示に失敗したときのタイムの倍率
/// ほっと一息の倍率+0.1%。ただし最小0.5%(目標順位ちょうどのときの値)
double mokuhyouOsaeShippaiUwamawariBairitsu(int uwamawariJunisuu) {
  final double hitoiki = mokuhyouHitoikiBairitsu(uwamawariJunisuu);
  const double saishou = 1.0 + mokuhyouOsaeShippaiSaishou;
  if (hitoiki < saishou) return saishou;
  return hitoiki + 0.001;
}

/// 最大の損になる差(秒)。[kyoriMeter] はこれから走る区間の距離(m)
double mokuhyouTsukkomiSaidaiSa(double kyoriMeter) {
  return mokuhyouTsukkomiByouPerKm * kyoriMeter / 1000.0;
}

/// 目標順位を下回ったときの「前半突っ込み」のタイムの倍率(1.0〜1.008)
/// [timeSa] 襷を受けた時点の、目標順位の大学とのタイム差(秒)
/// [kyoriMeter] これから走る区間の距離(m)
double mokuhyouTsukkomiBairitsu({
  required double timeSa,
  required double kyoriMeter,
}) {
  if (timeSa <= 0) return 1.0;
  final double saidaiSa = mokuhyouTsukkomiSaidaiSa(kyoriMeter);
  if (saidaiSa <= 0) return 1.0 + mokuhyouTsukkomiSaidai;
  final double wariai = (timeSa / saidaiSa).clamp(0.0, 1.0);
  return 1.0 + mokuhyouTsukkomiSaidai * wariai;
}

/// 目標順位を下回ったときに「前半抑え」の指示に失敗したときのタイムの倍率(1.005〜1.012)
/// 指示なしの場合の悪化(mokuhyouTsukkomiBairitsu)の1.5倍。ただし最小0.5%
/// [timeSa] 襷を受けた時点の、目標順位の大学とのタイム差(秒)
/// [kyoriMeter] これから走る区間の距離(m)
double mokuhyouOsaeShippaiBairitsu({
  required double timeSa,
  required double kyoriMeter,
}) {
  final double tsukkomi =
      mokuhyouTsukkomiBairitsu(timeSa: timeSa, kyoriMeter: kyoriMeter) - 1.0;
  final double akka = tsukkomi * mokuhyouOsaeShippaiKeisuu;
  return 1.0 +
      (akka < mokuhyouOsaeShippaiSaishou ? mokuhyouOsaeShippaiSaishou : akka);
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
