import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';

// ------------------------------------------------------------
// 学連選抜の監督(1.8.2)
//
// プレイヤーの大学が正月駅伝に出場できない年に、プレイヤーが学連選抜の監督になれる。
// ・KantokuData.yobiint2[75] 学連選抜の監督をするか(0=する(初期値)、1=しない)
//   学連選抜編成の画面(mode0290.dart)で切り替えられ、各種設定のQRコードにも含める
// ・監督をする年は、学連選抜編成の画面から区間配置を決められる(Modal_GakurenKukanHenshuu.dart)
// ・スキップ中は学連選抜編成の画面を通らないので、今まで通りコンピュータが決めた区間配置のまま
// ------------------------------------------------------------

const int gakurenKantokuIndex = 75;

/// 学連選抜の監督をする設定か(0=する(初期値)、1=しない)
bool gakurenKantokuSettei(KantokuData kantoku) {
  if (kantoku.yobiint2.length <= gakurenKantokuIndex) return true;
  return kantoku.yobiint2[gakurenKantokuIndex] != 1;
}

/// yobiint2に保存する値として正しいか(QRコードの読み込みで使う)
bool gakurenKantokuAtaiTadashii(int atai) {
  return atai == 0 || atai == 1;
}

/// 今年の正月駅伝で、プレイヤーが学連選抜の監督をするか
/// (プレイヤーの大学が正月駅伝に出場できず、設定が「する」のとき)
bool gakurenKantokuChuu(KantokuData kantoku, UnivData myUniv) {
  return gakurenKantokuSettei(kantoku) &&
      myUniv.taikaientryflag.length > 2 &&
      myUniv.taikaientryflag[2] == 0;
}
