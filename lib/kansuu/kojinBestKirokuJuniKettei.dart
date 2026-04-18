import 'package:hive/hive.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart';

void kojinBestKirokuJuniKettei(
  int kirokuBangou,
  List<Ghensuu> gh,
  List<SenshuData> sortedSenshuData,
) {
  // 元のsortedSenshuDataを変更しないように、コピーを作成してソートします。
  // 全体順位用のリスト
  //var bestKirokuJunSenshuData = List<SenshuData>.from(sortedSenshuData);
  var bestKirokuJunSenshuData = sortedSenshuData
      .where(
        (senshu) => senshu.time_bestkiroku[kirokuBangou] != TEISUU.DEFAULTTIME,
      )
      .toList(); // 新しいリストを作成
  // タイム順で並び替え (全体)
  bestKirokuJunSenshuData.sort(
    (a, b) => a.time_bestkiroku[kirokuBangou].compareTo(
      b.time_bestkiroku[kirokuBangou],
    ),
  );

  // 全体順位の設定
  for (int i = 0; i < bestKirokuJunSenshuData.length; i++) {
    // Hiveオブジェクトを直接変更します。変更を保存するには、後で .save() を呼び出す必要があります。
    bestKirokuJunSenshuData[i].zentaijuni_bestkiroku[kirokuBangou] = i;
    // 必要であれば、ここで bestKirokuJunSenshuData[i].save(); を呼び出します。
  }

  for (int i_univ = 0; i_univ < TEISUU.UNIVSUU; i_univ++) {
    // unividが特定のものだけ抽出 (学内)
    var univFilteredSenshuData = sortedSenshuData
        .where(
          (senshu) =>
              senshu.univid == i_univ &&
              senshu.time_bestkiroku[kirokuBangou] != TEISUU.DEFAULTTIME,
        )
        .toList(); // 新しいリストを作成

    // タイム順で並び替え (学内)
    univFilteredSenshuData.sort(
      (a, b) => a.time_bestkiroku[kirokuBangou].compareTo(
        b.time_bestkiroku[kirokuBangou],
      ),
    );

    // 学内順位の設定
    for (int i = 0; i < univFilteredSenshuData.length; i++) {
      // Hiveオブジェクトを直接変更します。変更を保存するには、後で .save() を呼び出す必要があります。
      univFilteredSenshuData[i].gakunaijuni_bestkiroku[kirokuBangou] = i;
      // 必要であれば、ここで univFilteredSenshuData[i].save(); を呼び出します。
    }
  }

  // 注意: この関数内でHiveオブジェクトの `save()` メソッドを呼び出すと、
  // ループ内で頻繁にDBアクセスが発生しパフォーマンスに影響を与える可能性があります。
  // 通常は、この関数が終了した後に、変更された SenshuData オブジェクトに対して
  // 一括で save() を呼び出すか、または変更されたオブジェクトのリストを返して
  // 呼び出し元で保存処理を行うのが一般的です。
  // ここでは、明示的な save() 呼び出しはコメントアウトしています。
}
