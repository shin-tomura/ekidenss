import 'package:ekiden/constants.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスにname_maeとname_atoがあるため必要
import 'dart:math'; // ★この行を追加★
import 'package:ekiden/kansuu/RironTime.dart';
import 'package:ekiden/kansuu/RironTime_Nyuugakuji.dart';
import 'package:ekiden/kantoku_data.dart';

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

  Box<SenshuData> senshuBox = Hive.box<SenshuData>('senshuBox');
  // Box内の全ての値をリストとして取得します
  final allSenshu = senshuBox.values.toList();
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
      final int r_mae = random.nextInt(TEISUU.SUU_NAMEMAE);
      final int r_ato = random.nextInt(TEISUU.SUU_NAMEATO);

      // name_maeとname_atoリストから名前を選び、結合して設定
      // Swiftコードは `gh[0].name_mae[r_mae]` だったので、Dartでは `ghensuu.name_mae[r_mae]`
      // ただし、リストのインデックス範囲外アクセスを防ぐためにチェックを加えるのが安全です
      if (r_mae < ghensuu.name_mae.length && r_ato < ghensuu.name_ato.length) {
        senshu.name = '${ghensuu.name_mae[r_mae]} ${ghensuu.name_ato[r_ato]}';
        //print(' -count=${count} ID ${senshu.id}: 名前を ${senshu.name} に設定しました。');
      } else {
        print(' - ID ${senshu.id}: 名前生成エラー: インデックスが範囲外です。');
        // エラー時のフォールバックとして、デフォルト名を維持するか、別の処理を検討
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

      bool tokubetuflag = false;
      int tokubetusisuu = 0;
      senshu.hirou = 0;
      {
        //選手ごとの成長力とか成長のスタート地点とか
        final Random random = Random();
        int aInt = 0;
        int tempRand = 0;
        int aMinInt = 0;

        if (random.nextInt(1500) < 10) {
          tokubetuflag = true;
          tokubetusisuu = random.nextInt(51);
          senshu.hirou = 2;
          // 13分20・30台大学入学の条件
          senshu.sositu_bonus = TEISUU.SOSITU_BONUS; //-100
          tempRand = tokubetusisuu + 1500; // 1550から1600までの乱数

          // a_min_intの計算 (temprand=1550の場合のa_min_int)
          aMinInt =
              (1550.0 * 1550.0 * 0.0333 - 1550.0 * 114.25 + senshu.magicnumber)
                  .toInt();

          final double tani = 1000.0 / (1680.0 - 1550.0);

          // a_intの計算
          aInt = aMinInt + ((tempRand - 1550) * tani).toInt();

          senshu.a = aInt * 0.000000001;
          senshu.b = 1645.0 * 0.0001; // 固定値
          senshu.sositu = tempRand;
        } else if (random.nextInt(100) < TEISUU.KAKURITU13PUNDAINYUUGAKU) {
          // 13分台大学入学の条件分岐
          senshu.sositu_bonus = TEISUU.SOSITU_BONUS; //-100
          tempRand = random.nextInt(51) + 1550; // 1550から1600までの乱数

          // a_min_intの計算 (temprand=1550の場合のa_min_int)
          aMinInt =
              (1550.0 * 1550.0 * 0.0333 - 1550.0 * 114.25 + senshu.magicnumber)
                  .toInt();

          final double tani = 1000.0 / (1680.0 - 1550.0);

          // a_intの計算
          aInt = aMinInt + ((tempRand - 1550) * tani).toInt();

          senshu.a = aInt * 0.000000001;
          senshu.b = 1645.0 * 0.0001; // 固定値
          senshu.sositu = tempRand;
        } else {
          senshu.sositu_bonus = 0;
          tempRand = random.nextInt(80) + 1601; // 1601から1680までの乱数

          // a_min_intの計算 (temprand=1550の場合のa_min_int)
          aMinInt =
              (1550.0 * 1550.0 * 0.0333 - 1550.0 * 114.25 + senshu.magicnumber)
                  .toInt();

          final double tani1 = 1000.0 / (1680.0 - 1550.0); // 最初の区間の単位
          final double tani2 = 3000.0 / (1680.0 - 1600.0); // 次の区間の単位

          // a_intの計算
          aInt =
              aMinInt +
              ((1600.0 - 1550.0) * tani1).toInt() +
              ((tempRand - 1600.0) * tani2).toInt();

          senshu.a = aInt * 0.000000001;
          senshu.b = 1645.0 * 0.0001; // 固定値
          senshu.sositu = tempRand;
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
      senshu.choukyorinebari = random.nextInt(99) + 1; // 1から99までの乱数を生成

      {
        const int bunbo = 1680 - 1550; // 分母
        final int bunsi = 1680 - senshu.sositu; // 分子

        final double ritu = bunsi.toDouble() / bunbo.toDouble(); // 比率を計算

        int kotae = (100 * ritu).toInt(); // 整数に変換して100を掛ける

        // 最小値を1に制限
        if (kotae < 1) {
          kotae = 1;
        }

        // 最大値を99に制限
        if (kotae > 99) {
          kotae = 99;
        }

        senshu.spurtryoku = kotae; // 結果を選手のspurtryokuに設定

        senshu.paceagesagetaiouryoku = kotae - 10 + (random.nextInt(21) - 10);
        if (senshu.paceagesagetaiouryoku > 89) {
          senshu.paceagesagetaiouryoku = 89;
        }
        if (senshu.paceagesagetaiouryoku < 1) {
          senshu.paceagesagetaiouryoku = 1;
        }
      }

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
      senshu.noboritekisei = random.nextInt(99) + 1;
      senshu.kudaritekisei = random.nextInt(99) + 1;
      senshu.noborikudarikirikaenouryoku = random.nextInt(99) + 1;
      senshu.tandokusou = random.nextInt(99) + 1;
      //senshu.paceagesagetaiouryoku = random.nextInt(99) + 1;
      if (random.nextInt(100) < 33) {
        int temp_paceagesagetaiouryoku = random.nextInt(99) + 1;
        if (temp_paceagesagetaiouryoku > senshu.paceagesagetaiouryoku) {
          senshu.paceagesagetaiouryoku = temp_paceagesagetaiouryoku;
        }
      }
      if (senshu.hirou == 2) {
        senshu.paceagesagetaiouryoku = 90 + tokubetusisuu ~/ 5;
      }

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

      ////出身地+趣味
      int targetHobbyIndex = random.nextInt(HobbyDatabase.allHobbies.length);
      // 都道府県: 27番目の要素 ("大阪府"と想定) -> インデックス 26
      int targetPrefectureIndex = random.nextInt(
        LocationDatabase.allPrefectures.length,
      );
      // ⭐ パック（格納）
      final int combinedIndex = PackedIndexHelper.packIndices(
        hobbyIndex: targetHobbyIndex,
        prefectureIndex: targetPrefectureIndex,
      );
      senshu.samusataisei = combinedIndex;
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
}
