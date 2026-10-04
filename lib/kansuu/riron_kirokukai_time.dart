import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/ChoukyoriNebariHoseitime.dart';
import 'package:ekiden/kansuu/SpurtRyokuHoseitime.dart';
import 'package:ekiden/kansuu/TimeDesugiHoseiHoseitime.dart';
import 'package:ekiden/kansuu/univkosei.dart';
import 'package:ekiden/kansuu/nouryoku_eikyodo.dart';

// ------------------------------------------------------------
// 箱庭モードの選手の編集画面に出す理論値(1.8.5)
// 平地の記録会(5000m記録会・10000m記録会・市民ハーフ)で走ったときのタイムを、
// RaceCalc.dartと同じ計算で求める。RaceCalcの中から、この3つのレースで通る計算だけを写した。
// ・大学の個性(実力発揮度。留学生は5)、年間強化練習とその強度、全体タイム調整、
//   出過ぎ補正(長距離タイム全体抑制値と、15000mを超える距離のタイム補正の設定を含む)、
//   ロード適性(ハーフ)・ペース変動対応力(5000m・1万m)、長距離粘り、スパート力を入れる
// ・毎回の±0.1%の乱数は入れない(調子・経験・指示・集団走などは、もともとこの3つのレースにはない)
// ※RaceCalcで記録会のタイムの計算を変えたら、ここも直すこと
// ------------------------------------------------------------

/// 理論値を出す種目の距離(5000m・1万m・ハーフ)
const List<double> rironKirokukaiKyori = [5000.0, 10000.0, 21097.5];

/// 平地の記録会の理論値(秒)(1.8.5)
/// [kyori]は5000.0・10000.0・21097.5のどれか
/// [kihonSouryokuHyouji]は箱庭モードの基本走力の目盛りの値(b=1550に直したa_intに300を足した値)
/// [trainingNum]は年間強化練習のメニュー(SenshuData.kaifukuryoku)
/// [choukyoriTimeHosei]は15000mを超える距離のタイム補正の設定(sortedUnivData[9].name_tanshuku == "1")
double rironKirokukaiTime({
  required double kyori,
  required int kihonSouryokuHyouji,
  required int choukyorinebari,
  required int spurtryoku,
  required int tandokusou,
  required int paceagesagetaiouryoku,
  required int univid,
  required bool ryuugakusei,
  required int trainingNum,
  required KantokuData kantoku,
  required bool choukyoriTimeHosei,
}) {
  // RaceCalcのレース番号(10→5000記録会、11→10000記録会、12→市民ハーフ)
  final bool half = kyori > 15000.0;
  final int racebangou = half ? 12 : (kyori > 7500.0 ? 11 : 10);

  // 能力の値(大学の個性と年間強化練習。RaceCalcと同じ)
  final int kyoudo = kantoku.yobiint2[16];
  final Map<AbilityType, int> abilityValues = getAbilitySettingsForUniv(univid);
  int settei(AbilityType type) => ryuugakusei ? 5 : (abilityValues[type] ?? 0);

  int set_nebari = jitsuryokuHakkiNouryoku(
    choukyorinebari,
    settei(AbilityType.nagakyoriNebari),
  );
  if (trainingNum == 2) {
    set_nebari += kyoudo * 4 ~/ 2;
  } else if (trainingNum == 0) {
    set_nebari += kyoudo;
  }
  if (set_nebari < 1) set_nebari = 1;
  int set_spurt = jitsuryokuHakkiNouryoku(
    spurtryoku,
    settei(AbilityType.spurtPower),
  );
  if (trainingNum == 1) {
    set_spurt += kyoudo * 7 ~/ 2;
  } else if (trainingNum == 0) {
    set_spurt += kyoudo;
  }
  if (set_spurt < 1) set_spurt = 1;
  int set_road = jitsuryokuHakkiNouryoku(
    tandokusou,
    settei(AbilityType.roadTekisei),
  );
  if (trainingNum == 2) {
    set_road += kyoudo * 4 ~/ 2;
  } else if (trainingNum == 0) {
    set_road += kyoudo;
  }
  if (set_road < 1) set_road = 1;
  int set_pacehendou = jitsuryokuHakkiNouryoku(
    paceagesagetaiouryoku,
    settei(AbilityType.paceHendoTaiouryoku),
  );
  if (trainingNum == 1) {
    set_pacehendou += kyoudo * 7 ~/ 2;
  } else if (trainingNum == 0) {
    set_pacehendou += kyoudo;
  }
  if (set_pacehendou < 1) set_pacehendou = 1;
  // 能力のタイムへの影響度(駅伝と駅伝予選だけなので、記録会では元の値のまま)
  final NouryokuEikyodo nouryokuEikyodo = NouryokuEikyodo.forRace(
    kantoku,
    racebangou,
  );
  final double eikyou_nebari = eikyodoNouryoku(
    set_nebari,
    nouryokuEikyodo.nebari,
  );
  final double eikyou_spurt = eikyodoNouryoku(
    set_spurt,
    nouryokuEikyodo.spurt,
  );
  final double eikyou_road = eikyodoNouryoku(set_road, nouryokuEikyodo.road);
  final double eikyou_pacehendou = eikyodoNouryoku(
    set_pacehendou,
    nouryokuEikyodo.pace,
  );

  // 基本走力からの理論タイム(RaceCalcの_calculateOptimalXと同じbを使う)
  // 基本走力の目盛りの値は、b=1550・magicnumber=TEISUU.MAGICNUMBERでのa_int+300なので、そこから差を求める
  // (magicnumberはタイムの計算では打ち消し合うので、選手ごとの上限によらない)
  final double newbdouble = (265.46 - (1501501.5 / kyori)).clamp(4.0, 300.0) +
      1450.0;
  const int b_int = 1550;
  final int a_int = kihonSouryokuHyouji - 300;
  final int a_min_int =
      (b_int * b_int * 0.0333 - b_int * 114.25 + TEISUU.MAGICNUMBER).round();
  final int sa = a_int - a_min_int;
  final int new_a_min_int =
      (newbdouble * newbdouble * 0.0333 -
              newbdouble * 114.25 +
              TEISUU.MAGICNUMBER)
          .round();
  final double double_a = (new_a_min_int + sa) * 0.000000001;
  final double double_b = newbdouble * 0.0001;
  double time = double_a * kyori * kyori + double_b * kyori;

  // 全体タイム調整(区間ごとの調整は駅伝だけ)
  final double chousei_zentai = kantoku.yobiint5[60].toDouble() / 2.0;
  time *= (100.0 + chousei_zentai) / 100.0;

  // 出過ぎ補正
  if (ryuugakusei) {
    time += TimeDesugiHoseiHoseitime_ryuugakusei(kyori: kyori, mototime: time);
  } else {
    time += TimeDesugiHoseiHoseitime(kyori: kyori, mototime: time);
  }
  if (choukyoriTimeHosei) {
    time = adjustTargetedFastTime(timeMoto: time, distanceM: kyori);
  }

  // ロード適性(ハーフ)とペース変動対応力(5000m・1万m)
  const double tanihosei = 0.03 / 100.0;
  final double road = half ? eikyou_road : 100.0;
  final double pace = half ? 100.0 : eikyou_pacehendou;
  time += time * ((100 - road) * tanihosei);
  time += time * ((100 - pace) * tanihosei);

  // 長距離粘りとスパート力
  time += ChoukyoriNebariHoseitime(
    kyori: kyori,
    choukyorinebari: eikyou_nebari,
    zentaiyokuseiti: kantoku.yobiint2[13],
  );
  time += SpurtRyokuHoseitime(kyori: kyori, spurtRyoku: eikyou_spurt);
  return time;
}
