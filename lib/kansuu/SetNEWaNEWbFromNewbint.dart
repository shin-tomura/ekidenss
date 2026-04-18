import 'package:ekiden/senshu_data.dart';

void SetNEWaNEWbFromNewbint(int Newbint, SenshuData senshu) {
  // 変数名はSwiftコードの指示通りにしています。
  int b_int = 0;
  int a_int = 0;
  int a_min_int = 0;
  int new_a_int = 0;
  int new_a_min_int = 0;
  int sa = 0;

  // 現在のaとbを整数に変換
  a_int = (senshu.a * 1000000000.0).toInt();
  b_int = (senshu.b * 10000.0).toInt();

  // 既存のb_intに基づいたa_min_intの計算
  a_min_int = (b_int * b_int * 0.0333 - b_int * 114.25 + senshu.magicnumber)
      .toInt();

  // aの差分を計算
  sa = a_int - a_min_int;

  // 新しいNewbintに基づいたnew_a_min_intの計算
  new_a_min_int =
      (Newbint * Newbint * 0.0333 - Newbint * 114.25 + senshu.magicnumber)
          .toInt();

  // 新しいa_intを計算
  new_a_int = new_a_min_int + sa;

  // 選手のaとbを更新
  senshu.a = new_a_int * 0.000000001;
  senshu.b = Newbint * 0.0001;
}
