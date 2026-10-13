import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart'; // 2.0.0の割合の移行の印

// ------------------------------------------------------------
// 新入生の成長タイプの割合(1.9.3)
// ・選手の成長タイプ(SenshuData.seichoutype)で、学年ごとの基本走力の伸びの倍率が決まる
//   (倍率は Ghensuu.seichouryoku_type_gakunen。中身は GhensuuShokika.dart で、1.9.3では変えていない)
// ・新入生の成長タイプは、Ghensuu.seichouryoku_type_sentakuritu の割合(合計100%)で選ぶ
//   (SenshuShokiti.dart。0〜99の乱数で選ぶので、合計はいつも100にする)
// ・1.9.2までは、1年の夏までに上限に届く型(1・5・8・9)が87%で、ほとんどの選手が
//   1年のうちに伸びきってしまい、その後の成長を楽しめなかった。
//   1.9.3から初期値では、1年で伸びきる型を4割にし、残りを2年以降に伸びる6つの型に均等に分けた。
//   (シミュレーションで、名声の低い大学でも、上限まで残り1万mで30秒以内の選手が
//   悪い年でも13人くらいは残るように決めた。名声の高い大学は、入学時の記録が速く上限まで近いので、
//   どの型でも1年のうちに上限に届き、ほとんど変わらない)
// ・割合は説明画面の設定タブの「成長タイプ設定」で変えられる(screens/seichou_type_settei.dart)。
//   全大学共通。各種設定のQRコードにも含める(qr_processor.dart)
// ・変えた割合は、次の4月の新入生と、新規ゲームの1年生から使う。在学中の選手の型は変えない
// ・留学生(いつも型1。ShozokusakiKettei_By_Univmeisei.dart)と、新規ゲームの2〜4年生
//   (初期の育成のための型。main.dart)は、今まで通りで、この割合を使わない
// ・2.0.0から、限界突破のくじの確率にも成長タイプの倍率をかけるようにした(joukai.dart の「限界突破の起こり方」)。
//   上限に届いたあとも型の伸びる学年に伸びるので、1年に伸びる型が多いと1年生が強くなりすぎる
//   (シミュレーションで、秋の全学年の上位100人のうち1年生が1人→7人)。そこで初期値を、ほぼ均等(各9%)にした
//   (1年生は3人、4年生は58人→54人で、今に近い。トップ層の速さは変わらない)。
//   1.9.3〜1.9.9の初期値(seichouType199)のままのデータは、一度だけ新しい初期値にする(seichouType200Ikou)。
//   自分で変えた割合はそのまま。成長タイプ設定の画面に、1.9.9までと1.9.2までの割合にするボタンもある
// ------------------------------------------------------------

/// 割合を決める成長タイプの数(型0〜10。配列は20種類分あるが、11〜19は使わない)
const int seichouTypeSuu = 11;

/// 画面に並べる順(大きく伸びる学年の順)
const List<int> seichouTypeNarabi = [1, 5, 8, 9, 0, 2, 6, 10, 3, 7, 4];

/// 成長タイプの名前(添字は型の番号)
const List<String> seichouTypeMei = [
  '毎年型', // 0
  '1年型', // 1
  '2年型', // 2
  '3年型', // 3
  '4年型', // 4
  '1〜2年型', // 5
  '2〜3年型', // 6
  '3〜4年型', // 7
  '1年・3年型', // 8
  '1年・4年型', // 9
  '2年・4年型', // 10
];

/// 成長タイプの説明(添字は型の番号。倍率の数字は出さない)
const List<String> seichouTypeSetsumei = [
  '毎年同じくらい伸びる', // 0
  '1年に大きく伸びる', // 1
  '2年に大きく伸びる', // 2
  '3年に大きく伸びる', // 3
  '4年に大きく伸びる', // 4
  '1年と2年に伸びる', // 5
  '2年と3年に伸びる', // 6
  '3年と4年に伸びる', // 7
  '1年と3年に伸びる', // 8
  '1年と4年に伸びる', // 9
  '2年と4年に伸びる', // 10
];

/// 割合の初期値(2.0.0から。添字は型の番号、合計100)
/// ほぼ均等(各9%。2年・4年型だけ10%)。限界突破の起こり方を成長タイプに合わせたので、型ごとの特徴が出る
const List<int> seichouTypeShokiti = [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 10];

/// 1.9.3〜1.9.9の初期値(添字は型の番号、合計100)
/// 1年で伸びきる型(1・5・8・9)が40%、2年以降に伸びる型(2・3・4・6・7・10)がほぼ10%ずつ
const List<int> seichouType199 = [1, 34, 10, 10, 9, 4, 10, 10, 1, 1, 10];

/// 1.9.2までの割合(添字は型の番号、合計100)
const List<int> seichouTypeIzen = [1, 75, 7, 1, 1, 10, 1, 1, 1, 1, 1];

/// 今の割合(型0〜10。保存されていない番号は0)
List<int> seichouTypeWariai(Ghensuu gh) {
  return [
    for (int i = 0; i < seichouTypeSuu; i++)
      i < gh.seichouryoku_type_sentakuritu.length
          ? gh.seichouryoku_type_sentakuritu[i]
          : 0,
  ];
}

/// 割合の合計
int seichouTypeGoukei(List<int> wariai) =>
    wariai.fold(0, (int a, int b) => a + b);

/// 割合として正しいか(型0〜10の11個が0〜100で、合計が100。QRコードの読み込みでも使う)
bool seichouTypeWariaiTadashii(List<dynamic> wariai) {
  if (wariai.length != seichouTypeSuu) return false;
  int goukei = 0;
  for (final dynamic v in wariai) {
    if (v is! int || v < 0 || v > 100) return false;
    goukei += v;
  }
  return goukei == 100;
}

/// 2つの割合が同じか
bool seichouTypeWariaiOnaji(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 割合を入れる(保存は呼び出し側で行う。正しくない割合なら何もしない)
/// 型11〜19は使わないので0にする
void seichouTypeWariaiIreru(Ghensuu gh, List<int> wariai) {
  if (!seichouTypeWariaiTadashii(wariai)) return;
  final List<int> atarashii = List<int>.filled(TEISUU.SEICHOUTYPESUU, 0);
  for (int i = 0; i < seichouTypeSuu && i < atarashii.length; i++) {
    atarashii[i] = wariai[i];
  }
  gh.seichouryoku_type_sentakuritu = atarashii;
}

/// 割合を入れて保存する
Future<void> seichouTypeWariaiHozon(Ghensuu gh, List<int> wariai) async {
  if (!seichouTypeWariaiTadashii(wariai)) return;
  seichouTypeWariaiIreru(gh, wariai);
  await gh.save();
}

/// 成長タイプの割合の2.0.0の移行をした印の保存先(KantokuData.yobiint3の番号。1なら移行済み)
const int seichouType200IkouIndex = 76;

/// 2.0.0の移行: 割合が1.9.3〜1.9.9の初期値のままなら、2.0.0の初期値(ほぼ均等)にする(一度だけ)
/// 自分で変えた割合はそのまま。印を付けるので、何度呼んでもよい
/// (main.dart の起動のときと、save_load_screen.dart の読み込みのときに呼ぶ。版の番号では判定しない)
Future<void> seichouType200Ikou(Ghensuu gh, KantokuData kantoku) async {
  if (kantoku.yobiint3.length <= seichouType200IkouIndex) return;
  if (kantoku.yobiint3[seichouType200IkouIndex] == 1) return;
  if (seichouTypeWariaiOnaji(seichouTypeWariai(gh), seichouType199)) {
    await seichouTypeWariaiHozon(gh, seichouTypeShokiti);
  }
  kantoku.yobiint3[seichouType200IkouIndex] = 1;
  await kantoku.save();
}

/// 2.0.0の移行をした印を付ける(保存は呼び出し側で行う)
/// 成長タイプ設定の画面やQRコードで割合を決めたときに付ける(新規ゲームのあと、起動し直す前に
/// 1.9.9までの割合を選んで保存しても、次の起動の移行で新しい初期値に戻されないように)
void seichouType200IkouShirushi(KantokuData kantoku) {
  if (kantoku.yobiint3.length <= seichouType200IkouIndex) return;
  kantoku.yobiint3[seichouType200IkouIndex] = 1;
}
