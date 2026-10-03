import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:ekiden/kansuu/mokuhyou_hosei.dart';
import 'package:ekiden/kansuu/chousi_keiken_hosei.dart';

// ------------------------------------------------------------
// 「指示ごとの損得予測」の画面の計算(1.8.1)
//
// 駅伝(10月・11月・正月・カスタム)の2区以降で、走り出す直前の選手について、
// 指示なし・前半突っ込み(成功・失敗)・前半抑え(成功・失敗)のそれぞれで
// タイムが何秒変わるかを出す(レース画面の指示の欄の下から開く画面で使う)。
//
// ・倍率は RaceCalc.dart と同じ関数・定数(mokuhyou_hosei.dart)を使う
// ・倍率をかける元のタイム(指示の補正がかかる直前のタイム)は、
//   ±0.5%の濁しをかけない試走タイム(経験補正込み)×調子補正で出す。
//   本番ではこれに基本のタイムの±0.1%の揺れが入るだけなので、秒数のずれは0.1秒未満
// ・画面では「約○秒」と1秒単位に丸めて出す
// ------------------------------------------------------------

/// 襷を受けた時点の、目標順位との関係
enum SijiSontokuJoukyou {
  /// 目標順位を下回っている
  shitamawari,

  /// 目標順位ちょうど
  choudo,

  /// 目標順位を上回っている
  uwamawari,

  /// 正月駅伝の6区(往路の順位による補正はない)
  fukuroStart,
}

/// 指示ごとの損得(秒。正の値が損、負の値が得)
class SijiSontoku {
  final SijiSontokuJoukyou joukyou;

  /// 襷を受けた時点の通過順位(0が1位)
  final int juni;

  /// 目標順位(0が1位)
  final int mokuhyou;

  /// 目標順位の大学とのタイム差(秒。下回っているときだけ。分からなければnull)
  final double? timeSa;

  /// 前半突っ込みの成功率(%)。駅伝男の値
  final int tsukkomiSeikouritsu;

  /// 前半抑えの成功率(%)。平常心の値
  final int osaeSeikouritsu;

  /// 指示なし
  final double nashi;

  /// 前半突っ込みの成功・失敗
  final double tsukkomiSeikou;
  final double tsukkomiShippai;

  /// 前半抑えの成功・失敗
  final double osaeSeikou;
  final double osaeShippai;

  const SijiSontoku({
    required this.joukyou,
    required this.juni,
    required this.mokuhyou,
    required this.timeSa,
    required this.tsukkomiSeikouritsu,
    required this.osaeSeikouritsu,
    required this.nashi,
    required this.tsukkomiSeikou,
    required this.tsukkomiShippai,
    required this.osaeSeikou,
    required this.osaeShippai,
  });
}

/// 「指示ごとの損得予測」を出せる場面か(駅伝の2区以降)
/// [racebangou] 大会番号、[kukan] 今から走る区間(0が1区)
bool sijiSontokuTaishou(int racebangou, int kukan) {
  return ((racebangou >= 0 && racebangou <= 2) || racebangou == 5) &&
      kukan >= 1;
}

/// 今から走る区間の選手[senshuId]の、指示ごとの損得を計算する
/// 出せない場面やデータがおかしいときはnull
Future<SijiSontoku?> sijiSontokuKeisan(int senshuId) async {
  final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
  final KantokuData? kantoku = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (gh == null || kantoku == null) return null;

  final int racebangou = gh.hyojiracebangou;
  final int kukan = gh.nowracecalckukan;
  if (!sijiSontokuTaishou(racebangou, kukan)) return null;

  final List<SenshuData> sortedSenshu =
      Hive.box<SenshuData>('senshuBox').values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  final List<UnivData> sortedUniv = Hive.box<UnivData>('univBox').values
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  // 試走タイムの計算は、選手idと並びの番号が同じ前提
  if (senshuId < 0 ||
      senshuId >= sortedSenshu.length ||
      sortedSenshu[senshuId].id != senshuId) {
    return null;
  }
  final SenshuData senshu = sortedSenshu[senshuId];
  if (senshu.univid < 0 || senshu.univid >= sortedUniv.length) return null;
  final UnivData univ = sortedUniv[senshu.univid];

  final int idx = kukan - 1; // 襷を受けた時点(前の区間の終了時点)
  if (univ.mokuhyojuniwositamawatteruflag.length <= idx ||
      univ.tuukajuni_taikai.length <= idx ||
      univ.time_taikai_total.length <= idx ||
      univ.mokuhyojuni.length <= racebangou) {
    return null;
  }
  final int flag = univ.mokuhyojuniwositamawatteruflag[idx];
  final int mokuhyou = univ.mokuhyojuni[racebangou];
  final double kyoriMeter = gh.kyori_taikai_kukangoto[racebangou][kukan];

  // 指示の補正がかかる直前の見込みタイム(秒)
  double mikomiTime = await runTrialCalculation(
    senshuId,
    kukan,
    gh,
    sortedSenshu,
    sortedUniv,
    kantoku,
    nigosu: false,
    keikenHosei: true,
  );
  mikomiTime *= chousiHoseiBairitsu(senshu, kantoku);

  // 目標順位の大学とのタイム差(下回っているときだけ使う)
  double? timeSa;
  if (flag == 1) {
    timeSa = mokuhyouJuniTimeSa(
      univs: sortedUniv,
      jibunTime: univ.time_taikai_total[idx],
      mokuhyou: mokuhyou,
      kukan: kukan,
    );
  }
  // 差が分からない場合(通常は起こらない)は、RaceCalcと同じく最大の悪化にする
  final double timeSaKeisan = timeSa ?? double.infinity;

  // 倍率(RaceCalc.dartの指示の補正と同じ分け方)
  final double nashiBairitsu;
  final double osaeSeikouBairitsu;
  final double osaeShippaiBairitsu;
  if (flag == 1) {
    nashiBairitsu = mokuhyouTsukkomiBairitsu(
      timeSa: timeSaKeisan,
      kyoriMeter: kyoriMeter,
    );
    osaeSeikouBairitsu = sijiOsaeSeikouShitamawariBairitsu;
    osaeShippaiBairitsu = mokuhyouOsaeShippaiBairitsu(
      timeSa: timeSaKeisan,
      kyoriMeter: kyoriMeter,
    );
  } else {
    final int uwamawari = flag < 0 ? -flag : 0;
    nashiBairitsu = flag < 0 ? mokuhyouHitoikiBairitsu(uwamawari) : 1.0;
    osaeSeikouBairitsu = sijiOsaeSeikouBairitsu;
    osaeShippaiBairitsu = mokuhyouOsaeShippaiUwamawariBairitsu(uwamawari);
  }

  // 正月駅伝の6区は、往路のゴールの時点で目標順位の判定を0(ちょうど扱い)にしている
  final SijiSontokuJoukyou joukyou;
  if (racebangou == 2 && kukan == 5 && flag == 0) {
    joukyou = SijiSontokuJoukyou.fukuroStart;
  } else if (flag == 1) {
    joukyou = SijiSontokuJoukyou.shitamawari;
  } else if (flag < 0) {
    joukyou = SijiSontokuJoukyou.uwamawari;
  } else {
    joukyou = SijiSontokuJoukyou.choudo;
  }

  double byou(double bairitsu) => mikomiTime * (bairitsu - 1.0);

  return SijiSontoku(
    joukyou: joukyou,
    juni: univ.tuukajuni_taikai[idx],
    mokuhyou: mokuhyou,
    timeSa: timeSa,
    tsukkomiSeikouritsu: senshu.konjou.clamp(0, 100).toInt(),
    osaeSeikouritsu: senshu.heijousin.clamp(0, 100).toInt(),
    nashi: byou(nashiBairitsu),
    tsukkomiSeikou: byou(sijiTsukkomiSeikouBairitsu),
    tsukkomiShippai: byou(sijiTsukkomiShippaiBairitsu),
    osaeSeikou: byou(osaeSeikouBairitsu),
    osaeShippai: byou(osaeShippaiBairitsu),
  );
}
