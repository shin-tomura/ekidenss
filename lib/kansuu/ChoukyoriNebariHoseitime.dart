import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスが定義されていると仮定します
import 'package:ekiden/senshu_gakuren_data.dart';

/// 長距離の粘り強さに応じたタイム補正値を計算します。
///
/// [kyori]: レースの距離 (メートル単位)。
/// [senshuid]: タイム補正を計算する選手のID。
/// [sortedsenshudata]: ID順にソートされた選手データのリスト。
///
/// 戻り値: 計算されたタイム補正値 (Double)。
double ChoukyoriNebariHoseitime({
  required double kyori,
  required int choukyorinebari,
  required int zentaiyokuseiti,
  //required int senshuid,
  //required List<SenshuData> sortedsenshudata,
}) {
  double gensuikyori_100m = 0.0;
  double tani = 0.0;
  double hoseitime = 0.0;

  // Swiftコードでコメントアウトされていた部分は、Dartコードでも反映しません。
  // if (sortedsenshudata[senshuid].choukyorinebari > 99) {
  //   sortedsenshudata[senshuid].choukyorinebari = 99;
  // }

  // 選手IDがリストの範囲内にあるかチェック (安全のため)
  /*if (senshuid < 0 || senshuid >= sortedsenshudata.length) {
    print('エラー: senshuid ($senshuid) が sortedSenshuData の範囲外です。');
    // エラーハンドリングとして0.0を返すか、例外をスローするなど検討
    return 0.0;
  }

  // 粘り強さの値を取得し、最大値を99に制限
  // Swiftのコメントアウトされたロジックを反映するなら、ここで最大値チェックを入れる
  int choukyorinebari = sortedsenshudata[senshuid].choukyorinebari;
  /*if (choukyorinebari > 99) {
    choukyorinebari = 99;
  }*/
  // ※ もし choukyorinebari の値を変更してHiveに保存する必要があるなら、
  //    この関数を async にして await senshu.save(); を呼ぶ必要がありますが、
  //    元のSwiftコードは副作用なしで値を計算して返すだけなので、ここでは行いません。
  //    （元のコメントアウト箇所も値を変更しようとしていたので、注意が必要です）
*/
  gensuikyori_100m = (kyori - 14999.999) / 100.0;
  int maxti = 117;
  if (zentaiyokuseiti < 0) {
    maxti += zentaiyokuseiti;
  }
  if (gensuikyori_100m > 0.0) {
    tani = TEISUU.MAXTIMEHOSEI_CHOUKYORINEBARI_PER100m / 98.0;
    //hoseitime = gensuikyori_100m * tani * (99 - choukyorinebari).toDouble();
    hoseitime = gensuikyori_100m * tani * (maxti - choukyorinebari).toDouble();
  }

  return hoseitime;
}

double ChoukyoriNebariHoseitime_gakuren({
  required double kyori,
  required int choukyorinebari,
  required int zentaiyokuseiti,
  //required int senshuid,
  //required List<Senshu_Gakuren_Data> gakurensenshudata,
}) {
  double gensuikyori_100m = 0.0;
  double tani = 0.0;
  double hoseitime = 0.0;

  // Swiftコードでコメントアウトされていた部分は、Dartコードでも反映しません。
  // if (sortedsenshudata[senshuid].choukyorinebari > 99) {
  //   sortedsenshudata[senshuid].choukyorinebari = 99;
  // }

  // 選手IDがリストの範囲内にあるかチェック (安全のため)
  /*if (senshuid < 0 || senshuid >= gakurensenshudata.length) {
    print('エラー: senshuid ($senshuid) が sortedSenshuData の範囲外です。');
    // エラーハンドリングとして0.0を返すか、例外をスローするなど検討
    return 0.0;
  }

  // 粘り強さの値を取得し、最大値を99に制限
  // Swiftのコメントアウトされたロジックを反映するなら、ここで最大値チェックを入れる
  int choukyorinebari = gakurensenshudata[senshuid].choukyorinebari;
  /*if (choukyorinebari > 99) {
    choukyorinebari = 99;
  }*/
  // ※ もし choukyorinebari の値を変更してHiveに保存する必要があるなら、
  //    この関数を async にして await senshu.save(); を呼ぶ必要がありますが、
  //    元のSwiftコードは副作用なしで値を計算して返すだけなので、ここでは行いません。
  //    （元のコメントアウト箇所も値を変更しようとしていたので、注意が必要です）
*/
  gensuikyori_100m = (kyori - 14999.999) / 100.0;
  int maxti = 117;
  if (zentaiyokuseiti < 0) {
    maxti += zentaiyokuseiti;
  }
  if (gensuikyori_100m > 0.0) {
    tani = TEISUU.MAXTIMEHOSEI_CHOUKYORINEBARI_PER100m / 98.0;
    //hoseitime = gensuikyori_100m * tani * (99 - choukyorinebari).toDouble();
    hoseitime = gensuikyori_100m * tani * (maxti - choukyorinebari).toDouble();
  }

  return hoseitime;
}
