import 'dart:math'; // Randomクラスを使用するため
//import 'package:flutter/services.dart';
//import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuモデルのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataモデルのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataモデルのインポート
import 'package:ekiden/constants.dart'; // 定数のインポート

//import 'package:ekiden/kansuu/time_date.dart'; // 時間・日付ユーティリティのインポート
//import 'package:ekiden/kansuu/EntryCalc.dart';
import 'package:ekiden/kansuu/TimeDesugiHoseiHoseitime.dart';
import 'package:ekiden/kansuu/SpurtRyokuHoseitime.dart';
import 'package:ekiden/kansuu/ChoukyoriNebariHoseitime.dart';
import 'package:ekiden/kansuu/univkosei.dart';
import 'package:ekiden/kantoku_data.dart';

// このメソッドは、各区間の走破タイム（秒単位のdouble型）を計算します。
Future<double> runTrialCalculation(
  int senshuid,
  int i_kukan,
  Ghensuu currentGhensuu,
  List<SenshuData> sortedsenshudata,
  List<UnivData> sortedUnivData,
  KantokuData kantoku,
  //Ghensuu currentGhensuu,
) async {
  if (senshuid < 0 || senshuid >= sortedsenshudata.length) {
    senshuid = 0;
  }

  double kotaetime = 0.0;
  final double tempkyori = currentGhensuu
      .kyori_taikai_kukangoto[currentGhensuu.hyojiracebangou][i_kukan];
  final double kyoriwariai_nobori =
      currentGhensuu.kyoriwariainobori_taikai_kukangoto[currentGhensuu
          .hyojiracebangou][i_kukan];
  final double kyoriwariai_kudari =
      currentGhensuu.kyoriwariaikudari_taikai_kukangoto[currentGhensuu
          .hyojiracebangou][i_kukan];
  final double heikinkoubai_nobori =
      currentGhensuu.heikinkoubainobori_taikai_kukangoto[currentGhensuu
          .hyojiracebangou][i_kukan];
  final double heikinkoubai_kudari =
      currentGhensuu.heikinkoubaikudari_taikai_kukangoto[currentGhensuu
          .hyojiracebangou][i_kukan];
  final int noborikudari_kirikaekaisuu =
      currentGhensuu.noborikudarikirikaekaisuu_taikai_kukangoto[currentGhensuu
          .hyojiracebangou][i_kukan];

  double hoseitotal = 0.0;
  //final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  //final KantokuData kantoku = kantokuBox.get('KantokuData')!;
  //強化練習強度を取得
  final int kyoudo = kantoku.yobiint2[16];
  //強化練習番号を取得
  final int trainingNum = sortedsenshudata[senshuid].kaifukuryoku;
  // 関数を呼び出してマップを取得(大学の個性)
  Map<AbilityType, int> abilityValues = getAbilitySettingsForUniv(
    sortedsenshudata[senshuid].univid,
  );
  // 設定値を取得 (0-9)
  int tempSetting = 0;
  tempSetting = abilityValues[AbilityType.nagakyoriNebari] ?? 0;
  if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
  int set_nebari = 150 - tempSetting * 10;
  set_nebari =
      ((set_nebari.toDouble() / 100.0) *
              sortedsenshudata[senshuid].choukyorinebari.toDouble())
          .toInt();
  if (trainingNum == 2) {
    //set_nebari += kyoudo * 7 ~/ 2;
    set_nebari += kyoudo * 4 ~/ 2;
  } else if (trainingNum == 0) {
    set_nebari += kyoudo;
  }
  if (set_nebari < 1) set_nebari = 1;
  tempSetting = abilityValues[AbilityType.spurtPower] ?? 0;
  if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
  int set_spurt = 150 - tempSetting * 10;
  set_spurt =
      ((set_spurt.toDouble() / 100.0) *
              sortedsenshudata[senshuid].spurtryoku.toDouble())
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
  if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
  int set_nobori = 150 - tempSetting * 10;
  set_nobori =
      ((set_nobori.toDouble() / 100.0) *
              sortedsenshudata[senshuid].noboritekisei.toDouble())
          .toInt();
  if (trainingNum == 3) {
    set_nobori += kyoudo * 7;
  } else if (trainingNum == 0) {
    set_nobori += kyoudo;
  }
  if (set_nobori < 1) set_nobori = 1;
  tempSetting = abilityValues[AbilityType.kudariTekisei] ?? 0;
  if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
  int set_kudari = 150 - tempSetting * 10;
  set_kudari =
      ((set_kudari.toDouble() / 100.0) *
              sortedsenshudata[senshuid].kudaritekisei.toDouble())
          .toInt();
  if (trainingNum == 4) {
    set_kudari += kyoudo * 7;
  } else if (trainingNum == 0) {
    set_kudari += kyoudo;
  }
  if (set_kudari < 1) set_kudari = 1;
  tempSetting = abilityValues[AbilityType.upDownTaiouryoku] ?? 0;
  if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
  int set_updown = 150 - tempSetting * 10;
  set_updown =
      ((set_updown.toDouble() / 100.0) *
              sortedsenshudata[senshuid].noborikudarikirikaenouryoku.toDouble())
          .toInt();
  if (trainingNum == 5) {
    set_updown += kyoudo * 7;
  } else if (trainingNum == 0) {
    set_updown += kyoudo;
  }
  if (set_updown < 1) set_updown = 1;
  tempSetting = abilityValues[AbilityType.roadTekisei] ?? 0;
  if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
  int set_road = 150 - tempSetting * 10;
  set_road =
      ((set_road.toDouble() / 100.0) *
              sortedsenshudata[senshuid].tandokusou.toDouble())
          .toInt();
  if (trainingNum == 2) {
    //set_road += kyoudo * 7 ~/ 2;
    set_road += kyoudo * 4 ~/ 2;
  } else if (trainingNum == 0) {
    set_road += kyoudo;
  }
  if (set_road < 1) set_road = 1;
  tempSetting = abilityValues[AbilityType.paceHendoTaiouryoku] ?? 0;
  if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
  int set_pacehendou = 150 - tempSetting * 10;
  set_pacehendou =
      ((set_pacehendou.toDouble() / 100.0) *
              sortedsenshudata[senshuid].paceagesagetaiouryoku.toDouble())
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

  int b_int = (sortedsenshudata[senshuid].b * 10000.0).round();
  int a_int = (sortedsenshudata[senshuid].a * 1000000000.0).round();
  int a_min_int =
      (b_int * b_int * 0.0333 -
              b_int * 114.25 +
              sortedsenshudata[senshuid].magicnumber)
          .round();
  int sa = a_int - a_min_int;
  int new_a_min_int =
      (newbdouble * newbdouble * 0.0333 -
              newbdouble * 114.25 +
              sortedsenshudata[senshuid].magicnumber)
          .round();
  int new_a_int = new_a_min_int + sa;

  double double_a = new_a_int * 0.000000001;
  double double_b = newbdouble * 0.0001;
  returntime = double_a * kyori * kyori + double_b * kyori;

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
    if (currentGhensuu.hyojiracebangou <= 2 ||
        currentGhensuu.hyojiracebangou == 5) {
      chousei_kukangoto =
          kantoku.yobiint5[i_kukan + (currentGhensuu.hyojiracebangou + 3) * 10]
              .toDouble() /
          2.0;
    }
    double chousei = chousei_zentai + chousei_kukangoto;
    returntime *= (100.0 + chousei) / 100.0;
  }

  // Excess time correction
  if (sortedsenshudata[senshuid].hirou == 1) {
    returntime += TimeDesugiHoseiHoseitime_ryuugakusei(
      kyori: tempkyori,
      mototime: returntime,
    );
    if (sortedUnivData[9].name_tanshuku == "1") {
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
    if (sortedUnivData[9].name_tanshuku == "1") {
      returntime = adjustTargetedFastTime(
        timeMoto: returntime,
        distanceM: tempkyori,
      );
    }
  }

  //sortedsenshudata[senshuid].speed = tempkyori / returntime;
  double double_speed = tempkyori / returntime;

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
  double_speed = double_speed * hosei_total_altitude;
  kotaetime = tempkyori / double_speed;

  int temptandokusou = 0;
  int temppaceagesagetaiouryoku = 0;
  double tekiyouritu_tandokusouhosei = 1.0;
  double tekiyouritu_paceagesagehosei = 1.0;
  // Solo Run / Pace Adjustment Adaptability
  if ((currentGhensuu.hyojiracebangou >= 6 &&
          currentGhensuu.hyojiracebangou <= 8) ||
      (currentGhensuu.hyojiracebangou >= 10 &&
          currentGhensuu.hyojiracebangou <= 16)) {
    if (currentGhensuu.hyojiracebangou == 8 ||
        currentGhensuu.hyojiracebangou == 12 ||
        currentGhensuu.hyojiracebangou == 15) {
      temptandokusou = set_road;
      temppaceagesagetaiouryoku = 100;
    } else if (currentGhensuu.hyojiracebangou == 13 ||
        currentGhensuu.hyojiracebangou == 14) {
      temptandokusou = 100;
      temppaceagesagetaiouryoku = 100;
    } else {
      temptandokusou = 100;
      temppaceagesagetaiouryoku = set_pacehendou;
    }
  }
  if (currentGhensuu.hyojiracebangou >= 0 &&
      currentGhensuu.hyojiracebangou <= 5) {
    if ((currentGhensuu.hyojiracebangou != 4 && i_kukan == 0) ||
        currentGhensuu.hyojiracebangou == 3) {
      temptandokusou = 100;
      temppaceagesagetaiouryoku = set_pacehendou;
    } else if (currentGhensuu.hyojiracebangou == 4 ||
        (i_kukan >= 1 && i_kukan <= 2)) {
      temptandokusou = set_road;
      tekiyouritu_tandokusouhosei = 0.5;
      temppaceagesagetaiouryoku = set_pacehendou;
      tekiyouritu_paceagesagehosei = 0.5;
    } else {
      temptandokusou = set_road;
      temppaceagesagetaiouryoku = 100;
    }
  }

  // Apply total correction
  kotaetime += kotaetime * hoseitotal;
  double tanihosei = 0.0;
  double temphosei = 0.0;

  // Solo running correction
  tanihosei = 0.03 / 100.0;
  temphosei = (100 - temptandokusou) * tanihosei;
  temphosei *= tekiyouritu_tandokusouhosei;
  kotaetime += kotaetime * temphosei;
  if (currentGhensuu.hyojiracebangou >= 0 &&
      currentGhensuu.hyojiracebangou <= 5) {}

  // Pace adjustment adaptability correction
  tanihosei = 0.03 / 100.0;
  temphosei = (100 - temppaceagesagetaiouryoku) * tanihosei;
  temphosei *= tekiyouritu_paceagesagehosei;
  kotaetime += kotaetime * temphosei;
  if (currentGhensuu.hyojiracebangou >= 0 &&
      currentGhensuu.hyojiracebangou <= 5) {}

  // Long-distance endurance correction
  final choukyoriHosei = ChoukyoriNebariHoseitime(
    kyori: tempkyori,
    choukyorinebari: set_nebari,
    zentaiyokuseiti: kantoku.yobiint2[13],
    //senshuid: senshuid,
    //sortedsenshudata: sortedsenshudata,
  );
  kotaetime += choukyoriHosei;
  if (currentGhensuu.hyojiracebangou >= 0 &&
      currentGhensuu.hyojiracebangou <= 5) {}

  // Sprint power correction
  final spurtHosei = SpurtRyokuHoseitime(
    kyori: tempkyori,
    spurtRyoku: set_spurt,
    //senshuid: senshuid,
    //sortedsenshudata: sortedsenshudata,
  );
  kotaetime += spurtHosei;
  if (currentGhensuu.hyojiracebangou >= 0 &&
      currentGhensuu.hyojiracebangou <= 5) {}

  //答えをそのまま見せるわけにはいかないので濁す処理
  double minPercentage = -0.005;
  double maxPercentage = 0.005;
  double randomPercentage =
      Random().nextDouble() * (maxPercentage - minPercentage) + minPercentage;

  // kotaeTimeにランダムな値を加える
  kotaetime = kotaetime * (1 + randomPercentage);

  // 値を返します
  //await Future.delayed(const Duration(milliseconds: 500));
  return kotaetime;
}
