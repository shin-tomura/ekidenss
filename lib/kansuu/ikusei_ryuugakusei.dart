import 'dart:math'; // Randomクラスを使用するため
import 'package:hive_flutter/hive_flutter.dart';
//import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスのインポート
import 'package:ekiden/constants.dart'; //

void ryuugakusei_ikusei({required int senshuid}) {
  final _random = Random();
  final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');
  List<SenshuData> sortedsenshudata = senshudataBox.values.toList();
  sortedsenshudata.sort((a, b) => a.id.compareTo(b.id));
  final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
  List<UnivData> sortedunivdata = univdataBox.values.toList();
  sortedunivdata.sort((a, b) => a.id.compareTo(b.id));

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

  int sokoage = 90;
  int sokoage_spurt =
      (4 - sortedunivdata[sortedsenshudata[senshuid].univid].r) * 10 + 60;
  int sokoage_paceagesage =
      (4 - sortedunivdata[sortedsenshudata[senshuid].univid].r) * 10 + 60;

  //底上げ処理
  if (sortedsenshudata[senshuid].choukyorinebari < sokoage) {
    sortedsenshudata[senshuid].choukyorinebari = sokoage + _random.nextInt(10);
  }
  //if (sortedsenshudata[senshuid].spurtryoku < sokoage) {
  sortedsenshudata[senshuid].spurtryoku = sokoage_spurt + _random.nextInt(10);
  //}
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
  if (sortedsenshudata[senshuid].tandokusou < sokoage) {
    sortedsenshudata[senshuid].tandokusou = sokoage + _random.nextInt(10);
  }
  //if (sortedsenshudata[senshuid].paceagesagetaiouryoku < sokoage) {
  sortedsenshudata[senshuid].paceagesagetaiouryoku =
      sokoage_paceagesage + _random.nextInt(10);
  //}

  // 育成ループ (Swiftでは`for _ in 0..<6`だったが、コメントアウトされた行を見ると回数が変化する可能性あり)
  // ここでは `0..<6` を採用
  //int ikuseiloopsuu = 6;
  int ikuseiloopsuu = 7 - sortedunivdata[sortedsenshudata[senshuid].univid].r;
  for (int i = 0; i < ikuseiloopsuu * 1; i++) {
    // 条件分岐 (Swiftでは`if true`だったが、コメントアウトされた行を見ると乱数判定の可能性あり)
    // ここでは `if true` を採用
    if (true) {
      // 速度パラメータaとbを整数値に変換して計算
      a_int = (sortedsenshudata[senshuid].a * 1000000000.0).toInt();
      b_int = (sortedsenshudata[senshuid].b * 10000.0).toInt();

      chouseisisuu = 0.2; // 調整指数
      sositu =
          1680 -
          (sortedsenshudata[senshuid].sositu +
              sortedsenshudata[senshuid].sositu_bonus);

      // 大学の育成力と素質ボーナスに基づいた乱数生成
      // Swift: Int.random(in: 0...(sortedunivdata[sortedsenshudata[senshuid].univid].ikuseiryoku+sositu))
      // Dart: _random.nextInt(max_value + 1)
      int ikusei_rand_max = 150 + sositu;
      int randseisuu = _random.nextInt(
        ikusei_rand_max + 1,
      ); // 0からikusei_rand_maxまで

      int motomotoseisuu = 0;
      motomotoseisuu = 150 + sositu;

      temp_seichou = (chouseisisuu * randseisuu).toInt() + motomotoseisuu;

      int zenhan = 0;
      zenhan = temp_seichou * 310;
      temp_seichou = (zenhan / 100).toInt();

      ///////ここで各大学の育成力による調整/////
      double ikuseiryokuchousei = 0.0;
      ikuseiryokuchousei = 150 / 150.0;
      temp_seichou = (temp_seichou.toDouble() * ikuseiryokuchousei).toInt();
      ////////////////////////////////////

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
            if (_random.nextInt(100) < 100) {
              // 0から99までの乱数が33未満 (33%の確率)
              //int suu_min = 40;
              //int suu_rand = 61;
              int suu_min =
                  (5 - sortedunivdata[sortedsenshudata[senshuid].univid].r) *
                      5 +
                  20;
              int suu_rand =
                  (5 - sortedunivdata[sortedsenshudata[senshuid].univid].r) *
                      10 +
                  21;
              sortedsenshudata[senshuid].magicnumber -=
                  (suu_min + _random.nextInt(suu_rand))
                      .toDouble(); // 0から75までの乱数
              sortedsenshudata[senshuid].genkaitoppakaisuu += 1; // 限界突破回数を加算

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
                a_int -= plusryou + _random.nextInt(10) + 1; // 0から9までの乱数 + 1
                sortedsenshudata[senshuid].a = a_int * 0.000000001;
              }
            }
          } else {
            // 限界突破回数が3回以上の場合のロジック
            if (_random.nextInt(100) < 100) {
              // 0から99までの乱数が10未満 (10%の確率)
              //int suu_min = 40;
              //int suu_rand = 61;
              int suu_min =
                  (5 - sortedunivdata[sortedsenshudata[senshuid].univid].r) *
                      5 +
                  20;
              int suu_rand =
                  (5 - sortedunivdata[sortedsenshudata[senshuid].univid].r) *
                      10 +
                  21;
              sortedsenshudata[senshuid].magicnumber -=
                  (suu_min + _random.nextInt(suu_rand))
                      .toDouble(); // 0から75までの乱数
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
}
