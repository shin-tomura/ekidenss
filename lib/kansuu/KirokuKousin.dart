//import 'dart:core';
import 'dart:math'; // Randomクラスを使用するため
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのインポート
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kiroku.dart';
//import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/toukei.dart';
import 'package:ekiden/kansuu/ChartPanelSenshu.dart';
import 'package:ekiden/kansuu/ChartPanelUniv.dart';

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

Future<void> kirokuKousin({
  required int racebangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedunivdata,
  required List<SenshuData> sortedsenshudata,
}) async {
  // 現在時刻と前回の休憩時刻を比較
  {
    final now = DateTime.now();
    if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
      // 3秒以上経過してたら
      await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
      Chousa.lastGapTime = DateTime.now();
    }
  }
  // Dartでは Date() は現在時刻を表さないので、DateTime.now() を使用
  // var startTime = DateTime.now();
  // var endTime = DateTime.now();
  // var timeInterval = endTime.difference(startTime).inMilliseconds; // 必要であれば
  final startTime = DateTime.now();
  print("KirokuKousinに入った");

  int temp_kirokuhozonjunisuu = 1;
  /////わざと一旦閉じる
  //var close_rsenshubox = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');
  //close_rsenshubox.close();
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData kantoku = kantokuBox.get('KantokuData')!;

  final gakurensenshuBox = Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox');
  final gakurensenshudata = gakurensenshuBox.values.toList();

  // Hive.box() を使って、既に開いているBoxを取得
  final kirokuBox = Hive.box<Kiroku>('kirokuBox');
  // Boxからデータを読み込む
  final Kiroku? kiroku = kirokuBox.get('KirokuData');

  final random = Random();
  gh[0].last_goldenballkakutokusuu = 0;
  gh[0].last_silverballkakutokusuu = 0;
  await gh[0].save(); // gh[0] の変更を保存

  for (var i = 0; i < sortedsenshudata.length; i++) {
    sortedsenshudata[i].chokuzentaikai_pbflag = 0;
    sortedsenshudata[i].chokuzentaikai_kojinrekidaisinflag = 0;
    sortedsenshudata[i].chokuzentaikai_kojinunivsinflag = 0;
    await sortedsenshudata[i].save(); // SenshuData の変更を保存
  }

  if (racebangou >= 0 && racebangou <= 5) {
    // univの順位とタイムの過去データ変数へ代入
    for (var iUniv = 0; iUniv < sortedunivdata.length; iUniv++) {
      for (var iZurasi = TEISUU.KIROKUHOZONNENSUU - 1; iZurasi > 0; iZurasi--) {
        sortedunivdata[iUniv].juni_race[racebangou][iZurasi] =
            sortedunivdata[iUniv].juni_race[racebangou][iZurasi - 1];
        sortedunivdata[iUniv].time_race[racebangou][iZurasi] =
            sortedunivdata[iUniv].time_race[racebangou][iZurasi - 1];
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }

    // `time_taikai_total` はリストなので、アクセス方法に注意
    // Swiftの sorted は新しい配列を返すため、Dartでも同様に新しいリストを作成
    var timeJunUnivData = List<UnivData>.from(sortedunivdata)
      ..sort(
        (a, b) => a.time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1]
            .compareTo(
              b.time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1],
            ),
      );

    for (var iJuni = 0; iJuni < timeJunUnivData.length; iJuni++) {
      if (timeJunUnivData[iJuni].taikaientryflag[racebangou] == 1) {
        timeJunUnivData[iJuni].juni_race[racebangou][0] = iJuni;
        timeJunUnivData[iJuni].time_race[racebangou][0] = timeJunUnivData[iJuni]
            .time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1];
        timeJunUnivData[iJuni].taikaibetushutujoukaisuu[racebangou] += 1;

        if (timeJunUnivData[iJuni].taikaibetusaikoujuni[racebangou] >
            timeJunUnivData[iJuni].juni_race[racebangou][0]) {
          timeJunUnivData[iJuni].taikaibetusaikoujuni[racebangou] =
              timeJunUnivData[iJuni].juni_race[racebangou][0];
        }
        timeJunUnivData[iJuni]
                .taikaibetujunibetukaisuu[racebangou][timeJunUnivData[iJuni]
                .juni_race[racebangou][0]] +=
            1;
      } else {
        timeJunUnivData[iJuni].juni_race[racebangou][0] = TEISUU.DEFAULTJUNI;
        timeJunUnivData[iJuni].time_race[racebangou][0] = TEISUU.DEFAULTTIME;
      }
      await timeJunUnivData[iJuni].save(); // UnivData の変更を保存
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
    // 個人レース結果を代入
    var entryFilteredSenshuData = sortedsenshudata
        .where((s) => s.entrykukan_race[racebangou][s.gakunen - 1] > -1)
        .toList();

    var timeJunSortedEntryFilteredSenshuData = List<SenshuData>.from(
      entryFilteredSenshuData,
    )..sort((a, b) => a.time_taikai_total.compareTo(b.time_taikai_total));

    for (
      var iEntry = 0;
      iEntry < timeJunSortedEntryFilteredSenshuData.length;
      iEntry++
    ) {
      timeJunSortedEntryFilteredSenshuData[iEntry]
          .kukantime_race[racebangou][timeJunSortedEntryFilteredSenshuData[iEntry]
              .gakunen -
          1] = timeJunSortedEntryFilteredSenshuData[iEntry]
          .time_taikai_total;
      await timeJunSortedEntryFilteredSenshuData[iEntry]
          .save(); // SenshuData の変更を保存
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
    // 大会新や区間新フラグ
    for (var i = 0; i < sortedunivdata.length; i++) {
      sortedunivdata[i].chokuzentaikai_zentaitaikaisinflag = 0;
      sortedunivdata[i].chokuzentaikai_univtaikaisinflag = 0;
      if (gh[0].time_zentaitaikaikiroku[racebangou][0] >
          sortedunivdata[i]
              .time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1]) {
        sortedunivdata[i].chokuzentaikai_zentaitaikaisinflag = 1;
      }
      if (i == gh[0].MYunivid) {
        if (sortedunivdata[gh[0].MYunivid]
                .time_univtaikaikiroku[racebangou][0] >
            sortedunivdata[i]
                .time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1]) {
          sortedunivdata[i].chokuzentaikai_univtaikaisinflag = 1;
        }
      }
      await sortedunivdata[i].save(); // UnivData の変更を保存
    }

    for (var i = 0; i < sortedsenshudata.length; i++) {
      sortedsenshudata[i].chokuzentaikai_zentaikukansinflag = 0;
      sortedsenshudata[i].chokuzentaikai_univkukansinflag = 0;
      await sortedsenshudata[i].save(); // SenshuData の変更を保存
    }

    for (
      var iKukan = 0;
      iKukan < gh[0].kukansuu_taikaigoto[racebangou];
      iKukan++
    ) {
      for (var i = 0; i < sortedsenshudata.length; i++) {
        if (sortedsenshudata[i]
                .entrykukan_race[racebangou][sortedsenshudata[i].gakunen - 1] ==
            iKukan) {
          if (gh[0].time_zentaikukankiroku[racebangou][iKukan][0] >
              sortedsenshudata[i].time_taikai_total) {
            sortedsenshudata[i].chokuzentaikai_zentaikukansinflag = 1;
          }

          if (sortedsenshudata[i].univid == gh[0].MYunivid) {
            if (sortedunivdata[gh[0].MYunivid]
                    .time_univkukankiroku[racebangou][iKukan][0] >
                sortedsenshudata[i].time_taikai_total) {
              sortedsenshudata[i].chokuzentaikai_univkukansinflag = 1;
            }
          }
          await sortedsenshudata[i].save(); // SenshuData の変更を保存
        }
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
    // 個人区間記録
    for (
      var iKukan = 0;
      iKukan < gh[0].kukansuu_taikaigoto[racebangou];
      iKukan++
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
      var kukanFilteredSenshuData = entryFilteredSenshuData
          .where((s) => s.entrykukan_race[racebangou][s.gakunen - 1] == iKukan)
          .toList();

      var timeJunSortedKukanFilteredSenshuData = List<SenshuData>.from(
        kukanFilteredSenshuData,
      )..sort((a, b) => a.time_taikai_total.compareTo(b.time_taikai_total));

      for (
        var iJuni = 0;
        iJuni < timeJunSortedKukanFilteredSenshuData.length;
        iJuni++
      ) {
        timeJunSortedKukanFilteredSenshuData[iJuni]
                .kukanjuni_race[racebangou][timeJunSortedKukanFilteredSenshuData[iJuni]
                    .gakunen -
                1] =
            iJuni;
        await timeJunSortedKukanFilteredSenshuData[iJuni]
            .save(); // SenshuData の変更を保存
      }

      // 全体区間記録
      //日本人+留学生
      for (
        var iTimeJuni = 0;
        iTimeJuni < timeJunSortedKukanFilteredSenshuData.length;
        iTimeJuni++
      ) {
        if (gh[0].time_zentaikukankiroku[racebangou][iKukan][TEISUU
                    .SUU_BESTKIROKUHOZONJUNISUU -
                1] >
            timeJunSortedKukanFilteredSenshuData[iTimeJuni].time_taikai_total) {
          for (
            var iHozonJuni = 0;
            iHozonJuni < temp_kirokuhozonjunisuu;
            iHozonJuni++
          ) {
            if (gh[0].time_zentaikukankiroku[racebangou][iKukan][iHozonJuni] >
                timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                    .time_taikai_total) {
              for (
                var iZurasijuni = temp_kirokuhozonjunisuu - 1;
                iZurasijuni > iHozonJuni;
                iZurasijuni--
              ) {
                gh[0].time_zentaikukankiroku[racebangou][iKukan][iZurasijuni] =
                    gh[0]
                        .time_zentaikukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
                gh[0].year_zentaikukankiroku[racebangou][iKukan][iZurasijuni] =
                    gh[0]
                        .year_zentaikukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
                gh[0].month_zentaikukankiroku[racebangou][iKukan][iZurasijuni] =
                    gh[0]
                        .month_zentaikukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
                gh[0].univname_zentaikukankiroku[racebangou][iKukan][iZurasijuni] =
                    gh[0]
                        .univname_zentaikukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
                gh[0].name_zentaikukankiroku[racebangou][iKukan][iZurasijuni] =
                    gh[0]
                        .name_zentaikukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
                gh[0].gakunen_zentaikukankiroku[racebangou][iKukan][iZurasijuni] =
                    gh[0]
                        .gakunen_zentaikukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
              }
              gh[0].time_zentaikukankiroku[racebangou][iKukan][iHozonJuni] =
                  timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                      .time_taikai_total;
              gh[0].year_zentaikukankiroku[racebangou][iKukan][iHozonJuni] =
                  gh[0].year;
              gh[0].month_zentaikukankiroku[racebangou][iKukan][iHozonJuni] =
                  gh[0].month;
              gh[0].univname_zentaikukankiroku[racebangou][iKukan][iHozonJuni] =
                  sortedunivdata[timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                          .univid]
                      .name;
              gh[0].name_zentaikukankiroku[racebangou][iKukan][iHozonJuni] =
                  timeJunSortedKukanFilteredSenshuData[iTimeJuni].name;
              gh[0].gakunen_zentaikukankiroku[racebangou][iKukan][iHozonJuni] =
                  timeJunSortedKukanFilteredSenshuData[iTimeJuni].gakunen;
              break;
            }
          }
          await gh[0].save(); // gh[0] の変更を保存
        } else {
          break;
        }
      } // 全体区間記録ループ終端
      //留学生
      for (
        var iTimeJuni = 0;
        iTimeJuni < timeJunSortedKukanFilteredSenshuData.length;
        iTimeJuni++
      ) {
        if (timeJunSortedKukanFilteredSenshuData[iTimeJuni].hirou == 1) {
          if (kiroku!
                  .time_zentai_ryuugakusei_kukankiroku[racebangou][iKukan][TEISUU
                      .SUU_BESTKIROKUHOZONJUNISUU -
                  1] >
              timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                  .time_taikai_total) {
            for (
              var iHozonJuni = 0;
              iHozonJuni < temp_kirokuhozonjunisuu;
              iHozonJuni++
            ) {
              if (kiroku
                      .time_zentai_ryuugakusei_kukankiroku[racebangou][iKukan][iHozonJuni] >
                  timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                      .time_taikai_total) {
                for (
                  var iZurasijuni = temp_kirokuhozonjunisuu - 1;
                  iZurasijuni > iHozonJuni;
                  iZurasijuni--
                ) {}
                kiroku.time_zentai_ryuugakusei_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                        .time_taikai_total;
                kiroku.year_zentai_ryuugakusei_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    gh[0].year;
                kiroku.month_zentai_ryuugakusei_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    gh[0].month;
                kiroku.univname_zentai_ryuugakusei_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    sortedunivdata[timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                            .univid]
                        .name;
                kiroku.name_zentai_ryuugakusei_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    timeJunSortedKukanFilteredSenshuData[iTimeJuni].name;
                kiroku.gakunen_zentai_ryuugakusei_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    timeJunSortedKukanFilteredSenshuData[iTimeJuni].gakunen;
                break;
              }
            }
            await kiroku.save(); // gh[0] の変更を保存
          } else {
            break;
          }
        }
      } // 全体区間記録ループ終端
      //日本人
      for (
        var iTimeJuni = 0;
        iTimeJuni < timeJunSortedKukanFilteredSenshuData.length;
        iTimeJuni++
      ) {
        if (timeJunSortedKukanFilteredSenshuData[iTimeJuni].hirou != 1) {
          if (kiroku!.time_zentai_jap_kukankiroku[racebangou][iKukan][TEISUU
                      .SUU_BESTKIROKUHOZONJUNISUU -
                  1] >
              timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                  .time_taikai_total) {
            for (
              var iHozonJuni = 0;
              iHozonJuni < temp_kirokuhozonjunisuu;
              iHozonJuni++
            ) {
              if (kiroku
                      .time_zentai_jap_kukankiroku[racebangou][iKukan][iHozonJuni] >
                  timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                      .time_taikai_total) {
                for (
                  var iZurasijuni = temp_kirokuhozonjunisuu - 1;
                  iZurasijuni > iHozonJuni;
                  iZurasijuni--
                ) {}
                kiroku.time_zentai_jap_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                        .time_taikai_total;
                kiroku.year_zentai_jap_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    gh[0].year;
                kiroku.month_zentai_jap_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    gh[0].month;
                kiroku.univname_zentai_jap_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    sortedunivdata[timeJunSortedKukanFilteredSenshuData[iTimeJuni]
                            .univid]
                        .name;
                kiroku.name_zentai_jap_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    timeJunSortedKukanFilteredSenshuData[iTimeJuni].name;
                kiroku.gakunen_zentai_jap_kukankiroku[racebangou][iKukan][iHozonJuni] =
                    timeJunSortedKukanFilteredSenshuData[iTimeJuni].gakunen;
                break;
              }
            }
            await kiroku.save(); // gh[0] の変更を保存
          } else {
            break;
          }
        }
      } // 全体区間記録ループ終端
      // 学内区間記録
      var univKukanFilteredSenshuData = kukanFilteredSenshuData
          .where((s) => s.univid == gh[0].MYunivid)
          .toList();
      //日本人+留学生
      for (
        var iTimeJuni = 0;
        iTimeJuni < univKukanFilteredSenshuData.length;
        iTimeJuni++
      ) {
        if (sortedunivdata[gh[0].MYunivid]
                .time_univkukankiroku[racebangou][iKukan][TEISUU
                    .SUU_BESTKIROKUHOZONJUNISUU -
                1] >
            univKukanFilteredSenshuData[iTimeJuni].time_taikai_total) {
          for (
            var iHozonJuni = 0;
            iHozonJuni < temp_kirokuhozonjunisuu;
            iHozonJuni++
          ) {
            if (sortedunivdata[gh[0].MYunivid]
                    .time_univkukankiroku[racebangou][iKukan][iHozonJuni] >
                univKukanFilteredSenshuData[iTimeJuni].time_taikai_total) {
              for (
                var iZurasijuni = temp_kirokuhozonjunisuu - 1;
                iZurasijuni > iHozonJuni;
                iZurasijuni--
              ) {
                sortedunivdata[gh[0].MYunivid]
                        .time_univkukankiroku[racebangou][iKukan][iZurasijuni] =
                    sortedunivdata[gh[0].MYunivid]
                        .time_univkukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
                sortedunivdata[gh[0].MYunivid]
                        .year_univkukankiroku[racebangou][iKukan][iZurasijuni] =
                    sortedunivdata[gh[0].MYunivid]
                        .year_univkukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
                sortedunivdata[gh[0].MYunivid]
                        .month_univkukankiroku[racebangou][iKukan][iZurasijuni] =
                    sortedunivdata[gh[0].MYunivid]
                        .month_univkukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
                sortedunivdata[gh[0].MYunivid]
                        .name_univkukankiroku[racebangou][iKukan][iZurasijuni] =
                    sortedunivdata[gh[0].MYunivid]
                        .name_univkukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
                sortedunivdata[gh[0].MYunivid]
                        .gakunen_univkukankiroku[racebangou][iKukan][iZurasijuni] =
                    sortedunivdata[gh[0].MYunivid]
                        .gakunen_univkukankiroku[racebangou][iKukan][iZurasijuni -
                        1];
              }
              sortedunivdata[gh[0].MYunivid]
                      .time_univkukankiroku[racebangou][iKukan][iHozonJuni] =
                  univKukanFilteredSenshuData[iTimeJuni].time_taikai_total;
              sortedunivdata[gh[0].MYunivid]
                      .year_univkukankiroku[racebangou][iKukan][iHozonJuni] =
                  gh[0].year;
              sortedunivdata[gh[0].MYunivid]
                      .month_univkukankiroku[racebangou][iKukan][iHozonJuni] =
                  gh[0].month;
              sortedunivdata[gh[0].MYunivid]
                      .name_univkukankiroku[racebangou][iKukan][iHozonJuni] =
                  univKukanFilteredSenshuData[iTimeJuni].name;
              sortedunivdata[gh[0].MYunivid]
                      .gakunen_univkukankiroku[racebangou][iKukan][iHozonJuni] =
                  univKukanFilteredSenshuData[iTimeJuni].gakunen;
              break;
            }
          }
          await sortedunivdata[gh[0].MYunivid].save(); // UnivData の変更を保存
        } else {
          break;
        }
      } // 学内区間記録ループ終端
      //留学生
      for (
        var iTimeJuni = 0;
        iTimeJuni < univKukanFilteredSenshuData.length;
        iTimeJuni++
      ) {
        if (univKukanFilteredSenshuData[iTimeJuni].hirou == 1) {
          if (kiroku!.time_univ_ryuugakusei_kukankiroku[gh[0]
                  .MYunivid][racebangou][iKukan][TEISUU
                      .SUU_BESTKIROKUHOZONJUNISUU -
                  1] >
              univKukanFilteredSenshuData[iTimeJuni].time_taikai_total) {
            for (
              var iHozonJuni = 0;
              iHozonJuni < temp_kirokuhozonjunisuu;
              iHozonJuni++
            ) {
              if (kiroku.time_univ_ryuugakusei_kukankiroku[gh[0]
                      .MYunivid][racebangou][iKukan][iHozonJuni] >
                  univKukanFilteredSenshuData[iTimeJuni].time_taikai_total) {
                for (
                  var iZurasijuni = temp_kirokuhozonjunisuu - 1;
                  iZurasijuni > iHozonJuni;
                  iZurasijuni--
                ) {}
                kiroku.time_univ_ryuugakusei_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    univKukanFilteredSenshuData[iTimeJuni].time_taikai_total;
                kiroku.year_univ_ryuugakusei_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    gh[0].year;
                kiroku.month_univ_ryuugakusei_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    gh[0].month;
                kiroku.name_univ_ryuugakusei_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    univKukanFilteredSenshuData[iTimeJuni].name;
                kiroku.gakunen_univ_ryuugakusei_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    univKukanFilteredSenshuData[iTimeJuni].gakunen;
                break;
              }
            }
            await kiroku.save(); // UnivData の変更を保存
          } else {
            break;
          }
        }
      } // 学内区間記録ループ終端
      //日本人
      for (
        var iTimeJuni = 0;
        iTimeJuni < univKukanFilteredSenshuData.length;
        iTimeJuni++
      ) {
        if (univKukanFilteredSenshuData[iTimeJuni].hirou != 1) {
          if (kiroku!.time_univ_jap_kukankiroku[gh[0]
                  .MYunivid][racebangou][iKukan][TEISUU
                      .SUU_BESTKIROKUHOZONJUNISUU -
                  1] >
              univKukanFilteredSenshuData[iTimeJuni].time_taikai_total) {
            for (
              var iHozonJuni = 0;
              iHozonJuni < temp_kirokuhozonjunisuu;
              iHozonJuni++
            ) {
              if (kiroku.time_univ_jap_kukankiroku[gh[0]
                      .MYunivid][racebangou][iKukan][iHozonJuni] >
                  univKukanFilteredSenshuData[iTimeJuni].time_taikai_total) {
                for (
                  var iZurasijuni = temp_kirokuhozonjunisuu - 1;
                  iZurasijuni > iHozonJuni;
                  iZurasijuni--
                ) {}
                kiroku.time_univ_jap_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    univKukanFilteredSenshuData[iTimeJuni].time_taikai_total;
                kiroku.year_univ_jap_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    gh[0].year;
                kiroku.month_univ_jap_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    gh[0].month;
                kiroku.name_univ_jap_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    univKukanFilteredSenshuData[iTimeJuni].name;
                kiroku.gakunen_univ_jap_kukankiroku[gh[0]
                        .MYunivid][racebangou][iKukan][iHozonJuni] =
                    univKukanFilteredSenshuData[iTimeJuni].gakunen;
                break;
              }
            }
            await kiroku.save(); // UnivData の変更を保存
          } else {
            break;
          }
        }
      } // 学内区間記録ループ終端
    } // 個人区間記録i_kukanループ終端

    // 大会記録
    for (var iTimeJuni = 0; iTimeJuni < timeJunUnivData.length; iTimeJuni++) {
      // 現在時刻と前回の休憩時刻を比較
      {
        final now = DateTime.now();
        if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
          // 3秒以上経過してたら
          await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
          Chousa.lastGapTime = DateTime.now();
        }
      }
      if (gh[0].time_zentaitaikaikiroku[racebangou][TEISUU
                  .SUU_BESTKIROKUHOZONJUNISUU -
              1] >
          timeJunUnivData[iTimeJuni]
              .time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1]) {
        if (iTimeJuni == 0 && (racebangou <= 2 || racebangou == 5)) {
          //大会記録樹立時の途中区間での大会記録比用に保存
          for (
            int i_kukan = 0;
            i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
            i_kukan++
          ) {
            kantoku.yobiint4[racebangou * 10 + 30 + i_kukan] =
                timeJunUnivData[iTimeJuni].time_taikai_total[i_kukan].toInt();
          }
          await kantoku.save();
        }

        for (
          var iHozonJuni = 0;
          iHozonJuni < temp_kirokuhozonjunisuu;
          iHozonJuni++
        ) {
          if (gh[0].time_zentaitaikaikiroku[racebangou][iHozonJuni] >
              timeJunUnivData[iTimeJuni].time_taikai_total[gh[0]
                      .kukansuu_taikaigoto[racebangou] -
                  1]) {
            for (
              var iZurasijuni = temp_kirokuhozonjunisuu - 1;
              iZurasijuni > iHozonJuni;
              iZurasijuni--
            ) {
              gh[0].time_zentaitaikaikiroku[racebangou][iZurasijuni] =
                  gh[0].time_zentaitaikaikiroku[racebangou][iZurasijuni - 1];
              gh[0].year_zentaitaikaikiroku[racebangou][iZurasijuni] =
                  gh[0].year_zentaitaikaikiroku[racebangou][iZurasijuni - 1];
              gh[0].month_zentaitaikaikiroku[racebangou][iZurasijuni] =
                  gh[0].month_zentaitaikaikiroku[racebangou][iZurasijuni - 1];
              gh[0].univname_zentaitaikaikiroku[racebangou][iZurasijuni] = gh[0]
                  .univname_zentaitaikaikiroku[racebangou][iZurasijuni - 1];
            }
            gh[0].time_zentaitaikaikiroku[racebangou][iHozonJuni] =
                timeJunUnivData[iTimeJuni].time_taikai_total[gh[0]
                        .kukansuu_taikaigoto[racebangou] -
                    1];
            gh[0].year_zentaitaikaikiroku[racebangou][iHozonJuni] = gh[0].year;
            gh[0].month_zentaitaikaikiroku[racebangou][iHozonJuni] =
                gh[0].month;
            gh[0].univname_zentaitaikaikiroku[racebangou][iHozonJuni] =
                timeJunUnivData[iTimeJuni].name;
            break;
          }
        }
        await gh[0].save(); // gh[0] の変更を保存
      } else {
        break;
      }
    } // 大会記録ループ終端

    // 学内大会記録
    if (sortedunivdata[gh[0].MYunivid].time_univtaikaikiroku[racebangou][TEISUU
                .SUU_BESTKIROKUHOZONJUNISUU -
            1] >
        sortedunivdata[gh[0].MYunivid]
            .time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1]) {
      for (
        var iHozonJuni = 0;
        iHozonJuni < temp_kirokuhozonjunisuu;
        iHozonJuni++
      ) {
        if (sortedunivdata[gh[0].MYunivid]
                .time_univtaikaikiroku[racebangou][iHozonJuni] >
            sortedunivdata[gh[0].MYunivid]
                .time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1]) {
          for (
            var iZurasijuni = temp_kirokuhozonjunisuu - 1;
            iZurasijuni > iHozonJuni;
            iZurasijuni--
          ) {
            sortedunivdata[gh[0].MYunivid]
                    .time_univtaikaikiroku[racebangou][iZurasijuni] =
                sortedunivdata[gh[0].MYunivid]
                    .time_univtaikaikiroku[racebangou][iZurasijuni - 1];
            sortedunivdata[gh[0].MYunivid]
                    .year_univtaikaikiroku[racebangou][iZurasijuni] =
                sortedunivdata[gh[0].MYunivid]
                    .year_univtaikaikiroku[racebangou][iZurasijuni - 1];
            sortedunivdata[gh[0].MYunivid]
                    .month_univtaikaikiroku[racebangou][iZurasijuni] =
                sortedunivdata[gh[0].MYunivid]
                    .month_univtaikaikiroku[racebangou][iZurasijuni - 1];
          }
          sortedunivdata[gh[0].MYunivid]
                  .time_univtaikaikiroku[racebangou][iHozonJuni] =
              sortedunivdata[gh[0].MYunivid]
                  .time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1];
          sortedunivdata[gh[0].MYunivid]
                  .year_univtaikaikiroku[racebangou][iHozonJuni] =
              gh[0].year;
          sortedunivdata[gh[0].MYunivid]
                  .month_univtaikaikiroku[racebangou][iHozonJuni] =
              gh[0].month;
          break;
        }
      }
      await sortedunivdata[gh[0].MYunivid].save(); // UnivData の変更を保存
    } // 学内大会記録ループ終端
  }

  // 目標順位達成の場合のご褒美
  if (racebangou >= 0 && racebangou <= 5) {
    int _getMaxRank(int raceIdx) {
      switch (raceIdx) {
        case 0:
          return 8;
        case 1:
          return 13;
        case 2:
          return 18;
        case 5:
          return 28;
        default:
          return 19;
      }
    }

    int _getSeedRank(int raceIdx) {
      switch (raceIdx) {
        case 0:
          return 4;
        case 1:
          return 7;
        case 2:
          return 9;
        case 5:
          return 9;
        default:
          return 4;
      }
    }

    kantoku.yobiint2[1] = 0;
    await kantoku.save();
    if (sortedunivdata[gh[0].MYunivid].taikaientryflag[racebangou] == 1) {
      if (sortedunivdata[gh[0].MYunivid].juni_race[racebangou][0] <=
          sortedunivdata[gh[0].MYunivid].mokuhyojuni[racebangou]) {
        kantoku.yobiint2[1] = 1;
        await kantoku.save();
        if (kantoku.yobiint2[0] == 0) {
          int r = 0;
          int rYuushou = 0;
          int rSeed = 0;
          if (gh[0].kazeflag == 0) {
            //r = 30;
            rSeed = 30;
            rYuushou = 50;
          }
          if (gh[0].kazeflag == 1) {
            //r = 50;
            rSeed = 50;
            rYuushou = 100;
          }
          if (gh[0].kazeflag == 2) {
            //r = 100;
            rSeed = 100;
            rYuushou = 200;
          }
          if (gh[0].kazeflag == 3) {
            //r = 200;
            rSeed = 200;
            rYuushou = 300;
          }

          //目標順位による報酬の補正
          if (racebangou <= 2 || racebangou == 5) {
            int maxrank = _getMaxRank(racebangou);
            int seedrank = _getSeedRank(racebangou);
            int targetrank =
                sortedunivdata[gh[0].MYunivid].mokuhyojuni[racebangou];
            if (targetrank == 0) {
              r = rYuushou;
              //何もしない
              /*} else if ((racebangou == 0 && targetrank >= 5) ||
                (racebangou == 1 && targetrank >= 8) ||
                (racebangou == 2 && targetrank >= 10) ||
                (racebangou == 5 && targetrank >= 10)) {*/
            } else if (targetrank == maxrank) {
              r = 10;
            } else {
              int sa = 0;
              double persa = 0.0;
              int ryou_koujousin = 0;
              int plusryou = 0;
              if (targetrank <= seedrank) {
                sa = rYuushou - rSeed;
                persa = sa / (seedrank - 0);
                ryou_koujousin = seedrank - targetrank;
                plusryou = (persa * ryou_koujousin).toInt();
                r = rSeed + plusryou;
              } else {
                sa = rSeed - 10;
                persa = sa / (maxrank - seedrank);
                ryou_koujousin = maxrank - targetrank;
                plusryou = (persa * ryou_koujousin).toInt();
                r = 10 + plusryou;
              }
            }
          } else {
            //予選突破は最低量に
            r = 10;
          }

          // Dartでは `Random()` を使用
          //final random = Random();
          if (random.nextInt(100) < 10) {
            if ((racebangou <= 2 || racebangou == 5) &&
                sortedunivdata[gh[0].MYunivid].juni_race[racebangou][0] == 0) {
              if (sortedunivdata[gh[0].MYunivid].mokuhyojuni[racebangou] == 0) {
                r *= 2;
              }
              //r = rYuushou; // Int.random(in: r_yuushou...r_yuushou) と同じ
              gh[0].last_goldenballkakutokusuu = r * kantoku.yobiint2[12];
            } else {
              gh[0].last_goldenballkakutokusuu = r * kantoku.yobiint2[12];
            }
            gh[0].goldenballsuu += r * kantoku.yobiint2[12];
          } else {
            if ((racebangou <= 2 || racebangou == 5) &&
                sortedunivdata[gh[0].MYunivid].juni_race[racebangou][0] == 0) {
              if (sortedunivdata[gh[0].MYunivid].mokuhyojuni[racebangou] == 0) {
                r *= 2;
              }
              //r = rYuushou; // Int.random(in: r_yuushou...r_yuushou) と同じ
              gh[0].last_silverballkakutokusuu = r * kantoku.yobiint2[12];
            } else {
              gh[0].last_silverballkakutokusuu = r * kantoku.yobiint2[12];
            }
            gh[0].silverballsuu += r * kantoku.yobiint2[12];
          }
          if (gh[0].goldenballsuu > 9999) {
            gh[0].goldenballsuu = 9999;
          }
          if (gh[0].silverballsuu > 9999) {
            gh[0].silverballsuu = 9999;
          }
          await gh[0].save(); // gh[0] の変更を保存
        }
      }
    }
  }

  if (racebangou == 5) {
    // カスタム駅伝
    // 名声加算
    int? bunsi = int.tryParse(sortedunivdata[5].name_tanshuku);
    if (bunsi == null || bunsi < 1 || bunsi > 10) {
      bunsi = 1;
    }
    int? bunbo = int.tryParse(sortedunivdata[6].name_tanshuku);
    if (bunbo == null || bunbo < 1 || bunbo > 10) {
      bunbo = 1;
    }
    double bairitu = bunsi.toDouble() / bunbo.toDouble();
    for (var iUniv = 0; iUniv < sortedunivdata.length; iUniv++) {
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 0) {
        int zoukaryou =
            (bairitu *
                    2000.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 1) {
        int zoukaryou =
            (bairitu *
                    1000.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 2) {
        int zoukaryou =
            (bairitu *
                    800.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 3) {
        int zoukaryou =
            (bairitu *
                    360.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 4) {
        int zoukaryou =
            (bairitu *
                    320.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 5) {
        int zoukaryou =
            (bairitu *
                    280.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 6) {
        int zoukaryou =
            (bairitu *
                    240.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 7) {
        int zoukaryou =
            (bairitu *
                    200.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 8) {
        int zoukaryou =
            (bairitu *
                    160.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 9) {
        int zoukaryou =
            (bairitu *
                    120.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] >= 10 &&
          sortedunivdata[iUniv].juni_race[racebangou][0] <= 19) {
        int zoukaryou =
            (bairitu *
                    50.toDouble() *
                    (gh[0].spurtryokuseichousisuu4.toDouble() /
                        gh[0].spurtryokuseichousisuu5.toDouble()) *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      //区間賞名声加算
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        if (sortedunivdata[iUniv].kukanjuni_taikai[i_kukan] == 0) {
          sortedunivdata[iUniv].meisei_yeargoto[0] +=
              (0.2 *
                      2000.toDouble() *
                      bairitu *
                      (gh[0].spurtryokuseichousisuu4.toDouble() /
                          gh[0].spurtryokuseichousisuu5.toDouble()))
                  .toInt();
        }
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }
  }
  if (racebangou == 0) {
    // 10月駅伝
    // 名声加算
    int? bunsi = int.tryParse(sortedunivdata[1].name_tanshuku);
    if (bunsi == null || bunsi < 1 || bunsi > 10) {
      bunsi = 1;
    }
    int? bunbo = int.tryParse(sortedunivdata[2].name_tanshuku);
    if (bunbo == null || bunbo < 1 || bunbo > 10) {
      bunbo = 1;
    }
    double bairitu = bunsi.toDouble() / bunbo.toDouble();
    for (var iUniv = 0; iUniv < sortedunivdata.length; iUniv++) {
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 0) {
        int zoukaryou =
            (500.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 1) {
        int zoukaryou =
            (250.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 2) {
        int zoukaryou =
            (200.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 3) {
        int zoukaryou =
            (90.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 4) {
        int zoukaryou =
            (80.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 5) {
        int zoukaryou =
            (24.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 6) {
        int zoukaryou =
            (23.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 7) {
        int zoukaryou =
            (22.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 8) {
        int zoukaryou =
            (21.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 9) {
        int zoukaryou =
            (20.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      //区間賞名声加算
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        if (sortedunivdata[iUniv].kukanjuni_taikai[i_kukan] == 0) {
          sortedunivdata[iUniv].meisei_yeargoto[0] +=
              (500.toDouble() * 0.2 * bairitu).toInt();
        }
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }
  }

  if (racebangou == 1) {
    // 11月駅伝
    // 名声加算
    int? bunsi = int.tryParse(sortedunivdata[3].name_tanshuku);
    if (bunsi == null || bunsi < 1 || bunsi > 10) {
      bunsi = 1;
    }
    int? bunbo = int.tryParse(sortedunivdata[4].name_tanshuku);
    if (bunbo == null || bunbo < 1 || bunbo > 10) {
      bunbo = 1;
    }
    double bairitu = bunsi.toDouble() / bunbo.toDouble();
    for (var iUniv = 0; iUniv < sortedunivdata.length; iUniv++) {
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 0) {
        int zoukaryou =
            (500.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 1) {
        int zoukaryou =
            (250.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 2) {
        int zoukaryou =
            (200.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 3) {
        int zoukaryou =
            (90.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 4) {
        int zoukaryou =
            (80.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 5) {
        int zoukaryou =
            (70.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 6) {
        int zoukaryou =
            (60.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 7) {
        int zoukaryou =
            (50.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] >= 8 &&
          sortedunivdata[iUniv].juni_race[racebangou][0] <= 14) {
        int zoukaryou =
            (20.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      //区間賞名声加算
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        if (sortedunivdata[iUniv].kukanjuni_taikai[i_kukan] == 0) {
          sortedunivdata[iUniv].meisei_yeargoto[0] +=
              (500.toDouble() * 0.2 * bairitu).toInt();
        }
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }
    // シード権
    for (var iUniv = 0; iUniv < sortedunivdata.length; iUniv++) {
      if (sortedunivdata[iUniv].juni_race[racebangou][0] < 8) {
        sortedunivdata[iUniv].taikaiseedflag[racebangou] = 1;
        /*sortedunivdata[iUniv].mokuhyojuni[racebangou] =
            sortedunivdata[iUniv].juni_race[racebangou][0] -
            (Random().nextInt(3) + 2); // 2...4
        if (sortedunivdata[iUniv].mokuhyojuni[racebangou] < 0) {
          sortedunivdata[iUniv].mokuhyojuni[racebangou] = 0;
        }*/
      } else {
        sortedunivdata[iUniv].taikaiseedflag[racebangou] = 0;
        //sortedunivdata[iUniv].mokuhyojuni[3] = 6;
        //sortedunivdata[iUniv].mokuhyojuni[racebangou] = 7;
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }
  }

  if (racebangou == 2) {
    // 正月駅伝
    // 名声加算ついでに三冠回数
    int? bunsi = int.tryParse(sortedunivdata[5].name_tanshuku);
    if (bunsi == null || bunsi < 1 || bunsi > 10) {
      bunsi = 1;
    }
    int? bunbo = int.tryParse(sortedunivdata[6].name_tanshuku);
    if (bunbo == null || bunbo < 1 || bunbo > 10) {
      bunbo = 1;
    }
    double bairitu = bunsi.toDouble() / bunbo.toDouble();
    for (var iUniv = 0; iUniv < sortedunivdata.length; iUniv++) {
      if (sortedunivdata[iUniv].juni_race[0][0] == 0 &&
          sortedunivdata[iUniv].juni_race[1][0] == 0 &&
          sortedunivdata[iUniv].juni_race[2][0] == 0) {
        sortedunivdata[iUniv].sankankaisuu += 1;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 0) {
        int zoukaryou =
            (2000.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 1) {
        int zoukaryou =
            (1000.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 2) {
        int zoukaryou =
            (800.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 3) {
        int zoukaryou =
            (360.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 4) {
        int zoukaryou =
            (320.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 5) {
        int zoukaryou =
            (280.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 6) {
        int zoukaryou =
            (240.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 7) {
        int zoukaryou =
            (200.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 8) {
        int zoukaryou =
            (160.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] == 9) {
        int zoukaryou =
            (120.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      if (sortedunivdata[iUniv].juni_race[racebangou][0] >= 10 &&
          sortedunivdata[iUniv].juni_race[racebangou][0] <= 19) {
        int zoukaryou =
            (50.toDouble() *
                    bairitu *
                    (1.0 / (sortedunivdata[iUniv].mokuhyojuni[racebangou] + 1)))
                .toInt();
        if (zoukaryou < 1) {
          zoukaryou = 1;
        }
        sortedunivdata[iUniv].meisei_yeargoto[0] += zoukaryou;
      }
      //区間賞名声加算
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        if (sortedunivdata[iUniv].kukanjuni_taikai[i_kukan] == 0) {
          sortedunivdata[iUniv].meisei_yeargoto[0] +=
              (2000.toDouble() * 0.2 * bairitu).toInt();
        }
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }
    // シード権、10月駅伝出場権
    for (var iUniv = 0; iUniv < sortedunivdata.length; iUniv++) {
      if (sortedunivdata[iUniv].juni_race[racebangou][0] < 10) {
        sortedunivdata[iUniv].taikaiseedflag[racebangou] = 1;
        /*sortedunivdata[iUniv].mokuhyojuni[racebangou] =
            sortedunivdata[iUniv].juni_race[racebangou][0] -
            (Random().nextInt(3) + 2); // 2...4
        if (sortedunivdata[iUniv].mokuhyojuni[racebangou] < 0) {
          sortedunivdata[iUniv].mokuhyojuni[racebangou] = 0;
        }*/
        /*if (sortedunivdata[iUniv].juni_race[0][0] <= 9) {
          //出場してるなら
          sortedunivdata[iUniv].mokuhyojuni[0] =
              sortedunivdata[iUniv].juni_race[0][0] -
              (Random().nextInt(3) + 2); // 2...4
          if (sortedunivdata[iUniv].mokuhyojuni[0] < 0) {
            sortedunivdata[iUniv].mokuhyojuni[0] = 0;
          }
          if (sortedunivdata[iUniv].mokuhyojuni[0] > 4) {
            sortedunivdata[iUniv].mokuhyojuni[0] = 4;
          }
        } else {
          sortedunivdata[iUniv].mokuhyojuni[0] = 4;
        }*/
      } else {
        sortedunivdata[iUniv].taikaiseedflag[racebangou] = 0;
        //sortedunivdata[iUniv].mokuhyojuni[4] = 9;
        //sortedunivdata[iUniv].mokuhyojuni[racebangou] = 9;
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }
  }

  if ((racebangou >= 0 && racebangou <= 2) || racebangou == 5) {
    // meisei_total更新
    for (var i = 0; i < sortedunivdata.length; i++) {
      sortedunivdata[i].meisei_total = 0;
      for (var ii = 0; ii < TEISUU.MEISEIHOZONNENSUU; ii++) {
        sortedunivdata[i].meisei_total += sortedunivdata[i].meisei_yeargoto[ii];
      }
      await sortedunivdata[i].save(); // UnivData の変更を保存
    }
    // 名声順位更新
    var meiseiJunUnivData = List<UnivData>.from(sortedunivdata)
      ..sort(
        (a, b) => (b.meisei_total * 100 + b.id).compareTo(
          a.meisei_total * 100 + a.id,
        ),
      );

    for (var i = 0; i < meiseiJunUnivData.length; i++) {
      meiseiJunUnivData[i].meiseijuni = i;
      await meiseiJunUnivData[i].save(); // UnivData の変更を保存
    }
  }

  if (racebangou == 3) {
    // 11月駅伝予選
    // 11月駅伝出場権
    for (var iUniv = 0; iUniv < sortedunivdata.length; iUniv++) {
      if (sortedunivdata[iUniv].juni_race[racebangou][0] < 7) {
        sortedunivdata[iUniv].taikaientryflag[1] = 1;
        if (gh[0].spurtryokuseichousisuu2 == 93 ||
            gh[0].spurtryokuseichousisuu2 == 2) {
          sortedunivdata[iUniv].mokuhyojuni[1] = 7;
        }
        if (gh[0].spurtryokuseichousisuu2 == 1) {
          sortedunivdata[iUniv].mokuhyojuni[1] =
              sortedunivdata[iUniv].juni_race[9][0];
          if (sortedunivdata[iUniv].mokuhyojuni[1] > 13) {
            sortedunivdata[iUniv].mokuhyojuni[1] = 13;
          }
        }
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }
  }

  if (racebangou == 4) {
    // 正月駅伝予選
    // 正月駅伝出場権
    for (var iUniv = 0; iUniv < sortedunivdata.length; iUniv++) {
      if (sortedunivdata[iUniv].juni_race[racebangou][0] < 10) {
        sortedunivdata[iUniv].taikaientryflag[2] = 1;
        if (gh[0].spurtryokuseichousisuu2 == 93 ||
            gh[0].spurtryokuseichousisuu2 == 2) {
          sortedunivdata[iUniv].mokuhyojuni[2] = 9;
        }
        if (gh[0].spurtryokuseichousisuu2 == 1) {
          sortedunivdata[iUniv].mokuhyojuni[2] =
              sortedunivdata[iUniv].juni_race[9][0];
          if (sortedunivdata[iUniv].mokuhyojuni[2] > 18) {
            sortedunivdata[iUniv].mokuhyojuni[2] = 18;
          }
        }
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }

    // 救済措置(今年度の三大駅伝すべて出れない、かつ、11月駅伝予選も正月駅伝予選も振るわなかった場合)
    if (kantoku.yobiint2[0] != 2) {
      if (sortedunivdata[gh[0].MYunivid].taikaientryflag[0] == 0 &&
          sortedunivdata[gh[0].MYunivid].taikaientryflag[1] == 0 &&
          sortedunivdata[gh[0].MYunivid].taikaientryflag[2] == 0 &&
          sortedunivdata[gh[0].MYunivid].juni_race[3][0] >= 15 &&
          sortedunivdata[gh[0].MYunivid].juni_race[4][0] >= 15) {
        if (Random().nextInt(100) < 100) {
          gh[0].last_goldenballkakutokusuu = 9;
          // gh[0].goldenballsuu += 0; // 0 を加算する意味がないため削除
          gh[0].last_silverballkakutokusuu = 9;
          gh[0].silverballsuu += 20 * kantoku.yobiint2[12];
        }
        await gh[0].save(); // gh[0] の変更を保存
      }
    }
  }

  if (racebangou == 4 ||
      racebangou == 3 ||
      (racebangou >= 6 && racebangou <= 8) ||
      (racebangou >= 10 && racebangou <= 17)) {
    //var timeInterval = stopwatch.elapsed;
    //print("KirokuKousin経過時間a: ${_timeToMinuteSecondString(timeInterval)}経過");

    // レース結果を代入
    if (racebangou != 3 && racebangou != 4) {
      for (int senshuid = 0; senshuid < TEISUU.SENSHUSUU_TOTAL; senshuid++) {
        // null safetyを考慮し、もし`sortedsenshudata[senshuid].gakunen - 1`が範囲外ならエラーハンドリングが必要
        if (sortedsenshudata[senshuid].gakunen - 1 >= 0 &&
            sortedsenshudata[senshuid].gakunen - 1 <
                sortedsenshudata[senshuid].kukantime_race[racebangou].length) {
          sortedsenshudata[senshuid]
              .kukantime_race[racebangou][sortedsenshudata[senshuid].gakunen -
              1] = sortedsenshudata[senshuid]
              .time_taikai_total;
          await sortedsenshudata[senshuid].save(); // Hiveに保存
        }
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
    List<SenshuData> entryFilteredSenshuData = sortedsenshudata
        .where(
          (senshu) =>
              senshu.entrykukan_race[racebangou][senshu.gakunen - 1] > -1,
        )
        .toList();

    // タイム順で並び替え
    List<SenshuData> kirokujunEntryFilteredSenshuData = entryFilteredSenshuData
        .toList() // 新しいリストを作成してソート
        .senshuSortByTime(); // 拡張メソッドでソート

    // 順位代入
    if (racebangou != 3 &&
        racebangou != 4 &&
        !(racebangou >= 13 && racebangou <= 16)) {
      for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
        sortedsenshudata[i]
                .kukanjuni_race[racebangou][sortedsenshudata[i].gakunen - 1] =
            TEISUU.DEFAULTJUNI;
        await sortedsenshudata[i].save(); // Hiveに保存
      }
      for (
        int jun_i = 0;
        jun_i < kirokujunEntryFilteredSenshuData.length;
        jun_i++
      ) {
        // null safetyを考慮し、もし`kirokujunEntryFilteredSenshuData[jun_i].gakunen - 1`が範囲外ならエラーハンドリングが必要
        if (kirokujunEntryFilteredSenshuData[jun_i].gakunen - 1 >= 0 &&
            kirokujunEntryFilteredSenshuData[jun_i].gakunen - 1 <
                kirokujunEntryFilteredSenshuData[jun_i]
                    .kukanjuni_race[racebangou]
                    .length) {
          kirokujunEntryFilteredSenshuData[jun_i]
                  .kukanjuni_race[racebangou][kirokujunEntryFilteredSenshuData[jun_i]
                      .gakunen -
                  1] =
              jun_i;
          await kirokujunEntryFilteredSenshuData[jun_i].save(); // Hiveに保存
        }
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
    // 夏のTTは学内順位を代入
    if (racebangou >= 13 && racebangou <= 16) {
      for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
        sortedsenshudata[i]
                .kukanjuni_race[racebangou][sortedsenshudata[i].gakunen - 1] =
            TEISUU.DEFAULTJUNI;
        await sortedsenshudata[i].save(); // Hiveに保存
      }
      for (var univ in sortedunivdata) {
        // 現在時刻と前回の休憩時刻を比較
        {
          final now = DateTime.now();
          if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
            // 3秒以上経過してたら
            await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
            Chousa.lastGapTime = DateTime.now();
          }
        }
        // タイム順で並び替え
        List<SenshuData> univFilteredkirokujunEntryFilteredSenshuData =
            entryFilteredSenshuData
                .where((senshu) => senshu.univid == univ.id)
                .toList() // 新しいリストを作成してソート
                .senshuSortByTime(); // 拡張メソッドでソート

        for (
          int jun_i = 0;
          jun_i < univFilteredkirokujunEntryFilteredSenshuData.length;
          jun_i++
        ) {
          // null safetyを考慮し、もし`univFilteredkirokujunEntryFilteredSenshuData[jun_i].gakunen - 1`が範囲外ならエラーハンドリングが必要
          if (univFilteredkirokujunEntryFilteredSenshuData[jun_i].gakunen - 1 >=
                  0 &&
              univFilteredkirokujunEntryFilteredSenshuData[jun_i].gakunen - 1 <
                  univFilteredkirokujunEntryFilteredSenshuData[jun_i]
                      .kukanjuni_race[racebangou]
                      .length) {
            univFilteredkirokujunEntryFilteredSenshuData[jun_i]
                    .kukanjuni_race[racebangou][univFilteredkirokujunEntryFilteredSenshuData[jun_i]
                        .gakunen -
                    1] =
                jun_i;
            await univFilteredkirokujunEntryFilteredSenshuData[jun_i]
                .save(); // Hiveに保存
          }
        }
      }
    }
    //timeInterval = stopwatch.elapsed;
    //debugPrint("KirokuKousin経過時間b: ${timeToFunByouString(timeInterval)}経過");

    int kirokubangou = 0;
    if (racebangou == 3) {
      kirokubangou = 1;
    }
    if (racebangou == 4) {
      kirokubangou = 2;
    }
    if (racebangou >= 10 && racebangou <= 12) {
      kirokubangou = racebangou - 10;
    }
    if (racebangou >= 13 && racebangou <= 16) {
      kirokubangou = racebangou - 9;
    }
    if (racebangou >= 6 && racebangou <= 8) {
      kirokubangou = racebangou - 6;
    }
    if (racebangou == 17) {
      kirokubangou = 3;
    }
    // 個人ベスト記録更新
    if (racebangou != 3 && racebangou != 4) {
      for (int i = 0; i < TEISUU.SENSHUSUU_TOTAL; i++) {
        if (sortedsenshudata[i]
                .entrykukan_race[racebangou][sortedsenshudata[i].gakunen - 1] >
            -1) {
          if (sortedsenshudata[i].time_bestkiroku[kirokubangou] >
              sortedsenshudata[i].time_taikai_total) {
            sortedsenshudata[i].time_bestkiroku[kirokubangou] =
                sortedsenshudata[i].time_taikai_total;
            sortedsenshudata[i].chokuzentaikai_pbflag = 1;
          }
          if (gh[0].time_zentaikojinkiroku[kirokubangou][0] >
              sortedsenshudata[i].time_taikai_total) {
            sortedsenshudata[i].chokuzentaikai_kojinrekidaisinflag = 1;
          }
          if (sortedsenshudata[i].univid == gh[0].MYunivid) {
            if (sortedunivdata[gh[0].MYunivid]
                    .time_univkojinkiroku[kirokubangou][0] >
                sortedsenshudata[i].time_taikai_total) {
              sortedsenshudata[i].chokuzentaikai_kojinunivsinflag = 1;
            }
          }
          await sortedsenshudata[i].save(); // Hiveに保存
        }
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
    //timeInterval = stopwatch.elapsed;
    //debugPrint("KirokuKousin経過時間c: ${timeToFunByouString(timeInterval)}経過");

    // 全体記録更新
    if (racebangou != 3 && racebangou != 4) {
      //日本人+留学生
      for (
        int i_kirokujun = 0;
        i_kirokujun < kirokujunEntryFilteredSenshuData.length;
        i_kirokujun++
      ) {
        if (gh[0].time_zentaikojinkiroku[kirokubangou][TEISUU
                    .SUU_BESTKIROKUHOZONJUNISUU -
                1] >
            kirokujunEntryFilteredSenshuData[i_kirokujun].time_taikai_total) {
          for (int i = 0; i < temp_kirokuhozonjunisuu; i++) {
            if (gh[0].time_zentaikojinkiroku[kirokubangou][i] >
                kirokujunEntryFilteredSenshuData[i_kirokujun]
                    .time_taikai_total) {
              // ずらす
              if (i < temp_kirokuhozonjunisuu - 1) {
                for (int ii = temp_kirokuhozonjunisuu - 1; ii > i; ii--) {
                  gh[0].time_zentaikojinkiroku[kirokubangou][ii] =
                      gh[0].time_zentaikojinkiroku[kirokubangou][ii - 1];
                  gh[0].year_zentaikojinkiroku[kirokubangou][ii] =
                      gh[0].year_zentaikojinkiroku[kirokubangou][ii - 1];
                  gh[0].month_zentaikojinkiroku[kirokubangou][ii] =
                      gh[0].month_zentaikojinkiroku[kirokubangou][ii - 1];
                  gh[0].univname_zentaikojinkiroku[kirokubangou][ii] =
                      gh[0].univname_zentaikojinkiroku[kirokubangou][ii - 1];
                  gh[0].name_zentaikojinkiroku[kirokubangou][ii] =
                      gh[0].name_zentaikojinkiroku[kirokubangou][ii - 1];
                  gh[0].gakunen_zentaikojinkiroku[kirokubangou][ii] =
                      gh[0].gakunen_zentaikojinkiroku[kirokubangou][ii - 1];
                }
              }
              // 代入
              gh[0].time_zentaikojinkiroku[kirokubangou][i] =
                  kirokujunEntryFilteredSenshuData[i_kirokujun]
                      .time_taikai_total;
              gh[0].year_zentaikojinkiroku[kirokubangou][i] = gh[0].year;
              gh[0].month_zentaikojinkiroku[kirokubangou][i] = gh[0].month;
              gh[0].univname_zentaikojinkiroku[kirokubangou][i] =
                  sortedunivdata[kirokujunEntryFilteredSenshuData[i_kirokujun]
                          .univid]
                      .name;
              gh[0].name_zentaikojinkiroku[kirokubangou][i] =
                  kirokujunEntryFilteredSenshuData[i_kirokujun].name;
              gh[0].gakunen_zentaikojinkiroku[kirokubangou][i] =
                  kirokujunEntryFilteredSenshuData[i_kirokujun].gakunen;
              await gh[0].save(); // Hiveに保存
              break;
            }
          }
        } else {
          break;
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
      //留学生
      for (
        int i_kirokujun = 0;
        i_kirokujun < kirokujunEntryFilteredSenshuData.length;
        i_kirokujun++
      ) {
        if (kirokujunEntryFilteredSenshuData[i_kirokujun].hirou == 1) {
          if (kiroku!.time_zentai_ryuugakusei_kojinkiroku[kirokubangou][TEISUU
                      .SUU_BESTKIROKUHOZONJUNISUU -
                  1] >
              kirokujunEntryFilteredSenshuData[i_kirokujun].time_taikai_total) {
            for (int i = 0; i < temp_kirokuhozonjunisuu; i++) {
              if (kiroku.time_zentai_ryuugakusei_kojinkiroku[kirokubangou][i] >
                  kirokujunEntryFilteredSenshuData[i_kirokujun]
                      .time_taikai_total) {
                // ずらす
                if (i < temp_kirokuhozonjunisuu - 1) {
                  for (int ii = temp_kirokuhozonjunisuu - 1; ii > i; ii--) {}
                }
                // 代入
                kiroku.time_zentai_ryuugakusei_kojinkiroku[kirokubangou][i] =
                    kirokujunEntryFilteredSenshuData[i_kirokujun]
                        .time_taikai_total;
                kiroku.year_zentai_ryuugakusei_kojinkiroku[kirokubangou][i] =
                    gh[0].year;
                kiroku.month_zentai_ryuugakusei_kojinkiroku[kirokubangou][i] =
                    gh[0].month;
                kiroku.univname_zentai_ryuugakusei_kojinkiroku[kirokubangou][i] =
                    sortedunivdata[kirokujunEntryFilteredSenshuData[i_kirokujun]
                            .univid]
                        .name;
                kiroku.name_zentai_ryuugakusei_kojinkiroku[kirokubangou][i] =
                    kirokujunEntryFilteredSenshuData[i_kirokujun].name;
                kiroku.gakunen_zentai_ryuugakusei_kojinkiroku[kirokubangou][i] =
                    kirokujunEntryFilteredSenshuData[i_kirokujun].gakunen;
                await kiroku.save(); // Hiveに保存
                break;
              }
            }
          } else {
            break;
          }
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
      //日本人
      for (
        int i_kirokujun = 0;
        i_kirokujun < kirokujunEntryFilteredSenshuData.length;
        i_kirokujun++
      ) {
        if (kirokujunEntryFilteredSenshuData[i_kirokujun].hirou != 1) {
          if (kiroku!.time_zentai_jap_kojinkiroku[kirokubangou][TEISUU
                      .SUU_BESTKIROKUHOZONJUNISUU -
                  1] >
              kirokujunEntryFilteredSenshuData[i_kirokujun].time_taikai_total) {
            for (int i = 0; i < temp_kirokuhozonjunisuu; i++) {
              if (kiroku.time_zentai_jap_kojinkiroku[kirokubangou][i] >
                  kirokujunEntryFilteredSenshuData[i_kirokujun]
                      .time_taikai_total) {
                // ずらす
                if (i < temp_kirokuhozonjunisuu - 1) {
                  for (int ii = temp_kirokuhozonjunisuu - 1; ii > i; ii--) {}
                }
                // 代入
                kiroku.time_zentai_jap_kojinkiroku[kirokubangou][i] =
                    kirokujunEntryFilteredSenshuData[i_kirokujun]
                        .time_taikai_total;
                kiroku.year_zentai_jap_kojinkiroku[kirokubangou][i] =
                    gh[0].year;
                kiroku.month_zentai_jap_kojinkiroku[kirokubangou][i] =
                    gh[0].month;
                kiroku.univname_zentai_jap_kojinkiroku[kirokubangou][i] =
                    sortedunivdata[kirokujunEntryFilteredSenshuData[i_kirokujun]
                            .univid]
                        .name;
                kiroku.name_zentai_jap_kojinkiroku[kirokubangou][i] =
                    kirokujunEntryFilteredSenshuData[i_kirokujun].name;
                kiroku.gakunen_zentai_jap_kojinkiroku[kirokubangou][i] =
                    kirokujunEntryFilteredSenshuData[i_kirokujun].gakunen;
                await kiroku.save(); // Hiveに保存
                break;
              }
            }
          } else {
            break;
          }
        }
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
    //timeInterval = stopwatch.elapsed;
    //debugPrint("KirokuKousin経過時間d: ${timeToFunByouString(timeInterval)}経過");

    // 学内記録更新
    if (racebangou != 3 && racebangou != 4) {
      List<SenshuData> univEntryFilteredSenshuData = entryFilteredSenshuData
          .where((senshu) => senshu.univid == gh[0].MYunivid)
          .toList();

      List<SenshuData> kirokujunUnivEntryFilteredSenshuData =
          univEntryFilteredSenshuData.senshuSortByTime(); // 拡張メソッドでソート
      //留学生+日本人
      for (
        int i_kirokujun = 0;
        i_kirokujun < kirokujunUnivEntryFilteredSenshuData.length;
        i_kirokujun++
      ) {
        final currentUnivId =
            kirokujunUnivEntryFilteredSenshuData[i_kirokujun].univid;
        if (currentUnivId >= sortedunivdata.length) {
          print(
            'Error: currentUnivId $currentUnivId out of bounds for sortedUnivData. Length: ${sortedunivdata.length}',
          );
          continue;
        }

        if (sortedunivdata[currentUnivId]
                .time_univkojinkiroku[kirokubangou][TEISUU
                    .SUU_BESTKIROKUHOZONJUNISUU -
                1] >
            kirokujunUnivEntryFilteredSenshuData[i_kirokujun]
                .time_taikai_total) {
          for (int i = 0; i < temp_kirokuhozonjunisuu; i++) {
            if (sortedunivdata[currentUnivId]
                    .time_univkojinkiroku[kirokubangou][i] >
                kirokujunUnivEntryFilteredSenshuData[i_kirokujun]
                    .time_taikai_total) {
              // ずらす
              if (i < temp_kirokuhozonjunisuu - 1) {
                for (int ii = temp_kirokuhozonjunisuu - 1; ii > i; ii--) {
                  sortedunivdata[currentUnivId]
                          .time_univkojinkiroku[kirokubangou][ii] =
                      sortedunivdata[currentUnivId]
                          .time_univkojinkiroku[kirokubangou][ii - 1];
                  sortedunivdata[currentUnivId]
                          .year_univkojinkiroku[kirokubangou][ii] =
                      sortedunivdata[currentUnivId]
                          .year_univkojinkiroku[kirokubangou][ii - 1];
                  sortedunivdata[currentUnivId]
                          .month_univkojinkiroku[kirokubangou][ii] =
                      sortedunivdata[currentUnivId]
                          .month_univkojinkiroku[kirokubangou][ii - 1];
                  sortedunivdata[currentUnivId]
                          .name_univkojinkiroku[kirokubangou][ii] =
                      sortedunivdata[currentUnivId]
                          .name_univkojinkiroku[kirokubangou][ii - 1];
                  sortedunivdata[currentUnivId]
                          .gakunen_univkojinkiroku[kirokubangou][ii] =
                      sortedunivdata[currentUnivId]
                          .gakunen_univkojinkiroku[kirokubangou][ii - 1];
                }
              }
              // 代入
              sortedunivdata[currentUnivId]
                      .time_univkojinkiroku[kirokubangou][i] =
                  kirokujunUnivEntryFilteredSenshuData[i_kirokujun]
                      .time_taikai_total;
              sortedunivdata[currentUnivId]
                      .year_univkojinkiroku[kirokubangou][i] =
                  gh[0].year;
              sortedunivdata[currentUnivId]
                      .month_univkojinkiroku[kirokubangou][i] =
                  gh[0].month;
              sortedunivdata[currentUnivId]
                      .name_univkojinkiroku[kirokubangou][i] =
                  kirokujunUnivEntryFilteredSenshuData[i_kirokujun].name;
              sortedunivdata[currentUnivId]
                      .gakunen_univkojinkiroku[kirokubangou][i] =
                  kirokujunUnivEntryFilteredSenshuData[i_kirokujun].gakunen;
              await sortedunivdata[currentUnivId].save(); // Hiveに保存
              break;
            }
          }
        } else {
          break;
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
      //留学生のみ
      for (
        int i_kirokujun = 0;
        i_kirokujun < kirokujunUnivEntryFilteredSenshuData.length;
        i_kirokujun++
      ) {
        final currentUnivId =
            kirokujunUnivEntryFilteredSenshuData[i_kirokujun].univid;
        if (currentUnivId >= sortedunivdata.length) {
          print(
            'Error: currentUnivId $currentUnivId out of bounds for sortedUnivData. Length: ${sortedunivdata.length}',
          );
          continue;
        }
        if (kirokujunUnivEntryFilteredSenshuData[i_kirokujun].hirou == 1) {
          if (kiroku!
                  .time_univ_ryuugakusei_kojinkiroku[currentUnivId][kirokubangou][TEISUU
                      .SUU_BESTKIROKUHOZONJUNISUU -
                  1] >
              kirokujunUnivEntryFilteredSenshuData[i_kirokujun]
                  .time_taikai_total) {
            for (int i = 0; i < temp_kirokuhozonjunisuu; i++) {
              if (kiroku
                      .time_univ_ryuugakusei_kojinkiroku[currentUnivId][kirokubangou][i] >
                  kirokujunUnivEntryFilteredSenshuData[i_kirokujun]
                      .time_taikai_total) {
                // ずらす
                if (i < temp_kirokuhozonjunisuu - 1) {
                  for (int ii = temp_kirokuhozonjunisuu - 1; ii > i; ii--) {}
                }
                // 代入
                kiroku.time_univ_ryuugakusei_kojinkiroku[currentUnivId][kirokubangou][i] =
                    kirokujunUnivEntryFilteredSenshuData[i_kirokujun]
                        .time_taikai_total;
                kiroku.year_univ_ryuugakusei_kojinkiroku[currentUnivId][kirokubangou][i] =
                    gh[0].year;
                kiroku.month_univ_ryuugakusei_kojinkiroku[currentUnivId][kirokubangou][i] =
                    gh[0].month;
                kiroku.name_univ_ryuugakusei_kojinkiroku[currentUnivId][kirokubangou][i] =
                    kirokujunUnivEntryFilteredSenshuData[i_kirokujun].name;
                kiroku.gakunen_univ_ryuugakusei_kojinkiroku[currentUnivId][kirokubangou][i] =
                    kirokujunUnivEntryFilteredSenshuData[i_kirokujun].gakunen;
                await kiroku.save(); // Hiveに保存
                break;
              }
            }
          } else {
            break;
          }
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
      //日本人のみ
      for (
        int i_kirokujun = 0;
        i_kirokujun < kirokujunUnivEntryFilteredSenshuData.length;
        i_kirokujun++
      ) {
        final currentUnivId =
            kirokujunUnivEntryFilteredSenshuData[i_kirokujun].univid;
        if (currentUnivId >= sortedunivdata.length) {
          print(
            'Error: currentUnivId $currentUnivId out of bounds for sortedUnivData. Length: ${sortedunivdata.length}',
          );
          continue;
        }
        if (kirokujunUnivEntryFilteredSenshuData[i_kirokujun].hirou != 1) {
          if (kiroku!
                  .time_univ_jap_kojinkiroku[currentUnivId][kirokubangou][TEISUU
                      .SUU_BESTKIROKUHOZONJUNISUU -
                  1] >
              kirokujunUnivEntryFilteredSenshuData[i_kirokujun]
                  .time_taikai_total) {
            for (int i = 0; i < temp_kirokuhozonjunisuu; i++) {
              if (kiroku
                      .time_univ_jap_kojinkiroku[currentUnivId][kirokubangou][i] >
                  kirokujunUnivEntryFilteredSenshuData[i_kirokujun]
                      .time_taikai_total) {
                // ずらす
                if (i < temp_kirokuhozonjunisuu - 1) {
                  for (int ii = temp_kirokuhozonjunisuu - 1; ii > i; ii--) {}
                }
                // 代入
                kiroku.time_univ_jap_kojinkiroku[currentUnivId][kirokubangou][i] =
                    kirokujunUnivEntryFilteredSenshuData[i_kirokujun]
                        .time_taikai_total;
                kiroku.year_univ_jap_kojinkiroku[currentUnivId][kirokubangou][i] =
                    gh[0].year;
                kiroku.month_univ_jap_kojinkiroku[currentUnivId][kirokubangou][i] =
                    gh[0].month;
                kiroku.name_univ_jap_kojinkiroku[currentUnivId][kirokubangou][i] =
                    kirokujunUnivEntryFilteredSenshuData[i_kirokujun].name;
                kiroku.gakunen_univ_jap_kojinkiroku[currentUnivId][kirokubangou][i] =
                    kirokujunUnivEntryFilteredSenshuData[i_kirokujun].gakunen;
                await kiroku.save(); // Hiveに保存
                break;
              }
            }
          } else {
            break;
          }
        }
      }
    }

    //timeInterval = stopwatch.elapsed;
    //debugPrint("KirokuKousin経過時間e: ${timeToFunByouString(timeInterval)}経過");

    if (racebangou >= 6 && racebangou <= 8) {
      // インカレポイント
      if (racebangou == 6) {
        for (int i = 0; i < TEISUU.UNIVSUU; i++) {
          for (int ii = 0; ii < 3; ii++) {
            sortedunivdata[i].inkarepoint[ii] = 0;
            await sortedunivdata[i].save(); // Hiveに保存
          }
        }
      }
      for (int i = 0; i < kirokujunEntryFilteredSenshuData.length; i++) {
        final currentUnivId = kirokujunEntryFilteredSenshuData[i].univid;
        if (currentUnivId >= sortedunivdata.length ||
            racebangou - 6 < 0 ||
            racebangou - 6 >=
                sortedunivdata[currentUnivId].inkarepoint.length) {
          print(
            'Error: Index out of bounds for inkarepoint for univid $currentUnivId, racebangou ${racebangou - 6}',
          );
          continue;
        }
        sortedunivdata[currentUnivId].inkarepoint[racebangou - 6] +=
            kirokujunEntryFilteredSenshuData.length - i; // Swiftコードに合わせて[0]を追加
        await sortedunivdata[currentUnivId].save(); // Hiveに保存
      }

      // 上位入賞者への名声ポイント加算
      if (kirokujunEntryFilteredSenshuData.isNotEmpty) {
        final List<int> meiseiPoints = [100, 50, 40, 18, 16, 14, 12, 10];
        for (
          int i = 0;
          i < meiseiPoints.length &&
              i < kirokujunEntryFilteredSenshuData.length;
          i++
        ) {
          final univId = kirokujunEntryFilteredSenshuData[i].univid;
          if (univId >= 0 && univId < sortedunivdata.length) {
            sortedunivdata[univId].meisei_yeargoto[0] += meiseiPoints[i];
            await sortedunivdata[univId].save();
          }
        }
      }

      // 同点の場合は抽選で順位決定することも加味してポイント順で並べ替え
      /*for (int i = 0; i < sortedunivdata.length; i++) {
        //sortedunivdata[i].r =
        //    (DateTime.now().microsecondsSinceEpoch % 100000); // 0-99999のランダム値
        sortedunivdata[i].r = random.nextInt(100000);
        sortedunivdata[i].save(); // Hiveに保存
      }*/

      List<UnivData> inkarepointTotalJunUnivData = sortedunivdata
          .toList(); // 新しいリストを作成してソート
      inkarepointTotalJunUnivData.sort((a, b) {
        // inkarepoint が List<int> なので、そのリスト全体の合計値を計算する
        // fold を使って合計（初期値 0 を指定）
        final totalPointA = a.inkarepoint.fold(
          0,
          (sum, element) => sum + element,
        );
        final totalPointB = b.inkarepoint.fold(
          0,
          (sum, element) => sum + element,
        );

        if (totalPointA == totalPointB) {
          //return b.r.compareTo(a.r);
          return random.nextInt(2) == 0 ? -1 : 1;
        } else {
          return totalPointB.compareTo(totalPointA);
        }
      });

      // 順位代入
      if (racebangou == 6) {
        for (int i = 0; i < inkarepointTotalJunUnivData.length; i++) {
          // Swiftのstride(from:to:by:)はtoを含まないので、Dartでは `> i_zurasi` となる
          for (
            int i_zurasi = TEISUU.KIROKUHOZONNENSUU - 1;
            i_zurasi > 0;
            i_zurasi--
          ) {
            if (inkarepointTotalJunUnivData[i].juni_race[9].length > i_zurasi &&
                inkarepointTotalJunUnivData[i].juni_race[9].length >
                    i_zurasi - 1) {
              // 範囲チェック
              inkarepointTotalJunUnivData[i].juni_race[9][i_zurasi] =
                  inkarepointTotalJunUnivData[i].juni_race[9][i_zurasi - 1];
            } else {
              print(
                'Warning: juni_race index out of bounds during shift for UnivData ${inkarepointTotalJunUnivData[i].name}',
              );
            }
          }
          await inkarepointTotalJunUnivData[i].save(); // Hiveに保存
        }
      }

      if (racebangou != 8) {
        for (int i = 0; i < inkarepointTotalJunUnivData.length; i++) {
          if (inkarepointTotalJunUnivData[i].juni_race[9].isNotEmpty) {
            // 範囲チェック
            inkarepointTotalJunUnivData[i].juni_race[9][0] = i;
            await inkarepointTotalJunUnivData[i].save(); // Hiveに保存
          }
        }
      }

      if (racebangou == 8) {
        for (int i = 0; i < inkarepointTotalJunUnivData.length; i++) {
          if (inkarepointTotalJunUnivData[i].juni_race[9].isNotEmpty) {
            // 範囲チェック
            inkarepointTotalJunUnivData[i].juni_race[9][0] = i;
            inkarepointTotalJunUnivData[i].taikaibetushutujoukaisuu[9] += 1;
            inkarepointTotalJunUnivData[i].taikaibetujunibetukaisuu[9][i] += 1;
            if (inkarepointTotalJunUnivData[i].taikaibetusaikoujuni[9] >
                inkarepointTotalJunUnivData[i].juni_race[9][0]) {
              inkarepointTotalJunUnivData[i].taikaibetusaikoujuni[9] =
                  inkarepointTotalJunUnivData[i].juni_race[9][0];
            }
            await inkarepointTotalJunUnivData[i].save(); // Hiveに保存
          }
        }
        // 上位入賞大学への名声ポイント加算
        final List<int> meiseiPointsOverall = [
          1000,
          500,
          400,
          180,
          160,
          140,
          120,
          100,
        ];
        for (
          int i = 0;
          i < meiseiPointsOverall.length &&
              i < inkarepointTotalJunUnivData.length;
          i++
        ) {
          if (inkarepointTotalJunUnivData[i].meisei_yeargoto.isNotEmpty) {
            inkarepointTotalJunUnivData[i].meisei_yeargoto[0] +=
                meiseiPointsOverall[i];
            await inkarepointTotalJunUnivData[i].save();
          }
        }

        /*print(
          "自分の大学の対校戦総合目標順位: ${sortedunivdata[gh[0].MYunivid].mokuhyojuni[9] + 1}位",
        );
        print(
          "自分の大学は対校戦総合で: ${sortedunivdata[gh[0].MYunivid].juni_race[9][0] + 1}位",
        );*/

        // 目標順位達成の場合のご褒美
        kantoku.yobiint2[1] = 0;
        await kantoku.save();
        if (sortedunivdata[gh[0].MYunivid].juni_race[9][0] <=
            sortedunivdata[gh[0].MYunivid].mokuhyojuni[9]) {
          kantoku.yobiint2[1] = 1;
          await kantoku.save();
          if (kantoku.yobiint2[0] == 0) {
            int r = 0;
            int rYuushou = 0;
            if (gh[0].kazeflag == 0) {
              r = 30;
              rYuushou = 50;
            }
            if (gh[0].kazeflag == 1) {
              r = 50;
              rYuushou = 100;
            }
            if (gh[0].kazeflag == 2) {
              r = 100;
              rYuushou = 200;
            }
            if (gh[0].kazeflag == 3) {
              r = 200;
              rYuushou = 300;
            }

            if (random.nextInt(100) < 10) {
              // 20%の確率
              if (random.nextInt(100) < 0) {
                // 常にfalse
                r = 100;
                gh[0].last_goldenballkakutokusuu = 1;
              } else if (sortedunivdata[gh[0].MYunivid].juni_race[9][0] == 0) {
                r = rYuushou;
                gh[0].last_goldenballkakutokusuu = r * kantoku.yobiint2[12];
              } else {
                gh[0].last_goldenballkakutokusuu = r * kantoku.yobiint2[12];
              }
              gh[0].goldenballsuu += r * kantoku.yobiint2[12];
            } else {
              if (random.nextInt(100) < 0) {
                // 常にfalse
                r = 100;
                gh[0].last_silverballkakutokusuu = 1;
              } else if (sortedunivdata[gh[0].MYunivid].juni_race[9][0] == 0) {
                r = rYuushou;
                gh[0].last_silverballkakutokusuu = r * kantoku.yobiint2[12];
              } else {
                gh[0].last_silverballkakutokusuu = r * kantoku.yobiint2[12];
              }
              gh[0].silverballsuu += r * kantoku.yobiint2[12];
            }

            if (gh[0].goldenballsuu > 9999) {
              gh[0].goldenballsuu = 9999;
            }
            if (gh[0].silverballsuu > 9999) {
              gh[0].silverballsuu = 9999;
            }
            await gh[0].save(); // Hiveに保存
          }
        }
      }

      // meisei_total更新
      for (int i = 0; i < sortedunivdata.length; i++) {
        sortedunivdata[i].meisei_total = 0;
        for (int ii = 0; ii < TEISUU.MEISEIHOZONNENSUU; ii++) {
          if (ii < sortedunivdata[i].meisei_yeargoto.length) {
            // 範囲チェック
            sortedunivdata[i].meisei_total +=
                sortedunivdata[i].meisei_yeargoto[ii];
          }
        }
        await sortedunivdata[i].save(); // Hiveに保存
      }

      // 名声順位更新
      List<UnivData> meiseijunUnivData = sortedunivdata
          .toList(); // 新しいリストを作成してソート
      meiseijunUnivData.sort((a, b) {
        final scoreA = a.meisei_total * 100 + a.id; // idは仮にHiveのkeyを使用
        final scoreB = b.meisei_total * 100 + b.id; // idは仮にHiveのkeyを使用
        return scoreB.compareTo(scoreA);
      });

      for (int i = 0; i < meiseijunUnivData.length; i++) {
        meiseijunUnivData[i].meiseijuni = i;
        await meiseijunUnivData[i].save(); // Hiveに保存
      }
    }

    //timeInterval = stopwatch.elapsed;
    //debugPrint("KirokuKousin経過時間f: ${timeToFunByouString(timeInterval)}経過");
    // 現在時刻と前回の休憩時刻を比較
    {
      final now = DateTime.now();
      if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
        // 3秒以上経過してたら
        await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
        Chousa.lastGapTime = DateTime.now();
      }
    }
    // 個人ベスト記録の全体順位・学内順位更新
    // `kojinbestkirokujunikettei` 関数は別途定義が必要
    kojinBestKirokuJuniKettei(kirokubangou, gh, sortedsenshudata);
    for (int i = 0; i < sortedsenshudata.length; i++) {
      await sortedsenshudata[i].save();
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
    await updateAllSenshuChartdata_atusataisei();
    await refreshAllUnivAnalysisData();
    //timeInterval = stopwatch.elapsed;
    //debugPrint("KirokuKousin経過時間g: ${timeToFunByouString(timeInterval)}経過");
  }

  if (racebangou == 9) {
    // ここにracebangouが9の場合の処理
  }

  /////わざと一旦閉じる
  //var open_rsenshubox = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');

  /////
  //駅伝の場合の監督実績記録
  sortedunivdata[10].name_tanshuku = "";
  await sortedunivdata[10].save();
  if (racebangou <= 2 || racebangou == 5) {
    //String motostr = sortedunivdata[8].name_tanshuku;
    String tempstr = "";
    //String tempstr2 = "";
    String eventname = "";
    if (racebangou == 0) eventname = "10月駅伝";
    if (racebangou == 1) eventname = "11月駅伝";
    if (racebangou == 2) eventname = "正月駅伝";
    if (racebangou == 5) eventname = sortedunivdata[0].name_tanshuku;
    tempstr += "#${gh[0].year}年${gh[0].month}月 ${eventname}\n";
    if (racebangou == 5 ||
        sortedunivdata[gh[0].MYunivid].taikaientryflag[racebangou] == 1) {
      tempstr += "${sortedunivdata[gh[0].MYunivid].name}大学の結果\n";
      tempstr += "------\n";
      tempstr +=
          "総合 ${sortedunivdata[gh[0].MYunivid].juni_race[racebangou][0] + 1}位 ${TimeDate.timeToJikanFunByouString(sortedunivdata[gh[0].MYunivid].time_race[racebangou][0])}\n";
      if (sortedunivdata[gh[0].MYunivid].chokuzentaikai_zentaitaikaisinflag ==
          1) {
        tempstr += "※大会新\n";
      } else if (sortedunivdata[gh[0].MYunivid]
              .chokuzentaikai_univtaikaisinflag ==
          1) {
        tempstr += "※学内新\n";
      }
      tempstr += "------\n";
      var FilteredSenshuData = sortedsenshudata
          .where(
            (s) =>
                s.entrykukan_race[racebangou][s.gakunen - 1] > -1 &&
                s.univid == gh[0].MYunivid,
          )
          .toList();
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        for (var senshu in FilteredSenshuData) {
          if (senshu.entrykukan_race[racebangou][senshu.gakunen - 1] ==
              i_kukan) {
            tempstr += "◆${i_kukan + 1}区 ${senshu.name} ${senshu.gakunen}年\n";
            tempstr +=
                "区間${senshu.kukanjuni_race[racebangou][senshu.gakunen - 1] + 1}位 ${TimeDate.timeToFunByouString(senshu.kukantime_race[racebangou][senshu.gakunen - 1])} ${sortedunivdata[gh[0].MYunivid].tuukajuni_taikai[i_kukan] + 1}位通過\n";
            if (senshu.chokuzentaikai_zentaikukansinflag == 1) {
              tempstr += "※区間新\n";
            } else if (senshu.chokuzentaikai_univkukansinflag == 1) {
              tempstr += "※学内新\n";
            }
            tempstr += "------\n";
          }
        }
      }
    } else {
      tempstr += "${sortedunivdata[gh[0].MYunivid].name}大学は不出場\n";
    }
    sortedunivdata[10].name_tanshuku = tempstr; //駅伝結果要約表示用
    await sortedunivdata[10].save();
    tempstr += "\n\n";
    //sortedunivdata[8].name_tanshuku = tempstr + motostr;
    sortedunivdata[8].name_tanshuku = tempstr + sortedunivdata[8].name_tanshuku;
    await sortedunivdata[8].save();
  }
  //11月駅伝予選の場合の監督実績記録
  if (racebangou == 3) {
    //String motostr = sortedunivdata[8].name_tanshuku;
    String tempstr = "";
    //String tempstr2 = "";
    String eventname = "11月駅伝予選";
    tempstr += "#${gh[0].year}年${gh[0].month}月 ${eventname}\n";
    if (sortedunivdata[gh[0].MYunivid].taikaientryflag[racebangou] == 1) {
      tempstr += "${sortedunivdata[gh[0].MYunivid].name}大学の結果\n";
      tempstr += "------\n";
      tempstr +=
          "総合 ${sortedunivdata[gh[0].MYunivid].juni_race[racebangou][0] + 1}位 ${TimeDate.timeToJikanFunByouString(sortedunivdata[gh[0].MYunivid].time_race[racebangou][0])}\n";
      tempstr += "------\n";
      var FilteredSenshuData = sortedsenshudata
          .where(
            (s) =>
                s.entrykukan_race[racebangou][s.gakunen - 1] > -1 &&
                s.univid == gh[0].MYunivid,
          )
          .toList();
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        tempstr +=
            "◆${i_kukan + 1}組目終了時点 ${sortedunivdata[gh[0].MYunivid].tuukajuni_taikai[i_kukan] + 1}位\n";
        for (var senshu in FilteredSenshuData) {
          if (senshu.entrykukan_race[racebangou][senshu.gakunen - 1] ==
              i_kukan) {
            tempstr += "${i_kukan + 1}組目 ${senshu.name} ${senshu.gakunen}年\n";

            tempstr +=
                "個人${senshu.kukanjuni_race[racebangou][senshu.gakunen - 1] + 1}位 ${TimeDate.timeToFunByouString(senshu.kukantime_race[racebangou][senshu.gakunen - 1])}\n";
            tempstr += "------\n";
          }
        }
      }
    } else {
      tempstr += "${sortedunivdata[gh[0].MYunivid].name}大学は不出場\n";
    }
    sortedunivdata[10].name_tanshuku = tempstr; //駅伝結果要約表示用
    await sortedunivdata[10].save();
    tempstr += "\n\n";
    //sortedunivdata[8].name_tanshuku = tempstr + motostr;
    sortedunivdata[8].name_tanshuku = tempstr + sortedunivdata[8].name_tanshuku;
    await sortedunivdata[8].save();
  }
  //正月駅伝予選の場合の監督実績記録
  if (racebangou == 4) {
    //String motostr = sortedunivdata[8].name_tanshuku;
    String tempstr = "";
    String eventname = "正月駅伝予選";
    tempstr += "#${gh[0].year}年${gh[0].month}月 ${eventname}\n";
    if (sortedunivdata[gh[0].MYunivid].taikaientryflag[racebangou] == 1) {
      tempstr += "${sortedunivdata[gh[0].MYunivid].name}大学の結果\n";
      tempstr +=
          "総合 ${sortedunivdata[gh[0].MYunivid].juni_race[racebangou][0] + 1}位 ${TimeDate.timeToJikanFunByouString(sortedunivdata[gh[0].MYunivid].time_race[racebangou][0])}\n";
      var FilteredSenshuData = sortedsenshudata
          .where(
            (s) =>
                s.entrykukan_race[racebangou][s.gakunen - 1] > -1 &&
                s.univid == gh[0].MYunivid,
          )
          .toList();
      FilteredSenshuData.sort((a, b) {
        return a.kukantime_race[racebangou][a.gakunen - 1].compareTo(
          b.kukantime_race[racebangou][b.gakunen - 1],
        );
      });
      int i_kukan = 0;
      for (int i_senshu = 0; i_senshu < FilteredSenshuData.length; i_senshu++) {
        var senshu = FilteredSenshuData[i_senshu];
        if (senshu.entrykukan_race[racebangou][senshu.gakunen - 1] == i_kukan) {
          tempstr +=
              "${senshu.kukanjuni_race[racebangou][senshu.gakunen - 1] + 1}位 ${senshu.name}(${senshu.gakunen}) ${TimeDate.timeToFunByouString(senshu.kukantime_race[racebangou][senshu.gakunen - 1])}\n";
        }
      }
    } else {
      tempstr += "${sortedunivdata[gh[0].MYunivid].name}大学は不出場\n";
    }
    tempstr += "\n\n";
    //sortedunivdata[8].name_tanshuku = tempstr + motostr;
    sortedunivdata[8].name_tanshuku = tempstr + sortedunivdata[8].name_tanshuku;
    await sortedunivdata[8].save();
  }
  //対校戦5000m・10000m・ハーフの場合の監督実績記録
  if (racebangou >= 6 && racebangou <= 8) {
    //String motostr = sortedunivdata[8].name_tanshuku;
    String tempstr = "";
    String eventname = "";
    if (racebangou == 6) eventname = "対校戦5000m";
    if (racebangou == 7) eventname = "対校戦10000m";
    if (racebangou == 8) eventname = "対校戦ハーフマラソン";
    tempstr += "#${gh[0].year}年${gh[0].month}月 ${eventname}\n";
    tempstr += "${sortedunivdata[gh[0].MYunivid].name}大学の結果\n";
    var FilteredSenshuData = sortedsenshudata
        .where(
          (s) =>
              s.entrykukan_race[racebangou][s.gakunen - 1] > -1 &&
              s.univid == gh[0].MYunivid,
        )
        .toList();
    FilteredSenshuData.sort((a, b) {
      return a.kukantime_race[racebangou][a.gakunen - 1].compareTo(
        b.kukantime_race[racebangou][b.gakunen - 1],
      );
    });
    int i_kukan = 0;
    for (int i_senshu = 0; i_senshu < FilteredSenshuData.length; i_senshu++) {
      var senshu = FilteredSenshuData[i_senshu];
      if (senshu.entrykukan_race[racebangou][senshu.gakunen - 1] == i_kukan) {
        tempstr +=
            "${senshu.kukanjuni_race[racebangou][senshu.gakunen - 1] + 1}位 ${senshu.name}(${senshu.gakunen}) ${TimeDate.timeToFunByouString(senshu.kukantime_race[racebangou][senshu.gakunen - 1])}\n";
      }
    }
    tempstr += "\n\n";
    //sortedunivdata[8].name_tanshuku = tempstr + motostr;
    sortedunivdata[8].name_tanshuku = tempstr + sortedunivdata[8].name_tanshuku;
    await sortedunivdata[8].save();
  }
  //対校戦総合順位の監督実績記録
  if (racebangou == 8) {
    //String motostr = sortedunivdata[8].name_tanshuku;
    String tempstr = "";
    String eventname = "対校戦総合";
    tempstr += "#${gh[0].year}年${gh[0].month}月 ${eventname}\n";
    tempstr += "${sortedunivdata[gh[0].MYunivid].name}大学の結果\n";
    tempstr += "総合 ${sortedunivdata[gh[0].MYunivid].juni_race[9][0] + 1}位\n";
    tempstr += "\n\n";
    //sortedunivdata[8].name_tanshuku = tempstr + motostr;
    sortedunivdata[8].name_tanshuku = tempstr + sortedunivdata[8].name_tanshuku;
    await sortedunivdata[8].save();
  }
  /////
  // 現在時刻と前回の休憩時刻を比較
  {
    final now = DateTime.now();
    if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
      // 3秒以上経過してたら
      await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
      Chousa.lastGapTime = DateTime.now();
    }
  }
  //統計データ
  final skipBox = Hive.box<Skip>('skipBox');
  // Boxからデータを読み込む
  final Skip skip = skipBox.get('SkipData')!;
  if (skip.skipflag >= 2 && (racebangou <= 2 || racebangou == 5)) {
    print("区間別統計データ記録ルーチン内通過");
    final statsContainer = EkidenStatistics.instance;
    for (
      int i_kukan = 0;
      i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
      i_kukan++
    ) {
      double mintime = TEISUU.DEFAULTTIME;
      double maxtime = -99999.0;
      double totaltime = 0.0;
      int count = 0;
      double averagetime = 0.0;
      for (var senshu in sortedsenshudata) {
        if (senshu.entrykukan_race[racebangou][senshu.gakunen - 1] == i_kukan) {
          if (mintime > senshu.time_taikai_total) {
            mintime = senshu.time_taikai_total;
          }
          if (maxtime < senshu.time_taikai_total) {
            maxtime = senshu.time_taikai_total;
          }
          totaltime += senshu.time_taikai_total;
          count++;
        }
      }
      averagetime = totaltime / count.toDouble();
      statsContainer.updateStats(
        ekidenIndex: racebangou,
        sectionIndex: i_kukan,
        fastestTime: mintime,
        worstTime: maxtime,
        averageTime: averagetime,
      );
    }
  }

  /////学連選抜の選手のデータ更新
  if (gakurensenshudata.isNotEmpty && racebangou == 2) {
    for (var gsenshu in gakurensenshudata) {
      for (var senshu in sortedsenshudata) {
        if (gsenshu.id == senshu.id) {
          senshu.entrykukan_race[racebangou][senshu.gakunen - 1] =
              gsenshu.entrykukan_race[racebangou][gsenshu.gakunen - 1];
          senshu.kukanjuni_race[racebangou][senshu.gakunen - 1] =
              gsenshu.kukanjuni_race[racebangou][gsenshu.gakunen - 1];
          senshu.kukantime_race[racebangou][senshu.gakunen - 1] =
              gsenshu.kukantime_race[racebangou][gsenshu.gakunen - 1];
          await senshu.save();
        }
      }
    }
  }

  final endTime = DateTime.now();
  final timeInterval = endTime.difference(startTime).inMicroseconds / 1000000.0;
  print("KirokuKousin処理時間: ${_timeToMinuteSecondString(timeInterval)}経過");
}

// SenshuDataのリストをtime_taikai_totalでソートするための拡張メソッド
extension SenshuDataListExtension on List<SenshuData> {
  List<SenshuData> senshuSortByTime() {
    this.sort((a, b) => a.time_taikai_total.compareTo(b.time_taikai_total));
    return this;
  }
}
