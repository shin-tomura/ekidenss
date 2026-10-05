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
import 'package:ekiden/kansuu/goldsilver_com.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart'; // 学連選抜の監督・目標順位(1.8.4)
import 'package:ekiden/kansuu/gakuren_text.dart'; // 学連選抜の結果(順位相当。1.8.4)
import 'package:ekiden/kansuu/meisei_rireki.dart'; // 名声の履歴(1.8.8)
import 'package:ekiden/kansuu/rekidai_kiroku.dart'; // 歴代10位までの記録(1.8.8)

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
    // 日本人・留学生の区間記録を残す順位の数(記録画面に出す大会は歴代10位まで。1.8.8)
    final int rekidaiSaidai = rekidaiTaishouRace(racebangou)
        ? TEISUU.SUU_REKIDAIKIROKUJUNISUU
        : TEISUU.SUU_BESTKIROKUHOZONJUNISUU;
    bool kirokuHenkou = false; // Kirokuを書き換えたか(保存はまとめて1回にする)
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
      // 全体の留学生・日本人(歴代10位まで。保存は区間のループのあとにまとめて行う。1.8.8)
      if (kiroku != null) {
        for (final bool ryuugakusei in [true, false]) {
          if (rekidaiKousin(
            okiba: rekidaiZentaiKukan(kiroku, ryuugakusei, racebangou, iKukan),
            junban: timeJunSortedKukanFilteredSenshuData,
            ryuugakusei: ryuugakusei,
            saidai: rekidaiSaidai,
            gh: gh[0],
            sortedunivdata: sortedunivdata,
          )) {
            kirokuHenkou = true;
          }
        }
      }
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
      // 学内の留学生・日本人(歴代10位まで。保存は区間のループのあとにまとめて行う。1.8.8)
      if (kiroku != null) {
        for (final bool ryuugakusei in [true, false]) {
          if (rekidaiKousin(
            okiba: rekidaiUnivKukan(
              kiroku,
              ryuugakusei,
              gh[0].MYunivid,
              racebangou,
              iKukan,
            ),
            junban: univKukanFilteredSenshuData,
            ryuugakusei: ryuugakusei,
            saidai: rekidaiSaidai,
            gh: gh[0],
            sortedunivdata: sortedunivdata,
          )) {
            kirokuHenkou = true;
          }
        }
      }
    } // 個人区間記録i_kukanループ終端
    if (kirokuHenkou && kiroku != null) {
      await kiroku.save(); // 日本人・留学生の区間記録をまとめて保存
    }

    // 大会記録(記録画面に出す大会は歴代10位まで。1.8.8)
    {
      final int saigoKukan = gh[0].kukansuu_taikaigoto[racebangou] - 1;
      final RekidaiOkiba okiba = rekidaiZentaiTaikai(gh[0], racebangou);
      final List<RekidaiKiroku> rekidai = okiba.yomu();
      bool kawatta = false;
      for (
        var iTimeJuni = 0;
        iTimeJuni < timeJunUnivData.length;
        iTimeJuni++
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
        final UnivData univ = timeJunUnivData[iTimeJuni];
        if (univ.taikaientryflag[racebangou] != 1) continue;
        final double time = univ.time_taikai_total[saigoKukan];
        if (iTimeJuni == 0 &&
            (racebangou <= 2 || racebangou == 5) &&
            gh[0].time_zentaitaikaikiroku[racebangou][0] > time) {
          //大会記録樹立時の途中区間での大会記録比用に保存
          for (
            int i_kukan = 0;
            i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
            i_kukan++
          ) {
            kantoku.yobiint4[racebangou * 10 + 30 + i_kukan] = univ
                .time_taikai_total[i_kukan]
                .toInt();
          }
          await kantoku.save();
        }
        if (rekidaiIreru(
          rekidai,
          RekidaiKiroku(
            time: time,
            year: gh[0].year,
            month: gh[0].month,
            univname: univ.name,
          ),
          rekidaiSaidai,
        )) {
          kawatta = true;
        } else {
          // タイム順なので、入らなかったら、これより後ろの大学も入らない
          break;
        }
      }
      if (kawatta) {
        okiba.kaku(rekidai);
        await gh[0].save(); // gh[0] の変更を保存
      }
    } // 大会記録終端

    // 学内大会記録(記録画面に出す大会は歴代10位まで。1.8.8)
    {
      final UnivData myUniv = sortedunivdata[gh[0].MYunivid];
      final RekidaiOkiba okiba = rekidaiUnivTaikai(myUniv, racebangou);
      final List<RekidaiKiroku> rekidai = okiba.yomu();
      if (rekidaiIreru(
        rekidai,
        RekidaiKiroku(
          time: myUniv
              .time_taikai_total[gh[0].kukansuu_taikaigoto[racebangou] - 1],
          year: gh[0].year,
          month: gh[0].month,
        ),
        rekidaiSaidai,
      )) {
        okiba.kaku(rekidai);
        await myUniv.save(); // UnivData の変更を保存
      }
    } // 学内大会記録終端
  }

  // コンピュータ大学の目標順位達成時の金銀獲得(夏合宿まで保有する)
  if (racebangou >= 0 && racebangou <= 5) {
    await comGoldSilverMokuhyouTassei(
      mokuhyouBangou: racebangou,
      gh: gh,
      sortedUnivData: sortedunivdata,
    );
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
    } else if (racebangou == 2) {
      // 自分の大学が正月駅伝に不出場で、学連選抜の監督をした年の目標達成の報酬(1.8.4)
      await _gakurenMokuhyouHoushuu(
        gh: gh[0],
        kantoku: kantoku,
        myUniv: sortedunivdata[gh[0].MYunivid],
        random: random,
      );
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
      // 総合順位の名声を足す前の今年度の名声(名声の履歴用。1.8.8)
      final int meiseiMae = sortedunivdata[iUniv].meisei_yeargoto[0];
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
      // 名声の履歴に、総合順位で得た名声を足す(1.8.8)
      await meiseiRirekiSougou(sortedunivdata[iUniv], racebangou, meiseiMae);
      //区間賞名声加算
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        if (sortedunivdata[iUniv].kukanjuni_taikai[i_kukan] == 0) {
          final int kukanshouMeisei =
              (0.2 *
                      2000.toDouble() *
                      bairitu *
                      (gh[0].spurtryokuseichousisuu4.toDouble() /
                          gh[0].spurtryokuseichousisuu5.toDouble()))
                  .toInt();
          sortedunivdata[iUniv].meisei_yeargoto[0] += kukanshouMeisei;
          // 名声の履歴に足す(1.8.8)
          await meiseiRirekiKukanshou(
            sortedunivdata[iUniv],
            sortedsenshudata,
            racebangou,
            i_kukan,
            kukanshouMeisei,
          );
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
      // 総合順位の名声を足す前の今年度の名声(名声の履歴用。1.8.8)
      final int meiseiMae = sortedunivdata[iUniv].meisei_yeargoto[0];
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
      // 名声の履歴に、総合順位で得た名声を足す(1.8.8)
      await meiseiRirekiSougou(sortedunivdata[iUniv], racebangou, meiseiMae);
      //区間賞名声加算
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        if (sortedunivdata[iUniv].kukanjuni_taikai[i_kukan] == 0) {
          final int kukanshouMeisei =
              (500.toDouble() * 0.2 * bairitu).toInt();
          sortedunivdata[iUniv].meisei_yeargoto[0] += kukanshouMeisei;
          // 名声の履歴に足す(1.8.8)
          await meiseiRirekiKukanshou(
            sortedunivdata[iUniv],
            sortedsenshudata,
            racebangou,
            i_kukan,
            kukanshouMeisei,
          );
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
      // 総合順位の名声を足す前の今年度の名声(名声の履歴用。1.8.8)
      final int meiseiMae = sortedunivdata[iUniv].meisei_yeargoto[0];
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
      // 名声の履歴に、総合順位で得た名声を足す(1.8.8)
      await meiseiRirekiSougou(sortedunivdata[iUniv], racebangou, meiseiMae);
      //区間賞名声加算
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        if (sortedunivdata[iUniv].kukanjuni_taikai[i_kukan] == 0) {
          final int kukanshouMeisei =
              (500.toDouble() * 0.2 * bairitu).toInt();
          sortedunivdata[iUniv].meisei_yeargoto[0] += kukanshouMeisei;
          // 名声の履歴に足す(1.8.8)
          await meiseiRirekiKukanshou(
            sortedunivdata[iUniv],
            sortedsenshudata,
            racebangou,
            i_kukan,
            kukanshouMeisei,
          );
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
      // 総合順位の名声を足す前の今年度の名声(名声の履歴用。1.8.8)
      final int meiseiMae = sortedunivdata[iUniv].meisei_yeargoto[0];
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
      // 名声の履歴に、総合順位で得た名声を足す(1.8.8)
      await meiseiRirekiSougou(sortedunivdata[iUniv], racebangou, meiseiMae);
      //区間賞名声加算
      for (
        int i_kukan = 0;
        i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
        i_kukan++
      ) {
        if (sortedunivdata[iUniv].kukanjuni_taikai[i_kukan] == 0) {
          final int kukanshouMeisei =
              (2000.toDouble() * 0.2 * bairitu).toInt();
          sortedunivdata[iUniv].meisei_yeargoto[0] += kukanshouMeisei;
          // 名声の履歴に足す(1.8.8)
          await meiseiRirekiKukanshou(
            sortedunivdata[iUniv],
            sortedsenshudata,
            racebangou,
            i_kukan,
            kukanshouMeisei,
          );
        }
      }
      await sortedunivdata[iUniv].save(); // UnivData の変更を保存
    }
    // 学連選抜の選手が区間1位相当で走ったときは、その選手の大学に名声(正月駅伝の区間賞の1/4。1.8.8)
    // (オープン参加なので区間賞ではない。大学の区間賞は今まで通り、大学の選手の中で一番速い選手の
    //  大学に入る。コンピュータが監督の年も同じ。学連選抜のチームの順位相当では名声はない)
    for (
      int i_kukan = 0;
      i_kukan < gh[0].kukansuu_taikaigoto[racebangou];
      i_kukan++
    ) {
      final GakurenKukanKekka? gakuren = gakurenKukanKekka(gh[0], i_kukan);
      if (gakuren == null || gakuren.kukanJuni != 0) continue;
      final int univid = gakuren.senshu.univid;
      if (univid < 0 || univid >= sortedunivdata.length) continue;
      final int ryou = gakurenKukanIchiiMeisei(bairitu);
      sortedunivdata[univid].meisei_yeargoto[0] += ryou;
      await sortedunivdata[univid].save(); // UnivData の変更を保存
      // 名声の履歴に足す(1.8.8)
      await meiseiRirekiTsuika(
        univid,
        '正月駅伝 学連選抜 ${i_kukan + 1}区 区間1位相当(${gakuren.senshu.name})',
        ryou,
      );
      // 確認用(どれくらい起きるかを、統計をとるときに数えられるように)
      print(
        '学連選抜 ${i_kukan + 1}区 区間1位相当: ${gakuren.senshu.name}(${gakuren.shozoku}大学) 名声+$ryou',
      );
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
    // 日本人・留学生の個人記録を残す順位の数(記録画面に出す種目は歴代10位まで。1.8.8)
    final int kojinRekidaiSaidai = rekidaiTaishouKojin(kirokubangou)
        ? TEISUU.SUU_REKIDAIKIROKUJUNISUU
        : TEISUU.SUU_BESTKIROKUHOZONJUNISUU;
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
      // 全体の留学生・日本人(5000m・10000m・ハーフ・フルは歴代10位まで。保存はまとめて1回。1.8.8)
      if (kiroku != null) {
        bool kawatta = false;
        for (final bool ryuugakusei in [true, false]) {
          if (rekidaiKousin(
            okiba: rekidaiZentaiKojin(kiroku, ryuugakusei, kirokubangou),
            junban: kirokujunEntryFilteredSenshuData,
            ryuugakusei: ryuugakusei,
            saidai: kojinRekidaiSaidai,
            gh: gh[0],
            sortedunivdata: sortedunivdata,
          )) {
            kawatta = true;
          }
        }
        if (kawatta) await kiroku.save(); // Hiveに保存
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
      // 学内の留学生・日本人(5000m・10000m・ハーフ・フルは歴代10位まで。保存はまとめて1回。1.8.8)
      if (kiroku != null) {
        bool kawatta = false;
        for (final bool ryuugakusei in [true, false]) {
          if (rekidaiKousin(
            okiba: rekidaiUnivKojin(
              kiroku,
              ryuugakusei,
              gh[0].MYunivid,
              kirokubangou,
            ),
            junban: kirokujunUnivEntryFilteredSenshuData,
            ryuugakusei: ryuugakusei,
            saidai: kojinRekidaiSaidai,
            gh: gh[0],
            sortedunivdata: sortedunivdata,
          )) {
            kawatta = true;
          }
        }
        if (kawatta) await kiroku.save(); // Hiveに保存
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
            // 名声の履歴に足す(1.8.8)
            final String shumoku = racebangou == 6
                ? '5000m'
                : (racebangou == 7 ? '10000m' : 'ハーフ');
            await meiseiRirekiTsuika(
              univId,
              '対校戦 $shumoku ${i + 1}位(${kirokujunEntryFilteredSenshuData[i].name})',
              meiseiPoints[i],
            );
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
            // 名声の履歴に足す(1.8.8)
            await meiseiRirekiTsuika(
              inkarepointTotalJunUnivData[i].id,
              '対校戦 総合${i + 1}位',
              meiseiPointsOverall[i],
            );
          }
        }

        /*print(
          "自分の大学の対校戦総合目標順位: ${sortedunivdata[gh[0].MYunivid].mokuhyojuni[9] + 1}位",
        );
        print(
          "自分の大学は対校戦総合で: ${sortedunivdata[gh[0].MYunivid].juni_race[9][0] + 1}位",
        );*/

        // コンピュータ大学の目標順位達成時の金銀獲得(対校戦総合、夏合宿まで保有する)
        await comGoldSilverMokuhyouTassei(
          mokuhyouBangou: 9,
          gh: gh,
          sortedUnivData: sortedunivdata,
        );

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
    // 日本人だけ(留学生を除く)の区間別統計(1.8.7)
    final statsContainerNihonjin = EkidenStatistics.instanceNihonjin;
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
      double mintimeNihonjin = TEISUU.DEFAULTTIME;
      double maxtimeNihonjin = -99999.0;
      double totaltimeNihonjin = 0.0;
      int countNihonjin = 0;
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
          if (senshu.hirou == 1) {
            statsContainer.ryuugakuseiGaHashitta = true;
          } else {
            if (mintimeNihonjin > senshu.time_taikai_total) {
              mintimeNihonjin = senshu.time_taikai_total;
            }
            if (maxtimeNihonjin < senshu.time_taikai_total) {
              maxtimeNihonjin = senshu.time_taikai_total;
            }
            totaltimeNihonjin += senshu.time_taikai_total;
            countNihonjin++;
          }
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
      if (countNihonjin > 0) {
        statsContainerNihonjin.updateStats(
          ekidenIndex: racebangou,
          sectionIndex: i_kukan,
          fastestTime: mintimeNihonjin,
          worstTime: maxtimeNihonjin,
          averageTime: totaltimeNihonjin / countNihonjin.toDouble(),
        );
      }
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

/// 正月駅伝の「駅伝名声設定」の倍率(大学id 5・6 の name_tanshuku。正月駅伝の名声の加算と同じ読み方)
double _shougatsuMeiseiBairitu() {
  int yomu(int id) {
    for (final UnivData u in Hive.box<UnivData>('univBox').values) {
      if (u.id == id) {
        final int? v = int.tryParse(u.name_tanshuku);
        return (v == null || v < 1 || v > 10) ? 1 : v;
      }
    }
    return 1;
  }

  return yomu(5).toDouble() / yomu(6).toDouble();
}

/// 学連選抜の監督として目標順位を達成したときの報酬(1.8.4)
/// ・自分の大学が正月駅伝に不出場で、学連選抜の監督をしていて(スキップ中でない)、
///   学連選抜の最終の順位相当が、最後に決めた目標順位以内のとき
/// ・目標順位が10位以内のときだけ(10位より下の目標で確実にもらうことはできない)
/// ・見抜く力は、大学の目標達成と同じ印(KantokuData.yobiint2[1])を付ける
/// ・金銀は、予選突破の目標達成と同じ最低量(10×金銀支給量の倍率。1割で金、9割で銀)。
///   学連選抜には各校のエースが集まり、目標を達成しやすいので、目標順位を上げても量は増やさない。
///   難易度モードの「極」「天」では金銀はなし(大学の目標達成と同じ)
Future<void> _gakurenMokuhyouHoushuu({
  required Ghensuu gh,
  required KantokuData kantoku,
  required UnivData myUniv,
  required Random random,
}) async {
  if (!gakurenKantokuRule(kantoku, myUniv)) return;
  if (gh.kukansuu_taikaigoto.length <= 2) return;
  final GakurenKukanKekka? saigo = gakurenKukanKekka(
    gh,
    gh.kukansuu_taikaigoto[2] - 1,
  );
  if (saigo == null) return;
  final int mokuhyou = gakurenMokuhyouSettei(kantoku); // 0が1位
  if (mokuhyou > gakurenHoushuuMokuhyouSaikai) return;
  if (saigo.tuukaJuni > mokuhyou) return;

  // 目標1位で総合1位相当に導いたときは、監督の手腕が評価されて、監督の大学に名声(1.8.8)
  // (学連選抜にはスポンサーはいないので金銀は増やさない。結果画面にお祝いの文を出す(mode0700_content.dart)。
  //  サプライズなので、説明書・生成AI向けの仕様・変更履歴には書かない)
  if (gakurenYuushouKantoku(gh, kantoku, myUniv)) {
    final int ryou = gakurenYuushouKantokuMeisei(_shougatsuMeiseiBairitu());
    myUniv.meisei_yeargoto[0] += ryou;
    await myUniv.save();
    await meiseiRirekiTsuika(
      myUniv.id,
      '学連選抜 総合1位相当(監督として。目標1位)',
      ryou,
    );
  }

  // 見抜く力(このあと金銀の画面と、見抜く能力を選ぶ画面に進む)
  kantoku.yobiint2[1] = 1;
  await kantoku.save();

  // 金銀(難易度モードが通常のときだけ)
  if (kantoku.yobiint2[0] != 0) return;
  final int ryou = 10 * kantoku.yobiint2[12];
  if (random.nextInt(100) < 10) {
    gh.last_goldenballkakutokusuu = ryou;
    gh.goldenballsuu += ryou;
  } else {
    gh.last_silverballkakutokusuu = ryou;
    gh.silverballsuu += ryou;
  }
  if (gh.goldenballsuu > 9999) gh.goldenballsuu = 9999;
  if (gh.silverballsuu > 9999) gh.silverballsuu = 9999;
  await gh.save();
}

// SenshuDataのリストをtime_taikai_totalでソートするための拡張メソッド
extension SenshuDataListExtension on List<SenshuData> {
  List<SenshuData> senshuSortByTime() {
    this.sort((a, b) => a.time_taikai_total.compareTo(b.time_taikai_total));
    return this;
  }
}
