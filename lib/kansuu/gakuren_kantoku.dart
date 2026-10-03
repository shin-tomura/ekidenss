import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';

// ------------------------------------------------------------
// 学連選抜の監督(1.8.2)
//
// プレイヤーの大学が正月駅伝に出場できない年に、プレイヤーが学連選抜の監督になれる。
// ・KantokuData.yobiint2[75] 学連選抜の監督をするか(0=する(初期値)、1=しない)
//   学連選抜編成の画面(mode0290.dart)で切り替えられ、各種設定のQRコードにも含める
// ・監督をする年は、学連選抜編成の画面から区間配置を決められる(Modal_GakurenKukanHenshuu.dart)
// ・レース中は、レース画面(mode0350_content.dart)が自動で進まずに学連選抜の監督の表示になり、
//   走る学連選抜の選手に指示を出せる(選手のsijiflagと、1区はstartchokugotobidasiflagに保存し、
//   RaceCalc_gakuren.dartで大学の選手と同じ倍率で補正する。2区以降は損得予測も見られる)
// ・スキップ中は学連選抜編成の画面もレース画面も通らないので、今まで通りコンピュータが
//   決めた区間配置のままで、指示も出ない
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
