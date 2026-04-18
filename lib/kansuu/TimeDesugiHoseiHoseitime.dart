import 'dart:math'; // pow 関数を使う場合に必要ですが、コメントアウトされているので不要かもしれません
//import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
//import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';

/// 距離に応じて、タイムの「出過ぎ」を補正する（タイムを悪化させる）値を計算します。
///
/// [kyori]: レースの距離 (メートル単位)。
///
/// 戻り値: 計算されたタイム補正値 (Double)。
///
///

double adjustTargetedFastTime({
  required double timeMoto, // 元のタイム (秒, double)
  required double distanceM, // 走る距離 (メートル)
}) {
  // 1. 定数と基準値
  const double K = 0.8; // ペナルティの強さを決める調整係数 (0.4から0.8に倍増)
  //const double K = 0.6; // ペナルティの強さを決める調整係数 (0.4から0.8に倍増)

  // 距離と対応するターゲットペースの基準点
  const double distance10k = 10000.0; // 10000mの距離
  const double baseDistance = 15000.0; // 補正を開始する距離
  const double halfMarathonDistance = 21097.5; // ハーフマラソンの距離
  const double fullMarathonDistance = 42195.0; // フルマラソンの距離

  // ユーザー定義の基準ペース (秒/km)
  const double pace10k = 165.0; // 10000mでの基準ペース
  //const double paceHalf = 172.0583; // ハーフでの基準ペース60.30
  const double paceHalf = 170.63633; // ハーフでの基準ペース60.00
  //const double paceHalf = 169.21436; // ハーフでの基準ペース59.30

  const double paceFull = 184.856; // フルでの基準ペース

  // 2. 補正対象の距離判定
  if (distanceM <= baseDistance + 0.01) {
    return timeMoto; // 15000m以下は補正しない
  }

  // 3. 距離に応じたターゲットペースの決定 (線形補間)
  double targetPaceLimit;

  // 3-1. 15000mでの基準ペースを計算
  // 10kmとハーフのペースを基に、15000mのペースを線形補間で求める
  // 距離が10kmとハーフの間のどこにあるかを計算 (0から1)
  final double ratio15k =
      (baseDistance - distance10k) / (halfMarathonDistance - distance10k);
  // 15kmでのターゲットペース
  final double pace15k = pace10k + (paceHalf - pace10k) * ratio15k;

  if (distanceM <= halfMarathonDistance) {
    // 15km〜ハーフの距離の場合
    // 距離が15kmとハーフの間のどこにあるかを計算 (0から1)
    final double ratio =
        (distanceM - baseDistance) / (halfMarathonDistance - baseDistance);

    // ターゲットペース = 15kmペース + (ハーフペース - 15kmペース) * 比率
    targetPaceLimit = pace15k + (paceHalf - pace15k) * ratio;
  } else if (distanceM <= fullMarathonDistance) {
    // ハーフ〜フルマラソンの距離の場合
    // 距離がハーフとフルの間のどこにあるかを計算 (0から1)
    final double ratio =
        (distanceM - halfMarathonDistance) /
        (fullMarathonDistance - halfMarathonDistance);

    // ターゲットペース = ハーフペース + (フルペース - ハーフペース) * 比率
    targetPaceLimit = paceHalf + (paceFull - paceHalf) * ratio;
  } else {
    // フルマラソン以上の距離の場合 (フルのペースを上限とする)
    targetPaceLimit = paceFull;
  }

  // 4. 実際のペース計算
  final double distanceKm = distanceM / 1000.0;
  final double actualPace = timeMoto / distanceKm;

  // 5. 補正対象のペース判定
  // 実際のペースがターゲットペースより遅い場合（actualPace >= targetPaceLimit）は補正しない
  if (actualPace >= targetPaceLimit) {
    return timeMoto;
  }

  // --- 補正の計算 (境界で逆転を防ぐ修正ロジック) ---

  // 6. 基準ペースからの速度超過の割合 (ペナルティの強さ)
  // actualPace < targetPaceLimit なので、この項は正の値になる
  // 例: (170 - 160) / 170 = 0.0588 (5.88%速い)
  final double speedExceedRatio =
      (targetPaceLimit - actualPace) / targetPaceLimit;

  // 7. 補正によってペースが遅くなる割合
  // 速さの超過割合にペナルティ係数 K を乗じる
  final double paceSlowdownRatio = speedExceedRatio * K;

  // 8. 補正後のペースを計算
  // newPace = actualPace + (actualPace * paceSlowdownRatio)
  // 境界でのペナルティはゼロになり、滑らかに増加します。
  final double newPace = actualPace * (1.0 + paceSlowdownRatio);

  // 9. 補正後のタイム
  final double timeNew = newPace * distanceKm;

  return timeNew;
}
/*double adjustLongDistanceTime({
  required double timeMoto, // 元のタイム (秒)
  required double distanceM, // 走る距離 (メートル)
}) {
  // 調整係数 (提案値を使用)
  const double alpha = 0.012;
  const double beta = 0.00001;
  const double baseDistance = 10000.0; // 基準距離 (10000m)
  // 10000m以下の場合は補正を適用しない
  if (distanceM <= baseDistance + 0.01) {
    return timeMoto;
  }
  // 10000mを超えた分の倍率
  final double distanceFactor = (distanceM / baseDistance) - 1.0;
  // タイムの速さに応じた動的な調整係数 (alpha + beta * time_moto)
  final double penaltyCoefficient = alpha + (beta * timeMoto);
  // 補正係数 (1 + (penaltyCoefficient * distanceFactor))
  final double correctionFactor = 1.0 + (penaltyCoefficient * distanceFactor);
  // 補正後のタイム
  final double timeNew = timeMoto * correctionFactor;
  return timeNew;
}*/

/*double adjustLongDistanceTime({
  required double timeMoto, // 元のタイム (秒)
  required double distanceM, // 走る距離 (メートル)
}) {
  // 調整係数 (最終提案値)
  const double alpha = 0.002;
  const double beta = 200.0; // 非線形性を高めるため、大きな値に変更
  const double baseDistance = 10000.0; // 基準距離 (10000m)
  // 10000m以下の場合は補正を適用しない
  if (distanceM <= baseDistance + 0.01) {
    return timeMoto;
  }
  // 10000mを超えた分の倍率
  final double distanceFactor = (distanceM / baseDistance) - 1.0;
  // タイムの速さに応じた動的な調整係数 (alpha + beta / time_moto)
  // 非線形性により、速いタイム(timeMotoが小さい)ほどペナルティが大きくなる
  final double penaltyCoefficient = alpha + (beta / timeMoto);
  // 補正係数 (1 + (penaltyCoefficient * distanceFactor))
  final double correctionFactor = 1.0 + (penaltyCoefficient * distanceFactor);
  // 補正後のタイム
  final double timeNew = timeMoto * correctionFactor;
  return timeNew;
}*/

double TimeDesugiHoseiHoseitime_ryuugakusei({
  required double kyori,
  required double mototime,
}) {
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData kantoku = kantokuBox.get('KantokuData')!;
  double tani = 0.0;
  double hoseitime = 0.0;
  if (kyori < 30000.0) {
    tani = 40.0 / 25000.0;
    hoseitime = (30000.0 - kyori) * tani;
  }

  double sikiiti_byou = 2700.0;
  int zentaiyokuseiti = kantoku.yobiint2[13];
  if (zentaiyokuseiti < 0) {
    zentaiyokuseiti = 0;
  }
  if (mototime > sikiiti_byou) {
    hoseitime +=
        (mototime - sikiiti_byou) *
        (60.toDouble() / (3600.toDouble() - sikiiti_byou)) *
        (zentaiyokuseiti.toDouble() / 35.0);
  }
  /*if (kyori > 10000.0) {
    //10000mを超える距離のタイム抑制
    tani = kantoku.yobiint2[13] / 5000.0;
    hoseitime += (kyori - 10000.0) * tani;
  }*/
  return hoseitime;
}

double TimeDesugiHoseiHoseitime({
  required double kyori,
  required double mototime,
}) {
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData kantoku = kantokuBox.get('KantokuData')!;
  double tani = 0.0;
  double hoseitime = 0.0;

  // 距離が30000m未満の場合の補正ロジック
  // (元のSwiftコードのコメントにあるように、5000mだと25秒悪化、10000mだと0秒悪化)
  // Swiftのif (kyori<30000.0) に対応
  if (kyori < 30000.0) {
    tani = 45.0 / 25000.0;
    hoseitime = (30000.0 - kyori) * tani;
  }

  double sikiiti_byou = 2700.0;
  int zentaiyokuseiti = kantoku.yobiint2[13];
  if (zentaiyokuseiti < 0) {
    zentaiyokuseiti = 0;
  }
  if (mototime > sikiiti_byou) {
    hoseitime +=
        (mototime - sikiiti_byou) *
        (60.toDouble() / (3600.toDouble() - sikiiti_byou)) *
        (zentaiyokuseiti.toDouble() / 35.0);
  }
  /*if (kyori > 10000.0) {
    //15000mを超える距離のタイム抑制
    tani = kantoku.yobiint2[13] / 5000.0;
    hoseitime += (kyori - 10000.0) * tani;
  }*/
  //hoseitime+=0.0008155*pow(kyori,1.141421356);//たとえば10000mだと30秒タイムを悪化させる補正をする式(距離に応じて)

  return hoseitime;
}
