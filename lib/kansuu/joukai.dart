import 'dart:math'; // log・exp・Randomを使うため
import 'package:ekiden/constants.dart'; // TEISUUクラスをインポート

// ------------------------------------------------------------
// 基本走力の上限(1.8.5)
// 1.8.4までは、基本走力の上限(magicnumberで決まる床)は全員共通(TEISUU.MAGICNUMBER)で、
// 成長タイプ1の選手は1年目の4/25の育成でほぼ全員が上限に届くため、入学時5000mの記録は
// その後の強さにほとんど影響しなかった(残る差は限界突破の運と能力値)。
// 1.8.5からは、新入生を作るときに、入学時5000mの記録で上限をずらす。
// ・入学時5000mが基準(13分50秒)の新入生は、1.8.4までと同じ上限
// ・基準より1秒速いごとに、ハーフの上限が1秒速く、1秒遅いごとに1秒遅くなる
//   (基準の13分50秒は、能力値も含めた10年に1人級の最速が1.8.4までと同じくらいになるように
//   シミュレーションで決めた。そのぶん全員の平均は、ハーフで約40秒遅くなる)
// ・限界突破の仕組みは今まで通り(運で化ける選手も残る)
// ・留学生は入学時5000mの記録がないので、優秀度ごとに決める(ryuugakuseiJoukaiMagicnumber)
// ・在学中の選手の上限は変えない(移行処理はしない。新入生と新規ゲームの選手から)
// magicnumberは、タイムの計算(RironTime・RaceCalcなど)では打ち消し合って効かず、
// 育成(Ikusei_Com)で基本走力が伸びる先の床としてだけ効く。
// ------------------------------------------------------------

/// 上限の基準になる入学時5000mの記録(秒)。この記録の新入生は1.8.4までと同じ上限になる
const double joukaiKijunNyuugakuji5000 = 830.0; // 13分50秒

/// 基本走力(magicnumber)の1あたりの、ハーフのタイムの秒数(21097.5mの2乗×10の-9乗)
const double halfByouPerKihonSouryoku = 0.445;

/// 入学時5000mの記録(秒)から、基本走力の上限(magicnumber)を決める(1.8.5)
/// 入学時5000mが基準より1秒速いごとに、ハーフの上限が1秒速くなる
double joukaiMagicnumberFromNyuugakuji5000(double nyuugakuji5000) {
  final double halfByou = nyuugakuji5000 - joukaiKijunNyuugakuji5000;
  return TEISUU.MAGICNUMBER + (halfByou / halfByouPerKihonSouryoku).round();
}

/// 留学生の基本走力の上限(magicnumber)(1.8.5)
/// [r]は大学の留学生の優秀度(UnivData.r。1最高優秀・2優秀・3普通・4やや優秀でない)
/// 日本人選手との力関係が1.8.4までと同じくらいになるように、ハーフで
/// 最高優秀0秒・優秀8秒・普通16秒・やや優秀でない24秒、1.8.4までより遅くする
/// (新しい上限では日本人の最速は今と同じだが、10位・30位・80位あたりは14〜24秒遅くなるため、
/// 優秀度ごとに競う相手の層が遅くなったぶんだけずらす。シミュレーションで決めた)
double ryuugakuseiJoukaiMagicnumber(int r) {
  final int yuushuudo = r < 1 ? 1 : (r > 4 ? 4 : r);
  final double halfByou = (yuushuudo - 1) * 8.0;
  return TEISUU.MAGICNUMBER + (halfByou / halfByouPerKihonSouryoku).round();
}

/// 13分台の新入生(素質1550〜1600)の入学時5000mの記録(秒)(1.8.5)
/// 1.8.4までは13分49秒〜13分59秒だったのを、13分35秒〜13分59秒に広げる
/// (13分35秒〜13分48秒の空白を埋める。13分20秒台は今まで通り特別な選手だけ)
/// 遅いほど多くなるようにし、13分40秒台と13分50秒台の人数がおよそ7:17になるようにした
/// (2025年度の高校3年生の5000m13分台の分布に合わせた)。素質の数値が小さいほど速い
double nyuugakuji5000Juusanpundai(int sositu, Random random) {
  const double hayai = 815.0; // 13分35秒
  const double haba = 24.0; // 13分59秒まで
  final double k = log(17.0 / 7.0) / 10.0;
  final double u = ((sositu - 1550) + random.nextDouble()) / 51.0; // 0以上1未満
  return hayai + log(1.0 + u * (exp(haba * k) - 1.0)) / k;
}

/// 基本走力の上限を、箱庭モードの基本走力と同じ目盛り(小さいほど速い)の値にする(1.8.5)
/// (基本走力の目盛りは、b=1550に直したa_intに300を足した値。上限に届いた選手の基本走力は、
/// この値から+10くらいまでになる)
int joukaiHyouji(double magicnumber) {
  return (1550 * 1550 * 0.0333 - 1550 * 114.25 + magicnumber).toInt() + 300;
}

/// 箱庭モードの目盛りの値から、基本走力の上限(magicnumber)を求める(joukaiHyoujiの逆)(1.8.5)
/// 基本走力の目盛りの値を渡すと、その基本走力がちょうど上限になるmagicnumberになる
double magicnumberFromJoukaiHyouji(int hyouji) {
  return (hyouji - 300) - (1550 * 1550 * 0.0333 - 1550 * 114.25);
}
