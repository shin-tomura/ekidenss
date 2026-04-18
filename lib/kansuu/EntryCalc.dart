import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:math'; // Randomクラスを使用するため
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/senshu_gakuren_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
import 'package:ekiden/kansuu/FindFastestTeam.dart';
import 'package:ekiden/kansuu/FindFastest2.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/Shuudansou.dart';
//import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/fastest_filteredplayer.dart';
import 'package:ekiden/kantoku_data.dart';

List<int> kukanIDs = [];

String _timeToMinuteSecondString(double time) {
  if (time == TEISUU.DEFAULTTIME) {
    return '記録無';
  }
  final int minutes = time ~/ 60;
  final int seconds = (time % 60).toInt();
  //final int milliseconds = ((time % 1) * 100)
  //    .toInt(); // 秒以下の部分をミリ秒として扱う (小数点2桁まで)
  return '${minutes.toString().padLeft(2, '0')}分${seconds.toString().padLeft(2, '0')}秒';
}

// DartではFutureを返す非同期関数として定義
Future<List<int>> EntryCalc({
  required int racebangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
}) async {
  // SwiftのコメントをDartのコメントに変換
  // 現在時刻と前回の休憩時刻を比較
  final now = DateTime.now();
  if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
    // 3秒以上経過してたら
    await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
    Chousa.lastGapTime = DateTime.now();
  }
  /*
  //[レース番号][学年(0→1年、3→4年)]
  //レース番号は、0→10月駅伝、1→11月駅伝、2→正月駅伝、3→11月駅伝予選、4→正月駅伝予選
  //5→マイ駅伝、6→インカレ5000、7→インカレ10000、8→インカレハーフ、9→インカレ総合
  //10→5000記録会、11→10000記録会、12→市民ハーフ、13→登り1万、14→下り1万、15→ロード1万、16→クロカン1万
  */
  final startTime = DateTime.now();
  print("EntryCalcに入った");

  final albumBox = Hive.box<Album>('albumBox');
  // Boxからデータを読み込む
  final Album album = albumBox.get('AlbumData')!;
  /////わざと一旦閉じる
  //var close_rsenshubox = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');
  //close_rsenshubox.close();

  //kantoku.yobiint4[0]から[9]従来全体区間記録、[10]から[19]従来学内区間記録、[20]従来全体大会記録、[21]従来学内大会記録
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData kantoku = kantokuBox.get('KantokuData')!;
  if (racebangou <= 2 || racebangou == 5) {
    //従来区間記録と大会記録をintで格納
    for (
      int i_kukan = 0;
      i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
      i_kukan++
    ) {
      kantoku.yobiint4[i_kukan] = gh[0]
          .time_zentaikukankiroku[racebangou][i_kukan][0]
          .toInt();
      kantoku.yobiint4[i_kukan + 10] = sortedUnivData[gh[0].MYunivid]
          .time_univkukankiroku[racebangou][i_kukan][0]
          .toInt();
      kantoku.yobiint3[i_kukan] =
          kantoku.yobiint4[racebangou * 10 + 30 + i_kukan];
    }
    kantoku.yobiint4[20] = gh[0].time_zentaitaikaikiroku[racebangou][0].toInt();
    kantoku.yobiint4[21] = sortedUnivData[gh[0].MYunivid]
        .time_univtaikaikiroku[racebangou][0]
        .toInt();
  } else {
    for (int i = 0; i < 22; i++) {
      kantoku.yobiint4[i] = 0;
    }
    for (int i = 0; i < 10; i++) {
      kantoku.yobiint3[i] = 0;
    }
  }
  await kantoku.save();

  // Swiftの || 演算子と範囲演算子をDartの || と >= <= に変換
  if ((racebangou >= 6 && racebangou <= 9) ||
      (racebangou >= 10 && racebangou <= 12) ||
      racebangou == 17) {
    // 個人種目は全て全員参加
    for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
      sortedSenshuData[i]
              .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
          0;
      sortedSenshuData[i].string_racesetumei = "";
      // HiveObject の変更を保存 (非同期処理なのでawait)
      await sortedSenshuData[i].save();
    }
  } else if (racebangou >= 13 && racebangou <= 16) {
    for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
      if (kantoku.yobiint2[19] == 1 ||
          sortedSenshuData[i].univid == gh[0].MYunivid) {
        sortedSenshuData[i]
                .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
            0;
      } else {
        sortedSenshuData[i]
                .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
            -1;
      }
      sortedSenshuData[i].string_racesetumei = "";
      await sortedSenshuData[i].save();
    }
  } else if (racebangou <= 2 || racebangou == 5 || racebangou == 4) {
    //Entry1Calcで-1(1次エントリー選手)と-2(エントリー外選手)を決めてるのでここでは初期化しない改め
    //-1か0の選手はいったん-1にする、コース編集画面の保存ボタン押下でもこのEntryCalcを呼び出すため
    for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
      if (sortedSenshuData[i]
              .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] >
          -2) {
        sortedSenshuData[i]
                .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
            -1;
        sortedSenshuData[i].string_racesetumei = "";
        await sortedSenshuData[i].save();
      }
    }
  } else {
    // いったん全員不出場で初期化
    for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
      sortedSenshuData[i]
              .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
          -1;
      sortedSenshuData[i].string_racesetumei = "";
      await sortedSenshuData[i].save();
    }
  }

  // 現在時刻と前回の休憩時刻を比較
  {
    final now = DateTime.now();
    if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
      // 3秒以上経過してたら
      await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
      Chousa.lastGapTime = DateTime.now();
    }
  }

  if ((racebangou >= 0 && racebangou <= 2) || racebangou == 5) {
    // 区間ごとの特徴スコアを計算し、順番を決定
    List<Map<String, dynamic>> kukanScores = [];
    for (int i = 0; i < gh[0].kukansuu_taikaigoto[racebangou]; i++) {
      double kukanKyoriScore =
          0.15 * gh[0].kyori_taikai_kukangoto[racebangou][i];
      double kukanNoboriScore =
          7500 *
          gh[0].kyoriwariainobori_taikai_kukangoto[racebangou][i] *
          gh[0].heikinkoubainobori_taikai_kukangoto[racebangou][i];
      double kukanKudariScore =
          7500 *
          gh[0].kyoriwariaikudari_taikai_kukangoto[racebangou][i] *
          gh[0].heikinkoubaikudari_taikai_kukangoto[racebangou][i];
      double kukanKirikaeScore =
          8.0 *
          gh[0].noborikudarikirikaekaisuu_taikai_kukangoto[racebangou][i]
              .toDouble();

      double totalKukanScore =
          kukanKyoriScore.abs() +
          kukanNoboriScore.abs() +
          kukanKudariScore.abs() +
          kukanKirikaeScore.abs();

      // --- 新たに追加した補正ロジック ---
      // 区間番号が若いほど大きなボーナスを加算する
      // 例: 1区(index 0)には1000のボーナス、2区(index 1)には900のボーナス、...
      // この係数は、区間の特徴とバランスを見ながら調整してください。
      if (i == 0 && gh[0].kukansuu_taikaigoto[racebangou] > 0) {
        double rankBonus =
            (gh[0].kukansuu_taikaigoto[racebangou] - (i + 0)) * 150.0;
        totalKukanScore += rankBonus;
      } else {
        double rankBonus = (gh[0].kukansuu_taikaigoto[racebangou] - i) * 150.0;
        totalKukanScore += rankBonus;
      }

      // ------------------------------------

      kukanScores.add({'kukanIndex': i, 'score': totalKukanScore});
    }

    // スコアが高い順に区間をソート
    kukanScores.sort((a, b) => b['score'].compareTo(a['score']));

    // ソートされた順番でkukanIDsリストを作成
    /*List<int> kukanIDs = kukanScores
        .map((k) => k['kukanIndex'] as int)
        .toList();*/
    kukanIDs = kukanScores.map((k) => k['kukanIndex'] as int).toList();
    // --- 追加したログ出力 ---
    //print('選手を配置する区間の順番 (インデックス): $kukanIDs');
    // ----------------------

    int senshusuu_univ = 0;
    // すべての大学に対して処理を行う
    for (int id_univ = 0; id_univ < sortedUnivData.length; id_univ++) {
      // 現在時刻と前回の休憩時刻を比較
      {
        final now = DateTime.now();
        if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
          // 3秒以上経過してたら
          await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
          Chousa.lastGapTime = DateTime.now();
        }
      }
      senshusuu_univ = 0;
      //for (var university in sortedUnivData) {
      if (sortedUnivData[id_univ].taikaientryflag[racebangou] == 1) {
        List<SenshuData> availableSenshu = sortedSenshuData
            .where(
              (s) =>
                  s.univid == id_univ &&
                  s.entrykukan_race[racebangou][s.gakunen - 1] >= -1, //-2は除外
              //university.taikaientryflag[racebangou] == 1,
            )
            .toList();

        Set<int> assignedSenshuIds = {};
        List<SenshuData> playersToSave = [];
        senshusuu_univ = availableSenshu.length;
        //print('\n--- 大学ID ${sortedUnivData[id_univ].id} の選手割り当てを開始 ---');
        //print("選手数は${senshusuu_univ}人");
        int count = 0;

        for (int kukanIndex in kukanIDs) {
          SenshuData? bestSenshu;
          double maxScore = -99999999999.0;
          double minScore = 99999999999.0;

          for (SenshuData senshu in availableSenshu) {
            if (assignedSenshuIds.contains(senshu.id)) {
              continue;
            }

            // ...（既存のスコア計算ロジック）...
            double kukanKyoriScore =
                0.01 * gh[0].kyori_taikai_kukangoto[racebangou][kukanIndex];
            double kukanNoboriScore =
                2 *
                7500.0 *
                gh[0]
                    .kyoriwariainobori_taikai_kukangoto[racebangou][kukanIndex] *
                gh[0]
                    .heikinkoubainobori_taikai_kukangoto[racebangou][kukanIndex];
            double kukanKudariScore =
                2 *
                7500.0 *
                gh[0]
                    .kyoriwariaikudari_taikai_kukangoto[racebangou][kukanIndex] *
                gh[0]
                    .heikinkoubaikudari_taikai_kukangoto[racebangou][kukanIndex];
            double kukanKirikaeScore =
                4.0 *
                gh[0]
                    .noborikudarikirikaekaisuu_taikai_kukangoto[racebangou][kukanIndex]
                    .toDouble();

            kukanKudariScore = kukanKudariScore.abs();

            double senshuKyoriScore = 0;
            double kukanbetuhosei = 0.0;
            double hosei_tani = 0.0;
            double hosei_time = 0.0;
            double temp_time = 0.0;
            if (senshu.time_bestkiroku.length > 2 &&
                gh[0].kyori_taikai_kukangoto[racebangou][kukanIndex] > 15000) {
              temp_time = senshu.time_bestkiroku[2];
              hosei_tani = 105.4875 / 100.0;
              if (kukanIndex == 0) {
                kukanbetuhosei =
                    senshu.tandokusou.toDouble() -
                    senshu.paceagesagetaiouryoku.toDouble();
                hosei_time = kukanbetuhosei * hosei_tani;
                temp_time = temp_time + hosei_time;
              }
              if (kukanIndex == 1 || kukanIndex == 2) {
                kukanbetuhosei =
                    senshu.tandokusou.toDouble() -
                    senshu.paceagesagetaiouryoku.toDouble();
                hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                temp_time = temp_time + hosei_time;
              }
              if (kukanIndex > 2) {
                //補正なし
              }
              senshuKyoriScore = (-5 / 12) * temp_time + 1625;
            } else if (senshu.time_bestkiroku.length > 1 &&
                gh[0].kyori_taikai_kukangoto[racebangou][kukanIndex] > 7500) {
              temp_time = senshu.time_bestkiroku[1];
              hosei_tani = 50.0 / 100.0;
              if (kukanIndex == 0) {
                //補正なし
              }
              if (kukanIndex == 1 || kukanIndex == 2) {
                kukanbetuhosei =
                    senshu.tandokusou.toDouble() -
                    senshu.paceagesagetaiouryoku.toDouble();
                hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                temp_time = temp_time - hosei_time;
              }
              if (kukanIndex > 2) {
                kukanbetuhosei =
                    senshu.tandokusou.toDouble() -
                    senshu.paceagesagetaiouryoku.toDouble();
                hosei_time = kukanbetuhosei * hosei_tani;
                temp_time = temp_time - hosei_time;
              }
              senshuKyoriScore = (-10 / 9) * temp_time + 1983.33;
            } else if (senshu.time_bestkiroku.length > 0) {
              temp_time = senshu.time_bestkiroku[0];
              hosei_tani = 25.0 / 100.0;
              if (kukanIndex == 0) {
                //補正なし
              }
              if (kukanIndex == 1 || kukanIndex == 2) {
                kukanbetuhosei =
                    senshu.tandokusou.toDouble() -
                    senshu.paceagesagetaiouryoku.toDouble();
                hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                temp_time = temp_time - hosei_time;
              }
              if (kukanIndex > 2) {
                kukanbetuhosei =
                    senshu.tandokusou.toDouble() -
                    senshu.paceagesagetaiouryoku.toDouble();
                hosei_time = kukanbetuhosei * hosei_tani;
                temp_time = temp_time - hosei_time;
              }
              senshuKyoriScore = (-10 / 3) * temp_time + 2850;
            }
            senshuKyoriScore *= 7;
            double senshuNoboriScore = 3 * senshu.noboritekisei.toDouble();
            double senshuKudariScore = 3 * senshu.kudaritekisei.toDouble();
            double senshuKirikaeScore =
                3 * senshu.noborikudarikirikaenouryoku.toDouble();

            double specialScore = 0;
            /*if (kukanIndex == 0) {
              specialScore = senshu.paceagesagetaiouryoku.toDouble();
            } else if (kukanIndex == 1 || kukanIndex == 2) {
              specialScore =
                  0.5 * senshu.paceagesagetaiouryoku.toDouble() +
                  0.5 * senshu.tandokusou.toDouble();
            } else {
              specialScore = senshu.tandokusou.toDouble();
            }
            //specialScore *= 200;
            */
            specialScore = 0;

            double totalScore =
                (kukanKyoriScore * senshuKyoriScore) +
                (kukanNoboriScore * senshuNoboriScore) +
                (kukanKudariScore * senshuKudariScore) +
                (kukanKirikaeScore * senshuKirikaeScore) +
                specialScore;

            if (totalScore.isNaN) {
              totalScore = -99999.0;
            }

            if (totalScore > maxScore) {
              maxScore = totalScore;
              bestSenshu = senshu;
            }
            if (totalScore < minScore) {
              minScore = totalScore;
            }
          }

          if (bestSenshu != null) {
            count++;
            bestSenshu.entrykukan_race[racebangou][bestSenshu.gakunen - 1] =
                kukanIndex;
            playersToSave.add(bestSenshu);
            assignedSenshuIds.add(bestSenshu.id);
            /*print(
              '  ${kukanIndex + 1}区 ID= ${bestSenshu.id}' +
                  ' ハーフ= ' +
                  _timeToMinuteSecondString(bestSenshu.time_bestkiroku[2]) +
                  ' 1万= ' +
                  _timeToMinuteSecondString(bestSenshu.time_bestkiroku[1]) +
                  ' 5千= ' +
                  _timeToMinuteSecondString(bestSenshu.time_bestkiroku[0]) +
                  ' 登り= ${bestSenshu.noboritekisei} 下り= ${bestSenshu.kudaritekisei} updown= ${bestSenshu.noborikudarikirikaenouryoku}',
            );
            print(
              '    ${kukanIndex + 1}区 maxscore=${maxScore.toInt()} minscore=${minScore.toInt()}',
            );*/
          }
        }

        //print('\n--- 大学ID ${sortedUnivData[id_univ].id} の選手割り当てを終了 ---');
        //print('合計${count}人エントリー');

        for (var senshu in playersToSave) {
          await senshu.save();
        }
      }
    }

    /////////////////////////////////////
    /////最適解区間配置で区間配置をし直す大学
    // 必要なデータをここで取得し、computeに渡す
    int NUMBER_OF_KUKAN = gh[0].kukansuu_taikaigoto[racebangou];
    //final hivePath = await getApplicationDocumentsDirectory();

    for (
      int targetunivid = 0;
      targetunivid < sortedUnivData.length;
      targetunivid++
    ) {
      // 現在時刻と前回の休憩時刻を比較
      {
        final now = DateTime.now();
        if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
          // 3秒以上経過してたら
          await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
          Chousa.lastGapTime = DateTime.now();
        }
      }
      if (sortedUnivData[targetunivid].taikaientryflag[racebangou] == 1) {
        if (Random().nextInt(100) < album.tourokusuu_total &&
            targetunivid != gh[0].MYunivid) {
          for (
            int id_senshu = 0;
            id_senshu < sortedSenshuData.length;
            id_senshu++
          ) {
            if (sortedSenshuData[id_senshu].univid == targetunivid) {
              if (sortedSenshuData[id_senshu]
                      .entrykukan_race[racebangou][sortedSenshuData[id_senshu]
                          .gakunen -
                      1] >=
                  -1) {
                sortedSenshuData[id_senshu]
                        .entrykukan_race[racebangou][sortedSenshuData[id_senshu]
                            .gakunen -
                        1] =
                    -1;
                await sortedSenshuData[id_senshu].save();
              }
            }
          }
          /*
          print("findFastestTeam関数呼び出し");
          // findFastestTeamに直接引数を渡す
          final result = await compute(findFastestTeam, [
            hivePath.path,
            targetunivid,
            NUMBER_OF_KUKAN,
            //playerIds, // ここでplayerIdsを追加
          ]);
          print("findFastestTeam関数から戻ってきた！！");
*/
          //
          print("findFastestTeam関数呼び出さない処理");
          //targetunividとNUMBER_OF_KUKANが必要
          final List<SenshuData> univFilteredSenshuData = sortedSenshuData
              .where(
                (s) =>
                    s.univid == targetunivid &&
                    s.entrykukan_race[gh[0].hyojiracebangou][s.gakunen - 1] >=
                        -1,
              )
              .toList();
          if (univFilteredSenshuData.length < NUMBER_OF_KUKAN) {
            throw Exception('区間数分の選手がいません。');
          }
          final List<int> playerIds = univFilteredSenshuData
              .map((s) => s.id)
              .toList();
          final int playerCount = playerIds.length;
          // 1. 試走タイムを事前に計算してキャッシュ
          final Map<int, Map<int, double>> trialTimesCache = {};
          for (final int playerId in playerIds) {
            trialTimesCache[playerId] = {};
            // 現在時刻と前回の休憩時刻を比較
            {
              final now = DateTime.now();
              if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
                // 3秒以上経過してたら
                await Future.delayed(
                  const Duration(milliseconds: 50),
                ); // 休憩を入れる
                Chousa.lastGapTime = DateTime.now();
              }
            }
            for (
              int kukanIndex = 0;
              kukanIndex < NUMBER_OF_KUKAN;
              kukanIndex++
            ) {
              final double time = await runTrialCalculation(
                playerId,
                kukanIndex,
                gh[0],
                sortedSenshuData,
                sortedUnivData,
                kantoku,
              );
              trialTimesCache[playerId]![kukanIndex] = time;
            }
          }
          // 2. 動的計画法による最適配置の探索（ビットマスクを使用）
          // dp[k][mask] = k区間目までで、選手集合maskを使用したときの最小タイム
          final List<Map<int, double>> dp = List.generate(
            NUMBER_OF_KUKAN + 1,
            (_) => {},
          );
          // parent[k][mask] = k区間目で配置した選手インデックス
          final List<Map<int, int>> parent = List.generate(
            NUMBER_OF_KUKAN + 1,
            (_) => {},
          );
          // 初期化: 0区間目、選手不使用のマスク
          dp[0][0] = 0.0;
          // ループでDPテーブルを埋めていく
          for (int kukan = 1; kukan <= NUMBER_OF_KUKAN; kukan++) {
            // 現在時刻と前回の休憩時刻を比較
            {
              final now = DateTime.now();
              if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
                // 3秒以上経過してたら
                await Future.delayed(
                  const Duration(milliseconds: 50),
                ); // 休憩を入れる
                Chousa.lastGapTime = DateTime.now();
              }
            }
            final int prevKukan = kukan - 1;
            for (final prevMask in dp[prevKukan].keys) {
              // 過去に使用した選手を特定
              for (
                int currentPlayerIdx = 0;
                currentPlayerIdx < playerCount;
                currentPlayerIdx++
              ) {
                // currentPlayerIdx (選手インデックス)に対応するビット
                final int currentMaskBit = 1 << currentPlayerIdx;
                // 選手が既に使用されているかチェック
                if ((prevMask & currentMaskBit) == 0) {
                  // 未使用の場合、選手を配置可能
                  final int newMask = prevMask | currentMaskBit;
                  final double currentTime =
                      trialTimesCache[playerIds[currentPlayerIdx]]![kukan - 1]!;
                  final double totalTime =
                      dp[prevKukan][prevMask]! + currentTime;
                  // 新しいマスクでの最小タイムを更新
                  if (totalTime < (dp[kukan][newMask] ?? double.infinity)) {
                    dp[kukan][newMask] = totalTime;
                    parent[kukan][newMask] = currentPlayerIdx;
                  }
                }
              }
            }
          }
          // 3. 最後の区間までの最適な合計タイムと組み合わせを逆順でたどる
          double fastestTotalTime = double.infinity;
          int finalMask = -1;
          final int finalKukan = NUMBER_OF_KUKAN;
          for (final mask in dp[finalKukan].keys) {
            if (dp[finalKukan][mask]! < fastestTotalTime) {
              fastestTotalTime = dp[finalKukan][mask]!;
              finalMask = mask;
            }
          }
          final List<int> fastestPlayerIds_notheiretu = [];
          int currentMask = finalMask;
          for (int kukan = NUMBER_OF_KUKAN; kukan >= 1; kukan--) {
            final int currentPlayerIdx = parent[kukan][currentMask]!;
            final int currentPlayerId = playerIds[currentPlayerIdx];
            fastestPlayerIds_notheiretu.insert(0, currentPlayerId);
            // 現在の選手をマスクから外して、前の状態のマスクを計算
            currentMask = currentMask ^ (1 << currentPlayerIdx);
          }
          print("最速の組み合わせ探索終了！！(並列処理じゃない版)");
          //return {
          //  'fastestTotalTime': fastestTotalTime,
          //  'fastestPlayerIds': fastestPlayerIds,
          //};
          print("findFastestTeam関数呼び出さない処理終了");

          // 結果から最適な選手配置リストを取得
          List<int> fastestPlayerIds = [];
          fastestPlayerIds = fastestPlayerIds_notheiretu; //並列じゃない処理版
          //fastestPlayerIds = result['fastestPlayerIds'];//並列処理用版
          for (
            int i_kukan = 0;
            i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
            i_kukan++
          ) {
            sortedSenshuData[fastestPlayerIds[i_kukan]]
                    .entrykukan_race[racebangou][sortedSenshuData[fastestPlayerIds[i_kukan]]
                        .gakunen -
                    1] =
                i_kukan;
            await sortedSenshuData[fastestPlayerIds[i_kukan]].save();
          }
        } //if (Random().nextInt(100) < 30) {終端
      }
    }
  } // if (racebangou>=0 && racebangou <= 2) 終端

  //////////////
  ////学連選抜////////////////////
  //////////////
  if (racebangou == 2) {
    final Box<Senshu_Gakuren_Data> gakurenSenshuBox =
        Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox');
    await gakurenSenshuBox.clear();
    for (int id_univ = 0; id_univ < sortedUnivData.length; id_univ++) {
      //for (var university in sortedUnivData) {
      if (sortedUnivData[id_univ].taikaientryflag[racebangou] == 0) {
        List<SenshuData> timejununivfilterdSenshudata = sortedSenshuData
            .where(
              (s) => s.univid == id_univ && s.hirou != 1, //&&
            )
            .toList();
        timejununivfilterdSenshudata.sort(
          (a, b) => a.kukantime_race[4][a.gakunen - 1].compareTo(
            b.kukantime_race[4][b.gakunen - 1],
          ),
        );
        for (int i = 0; i < timejununivfilterdSenshudata.length; i++) {
          int count = 0;
          for (
            int i_gakunen = timejununivfilterdSenshudata[i].gakunen - 1;
            i_gakunen >= 1;
            i_gakunen--
          ) {
            if (timejununivfilterdSenshudata[i]
                    .entrykukan_race[racebangou][i_gakunen - 1] >=
                0) {
              count++;
            }
          }
          if (count <= 1) {
            //ここで学連選抜選手データに追加
            final Senshu_Gakuren_Data gakurenSenshu =
                Senshu_Gakuren_Data.fromSenshuData(
                  timejununivfilterdSenshudata[i],
                );
            await gakurenSenshuBox.put(gakurenSenshu.id, gakurenSenshu);
            break;
          }
        }
      }
    }
    ////学連選抜区間配置
    // 区間ごとの特徴スコアを計算し、順番を決定
    List<Map<String, dynamic>> kukanScores = [];
    for (int i = 0; i < gh[0].kukansuu_taikaigoto[racebangou]; i++) {
      double kukanKyoriScore =
          0.15 * gh[0].kyori_taikai_kukangoto[racebangou][i];
      double kukanNoboriScore =
          7500 *
          gh[0].kyoriwariainobori_taikai_kukangoto[racebangou][i] *
          gh[0].heikinkoubainobori_taikai_kukangoto[racebangou][i];
      double kukanKudariScore =
          7500 *
          gh[0].kyoriwariaikudari_taikai_kukangoto[racebangou][i] *
          gh[0].heikinkoubaikudari_taikai_kukangoto[racebangou][i];
      double kukanKirikaeScore =
          8.0 *
          gh[0].noborikudarikirikaekaisuu_taikai_kukangoto[racebangou][i]
              .toDouble();
      double totalKukanScore =
          kukanKyoriScore.abs() +
          kukanNoboriScore.abs() +
          kukanKudariScore.abs() +
          kukanKirikaeScore.abs();
      // --- 新たに追加した補正ロジック ---
      // 区間番号が若いほど大きなボーナスを加算する
      // 例: 1区(index 0)には1000のボーナス、2区(index 1)には900のボーナス、...
      // この係数は、区間の特徴とバランスを見ながら調整してください。
      if (i == 0 && gh[0].kukansuu_taikaigoto[racebangou] > 0) {
        double rankBonus =
            (gh[0].kukansuu_taikaigoto[racebangou] - (i + 0)) * 150.0;
        totalKukanScore += rankBonus;
      } else {
        double rankBonus = (gh[0].kukansuu_taikaigoto[racebangou] - i) * 150.0;
        totalKukanScore += rankBonus;
      }
      // ------------------------------------
      kukanScores.add({'kukanIndex': i, 'score': totalKukanScore});
    }
    // スコアが高い順に区間をソート
    kukanScores.sort((a, b) => b['score'].compareTo(a['score']));
    kukanIDs = kukanScores.map((k) => k['kukanIndex'] as int).toList();
    int senshusuu_univ = 0;
    final availableSenshu = gakurenSenshuBox.values.toList();
    Set<int> assignedSenshuIds = {};
    List<Senshu_Gakuren_Data> playersToSave = [];
    senshusuu_univ = availableSenshu.length;
    //print('\n--- 大学ID ${sortedUnivData[id_univ].id} の選手割り当てを開始 ---');
    //print("選手数は${senshusuu_univ}人");
    int count = 0;
    for (int kukanIndex in kukanIDs) {
      // 現在時刻と前回の休憩時刻を比較
      {
        final now = DateTime.now();
        if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
          // 3秒以上経過してたら
          await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
          Chousa.lastGapTime = DateTime.now();
        }
      }
      Senshu_Gakuren_Data? bestSenshu;
      double maxScore = -99999999999.0;
      double minScore = 99999999999.0;
      for (Senshu_Gakuren_Data senshu in availableSenshu) {
        if (assignedSenshuIds.contains(senshu.id)) {
          continue;
        }
        // ...（既存のスコア計算ロジック）...
        double kukanKyoriScore =
            0.01 * gh[0].kyori_taikai_kukangoto[racebangou][kukanIndex];
        double kukanNoboriScore =
            2 *
            7500.0 *
            gh[0].kyoriwariainobori_taikai_kukangoto[racebangou][kukanIndex] *
            gh[0].heikinkoubainobori_taikai_kukangoto[racebangou][kukanIndex];
        double kukanKudariScore =
            2 *
            7500.0 *
            gh[0].kyoriwariaikudari_taikai_kukangoto[racebangou][kukanIndex] *
            gh[0].heikinkoubaikudari_taikai_kukangoto[racebangou][kukanIndex];
        double kukanKirikaeScore =
            4.0 *
            gh[0]
                .noborikudarikirikaekaisuu_taikai_kukangoto[racebangou][kukanIndex]
                .toDouble();
        kukanKudariScore = kukanKudariScore.abs();
        double senshuKyoriScore = 0;
        double kukanbetuhosei = 0.0;
        double hosei_tani = 0.0;
        double hosei_time = 0.0;
        double temp_time = 0.0;
        if (senshu.time_bestkiroku.length > 2 &&
            gh[0].kyori_taikai_kukangoto[racebangou][kukanIndex] > 15000) {
          temp_time = senshu.time_bestkiroku[2];
          hosei_tani = 105.4875 / 100.0;
          if (kukanIndex == 0) {
            kukanbetuhosei =
                senshu.tandokusou.toDouble() -
                senshu.paceagesagetaiouryoku.toDouble();
            hosei_time = kukanbetuhosei * hosei_tani;
            temp_time = temp_time + hosei_time;
          }
          if (kukanIndex == 1 || kukanIndex == 2) {
            kukanbetuhosei =
                senshu.tandokusou.toDouble() -
                senshu.paceagesagetaiouryoku.toDouble();
            hosei_time = kukanbetuhosei * hosei_tani * 0.5;
            temp_time = temp_time + hosei_time;
          }
          if (kukanIndex > 2) {
            //補正なし
          }
          senshuKyoriScore = (-5 / 12) * temp_time + 1625;
        } else if (senshu.time_bestkiroku.length > 1 &&
            gh[0].kyori_taikai_kukangoto[racebangou][kukanIndex] > 7500) {
          temp_time = senshu.time_bestkiroku[1];
          hosei_tani = 50.0 / 100.0;
          if (kukanIndex == 0) {
            //補正なし
          }
          if (kukanIndex == 1 || kukanIndex == 2) {
            kukanbetuhosei =
                senshu.tandokusou.toDouble() -
                senshu.paceagesagetaiouryoku.toDouble();
            hosei_time = kukanbetuhosei * hosei_tani * 0.5;
            temp_time = temp_time - hosei_time;
          }
          if (kukanIndex > 2) {
            kukanbetuhosei =
                senshu.tandokusou.toDouble() -
                senshu.paceagesagetaiouryoku.toDouble();
            hosei_time = kukanbetuhosei * hosei_tani;
            temp_time = temp_time - hosei_time;
          }
          senshuKyoriScore = (-10 / 9) * temp_time + 1983.33;
        } else if (senshu.time_bestkiroku.length > 0) {
          temp_time = senshu.time_bestkiroku[0];
          hosei_tani = 25.0 / 100.0;
          if (kukanIndex == 0) {
            //補正なし
          }
          if (kukanIndex == 1 || kukanIndex == 2) {
            kukanbetuhosei =
                senshu.tandokusou.toDouble() -
                senshu.paceagesagetaiouryoku.toDouble();
            hosei_time = kukanbetuhosei * hosei_tani * 0.5;
            temp_time = temp_time - hosei_time;
          }
          if (kukanIndex > 2) {
            kukanbetuhosei =
                senshu.tandokusou.toDouble() -
                senshu.paceagesagetaiouryoku.toDouble();
            hosei_time = kukanbetuhosei * hosei_tani;
            temp_time = temp_time - hosei_time;
          }
          senshuKyoriScore = (-10 / 3) * temp_time + 2850;
        }
        senshuKyoriScore *= 7;
        double senshuNoboriScore = 3 * senshu.noboritekisei.toDouble();
        double senshuKudariScore = 3 * senshu.kudaritekisei.toDouble();
        double senshuKirikaeScore =
            3 * senshu.noborikudarikirikaenouryoku.toDouble();
        double specialScore = 0;
        specialScore = 0;
        double totalScore =
            (kukanKyoriScore * senshuKyoriScore) +
            (kukanNoboriScore * senshuNoboriScore) +
            (kukanKudariScore * senshuKudariScore) +
            (kukanKirikaeScore * senshuKirikaeScore) +
            specialScore;

        if (totalScore.isNaN) {
          totalScore = -99999.0;
        }
        if (totalScore > maxScore) {
          maxScore = totalScore;
          bestSenshu = senshu;
        }
        if (totalScore < minScore) {
          minScore = totalScore;
        }
      }
      if (bestSenshu != null) {
        count++;
        bestSenshu.entrykukan_race[racebangou][bestSenshu.gakunen - 1] =
            kukanIndex;
        playersToSave.add(bestSenshu);
        assignedSenshuIds.add(bestSenshu.id);
      }
    }
    for (var senshu in playersToSave) {
      await senshu.save();
    }
  }
  ///////////学連選抜終わり////////

  if ((racebangou >= 0 && racebangou <= 2) || racebangou == 5) {
    //check
    // 関数の内部に関数として定義
    int checkEkidenEntries({
      required int racebangou,
      required List<UnivData> sortedUnivData,
      required List<SenshuData> sortedSenshuData,
    }) {
      // 1. sortedSenshuDataをunividごとにグループ化する
      final Map<int, List<SenshuData>> senshuDataByUnivid = {};
      for (var senshuData in sortedSenshuData) {
        if (!senshuDataByUnivid.containsKey(senshuData.univid)) {
          senshuDataByUnivid[senshuData.univid] = [];
        }
        senshuDataByUnivid[senshuData.univid]!.add(senshuData);
      }
      // 2. 出場大学のunividsを取得する
      final List<int> entryUnivids = sortedUnivData
          .where((univData) => univData.taikaientryflag[racebangou] == 1)
          .map((univData) => univData.id)
          .toList();

      // 3. 出場大学ごとにエントリー状況をチェックする
      for (var univid in entryUnivids) {
        // 選手データがなければスキップ
        if (!senshuDataByUnivid.containsKey(univid)) {
          print('univid: $univid には選手データがありません。');
          continue;
        }
        final List<int> entryKukanList = [];
        // 大学ごとの選手リストをループ
        for (var senshuData in senshuDataByUnivid[univid]!) {
          // エントリーされている区間を取得
          if (senshuData.entrykukan_race[racebangou][senshuData.gakunen - 1] >
              -1) {
            entryKukanList.add(
              senshuData.entrykukan_race[racebangou][senshuData.gakunen - 1],
            );
          }
        }
        // 4. ルールチェック
        final Set<int> uniqueEntries = entryKukanList.toSet();
        if (uniqueEntries.length != entryKukanList.length) {
          print('univid: $univid で複数の区間にエントリーしている選手がいます。');
          return univid;
        }
        final int maxKukan =
            gh[0].kukansuu_taikaigoto[racebangou]; // 区間の最大数に応じて変更
        if (uniqueEntries.length < maxKukan) {
          print('univid: $univid でエントリー不足の区間があります。');
          return univid;
        }
      }
      return -1;
    }

    // checkEkidenEntries関数の呼び出し
    kantoku.yobiint2[22] = 0;
    await kantoku.save();
    int isValid = checkEkidenEntries(
      racebangou: racebangou,
      sortedUnivData: sortedUnivData,
      sortedSenshuData: sortedSenshuData,
    );
    // 戻り値を使って次の処理を行う
    if (isValid == -1) {
      print('エントリーはすべて有効です。');
    } else {
      print('${sortedUnivData[isValid].name}のエントリーに問題があります。');
      //throw Exception('開発用強制停止: 想定外');
      //全区間最適解区間配置を使わないやり方で区間再配置する
      for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
        if (sortedSenshuData[i]
                .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] >
            -2) {
          sortedSenshuData[i].entrykukan_race[racebangou][sortedSenshuData[i]
                      .gakunen -
                  1] =
              -1;
          sortedSenshuData[i].string_racesetumei = "";
          await sortedSenshuData[i].save();
        }
      }
      // 区間ごとの特徴スコアを計算し、順番を決定
      List<Map<String, dynamic>> kukanScores = [];
      for (int i = 0; i < gh[0].kukansuu_taikaigoto[racebangou]; i++) {
        double kukanKyoriScore =
            0.15 * gh[0].kyori_taikai_kukangoto[racebangou][i];
        double kukanNoboriScore =
            7500 *
            gh[0].kyoriwariainobori_taikai_kukangoto[racebangou][i] *
            gh[0].heikinkoubainobori_taikai_kukangoto[racebangou][i];
        double kukanKudariScore =
            7500 *
            gh[0].kyoriwariaikudari_taikai_kukangoto[racebangou][i] *
            gh[0].heikinkoubaikudari_taikai_kukangoto[racebangou][i];
        double kukanKirikaeScore =
            8.0 *
            gh[0].noborikudarikirikaekaisuu_taikai_kukangoto[racebangou][i]
                .toDouble();

        double totalKukanScore =
            kukanKyoriScore.abs() +
            kukanNoboriScore.abs() +
            kukanKudariScore.abs() +
            kukanKirikaeScore.abs();

        // --- 新たに追加した補正ロジック ---
        // 区間番号が若いほど大きなボーナスを加算する
        // 例: 1区(index 0)には1000のボーナス、2区(index 1)には900のボーナス、...
        // この係数は、区間の特徴とバランスを見ながら調整してください。
        if (i == 0 && gh[0].kukansuu_taikaigoto[racebangou] > 0) {
          double rankBonus =
              (gh[0].kukansuu_taikaigoto[racebangou] - (i + 0)) * 150.0;
          totalKukanScore += rankBonus;
        } else {
          double rankBonus =
              (gh[0].kukansuu_taikaigoto[racebangou] - i) * 150.0;
          totalKukanScore += rankBonus;
        }

        // ------------------------------------

        kukanScores.add({'kukanIndex': i, 'score': totalKukanScore});
      }

      // スコアが高い順に区間をソート
      kukanScores.sort((a, b) => b['score'].compareTo(a['score']));

      // ソートされた順番でkukanIDsリストを作成
      /*List<int> kukanIDs = kukanScores
        .map((k) => k['kukanIndex'] as int)
        .toList();*/
      kukanIDs = kukanScores.map((k) => k['kukanIndex'] as int).toList();
      // --- 追加したログ出力 ---
      //print('選手を配置する区間の順番 (インデックス): $kukanIDs');
      // ----------------------

      int senshusuu_univ = 0;
      // すべての大学に対して処理を行う
      for (int id_univ = 0; id_univ < sortedUnivData.length; id_univ++) {
        senshusuu_univ = 0;
        //for (var university in sortedUnivData) {
        if (sortedUnivData[id_univ].taikaientryflag[racebangou] == 1) {
          List<SenshuData> availableSenshu = sortedSenshuData
              .where(
                (s) =>
                    s.univid == id_univ &&
                    s.entrykukan_race[racebangou][s.gakunen - 1] >= -1, //-2は除外
                //university.taikaientryflag[racebangou] == 1,
              )
              .toList();

          Set<int> assignedSenshuIds = {};
          List<SenshuData> playersToSave = [];
          senshusuu_univ = availableSenshu.length;
          //print('\n--- 大学ID ${sortedUnivData[id_univ].id} の選手割り当てを開始 ---');
          //print("選手数は${senshusuu_univ}人");
          int count = 0;

          for (int kukanIndex in kukanIDs) {
            SenshuData? bestSenshu;
            double maxScore = -99999999999.0;
            double minScore = 99999999999.0;

            for (SenshuData senshu in availableSenshu) {
              if (assignedSenshuIds.contains(senshu.id)) {
                continue;
              }

              // ...（既存のスコア計算ロジック）...
              double kukanKyoriScore =
                  0.01 * gh[0].kyori_taikai_kukangoto[racebangou][kukanIndex];
              double kukanNoboriScore =
                  2 *
                  7500.0 *
                  gh[0]
                      .kyoriwariainobori_taikai_kukangoto[racebangou][kukanIndex] *
                  gh[0]
                      .heikinkoubainobori_taikai_kukangoto[racebangou][kukanIndex];
              double kukanKudariScore =
                  2 *
                  7500.0 *
                  gh[0]
                      .kyoriwariaikudari_taikai_kukangoto[racebangou][kukanIndex] *
                  gh[0]
                      .heikinkoubaikudari_taikai_kukangoto[racebangou][kukanIndex];
              double kukanKirikaeScore =
                  4.0 *
                  gh[0]
                      .noborikudarikirikaekaisuu_taikai_kukangoto[racebangou][kukanIndex]
                      .toDouble();

              kukanKudariScore = kukanKudariScore.abs();

              double senshuKyoriScore = 0;
              double kukanbetuhosei = 0.0;
              double hosei_tani = 0.0;
              double hosei_time = 0.0;
              double temp_time = 0.0;
              if (senshu.time_bestkiroku.length > 2 &&
                  gh[0].kyori_taikai_kukangoto[racebangou][kukanIndex] >
                      15000) {
                temp_time = senshu.time_bestkiroku[2];
                hosei_tani = 105.4875 / 100.0;
                if (kukanIndex == 0) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani;
                  temp_time = temp_time + hosei_time;
                }
                if (kukanIndex == 1 || kukanIndex == 2) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                  temp_time = temp_time + hosei_time;
                }
                if (kukanIndex > 2) {
                  //補正なし
                }
                senshuKyoriScore = (-5 / 12) * temp_time + 1625;
              } else if (senshu.time_bestkiroku.length > 1 &&
                  gh[0].kyori_taikai_kukangoto[racebangou][kukanIndex] > 7500) {
                temp_time = senshu.time_bestkiroku[1];
                hosei_tani = 50.0 / 100.0;
                if (kukanIndex == 0) {
                  //補正なし
                }
                if (kukanIndex == 1 || kukanIndex == 2) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                  temp_time = temp_time - hosei_time;
                }
                if (kukanIndex > 2) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani;
                  temp_time = temp_time - hosei_time;
                }
                senshuKyoriScore = (-10 / 9) * temp_time + 1983.33;
              } else if (senshu.time_bestkiroku.length > 0) {
                temp_time = senshu.time_bestkiroku[0];
                hosei_tani = 25.0 / 100.0;
                if (kukanIndex == 0) {
                  //補正なし
                }
                if (kukanIndex == 1 || kukanIndex == 2) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani * 0.5;
                  temp_time = temp_time - hosei_time;
                }
                if (kukanIndex > 2) {
                  kukanbetuhosei =
                      senshu.tandokusou.toDouble() -
                      senshu.paceagesagetaiouryoku.toDouble();
                  hosei_time = kukanbetuhosei * hosei_tani;
                  temp_time = temp_time - hosei_time;
                }
                senshuKyoriScore = (-10 / 3) * temp_time + 2850;
              }
              senshuKyoriScore *= 7;
              double senshuNoboriScore = 3 * senshu.noboritekisei.toDouble();
              double senshuKudariScore = 3 * senshu.kudaritekisei.toDouble();
              double senshuKirikaeScore =
                  3 * senshu.noborikudarikirikaenouryoku.toDouble();

              double specialScore = 0;
              /*if (kukanIndex == 0) {
              specialScore = senshu.paceagesagetaiouryoku.toDouble();
            } else if (kukanIndex == 1 || kukanIndex == 2) {
              specialScore =
                  0.5 * senshu.paceagesagetaiouryoku.toDouble() +
                  0.5 * senshu.tandokusou.toDouble();
            } else {
              specialScore = senshu.tandokusou.toDouble();
            }
            //specialScore *= 200;
            */
              specialScore = 0;

              double totalScore =
                  (kukanKyoriScore * senshuKyoriScore) +
                  (kukanNoboriScore * senshuNoboriScore) +
                  (kukanKudariScore * senshuKudariScore) +
                  (kukanKirikaeScore * senshuKirikaeScore) +
                  specialScore;

              if (totalScore.isNaN) {
                totalScore = -99999.0;
              }

              if (totalScore > maxScore) {
                maxScore = totalScore;
                bestSenshu = senshu;
              }
              if (totalScore < minScore) {
                minScore = totalScore;
              }
            }

            if (bestSenshu != null) {
              count++;
              bestSenshu.entrykukan_race[racebangou][bestSenshu.gakunen - 1] =
                  kukanIndex;
              playersToSave.add(bestSenshu);
              assignedSenshuIds.add(bestSenshu.id);
              /*print(
              '  ${kukanIndex + 1}区 ID= ${bestSenshu.id}' +
                  ' ハーフ= ' +
                  _timeToMinuteSecondString(bestSenshu.time_bestkiroku[2]) +
                  ' 1万= ' +
                  _timeToMinuteSecondString(bestSenshu.time_bestkiroku[1]) +
                  ' 5千= ' +
                  _timeToMinuteSecondString(bestSenshu.time_bestkiroku[0]) +
                  ' 登り= ${bestSenshu.noboritekisei} 下り= ${bestSenshu.kudaritekisei} updown= ${bestSenshu.noborikudarikirikaenouryoku}',
            );
            print(
              '    ${kukanIndex + 1}区 maxscore=${maxScore.toInt()} minscore=${minScore.toInt()}',
            );*/
            }
          }

          //print('\n--- 大学ID ${sortedUnivData[id_univ].id} の選手割り当てを終了 ---');
          //print('合計${count}人エントリー');

          for (var senshu in playersToSave) {
            await senshu.save();
          }
        }
      }

      kantoku.yobiint2[22] = 1;
      await kantoku.save();

      int isValid2 = checkEkidenEntries(
        racebangou: racebangou,
        sortedUnivData: sortedUnivData,
        sortedSenshuData: sortedSenshuData,
      );
      if (isValid2 == -1) {
        print('再配置エントリーはすべて有効です。');
      } else {
        print('${sortedUnivData[isValid2].name}の再配置エントリーに問題があります。');
        kantoku.yobiint2[22] = 2;
        await kantoku.save();
      }
    } //////区間再配置終わり////////
  }

  if (racebangou == 3) {
    List<int> ketteisuu_univgoto = List.filled(TEISUU.UNIVSUU, 0);

    List<SenshuData> time10000junsenshudata = sortedSenshuData
        .toList()
        .cast<SenshuData>()
        .where((s) => s.time_bestkiroku.length > 1)
        .toList();

    time10000junsenshudata.sort(
      (a, b) => a.time_bestkiroku[1].compareTo(b.time_bestkiroku[1]),
    );

    for (
      int senshuid = 0;
      senshuid < time10000junsenshudata.length;
      senshuid++
    ) {
      final currentSenshu = time10000junsenshudata[senshuid];
      if (sortedUnivData[currentSenshu.univid].taikaientryflag[racebangou] ==
          1) {
        if (ketteisuu_univgoto[currentSenshu.univid] == 0 &&
            currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                    1] ==
                -1) {
          currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen - 1] =
              3;
          ketteisuu_univgoto[currentSenshu.univid] += 1;
          await currentSenshu.save();
        } else if (ketteisuu_univgoto[currentSenshu.univid] == 1 &&
            currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                    1] ==
                -1) {
          currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen - 1] =
              3;
          ketteisuu_univgoto[currentSenshu.univid] += 1;
          await currentSenshu.save();
        } else if (ketteisuu_univgoto[currentSenshu.univid] == 2 &&
            currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                    1] ==
                -1) {
          currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen - 1] =
              2;
          ketteisuu_univgoto[currentSenshu.univid] += 1;
          await currentSenshu.save();
        } else if (ketteisuu_univgoto[currentSenshu.univid] == 3 &&
            currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                    1] ==
                -1) {
          currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen - 1] =
              2;
          ketteisuu_univgoto[currentSenshu.univid] += 1;
          await currentSenshu.save();
        } else if (ketteisuu_univgoto[currentSenshu.univid] == 4 &&
            currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                    1] ==
                -1) {
          currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen - 1] =
              0;
          ketteisuu_univgoto[currentSenshu.univid] += 1;
          await currentSenshu.save();
        } else if (ketteisuu_univgoto[currentSenshu.univid] == 5 &&
            currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                    1] ==
                -1) {
          currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen - 1] =
              0;
          ketteisuu_univgoto[currentSenshu.univid] += 1;
          await currentSenshu.save();
        } else if (ketteisuu_univgoto[currentSenshu.univid] == 6 &&
            currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                    1] ==
                -1) {
          currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen - 1] =
              1;
          ketteisuu_univgoto[currentSenshu.univid] += 1;
          await currentSenshu.save();
        } else if (ketteisuu_univgoto[currentSenshu.univid] == 7 &&
            currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                    1] ==
                -1) {
          currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen - 1] =
              1;
          ketteisuu_univgoto[currentSenshu.univid] += 1;
          await currentSenshu.save();
        }
      }
    }
  } // if racebangou == 3 終端

  if (racebangou == 4) {
    for (var senshu in sortedSenshuData) {
      senshu.entrykukan_race[racebangou][senshu.gakunen - 1] += 1;
      await senshu.save();
    }

    // Hive.box() を使って、既に開いているBoxを取得
    final shuudansouBox = Hive.box<Shuudansou>('shuudansouBox');
    // Boxからデータを読み込む
    final Shuudansou shuudansou = shuudansouBox.get('ShuudansouData')!;

    for (var senshu in sortedSenshuData) {
      if (sortedUnivData[senshu.univid].taikaientryflag[racebangou] == 1) {
        if (senshu.entrykukan_race[racebangou][senshu.gakunen - 1] == 0) {
          shuudansou.sisoutime[senshu.id] = await runTrialCalculation(
            senshu.id,
            0,
            gh[0],
            sortedSenshuData,
            sortedUnivData,
            kantoku,
          );
          await shuudansou.save();
        }
      }
    }
  } // if racebangou == 4 終端

  gh[0].nowracecalckukan = 0;
  await gh[0].save(); // gh[0]の変更を保存

  if (racebangou >= 0 && racebangou <= 5) {
    for (int i = 0; i < sortedSenshuData.length; i++) {
      sortedSenshuData[i].startchokugotobidasiflag = 0;
      sortedSenshuData[i].startchokugotobidasiseikouflag = 0;
      sortedSenshuData[i].sijiflag = 0;
      sortedSenshuData[i].sijiseikouflag = 0;
      await sortedSenshuData[i].save();
    }
    for (int i = 0; i < sortedUnivData.length; i++) {
      for (int ii = 0; ii < TEISUU.SUU_MAXKUKANSUU; ii++) {
        sortedUnivData[i].mokuhyojuniwositamawatteruflag[ii] = 0;
      }
      await sortedUnivData[i].save();
    }
    for (int i = 0; i < TEISUU.SENSHUSUU_UNIV; i++) {
      gh[0].SijiSelectedOption[i] = 0;
    }
    await gh[0].save(); // gh[0]の変更を保存

    List<SenshuData> univfilteredsenshudata = sortedSenshuData
        .where(
          (s) =>
              s.univid == gh[0].MYunivid &&
              s.entrykukan_race[racebangou][s.gakunen - 1] >= -1,
        )
        .toList();

    List<SenshuData> gakunenjununivfilteredsenshudata = univfilteredsenshudata
        .toList(); // 新しいリストを作成
    gakunenjununivfilteredsenshudata.sort((a, b) {
      // gakunenを降順で比較
      int gakunenComparison = b.gakunen.compareTo(a.gakunen);

      // gakunenが同じ場合は、idを昇順で比較
      if (gakunenComparison == 0) {
        return a.id.compareTo(b.id);
      }

      return gakunenComparison;
    });

    if (racebangou == 3) {
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        for (int i = 0; i < gakunenjununivfilteredsenshudata.length; i++) {
          final currentSenshu = gakunenjununivfilteredsenshudata[i];
          if (currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                  1] ==
              i_kukan) {
            gh[0].SenshuSelectedOption[i_kukan] = i;
            await gh[0].save();
            break;
          }
        }
        for (int i = gakunenjununivfilteredsenshudata.length - 1; i >= 0; i--) {
          final currentSenshu = gakunenjununivfilteredsenshudata[i];
          if (currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                  1] ==
              i_kukan) {
            gh[0].SenshuSelectedOption2[i_kukan] = i;
            await gh[0].save();
            break;
          }
        }
      }
    } else if (racebangou != 4) {
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        for (int i = 0; i < gakunenjununivfilteredsenshudata.length; i++) {
          final currentSenshu = gakunenjununivfilteredsenshudata[i];
          if (currentSenshu.entrykukan_race[racebangou][currentSenshu.gakunen -
                  1] ==
              i_kukan) {
            gh[0].SenshuSelectedOption[i_kukan] = i;
            await gh[0].save();
            break;
          }
        }
      }
    }
  }

  // 区間内順位算出
  for (int i = 0; i < sortedSenshuData.length; i++) {
    for (
      int i_kirokubangou = 0;
      i_kirokubangou < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU;
      i_kirokubangou++
    ) {
      sortedSenshuData[i].kukannaijuni[i_kirokubangou] = TEISUU.DEFAULTJUNI;
    }
    await sortedSenshuData[i].save();
  }

  for (
    int i_kukan = 0;
    i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
    i_kukan++
  ) {
    List<SenshuData> entryfilteredsenshudata = sortedSenshuData
        .where((s) => s.entrykukan_race[racebangou][s.gakunen - 1] == i_kukan)
        .toList();

    for (
      int i_kirokubangou = 0;
      i_kirokubangou < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU;
      i_kirokubangou++
    ) {
      // time_bestkirokuのインデックスが有効か確認
      final validEntries = entryfilteredsenshudata
          .where((s) => s.time_bestkiroku.length > i_kirokubangou)
          .toList();

      List<SenshuData> timejunsenshudata = validEntries.toList(); // 新しいリストを作成
      timejunsenshudata.sort(
        (a, b) => a.time_bestkiroku[i_kirokubangou].compareTo(
          b.time_bestkiroku[i_kirokubangou],
        ),
      );

      for (int i_juni = 0; i_juni < timejunsenshudata.length; i_juni++) {
        timejunsenshudata[i_juni].kukannaijuni[i_kirokubangou] = i_juni;
        await timejunsenshudata[i_juni].save();
      }
    }
  }

  //COMチーム選手指示確定//
  //11月駅伝予選全組
  if (racebangou == 3) {
    List<SenshuData> comEntryFilteredSenshudata = sortedSenshuData
        .where(
          (s) =>
              s.entrykukan_race[racebangou][s.gakunen - 1] >= 0 &&
              s.univid != gh[0].MYunivid,
        )
        .toList();
    //指示なし飛び出し
    for (var senshu in comEntryFilteredSenshudata) {
      if (senshu.konjou >= 85) {
        if (Random().nextInt(100) < TEISUU.STARTTOBIDASIKAKURITU) {
          senshu.startchokugotobidasiflag = 1;
          await senshu.save();
        }
      }
    }
  }
  //駅伝1区
  if (racebangou <= 2 || racebangou == 5) {
    List<SenshuData> comEntryFilteredSenshudata = sortedSenshuData
        .where(
          (s) =>
              s.entrykukan_race[racebangou][s.gakunen - 1] == 0 &&
              s.univid != gh[0].MYunivid,
        )
        .toList();
    //指示なし飛び出し
    for (var senshu in comEntryFilteredSenshudata) {
      if (senshu.konjou >= 85) {
        if (Random().nextInt(100) < TEISUU.STARTTOBIDASIKAKURITU) {
          senshu.startchokugotobidasiflag = 1;
          await senshu.save();
        }
      }
    }
  }
  //駅伝2区以降
  if (racebangou <= 2 || racebangou == 5) {
    List<SenshuData> comEntryFilteredSenshudata = sortedSenshuData
        .where(
          (s) =>
              s.entrykukan_race[racebangou][s.gakunen - 1] >= 1 &&
              s.univid != gh[0].MYunivid,
        )
        .toList();
    for (var senshu in comEntryFilteredSenshudata) {
      if (senshu.konjou >= 85) {
        if (Random().nextInt(100) < senshu.konjou) {
          senshu.sijiflag = 1;
          /*if (Random().nextInt(100) < senshu.konjou) {
            senshu.sijiseikouflag = 1;
          }*/
          await senshu.save();
        }
      }
      if (senshu.sijiflag == 0 && senshu.heijousin >= 80) {
        if (Random().nextInt(100) < senshu.heijousin) {
          senshu.sijiflag = 2;
          /*if (Random().nextInt(100) < senshu.heijousin) {
            senshu.sijiseikouflag = 1;
          }*/
          await senshu.save();
        }
      }
    }
  }

  /////わざと一旦閉じる
  //var open_rsenshubox = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');

  final endTime = DateTime.now();
  final timeInterval = endTime.difference(startTime).inMicroseconds / 1000000.0;
  print("EntryCalc終了 処理時間: ${_timeToMinuteSecondString(timeInterval)}経過");
  return kukanIDs;
}
