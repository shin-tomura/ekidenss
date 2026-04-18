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
Future<void> Kyouka_com({
  //required int racebangou,
  required List<Ghensuu> gh,
  //required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
}) async {
  final startTime = DateTime.now();
  print("Kyouka_comに入った");

  for (int targetunivid = 0; targetunivid < TEISUU.UNIVSUU; targetunivid++) {
    if (targetunivid != gh[0].MYunivid) {
      final List<SenshuData> univFilteredSenshuData = sortedSenshuData
          .where((s) => s.univid == targetunivid)
          .toList();
      for (var senshu in univFilteredSenshuData) {
        senshu.kaifukuryoku = 0;
      }

      //
      int senshutuninzuu = 2;

      //
      univFilteredSenshuData.sort(
        (a, b) => b.kudaritekisei.compareTo(a.kudaritekisei),
      );
      for (int i = 0; i < senshutuninzuu; i++) {
        univFilteredSenshuData[i].kaifukuryoku = 4;
      }

      //
      univFilteredSenshuData.sort(
        (a, b) => b.noborikudarikirikaenouryoku.compareTo(
          a.noborikudarikirikaenouryoku,
        ),
      );
      for (int i = 0; i < senshutuninzuu; i++) {
        univFilteredSenshuData[i].kaifukuryoku = 5;
      }

      //
      univFilteredSenshuData.sort(
        (a, b) => b.noboritekisei.compareTo(a.noboritekisei),
      );
      for (int i = 0; i < senshutuninzuu; i++) {
        univFilteredSenshuData[i].kaifukuryoku = 3;
      }

      //
      univFilteredSenshuData.sort(
        (a, b) => (b.spurtryoku + b.paceagesagetaiouryoku).compareTo(
          a.spurtryoku + a.paceagesagetaiouryoku,
        ),
      );
      senshutuninzuu = 4;
      int count = 0;
      for (int i = 0; i < univFilteredSenshuData.length; i++) {
        if (univFilteredSenshuData[i].kaifukuryoku == 0 &&
            univFilteredSenshuData[i].spurtryoku +
                    univFilteredSenshuData[i].paceagesagetaiouryoku >
                univFilteredSenshuData[i].choukyorinebari +
                    univFilteredSenshuData[i].tandokusou) {
          univFilteredSenshuData[i].kaifukuryoku = 1;
          count++;
          if (count >= senshutuninzuu) break;
        }
      }
      //
      univFilteredSenshuData.sort(
        (a, b) => (b.choukyorinebari + b.tandokusou).compareTo(
          a.choukyorinebari + a.tandokusou,
        ),
      );
      senshutuninzuu = 8;
      count = 0;
      for (int i = 0; i < univFilteredSenshuData.length; i++) {
        if (univFilteredSenshuData[i].kaifukuryoku == 0 &&
            univFilteredSenshuData[i].spurtryoku +
                    univFilteredSenshuData[i].paceagesagetaiouryoku <
                univFilteredSenshuData[i].choukyorinebari +
                    univFilteredSenshuData[i].tandokusou) {
          univFilteredSenshuData[i].kaifukuryoku = 2;
          count++;
          if (count >= senshutuninzuu) break;
        }
      }

      //
      for (var senshu in univFilteredSenshuData) {
        await senshu.save();
      }
    }
  }

  final endTime = DateTime.now();
  final timeInterval = endTime.difference(startTime).inMicroseconds / 1000000.0;
  print("Kyouka_com終了 処理時間: ${_timeToMinuteSecondString(timeInterval)}経過");
}
