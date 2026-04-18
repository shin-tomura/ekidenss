import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスが定義されていると仮定します
import 'package:ekiden/senshu_gakuren_data.dart';

/// スパート力に応じたタイム補正値を計算します。
///
/// [kyori]: レースの距離 (メートル単位)。この関数では現在未使用ですが、引数として残します。
/// [senshuid]: タイム補正を計算する選手のID。
/// [sortedsenshudata]: ID順にソートされた選手データのリスト。
///
/// 戻り値: 計算されたタイム補正値 (Double)。
double SpurtRyokuHoseitime({
  required double kyori,
  required int spurtRyoku,
  //required int senshuid,
  //required List<SenshuData> sortedsenshudata,
}) {
  double spurtkyori_100m = 0.0;
  double tani = 0.0;
  double hoseitime = 0.0;

  // Swiftコードでコメントアウトされていた部分は、Dartコードでも反映しません。
  // if (sortedsenshudata[senshuid].spurtryoku > 99) {
  //   sortedsenshudata[senshuid].spurtryoku = 99;
  // }

  // 選手IDがリストの範囲内にあるかチェック (安全のため)
  /*if (senshuid < 0 || senshuid >= sortedsenshudata.length) {
    print('エラー: senshuid ($senshuid) が sortedSenshuData の範囲外です。');
    // エラーハンドリングとして0.0を返すか、例外をスローするなど検討
    return 0.0;
  }

  // スパート力の値を取得し、最大値を99に制限（元のSwiftコメントアウトに沿うなら）
  int spurtRyoku = sortedsenshudata[senshuid].spurtryoku;
  /*if (spurtRyoku > 99) {
    spurtRyoku = 99;
  }*/
  // ※ ChoukyoriNebariHoseitime と同様に、この関数は値を返すだけで、
  //    選手データ自体を変更してHiveに保存する機能は持っていません。
*/
  // 距離に関係なく一律処理に変更（元のSwiftコードのコメントアウトに従う）
  // spurtkyori_100m=(kyori*2/50.0)/100.0;
  spurtkyori_100m = 8.0;

  if (spurtkyori_100m > 0.0) {
    tani = TEISUU.MAXTIMEHOSEI_SPURTRYOKU_PER100m / 98.0;
    // Dartでは int から double への変換に .toDouble() を使用
    hoseitime = spurtkyori_100m * tani * spurtRyoku.toDouble();
    // 距離に応じて減衰 (元のSwiftコードのコメントアウトに従う)
    // hoseitime=gensuispurttime(hoseitime,kyori);
  }

  return hoseitime;
}

double SpurtRyokuHoseitime_gakuren({
  required double kyori,
  required int spurtRyoku,
  //required int senshuid,
  //required List<Senshu_Gakuren_Data> gakurensenshudata,
}) {
  double spurtkyori_100m = 0.0;
  double tani = 0.0;
  double hoseitime = 0.0;

  // Swiftコードでコメントアウトされていた部分は、Dartコードでも反映しません。
  // if (sortedsenshudata[senshuid].spurtryoku > 99) {
  //   sortedsenshudata[senshuid].spurtryoku = 99;
  // }

  // 選手IDがリストの範囲内にあるかチェック (安全のため)
  /*if (senshuid < 0 || senshuid >= gakurensenshudata.length) {
    print('エラー: senshuid ($senshuid) が sortedSenshuData の範囲外です。');
    // エラーハンドリングとして0.0を返すか、例外をスローするなど検討
    return 0.0;
  }

  // スパート力の値を取得し、最大値を99に制限（元のSwiftコメントアウトに沿うなら）
  int spurtRyoku = gakurensenshudata[senshuid].spurtryoku;
  /*if (spurtRyoku > 99) {
    spurtRyoku = 99;
  }*/
  // ※ ChoukyoriNebariHoseitime と同様に、この関数は値を返すだけで、
  //    選手データ自体を変更してHiveに保存する機能は持っていません。
*/
  // 距離に関係なく一律処理に変更（元のSwiftコードのコメントアウトに従う）
  // spurtkyori_100m=(kyori*2/50.0)/100.0;
  spurtkyori_100m = 8.0;

  if (spurtkyori_100m > 0.0) {
    tani = TEISUU.MAXTIMEHOSEI_SPURTRYOKU_PER100m / 98.0;
    // Dartでは int から double への変換に .toDouble() を使用
    hoseitime = spurtkyori_100m * tani * spurtRyoku.toDouble();
    // 距離に応じて減衰 (元のSwiftコードのコメントアウトに従う)
    // hoseitime=gensuispurttime(hoseitime,kyori);
  }

  return hoseitime;
}
