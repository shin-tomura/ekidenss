import 'dart:math'; // Randomクラスを使用するため
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
import 'package:ekiden/kansuu/ChoukyoriNebariHoseitime.dart';
import 'package:ekiden/kansuu/SpurtRyokuHoseitime.dart';
import 'package:ekiden/kansuu/TimeDesugiHoseiHoseitime.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/Shuudansou.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/univ_gakuren_data.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/univkosei.dart';

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

Future<void> RaceCalc_gakuren({
  required int racebangou,
  required List<Ghensuu> gh,
  required List<UnivData> sortedunivdata,
  //required List<SenshuData> gakurensenshudata,
}) async {
  // Hive.box() を使って、既に開いているBoxを取得
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  // Boxからデータを読み込む
  final KantokuData kantoku = kantokuBox.get('KantokuData')!;

  final gakurenunivBox = Hive.box<UnivGakurenData>('gakurenUnivBox');
  final gakurenunivdata = gakurenunivBox.values.toList();
  final gakurensenshuBox = Hive.box<Senshu_Gakuren_Data>('gakurenSenshuBox');
  final gakurensenshudata = gakurensenshuBox.values.toList();

  if (gakurensenshudata.isEmpty) {
    return;
  }

  // Randomインスタンスを作成
  final random = Random();
  var hoseitotal = 0.0;
  var tanihosei = 0.0;
  var temphosei = 0.0;
  var tempkyori = 0.0;
  var kyoriwariai_nobori = 0.0;
  var kyoriwariai_kudari = 0.0;
  var heikinkoubai_nobori = 0.0;
  var heikinkoubai_kudari = 0.0;
  var noborikudari_kirikaekaisuu = 0;
  var temptandokusou = 0;
  var temppaceagesagetaiouryoku = 0;
  var tekiyouritu_tandokusouhosei = 1.0;
  var tekiyouritu_paceagesagehosei = 1.0;
  int hoseishuruisuu = 17;
  int idshuruisuu = gakurensenshudata.length;

  List<double> timesa_free_shuudan = List.filled(idshuruisuu, 0.0);

  //補正種類番号
  //0登り補正、1下り補正、2アップダウン対応力補正、3経験補正、4ロード適性補正、5ペース変動対応力補正、6長距離粘り補正、7スパート力補正
  //8基本走力差、9〜13その他補正、14集団走補正、15補正計、16基本走力差+補正計
  //atai_hosei[選手ID][補正種類番号]
  List<List<double>> atai_hosei = List.generate(
    idshuruisuu,
    (i) => List<double>.filled(hoseishuruisuu, TEISUU.DEFAULTTIME),
  );
  //juni_hosei[選手ID][補正種類番号]
  List<List<int>> juni_hosei = List.generate(
    idshuruisuu,
    (i) => List<int>.filled(hoseishuruisuu, TEISUU.DEFAULTJUNI),
  );
  //補正名
  List<String> name_hosei = List.filled(hoseishuruisuu, "その他補正");
  name_hosei[0] = "登り補正";
  name_hosei[1] = "下り補正";
  name_hosei[2] = "アップダウン対応力補正";
  name_hosei[3] = "経験補正";
  name_hosei[4] = "ロード適性補正";
  name_hosei[5] = "ペース変動対応力補正";
  name_hosei[6] = "長距離粘り補正";
  name_hosei[7] = "スパート力補正";
  name_hosei[8] = "基本走力差";
  name_hosei[14] = "集団走補正";
  name_hosei[15] = "補正計";
  name_hosei[16] = "トータル";
  //補正名
  List<int> nouryokumieruflagIndex_hosei = List.filled(hoseishuruisuu, 0);
  nouryokumieruflagIndex_hosei[0] = 5;
  nouryokumieruflagIndex_hosei[1] = 6;
  nouryokumieruflagIndex_hosei[2] = 7;
  nouryokumieruflagIndex_hosei[3] = 0; //使わない
  nouryokumieruflagIndex_hosei[4] = 8;
  nouryokumieruflagIndex_hosei[5] = 9;
  nouryokumieruflagIndex_hosei[6] = 2;
  nouryokumieruflagIndex_hosei[7] = 3;
  nouryokumieruflagIndex_hosei[8] = 0; //使わない

  final startTime = DateTime.now();
  print("RaceCal_gakurenに入った");

  if (racebangou >= 0 && racebangou <= 5) {
    if (gh[0].nowracecalckukan == 0) {
      for (var ii = 0; ii < TEISUU.SUU_MAXKUKANSUU; ii++) {
        gakurenunivdata[0].time_taikai_total[ii] = 0.0;
      }
    }
  }

  if (racebangou >= 0 && racebangou <= 5) {
    tempkyori =
        gh[0].kyori_taikai_kukangoto[racebangou][gh[0].nowracecalckukan];
    kyoriwariai_nobori = gh[0]
        .kyoriwariainobori_taikai_kukangoto[racebangou][gh[0].nowracecalckukan];
    kyoriwariai_kudari = gh[0]
        .kyoriwariaikudari_taikai_kukangoto[racebangou][gh[0].nowracecalckukan];
    heikinkoubai_nobori =
        gh[0].heikinkoubainobori_taikai_kukangoto[racebangou][gh[0]
            .nowracecalckukan];
    heikinkoubai_kudari =
        gh[0].heikinkoubaikudari_taikai_kukangoto[racebangou][gh[0]
            .nowracecalckukan];
    noborikudari_kirikaekaisuu =
        gh[0].noborikudarikirikaekaisuu_taikai_kukangoto[racebangou][gh[0]
            .nowracecalckukan];
  }

  if (gh[0].nowracecalckukan == 0) {
    for (var senshuid = 0; senshuid < gakurensenshudata.length; senshuid++) {
      gakurensenshudata[senshuid].time_taikai_total = TEISUU.DEFAULTTIME;
    }
  }
  //強化練習強度を取得
  final int kyoudo = kantoku.yobiint2[16];
  for (var senshuid = 0; senshuid < gakurensenshudata.length; senshuid++) {
    hoseitotal = 0.0;
    if (gakurensenshudata[senshuid]
            .entrykukan_race[racebangou][gakurensenshudata[senshuid].gakunen -
            1] ==
        gh[0].nowracecalckukan) {
      //強化練習番号を取得
      final int trainingNum = gakurensenshudata[senshuid].kaifukuryoku;
      // 関数を呼び出してマップを取得(大学の個性)
      Map<AbilityType, int> abilityValues = getAbilitySettingsForUniv(
        gakurensenshudata[senshuid].univid,
      );
      // 設定値を取得 (0-9)
      int tempSetting = 0;
      tempSetting = abilityValues[AbilityType.nagakyoriNebari] ?? 0;
      if (gakurensenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_nebari = 150 - tempSetting * 10;
      set_nebari =
          ((set_nebari.toDouble() / 100.0) *
                  gakurensenshudata[senshuid].choukyorinebari.toDouble())
              .toInt();
      if (trainingNum == 2) {
        //set_nebari += kyoudo * 7 ~/ 2;
        set_nebari += kyoudo * 4 ~/ 2;
      } else if (trainingNum == 0) {
        set_nebari += kyoudo;
      }
      if (set_nebari < 1) set_nebari = 1;
      tempSetting = abilityValues[AbilityType.spurtPower] ?? 0;
      if (gakurensenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_spurt = 150 - tempSetting * 10;
      set_spurt =
          ((set_spurt.toDouble() / 100.0) *
                  gakurensenshudata[senshuid].spurtryoku.toDouble())
              .toInt();
      if (trainingNum == 1) {
        set_spurt += kyoudo * 7 ~/ 2;
      } else if (trainingNum == 0) {
        set_spurt += kyoudo;
      }
      if (set_spurt < 1) set_spurt = 1;
      /*tempSetting = abilityValues[AbilityType.charisma] ?? 0;
      if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_karisuma = 150 - tempSetting * 10;
      set_karisuma =
          ((set_karisuma.toDouble() / 100.0) *
                  sortedsenshudata[senshuid].karisuma.toDouble())
              .toInt();
      if (set_karisuma < 1) set_karisuma = 1;*/
      tempSetting = abilityValues[AbilityType.noboriTekisei] ?? 0;
      if (gakurensenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_nobori = 150 - tempSetting * 10;
      set_nobori =
          ((set_nobori.toDouble() / 100.0) *
                  gakurensenshudata[senshuid].noboritekisei.toDouble())
              .toInt();
      if (trainingNum == 3) {
        set_nobori += kyoudo * 7;
      } else if (trainingNum == 0) {
        set_nobori += kyoudo;
      }
      if (set_nobori < 1) set_nobori = 1;
      tempSetting = abilityValues[AbilityType.kudariTekisei] ?? 0;
      if (gakurensenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_kudari = 150 - tempSetting * 10;
      set_kudari =
          ((set_kudari.toDouble() / 100.0) *
                  gakurensenshudata[senshuid].kudaritekisei.toDouble())
              .toInt();
      if (trainingNum == 4) {
        set_kudari += kyoudo * 7;
      } else if (trainingNum == 0) {
        set_kudari += kyoudo;
      }
      if (set_kudari < 1) set_kudari = 1;
      tempSetting = abilityValues[AbilityType.upDownTaiouryoku] ?? 0;
      if (gakurensenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_updown = 150 - tempSetting * 10;
      set_updown =
          ((set_updown.toDouble() / 100.0) *
                  gakurensenshudata[senshuid].noborikudarikirikaenouryoku
                      .toDouble())
              .toInt();
      if (trainingNum == 5) {
        set_updown += kyoudo * 7;
      } else if (trainingNum == 0) {
        set_updown += kyoudo;
      }
      if (set_updown < 1) set_updown = 1;
      tempSetting = abilityValues[AbilityType.roadTekisei] ?? 0;
      if (gakurensenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_road = 150 - tempSetting * 10;
      set_road =
          ((set_road.toDouble() / 100.0) *
                  gakurensenshudata[senshuid].tandokusou.toDouble())
              .toInt();
      if (trainingNum == 2) {
        //set_road += kyoudo * 7 ~/ 2;
        set_road += kyoudo * 4 ~/ 2;
      } else if (trainingNum == 0) {
        set_road += kyoudo;
      }
      if (set_road < 1) set_road = 1;
      tempSetting = abilityValues[AbilityType.paceHendoTaiouryoku] ?? 0;
      if (gakurensenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_pacehendou = 150 - tempSetting * 10;
      set_pacehendou =
          ((set_pacehendou.toDouble() / 100.0) *
                  gakurensenshudata[senshuid].paceagesagetaiouryoku.toDouble())
              .toInt();
      if (trainingNum == 1) {
        set_pacehendou += kyoudo * 7 ~/ 2;
      } else if (trainingNum == 0) {
        set_pacehendou += kyoudo;
      }
      if (set_pacehendou < 1) set_pacehendou = 1;

      // Theoretical time calculation
      final kyori = tempkyori;
      double returntime = 0.0;

      double _calculateOptimalX(double kyori) {
        // 数理的に導出した「x」を最小にする魔法の式
        // 1715.46 (Bの頂点) - 1450 (xへの変換) = 265.46
        double x = 265.46 - (1501501.5 / kyori);
        // 5000m以下でxが極端に小さく（マイナスに）ならないよう、
        // これまでの実績値(x=4付近)を下限としてガードをかけます
        return x.clamp(4.0, 300.0);
      }

      double newbdouble = _calculateOptimalX(kyori) + 1450.0;
      //int newbint = _calculateOptimalX(kyori).round();
      /*if (kyori < 5001.0) {
        newbint = 4;
      } else if (kyori < 6001.0) {
        newbint = 20;
      } else if (kyori < 7001.0) {
        newbint = 45;
      } else if (kyori < 8001.0) {
        newbint = 74;
      } else if (kyori < 9001.0) {
        newbint = 97;
      } else if (kyori < 10001.0) {
        newbint = 115;
      } else if (kyori < 11001.0) {
        newbint = 128;
      } else if (kyori < 12001.0) {
        newbint = 139;
      } else if (kyori < 13001.0) {
        newbint = 150;
      } else if (kyori < 14001.0) {
        newbint = 154;
      } else if (kyori < 15001.0) {
        newbint = 163;
      } else if (kyori < 16001.0) {
        newbint = 170;
      } else if (kyori < 17001.0) {
        newbint = 176;
      } else if (kyori < 18001.0) {
        newbint = 181;
      } else if (kyori < 19001.0) {
        newbint = 185;
      } else if (kyori < 20001.0) {
        newbint = 189;
      } else if (kyori < 21001.0) {
        newbint = 192;
      } else if (kyori < 22001.0) {
        newbint = 195;
      } else if (kyori < 23001.0) {
        newbint = 199;
      } else if (kyori < 24001.0) {
        newbint = 202;
      } else if (kyori < 25001.0) {
        newbint = 205;
        /*} else if (kyori < 26001.0) {
        newbint = 207;
      } else if (kyori < 27001.0) {
        newbint = 210;
      } else if (kyori < 28001.0) {
        newbint = 213;
      } else if (kyori < 29001.0) {
        newbint = 216;*/
      } else {
        //newbint = 150;
        newbint = 230;
      }*/
      //newbint += 1450;

      int b_int = (gakurensenshudata[senshuid].b * 10000.0).round();
      int a_int = (gakurensenshudata[senshuid].a * 1000000000.0).round();
      int a_min_int =
          (b_int * b_int * 0.0333 -
                  b_int * 114.25 +
                  gakurensenshudata[senshuid].magicnumber)
              .round();
      int sa = a_int - a_min_int;
      int new_a_min_int =
          (newbdouble * newbdouble * 0.0333 -
                  newbdouble * 114.25 +
                  gakurensenshudata[senshuid].magicnumber)
              .round();
      int new_a_int = new_a_min_int + sa;

      /*gakurensenshudata[senshuid].a = new_a_int * 0.000000001;
      gakurensenshudata[senshuid].b = newbdouble * 0.0001;
      await gakurensenshudata[senshuid].save();
      returntime =
          gakurensenshudata[senshuid].a * kyori * kyori +
          gakurensenshudata[senshuid].b * kyori;*/

      double double_a = new_a_int * 0.000000001;
      double double_b = newbdouble * 0.0001;
      returntime = double_a * kyori * kyori + double_b * kyori;

      // 元のスコアを計算
      final double originaltime = returntime; // 780.0

      // ランダムな変動幅を計算 (0.1%)
      final double variation = originaltime * 0.001; // 780.0 * 0.001 = 0.78

      // -variation から +variation の範囲でランダムな値を生成
      // nextDouble() は 0.0 以上 1.0 未満の値を返す
      // 0.0 から 2.0 * variation の範囲の値を生成し、そこから variation を引くことで
      // -variation から +variation の範囲にする
      final double randomOffset =
          (random.nextDouble() * 2 * variation) - variation;

      // 新しいスコアを計算
      final double newtime = originaltime + randomOffset;

      returntime = newtime;

      //タイム調整
      //kantoku.yobiint5の
      //[30から39]10月駅伝区間ごとタイム調整、
      //[40から49]11月駅伝区間ごとタイム調整、
      //[50から59]正月駅伝区間ごとタイム調整、
      //[60]全体タイム調整、
      //[80から89]カスタム駅伝区間ごとタイム調整、
      {
        double chousei_zentai = kantoku.yobiint5[60].toDouble() / 2.0;
        double chousei_kukangoto = 0.0;
        if (racebangou <= 2 || racebangou == 5) {
          chousei_kukangoto =
              kantoku.yobiint5[gh[0].nowracecalckukan + (racebangou + 3) * 10]
                  .toDouble() /
              2.0;
        }
        double chousei = chousei_zentai + chousei_kukangoto;
        returntime *= (100.0 + chousei) / 100.0;
      }

      // Excess time correction
      if (gakurensenshudata[senshuid].hirou == 1) {
        returntime += TimeDesugiHoseiHoseitime_ryuugakusei(
          kyori: tempkyori,
          mototime: returntime,
        );
        if (sortedunivdata[9].name_tanshuku == "1") {
          returntime = adjustTargetedFastTime(
            timeMoto: returntime,
            distanceM: tempkyori,
          );
        }
      } else {
        returntime += TimeDesugiHoseiHoseitime(
          kyori: tempkyori,
          mototime: returntime,
        );
        if (sortedunivdata[9].name_tanshuku == "1") {
          returntime = adjustTargetedFastTime(
            timeMoto: returntime,
            distanceM: tempkyori,
          );
        }
      }

      //gakurensenshudata[senshuid].speed = tempkyori / returntime;
      double double_speed = tempkyori / returntime;

      atai_hosei[senshuid][8] = returntime;

      // Climbing/Descending Correction
      double hosei_nobori = 0.0;
      double hosei_kudari = 0.0;
      double hosei_kirikae = 0.0;
      double hyoukousasisuu = 0.0;

      // Uphill
      double hosei = 0.044 - 0.00017 * set_nobori * TEISUU.CHOUSEI_NOBORI;
      hyoukousasisuu = kyoriwariai_nobori * heikinkoubai_nobori;
      hosei = hosei * (hyoukousasisuu / 0.01);
      hosei_nobori = -hosei;

      // Downhill
      hosei = 0.00965 + 0.00018 * set_kudari * TEISUU.CHOUSEI_KUDARI;
      hyoukousasisuu = kyoriwariai_kudari * heikinkoubai_kudari;
      hosei = hosei * (-hyoukousasisuu / 0.01);
      hosei_kudari = hosei;

      // Switchback
      hosei =
          TEISUU.CHOUSEI_KIRIKAE *
          noborikudari_kirikaekaisuu *
          //(100.0 - set_updown);
          (135.0 - set_updown);
      hosei_kirikae = -hosei;

      double hosei_total_altitude =
          (hosei_nobori + hosei_kudari + hosei_kirikae) + 1.0;
      double moto_time_taikai_total = 0.0;
      double moto_speed = double_speed;
      double temp_speed = 0.0;
      double new_time_taikai_total = 0.0;
      double_speed = double_speed * hosei_total_altitude;
      gakurensenshudata[senshuid].time_taikai_total = tempkyori / double_speed;

      if (racebangou >= 0 && racebangou <= 5) {
        atai_hosei[senshuid][0] =
            -gakurensenshudata[senshuid].time_taikai_total * hosei_nobori;
        atai_hosei[senshuid][1] =
            -gakurensenshudata[senshuid].time_taikai_total * hosei_kudari;
        atai_hosei[senshuid][2] =
            -gakurensenshudata[senshuid].time_taikai_total * hosei_kirikae;
      }

      // Solo Run / Pace Adjustment Adaptability
      if (racebangou >= 0 && racebangou <= 5) {
        if ((racebangou != 4 && gh[0].nowracecalckukan == 0) ||
            racebangou == 3) {
          temptandokusou = 100;
          temppaceagesagetaiouryoku = set_pacehendou;
        } else if (racebangou == 4) {
          temptandokusou = set_road;
          tekiyouritu_tandokusouhosei = 0.5;
          temppaceagesagetaiouryoku = set_pacehendou;
          tekiyouritu_paceagesagehosei = 0.5;
        } else if (gh[0].nowracecalckukan >= 1 && gh[0].nowracecalckukan <= 2) {
          temptandokusou = set_road;
          tekiyouritu_tandokusouhosei = 0.5;
          temppaceagesagetaiouryoku = set_pacehendou;
          tekiyouritu_paceagesagehosei = 0.5;
        } else {
          temptandokusou = set_road;
          temppaceagesagetaiouryoku = 100;
        }
      }

      // Experience correction
      if ((racebangou >= 0 && racebangou <= 2) || racebangou == 5) {
        var temphosei_exp = 0.0;
        for (
          var i_gakunen = gakurensenshudata[senshuid].gakunen - 1;
          i_gakunen >= 1;
          i_gakunen--
        ) {
          if (gakurensenshudata[senshuid]
                  .entrykukan_race[racebangou][i_gakunen - 1] >=
              0) {
            if (gakurensenshudata[senshuid]
                    .entrykukan_race[racebangou][i_gakunen - 1] ==
                gh[0].nowracecalckukan) {
              temphosei_exp -= 0.003;
            }
          }
        }
        hoseitotal += temphosei_exp;
        if (temphosei_exp < -0.0001) {
          atai_hosei[senshuid][3] =
              gakurensenshudata[senshuid].time_taikai_total * temphosei_exp;
        }
      }

      // Apply total correction
      gakurensenshudata[senshuid].time_taikai_total +=
          gakurensenshudata[senshuid].time_taikai_total * hoseitotal;

      ///
      timesa_free_shuudan[senshuid] = 0.0;
      // Solo running correction
      tanihosei = 0.03 / 100.0;
      temphosei = (100 - temptandokusou) * tanihosei;
      temphosei *= tekiyouritu_tandokusouhosei;
      moto_time_taikai_total = gakurensenshudata[senshuid].time_taikai_total;
      gakurensenshudata[senshuid].time_taikai_total +=
          gakurensenshudata[senshuid].time_taikai_total * temphosei;
      if (racebangou >= 0 && racebangou <= 5) {
        //if (gh[0].nouryokumieruflag[8] == 1) {
        /*gakurensenshudata[senshuid].string_racesetumei +=
              "ロード適性補正:${(gakurensenshudata[senshuid].time_taikai_total * temphosei).isNegative ? '' : '+'}${(gakurensenshudata[senshuid].time_taikai_total * temphosei).toStringAsFixed(1)}秒\n";
              */
        atai_hosei[senshuid][4] = moto_time_taikai_total * temphosei;
        if (racebangou == 4 && tekiyouritu_tandokusouhosei < 0.45) {
          double moto_temphosei = temphosei / tekiyouritu_tandokusouhosei;
          double free_temphosei = moto_temphosei * 0.5;
          timesa_free_shuudan[senshuid] +=
              atai_hosei[senshuid][4] - moto_time_taikai_total * free_temphosei;
        }
        //}
      }

      // Pace adjustment adaptability correction
      tanihosei = 0.03 / 100.0;
      temphosei = (100 - temppaceagesagetaiouryoku) * tanihosei;
      temphosei *= tekiyouritu_paceagesagehosei;
      moto_time_taikai_total = gakurensenshudata[senshuid].time_taikai_total;
      gakurensenshudata[senshuid].time_taikai_total +=
          gakurensenshudata[senshuid].time_taikai_total * temphosei;
      if (racebangou >= 0 && racebangou <= 5) {
        //if (gh[0].nouryokumieruflag[9] == 1) {
        /*gakurensenshudata[senshuid].string_racesetumei +=
              "ペース変動対応力補正:${(gakurensenshudata[senshuid].time_taikai_total * temphosei).isNegative ? '' : '+'}${(gakurensenshudata[senshuid].time_taikai_total * temphosei).toStringAsFixed(1)}秒\n";
              */
        atai_hosei[senshuid][5] = moto_time_taikai_total * temphosei;
        if (racebangou == 4 && tekiyouritu_paceagesagehosei < 0.45) {
          double moto_temphosei = temphosei / tekiyouritu_paceagesagehosei;
          double free_temphosei = moto_temphosei * 0.5;
          timesa_free_shuudan[senshuid] +=
              atai_hosei[senshuid][5] - moto_time_taikai_total * free_temphosei;
        }
        //}
      }

      // Long-distance endurance correction
      final choukyoriHosei = ChoukyoriNebariHoseitime_gakuren(
        kyori: tempkyori,
        choukyorinebari: set_nebari,
        zentaiyokuseiti: kantoku.yobiint2[13],
        //senshuid: senshuid,
        //gakurensenshudata: gakurensenshudata,
      );
      gakurensenshudata[senshuid].time_taikai_total += choukyoriHosei;
      if (racebangou >= 0 && racebangou <= 5) {
        //if (gh[0].nouryokumieruflag[2] == 1) {
        /*gakurensenshudata[senshuid].string_racesetumei +=
              "長距離粘り補正:${choukyoriHosei.isNegative ? '' : '+'}${choukyoriHosei.toStringAsFixed(1)}秒\n";
              */
        atai_hosei[senshuid][6] = choukyoriHosei;
        //}
      }

      // Sprint power correction
      final spurtHosei = SpurtRyokuHoseitime_gakuren(
        kyori: tempkyori,
        spurtRyoku: set_spurt,
        //senshuid: senshuid,
        //gakurensenshudata: gakurensenshudata,
      );
      gakurensenshudata[senshuid].time_taikai_total += spurtHosei;
      if (racebangou >= 0 && racebangou <= 5) {
        //if (gh[0].nouryokumieruflag[3] == 1) {
        /*gakurensenshudata[senshuid].string_racesetumei +=
              "スパート力補正:${spurtHosei.isNegative ? '' : '+'}${spurtHosei.toStringAsFixed(1)}秒\n";
              */
        atai_hosei[senshuid][7] = spurtHosei;
        //}
      }

      //調子補正
      if (racebangou <= 2 || racebangou == 5 && kantoku.yobiint2[2] != 0) {
        if (gakurensenshudata[senshuid].chousi == 0) {
          tanihosei = (kantoku.yobiint2[11].toDouble() / 100.0) / 100.0;
          temphosei = (100 - 0) * tanihosei;
          //temphosei *= (kantoku.yobiint2[2].toDouble() / 100.0); //調子適用率
          moto_time_taikai_total =
              gakurensenshudata[senshuid].time_taikai_total;
          gakurensenshudata[senshuid].time_taikai_total +=
              gakurensenshudata[senshuid].time_taikai_total * temphosei;
          atai_hosei[senshuid][13] = moto_time_taikai_total * temphosei;
          gakurensenshudata[senshuid].string_racesetumei +=
              "調子補正:調子${gakurensenshudata[senshuid].chousi} → ${(atai_hosei[senshuid][13]).isNegative ? '' : '+'}${(atai_hosei[senshuid][13]).toStringAsFixed(1)}秒\n";
        } else {
          tanihosei = 0.10 / 100.0;
          temphosei = (100 - gakurensenshudata[senshuid].chousi) * tanihosei;
          temphosei *= (kantoku.yobiint2[2].toDouble() / 100.0); //調子適用率
          moto_time_taikai_total =
              gakurensenshudata[senshuid].time_taikai_total;
          gakurensenshudata[senshuid].time_taikai_total +=
              gakurensenshudata[senshuid].time_taikai_total * temphosei;
          atai_hosei[senshuid][13] = moto_time_taikai_total * temphosei;
          gakurensenshudata[senshuid].string_racesetumei +=
              "調子補正:調子${gakurensenshudata[senshuid].chousi} → ${(atai_hosei[senshuid][13]).isNegative ? '' : '+'}${(atai_hosei[senshuid][13]).toStringAsFixed(1)}秒\n";
        }
      }

      // Instruction related
      if ((racebangou >= 0 && racebangou <= 3) || racebangou == 5) {
        if (racebangou == 3) {
          if (gakurensenshudata[senshuid].startchokugotobidasiflag == 1) {
            final lasttime = gakurensenshudata[senshuid].time_taikai_total;
            if (Random().nextInt(100) < gakurensenshudata[senshuid].konjou) {
              gakurensenshudata[senshuid].time_taikai_total *= 0.99;
              gakurensenshudata[senshuid].startchokugotobidasiseikouflag = 1;
            } else {
              gakurensenshudata[senshuid].time_taikai_total *= 1.015;
            }
            final sontokutime =
                gakurensenshudata[senshuid].time_taikai_total - lasttime;
            gakurensenshudata[senshuid].string_racesetumei +=
                "スタート直後飛び出し補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
            atai_hosei[senshuid][9] = sontokutime;
          }
        } else {
          if (gh[0].nowracecalckukan == 0) {
            if (gakurensenshudata[senshuid].startchokugotobidasiflag == 1) {
              final lasttime = gakurensenshudata[senshuid].time_taikai_total;
              if (Random().nextInt(100) < gakurensenshudata[senshuid].konjou) {
                gakurensenshudata[senshuid].time_taikai_total *= 0.99;
                gakurensenshudata[senshuid].startchokugotobidasiseikouflag = 1;
              } else {
                gakurensenshudata[senshuid].time_taikai_total *= 1.015;
              }
              final sontokutime =
                  gakurensenshudata[senshuid].time_taikai_total - lasttime;
              gakurensenshudata[senshuid].string_racesetumei +=
                  "指示(スタート直後飛び出し)補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
              //atai_hosei[senshuid][10] = sontokutime;
              atai_hosei[senshuid][9] = sontokutime;
            }
          } else {
            if (gakurensenshudata[senshuid].sijiflag == 1) {
              final lasttime = gakurensenshudata[senshuid].time_taikai_total;
              if (Random().nextInt(100) < gakurensenshudata[senshuid].konjou) {
                gakurensenshudata[senshuid].time_taikai_total *= 0.99;
                gakurensenshudata[senshuid].sijiseikouflag = 1;
              } else {
                gakurensenshudata[senshuid].time_taikai_total *= 1.015;
              }
              final sontokutime =
                  gakurensenshudata[senshuid].time_taikai_total - lasttime;
              gakurensenshudata[senshuid].string_racesetumei +=
                  "指示(前半突っ込み)補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
              //atai_hosei[senshuid][11] = sontokutime;
              atai_hosei[senshuid][9] = sontokutime;
            } else if (gakurensenshudata[senshuid].sijiflag == 2) {
              if (gakurenunivdata[0].mokuhyojuniwositamawatteruflag[gh[0]
                          .nowracecalckukan -
                      1] ==
                  1) {
                final lasttime = gakurensenshudata[senshuid].time_taikai_total;
                if (Random().nextInt(100) <
                    gakurensenshudata[senshuid].heijousin) {
                  gakurensenshudata[senshuid].time_taikai_total *= 0.999;
                  gakurensenshudata[senshuid].sijiseikouflag = 1;
                } else {
                  gakurensenshudata[senshuid].time_taikai_total *= 1.015;
                }
                final sontokutime =
                    gakurensenshudata[senshuid].time_taikai_total - lasttime;
                gakurensenshudata[senshuid].string_racesetumei +=
                    "指示(前半抑え)補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
                //atai_hosei[senshuid][12] = sontokutime;
                atai_hosei[senshuid][9] = sontokutime;
              } else {
                final lasttime = gakurensenshudata[senshuid].time_taikai_total;
                if (Random().nextInt(100) <
                    gakurensenshudata[senshuid].heijousin) {
                  gakurensenshudata[senshuid].time_taikai_total *= 0.997;
                  gakurensenshudata[senshuid].sijiseikouflag = 1;
                } else {
                  gakurensenshudata[senshuid].time_taikai_total *= 1.005;
                }
                final sontokutime =
                    gakurensenshudata[senshuid].time_taikai_total - lasttime;
                gakurensenshudata[senshuid].string_racesetumei +=
                    "指示(前半抑え)補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
                //atai_hosei[senshuid][12] = sontokutime;
                atai_hosei[senshuid][9] = sontokutime;
              }
            } else {
              if (gakurenunivdata[0].mokuhyojuniwositamawatteruflag[gh[0]
                          .nowracecalckukan -
                      1] ==
                  1) {
                final lasttime = gakurensenshudata[senshuid].time_taikai_total;
                gakurensenshudata[senshuid].time_taikai_total *= 1.008;
                final sontokutime =
                    gakurensenshudata[senshuid].time_taikai_total - lasttime;
                gakurensenshudata[senshuid].string_racesetumei +=
                    "目標順位下回って突っ込み補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
                //atai_hosei[senshuid][13] = sontokutime;
                atai_hosei[senshuid][9] = sontokutime;
              }
            }
          }
        }
      }
    }
  }

  // Group run correction for November Ekiden qualifier and 1st section of each Ekiden
  /*if (racebangou == 3 ||
      (((racebangou >= 0 && racebangou <= 2) || racebangou == 5) &&
          gh[0].nowracecalckukan == 0)) {
    int maxkarisuma = -1;
    int pacemaker_senshu_id = -1;
    double kijuntime = 0.0;

    // Filter players who are in this section and not doing an early burst
    final entryFilteredsenshudata = gakurensenshudata
        .where(
          (s) =>
              s.entrykukan_race[racebangou][s.gakunen - 1] ==
                  gh[0].nowracecalckukan &&
              s.startchokugotobidasiflag != 1,
        )
        .toList();

    if (entryFilteredsenshudata.isNotEmpty) {
      // Find the pacemaker (highest charisma)
      for (var senshu in entryFilteredsenshudata) {
        if (senshu.karisuma > maxkarisuma) {
          maxkarisuma = senshu.karisuma;
          kijuntime = senshu.time_taikai_total;
          pacemaker_senshu_id = senshu
              .hashCode; // Use hashCode as a unique identifier for comparison
        }
      }

      for (var senshu in entryFilteredsenshudata) {
        if (senshu.startchokugotobidasiflag != 1) {
          if (senshu.hashCode != pacemaker_senshu_id) {
            // Check if it's not the pacemaker
            if (senshu.time_taikai_total < kijuntime) {
              // If own pace is faster than group pace
              final lasttime = senshu.time_taikai_total;
              senshu.time_taikai_total =
                  (kijuntime + senshu.time_taikai_total) / 2.0;
              final sontokutime = senshu.time_taikai_total - lasttime;
              senshu.string_racesetumei +=
                  "集団のペースは自分の本来のペースよりも遅かった→タイム損(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
              atai_hosei[senshu.id][14] = sontokutime;
            } else if (senshu.time_taikai_total > kijuntime) {
              if (kijuntime * 1.01 > senshu.time_taikai_total) {
                // Own pace is slower, but manageable
                final lasttime = senshu.time_taikai_total;
                senshu.time_taikai_total =
                    (kijuntime + senshu.time_taikai_total) / 2.0;
                final sontokutime = senshu.time_taikai_total - lasttime;
                senshu.string_racesetumei +=
                    "集団のペースは自分の本来のペースよりも速かったが速すぎるというほどではなかった→少しタイム得(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
                atai_hosei[senshu.id][14] = sontokutime;
              } else if (kijuntime * 1.03 > senshu.time_taikai_total) {
                // Own pace is much slower, but managed to avoid collapse
                senshu.string_racesetumei +=
                    "集団のペースは自分の本来のペースよりも速かったが後半の大失速は免れた→タイム損得なし\n";
              } else {
                // Group pace is too fast, collapse scenario
                final lasttime = senshu.time_taikai_total;
                senshu.time_taikai_total *= 1.025;
                final sontokutime = senshu.time_taikai_total - lasttime;
                senshu.string_racesetumei +=
                    "集団のペースは自分の本来のペースよりも速すぎた→無理して付いていって後半大失速→大きくタイム損(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
                atai_hosei[senshu.id][14] = sontokutime;
              }
            }
          } else {
            senshu.string_racesetumei += "集団のペースを自分で作った\n";
          }
        }
      }
    }
  }*/

  //////////////////
  ///
  ////
  // 対象となる列（8番目の列）の値をすべて抽出
  /*List<double> columnValues = [];
  for (int i = 0; i < idshuruisuu; i++) {
    columnValues.add(atai_hosei[i][8]);
  }
  // 抽出した値の中から最小値を求める
  double minValue = columnValues.reduce((a, b) => a < b ? a : b);
  // 最小値との差分を計算し、元の位置に代入する
  for (int i = 0; i < idshuruisuu; i++) {
    atai_hosei[i][8] = atai_hosei[i][8] - minValue;
  }
  ////
  double hosei_total = 0.0;
  double total_total = 0.0;
  for (int i = 0; i < idshuruisuu; i++) {
    if (gakurensenshudata[i]
            .entrykukan_race[racebangou][gakurensenshudata[i].gakunen - 1] ==
        gh[0].nowracecalckukan) {
      hosei_total = 0.0;
      total_total = 0.0;
      for (int j = 0; j < hoseishuruisuu - 2; j++) {
        if (atai_hosei[i][j] != TEISUU.DEFAULTTIME) {
          if (j == 8) {
            total_total += atai_hosei[i][j];
          } else {
            total_total += atai_hosei[i][j];
            hosei_total += atai_hosei[i][j];
          }
        }
      }
      atai_hosei[i][15] = hosei_total;
      atai_hosei[i][16] = total_total;
    }
  }
  //補正値順位検索
  // 順位付けのロジック
  for (int j = 0; j < hoseishuruisuu; j++) {
    // 1. 各列の値を抽出し、元のインデックスとペアにする
    // 例：[[値, 0], [値, 1], [値, 2], ...]
    List<List<Object>> columnWithIndices = [];
    for (int i = 0; i < idshuruisuu; i++) {
      columnWithIndices.add([atai_hosei[i][j], i]);
    }
    // 2. 値の小さい順にソートする
    // `sort` メソッドを使用し、第1要素（値）に基づいて比較
    columnWithIndices.sort(
      (a, b) => (a[0] as double).compareTo(b[0] as double),
    );
    // 3. ソートされたリストから順位を決定し、`juni_hosei`に代入
    for (int i = 0; i < idshuruisuu; i++) {
      // ソートされたリストの要素から元のインデックスを取得
      int originalIndex = columnWithIndices[i][1] as int;
      // 順位を代入（0が1位）
      juni_hosei[originalIndex][j] = i;
    }
  }
  //各補正をstring_racesetumeiに代入
  List<bool> hoseimukankeiflag = List.filled(hoseishuruisuu, true);
  for (int j = 0; j < hoseishuruisuu; j++) {
    hoseimukankeiflag[j] = true;
    for (var senshuid = 0; senshuid < gakurensenshudata.length; senshuid++) {
      if (gakurensenshudata[senshuid]
              .entrykukan_race[racebangou][gakurensenshudata[senshuid].gakunen -
              1] ==
          gh[0].nowracecalckukan) {
        if (atai_hosei[senshuid][j] > 0.001 ||
            atai_hosei[senshuid][j] < -0.001) {
          hoseimukankeiflag[j] = false;
          break;
        }
      }
    }
  }
  for (var senshuid = 0; senshuid < gakurensenshudata.length; senshuid++) {
    if (gakurensenshudata[senshuid]
            .entrykukan_race[racebangou][gakurensenshudata[senshuid].gakunen -
            1] ==
        gh[0].nowracecalckukan) {
      gakurensenshudata[senshuid].string_racesetumei +=
          name_hosei[8] +
          " ${juni_hosei[senshuid][8] + 1}位:${atai_hosei[senshuid][8].isNegative ? '' : '+'}${atai_hosei[senshuid][8].toStringAsFixed(1)}秒\n";
      gakurensenshudata[senshuid].string_racesetumei +=
          name_hosei[15] +
          " ${juni_hosei[senshuid][15] + 1}位:${atai_hosei[senshuid][15].isNegative ? '' : '+'}${atai_hosei[senshuid][15].toStringAsFixed(1)}秒\n";
      gakurensenshudata[senshuid].string_racesetumei +=
          name_hosei[16] +
          " ${juni_hosei[senshuid][16] + 1}位:${atai_hosei[senshuid][16].isNegative ? '' : '+'}${atai_hosei[senshuid][16].toStringAsFixed(1)}秒(";

      gakurensenshudata[senshuid].string_racesetumei +=
          TimeDate.timeToFunByouString(atai_hosei[senshuid][16] + minValue) +
          ")\n";
      gakurensenshudata[senshuid].string_racesetumei +=
          "逆算誤差(トータルー走破タイム):${((atai_hosei[senshuid][16] + minValue) - gakurensenshudata[senshuid].time_taikai_total).isNegative ? '' : '+'}${((atai_hosei[senshuid][16] + minValue) - gakurensenshudata[senshuid].time_taikai_total).toStringAsFixed(3)}秒\n";

      for (int j = 0; j < hoseishuruisuu; j++) {
        if (j < 8) {
          if (hoseimukankeiflag[j] == true) {
            if (j == 3) {
            } else {
              if (gh[0].nouryokumieruflag[nouryokumieruflagIndex_hosei[j]] ==
                  1) {
                gakurensenshudata[senshuid].string_racesetumei +=
                    name_hosei[j] + " 無\n";
              }
            }
          } else {
            if (j == 3) {
              if (atai_hosei[senshuid][j] < -0.0001) {
                gakurensenshudata[senshuid].string_racesetumei +=
                    name_hosei[j] +
                    ":${atai_hosei[senshuid][j].isNegative ? '' : '+'}${atai_hosei[senshuid][j].toStringAsFixed(1)}秒\n";
              }
            } else {
              if (gh[0].nouryokumieruflag[nouryokumieruflagIndex_hosei[j]] ==
                  1) {
                gakurensenshudata[senshuid].string_racesetumei +=
                    name_hosei[j] +
                    " ${juni_hosei[senshuid][j] + 1}位:${atai_hosei[senshuid][j].isNegative ? '' : '+'}${atai_hosei[senshuid][j].toStringAsFixed(1)}秒\n";
              }
            }
          }
        }
      }
    }
  }*/

  //1区の補正
  final albumBox = Hive.box<Album>('albumBox');
  final Album album = albumBox.get('AlbumData')!;
  if (gh[0].nowracecalckukan == 0) {
    for (var senshuid = 0; senshuid < gakurensenshudata.length; senshuid++) {
      if (gakurensenshudata[senshuid]
              .entrykukan_race[racebangou][gakurensenshudata[senshuid].gakunen -
              1] ==
          gh[0].nowracecalckukan) {
        if (TEISUU.STARTTOBIDASIKAKURITU >
            (DateTime.now().microsecondsSinceEpoch % 100)) {
          gakurensenshudata[senshuid].startchokugotobidasiflag = 1;
        }
        if (gakurensenshudata[senshuid].startchokugotobidasiflag != 1) {
          gakurensenshudata[senshuid].time_taikai_total =
              (gakurensenshudata[senshuid].time_taikai_total +
                  album.yobiint5.toDouble()) /
              2.0;
        } else {
          if (Random().nextInt(100) < gakurensenshudata[senshuid].konjou) {
            gakurensenshudata[senshuid].time_taikai_total *= 0.99;
            gakurensenshudata[senshuid].startchokugotobidasiseikouflag = 1;
          } else {
            gakurensenshudata[senshuid].time_taikai_total *= 1.015;
          }
        }
      }
    }
  }

  // Assignment of times and rankings
  for (var senshuid = 0; senshuid < gakurensenshudata.length; senshuid++) {
    if (gakurensenshudata[senshuid]
            .entrykukan_race[racebangou][gakurensenshudata[senshuid].gakunen -
            1] ==
        gh[0].nowracecalckukan) {
      if ((racebangou >= 0 && racebangou <= 3) || racebangou == 5) {
        //学連選抜モチベーション低下補正
        if (gh[0].nowracecalckukan != 0) {
          double hosei = album.yobiint4 * 0.003;
          /*if (album.yobiint4 == 0) {
            hosei = 0.0;
          } else if (album.yobiint4 == 1) {
            hosei = 0.005;
          } else if (album.yobiint4 == 2) {
            hosei = 0.01;
          } else if (album.yobiint4 == 3) {
            hosei = 0.015;
          } else {
            //念の為
            hosei = 0.0;
          }*/
          gakurensenshudata[senshuid].time_taikai_total *= (1.00 + hosei);
        }
        var temptime_assign = gakurensenshudata[senshuid].time_taikai_total;
        gakurenunivdata[0].time_taikai_total[gh[0].nowracecalckukan] +=
            temptime_assign;
      }
    }
  }

  if (racebangou >= 0 && racebangou <= 5) {
    // Sectional rank
    /*final kukangotojun = sortedunivdata.toList()
      ..sort(
        (a, b) => a.time_taikai_total[gh[0].nowracecalckukan].compareTo(
          b.time_taikai_total[gh[0].nowracecalckukan],
        ),
      );

    for (var i = 0; i < TEISUU.UNIVSUU; i++) {
      kukangotojunsortedunivdata[i].kukanjuni_taikai[gh[0].nowracecalckukan] =
          i;
    }*/

    //学連選抜のunivdataに区間順位と区間タイムを代入しちゃう
    if (gh[0].nowracecalckukan == 0) {
      final kukangotojunsortedunivdata = sortedunivdata.toList()
        ..sort(
          (a, b) => a.time_taikai_total[gh[0].nowracecalckukan].compareTo(
            b.time_taikai_total[gh[0].nowracecalckukan],
          ),
        );
      for (var i = 0; i < TEISUU.UNIVSUU; i++) {
        if (kukangotojunsortedunivdata[i].time_taikai_total[gh[0]
                .nowracecalckukan] >
            gakurenunivdata[0].time_taikai_total[gh[0].nowracecalckukan]) {
          print(
            "nowracecalckukan=${gh[0].nowracecalckukan} i=${i} kukangotojunsortedunivdata=${_timeToMinuteSecondString(kukangotojunsortedunivdata[i].time_taikai_total[gh[0].nowracecalckukan])} gakurenunivdata=${_timeToMinuteSecondString(gakurenunivdata[0].time_taikai_total[gh[0].nowracecalckukan])}",
          );
          gakurenunivdata[0].kukanjuni_taikai[gh[0].nowracecalckukan] = i;
          break;
        }
      }
    } else {
      final kukangotojunsortedunivdata = sortedunivdata.toList()
        ..sort(
          (a, b) =>
              (a.time_taikai_total[gh[0].nowracecalckukan] -
                      a.time_taikai_total[gh[0].nowracecalckukan - 1])
                  .compareTo(
                    (b.time_taikai_total[gh[0].nowracecalckukan] -
                        b.time_taikai_total[gh[0].nowracecalckukan - 1]),
                  ),
        );
      for (var i = 0; i < TEISUU.UNIVSUU; i++) {
        if (kukangotojunsortedunivdata[i].time_taikai_total[gh[0]
                    .nowracecalckukan] -
                kukangotojunsortedunivdata[i]
                    .time_taikai_total[gh[0].nowracecalckukan - 1] >
            gakurenunivdata[0].time_taikai_total[gh[0].nowracecalckukan]) {
          /*print(
          "nowracecalckukan=${gh[0].nowracecalckukan} i=${i} kukangotojunsortedunivdata=${_timeToMinuteSecondString(kukangotojunsortedunivdata[i].time_taikai_total[gh[0].nowracecalckukan])} gakurenunivdata=${_timeToMinuteSecondString(gakurenunivdata[0].time_taikai_total[gh[0].nowracecalckukan])}",
        );*/
          gakurenunivdata[0].kukanjuni_taikai[gh[0].nowracecalckukan] = i;
          break;
        }
      }
    }

    //ここで個人の区間タイムも記録しちゃう
    for (var senshuid = 0; senshuid < gakurensenshudata.length; senshuid++) {
      if (gakurensenshudata[senshuid]
              .entrykukan_race[racebangou][gakurensenshudata[senshuid].gakunen -
              1] ==
          gh[0].nowracecalckukan) {
        gakurensenshudata[senshuid]
            .kukantime_race[racebangou][gakurensenshudata[senshuid].gakunen -
            1] = gakurensenshudata[senshuid]
            .time_taikai_total;
        break;
      }
    }

    // Update cumulative time for subsequent sections
    if (gh[0].nowracecalckukan > 0) {
      gakurenunivdata[0].time_taikai_total[gh[0].nowracecalckukan] +=
          gakurenunivdata[0].time_taikai_total[gh[0].nowracecalckukan - 1];
    }

    //学連選抜のunivdataに区間ごとの通過順位を代入しちゃう
    final tuukajunsortedunivdata = sortedunivdata.toList()
      ..sort(
        (a, b) => a.time_taikai_total[gh[0].nowracecalckukan].compareTo(
          b.time_taikai_total[gh[0].nowracecalckukan],
        ),
      );
    for (var i = 0; i < TEISUU.UNIVSUU; i++) {
      if (tuukajunsortedunivdata[i].time_taikai_total[gh[0].nowracecalckukan] >
          gakurenunivdata[0].time_taikai_total[gh[0].nowracecalckukan]) {
        gakurenunivdata[0].tuukajuni_taikai[gh[0].nowracecalckukan] = i;
        break;
      }
    }
    //学連選抜は毎回10位を目標ということにしちゃう
    if (gakurenunivdata[0].tuukajuni_taikai[gh[0].nowracecalckukan] < 10) {
      gakurenunivdata[0].mokuhyojuniwositamawatteruflag[gh[0]
              .nowracecalckukan] =
          0;
    } else {
      gakurenunivdata[0].mokuhyojuniwositamawatteruflag[gh[0]
              .nowracecalckukan] =
          1;
    }

    // Cumulative rank at section end
    /*final tuukajunsortedunivdata = sortedunivdata.toList()
      ..sort(
        (a, b) => a.time_taikai_total[gh[0].nowracecalckukan].compareTo(
          b.time_taikai_total[gh[0].nowracecalckukan],
        ),
      );
    for (var i = 0; i < TEISUU.UNIVSUU; i++) {
      tuukajunsortedunivdata[i].tuukajuni_taikai[gh[0].nowracecalckukan] = i;
    }*/

    // Check if team goal rank is not met
    /*for (var i = 0; i < TEISUU.UNIVSUU; i++) {
      if (tuukajunsortedunivdata[i].mokuhyojuni[racebangou] < i) {
        tuukajunsortedunivdata[i].mokuhyojuniwositamawatteruflag[gh[0]
                .nowracecalckukan] =
            1;
      } else {
        tuukajunsortedunivdata[i].mokuhyojuniwositamawatteruflag[gh[0]
                .nowracecalckukan] =
            0;
      }
    }*/

    //ここで個人の区間順位も+100で記録しちゃう
    for (var senshuid = 0; senshuid < gakurensenshudata.length; senshuid++) {
      if (gakurensenshudata[senshuid]
              .entrykukan_race[racebangou][gakurensenshudata[senshuid].gakunen -
              1] ==
          gh[0].nowracecalckukan) {
        gakurensenshudata[senshuid]
                .kukanjuni_race[racebangou][gakurensenshudata[senshuid]
                    .gakunen -
                1] =
            gakurenunivdata[0].kukanjuni_taikai[gh[0].nowracecalckukan] + 100;
        break;
      }
    }
  }

  await gakurenunivdata[0].save();
  for (int i = 0; i < gakurensenshudata.length; i++) {
    await gakurensenshudata[i].save();
  }

  //gh[0].nowracecalckukan++;

  final endTime = DateTime.now();
  final timeInterval = endTime.difference(startTime).inMicroseconds / 1000000.0;
  print("RaceCalc_gakuren処理時間: ${_timeToMinuteSecondString(timeInterval)}経過");
}
