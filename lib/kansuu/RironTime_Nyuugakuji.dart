import 'package:ekiden/senshu_data.dart';
import 'SetNEWaNEWbFromNewbint.dart';
import 'package:ekiden/constants.dart';

double RironTime_Nyuugakuji(
  bool tokubetuflag,
  int tokubetusisuu,
  double kyori,
  SenshuData senshu,
) {
  if (kyori < 7500.0) {
    if (tokubetuflag == true) {
      SetNEWaNEWbFromNewbint(1400 + tokubetusisuu, senshu);
    } else {
      SetNEWaNEWbFromNewbint(1555, senshu);
    }
  } else if (kyori < 15000.0) {
    SetNEWaNEWbFromNewbint(TEISUU.MOKUHYO_B_10000, senshu);
  } else {
    SetNEWaNEWbFromNewbint(TEISUU.MOKUHYO_B_HALF, senshu);
  }
  final double returntime = senshu.a * kyori * kyori + senshu.b * kyori;
  return returntime;
}
