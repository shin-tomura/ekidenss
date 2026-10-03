import 'dart:math'; // Randomクラスを使用するため
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのインポート
import 'package:ekiden/kansuu/RaceCalc_gakuren.dart';
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
import 'package:ekiden/kansuu/ChoukyoriNebariHoseitime.dart';
import 'package:ekiden/kansuu/SpurtRyokuHoseitime.dart';
import 'package:ekiden/kansuu/TimeDesugiHoseiHoseitime.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/Shuudansou.dart';
//import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/univkosei.dart';
import 'package:ekiden/kansuu/ToujituHenkou_com.dart';
import 'package:ekiden/kansuu/mokuhyou_hosei.dart';
import 'package:ekiden/kansuu/chousi_keiken_hosei.dart';
import 'package:ekiden/kansuu/nouryoku_eikyodo.dart';

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

Future<void> RaceCalc({
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
  double HoseimaeTime = 0.0;
  /////わざと一旦閉じる
  //var close_rsenshubox = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');
  //close_rsenshubox.close();

  // Hive.box() を使って、既に開いているBoxを取得
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  // Boxからデータを読み込む
  final KantokuData kantoku = kantokuBox.get('KantokuData')!;
  // 目標順位・指示の補正の強さ(全大学共通の設定。1.8.2)
  final HoseiTsuyosa hoseiTsuyosa = HoseiTsuyosa.fromKantoku(kantoku);
  // 能力のタイムへの影響度(全大学共通の設定。駅伝と駅伝予選だけ。1.8.2)
  final NouryokuEikyodo nouryokuEikyodo = NouryokuEikyodo.forRace(
    kantoku,
    racebangou,
  );

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
  double temptandokusou = 0; // ロード適性(影響度を反映した小数。1.8.2から)
  double temppaceagesagetaiouryoku = 0; // ペース変動対応力(同じ)
  var tekiyouritu_tandokusouhosei = 1.0;
  var tekiyouritu_paceagesagehosei = 1.0;
  int hoseishuruisuu = 17;
  int idshuruisuu = TEISUU.SENSHUSUU_TOTAL;

  List<double> timesa_free_shuudan = List.filled(idshuruisuu, 0.0);

  //影響度指数用変数 tensuu[選手id][下記の種類番号]
  //0調子、1指示・メンタル、2集団走(1区のみ)、3基本走力、4登り、5下り、6アップダウン、7経験、8ロード適正、9ペース変動、10長距離粘り、11スパート力
  List<List<double>> tensuu = List.generate(
    TEISUU.SENSHUSUU_TOTAL,
    (i) => List.generate(12, (j) => 0.0),
  );

  //補正種類番号
  //0登り補正、1下り補正、2アップダウン対応力補正、3経験補正、4ロード適性補正、5ペース変動対応力補正、6長距離粘り補正、7スパート力補正
  //8基本走力差、9指示補正、10〜12予備、13調子補正、14集団走補正、15補正計、16基本走力差+補正計
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
  print("RaceCalcに入った");

  if (racebangou >= 0 && racebangou <= 5) {
    if (gh[0].nowracecalckukan == 0) {
      for (var i = 0; i < TEISUU.UNIVSUU; i++) {
        if (sortedunivdata[i].taikaientryflag[racebangou] == 1) {
          for (var ii = 0; ii < TEISUU.SUU_MAXKUKANSUU; ii++) {
            sortedunivdata[i].time_taikai_total[ii] = 0.0;
          }
        } else {
          for (var ii = 0; ii < TEISUU.SUU_MAXKUKANSUU; ii++) {
            sortedunivdata[i].time_taikai_total[ii] =
                TEISUU.DEFAULTTIME * (ii + 1);
          }
        }
      }
    }
  }

  if ((racebangou >= 6 && racebangou <= 8) ||
      (racebangou >= 10 && racebangou <= 17)) {
    if (racebangou == 6 || racebangou == 10) {
      tempkyori = 5000.0;
    } else if (racebangou == 7 ||
        racebangou == 11 ||
        (racebangou >= 13 && racebangou <= 16)) {
      tempkyori = 10000.0;
    } else if (racebangou == 8 || racebangou == 12) {
      tempkyori = 21097.5;
    } else if (racebangou == 17) {
      tempkyori = 42195;
    }

    if (racebangou == 13) {
      kyoriwariai_nobori = 1.0;
      kyoriwariai_kudari = 0.0;
      heikinkoubai_nobori = 0.06;
      heikinkoubai_kudari = 0.0;
      noborikudari_kirikaekaisuu = 0;
    } else if (racebangou == 14) {
      kyoriwariai_nobori = 0.0;
      kyoriwariai_kudari = 1.0;
      heikinkoubai_nobori = 0.0;
      heikinkoubai_kudari = -0.06;
      noborikudari_kirikaekaisuu = 0;
    } else if (racebangou == 16) {
      kyoriwariai_nobori = 0.4;
      kyoriwariai_kudari = 0.4;
      heikinkoubai_nobori = 0.01;
      heikinkoubai_kudari = -0.01;
      noborikudari_kirikaekaisuu = 100;
    } else {
      kyoriwariai_nobori = 0.0;
      kyoriwariai_kudari = 0.0;
      heikinkoubai_nobori = 0.0;
      heikinkoubai_kudari = 0.0;
      noborikudari_kirikaekaisuu = 0;
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

  // コンピュータ大学の当日変更(当日変更画面を通らなかった場合はここで実行)
  if ((racebangou >= 0 && racebangou <= 2) || racebangou == 5) {
    if (gh[0].nowracecalckukan == 0) {
      await comToujituHenkou(
        racebangou: racebangou,
        day: racebangou == 2 ? 1 : 0,
        gh: gh,
        sortedUnivData: sortedunivdata,
        sortedSenshuData: sortedsenshudata,
      );
      // 区間エントリーの整合性チェックと自動修復(区間空白・区間重複の防止)
      await kukanSeigouseiShuufuku(
        racebangou: racebangou,
        gh: gh,
        sortedUnivData: sortedunivdata,
        sortedSenshuData: sortedsenshudata,
        kukannaiJuniSaikeisan: true,
      );
    } else if (racebangou == 2 && gh[0].nowracecalckukan == 5) {
      await comToujituHenkou(
        racebangou: racebangou,
        day: 2,
        gh: gh,
        sortedUnivData: sortedunivdata,
        sortedSenshuData: sortedsenshudata,
      );
      // 区間エントリーの整合性チェックと自動修復(復路のみ)
      await kukanSeigouseiShuufuku(
        racebangou: racebangou,
        gh: gh,
        sortedUnivData: sortedunivdata,
        sortedSenshuData: sortedsenshudata,
        kaishiKukan: 5,
        kukannaiJuniSaikeisan: true,
      );
    }
  }

  if (gh[0].nowracecalckukan == 0) {
    for (var senshuid = 0; senshuid < TEISUU.SENSHUSUU_TOTAL; senshuid++) {
      sortedsenshudata[senshuid].time_taikai_total = TEISUU.DEFAULTTIME;
    }
  }
  //強化練習強度を取得
  final int kyoudo = kantoku.yobiint2[16];
  for (var senshuid = 0; senshuid < TEISUU.SENSHUSUU_TOTAL; senshuid++) {
    hoseitotal = 0.0;
    if (sortedsenshudata[senshuid]
            .entrykukan_race[racebangou][sortedsenshudata[senshuid].gakunen -
            1] ==
        gh[0].nowracecalckukan) {
      // 現在時刻と前回の休憩時刻を比較
      {
        final now = DateTime.now();
        if (now.difference(Chousa.lastGapTime).inSeconds >= 1) {
          // 3秒以上経過してたら
          await Future.delayed(const Duration(milliseconds: 50)); // 休憩を入れる
          Chousa.lastGapTime = DateTime.now();
        }
      }
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
      int set_nebari = jitsuryokuHakkiNouryoku(
        sortedsenshudata[senshuid].choukyorinebari,
        tempSetting,
      );
      if (trainingNum == 2) {
        //set_nebari += kyoudo * 7 ~/ 2;
        set_nebari += kyoudo * 4 ~/ 2;
      } else if (trainingNum == 0) {
        set_nebari += kyoudo;
      }
      if (set_nebari < 1) set_nebari = 1;
      tempSetting = abilityValues[AbilityType.spurtPower] ?? 0;
      if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_spurt = jitsuryokuHakkiNouryoku(
        sortedsenshudata[senshuid].spurtryoku,
        tempSetting,
      );
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
      int set_nobori = jitsuryokuHakkiNouryoku(
        sortedsenshudata[senshuid].noboritekisei,
        tempSetting,
      );
      if (trainingNum == 3) {
        set_nobori += kyoudo * 7;
      } else if (trainingNum == 0) {
        set_nobori += kyoudo;
      }
      if (set_nobori < 1) set_nobori = 1;
      tempSetting = abilityValues[AbilityType.kudariTekisei] ?? 0;
      if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_kudari = jitsuryokuHakkiNouryoku(
        sortedsenshudata[senshuid].kudaritekisei,
        tempSetting,
      );
      if (trainingNum == 4) {
        set_kudari += kyoudo * 7;
      } else if (trainingNum == 0) {
        set_kudari += kyoudo;
      }
      if (set_kudari < 1) set_kudari = 1;
      tempSetting = abilityValues[AbilityType.upDownTaiouryoku] ?? 0;
      if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_updown = jitsuryokuHakkiNouryoku(
        sortedsenshudata[senshuid].noborikudarikirikaenouryoku,
        tempSetting,
      );
      if (trainingNum == 5) {
        set_updown += kyoudo * 7;
      } else if (trainingNum == 0) {
        set_updown += kyoudo;
      }
      if (set_updown < 1) set_updown = 1;
      tempSetting = abilityValues[AbilityType.roadTekisei] ?? 0;
      if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_road = jitsuryokuHakkiNouryoku(
        sortedsenshudata[senshuid].tandokusou,
        tempSetting,
      );
      if (trainingNum == 2) {
        //set_road += kyoudo * 7 ~/ 2;
        set_road += kyoudo * 4 ~/ 2;
      } else if (trainingNum == 0) {
        set_road += kyoudo;
      }
      if (set_road < 1) set_road = 1;
      tempSetting = abilityValues[AbilityType.paceHendoTaiouryoku] ?? 0;
      if (sortedsenshudata[senshuid].hirou == 1) tempSetting = 5;
      int set_pacehendou = jitsuryokuHakkiNouryoku(
        sortedsenshudata[senshuid].paceagesagetaiouryoku,
        tempSetting,
      );
      if (trainingNum == 1) {
        set_pacehendou += kyoudo * 7 ~/ 2;
      } else if (trainingNum == 0) {
        set_pacehendou += kyoudo;
      }
      if (set_pacehendou < 1) set_pacehendou = 1;
      // 能力のタイムへの影響度(1.8.2)を反映した能力の値(小数)。能力50を基準に差を広げたり縮めたりする
      // (駅伝と駅伝予選だけ。初期値(100%)では元の値と全く同じ値になる)
      final double eikyou_nebari = eikyodoNouryoku(set_nebari, nouryokuEikyodo.nebari);
      final double eikyou_spurt = eikyodoNouryoku(set_spurt, nouryokuEikyodo.spurt);
      final double eikyou_nobori = eikyodoNouryoku(set_nobori, nouryokuEikyodo.nobori);
      final double eikyou_kudari = eikyodoNouryoku(set_kudari, nouryokuEikyodo.kudari);
      final double eikyou_updown = eikyodoNouryoku(set_updown, nouryokuEikyodo.updown);
      final double eikyou_road = eikyodoNouryoku(set_road, nouryokuEikyodo.road);
      final double eikyou_pacehendou = eikyodoNouryoku(
        set_pacehendou,
        nouryokuEikyodo.pace,
      );

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

      /*sortedsenshudata[senshuid].a = new_a_int * 0.000000001;
      sortedsenshudata[senshuid].b = newbdouble * 0.0001;
      await sortedsenshudata[senshuid].save();
      returntime =
          sortedsenshudata[senshuid].a * kyori * kyori +
          sortedsenshudata[senshuid].b * kyori;*/

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
      if (sortedsenshudata[senshuid].hirou == 1) {
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

      //sortedsenshudata[senshuid].speed = tempkyori / returntime;
      double double_speed = tempkyori / returntime;

      atai_hosei[senshuid][8] = returntime;

      // Climbing/Descending Correction
      double hosei_nobori = 0.0;
      double hosei_kudari = 0.0;
      double hosei_kirikae = 0.0;
      double hyoukousasisuu = 0.0;

      // Uphill
      double hosei = 0.044 - 0.00017 * eikyou_nobori * TEISUU.CHOUSEI_NOBORI;
      hyoukousasisuu = kyoriwariai_nobori * heikinkoubai_nobori;
      hosei = hosei * (hyoukousasisuu / 0.01);
      hosei_nobori = -hosei;

      // Downhill
      hosei = 0.00965 + 0.00018 * eikyou_kudari * TEISUU.CHOUSEI_KUDARI;
      hyoukousasisuu = kyoriwariai_kudari * heikinkoubai_kudari;
      hosei = hosei * (-hyoukousasisuu / 0.01);
      hosei_kudari = hosei;

      // Switchback
      hosei =
          TEISUU.CHOUSEI_KIRIKAE *
          noborikudari_kirikaekaisuu *
          //(100.0 - set_updown);
          (135.0 - eikyou_updown);
      hosei_kirikae = -hosei;

      double hosei_total_altitude =
          (hosei_nobori + hosei_kudari + hosei_kirikae) + 1.0;
      double moto_time_taikai_total = 0.0;
      double moto_speed = double_speed;
      double temp_speed = 0.0;
      double new_time_taikai_total = 0.0;
      double_speed = double_speed * hosei_total_altitude;
      sortedsenshudata[senshuid].time_taikai_total = tempkyori / double_speed;

      if (racebangou >= 0 && racebangou <= 5) {
        //if (gh[0].nouryokumieruflag[5] == 1) {
        /*sortedsenshudata[senshuid].string_racesetumei +=
              "登り補正:${(-sortedsenshudata[senshuid].time_taikai_total * hosei_nobori).isNegative ? '' : '+'}${(-sortedsenshudata[senshuid].time_taikai_total * hosei_nobori).toStringAsFixed(1)}秒\n";
              */
        /*moto_time_taikai_total = tempkyori / moto_speed;
        temp_speed = moto_speed * (hosei_nobori + 1.0);
        new_time_taikai_total = tempkyori / temp_speed;
        atai_hosei[senshuid][0] =
            new_time_taikai_total - moto_time_taikai_total;
            */
        atai_hosei[senshuid][0] =
            -sortedsenshudata[senshuid].time_taikai_total * hosei_nobori;
        tensuu[senshuid][4] = atai_hosei[senshuid][0];
        //}
        //if (gh[0].nouryokumieruflag[6] == 1) {
        /*sortedsenshudata[senshuid].string_racesetumei +=
              "下り補正:${(-sortedsenshudata[senshuid].time_taikai_total * hosei_kudari).isNegative ? '' : '+'}${(-sortedsenshudata[senshuid].time_taikai_total * hosei_kudari).toStringAsFixed(1)}秒\n";
              */
        /*moto_time_taikai_total = tempkyori / moto_speed;
        temp_speed = moto_speed * (hosei_kudari + 1.0);
        new_time_taikai_total = tempkyori / temp_speed;
        atai_hosei[senshuid][1] =
            new_time_taikai_total - moto_time_taikai_total;
            */
        atai_hosei[senshuid][1] =
            -sortedsenshudata[senshuid].time_taikai_total * hosei_kudari;
        tensuu[senshuid][5] = atai_hosei[senshuid][1];
        //}
        //if (gh[0].nouryokumieruflag[7] == 1) {
        /*sortedsenshudata[senshuid].string_racesetumei +=
              "アップダウン対応力補正:${(-sortedsenshudata[senshuid].time_taikai_total * hosei_kirikae).isNegative ? '' : '+'}${(-sortedsenshudata[senshuid].time_taikai_total * hosei_kirikae).toStringAsFixed(1)}秒\n";
              */
        /*moto_time_taikai_total = tempkyori / moto_speed;
        temp_speed = moto_speed * (hosei_kirikae + 1.0);
        new_time_taikai_total = tempkyori / temp_speed;
        atai_hosei[senshuid][2] =
            new_time_taikai_total - moto_time_taikai_total;
            */
        atai_hosei[senshuid][2] =
            -sortedsenshudata[senshuid].time_taikai_total * hosei_kirikae;
        tensuu[senshuid][6] = atai_hosei[senshuid][2];
        //}
      }

      // Solo Run / Pace Adjustment Adaptability
      if ((racebangou >= 6 && racebangou <= 8) ||
          (racebangou >= 10 && racebangou <= 17)) {
        if (racebangou == 8 ||
            racebangou == 12 ||
            racebangou == 15 ||
            racebangou == 17) {
          temptandokusou = eikyou_road;
          temppaceagesagetaiouryoku = 100;
        } else if (racebangou == 13 || racebangou == 14) {
          temptandokusou = 100;
          temppaceagesagetaiouryoku = 100;
        } else {
          temptandokusou = 100;
          temppaceagesagetaiouryoku = eikyou_pacehendou;
        }
      }
      if (racebangou >= 0 && racebangou <= 5) {
        if ((racebangou != 4 && gh[0].nowracecalckukan == 0) ||
            racebangou == 3) {
          temptandokusou = 100;
          temppaceagesagetaiouryoku = eikyou_pacehendou;
        } else if (racebangou == 4) {
          /*if (sortedsenshudata[senshuid].sijiflag == 0 ||
              sortedsenshudata[senshuid].sijiflag == 3 ||
              sortedsenshudata[senshuid].sijiflag == 5 ||
              sortedsenshudata[senshuid].sijiflag == 7 ||
              sortedsenshudata[senshuid].sijiflag == 9 ||
              sortedsenshudata[senshuid].sijiflag == 11 ||
              sortedsenshudata[senshuid].sijiflag == 13) {*/
          temptandokusou = eikyou_road;
          tekiyouritu_tandokusouhosei = 0.5;
          temppaceagesagetaiouryoku = eikyou_pacehendou;
          tekiyouritu_paceagesagehosei = 0.5;
          /*} else {
            if (sortedsenshudata[senshuid].sijiflag == 2 ||
                sortedsenshudata[senshuid].sijiflag == 4 ||
                sortedsenshudata[senshuid].sijiflag == 6 ||
                sortedsenshudata[senshuid].sijiflag == 8 ||
                sortedsenshudata[senshuid].sijiflag == 10 ||
                sortedsenshudata[senshuid].sijiflag == 12) {
              for (int iiii = 0; iiii < sortedsenshudata.length; iiii++) {
                if (sortedsenshudata[iiii].sijiflag ==
                    sortedsenshudata[senshuid].sijiflag + 1) {
                  if (sortedsenshudata[iiii].sijiseikouflag == 1) {
                    temptandokusou = sortedsenshudata[senshuid].tandokusou;
                    tekiyouritu_tandokusouhosei = 0.4;
                    temppaceagesagetaiouryoku =
                        sortedsenshudata[senshuid].paceagesagetaiouryoku;
                    tekiyouritu_paceagesagehosei = 0.4;
                    break;
                  }
                }
              }
            }
          }*/
        } else if (gh[0].nowracecalckukan >= 1 && gh[0].nowracecalckukan <= 2) {
          temptandokusou = eikyou_road;
          tekiyouritu_tandokusouhosei = 0.5;
          temppaceagesagetaiouryoku = eikyou_pacehendou;
          tekiyouritu_paceagesagehosei = 0.5;
        } else {
          temptandokusou = eikyou_road;
          temppaceagesagetaiouryoku = 100;
        }
      }

      // Experience correction
      if ((racebangou >= 0 && racebangou <= 2) || racebangou == 5) {
        // 同じ区間を走った回数×0.3%(式は chousi_keiken_hosei.dart で、試走タイムと共通)
        final double temphosei_exp = keikenHoseiWariai(
          sortedsenshudata[senshuid],
          racebangou,
          gh[0].nowracecalckukan,
        );
        hoseitotal += temphosei_exp;
        if (temphosei_exp < -0.0001) {
          /*sortedsenshudata[senshuid].string_racesetumei +=
              "経験補正:${(sortedsenshudata[senshuid].time_taikai_total * temphosei_exp).isNegative ? '' : '+'}${(sortedsenshudata[senshuid].time_taikai_total * temphosei_exp).toStringAsFixed(1)}秒\n";
              */
          atai_hosei[senshuid][3] =
              sortedsenshudata[senshuid].time_taikai_total * temphosei_exp;
          tensuu[senshuid][7] = atai_hosei[senshuid][3];
        }
      }

      // Apply total correction
      sortedsenshudata[senshuid].time_taikai_total +=
          sortedsenshudata[senshuid].time_taikai_total * hoseitotal;

      ///
      timesa_free_shuudan[senshuid] = 0.0;
      // Solo running correction
      tanihosei = 0.03 / 100.0;
      temphosei = (100 - temptandokusou) * tanihosei;
      temphosei *= tekiyouritu_tandokusouhosei;
      moto_time_taikai_total = sortedsenshudata[senshuid].time_taikai_total;
      sortedsenshudata[senshuid].time_taikai_total +=
          sortedsenshudata[senshuid].time_taikai_total * temphosei;
      if (racebangou >= 0 && racebangou <= 5) {
        //if (gh[0].nouryokumieruflag[8] == 1) {
        /*sortedsenshudata[senshuid].string_racesetumei +=
              "ロード適性補正:${(sortedsenshudata[senshuid].time_taikai_total * temphosei).isNegative ? '' : '+'}${(sortedsenshudata[senshuid].time_taikai_total * temphosei).toStringAsFixed(1)}秒\n";
              */
        atai_hosei[senshuid][4] = moto_time_taikai_total * temphosei;
        tensuu[senshuid][8] = atai_hosei[senshuid][4];

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
      moto_time_taikai_total = sortedsenshudata[senshuid].time_taikai_total;
      sortedsenshudata[senshuid].time_taikai_total +=
          sortedsenshudata[senshuid].time_taikai_total * temphosei;
      if (racebangou >= 0 && racebangou <= 5) {
        //if (gh[0].nouryokumieruflag[9] == 1) {
        /*sortedsenshudata[senshuid].string_racesetumei +=
              "ペース変動対応力補正:${(sortedsenshudata[senshuid].time_taikai_total * temphosei).isNegative ? '' : '+'}${(sortedsenshudata[senshuid].time_taikai_total * temphosei).toStringAsFixed(1)}秒\n";
              */
        atai_hosei[senshuid][5] = moto_time_taikai_total * temphosei;
        tensuu[senshuid][9] = atai_hosei[senshuid][5];
        if (racebangou == 4 && tekiyouritu_paceagesagehosei < 0.45) {
          double moto_temphosei = temphosei / tekiyouritu_paceagesagehosei;
          double free_temphosei = moto_temphosei * 0.5;
          timesa_free_shuudan[senshuid] +=
              atai_hosei[senshuid][5] - moto_time_taikai_total * free_temphosei;
        }
        //}
      }

      // Long-distance endurance correction
      final choukyoriHosei = ChoukyoriNebariHoseitime(
        kyori: tempkyori,
        choukyorinebari: eikyou_nebari,
        zentaiyokuseiti: kantoku.yobiint2[13],
        //senshuid: senshuid,
        //sortedsenshudata: sortedsenshudata,
      );
      sortedsenshudata[senshuid].time_taikai_total += choukyoriHosei;
      if (racebangou >= 0 && racebangou <= 5) {
        //if (gh[0].nouryokumieruflag[2] == 1) {
        /*sortedsenshudata[senshuid].string_racesetumei +=
              "長距離粘り補正:${choukyoriHosei.isNegative ? '' : '+'}${choukyoriHosei.toStringAsFixed(1)}秒\n";
              */
        atai_hosei[senshuid][6] = choukyoriHosei;
        tensuu[senshuid][10] = atai_hosei[senshuid][6];
        //}
      }

      // Sprint power correction
      final spurtHosei = SpurtRyokuHoseitime(
        kyori: tempkyori,
        spurtRyoku: eikyou_spurt,
        //senshuid: senshuid,
        //sortedsenshudata: sortedsenshudata,
      );
      sortedsenshudata[senshuid].time_taikai_total += spurtHosei;
      if (racebangou >= 0 && racebangou <= 5) {
        //if (gh[0].nouryokumieruflag[3] == 1) {
        /*sortedsenshudata[senshuid].string_racesetumei +=
              "スパート力補正:${spurtHosei.isNegative ? '' : '+'}${spurtHosei.toStringAsFixed(1)}秒\n";
              */
        atai_hosei[senshuid][7] = spurtHosei;
        tensuu[senshuid][11] = atai_hosei[senshuid][7];
        //}
      }

      //調子補正
      // 駅伝(10月・11月・正月・カスタム)で、調子のタイムへの影響度が0%でない場合のみ
      // (影響度0%なら体調不良も含めて補正しない)
      if ((racebangou <= 2 || racebangou == 5) && kantoku.yobiint2[2] != 0) {
        // 体調不良(調子0)は設定の悪化パーセント、それ以外は(100−調子)×0.1%×調子適用率
        // (式は chousi_keiken_hosei.dart で、コンピュータの当日変更・指示ごとの損得予測の画面と共通)
        temphosei =
            chousiHoseiBairitsu(sortedsenshudata[senshuid], kantoku) - 1.0;
        moto_time_taikai_total = sortedsenshudata[senshuid].time_taikai_total;
        sortedsenshudata[senshuid].time_taikai_total +=
            sortedsenshudata[senshuid].time_taikai_total * temphosei;
        atai_hosei[senshuid][13] = moto_time_taikai_total * temphosei;
        sortedsenshudata[senshuid].string_racesetumei +=
            "調子補正:調子${sortedsenshudata[senshuid].chousi} → ${(atai_hosei[senshuid][13]).isNegative ? '' : '+'}${(atai_hosei[senshuid][13]).toStringAsFixed(1)}秒\n";
        tensuu[senshuid][0] = atai_hosei[senshuid][13];
      }

      // Instruction related
      if ((racebangou >= 0 && racebangou <= 3) || racebangou == 5) {
        if (racebangou == 3) {
          if (sortedsenshudata[senshuid].startchokugotobidasiflag == 1) {
            final lasttime = sortedsenshudata[senshuid].time_taikai_total;
            if (Random().nextInt(100) < sortedsenshudata[senshuid].konjou) {
              sortedsenshudata[senshuid].time_taikai_total *= 0.99;
              sortedsenshudata[senshuid].startchokugotobidasiseikouflag = 1;
            } else {
              sortedsenshudata[senshuid].time_taikai_total *= 1.015;
            }
            final sontokutime =
                sortedsenshudata[senshuid].time_taikai_total - lasttime;
            sortedsenshudata[senshuid].string_racesetumei +=
                "スタート直後飛び出し補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
            atai_hosei[senshuid][9] = sontokutime;
          }
        } else {
          if (gh[0].nowracecalckukan == 0) {
            if (sortedsenshudata[senshuid].startchokugotobidasiflag == 1) {
              final lasttime = sortedsenshudata[senshuid].time_taikai_total;
              if (Random().nextInt(100) < sortedsenshudata[senshuid].konjou) {
                sortedsenshudata[senshuid].time_taikai_total *= 0.99;
                sortedsenshudata[senshuid].startchokugotobidasiseikouflag = 1;
              } else {
                sortedsenshudata[senshuid].time_taikai_total *= 1.015;
              }
              final sontokutime =
                  sortedsenshudata[senshuid].time_taikai_total - lasttime;
              sortedsenshudata[senshuid].string_racesetumei +=
                  "指示(スタート直後飛び出し)補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
              //atai_hosei[senshuid][10] = sontokutime;
              atai_hosei[senshuid][9] = sontokutime;
            }
          } else {
            // 倍率の数値は mokuhyou_hosei.dart にまとめている(指示ごとの損得予測の画面と共通)
            if (sortedsenshudata[senshuid].sijiflag == 1) {
              final lasttime = sortedsenshudata[senshuid].time_taikai_total;
              if (Random().nextInt(100) < sortedsenshudata[senshuid].konjou) {
                sortedsenshudata[senshuid].time_taikai_total *=
                    sijiTsukkomiSeikouBairitsu(hoseiTsuyosa);
                sortedsenshudata[senshuid].sijiseikouflag = 1;
              } else {
                sortedsenshudata[senshuid].time_taikai_total *=
                    sijiTsukkomiShippaiBairitsu(hoseiTsuyosa);
              }
              final sontokutime =
                  sortedsenshudata[senshuid].time_taikai_total - lasttime;
              sortedsenshudata[senshuid].string_racesetumei +=
                  "指示(前半突っ込み)補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
              //atai_hosei[senshuid][11] = sontokutime;
              atai_hosei[senshuid][9] = sontokutime;
            } else if (sortedsenshudata[senshuid].sijiflag == 2) {
              if (sortedunivdata[sortedsenshudata[senshuid].univid]
                      .mokuhyojuniwositamawatteruflag[gh[0].nowracecalckukan -
                      1] ==
                  1) {
                final lasttime = sortedsenshudata[senshuid].time_taikai_total;
                final UnivData jibunUniv =
                    sortedunivdata[sortedsenshudata[senshuid].univid];
                if (Random().nextInt(100) <
                    sortedsenshudata[senshuid].heijousin) {
                  sortedsenshudata[senshuid].time_taikai_total *=
                      sijiOsaeSeikouShitamawariBairitsu(hoseiTsuyosa);
                  sortedsenshudata[senshuid].sijiseikouflag = 1;
                } else {
                  // 失敗したときは、指示なしの場合の前半突っ込みの悪化の1.5倍(最小0.5%、最大1.2%)
                  // (1.7.9までは一律1.5%で、前半突っ込みの指示の失敗と同じだった)
                  final double? mokuhyouSa = mokuhyouJuniTimeSa(
                    univs: sortedunivdata,
                    jibunTime:
                        jibunUniv.time_taikai_total[gh[0].nowracecalckukan - 1],
                    mokuhyou: jibunUniv.mokuhyojuni[racebangou],
                    kukan: gh[0].nowracecalckukan,
                  );
                  sortedsenshudata[senshuid].time_taikai_total *=
                      mokuhyouOsaeShippaiBairitsu(
                        // 差が分からない場合(通常は起こらない)は最大の1.2%
                        timeSa: mokuhyouSa ?? double.infinity,
                        kyoriMeter: gh[0]
                            .kyori_taikai_kukangoto[racebangou][gh[0]
                            .nowracecalckukan],
                        tsuyosa: hoseiTsuyosa,
                      );
                }
                final sontokutime =
                    sortedsenshudata[senshuid].time_taikai_total - lasttime;
                sortedsenshudata[senshuid].string_racesetumei +=
                    "指示(前半抑え)補正(${_mokuhyouKonkyo(jibunUniv, racebangou, gh[0].nowracecalckukan, univs: sortedunivdata)}):${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
                //atai_hosei[senshuid][12] = sontokutime;
                atai_hosei[senshuid][9] = sontokutime;
              } else {
                final lasttime = sortedsenshudata[senshuid].time_taikai_total;
                if (Random().nextInt(100) <
                    sortedsenshudata[senshuid].heijousin) {
                  sortedsenshudata[senshuid].time_taikai_total *=
                      sijiOsaeSeikouBairitsu(hoseiTsuyosa);
                  sortedsenshudata[senshuid].sijiseikouflag = 1;
                } else {
                  // 失敗したときは、ほっと一息の悪化+0.1%
                  // (最小0.5%で、目標順位ちょうどで襷を受けたときはこの値)
                  final int flag =
                      sortedunivdata[sortedsenshudata[senshuid].univid]
                          .mokuhyojuniwositamawatteruflag[gh[0]
                              .nowracecalckukan -
                          1];
                  sortedsenshudata[senshuid].time_taikai_total *=
                      mokuhyouOsaeShippaiUwamawariBairitsu(
                        flag < 0 ? -flag : 0,
                        hoseiTsuyosa,
                      );
                }
                final sontokutime =
                    sortedsenshudata[senshuid].time_taikai_total - lasttime;
                sortedsenshudata[senshuid].string_racesetumei +=
                    "指示(前半抑え)補正:${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
                //atai_hosei[senshuid][12] = sontokutime;
                atai_hosei[senshuid][9] = sontokutime;
              }
            } else {
              if (sortedunivdata[sortedsenshudata[senshuid].univid]
                      .mokuhyojuniwositamawatteruflag[gh[0].nowracecalckukan -
                      1] ==
                  1) {
                final lasttime = sortedsenshudata[senshuid].time_taikai_total;
                // 目標順位の大学とのタイム差に比例(最大0.8%。最大の損になる差は
                // 1kmあたり3秒×これから走る区間の距離)
                final UnivData jibunUniv =
                    sortedunivdata[sortedsenshudata[senshuid].univid];
                final double? mokuhyouSa = mokuhyouJuniTimeSa(
                  univs: sortedunivdata,
                  jibunTime:
                      jibunUniv.time_taikai_total[gh[0].nowracecalckukan - 1],
                  mokuhyou: jibunUniv.mokuhyojuni[racebangou],
                  kukan: gh[0].nowracecalckukan,
                );
                sortedsenshudata[senshuid].time_taikai_total *=
                    mokuhyouTsukkomiBairitsu(
                      // 差が分からない場合(通常は起こらない)は今まで通り最大の0.8%
                      timeSa: mokuhyouSa ?? double.infinity,
                      kyoriMeter: gh[0]
                          .kyori_taikai_kukangoto[racebangou][gh[0]
                          .nowracecalckukan],
                      tsuyosa: hoseiTsuyosa,
                    );
                final sontokutime =
                    sortedsenshudata[senshuid].time_taikai_total - lasttime;
                sortedsenshudata[senshuid].string_racesetumei +=
                    "目標順位下回って突っ込み補正(${_mokuhyouKonkyo(jibunUniv, racebangou, gh[0].nowracecalckukan, univs: sortedunivdata)}):${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
                //atai_hosei[senshuid][13] = sontokutime;
                atai_hosei[senshuid][9] = sontokutime;
              } else if (sortedunivdata[sortedsenshudata[senshuid].univid]
                      .mokuhyojuniwositamawatteruflag[gh[0].nowracecalckukan -
                      1] <
                  0) {
                final lasttime = sortedsenshudata[senshuid].time_taikai_total;
                sortedsenshudata[senshuid].time_taikai_total *=
                    mokuhyouHitoikiBairitsu(
                      -sortedunivdata[sortedsenshudata[senshuid].univid]
                          .mokuhyojuniwositamawatteruflag[gh[0]
                              .nowracecalckukan -
                          1],
                      hoseiTsuyosa,
                    );
                final sontokutime =
                    sortedsenshudata[senshuid].time_taikai_total - lasttime;
                sortedsenshudata[senshuid].string_racesetumei +=
                    "目標順位上回って一息補正(${_mokuhyouKonkyo(sortedunivdata[sortedsenshudata[senshuid].univid], racebangou, gh[0].nowracecalckukan)}):${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒\n";
                //atai_hosei[senshuid][13] = sontokutime;
                atai_hosei[senshuid][9] = sontokutime;
              }
            }
          }
        }
        // ★修正: DEFAULTTIME（9999.0等）が混入するのを防ぐ
        if (atai_hosei[senshuid][9] != TEISUU.DEFAULTTIME) {
          tensuu[senshuid][1] = atai_hosei[senshuid][9]; // += ではなく = でOK
        }
      }
    }
  }

  // Group run correction for November Ekiden qualifier and 1st section of each Ekiden
  if (racebangou == 3 ||
      (((racebangou >= 0 && racebangou <= 2) || racebangou == 5) &&
          gh[0].nowracecalckukan == 0)) {
    int maxkarisuma = -1;
    int pacemaker_senshu_id = -1;
    double kijuntime = 0.0;

    // Filter players who are in this section and not doing an early burst
    final entryFilteredsenshudata = sortedsenshudata
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

      final albumBox = Hive.box<Album>('albumBox');
      final Album album = albumBox.get('AlbumData')!;
      album.yobiint5 = kijuntime.toInt();
      await album.save();

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
          if (atai_hosei[senshu.id][14] != TEISUU.DEFAULTTIME) {
            tensuu[senshu.id][2] = atai_hosei[senshu.id][14];
          }
        }
      }
    }
  }

  if (racebangou == 4) {
    for (int ii = 0; ii < sortedsenshudata.length; ii++) {
      atai_hosei[ii][14] = 0.0;
    }
    List<SenshuData> entryFilteredsenshudata;
    //前半突っ込み
    entryFilteredsenshudata = sortedsenshudata
        .where((s) => s.univid == gh[0].MYunivid && s.sijiflag == 1)
        .toList();
    if (entryFilteredsenshudata.isNotEmpty) {
      // Find the pacemaker (highest charisma)
      for (var senshu in entryFilteredsenshudata) {
        if (senshu.sijiseikouflag == 1) {
          final lasttime = senshu.time_taikai_total;
          senshu.time_taikai_total *= 0.992;
          final sontokutime = senshu.time_taikai_total - lasttime;
          senshu.string_racesetumei +=
              "前半突っ込み成功！！(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
          atai_hosei[senshu.id][14] = sontokutime;
        } else {
          final lasttime = senshu.time_taikai_total;
          senshu.time_taikai_total *= 1.014;
          final sontokutime = senshu.time_taikai_total - lasttime;
          senshu.string_racesetumei +=
              "前半突っ込み失敗(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
          atai_hosei[senshu.id][14] = sontokutime;
        }
      }
    }
    //前半抑え
    entryFilteredsenshudata = sortedsenshudata
        .where((s) => s.univid == gh[0].MYunivid && s.sijiflag == 2)
        .toList();
    if (entryFilteredsenshudata.isNotEmpty) {
      // Find the pacemaker (highest charisma)
      for (var senshu in entryFilteredsenshudata) {
        if (senshu.sijiseikouflag == 1) {
          final lasttime = senshu.time_taikai_total;
          senshu.time_taikai_total *= 0.998;
          final sontokutime = senshu.time_taikai_total - lasttime;
          senshu.string_racesetumei +=
              "前半抑え成功！！(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
          atai_hosei[senshu.id][14] = sontokutime;
        } else {
          final lasttime = senshu.time_taikai_total;
          senshu.time_taikai_total *= 1.003;
          final sontokutime = senshu.time_taikai_total - lasttime;
          senshu.string_racesetumei +=
              "前半抑え失敗(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
          atai_hosei[senshu.id][14] = sontokutime;
        }
      }
    }
    //int maxkarisuma = -1;
    //int pacemaker_senshu_id = -1;
    double kijuntime = 0.0;
    int maxheijousin = 0;
    int maxheijousinid = 0;
    bool otitukaseseiouflag = false;
    String shuudanstr = "";
    //bool sijiflag2iruflag = false;
    // Hive.box() を使って、既に開いているBoxを取得
    final shuudansouBox = Hive.box<Shuudansou>('shuudansouBox');
    // Boxからデータを読み込む
    final Shuudansou? shuudansou = shuudansouBox.get('ShuudansouData');

    for (int i_shuudan = 0; i_shuudan < 6; i_shuudan++) {
      if (i_shuudan == 0) {
        shuudanstr = "A";
      }
      if (i_shuudan == 1) {
        shuudanstr = "B";
      }
      if (i_shuudan == 2) {
        shuudanstr = "C";
      }
      if (i_shuudan == 3) {
        shuudanstr = "D";
      }
      if (i_shuudan == 4) {
        shuudanstr = "E";
      }
      if (i_shuudan == 5) {
        shuudanstr = "F";
      }
      entryFilteredsenshudata = sortedsenshudata
          .where(
            (s) => s.univid == gh[0].MYunivid && s.sijiflag == i_shuudan + 3,
          )
          .toList();
      if (entryFilteredsenshudata.isNotEmpty) {
        maxheijousin = -1;
        for (var senshu in entryFilteredsenshudata) {
          if (senshu.heijousin > maxheijousin) {
            maxheijousin = senshu.heijousin;
            maxheijousinid = senshu.id;
          }
        }
        if (Random().nextInt(100) < maxheijousin) {
          otitukaseseiouflag = true;
        } else {
          otitukaseseiouflag = false;
        }
        kijuntime = shuudansou!.setteitime[i_shuudan];
        for (var senshu in entryFilteredsenshudata) {
          senshu.string_racesetumei +=
              "集団${shuudanstr}設定タイム:${_timeToMinuteSecondString(shuudansou.setteitime[i_shuudan])}\n";
          if (otitukaseseiouflag == true) {
            final lasttime = senshu.time_taikai_total;
            senshu.time_taikai_total *= 0.998;
            final sontokutime = senshu.time_taikai_total - lasttime;
            senshu.string_racesetumei +=
                "集団${shuudanstr}は${sortedsenshudata[maxheijousinid].name}(${sortedsenshudata[maxheijousinid].gakunen})の平常心が集団を落ち着かせた(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
            atai_hosei[senshu.id][14] = sontokutime;
          }
          // Check if it's not the pacemaker
          if (senshu.time_taikai_total <= kijuntime) {
            // If own pace is faster than group pace
            final lasttime = senshu.time_taikai_total;
            senshu.time_taikai_total =
                (kijuntime +
                    senshu.time_taikai_total +
                    senshu.time_taikai_total +
                    senshu.time_taikai_total) /
                4.0;
            final sontokutime = senshu.time_taikai_total - lasttime;
            senshu.string_racesetumei +=
                "集団${shuudanstr}のペースは自分の本来のペースよりも遅かった→タイム損(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
            atai_hosei[senshu.id][14] += sontokutime;
          } else {
            if (kijuntime * 1.01 > senshu.time_taikai_total) {
              // Own pace is slower, but manageable
              final lasttime = senshu.time_taikai_total;
              senshu.time_taikai_total =
                  (kijuntime +
                      senshu.time_taikai_total +
                      senshu.time_taikai_total +
                      senshu.time_taikai_total) /
                  4.0;
              final sontokutime = senshu.time_taikai_total - lasttime;
              senshu.string_racesetumei +=
                  "集団${shuudanstr}のペースは自分の本来のペースよりも速かったが速すぎるというほどではなかった→少しタイム得(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
              atai_hosei[senshu.id][14] += sontokutime;
            } else if (kijuntime * 1.03 > senshu.time_taikai_total) {
              // Own pace is much slower, but managed to avoid collapse
              senshu.string_racesetumei +=
                  "集団${shuudanstr}のペースは自分の本来のペースよりも速かったが後半の大失速は免れた→タイム損得なし\n";
            } else {
              // Group pace is too fast, collapse scenario
              final lasttime = senshu.time_taikai_total;
              senshu.time_taikai_total *= 1.025;
              final sontokutime = senshu.time_taikai_total - lasttime;
              senshu.string_racesetumei +=
                  "集団${shuudanstr}のペースは自分の本来のペースよりも速すぎた→無理して付いていって後半大失速→大きくタイム損(${sontokutime.isNegative ? '' : '+'}${sontokutime.toStringAsFixed(1)}秒)\n";
              atai_hosei[senshu.id][14] += sontokutime;
            }
          }
          senshu.string_racesetumei +=
              "集団走効果計(${atai_hosei[senshu.id][14].isNegative ? '' : '+'}${atai_hosei[senshu.id][14].toStringAsFixed(1)}秒)\n";
        }
      }
    }
  }

  //////////////////
  ///
  ////
  // 対象となる列（8番目の列）の値をすべて抽出
  List<double> columnValues = [];
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
    if (sortedsenshudata[i]
            .entrykukan_race[racebangou][sortedsenshudata[i].gakunen - 1] ==
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
    for (var senshuid = 0; senshuid < TEISUU.SENSHUSUU_TOTAL; senshuid++) {
      if (sortedsenshudata[senshuid]
              .entrykukan_race[racebangou][sortedsenshudata[senshuid].gakunen -
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
  for (var senshuid = 0; senshuid < TEISUU.SENSHUSUU_TOTAL; senshuid++) {
    if (sortedsenshudata[senshuid]
            .entrykukan_race[racebangou][sortedsenshudata[senshuid].gakunen -
            1] ==
        gh[0].nowracecalckukan) {
      sortedsenshudata[senshuid].string_racesetumei +=
          name_hosei[8] +
          " ${juni_hosei[senshuid][8] + 1}位:${atai_hosei[senshuid][8].isNegative ? '' : '+'}${atai_hosei[senshuid][8].toStringAsFixed(1)}秒\n";
      sortedsenshudata[senshuid].string_racesetumei +=
          name_hosei[15] +
          " ${juni_hosei[senshuid][15] + 1}位:${atai_hosei[senshuid][15].isNegative ? '' : '+'}${atai_hosei[senshuid][15].toStringAsFixed(1)}秒\n";
      sortedsenshudata[senshuid].string_racesetumei +=
          name_hosei[16] +
          " ${juni_hosei[senshuid][16] + 1}位:${atai_hosei[senshuid][16].isNegative ? '' : '+'}${atai_hosei[senshuid][16].toStringAsFixed(1)}秒(";

      sortedsenshudata[senshuid].string_racesetumei +=
          TimeDate.timeToFunByouString(atai_hosei[senshuid][16] + minValue) +
          ")\n";
      //sortedsenshudata[senshuid].string_racesetumei +=
      //    "逆算誤差(トータルー走破タイム):${((atai_hosei[senshuid][16] + minValue) - sortedsenshudata[senshuid].time_taikai_total).isNegative ? '' : '+'}${((atai_hosei[senshuid][16] + minValue) - sortedsenshudata[senshuid].time_taikai_total).toStringAsFixed(3)}秒\n";

      tensuu[senshuid][3] = atai_hosei[senshuid][8];

      for (int j = 0; j < hoseishuruisuu; j++) {
        if (j < 8) {
          if (hoseimukankeiflag[j] == true) {
            if (j == 3) {
            } else {
              if (gh[0].nouryokumieruflag[nouryokumieruflagIndex_hosei[j]] ==
                  1) {
                sortedsenshudata[senshuid].string_racesetumei +=
                    name_hosei[j] + " 無\n";
              }
            }
          } else {
            if (j == 3) {
              if (atai_hosei[senshuid][j] < -0.0001) {
                sortedsenshudata[senshuid].string_racesetumei +=
                    name_hosei[j] +
                    ":${atai_hosei[senshuid][j].isNegative ? '' : '+'}${atai_hosei[senshuid][j].toStringAsFixed(1)}秒\n";
              }
            } else {
              if (gh[0].nouryokumieruflag[nouryokumieruflagIndex_hosei[j]] ==
                  1) {
                sortedsenshudata[senshuid].string_racesetumei +=
                    name_hosei[j] +
                    " ${juni_hosei[senshuid][j] + 1}位:${atai_hosei[senshuid][j].isNegative ? '' : '+'}${atai_hosei[senshuid][j].toStringAsFixed(1)}秒\n";
              }
            }
          }
        }
      }
    }
  }

  // Assignment of times and rankings
  for (var senshuid = 0; senshuid < TEISUU.SENSHUSUU_TOTAL; senshuid++) {
    if (sortedsenshudata[senshuid]
            .entrykukan_race[racebangou][sortedsenshudata[senshuid].gakunen -
            1] ==
        gh[0].nowracecalckukan) {
      if ((racebangou >= 0 && racebangou <= 3) || racebangou == 5) {
        var temptime_assign = sortedsenshudata[senshuid].time_taikai_total;
        sortedunivdata[sortedsenshudata[senshuid].univid]
                .time_taikai_total[gh[0].nowracecalckukan] +=
            temptime_assign;
      }
    }
  }

  if (racebangou == 3 || racebangou == 4) {
    // Rank within group
    final kumifilteredsenshudata = sortedsenshudata
        .where(
          (s) =>
              s.entrykukan_race[racebangou][s.gakunen - 1] ==
              gh[0].nowracecalckukan,
        )
        .toList();
    kumifilteredsenshudata.sort(
      (a, b) => a.time_taikai_total.compareTo(b.time_taikai_total),
    );

    for (var i_juni = 0; i_juni < kumifilteredsenshudata.length; i_juni++) {
      kumifilteredsenshudata[i_juni].temp_juni = i_juni;
    }

    if (racebangou == 4) {
      // Aggregate top 10 times for each university
      List<int> shuukeizumininzuu_univgoto = List.generate(
        TEISUU.UNIVSUU,
        (_) => 0,
      );
      for (var senshu in kumifilteredsenshudata) {
        if (sortedunivdata[senshu.univid].taikaientryflag[racebangou] == 1) {
          if (shuukeizumininzuu_univgoto[senshu.univid] < 10) {
            sortedunivdata[senshu.univid].time_taikai_total[0] +=
                senshu.time_taikai_total;
            shuukeizumininzuu_univgoto[senshu.univid]++;
          }
        }
      }
    }
  }

  if (racebangou <= 5) {
    // Sectional rank
    final kukangotojunsortedunivdata = sortedunivdata.toList()
      ..sort(
        (a, b) => a.time_taikai_total[gh[0].nowracecalckukan].compareTo(
          b.time_taikai_total[gh[0].nowracecalckukan],
        ),
      );

    for (var i = 0; i < TEISUU.UNIVSUU; i++) {
      kukangotojunsortedunivdata[i].kukanjuni_taikai[gh[0].nowracecalckukan] =
          i;
    }

    // Update cumulative time for subsequent sections
    if (gh[0].nowracecalckukan > 0) {
      for (var i_univ = 0; i_univ < sortedunivdata.length; i_univ++) {
        if (sortedunivdata[i_univ].taikaientryflag[racebangou] == 1) {
          sortedunivdata[i_univ].time_taikai_total[gh[0].nowracecalckukan] +=
              sortedunivdata[i_univ].time_taikai_total[gh[0].nowracecalckukan -
                  1];
        }
      }
    }

    // Cumulative rank at section end
    final tuukajunsortedunivdata = sortedunivdata.toList()
      ..sort(
        (a, b) => a.time_taikai_total[gh[0].nowracecalckukan].compareTo(
          b.time_taikai_total[gh[0].nowracecalckukan],
        ),
      );

    for (var i = 0; i < TEISUU.UNIVSUU; i++) {
      tuukajunsortedunivdata[i].tuukajuni_taikai[gh[0].nowracecalckukan] = i;
    }

    // Check if team goal rank is not met
    if (racebangou == 2 && gh[0].nowracecalckukan == 4) {
      for (var i = 0; i < tuukajunsortedunivdata.length; i++) {
        tuukajunsortedunivdata[i].mokuhyojuniwositamawatteruflag[gh[0]
                .nowracecalckukan] =
            0;
      }
    } else {
      for (var i = 0; i < TEISUU.UNIVSUU; i++) {
        if (tuukajunsortedunivdata[i].mokuhyojuni[racebangou] < i) {
          tuukajunsortedunivdata[i].mokuhyojuniwositamawatteruflag[gh[0]
                  .nowracecalckukan] =
              1;
          /*} else if (tuukajunsortedunivdata[i].id == gh[0].MYunivid) {
        tuukajunsortedunivdata[i].mokuhyojuniwositamawatteruflag[gh[0]
                .nowracecalckukan] =
            i - tuukajunsortedunivdata[i].mokuhyojuni[racebangou];*/
        } else {
          /*tuukajunsortedunivdata[i].mokuhyojuniwositamawatteruflag[gh[0]
                .nowracecalckukan] =
            0;*/
          tuukajunsortedunivdata[i].mokuhyojuniwositamawatteruflag[gh[0]
                  .nowracecalckukan] =
              i - tuukajunsortedunivdata[i].mokuhyojuni[racebangou];
        }
      }
    }
  }

  if (racebangou <= 5) {
    // --- 事前準備 ---
    int validCount = 0;
    List<int> targetSenshuIds = []; // 2回目のループを減らすためのキャッシュ

    // 値をストックするための2次元配列 (12項目 × 人数分)
    List<List<double>> typeValues = List.generate(12, (_) => []);

    // --- 1回目のループ：対象の絞り込みと値の収集 ---
    for (var senshuid = 0; senshuid < TEISUU.SENSHUSUU_TOTAL; senshuid++) {
      var senshu = sortedsenshudata[senshuid];

      // 対象区間を走る選手のみ抽出
      if (senshu.entrykukan_race[racebangou][senshu.gakunen - 1] ==
          gh[0].nowracecalckukan) {
        validCount++;
        targetSenshuIds.add(senshuid);

        // 種類番号0〜11の値をリストにストック
        for (int type = 0; type <= 11; type++) {
          typeValues[type].add(tensuu[senshuid][type]);
        }
      }
    }

    // 対象者がいなければ処理終了
    if (validCount > 0) {
      List<double> robustMeans = List.filled(12, 0.0);
      double globalMaxSD = 0.0; // 全項目を通じた「最大の影響度のブレ幅」

      // --- 各項目の外れ値を除外（IQR法）し、平均と全体の最大標準偏差を計算 ---
      for (int type = 0; type <= 11; type++) {
        // データをコピーして小さい順に並び替え
        List<double> values = List.from(typeValues[type]);
        values.sort();
        int n = values.length;

        List<double> filteredValues = [];

        // データが4個以上ある場合のみIQR判定を行う
        if (n >= 4) {
          double q1 = values[(n * 0.25).floor()];
          double q3 = values[(n * 0.75).floor()];
          double iqr = q3 - q1;

          // 外れ値のボーダーライン（1.5 * IQR）
          double lowerBound = q1 - (1.5 * iqr);
          double upperBound = q3 + (1.5 * iqr);

          // ボーダーライン内（正常な値）だけを抽出
          for (double v in values) {
            if (v >= lowerBound && v <= upperBound) {
              filteredValues.add(v);
            }
          }
        }

        // 人数が少ない、または外れ値判定でデータが消えすぎた場合のフェイルセーフ
        if (filteredValues.isEmpty) {
          filteredValues = values;
        }

        // 外れ値を除外した「一般的な集団」だけで平均とSDを計算
        double sum = 0.0;
        double sumSq = 0.0;
        int count = filteredValues.length;

        for (double v in filteredValues) {
          sum += v;
          sumSq += v * v;
        }

        // 基準となる平均値
        robustMeans[type] = sum / count;

        // 分散 = (二乗和 - (合計の二乗 / 人数)) / 人数
        double variance = (sumSq - (sum * sum) / count) / count;
        double sd = variance > 0 ? sqrt(variance) : 0.0;

        // 全項目の中で最も個人差（ばらつき）が大きかったSDを基準にする
        if (sd > globalMaxSD) {
          globalMaxSD = sd;
        }
      }

      // --- 2回目のループ：影響度（-7〜+7）の計算と4ビット圧縮 ---
      for (int senshuid in targetSenshuIds) {
        int compressedFlag = 0;

        // 種類番号0〜11 の処理 [各4ビット消費、合計48ビット]
        for (int type = 0; type <= 11; type++) {
          int storedValue = 7; // デフォルト（平均値ピッタリ、または差がない項目）は7

          if (globalMaxSD > 0) {
            // 比較の基準を「IQRで計算した平均値（robustMeans）」にする
            double deviation = tensuu[senshuid][type] - robustMeans[type];

            // 最大SDを基準に、-7〜+7の範囲にスケーリング
            // （標準偏差の約2.5倍を7に割り当てる）
            int impact = (deviation * 5.0 / globalMaxSD).round();

            // -7 〜 +7 の範囲にクランプ
            // （外れ値の選手は限界突破しても、ここで確実に-7または+7で止まる）
            impact = impact.clamp(-7, 7);

            // ビット演算用にプラスの値にする (-7〜7 を 0〜14 に変換)
            storedValue = impact + 7;
          }

          // ビットのシフト量: 種類番号 × 4ビット
          // type 0 = 0bitシフト, type 1 = 4bitシフト, ..., type 11 = 44bitシフト
          int shift = type * 4;

          // 4ビット(0xF)でマスクして格納
          compressedFlag |= (storedValue & 0xF) << shift;
        }

        // 圧縮したデータを格納
        sortedsenshudata[senshuid].racechuukakuseiflag = compressedFlag;
      }
    }
  }

  if (racebangou == 2) {
    await RaceCalc_gakuren(
      racebangou: racebangou,
      gh: gh,
      sortedunivdata: sortedunivdata,
    );
  }

  gh[0].nowracecalckukan++;

  /////わざと一旦閉じる
  //var open_rsenshubox = await Hive.openBox<Senshu_R_Data>('retiredSenshuBox');

  final endTime = DateTime.now();
  final timeInterval = endTime.difference(startTime).inMicroseconds / 1000000.0;
  print("RaceCalc処理時間: ${_timeToMinuteSecondString(timeInterval)}経過");
}

/// 目標順位による補正の根拠(例: 襷を受けた時点5位/目標3位)
/// 判定は襷を受けた時点(前の区間の終了時点)の通過順位と目標順位で行っている
/// [univs] を渡すと、目標順位を下回っているときは目標順位の大学とのタイム差も付ける
/// (例: 襷を受けた時点5位/目標3位・3位と32.0秒差)
String _mokuhyouKonkyo(
  UnivData univ,
  int racebangou,
  int kukan, {
  List<UnivData>? univs,
}) {
  if (kukan <= 0 ||
      univ.tuukajuni_taikai.length < kukan ||
      univ.mokuhyojuni.length <= racebangou) {
    return '';
  }
  final String sa = univs == null
      ? ''
      : mokuhyouSaBun(
          univs: univs,
          univ: univ,
          racebangou: racebangou,
          kukan: kukan,
        );
  return '襷を受けた時点${univ.tuukajuni_taikai[kukan - 1] + 1}位/目標${univ.mokuhyojuni[racebangou] + 1}位'
      '${sa.isEmpty ? '' : '・$sa'}';
}
