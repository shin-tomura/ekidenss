import 'package:ekiden/senshu_data.dart';

double RironTime(double kyori, SenshuData senshu) {
  int newbint = 0;

  // 距離に応じた newbint の設定
  if (kyori < 5001.0) {
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
    newbint = 150;
  }

  // newbint に 1450 を加算
  newbint += 1450;

  // SetNEWaNEWbFromNewbint 関数の内容をインラインで記述
  // (Swiftのdoブロックは、Dartでは単にスコープを区切るためなので、直接記述)
  int b_int = (senshu.b * 10000.0).toInt();
  int a_int = (senshu.a * 1000000000.0).toInt();

  // Swiftのa_min_intはb_intに基づく
  int a_min_int = (b_int * b_int * 0.0333 - b_int * 114.25 + senshu.magicnumber)
      .toInt();

  int sa = a_int - a_min_int;

  // new_a_min_intはnewbintに基づく
  int new_a_min_int =
      (newbint * newbint * 0.0333 - newbint * 114.25 + senshu.magicnumber)
          .toInt();

  int new_a_int = new_a_min_int + sa;

  // 選手の a と b を更新 (参照渡しなのでsenshuオブジェクトが直接変更される)
  senshu.a = new_a_int * 0.000000001;
  senshu.b = newbint * 0.0001;

  // 理論タイムの計算
  final double returntime = senshu.a * kyori * kyori + senshu.b * kyori;
  return returntime;
}
