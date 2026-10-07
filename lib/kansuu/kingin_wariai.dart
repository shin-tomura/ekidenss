import 'package:ekiden/kantoku_data.dart';

// ------------------------------------------------------------
// 難易度ごとの金銀支給量の割合(1.9.1。「金銀支給量設定」の画面で設定する)
//
// KantokuData.yobiint3 の
//   [70] 鬼  [71] 難しい  [72] 普通  [73] 易しい (70+難易度(Ghensuu.kazeflag 0〜3))
// 値は0なら100%(初期値)、1〜50なら値×10%(10%〜500%)。0%は選べない
//
// ・春の定期支給と、目標順位を達成したときの金銀の量に掛ける
//   (駅伝・駅伝予選・対校戦総合の目標達成と、学連選抜の監督としての目標達成)
// ・プレイヤーの大学は今の難易度の割合、コンピュータの大学は支給レベルの難易度の割合
//   (「プレイヤーと同じ」はプレイヤーの難易度の割合。goldsilver_com.dart)
// ・難易度の表から出した量に掛けて、四捨五入で1の位までにし、そのあとで金銀支給量倍率
//   (yobiint2[12])と、目標1位で優勝したときの2倍を掛ける
// ・大学当局の温情の支給には掛けない
// ------------------------------------------------------------

const int kinginWariaiIndex = 70;

/// 割合の上限・下限(%)
const int kinginWariaiSaidai = 500;
const int kinginWariaiSaishou = 10;

/// 難易度の名前(難易度変更の画面と同じ。kazeflag 0〜3)
const List<String> kinginWariaiNanidoMei = ['鬼', '難しい', '普通', '易しい'];

/// 春の定期支給の表(上ほど良い成績。goldsilverTeikiKakutoku.dart・goldsilver_com.dart と同じ量)
/// 画面で、割合を掛けたあとの量を見せるのに使う
const List<List<int>> kinginTeikiHyou = [
  [50, 45, 40, 35, 30, 20, 10], // 鬼
  [100, 90, 85, 80, 75, 65, 50], // 難しい
  [200, 180, 170, 160, 150, 125, 100], // 普通
  [300, 280, 270, 260, 250, 225, 200], // 易しい
];

/// 目標1位を達成したときの量(優勝したときはさらに2倍。KirokuKousin.dart の rYuushou と同じ量)
const List<int> kinginMokuhyouIchiiRyou = [50, 100, 200, 300];

/// 目標達成のいちばん少ない量(目標をいちばん下の順位にしたときと、駅伝予選の突破)
const int kinginMokuhyouSaiteiRyou = 10;

/// 割合(%)を読む。値が0なら100%(初期値)、1〜50なら値×10%
int kinginWariaiPercent(KantokuData kantoku, int kazeflag) {
  if (kazeflag < 0 || kazeflag > 3) return 100;
  final int index = kinginWariaiIndex + kazeflag;
  if (kantoku.yobiint3.length <= index) return 100;
  final int v = kantoku.yobiint3[index];
  if (v < 1 || v > kinginWariaiSaidai ~/ 10) return 100;
  return v * 10;
}

/// yobiint3に保存する割合の値として正しいか(0〜50。QRコードの読み込みで使う)
bool kinginWariaiAtaiTadashii(int atai) {
  return atai >= 0 && atai <= kinginWariaiSaidai ~/ 10;
}

/// 割合(%)を、yobiint3に保存する値にする(100%は0、それ以外は%÷10)
int kinginWariaiAtai(int percent) {
  int p = percent ~/ 10 * 10;
  if (p < kinginWariaiSaishou) p = kinginWariaiSaishou;
  if (p > kinginWariaiSaidai) p = kinginWariaiSaidai;
  if (p == 100) return 0;
  return p ~/ 10;
}

/// 難易度の表から出した量[ryou]に、その難易度の割合を掛ける(四捨五入で1の位まで)
int kinginWariaiKakeru(int ryou, KantokuData kantoku, int kazeflag) {
  final int percent = kinginWariaiPercent(kantoku, kazeflag);
  if (percent == 100 || ryou <= 0) return ryou;
  return (ryou * percent + 50) ~/ 100;
}
