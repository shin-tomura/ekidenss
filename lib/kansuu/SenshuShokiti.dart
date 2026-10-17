import 'package:ekiden/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスにname_maeとname_atoがあるため必要
import 'dart:math'; // ★この行を追加★
import 'package:ekiden/kansuu/RironTime.dart';
import 'package:ekiden/kansuu/RironTime_Nyuugakuji.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/joukai.dart';
import 'package:ekiden/kansuu/kingin_kiroku.dart'; // 金銀の記録(1.9.9)
import 'package:ekiden/kansuu/shinnyuusei_dodai.dart'; // 新入生の土台(2.0.4)
import 'package:ekiden/kansuu/koukou.dart' show koukouRainenDodaiYomu; // 7月下旬に先に決めた新入生の土台(2.0.4)

/// SenshuData Box 内の選手をループし、指定した学年の選手に特定の処理を適用する関数。
///
/// [senshuBox] は選手データを保存するHive Boxです。
/// [targetGakunen] は処理対象とする学年です。この値と一致する選手のみが処理されます。
///                 null の場合、全ての選手が対象となります。
Future<void> SenshuShokitiSetteiByGakunen(
  //Box<SenshuData> senshuBox, {
  int targetGakunen, // オプション引数としてnullableにする
) async {
  String logMessage = 'Updating SenshuData entries';
  if (targetGakunen != 0) {
    logMessage += ' for Gakunen $targetGakunen';
  } else {
    logMessage += ' for all Gakunen';
  }
  print('$logMessage...');

  // ランダム生成器を初期化
  final Random random = Random();

  final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
  final Ghensuu ghensuu = ghensuuBox.get(
    'global_ghensuu',
    defaultValue: Ghensuu.initial(),
  )!;

  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData? kantoku = kantokuBox.get('KantokuData')!;

  // SenshuData Box内の全ての選手をループ
  // senshuBox.values は Box 内の全ての SenshuData オブジェクトのIterableを返します。
  // .toList() を使うことで、ループ中に Box の内容が変更されても安全に処理できます。
  int count = 0;
  int itsuzaiSuu = 0; // 隠れた逸材にした人数(確認用のログに出す。1.8.8)

  Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');
  // Box内の全ての値をリストとして取得します
  final allSenshu = senshuBox.values.toList();
  // 在籍中の選手(今回名前を作り直さない選手)のフルネーム。
  // 新しく作る名前がこれと同じにならないようにする(同時期に同じ名前の選手がいないように)。
  // 新規ゲーム開始時(targetGakunen == 0)は全員作り直すので空
  final Set<String> zaisekiNames = {
    if (targetGakunen != 0)
      for (final s in allSenshu)
        if (s.gakunen != targetGakunen) s.name,
  };
  // 4月の新入生(1年生)に使う、7月下旬に高校の大会のために先に決めた来年の新入生の土台
  // (2.0.4。koukou.dart。なければ空で、ここで引く)
  final List<ShinnyuuseiDodai> dodaiList =
      targetGakunen == 1 ? koukouRainenDodaiYomu() : const <ShinnyuuseiDodai>[];
  int dodaiI = 0;
  // 取得した全ての選手データをループ処理します
  for (var senshu in allSenshu) {
    /*for (final entry in senshuBox.toMap().entries) {
    final int senshuId = entry.key;
    final SenshuData senshu = entry.value;*/

    count++;

    if (targetGakunen == 0) {
      //新規ゲーム開始時なので、学年と所属大学決定
      senshu.univid = senshu.id ~/ TEISUU.SENSHUSUU_UNIV;
      senshu.gakunen = senshu.id % 4 + 1;
    }

    // 学年で処理を分岐
    if (targetGakunen == 0 || senshu.gakunen == targetGakunen) {
      // 卒業した選手の枠を新しい選手に作り直すので、金銀の記録を消す(1.9.9。kingin_kiroku.dart)
      senshu.name_tanshuku = kinginKirokuNashi;
      // 新入生の土台(名前・素質の引き方・入学時5000m・能力値の一部・出身地と趣味。2.0.4。shinnyuusei_dodai.dart)
      // 7月下旬に先に決めた土台があれば順に使い(高校の情報も入っている。koukou.dart)、なければここで引く
      // (引き方は2.0.3までと同じ。在籍中の選手と名字・名前の両方が同じにならないように選ぶ)
      final ShinnyuuseiDodai dodai = dodaiI < dodaiList.length
          ? dodaiList[dodaiI++]
          : shinnyuuseiDodaiHiku(random, ghensuu, zaisekiNames);
      final String? dodaiName = dodai.name;
      if (dodaiName != null) {
        senshu.name = dodaiName;
        zaisekiNames.add(senshu.name); // 同じ回に作る他の選手とも重ならないように
      } else {
        print(' - ID ${senshu.id}: 名前生成エラー: インデックスが範囲外です。');
        // エラー時のフォールバックとして、デフォルト名を維持する
      }

      // 各能力値の初期値
      senshu.magicnumber = TEISUU.MAGICNUMBER;
      {
        //選手の成長タイプ
        final Random random = Random();
        int tempRand;
        int totalSentakuritu;

        tempRand = random.nextInt(100); // 0から99までの乱数を生成
        totalSentakuritu = 0;
        senshu.seichoutype = 0; // デフォルト値を設定

        for (int i = 0; i < TEISUU.SEICHOUTYPESUU; i++) {
          if (i < ghensuu.seichouryoku_type_sentakuritu.length) {
            totalSentakuritu += ghensuu.seichouryoku_type_sentakuritu[i];
          } else {
            // seichouryoku_type_sentakuritu.SEICHOUTYPESUUより少ない場合のハンドリング
            // 必要に応じてエラーログを出力するか、適切なデフォルト値を設定
            print('警告: ghensuu.seichouryokuTypeSentakurituの要素数が不足しています。');
            break;
          }
          if (tempRand < totalSentakuritu) {
            senshu.seichoutype = i;
            break;
          }
        }
      }

      // 素質の引き方と素質は土台で決めてある(2.0.4)
      final bool tokubetuflag = dodai.kuji == dodaiKujiTokubetu;
      final int tokubetusisuu = tokubetuflag ? dodai.sositu : 0;
      bool itsuzaiflag = false; // 隠れた逸材(1.8.8。joukai.dart)
      senshu.hirou = 0;
      {
        //選手ごとの成長力とか成長のスタート地点とか
        // (a・b・素質・素質ボーナスの計算は2.0.3までと同じ。shinnyuusei_dodai.dart の shinnyuuseiSosituSettei)
        final Random random = Random();
        final ({int aInt, int aMinInt}) ai = shinnyuuseiSosituSettei(senshu, dodai.kuji, dodai.sositu);
        final int aInt = ai.aInt;
        final int aMinInt = ai.aMinInt;
        // 13分台でない新入生のうちitsuzaiWariai%を、隠れた逸材にする(1.8.8。joukai.dart)
        // (入学時5000mの記録・能力値は、ここで決めた素質のまま決め、上限を決めたあとで基本走力と上限を置き換える)
        if (dodai.kuji == dodaiKujiFutsuu && random.nextInt(100) < itsuzaiWariai) {
          itsuzaiflag = true;
        }

        // 素質が1600を超える場合の追加処理
        if (senshu.sositu > 1600) {
          if (random.nextInt(100) < TEISUU.GENKAICHOKUMENSISUU) {
            //100
            int lastSositu = senshu.sositu;
            int newSositu = ((8145.0 - (aInt - aMinInt)) / 4.5).toInt();

            if (lastSositu < newSositu) {
              newSositu = lastSositu;
            }
            if (newSositu < 1600 + senshu.sositu_bonus) {
              // ここは元のSwiftコードのsositu_bonusを使用
              newSositu = 1600 + senshu.sositu_bonus;
            }
            senshu.sositu_bonus = newSositu - lastSositu;
          }
        }
      }
      senshu.genkaichokumenkaisuu = 0;
      senshu.genkaitoppakaisuu = 0;
      senshu.seichoukaisuu = 0;
      {
        final Random random = Random();
        final int temprand = random.nextInt(100); // 0から99までの乱数を生成

        if (temprand < 33) {
          senshu.mokuhyo_b = TEISUU.MOKUHYO_B_5000;
        } else if (temprand < 66) {
          senshu.mokuhyo_b = TEISUU.MOKUHYO_B_10000;
        } else {
          senshu.mokuhyo_b = TEISUU.MOKUHYO_B_HALF;
        }
      }
      senshu.kiroku_nyuugakuji_5000 = RironTime_Nyuugakuji(
        tokubetuflag,
        tokubetusisuu,
        5000.0,
        senshu,
      );
      // 入学時5000mは土台の値にする(土台と同じ計算。13分台の新入生は13分35秒〜13分59秒に広げた値。1.8.5・2.0.4)
      // (RironTime_Nyuugakuji は a・b を書き換えるので、今まで通り呼んでから記録だけ置き換える)
      senshu.kiroku_nyuugakuji_5000 = dodai.t5;
      // 基本走力の上限を、入学時5000mの記録で決める(1.8.5。詳しくは joukai.dart)
      // (入学時の基本走力はどの選手も上限より遅いので、今まで通り育成で上限に向かって伸びる)
      senshu.magicnumber = joukaiMagicnumberFromNyuugakuji5000(
        senshu.kiroku_nyuugakuji_5000,
      );
      // 隠れた逸材は、入学時の基本走力と上限を、13分台の新入生と同じ決め方で決め直す(1.8.8。joukai.dart)
      // (入学時5000mの記録は上で決めたまま。理論タイムは下で、決め直した基本走力から計算する)
      if (itsuzaiflag) {
        itsuzaiNiSuru(senshu, random);
        itsuzaiSuu++;
      }
      senshu.rirontime5000 = RironTime(5000.0, senshu);
      senshu.rirontime10000 = RironTime(10000.0, senshu);
      senshu.rirontimehalf = RironTime(21097.5, senshu);
      for (int i = 0; i < TEISUU.SUU_KOJINBESTKIROKUSHURUISUU; i++) {
        senshu.time_bestkiroku[i] = TEISUU.DEFAULTTIME;
        senshu.year_bestkiroku[i] = 0;
        senshu.month_bestkiroku[i] = 0;
        senshu.zentaijuni_bestkiroku[i] = TEISUU.DEFAULTJUNI;
        senshu.gakunaijuni_bestkiroku[i] = TEISUU.DEFAULTJUNI;
      }
      senshu.time_bestkiroku[0] = senshu.kiroku_nyuugakuji_5000;
      senshu.choukyorinebari = dodai.nebari; // 1から99まで(土台で引いてある。2.0.4)

      // スパート力(素質から)とペース変動対応力(スパート力の近く)は、土台で決めてある(2.0.4)
      senshu.spurtryoku = dodai.spurt;
      senshu.paceagesagetaiouryoku = dodai.pace;

      senshu.kegaflag = 0;

      //senshu.hirou = 0;
      //senshu.kaifukuryoku = random.nextInt(99) + 1;
      senshu.kaifukuryoku = 0; //個別練習メニュー
      senshu.anteikan = random.nextInt(99) + 1;
      if (senshu.gakunen == 4) {
        if (senshu.anteikan < kantoku!.yobiint2[7]) {
          senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[7];
          //senshu.save();
        }
      }
      if (senshu.gakunen == 3) {
        if (senshu.anteikan < kantoku!.yobiint2[8]) {
          senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[8];
          //senshu.save();
        }
      }
      if (senshu.gakunen == 2) {
        if (senshu.anteikan < kantoku!.yobiint2[9]) {
          senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[9];
          //senshu.save();
        }
      }

      //if (random.nextInt(100) < 50) {
      //  senshu.chousi = senshu.anteikan;
      //} else {
      senshu.chousi = 100;

      //}
      senshu.karisuma = random.nextInt(99) + 1;
      senshu.kazetaisei = random.nextInt(99) + 1;
      //senshu.atusataisei = random.nextInt(99) + 1;
      //senshu.samusataisei = random.nextInt(99) + 1;
      // 登り・下り・アップダウン・ロードは土台で引いてある(ペース変動対応力の引き直しと、
      // 特別な選手のペース変動対応力も土台に入っている。2.0.4)
      senshu.noboritekisei = dodai.nobori;
      senshu.kudaritekisei = dodai.kudari;
      senshu.noborikudarikirikaenouryoku = dodai.updown;
      senshu.tandokusou = dodai.road;

      if (random.nextInt(100) < 80) {
        senshu.konjou = random.nextInt(50) + 1;
      } else if (random.nextInt(100) < 50) {
        senshu.konjou = random.nextInt(19) + 51;
      } else if (random.nextInt(100) < 70) {
        senshu.konjou = random.nextInt(20) + 70;
      } else {
        senshu.konjou = random.nextInt(10) + 90;
      }
      senshu.heijousin = random.nextInt(99) + 1;
      for (int i = 0; i < TEISUU.SUU_MAXRACESUU_1YEAR; i++) {
        for (int ii = 0; ii < TEISUU.GAKUNENSUU; ii++) {
          senshu.entrykukan_race[i][ii] = -1;
          senshu.kukanjuni_race[i][ii] = TEISUU.DEFAULTJUNI;
          senshu.kukantime_race[i][ii] = TEISUU.DEFAULTTIME;
        }
      }
      senshu.time_taikai_total = TEISUU.DEFAULTTIME;

      ////出身地+趣味(土台で引いてある。7月下旬に先に決めた土台は、出身校と高校時代の実績も入っている。2.0.4)
      senshu.samusataisei = dodai.samusataisei;
    }
    if (targetGakunen == 0) {
      //初期の2年生以上の選手は後の初期選手用育成処理の関係で成長タイプ上書き

      if (senshu.gakunen == 2) {
        senshu.seichoutype = 2;
      }
      if (senshu.gakunen == 3) {
        senshu.seichoutype = 3;
      }
      if (senshu.gakunen == 4) {
        senshu.seichoutype = 4;
      }
    }
    // 処理を適用した選手データをBoxに保存（上書き）
    //await senshuBox.put(senshuId, senshu);
    await senshu.save();
  }

  print('SenshuData update completed.');
  print('隠れた逸材: $itsuzaiSuu人'); // 確認用(1.8.8)
}
