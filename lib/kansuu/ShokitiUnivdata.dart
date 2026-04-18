import 'package:ekiden/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/univ_data.dart';

Future<void> ShokitiUnivdata(
  bool ikuseiryoku_meisei_ijiflag,
  Box<UnivData> univBox,
) async {
  int temptotal = 0;
  for (final entry in univBox.toMap().entries) {
    final int univId = entry.key;
    final UnivData univ = entry.value;

    // ここからSwiftコードの移植
    // univ.sankankaisuu=0;
    univ.sankankaisuu = 0;

    // var temptotal=0;
    temptotal = 0; // Dartでのint変数の宣言

    if (ikuseiryoku_meisei_ijiflag == false) {
      // sortedunivdata[i].meisei_yeargoto[0]=0;
      // DartのList<int>を初期化していると仮定
      if (univ.meisei_yeargoto.isNotEmpty) {
        // リストが空でないことを確認
        univ.meisei_yeargoto[0] = 0;
      } else {
        // リストがまだ初期化されていない場合、適切なサイズで初期化
        univ.meisei_yeargoto = List.filled(TEISUU.MEISEIHOZONNENSUU, 0);
        univ.meisei_yeargoto[0] = 0;
      }

      // for (int ii=1;ii<TEISUU.MEISEIHOZONNENSUU;ii++){
      //     sortedunivdata[i].meisei_yeargoto[ii]=TEISUU.UNIVSUU-i;
      //     temptotal+=sortedunivdata[i].meisei_yeargoto[ii];
      // }
      for (int ii = 1; ii < TEISUU.MEISEIHOZONNENSUU; ii++) {
        // Swiftの `TEISUU.UNIVSUU-i` の `i` はループ変数ではなく、現在の大学のソート済みインデックス
        // ここでは `univ.id` を使って対応します。
        // ただし、名声の初期値が `TEISUU.UNIVSUU - 現在の大学のランキング順位（0始まり）` を意味するなら
        // その「ランキング順位」は初期化のこの時点ではまだ決定されていないはずです。
        // もしこれが初期の名声ポイントとしての固定値であればそのまま、
        // 実際には「（初期の名声計算に使う）順位」を意味するなら、そのロジックを別途組み込む必要があります。
        // ここではSwiftコードの literal な移植として `TEISUU.UNIVSUU - univ.id` としますが、
        // 意図と異なる場合は調整が必要です。

        /*if (univ.id == 0) {
        univ.meisei_yeargoto[ii] = 10000;
      } else {
        univ.meisei_yeargoto[ii] = TEISUU.UNIVSUU - univ.id;
      }*/
        univ.meisei_yeargoto[ii] = TEISUU.UNIVSUU - univ.id;

        temptotal += univ.meisei_yeargoto[ii];
      }

      // sortedunivdata[i].meisei_total=temptotal;
      univ.meisei_total = temptotal;
    }

    // 名声順位更新
    // Swiftのこの部分は、全ての大学が初期化された後に、
    // 全体の名声順位を計算して各大学オブジェクトに反映させる処理です。
    // この for ループの中ではなく、ShokitiUnivdata関数のループの外で、
    // 全ての大学が初期化された後に一度だけ実行する必要があります。
    // この初期化ループ内で個々のunivオブジェクトを更新しているため、
    // ここに直接記述すると、まだ初期化されていない他の大学データが考慮されないため、
    // 正しい順位計算ができません。
    // なので、この部分は一旦コメントアウトして、後でShokitiUnivdataの最後に記述します。
    /*
    var meiseijununivdata: [UnivData] = sortedunivdata.sorted { // sortedunivdata の取得方法は要検討
      $0.meisei_total * 100 + $0.id > $1.meisei_total * 100 + $1.id
    }
    for i in 0..<meiseijununivdata.count {
      meiseijununivdata[i].meiseijuni = i
    }
    */

    if (ikuseiryoku_meisei_ijiflag == false) {
      // sortedunivdata[i].ikuseiryoku=150
      univ.ikuseiryoku = 150;
    }

    // for ii in 0..<TEISUU.SUU_MAXRACESUU_1YEAR{
    //     for iii in 0..<TEISUU.KIROKUHOZONNENSUU{
    //         sortedunivdata[i].juni_race[ii][iii] = TEISUU.DEFAULTJUNI
    //         sortedunivdata[i].time_race[ii][iii] = TEISUU.DEFAULTTIME
    //     }
    // }
    for (int ii = 0; ii < TEISUU.SUU_MAXRACESUU_1YEAR; ii++) {
      // 2次元リストの初期化とアクセス
      // univ.juni_race は List<List<int>> と仮定
      /*if (univ.juni_race.length <= ii) {
        // サイズが足りない場合は拡張/初期化
        univ.juni_race.add(
          List.filled(TEISUU.KIROKUHOZONNENSUU, TEISUU.DEFAULTJUNI),
        );
      }
      if (univ.time_race.length <= ii) {
        // 同様にtime_raceも
        univ.time_race.add(
          List.filled(TEISUU.KIROKUHOZONNENSUU, TEISUU.DEFAULTTIME),
        );
      }*/

      for (int iii = 0; iii < TEISUU.KIROKUHOZONNENSUU; iii++) {
        univ.juni_race[ii][iii] = TEISUU.DEFAULTJUNI;
        univ.time_race[ii][iii] = TEISUU.DEFAULTTIME;
      }
    }

    // for ii in 0..<TEISUU.SUU_MAXKUKANSUU{
    //     sortedunivdata[i].time_taikai_total[ii]=TEISUU.DEFAULTTIME
    // }
    for (int ii = 0; ii < TEISUU.SUU_MAXKUKANSUU; ii++) {
      // univ.time_taikai_total は List<double> と仮定
      /*if (univ.time_taikai_total.length <= ii) {
        // サイズが足りない場合は拡張/初期化
        // リストの初期化は通常ファクトリコンストラクタで行うべきですが、
        // ここではランタイムでの安全性確保のため記述
        univ.time_taikai_total = List.filled(
          TEISUU.SUU_MAXKUKANSUU,
          TEISUU.DEFAULTTIME,
        );
      }*/
      univ.time_taikai_total[ii] = TEISUU.DEFAULTTIME;
    }

    // 各種記録の初期化ループ
    for (int ii = 0; ii < TEISUU.SUU_MAXRACESUU_1YEAR; ii++) {
      for (int iii = 0; iii < TEISUU.SUU_BESTKIROKUHOZONJUNISUU; iii++) {
        // time_univtaikaikiroku
        /*if (univ.time_univtaikaikiroku.length <= ii ||
            univ.time_univtaikaikiroku[ii].length <= iii) {
          // 必要に応じてListを拡張または初期化するロジックを追加
          // 通常はUnivData.initial()で適切に初期化されているはず
          // 例: univ.time_univtaikaikiroku = List.generate(TEISUU.SUU_MAXRACESUU_1YEAR, (_) => List.filled(TEISUU.SUU_BESTKIROKUHOZONJUNISUU, TEISUU.DEFAULTTIME));
        }*/
        univ.time_univtaikaikiroku[ii][iii] = TEISUU.DEFAULTTIME;
        univ.year_univtaikaikiroku[ii][iii] = 0;
        univ.month_univtaikaikiroku[ii][iii] = 0;
        // day_univtaikaikiroku はコメントアウトされているため移植しない

        // time_univkukankiroku
        for (int iiii = 0; iiii < TEISUU.SUU_MAXKUKANSUU; iiii++) {
          /*if (univ.time_univkukankiroku.length <= ii ||
              univ.time_univkukankiroku[ii].length <= iiii ||
              univ.time_univkukankiroku[ii][iiii].length <= iii) {
            // 必要に応じてListを拡張または初期化するロジックを追加
          }*/
          univ.time_univkukankiroku[ii][iiii][iii] =
              TEISUU.DEFAULTTIME; // Swiftのiiiiとiiiの順序を考慮
          univ.year_univkukankiroku[ii][iiii][iii] = 0;
          univ.month_univkukankiroku[ii][iiii][iii] = 0;
          // day_univkukankiroku はコメントアウトされているため移植しない
          univ.name_univkukankiroku[ii][iiii][iii] = "";
          univ.gakunen_univkukankiroku[ii][iiii][iii] = 0;
          // 1nensei_univkukankiroku はコメントアウトされているため移植しない
        }
      }
    }

    for (int ii = 0; ii < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU; ii++) {
      for (int iii = 0; iii < TEISUU.SUU_BESTKIROKUHOZONJUNISUU; iii++) {
        // time_univkojinkiroku
        /*if (univ.time_univkojinkiroku.length <= ii ||
            univ.time_univkojinkiroku[ii].length <= iii) {
          // 必要に応じてListを拡張または初期化するロジックを追加
        }*/
        univ.time_univkojinkiroku[ii][iii] = TEISUU.DEFAULTTIME;
        univ.year_univkojinkiroku[ii][iii] = 0;
        univ.month_univkojinkiroku[ii][iii] = 0;
        // day_univkojinkiroku はコメントアウトされているため移植しない
        univ.name_univkojinkiroku[ii][iii] = "";
        univ.gakunen_univkojinkiroku[ii][iii] = 0;
        // 1nensei_univkojinkiroku はコメントアウトされているため移植しない
      }
    }

    // 大会別記録の初期化
    for (int ii = 0; ii < TEISUU.SUU_MAXRACESUU_1YEAR; ii++) {
      univ.taikaibetusaikoujuni[ii] = TEISUU.DEFAULTJUNI;
      univ.taikaibetushutujoukaisuu[ii] = 0;
      univ.taikaientryflag[ii] = 0;
      univ.taikaiseedflag[ii] = 0;
      for (int iii = 0; iii < TEISUU.UNIVSUU; iii++) {
        univ.taikaibetujunibetukaisuu[ii][iii] = 0;
      }
    }

    // 仮にシード権と出場権
    univ.taikaientryflag[5] = 1;
    univ.mokuhyojuni[5] = 9;

    // sortedunivdata[i].mokuhyojuni[9]=7
    univ.mokuhyojuni[9] = 7;

    // if i<10{ ... } else { ... }
    // ここでSwiftの `i` はループ変数ではなく、元の `sortedunivdata` のインデックスを指します。
    // Dartのこのループでは `univId` (Boxのキー) がそれに該当します。
    if (univId < 10) {
      univ.taikaiseedflag[2] = 1;
      univ.taikaientryflag[2] = 1;
      univ.taikaientryflag[0] = 1;
      univ.mokuhyojuni[2] = 9;
      univ.mokuhyojuni[0] = 4;
    } else {
      univ.taikaientryflag[4] = 1;
      univ.mokuhyojuni[4] = 9;
      univ.mokuhyojuni[0] = 9;
      univ.mokuhyojuni[2] = 9;
    }

    // if i<8{ ... } else { ... }
    if (univId < 8) {
      univ.taikaiseedflag[1] = 1;
      univ.taikaientryflag[1] = 1;
      univ.mokuhyojuni[1] = 7;
    } else {
      univ.taikaientryflag[3] = 1;
      univ.mokuhyojuni[3] = 6;
      univ.mokuhyojuni[1] = 7;
    }

    // 各大学データを更新したら、Hive Boxに保存し直す
    await univBox.put(univId, univ);
  }

  // ★★★ 名声順位の計算は、全ての大学データが初期化された後に行うべきです ★★★
  // ここで、全ての大学が初期化された後の名声順位を計算します。
  // 一度全てのUnivDataをHiveから取得し、Listに変換してソートします。
  List<UnivData> allUnivs = univBox.toMap().values.toList();

  // 名声に基づいてソート (meisei_totalが大きいほど上位、同点ならidが大きいほど上位)
  allUnivs.sort((a, b) {
    int compareTotal = (b.meisei_total * 100).toInt().compareTo(
      (a.meisei_total * 100).toInt(),
    );
    if (compareTotal != 0) {
      return compareTotal;
    }
    return b.id.compareTo(
      a.id,
    ); // meisei_totalが同じ場合はidでソート (Swiftコードの `$0.id > $1.id` に対応)
  });

  // ソートされたリストに基づいて名声順位を更新し、Hiveに保存
  for (int i = 0; i < allUnivs.length; i++) {
    allUnivs[i].meiseijuni = i;
    // 更新したUnivDataをHive Boxに保存し直す
    await univBox.put(allUnivs[i].id, allUnivs[i]);
  }
}
