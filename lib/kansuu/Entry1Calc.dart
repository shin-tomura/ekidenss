//import 'package:path_provider/path_provider.dart';
//import 'package:flutter/foundation.dart';
//import 'dart:math'; // Randomクラスを使用するため
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
//import 'package:ekiden/senshu_gakuren_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
//import 'package:ekiden/kansuu/FindFastestTeam.dart';
//import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:hive_flutter/hive_flutter.dart';
//import 'package:ekiden/Shuudansou.dart';
//import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/album.dart';

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
Future<List<int>> Entry1Calc({
  required int racebangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
}) async {
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
  print("Entry1Calcに入った");

  final albumBox = Hive.box<Album>('albumBox');
  // Boxからデータを読み込む
  final Album album = albumBox.get('AlbumData')!;
  /////わざと一旦閉じる
  //var close_rsenshubox = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');
  //close_rsenshubox.close();

  // Swiftの || 演算子と範囲演算子をDartの || と >= <= に変換
  if (racebangou <= 2 || racebangou == 5 || racebangou == 4) {
    // いったん全員1次エントリー漏れで初期化
    for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
      sortedSenshuData[i]
              .entrykukan_race[racebangou][sortedSenshuData[i].gakunen - 1] =
          -2;
      sortedSenshuData[i].string_racesetumei = "";
      await sortedSenshuData[i].save();
    }
  }
  print("Entry1Calc通過1");

  if (racebangou <= 2 || racebangou == 5 || racebangou == 4) {
    int ninzuu_teiin = 0;
    if (gh[0].kukansuu_taikaigoto[racebangou] <= 6) {
      ninzuu_teiin = 8;
    } else if (gh[0].kukansuu_taikaigoto[racebangou] <= 8) {
      ninzuu_teiin = 13;
    } else {
      ninzuu_teiin = 16;
    }
    if (racebangou == 4) ninzuu_teiin = 12;
    int kukansuu_near5000 = 0;
    int kukansuu_near10000 = 0;
    int kukansuu_nearhalf = 0;
    double totalkyori = 0.0;
    for (
      int i_kukan = 0;
      i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
      i_kukan++
    ) {
      totalkyori += gh[0].kyori_taikai_kukangoto[racebangou][i_kukan];
      if (gh[0].kyori_taikai_kukangoto[racebangou][i_kukan] < 7500.0) {
        kukansuu_near5000++;
      } else if (gh[0].kyori_taikai_kukangoto[racebangou][i_kukan] < 15000.0) {
        kukansuu_near10000++;
      } else {
        kukansuu_nearhalf++;
      }
    }
    double averagekyori =
        totalkyori / (gh[0].kukansuu_taikaigoto[racebangou].toDouble());
    print("Entry1Calc通過2");
    // すべての大学に対して処理を行う
    for (int id_univ = 0; id_univ < sortedUnivData.length; id_univ++) {
      // 現在時刻と前回の休憩時刻を比較
      final now = DateTime.now();
      if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
        // 3秒以上経過してたら
        await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
        Chousa.lastGapTime = DateTime.now();
      }
      //for (var university in sortedUnivData) {
      if (sortedUnivData[id_univ].taikaientryflag[racebangou] == 1) {
        List<SenshuData> time5000junsenshudata = sortedSenshuData
            .toList() // 元のリストを変更しないためtoList()
            .cast<SenshuData>() // 型を明示的に指定 (HiveObjectのListの場合など)
            .where(
              (s) => s.time_bestkiroku.isNotEmpty && s.univid == id_univ,
            ) // time_bestkirokuが空でないことを確認
            .toList();
        time5000junsenshudata.sort(
          (a, b) => a.time_bestkiroku[0].compareTo(b.time_bestkiroku[0]),
        );

        List<SenshuData> time10000junsenshudata = sortedSenshuData
            .toList()
            .cast<SenshuData>()
            .where(
              (s) => s.time_bestkiroku.length > 1 && s.univid == id_univ,
            ) // time_bestkiroku[1]が存在することを確認
            .toList();
        time10000junsenshudata.sort(
          (a, b) => a.time_bestkiroku[1].compareTo(b.time_bestkiroku[1]),
        );

        List<SenshuData> timehalfjunsenshudata = sortedSenshuData
            .toList()
            .cast<SenshuData>()
            .where(
              (s) => s.time_bestkiroku.length > 2 && s.univid == id_univ,
            ) // time_bestkiroku[1]が存在することを確認
            .toList();
        timehalfjunsenshudata.sort(
          (a, b) => a.time_bestkiroku[2].compareTo(b.time_bestkiroku[2]),
        );
        int hoketusuu =
            ninzuu_teiin -
            kukansuu_near5000 -
            kukansuu_near10000 -
            kukansuu_nearhalf;
        int plussuu = hoketusuu ~/ 3;
        //if (kukansuu_near5000 > 0) {
        for (int i = 0; i < kukansuu_near5000 + plussuu; i++) {
          time5000junsenshudata[i]
                  .entrykukan_race[racebangou][time5000junsenshudata[i]
                      .gakunen -
                  1] =
              -1;
          await time5000junsenshudata[i].save();
        }
        //}
        //if (kukansuu_near10000 > 0) {
        for (int i = 0; i < kukansuu_near10000 + plussuu; i++) {
          time10000junsenshudata[i]
                  .entrykukan_race[racebangou][time10000junsenshudata[i]
                      .gakunen -
                  1] =
              -1;
          await time10000junsenshudata[i].save();
        }
        //}
        //if (kukansuu_nearhalf > 0) {
        for (int i = 0; i < kukansuu_nearhalf + plussuu; i++) {
          timehalfjunsenshudata[i]
                  .entrykukan_race[racebangou][timehalfjunsenshudata[i]
                      .gakunen -
                  1] =
              -1;
          await timehalfjunsenshudata[i].save();
        }
        //}
        int entryzumisuu = 0;
        List<SenshuData> univfilteredsenshudata = sortedSenshuData
            .toList() // 元のリストを変更しないためtoList()
            .cast<SenshuData>() // 型を明示的に指定 (HiveObjectのListの場合など)
            .where((s) => s.univid == id_univ) // time_bestkirokuが空でないことを確認
            .toList();
        for (int i = 0; i < univfilteredsenshudata.length; i++) {
          if (univfilteredsenshudata[i]
                  .entrykukan_race[racebangou][univfilteredsenshudata[i]
                      .gakunen -
                  1] ==
              -1) {
            entryzumisuu++;
          }
        }
        for (int i = 0; i < TEISUU.SENSHUSUU_UNIV; i++) {
          if (entryzumisuu >= ninzuu_teiin) break;
          if (averagekyori < 7500.0) {
            if (time5000junsenshudata[i]
                    .entrykukan_race[racebangou][time5000junsenshudata[i]
                        .gakunen -
                    1] ==
                -2) {
              time5000junsenshudata[i]
                      .entrykukan_race[racebangou][time5000junsenshudata[i]
                          .gakunen -
                      1] =
                  -1;
              await time5000junsenshudata[i].save();
              entryzumisuu++;
            }
          } else if (averagekyori < 15000.0) {
            if (time10000junsenshudata[i]
                    .entrykukan_race[racebangou][time10000junsenshudata[i]
                        .gakunen -
                    1] ==
                -2) {
              time10000junsenshudata[i]
                      .entrykukan_race[racebangou][time10000junsenshudata[i]
                          .gakunen -
                      1] =
                  -1;
              await time10000junsenshudata[i].save();
              entryzumisuu++;
            }
          } else {
            if (timehalfjunsenshudata[i]
                    .entrykukan_race[racebangou][timehalfjunsenshudata[i]
                        .gakunen -
                    1] ==
                -2) {
              timehalfjunsenshudata[i]
                      .entrykukan_race[racebangou][timehalfjunsenshudata[i]
                          .gakunen -
                      1] =
                  -1;
              await timehalfjunsenshudata[i].save();
              entryzumisuu++;
            }
          }
        }
      }
    }
    print("Entry1Calc通過3");
  }

  final endTime = DateTime.now();
  final timeInterval = endTime.difference(startTime).inMicroseconds / 1000000.0;
  print("Entry1Calc終了 処理時間: ${_timeToMinuteSecondString(timeInterval)}経過");
  return kukanIDs;
}
