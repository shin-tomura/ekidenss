// ------------------------------------------------------------
// 推移の図のための補正の秒(2.1.7)
//
// 情報集約パネルの「推移」(screens/Modal_ichiKankei.dart の _Katachi)で、長距離粘りとスパート力の補正の秒を、
// 計算の式どおりの場所に置くために、レースの計算(RaceCalc.dart・RaceCalc_gakuren.dart)で選手ごとに残す。
// ・長距離粘りの補正(ChoukyoriNebariHoseitime): 15kmを超えた距離100mごとに効く → 推移では15km地点から先に均等に置く
// ・スパート力の補正(SpurtRyokuHoseitime): 最後の800m(100m×8)で効く → 推移では最後の800mに均等に置く
// ・保存場所は SenshuData.speed / Senshu_Gakuren_Data.speed(小数。もとは速さを入れる欄だったが、入れる処理は
//   コメントになっていて、どこからも使っていなかった)。走るたびに書き換わるので、読むのは今の大会の選手だけ
// ・詰め方: 1兆 + (長距離粘りの補正の0.1秒単位 + 50万) × 1万 + (スパート力の補正の0.1秒単位 + 5000)
//   (どちらも符号付き。能力のタイムへの影響度の設定によっては、粘りが得に、スパートが損になることもある)。
//   2.1.6までの選手は0なので、読めない(null)
// ・レースのタイムには使わない(表示のためだけ)
// ------------------------------------------------------------

/// 詰めた値の始まり(これより小さい値は、2.1.6までの0など、詰めていない値)
const double _suiiHoseiKiten = 1000000000000.0;

/// 長距離粘りの補正[nebari](秒)とスパート力の補正[spurt](秒)を、speed の欄に入れる値にする
double suiiHoseiTsumeru(double nebari, double spurt) {
  final int n = (nebari * 10).round().clamp(-499999, 499999).toInt();
  final int s = (spurt * 10).round().clamp(-4999, 4999).toInt();
  return _suiiHoseiKiten + (n + 500000) * 10000.0 + (s + 5000);
}

/// speed の欄の値[atai]から、長距離粘りとスパート力の補正の秒を読む(詰めていない値ならnull)
({double nebari, double spurt})? suiiHoseiYomu(double atai) {
  if (!atai.isFinite || atai < _suiiHoseiKiten || atai >= _suiiHoseiKiten * 2) return null;
  final int v = (atai - _suiiHoseiKiten).round();
  final int s = v % 10000 - 5000;
  final int n = v ~/ 10000 - 500000;
  return (nebari: n / 10.0, spurt: s / 10.0);
}
