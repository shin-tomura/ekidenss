import 'dart:math'; // Randomクラスを使用するため
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
import 'package:ekiden/kansuu/ikusei_ryuugakusei.dart';
import 'package:flutter/services.dart';
// 必要に応じて他のモデルや定数ファイルのインポートを追加してください

/// 大学の名声に基づいて選手を各大学に割り当てる関数
///
/// [sortedunivdata]: ID順にソートされた大学データのリスト。
/// [nyuugakuji5000_senshudata]: 入学時5000mの記録でソートされた選手データのリスト。
/// [gakunen]: 割り当てを行う学年。
///
/// この関数は、渡されたリスト内のSenshuDataオブジェクトの
/// プロパティ（主にunivid）を変更します。
/// 変更を永続化するには、この関数を呼び出した後にHive Boxに保存し直す必要があります。
Future<void> ShozokusakiKettei_By_Univmeisei({
  required List<UnivData> sortedunivdata,
  required List<SenshuData> nyuugakuji5000_senshudata,
  required int gakunen,
  required Ghensuu ghensuu,
}) async {
  print('ShozokusakiKettei_By_Univmeisei: 大学所属先決定処理を開始 (学年: $gakunen)...');

  // 変数の初期化
  List<int> ketteisuu = List.filled(TEISUU.UNIVSUU, 0);
  int totalrandmotosuu = 0;
  List<int> randmotosuu = List.filled(TEISUU.UNIVSUU, 0);
  int suu = 0;
  int temp_total = 0;

  final _random = Random(); // 乱数ジェネレータのインスタンス

  // 名声に基づいて大学リストを降順にソートする
  // 元のリストを変更しないよう、コピーを作成してソート
  List<UnivData> sortedByMeiseiUnivData = List.from(sortedunivdata);
  sortedByMeiseiUnivData.sort(
    (a, b) => b.meisei_total.compareTo(a.meisei_total),
  );

  // 各大学の抽選確率を決定するリスト
  List<int> temp_meisei = List.filled(TEISUU.UNIVSUU, 0);
  int top1 = 1;
  int top2 = 1;
  int top3 = 1;
  if (ghensuu.spurtryokuseichousisuu3 == 9) {
    //初期値（デフォルト値）
    top1 = 20;
    top2 = 15;
    top3 = 10;
  }
  if (ghensuu.spurtryokuseichousisuu3 == 8) {
    top1 = 13;
    top2 = 9;
    top3 = 7;
  }
  if (ghensuu.spurtryokuseichousisuu3 == 7) {
    top1 = 8;
    top2 = 6;
    top3 = 4;
  }
  if (ghensuu.spurtryokuseichousisuu3 == 6) {
    top1 = 4;
    top2 = 3;
    top3 = 2;
  }
  if (ghensuu.spurtryokuseichousisuu3 == 5) {
    top1 = 1;
    top2 = 1;
    top3 = 1;
  }
  int hosei = 0;
  // ソートされた大学リストに基づいて、抽選確率を設定
  for (int i = 0; i < TEISUU.UNIVSUU; i++) {
    int univId = sortedByMeiseiUnivData[i].id;
    int meisei = sortedByMeiseiUnivData[i].meisei_total;
    if (ghensuu.spurtryokuseichousisuu3 == 0) {
      //完全ランダム
      temp_meisei[univId] = 100;
    } else if (ghensuu.spurtryokuseichousisuu3 == 1) {
      if (i == 0) {
        hosei = (meisei * 2.0).toInt();
      }
      temp_meisei[univId] = meisei + hosei;
    } else if (ghensuu.spurtryokuseichousisuu3 == 2) {
      if (i == 0) {
        hosei = (meisei * 1.0).toInt();
      }
      temp_meisei[univId] = meisei + hosei;
    } else if (ghensuu.spurtryokuseichousisuu3 == 3) {
      if (i == 0) {
        hosei = (meisei * 0.7).toInt();
      }
      temp_meisei[univId] = meisei + hosei;
    } else if (ghensuu.spurtryokuseichousisuu3 == 4) {
      if (i == 0) {
        hosei = (meisei * 0.3).toInt();
      }
      temp_meisei[univId] = meisei + hosei;
    } else {
      // 名声トップ3の大学に特別な優遇措置を適用
      if (i == 0) {
        temp_meisei[univId] = meisei * top1; // トップ3の確率は3倍
      } else if (i == 1) {
        temp_meisei[univId] = meisei * top2; // トップ3の確率は3倍
      } else if (i == 2) {
        temp_meisei[univId] = meisei * top3; // トップ3の確率は3倍
      } else {
        temp_meisei[univId] = meisei; // それ以外の大学はそのまま
      }
    }
  }

  // 選手を大学に割り当てるメインループ
  for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
    // 処理対象の選手が、現在割り当てを行うべき学年であるかを確認
    if (nyuugakuji5000_senshudata[i].gakunen == gakunen) {
      // 各大学の定員チェックと、割り当て確率の計算
      for (int ii = 0; ii < TEISUU.UNIVSUU; ii++) {
        if (ketteisuu[ii] >= TEISUU.NINZUU_1GAKUNEN_INUNIV) {
          randmotosuu[ii] = 0; // 定員オーバーの大学は割り当て確率を0にする
        } else {
          randmotosuu[ii] = temp_meisei[ii]; // 定員内の大学は優遇された名声を使用
        }
      }

      // 割り当て可能な全大学の確率の合計を計算
      totalrandmotosuu = 0;
      for (int ii = 0; ii < TEISUU.UNIVSUU; ii++) {
        totalrandmotosuu += randmotosuu[ii];
      }

      // もし割り当て可能な大学が一つもなければ、ログを出力して次の選手へ
      if (totalrandmotosuu == 0) {
        print(
          'Warning: 学年 $gakunen の選手 (ID: ${nyuugakuji5000_senshudata[i].id}) に割り当て可能な大学がありません。',
        );
        continue; // この選手はスキップされる
      }

      // 乱数を生成し、大学を抽選
      suu = _random.nextInt(
        totalrandmotosuu,
      ); // 0 から totalrandmotosuu - 1 までの乱数

      temp_total = 0; // 累積合計をリセット
      // 抽選された乱数に基づいて、実際に選手を割り当てる大学を決定
      for (int iii = 0; iii < TEISUU.UNIVSUU; iii++) {
        if (suu < temp_total + randmotosuu[iii]) {
          // 選手を決定した大学に割り当て、割り当て数をカウント
          nyuugakuji5000_senshudata[i].univid = iii;
          ketteisuu[iii]++;
          break; // 大学が決まったら、内側のループを抜ける
        }
        temp_total += randmotosuu[iii];
      }
    }
  }

  //留学生処理
  final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
  List<SenshuData> sortedSenshuData = senshudataBox.values.toList();
  sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
  //まずは各大学の現在の留学生数を数える
  List<int> nowsuu_ryuugakusei = List.generate(TEISUU.UNIVSUU, (index) => 0);
  for (int i = 0; i < sortedSenshuData.length; i++) {
    if (sortedSenshuData[i].hirou == 1) {
      nowsuu_ryuugakusei[sortedSenshuData[i].univid]++;
    }
  }
  //留学生の受け入れが必要な大学を抽出
  final Random random = Random();
  final String fileContent = await rootBundle.loadString(
    'lib/assets/data/name_ryuugakusei.txt',
  );
  final List<String> names = fileContent
      .split('\n')
      .where((name) => name.isNotEmpty)
      .toList();
  if (names.isEmpty) {
    print('Error: name_ryuugakusei.txt is empty or not found.');
  }
  for (int i = 0; i < sortedunivdata.length; i++) {
    if (sortedunivdata[i].r >= 1 && nowsuu_ryuugakusei[i] == 0) {
      for (int ii = nyuugakuji5000_senshudata.length - 1; ii >= 0; ii--) {
        // 処理対象の選手が、現在割り当てを行うべき学年であるかを確認
        if (nyuugakuji5000_senshudata[ii].gakunen == gakunen &&
            nyuugakuji5000_senshudata[ii].univid == i) {
          nyuugakuji5000_senshudata[ii].hirou = 1;
          nyuugakuji5000_senshudata[ii].seichoutype = 1;
          final int randomIndex = random.nextInt(names.length);
          final String namestring = names[randomIndex];
          nyuugakuji5000_senshudata[ii].name = namestring;
          nyuugakuji5000_senshudata[ii].kiroku_nyuugakuji_5000 =
              TEISUU.DEFAULTTIME;
          nyuugakuji5000_senshudata[ii].time_bestkiroku[0] = TEISUU.DEFAULTTIME;
          nyuugakuji5000_senshudata[ii].sositu_bonus =
              TEISUU.SOSITU_BONUS; //-100
          final int tempRand = random.nextInt(11) + 1550; // 1550から1600までの乱数
          // a_min_intの計算 (temprand=1550の場合のa_min_int)
          final int aMinInt =
              (1550.0 * 1550.0 * 0.0333 -
                      1550.0 * 114.25 +
                      nyuugakuji5000_senshudata[ii].magicnumber)
                  .toInt();
          final double tani = 1000.0 / (1680.0 - 1550.0);
          // a_intの計算
          final int aInt = aMinInt + ((tempRand - 1550) * tani).toInt();
          nyuugakuji5000_senshudata[ii].a = aInt * 0.000000001;
          nyuugakuji5000_senshudata[ii].b = 1645.0 * 0.0001; // 固定値
          nyuugakuji5000_senshudata[ii].sositu = tempRand;
          ryuugakusei_ikusei(senshuid: nyuugakuji5000_senshudata[ii].id);
          break;
        }
      }
    }
  }
  print('ShozokusakiKettei_By_Univmeisei: 大学所属先決定処理を完了しました。');
  // この関数で変更された選手データ (nyuugakuji5000_senshudata) は、
  // この関数を呼び出した側でHive Boxに保存し直す必要があります。
}
