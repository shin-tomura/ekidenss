import 'dart:math'; // Randomクラスを使用するため

import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート
// 必要に応じて他のモデルや定数ファイルのインポートを追加してください

/// 選手の育成（成長）処理を行う関数
///
/// [gh]: グローバル変数 (Ghensuu) のリスト。通常は要素が1つのリスト。
/// [sortedunivdata]: ID順にソートされた大学データのリスト。
/// [sortedsenshudata]: ID順にソートされた選手データのリスト。
/// [gakunen]: 育成対象の学年。
///
/// この関数は、渡されたリスト内のSenshuDataオブジェクトのプロパティを変更します。
/// 変更を永続化するには、この関数を呼び出した後にHive Boxに保存し直す必要があります。
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

Future<void> Ikusei_Com({
  required List<Ghensuu> gh,
  required List<UnivData> sortedunivdata,
  required List<SenshuData> sortedsenshudata,
  required int gakunen,
}) async {
  final startTime = DateTime.now();
  print("Ikusei_Comに入った");
  //print('Ikusei_Com: 育成処理を開始 (学年: $gakunen)...');

  // 変数の初期化
  // var i=0 // 未使用のためコメントアウト
  int a_int = 0;
  int b_int = 0;
  int a_int_new = 0;
  // var b_int_new=0 // 未使用のためコメントアウト
  int a_min_int = 0;
  // var a_min_int_new=0 // 未使用のためコメントアウト
  // var bunbo=0 // 未使用のためコメントアウト
  // var bunsi=0 // 未使用のためコメントアウト
  // var bunbo_new=0 // 未使用のためコメントアウト
  int a_kotae_int = 0;
  // var b_kotae_int=0 // 未使用のためコメントアウト
  int genkaitoppaflag = 0;
  // var tenjou=0 // 未使用のためコメントアウト
  // var sa=0 // 未使用のためコメントアウト
  int sositu = 0;
  double chouseisisuu = 0.0;
  int temp_seichou = 0;

  final _random = Random(); // 乱数ジェネレータのインスタンス

  // 全選手をループ
  for (int senshuid = 0; senshuid < TEISUU.SENSHUSUU_TOTAL; senshuid++) {
    // 対象学年の選手のみを処理
    if (sortedsenshudata[senshuid].gakunen == gakunen) {
      //二重育成防止
      /*if ((gh[0].month == 4 && gh[0].day == 25) ||
          (gh[0].month == 7 && gh[0].day == 15)) {
        bool nijyuuflag = false;
        int kasankaisuu = 0;
        if (gh[0].month == 7) kasankaisuu = 6;
        if (sortedsenshudata[senshuid].hirou != 1) {
          if (gh[0].year == 1) {
            if (sortedsenshudata[senshuid].gakunen == 4) {
              if (sortedsenshudata[senshuid].seichoukaisuu > 12 + kasankaisuu) {
                nijyuuflag = true;
              }
            } else if (sortedsenshudata[senshuid].gakunen == 3) {
              if (sortedsenshudata[senshuid].seichoukaisuu > 12 + kasankaisuu) {
                nijyuuflag = true;
              }
            } else if (sortedsenshudata[senshuid].gakunen == 2) {
              if (sortedsenshudata[senshuid].seichoukaisuu > 12 + kasankaisuu) {
                nijyuuflag = true;
              }
            } else {
              if (sortedsenshudata[senshuid].seichoukaisuu > 0 + kasankaisuu) {
                nijyuuflag = true;
              }
            }
          } else if (gh[0].year == 2) {
            if (sortedsenshudata[senshuid].gakunen == 4) {
              if (sortedsenshudata[senshuid].seichoukaisuu >
                  12 + 12 + kasankaisuu) {
                nijyuuflag = true;
              }
            } else if (sortedsenshudata[senshuid].gakunen == 3) {
              if (sortedsenshudata[senshuid].seichoukaisuu >
                  12 + 12 + kasankaisuu) {
                nijyuuflag = true;
              }
            } else if (sortedsenshudata[senshuid].gakunen == 2) {
              if (sortedsenshudata[senshuid].seichoukaisuu > 12 + kasankaisuu) {
                nijyuuflag = true;
                break;
              }
            } else {
              if (sortedsenshudata[senshuid].seichoukaisuu > 0 + kasankaisuu) {
                nijyuuflag = true;
              }
            }
          } else if (gh[0].year == 3) {
            if (sortedsenshudata[senshuid].gakunen == 4) {
              if (sortedsenshudata[senshuid].seichoukaisuu >
                  12 + 12 + 12 + kasankaisuu) {
                nijyuuflag = true;
              }
            } else if (sortedsenshudata[senshuid].gakunen == 3) {
              if (sortedsenshudata[senshuid].seichoukaisuu >
                  12 + 12 + kasankaisuu) {
                nijyuuflag = true;
              }
            } else if (sortedsenshudata[senshuid].gakunen == 2) {
              if (sortedsenshudata[senshuid].seichoukaisuu > 12 + kasankaisuu) {
                nijyuuflag = true;
              }
            } else {
              if (sortedsenshudata[senshuid].seichoukaisuu > 0 + kasankaisuu) {
                nijyuuflag = true;
              }
            }
          } else {
            if ((sortedsenshudata[senshuid].gakunen - 1) * 12 + kasankaisuu <
                sortedsenshudata[senshuid].seichoukaisuu) {
              nijyuuflag = true;
            }
          }
        }
        if (nijyuuflag == true) {
          print(
            "二重育成防止措置発動 ${gh[0].year}年${gh[0].month}月 ${sortedsenshudata[senshuid].name} (${sortedsenshudata[senshuid].gakunen}年) ${sortedunivdata[sortedsenshudata[senshuid].univid].name}大学 seichoukaisuu=${sortedsenshudata[senshuid].seichoukaisuu}",
          );
          continue;
        }
      }*/

      //ここで、ondoflagを使った他の大学の選手の底上げ処理
      if (sortedsenshudata[senshuid].univid != gh[0].MYunivid) {
        if (sortedsenshudata[senshuid].choukyorinebari < gh[0].ondoflag * 10) {
          sortedsenshudata[senshuid].choukyorinebari =
              gh[0].ondoflag * 10 + _random.nextInt(10);
        }
        /*if (sortedsenshudata[senshuid].spurtryoku < gh[0].ondoflag * 10) {
          sortedsenshudata[senshuid].spurtryoku =
              gh[0].ondoflag * 10 + _random.nextInt(10);
        }*/
        /*if (sortedsenshudata[senshuid].noboritekisei < gh[0].ondoflag * 10) {
          sortedsenshudata[senshuid].noboritekisei =
              gh[0].ondoflag * 10 + _random.nextInt(10);
        }*/
        /*if (sortedsenshudata[senshuid].kudaritekisei < gh[0].ondoflag * 10) {
          sortedsenshudata[senshuid].kudaritekisei =
              gh[0].ondoflag * 10 + _random.nextInt(10);
        }*/
        /*if (sortedsenshudata[senshuid].noborikudarikirikaenouryoku <
            gh[0].ondoflag * 10) {
          sortedsenshudata[senshuid].noborikudarikirikaenouryoku =
              gh[0].ondoflag * 10 + _random.nextInt(10);
        }*/
        if (sortedsenshudata[senshuid].tandokusou < gh[0].ondoflag * 10) {
          sortedsenshudata[senshuid].tandokusou =
              gh[0].ondoflag * 10 + _random.nextInt(10);
        }
        if (sortedsenshudata[senshuid].paceagesagetaiouryoku <
            gh[0].ondoflag * 10) {
          sortedsenshudata[senshuid].paceagesagetaiouryoku =
              gh[0].ondoflag * 10 + _random.nextInt(10);
        }
      }

      // 育成ループ (Swiftでは`for _ in 0..<6`だったが、コメントアウトされた行を見ると回数が変化する可能性あり)
      // ここでは `0..<6` を採用
      for (int i = 0; i < 6; i++) {
        // 条件分岐 (Swiftでは`if true`だったが、コメントアウトされた行を見ると乱数判定の可能性あり)
        // ここでは `if true` を採用
        if (true) {
          // 速度パラメータaとbを整数値に変換して計算
          a_int = (sortedsenshudata[senshuid].a * 1000000000.0).toInt();
          b_int = (sortedsenshudata[senshuid].b * 10000.0).toInt();
          if (sortedsenshudata[senshuid].hirou == 1) {
            chouseisisuu = 0.002; // 調整指数
          } else {
            chouseisisuu = 0.2; // 調整指数
          }

          sositu =
              1680 -
              (sortedsenshudata[senshuid].sositu +
                  sortedsenshudata[senshuid].sositu_bonus);

          // 大学の育成力と素質ボーナスに基づいた乱数生成
          // Swift: Int.random(in: 0...(sortedunivdata[sortedsenshudata[senshuid].univid].ikuseiryoku+sositu))
          // Dart: _random.nextInt(max_value + 1)
          int ikusei_rand_max =
              sortedunivdata[sortedsenshudata[senshuid].univid].ikuseiryoku +
              sositu;
          int randseisuu = _random.nextInt(
            ikusei_rand_max + 1,
          ); // 0からikusei_rand_maxまで

          int motomotoseisuu = 0;
          motomotoseisuu =
              sortedunivdata[sortedsenshudata[senshuid].univid].ikuseiryoku +
              sositu;

          temp_seichou = (chouseisisuu * randseisuu).toInt() + motomotoseisuu;

          int zenhan = 0;
          zenhan =
              temp_seichou *
              gh[0].seichouryoku_type_gakunen[sortedsenshudata[senshuid]
                  .seichoutype][sortedsenshudata[senshuid].gakunen - 1];
          temp_seichou = (zenhan / 100).toInt();

          ///////ここで各大学の育成力による調整/////
          double ikuseiryokuchousei = 0.0;
          ikuseiryokuchousei =
              sortedunivdata[sortedsenshudata[senshuid].univid].ikuseiryoku /
              150.0;
          temp_seichou = (temp_seichou.toDouble() * ikuseiryokuchousei).toInt();
          ////////////////////////////////////
          ///
          if (sortedsenshudata[senshuid].hirou == 1 &&
              sortedsenshudata[senshuid].gakunen > 1) {
            temp_seichou = _random.nextInt(2);
          }

          ///

          a_int_new = a_int - temp_seichou;

          // 最低速度a_min_intの計算
          a_min_int =
              (b_int.toDouble() * b_int.toDouble() * 0.0333 -
                      b_int.toDouble() * 114.25 +
                      sortedsenshudata[senshuid].magicnumber)
                  .toInt();

          genkaitoppaflag = 0;
          if (a_min_int > a_int_new) {
            a_int_new = a_min_int + _random.nextInt(11); // 0から10まで
            genkaitoppaflag = 1;
          }

          a_kotae_int = a_int_new;

          // 選手データの速度aを更新
          sortedsenshudata[senshuid].a = a_kotae_int * 0.000000001;
          // sortedsenshudata[senshuid].b=Double(Double(b_kotae_int)*0.0001); // コメントアウトされているため移植しない

          sortedsenshudata[senshuid].seichoukaisuu += 1; // 成長回数を加算

          // 限界突破ロジック
          if (genkaitoppaflag == 1) {
            if (sortedsenshudata[senshuid].genkaitoppakaisuu <= 47) {
              sortedsenshudata[senshuid].genkaichokumenkaisuu += 1; // 限界直面回数を加算
              if (sortedsenshudata[senshuid].genkaitoppakaisuu < 3) {
                if (_random.nextInt(100) < 33) {
                  // 0から99までの乱数が33未満 (33%の確率)
                  sortedsenshudata[senshuid].magicnumber -=
                      (25 + _random.nextInt(76)).toDouble(); // 0から75までの乱数
                  sortedsenshudata[senshuid].genkaitoppakaisuu +=
                      1; // 限界突破回数を加算

                  a_int = (sortedsenshudata[senshuid].a * 1000000000.0).toInt();
                  b_int = (sortedsenshudata[senshuid].b * 10000.0).toInt();
                  // TEISUU.MAGICNUMBERは、sortedsenshudata[senshuid].magicnumberとは異なる定数として扱う
                  a_min_int =
                      (b_int.toDouble() * b_int.toDouble() * 0.0333 -
                              b_int.toDouble() * 114.25 +
                              TEISUU.MAGICNUMBER)
                          .toInt();

                  if (a_int - a_min_int >= 0) {
                    int plusryou = 0;
                    plusryou = a_int - a_min_int;
                    a_int -=
                        plusryou + _random.nextInt(10) + 1; // 0から9までの乱数 + 1
                    sortedsenshudata[senshuid].a = a_int * 0.000000001;
                  }
                }
              } else {
                /*if (sortedsenshudata[senshuid].hirou != 1 ||
                    (sortedsenshudata[senshuid].hirou == 1 &&
                        sortedsenshudata[senshuid].genkaitoppakaisuu < 12)) {}*/
                // 限界突破回数が3回以上の場合のロジック
                if (_random.nextInt(100) < 10) {
                  // 0から99までの乱数が10未満 (10%の確率)
                  sortedsenshudata[senshuid].magicnumber -=
                      (25 + _random.nextInt(76)).toDouble();
                  sortedsenshudata[senshuid].genkaitoppakaisuu += 1;

                  a_int = (sortedsenshudata[senshuid].a * 1000000000.0).toInt();
                  b_int = (sortedsenshudata[senshuid].b * 10000.0).toInt();
                  a_min_int =
                      (b_int.toDouble() * b_int.toDouble() * 0.0333 -
                              b_int.toDouble() * 114.25 +
                              TEISUU.MAGICNUMBER)
                          .toInt();

                  if (a_int - a_min_int >= 0) {
                    int plusryou = 0;
                    plusryou = a_int - a_min_int;
                    a_int -= plusryou + _random.nextInt(10) + 1;
                    sortedsenshudata[senshuid].a = a_int * 0.000000001;
                  }
                }
              }
            }
          }
        }
      }
      /* コメントアウトされている追加の育成ロジック
      for i in 0..<76{
        // ... (省略)
      }
      */
    }
  }

  final endTime = DateTime.now();
  final timeInterval = endTime.difference(startTime).inMicroseconds / 1000000.0;
  print("Ikusei_Com処理時間: ${_timeToMinuteSecondString(timeInterval)}経過");
  print('Ikusei_Com: 育成処理を完了しました。');
  // この関数で変更された選手データ (sortedsenshudata) は、
  // この関数を呼び出した側でHive Boxに保存し直す必要があります。
}
