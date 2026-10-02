import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';

// ------------------------------------------------------------
// 駅伝の調子補正と経験補正の計算(1.8.1で共通の関数にした)
//
// RaceCalc.dart(本番の計算)、TrialTime.dart(試走タイム)、
// ToujituHenkou_com.dart(コンピュータの当日変更の見込みタイム)、
// siji_sontoku.dart(「指示ごとの損得」の画面)から使う。
// 式を変えるときはここだけを変えれば、すべてに反映される。
// ------------------------------------------------------------

/// 調子によるタイム補正の倍率(駅伝(10月・11月・正月・カスタム)で使う)
/// ・調子のタイムへの影響度(yobiint2[2])が0%なら、体調不良も含めて補正しない(1.0)
/// ・体調不良(調子0)は、設定の体調不良タイム悪化パーセント(yobiint2[11])だけ悪くなる
/// ・それ以外は、(100−調子)×0.1%×影響度だけ悪くなる
double chousiHoseiBairitsu(SenshuData s, KantokuData kantoku) {
  if (kantoku.yobiint2[2] == 0) return 1.0;
  if (s.chousi == 0) {
    return 1.0 + kantoku.yobiint2[11].toDouble() / 100.0;
  }
  return 1.0 +
      (100 - s.chousi).toDouble() *
          0.001 *
          (kantoku.yobiint2[2].toDouble() / 100.0);
}

/// 経験補正の割合(負の値で、タイムが良くなる割合)
/// 駅伝(10月・11月・正月・カスタム)で、前の学年までに同じ駅伝の同じ区間を走った回数×0.3%良くなる
/// [racebangou] 大会番号、[kukan] 区間(0が1区)
double keikenHoseiWariai(SenshuData s, int racebangou, int kukan) {
  if (!((racebangou >= 0 && racebangou <= 2) || racebangou == 5)) {
    return 0.0;
  }
  double wariai = 0.0;
  for (int i_gakunen = s.gakunen - 1; i_gakunen >= 1; i_gakunen--) {
    final int entry = s.entrykukan_race[racebangou][i_gakunen - 1];
    if (entry >= 0 && entry == kukan) {
      wariai -= 0.003;
    }
  }
  return wariai;
}
