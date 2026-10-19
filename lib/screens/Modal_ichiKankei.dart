// 情報集約パネル(2.0.6で「区間終了時点の位置関係」として作り、2.0.7で名前を変えた)
// ・2.0.7から、区間を選ぶところの一番左に「スタート」を置く(1区のスタートの前の並び。出場校を大学のID順に
//   並べ、学連選抜は最後。距離はみな0で、順位・順位の変化・シード権ライン・右の括弧は出さない)。
//   大学の四角を押すと、帯に「大学名　目標○位」と1区を走る選手(区間配置確認のカードを開いたときと同じ中身)を
//   出し、もう一度押すと閉じる。1区の指示の画面(mode 350の1区)にもカードを置き、そこではスタートだけを出す。
// ・2.0.7から、区間は「‹」「›」で1つずつ、真ん中を押して出る一覧で好きな区間に切り替える(区間が多くても1行)。
// ・2.0.8から、区間を選ぶ行の右の黄色のボタンを押すたびに、「位置」(道の位置関係)→「通過」(通過順位速報)→
//   「個人」(個人順位速報)→「位置」と表示を切り替える。通過と個人は、今の速報の画面を、上のバーと下の「前・次」を
//   外して入れたもの(Modal_tuukajuni.dart・Modal_kukanresult350.dart(レースの途中)・Modal_kukanresult.dart
//   (結果画面)の umekomi)で、区間はパネルで選んだ区間。スタートでは、まだないことを出す。
//   通過と個人のときは、倍率の行を隠し、押した大学の帯は閉じる。覚えない(開いたときは「位置」)。
//   スタートしかないとき(1区の指示の画面)は、ボタンを出さない。
// ・2.0.9から、切り替えボタンの4つ目に「配置」(区間配置確認)を足した(位置 → 通過 → 個人 → 配置 → 位置。
//   スタートしかないとき(1区の指示の画面)は、位置 → 配置 → 位置)。区間配置確認の画面を、上のバー(共有のボタンも)・
//   大学を選ぶ行・下の「戻る」を外して入れたもの(Modal_kukanhaiti2.dart の umekomi)。配置のときは、区間を選ぶ欄が
//   大学を選ぶ欄(「‹」「›」は端まで行くと反対の端に回る。一覧は出場校のID順で、学連選抜がいる年は最後に学連選抜)に
//   入れ替わる。最初は自分の大学(学連選抜の監督の年は学連選抜。自分の大学が出ていない年は、ID順の最初の大学)で、
//   画面を閉じるまで選んだ大学を覚える。大学名は1行に収め、入りきらないところは「…」で省く。
// ・2.0.8から、おまかせのときに「おまかせ」をもう一度押すと「おまかせ ↔」(幅に合わせる)になり、道が横幅に収まるように、
//   道の上の文字(四角の中・右の差・シード権ライン)を小さくする(6割まで。それでも入らなければ
//   横にスクロールする)。縦の縮尺は変えない。もう一度押すと戻り、「−」「＋」を押すと、おまかせと一緒に外れる。覚えない。
// レースの途中の区間ごとの画面(mode 350)と、結果画面(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝)の、
// 区間ごとのタイム分布と1枚にまとめたカード(KukanBunsekiCard。右半分の「位置関係」)から開く。
// ・幅のある道の帯に、大学名を四角で囲んで並べ、1位からの距離を縮尺どおりの間隔で出す。
//   四角の中の大学名は、最後の「大」を省く(下の帯の文は省かない)。学連選抜は四角の中では「OP学連」。
//   2.1.0から、四角の中を順位・大学名・順位の変化の欄に分け、区間の中ではどの四角も同じ幅にする
//   (大学名の欄は2文字分で左寄せ。長い名前は横だけ縮め、5割まで縮めても入らなければ最後を「…」で省く)。
//   大学名の後ろに、前の区間の終了時点からの順位の変化を「↑2」(緑)「↓3」(赤)「→」(灰色)で付ける
//   (1区は付けない。学連選抜は通過順位相当で比べる。下の帯にも「5位(↑3)」の形で出す)。
// ・集団(2.1.0から): 前の大学との差が1秒以内(右の括弧と同じ切り捨ての秒。「並走」か「1秒」)なら、
//   同じ集団としてつなげる(長さの上限はなし。拡大・縮小しても変わらない)。シード権ラインと詰めた間では分ける。
//   (2.0.9までは、画面の上で四角1つ分より近い大学をつなげていたので、倍率が小さいと100m以上離れた大学も
//   同じ枠に入り、集団走のように見えていた)
//   集団の中は、先頭と同じ秒の大学を1行目に横に並べ、1秒遅れるごとに次の行にし、秒が変わった行の右に
//   「+1秒」を出す(同じ秒で入りきらずに折り返した行には出さない)。
//   1行に並べる数は3校までで、「四角の行 + 右の括弧と差の文」が画面の幅に入る一番大きい数(3→2→1)にする
//   (_gyouSuuKimeru。パネルで見られる全部の区間で決め、画面を閉じるまで同じ)。
//   集団でない大学は1校ずつ縦に並べ、どの間にも右の括弧と差を出す。
//   集団の一番上の行は、前の大学(前が集団なら、その一番下の行)から、間の距離ぶん下に置き、
//   集団のあとの大学は、集団の一番下の行を起点にして、集団の最後の大学との間の距離ぶん下に置く。
//   四角が重なるほど近いときは、重ならないところまで下に広げて置く(印は付けない。右の数字が本当の差)。
//   2校以上の集団は、四角にぴったり合わせた薄い枠で囲む。集団どうしは、枠がくっつかないよう10px以上空ける。
//   2.1.0から、四角を行ごとに道の左右の真ん中に置く(集団は隊列のような形になる。「+1秒」は四角の右に出し、
//   枠は道の真ん中を軸に左右同じ幅で囲む。行が道より広いときは、今まで通り左から並べて横にスクロール)。
// ・画面の説明の文は短くし(「○区終了時点のタイム差を、区間の平均の速さで距離に換算した位置関係の図です」
//   と、括弧・色・押したときのこと)、おまかせと集団の説明は説明書に書く。
// ・道の右に、前の大学(集団)との間を示す括弧を引き、その真ん中に間の距離と秒差を出す。
//   2.1.0から、距離と秒差を2行にし(「90m」の下に「16秒」)、文字を少し小さく(12→11)して幅を抑えた。
//   文字を大きくしても文が括弧からずれないように、集団どうしの間は2行の文が収まる高さより狭くしない。
//   括弧は、前の集団の一番下の行の真ん中から、次の集団の一番上の行の真ん中まで。集団の中の間は出さない。
//   (1位との差を出していたが、隣どうしの間が縮尺どおりなので、間を出すほうが分かりやすいため、2.0.6の開発中に変えた)
// ・四角と間の文は折り返さず、道と四角と間の文の部分だけを横にもスクロールできるようにする
//   (文字を大きくしても、文の長さで行がずれて、距離と位置が合わなくならないように)。
// ・大学の四角を押すと、その大学の順位・1位との差・前の大学(1位は次の大学)との差を、
//   画面の下に固定した帯に出す。
//   もう一度押すと、帯の中に、その区間を走った選手の説明文(個人順位速報の「説明文」と同じ文)も出し、
//   3回目で、説明文の代わりに次の区間を走る選手(区間配置確認のカードを開いたときと同じ中身。
//   senshu_haichi_panel.dart の部品)を出し、4回目で閉じる。最終区など次の区間の選手がいなければ3回目で閉じる。
//   2.1.0から、2回目は説明文の下に走った選手の、3回目は次の区間を走る選手の、持ちタイムの表と能力(1行に1つ)を
//   同じ並びで出す(_kirokuToNouryoku。カードの能力の行は、下の能力に全部入るので出さない)。
//   開いたまま、ほかの四角を押すと、同じ段のままその大学に切り替える。
//   帯の一番上の行(差の基準と閉じる「×」)は固定し、その下は、まとめて帯の中でスクロールする。
//   同じ段のまま、ほかの大学の四角を押したときは、帯のスクロールの位置を保つ(次の区間の選手は持ちタイムの表、
//   説明文は本文の始まりが、切り替える前と同じ高さに来るようにする。測れなければスクロールの量をそのまま保つ)。
//   同じ大学で段が進んだときと、区間を切り替えたときは、先頭に戻す。
//   帯が伸びて押した四角が隠れるときは、道を動かして見えるようにする(2.0.7)。
//   説明文の上の行(走った選手)にも、区間配置確認と同じ「詳細」を置き、選手の詳細の画面を開けるようにする。
// ・下の帯の一番上の「差の基準」で、1位との差の代わりに、押した大学それぞれの目標順位との差を出せる(2.0.7)。
//   目標より下なら目標の順位の大学との差(「目標3位(東湊大)と120m +22秒」)、目標以内なら目標の1つ下の大学との
//   差(「目標3位以内　4位の白鷺大に250m 45秒のリード」。区間ごとの画面の「○位との差」と同じ考え)。
//   学連選抜は、レースの計算と同じ学連選抜の目標(監督をしていれば決めた順位、ほかは10位)で、順位は相当で比べる。
//   目標順位は今の値(正月駅伝で復路の目標を決め直したあとは、往路の区間も決め直したあとの目標で出す)。
//   選んだ基準は、大学や区間を替えてもそのままで、覚えない(画面を閉じたらトップに戻る)。
// ・区間の切り替えと、表示の倍率のボタン・縮尺の棒は、画面の上に固定する(どちらも折り返す)。
//   固定の部分は、上のバーを除いた高さの3割までで、超えるときは固定の部分の中だけでスクロールする。
// ・押した大学の帯は、道の下(画面の一番下)に置き、上のバーを除いた高さの4割5分までにする。
//   道にはいつも4分の1以上を残す(小さいスマホで文字を大きくしても、道が消えて四角を押せなくならないように。
//   2.0.6は、固定の部分が画面の高さの4割まで、帯は「戻る」の上の固定で、高さを抑えていなかった。2.0.7)
// ・画面の一番下の「戻る」は、2.0.7でなくした(道を広くするため。左上の「←」と、Androidの戻る操作で閉じる)。
// ・距離は「1位が区間を走り終えたとき、ほかの大学がどれだけ後ろにいるか」を、その区間の出場校の
//   区間タイムの平均から出した速さ(全員で同じ。学連選抜は平均に入れない)で、タイム差から換算したもの。
//   速さを全員で1つにするので、距離はタイム差に比例し、順位と位置の並びが逆にならない
//   (ゲームとしての見せ方。1位が着いた時点か最後の大学が着いた時点か、などは考えない)。
// ・1区から終わった区間まで切り替えられる(覚えない。開くたびに一番あとの区間)。
// ・前の大学との間のうち、飛び抜けて大きい間(その区間の間の中央値の4倍以上。大きい順に多くて3か所。
//   _tobinukeAida)だけを詰めて、道に切れ目の点線を引き、右の括弧を点線にする(2.0.9までは「(詰めています)」を
//   添えていた。2.1.0の開発中に「(途中を省略)」にしたが、幅を取るので添え書きはなくし、点線で示す)。
//   倍率ではなくデータで決めるので、
//   だいたい同じくらい空いているときは詰めない。1つの間が画面の高さを超えるところも詰める
//   (拡大しすぎて、何もない道を延々とスクロールしないように。2.0.9までは手動で倍率を選んでいるときだけ。
//   2.1.0から、おまかせが×2より小さくならないので、おまかせでも詰める)。
//   (最初は「画面で144pxを超えたら」詰めていたが、おまかせの倍率とぶつかり、出場校の少ない大会や
//   差の開いた区間で、ほとんどの間が詰められて位置関係がつかめなかったので、2.0.6の開発中に変えた)
// ・表示の倍率(1mあたりの高さ)は「−」「＋」で6段階に変えられる(文字の大きさは変わらない)。
//   開いたときは「おまかせ」(区間ごとに、詰めた間を除いた1位から最後尾までの長さが、画面の高さの
//   およそ2つ分に収まる一番大きい倍率。大きく遅れた大学に引っぱられて先頭のほうが縮こまらないように)。
//   2.1.0から、おまかせは×2より小さくしない(_omakaseSaitei。差の開いた区間で×1/2などになると、100mの差も
//   10mの差も四角が重ならない一番小さい間隔になり、同じに見えていたため。×2なら100mが四角2つ分ほどになる)。
//   縦が長くなるので、道の右端につまんで動かせるスクロールバーを出し、説明の「オレンジの枠」の行を押すと
//   自分の大学(学連選抜の監督の年は学連選抜)が見える所まで動くようにした。
//   「−」「＋」を押すとおまかせが外れ、区間を切り替えてもその倍率のまま。
//   覚えない(画面を閉じたらおまかせに戻る)。倍率のボタンの横に縮尺の棒を出す。
// ・11月駅伝は8位、正月駅伝は10位の下にシード権ラインを引く(10月駅伝とカスタム駅伝はなし)。
//   ラインをまたいでは集団にしない。詰めた間のあとも新しい集団にする。
// ・四角の見た目: 自分の大学はオレンジの枠(文字と塗りはほかの大学と同じ)、1位は太い白の枠、学連選抜(正月駅伝のオープン参加)は
//   点線の枠(学連選抜の監督をした年はオレンジの点線)。学連選抜は順位とシード権ラインに数えない。
// ・距離は1kmまでは10m単位、1km以上は「1.2km」。秒は画面と同じく切り捨ててから引き(saByou)、
//   距離はその秒から出す。間が0秒なら「並走」。四角を押したときの下の帯では、1位との差
//   (「180m +33秒」。0秒なら「トップと並走」)と前の大学との差を出す。
// ・結果は記事と同じ EkidenKekka(kiji_kekka.dart)から作る。レースの途中は1区から終わった区間まで。
//   新しく保存するものはない。作れなければカードを出さない。
// ・2.0.6の開発中に、点と名前の行の形から四角の形に変え、2枚あったカード(タイム分布と位置関係)を
//   見出しだけの1枚にした。

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/shushou.dart'
    show shushouShirushi, shushouKaIma; // 主将の印(個人順位速報・区間配置確認と同じ。2.0.7)
import 'package:ekiden/kansuu/konki_best.dart'; // 今季ベスト(区間配置確認と同じ設定。2.0.7)
import 'package:ekiden/screens/shushou_iro.dart'; // 主将を示す色(区間配置確認と同じ。2.0.7)
import 'package:ekiden/screens/senshu_haichi_panel.dart'; // 区間配置確認のカードの部品(2.0.7)
import 'package:ekiden/screens/Modal_tuukajuni.dart'
    show ModalKukanResultListViewPass; // 通過順位速報(パネルの中に入れる。2.0.8)
import 'package:ekiden/screens/Modal_kukanresult350.dart'
    show ModalKukanResultListView350; // 個人順位速報(レースの途中。2.0.8)
import 'package:ekiden/screens/Modal_kukanresult.dart'
    show ModalKukanResultListView; // 個人順位速報(結果画面。2.0.8)
import 'package:ekiden/screens/Modal_kukanhaiti2.dart'
    show ModalKukanHaitiView, kukanHaitiGakurenId; // 区間配置確認(パネルの中に入れる。2.0.9)
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/screens/Modal_kukanTimeBunpu.dart'
    show KukanBunpuYomikomi, kukanBunpuYomu, kukanBunpuGamenHiraku;

/// 表示の倍率の段階(1mあたりの高さ(px))と名前(×1は、最初に作ったときの決め打ちの倍率)
const List<double> _bairitsu = [0.1, 0.2, 0.4, 0.8, 1.6, 3.2];
const List<String> _bairitsuMei = ['×1/4', '×1/2', '×1', '×2', '×4', '×8'];

/// おまかせの倍率: 1位から最後尾までが、画面の高さのこの倍に収まる一番大きい倍率
const double _omakaseGamen = 2.0;

/// おまかせの倍率の下限(_bairitsu の番号。3は×2。100mの差が四角2つ分ほどの間になる。2.1.0)
const int _omakaseSaitei = 3;

/// 幅に合わせる(おまかせ ↔)ときに、道の上の文字を小さくする下限(今の文字の大きさに対する割合。2.0.8)
const double _habaSaishou = 0.6;

/// 飛び抜けて大きい間: その区間の間の中央値の、この倍以上
const double _tobinukeBai = 4;

/// 飛び抜けて大きい間として詰めるのは、大きい順に多くてこの数まで
const int _tobinukeSaidai = 3;

/// 飛び抜けて大きい間の下限(m。並走が多くて中央値が0に近いときに、小さな間を詰めないように)
const double _tobinukeSaitei = 50;

/// 詰めたところの高さ(px)
const double _tsumePx = 52;

/// 道の帯の右に置く括弧と差の文の、文以外の幅(括弧までのすきま6・括弧から文まで14・文の右の余白8)
/// (2.1.0から、道の帯は画面の幅からこの幅と差の文の幅を引いた残り全部にする。2.0.9までは画面の幅の6割と
/// 決めていたが、差の文を2行にして細くしたら、右に大きな余白が残ったため。四角の行のほうが広いときは
/// 四角に合わせ、はみ出したぶんは横にスクロールする)
const double _migiYohaku = 6.0 + 14.0 + 8.0;

/// 集団の1行に並べる大学の数の上限(画面の幅に合わせて、これ以下で決める。_gyouSuuKimeru。2.1.0)
const int _gyouSaidai = 3;

/// 前の大学との差がこの秒以内なら、同じ集団にする(右の括弧と同じ切り捨ての秒。2.1.0)
const int _shuudanByou = 1;

/// 詰めた間の括弧の文に添える言葉

/// 四角どうし・行どうしのすきま
const double _sukima = 4;

/// 集団(1校だけのときも)どうしの最小のすきま(枠どうしがくっつかないように)
const double _shuudanSukima = 10;

/// 四角の左端(集団の枠の内側の余白のぶん、道の端から空ける)
const double _hakoHidari = 8;

/// 集団の枠の、四角のまわりの余白
const double _wakuYohaku = 4;

/// 四角の中の余白(横・縦)
const double _hakoYoko = 6;
const double _hakoTate = 3;

/// 四角の中の大学名の欄の文字数(どの四角も同じ幅にする。長い名前は横に縮める。2.1.0。
/// 開発中に3文字分で作ったが、四角を狭くするため2文字分にした)
const int _meiMojisuu = 2;

/// 大学名を横に縮める下限(これより縮めないと入らないときは、最後を「…」で省く。2.1.0。
/// 2文字分の欄に4文字の名前が入るように5割にした)
const double _meiChijimiSaishou = 0.5;

/// 四角の中の、順位と大学名のすきま・大学名と順位の変化のすきま(2.1.0)
const double _juniSukima = 4;
const double _hendouSukima = 3;

/// 四角の中の文字(順位と「OP」・大学名・順位の変化。順位の変化の色は変化ごとに付ける)
const TextStyle _juniStyle = TextStyle(color: Colors.white54, fontSize: 11.5);
const TextStyle _meiStyle = TextStyle(color: HENSUU.textcolor, fontSize: 13);
const TextStyle _hendouStyle = TextStyle(fontSize: 12);

/// 区間の四角の中の欄の幅と文の高さ(区間の中ではどの四角も同じ。2.1.0)
class _HakoHaba {
  /// 順位の欄(学連選抜の「OP」も。なければ0)
  final double juni;

  /// 大学名の欄(_meiMojisuu 文字分)
  final double mei;

  /// 順位の変化の欄(1区とスタートは0)
  final double hendou;

  /// 文の高さ
  final double takasa;

  const _HakoHaba(this.juni, this.mei, this.hendou, this.takasa);

  /// 中身の幅(欄とすきまの合計)
  double get naka =>
      juni + (juni > 0 ? _juniSukima : 0) + mei + (hendou > 0 ? _hendouSukima + hendou : 0);
}

/// 四角の枠の太さの最大(四角の大きさを決めるときに、これだけ見込む)
const double _wakuSaidai = 2;

/// 道の帯の色
const Color _michiIro = Color(0xFF1C1C1C);

/// カードと位置関係の色
const Color _iro = Colors.lightBlueAccent;

/// 自分の大学の色(区間ごとのタイム分布と同じ)
const Color _jibunIro = Colors.orangeAccent;

/// 道の中の四角に出す大学名(最後の「大」を省く。「東湊大」→「東湊」。省くと空になるときはそのまま)
String _michiMei(String mei) =>
    (mei.length > 1 && mei.endsWith('大')) ? mei.substring(0, mei.length - 1) : mei;

/// 道の右の括弧の秒差の文(1分未満は「40秒」、1分以上は「3'40"」。2.1.0。
/// 幅を抑えるため、記事などの「3分40秒」(saMoji)より短い、今季タイム一覧表のタイムと同じ書き方にする。
/// 四角を押したときの下の帯は、場所に余裕があるので「3分40秒」のまま)
String _aidaByouMoji(int sa) {
  final int s = sa.abs();
  if (s < 60) return '$s秒';
  return '${s ~/ 60}\'${(s % 60).toString().padLeft(2, '0')}"';
}

/// 距離の文(「180m」「1.2km」。1kmまでは10m単位)
String _kyoriMoji(double m) {
  final int r = (m / 10).round() * 10;
  if (r < 1000) return '${r}m';
  return '${(m / 1000).toStringAsFixed(1)}km';
}

/// 区間順位(個人順位速報と同じく大学データの区間順位。なければ結果から数えた順位。2.0.7)
int _kukanJuniYomu(EkidenUnivKekka x, int kk) {
  final List<int> kj = x.u.kukanjuni_taikai;
  if (kj.length > kk && kj[kk] >= 0 && kj[kk] != TEISUU.DEFAULTJUNI) return kj[kk];
  return x.kukanJuni[kk];
}

/// 大学1校分(学連選抜も)
class _IchiDaigaku {
  final String mei;

  /// 区間終了時点の累計タイム
  final double ruikei;

  /// 区間終了時点の順位(0が1位。学連選抜は-1)
  final int juni;

  /// 自分の大学か
  final bool jibun;

  /// 学連選抜(オープン参加)か
  final bool op;

  /// 前の区間の終了時点からの順位の変化(上げた数がプラス、下げた数がマイナス、同じなら0。
  /// 1区はnull。学連選抜は通過順位相当で比べる。2.0.6)
  final int? hendou;

  /// 学連選抜の通過順位相当(0が1位相当。大学はnull)
  final int? soutouJuni;

  /// その区間を走った選手(大学は senshu、学連選抜は gSenshu。分からなければnull。
  /// 四角を2回押したときの説明文に使う。2.0.7)
  final SenshuData? senshu;
  final Senshu_Gakuren_Data? gSenshu;

  /// 学連選抜の選手の所属大学の名前(大学はnull)
  final String? shozoku;

  /// 区間順位(0が1位。学連選抜は区間順位相当)
  final int? kukanJuni;

  /// 区間タイム
  final double? kukanTime;

  /// 次の区間を走る選手(大学は tsugiSenshu、学連選抜は tsugiGSenshu。最終区などはnull。
  /// 四角を3回押したときに、区間配置確認のカードを開いたときと同じ中身を出す。2.0.7)
  final SenshuData? tsugiSenshu;
  final Senshu_Gakuren_Data? tsugiGSenshu;

  const _IchiDaigaku(
    this.mei,
    this.ruikei,
    this.juni,
    this.jibun,
    this.op, {
    this.hendou,
    this.soutouJuni,
    this.senshu,
    this.gSenshu,
    this.shozoku,
    this.kukanJuni,
    this.kukanTime,
    this.tsugiSenshu,
    this.tsugiGSenshu,
    this.mokuhyou,
  });

  /// 目標順位(0が1位。学連選抜は学連選抜の目標。分からなければnull。差の基準を目標順位にしたときに使う。2.0.7)
  final int? mokuhyou;

  /// 次の区間を走る選手がいるか
  bool get tsugiAri => tsugiSenshu != null || tsugiGSenshu != null;

  /// 走った選手の詳細の画面を開くときの選手id(区間配置確認と同じ。分からなければnull。2.0.7)
  int? get shousaiId => senshu?.id ?? gSenshu?.id;

  /// 走った選手の説明文(個人順位速報の「説明文」と同じ。末尾の改行は省く。なければnull。2.0.7)
  String? get setsumei {
    final String? s = senshu?.string_racesetumei ?? gSenshu?.string_racesetumei;
    if (s == null) return null;
    final String t = s.trimRight();
    return t.isEmpty ? null : t;
  }

  /// 順位の変化の文(「↑2」「↓3」「→」。1区はnull)
  String? get hendouMoji {
    final int? h = hendou;
    if (h == null) return null;
    if (h > 0) return '↑$h';
    if (h < 0) return '↓${-h}';
    return '→';
  }
}

/// 区間1つ分の位置関係
class _IchiKukan {
  /// 区間(0が1区。-1はスタート。2.0.7)
  final int kk;

  /// 区間の平均の速さ(m/秒)
  final double hayasa;

  /// 累計タイムの順(学連選抜も入る)
  final List<_IchiDaigaku> narabi;

  _IchiKukan(this.kk, this.hayasa, this.narabi);

  /// 1位(学連選抜を除く)
  _IchiDaigaku get top => narabi.firstWhere((x) => !x.op, orElse: () => narabi.first);

  /// [x]の、1位との差(秒。画面と同じく切り捨ててから引く。1位より前の学連選抜はマイナス)
  int sa(_IchiDaigaku x) => saByou(x.ruikei, top.ruikei);

  /// 1kmあたりのタイム(秒)
  int get pace => hayasa > 0 ? (1000 / hayasa).round() : 0;

  /// 1位との差の文(距離が先。「トップ」「180m +33秒」「トップと並走」「トップより30m前 5秒」)
  String saBun(_IchiDaigaku x) {
    if (identical(x, top)) return 'トップ';
    final int s = sa(x);
    if (s == 0) return 'トップと並走';
    if (s < 0) return 'トップより${_kyoriMoji(-s * hayasa)}前 ${saMoji(s)}';
    return '${_kyoriMoji(s * hayasa)} +${saMoji(s)}';
  }

  /// [x]の目標順位との差の文(差の基準を目標順位にしたとき。2.0.7)
  /// 目標より下なら「目標3位(東湊大)と120m +22秒」、目標以内なら「目標3位以内　4位の白鷺大に250m 45秒のリード」。
  /// 学連選抜は順位相当で比べる(目標以内なら、押し出される目標の順位の大学とのリード)
  String mokuhyouBun(_IchiDaigaku x) {
    final int? t = x.mokuhyou;
    if (t == null || t < 0) return '目標順位なし';
    // 大学だけの順位の順(学連選抜は入れない。並びの番号が順位)
    final List<_IchiDaigaku> daigaku = [for (final _IchiDaigaku y in narabi) if (!y.op) y];
    _IchiDaigaku? juniNo(int j) => (j >= 0 && j < daigaku.length) ? daigaku[j] : null;
    // 目標以内のときの、目標の1つ下の大学とのリードの文
    String lead(_IchiDaigaku ushiro) {
      final int s = saByou(ushiro.ruikei, x.ruikei);
      return s <= 0 ? 'と並走' : 'に${_kyoriMoji(s * hayasa)} ${saMoji(s)}のリード';
    }

    final String soutou = x.op ? '相当' : '';
    final int jibunJuni = x.op ? (x.soutouJuni ?? 0) : x.juni;
    final _IchiDaigaku? mokuhyouDaigaku = juniNo(t);
    if (jibunJuni > t) {
      // 目標より下: 目標の順位の大学との差
      if (mokuhyouDaigaku == null) return '目標${t + 1}位$soutou';
      return '目標${t + 1}位$soutou(${mokuhyouDaigaku.mei})と${futatsuBun(x, mokuhyouDaigaku)}';
    }
    // 目標以内: 目標の1つ下の大学(学連選抜は、押し出される目標の順位の大学)とのリード
    final int ushiroJuni = x.op ? t : t + 1;
    final _IchiDaigaku? ushiro = juniNo(ushiroJuni);
    if (ushiro == null) return '目標${t + 1}位以内$soutou';
    return '目標${t + 1}位以内$soutou　${ushiroJuni + 1}位の${ushiro.mei}${lead(ushiro)}';
  }

  /// 2つの大学の間の文(道の右の括弧に出す。間なので「+」を付けない。0秒は「並走」)
  /// 2.1.0から、幅を抑えるため距離と秒差を2行にし(「90m」の下に「16秒」)、1分以上の秒差は
  /// 今季タイム一覧表のタイムと同じ「3'40"」の形にする(_aidaByouMoji)
  String aidaBun(_IchiDaigaku osoi, _IchiDaigaku hayai) {
    final int s = saByou(osoi.ruikei, hayai.ruikei);
    if (s <= 0) return '並走';
    return '${_kyoriMoji(s * hayasa)}\n${_aidaByouMoji(s)}';
  }

  /// 2つの大学の差の文(距離が先。「30m +5秒」。0秒は「並走」)
  String futatsuBun(_IchiDaigaku osoi, _IchiDaigaku hayai) {
    final int s = saByou(osoi.ruikei, hayai.ruikei);
    if (s <= 0) return '並走';
    return '${_kyoriMoji(s * hayasa)} +${saMoji(s)}';
  }

  /// 名前の行を押したときの、前の大学(1位は次の大学)との差の文
  String maeBun(int i) {
    if (i == 0) {
      if (narabi.length < 2) return '';
      final _IchiDaigaku tsugi = narabi[1];
      final String s = futatsuBun(tsugi, narabi[0]);
      return s == '並走'
          ? '次の${_yobi(tsugi)}と並走'
          : '次の${_yobi(tsugi)}とは$s';
    }
    final _IchiDaigaku mae = narabi[i - 1];
    final String s = futatsuBun(narabi[i], mae);
    return s == '並走' ? '前の${_yobi(mae)}と並走' : '前の${_yobi(mae)}とは$s';
  }

  String _yobi(_IchiDaigaku x) => x.op ? '学連選抜' : x.mei;
}

/// 位置関係のもとになる結果(位置関係の画面と、カードで使う)
class _IchiKankei {
  /// 1区から順
  final List<_IchiKukan> kukan;

  /// シード権の数(11月駅伝8・正月駅伝10。ほかの大会はnull)
  final int? seed;

  /// 学連選抜の監督をした年か(学連選抜をオレンジの白抜きにする)
  final bool gakurenJibun;

  /// 大会の区間数
  final int zenKukansuu;

  /// 大会番号
  final int race;

  /// 配置(区間配置確認)で選べる大学(出場校のID順。学連選抜がいる年は最後に学連選抜。2.0.9)
  final List<({int id, String mei})> haichiDaigaku;

  _IchiKankei._(
    this.kukan,
    this.seed,
    this.gakurenJibun,
    this.zenKukansuu,
    this.race,
    this.haichiDaigaku,
  );

  /// 大会[race]の結果から作る([made] を渡すと、レースの途中の1区から[made]区まで)
  /// (思わぬデータで画面が止まらないよう、作れなければnull)
  /// [made] が0なら、1区のスタートの前(スタートの並びだけ。2.0.7)
  static _IchiKankei? yomu(int race, {int? made}) {
    try {
      return _yomuHontai(race, made);
    } catch (e, st) {
      debugPrint('[情報集約パネル] 作れませんでした: $e\n$st');
      return null;
    }
  }

  static _IchiKankei? _yomuHontai(int race, int? made) {
    // レースの途中は、実況(kiji_jikkyou.dart)と同じく結果の記事ではない形で読む
    final KijiKankyou? k = KijiKankyou.yomuRace(race, kekka: made == null);
    if (k == null || !k.ekiden) return null;
    if (made != null && made < 0) return null;
    // 1区のスタートの前(made が0)は結果がないので、スタートの並びだけを作る(2.0.7)
    final bool startMae = made != null && made == 0;
    final EkidenKekka? e = startMae ? null : EkidenKekka.tsukuru(k, made: made);
    if (!startMae && e == null) return null;
    final UnivData? my = k.jibunUniv;
    final bool gakurenAri = race == 2 && gakurenKonnenAri(k.gh);
    // 自分の大学が出場していないか(学連選抜の監督をする年)
    final bool jibunNashi = e != null ? e.jibun == null : !(my != null && k.shutsujou(my));
    final bool gakurenJibun =
        gakurenAri && jibunNashi && my != null && gakurenKantokuChuu(k.kantoku, my);
    final List<double> kyoriIchiran = k.gh.kyori_taikai_kukangoto.length > race
        ? k.gh.kyori_taikai_kukangoto[race]
        : const <double>[];
    // 区間ごとの、区間エントリーの選手(区間 → 大学id → 選手。次の区間を走る選手に使う。2.0.7)
    final Map<int, Map<int, SenshuData>> entryHyou = {};
    for (final SenshuData s in k.senshu) {
      final int en = k.entry(s);
      if (en >= 0) (entryHyou[en] ??= <int, SenshuData>{})[s.univid] = s;
    }
    final List<_IchiKukan> kukan = [];
    // スタート(1区のスタートの前の並び。いつも一番左。2.0.7)
    final _IchiKukan? start = _startTsukuru(k, race, entryHyou, gakurenAri);
    if (start != null) kukan.add(start);
    for (int kk = 0; e != null && kk < e.ks; kk++) {
      final double kyori = kyoriIchiran.length > kk ? kyoriIchiran[kk] : 0.0;
      // 次の区間(最終区のあとはなし)
      final bool tsugiKukanAri = kk + 1 < k.kukansuu;
      final Map<int, SenshuData>? tsugiHyou = tsugiKukanAri ? entryHyou[kk + 1] : null;
      if (kyori <= 0) continue;
      // 区間終了時点の順(通過順位。記事と同じ並び)
      final List<EkidenUnivKekka> l = [
        for (final EkidenUnivKekka x in e.jun)
          if (x.ruikei[kk] > 0 &&
              x.ruikei[kk] < TEISUU.DEFAULTTIME &&
              x.kukanTime[kk] > 0 &&
              x.kukanTime[kk] < TEISUU.DEFAULTTIME)
            x,
      ]..sort((a, b) => a.tuuka[kk].compareTo(b.tuuka[kk]));
      if (l.length < 2) continue;
      // 区間の平均の速さ(出場校の区間タイムの平均から。学連選抜は入れない)
      double goukei = 0;
      for (final EkidenUnivKekka x in l) {
        goukei += x.kukanTime[kk];
      }
      final double heikin = goukei / l.length;
      if (heikin <= 0) continue;
      final List<_IchiDaigaku> narabi = [
        for (int i = 0; i < l.length; i++)
          _IchiDaigaku(
            l[i].mei,
            l[i].ruikei[kk],
            i,
            l[i].u.id == k.gh.MYunivid,
            false,
            // 前の区間の終了時点の通過順位から、いくつ上げたか(1区はなし)
            hendou: kk > 0 ? l[i].tuuka[kk - 1] - l[i].tuuka[kk] : null,
            // 走った選手と区間順位・区間タイム(四角を2回押したときの説明文に使う。2.0.7)
            senshu: l[i].senshu[kk],
            kukanJuni: _kukanJuniYomu(l[i], kk),
            kukanTime: l[i].kukanTime[kk],
            tsugiSenshu: tsugiHyou?[l[i].u.id],
            mokuhyou: l[i].u.mokuhyojuni.length > race ? l[i].u.mokuhyojuni[race] : null,
          ),
      ];
      final GakurenKukanKekka? g = gakurenAri ? gakurenKukanKekka(k.gh, kk) : null;
      if (g != null && g.tuukaTime > 0 && g.tuukaTime < TEISUU.DEFAULTTIME) {
        // 学連選抜は、同じタイムの大学より後ろに入れる
        int basho = narabi.length;
        for (int i = 0; i < narabi.length; i++) {
          if (g.tuukaTime < narabi[i].ruikei) {
            basho = i;
            break;
          }
        }
        // 学連選抜の順位の変化は、通過順位相当で比べる(1区はなし)
        final int? gMae = g.maeTuukaJuni;
        narabi.insert(
          basho,
          _IchiDaigaku(
            '学連選抜',
            g.tuukaTime,
            -1,
            false,
            true,
            hendou: gMae == null ? null : gMae - g.tuukaJuni,
            soutouJuni: g.tuukaJuni,
            gSenshu: g.senshu,
            shozoku: g.shozoku,
            kukanJuni: g.kukanJuni,
            kukanTime: g.kukanTime,
            tsugiGSenshu: tsugiKukanAri ? gakurenKukanSenshu(kk + 1) : null,
            // 学連選抜の目標(レースの計算と同じく、監督をしていれば決めた順位、ほかは10位)
            mokuhyou: gakurenMokuhyouGenzai(),
          ),
        );
      }
      kukan.add(_IchiKukan(kk, kyori / heikin, narabi));
    }
    if (kukan.isEmpty) return null;
    // レースの途中と結果画面で、区間が1つも作れなければ(思わぬデータ)、今まで通り出さない
    if (!startMae && !kukan.any((r) => r.kk >= 0)) return null;
    final int? seed = e != null ? e.seedSuu : (race == 1 ? 8 : (race == 2 ? 10 : null));
    // 配置(区間配置確認)で選べる大学(区間配置確認の大学を選ぶ行と同じ。2.0.9)
    final List<({int id, String mei})> haichiDaigaku = [
      for (final UnivData u in k.univ)
        if (k.shutsujou(u)) (id: u.id, mei: u.name),
      if (gakurenAri) (id: kukanHaitiGakurenId, mei: '学連選抜(OP)'),
    ];
    return _IchiKankei._(kukan, seed, gakurenJibun, k.kukansuu, race, haichiDaigaku);
  }

  /// スタートの並び(出場校を大学のID順に並べ、学連選抜は最後。距離はみな0。
  /// 押すと1区を走る選手を出すので、tsugiSenshu に1区の選手を入れる。2.0.7)
  static _IchiKukan? _startTsukuru(
    KijiKankyou k,
    int race,
    Map<int, Map<int, SenshuData>> entryHyou,
    bool gakurenAri,
  ) {
    final Map<int, SenshuData>? ikku = entryHyou[0];
    final List<UnivData> univs = [
      for (final UnivData u in k.univ)
        if (k.shutsujou(u)) u,
    ]..sort((a, b) => a.id.compareTo(b.id));
    final List<_IchiDaigaku> narabi = [
      for (int i = 0; i < univs.length; i++)
        _IchiDaigaku(
          daigakuMei(univs[i]),
          0,
          i,
          univs[i].id == k.gh.MYunivid,
          false,
          tsugiSenshu: ikku?[univs[i].id],
          mokuhyou: univs[i].mokuhyojuni.length > race ? univs[i].mokuhyojuni[race] : null,
        ),
    ];
    if (gakurenAri) {
      final Senshu_Gakuren_Data? g = gakurenKukanSenshu(0);
      if (g != null) {
        narabi.add(
          _IchiDaigaku(
            '学連選抜',
            0,
            -1,
            false,
            true,
            tsugiGSenshu: g,
            mokuhyou: gakurenMokuhyouGenzai(),
          ),
        );
      }
    }
    if (narabi.length < 2) return null;
    return _IchiKukan(-1, 0, narabi);
  }

  /// 学連選抜が走っている区間があるか
  bool get opAri => kukan.any((r) => r.narabi.any((x) => x.op));
}

/// 位置関係の画面を開く
void _ichiGamenHiraku(BuildContext context, int race, int? made) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
    barrierDismissible: true, // 背景タップで閉じられるようにする
    barrierLabel: '情報集約パネル', // アクセシビリティ用ラベル
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ModalIchiKankeiView(race: race, made: made),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}


/// 区間ごとのタイム分布と、情報集約パネルを1枚にまとめたカード(2.0.6)
/// ・上が「情報集約パネル」、下が「タイム分布」(Modal_kukanTimeBunpu.dart)の2つのボタンで、それぞれ別に押せる。
///   どちらも横いっぱい(2.0.6は、左にタイム分布、右に位置関係を並べていた。2.0.7で上下2段にした)。
///   中身はアイコンと見出しだけ(区間の帯のグラフなどは、開いた画面で見る)。
///   ほかのカードより目立つよう、それぞれの色(水色・青緑)の線で角を丸めて囲み、同じ色でうっすら塗る。
/// ・片方が作れないときは、作れたほうの1段だけ。両方とも作れなければ出さない
///   (1区の指示の画面では、タイム分布はまだ作れないので、情報集約パネルの1段だけ。2.0.7)
/// ・区間が終わるたびの画面(mode 350。[made] に終わった区間の数)の実況のカードのすぐ下と、
///   結果画面([made] はnull)のニュース記事のカードのすぐ下に置く
/// ・結果は画面を出したあとで1回だけ作る。区間や大会が変わったら作り直すよう、置く側で key を付ける
class KukanBunsekiCard extends StatefulWidget {
  /// 大会番号(0: 10月駅伝、1: 11月駅伝、2: 正月駅伝、5: カスタム駅伝)
  final int race;

  /// レースの途中のとき、終わった区間の数(結果画面ではnull)
  final int? made;
  const KukanBunsekiCard({super.key, required this.race, this.made});

  @override
  State<KukanBunsekiCard> createState() => _KukanBunsekiCardState();
}

class _KukanBunsekiCardState extends State<KukanBunsekiCard> {
  /// タイム分布が作れたか
  bool _bunpuAri = false;

  /// 位置関係が作れたか
  bool _ichiAri = false;

  /// 結果を作ったか
  bool _tsukutta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final KukanBunpuYomikomi? bunpu = kukanBunpuYomu(widget.race, made: widget.made);
      final _IchiKankei? ichi = _IchiKankei.yomu(widget.race, made: widget.made);
      if (!mounted) return;
      setState(() {
        _bunpuAri = bunpu != null;
        _ichiAri = ichi != null;
        _tsukutta = true;
      });
    });
  }

  /// ボタン1つ(アイコンと見出し。その色の線で囲み、同じ色でうっすら塗る)
  Widget _botan(IconData icon, Color iro, String moji, VoidCallback onTap) {
    return Material(
      color: iro.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: iro, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: iro, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$moji ›',
                  style: TextStyle(color: iro, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_tsukutta || (!_bunpuAri && !_ichiAri)) return const SizedBox.shrink();
    // 上に情報集約パネル、下にタイム分布(どちらも横いっぱい。2.0.7)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_ichiAri)
            _botan(
              Icons.directions_run,
              _iro,
              '情報集約パネル',
              () => _ichiGamenHiraku(context, widget.race, widget.made),
            ),
          if (_bunpuAri && _ichiAri) const SizedBox(height: 8),
          if (_bunpuAri)
            _botan(
              Icons.candlestick_chart,
              Colors.tealAccent,
              'タイム分布',
              () => kukanBunpuGamenHiraku(context, widget.race, widget.made),
            ),
        ],
      ),
    );
  }
}

class ModalIchiKankeiView extends StatefulWidget {
  /// 大会番号(0: 10月駅伝、1: 11月駅伝、2: 正月駅伝、5: カスタム駅伝)
  final int race;

  /// レースの途中のとき、終わった区間の数(結果画面からはnull)
  final int? made;
  const ModalIchiKankeiView({super.key, required this.race, this.made});

  @override
  State<ModalIchiKankeiView> createState() => _ModalIchiKankeiViewState();
}

/// 大学の四角1つ分の置き場所
class _Hako {
  /// narabi の番号
  final int i;
  final double x;
  final double w;
  final double h;
  const _Hako(this.i, this.x, this.w, this.h);
}

/// 四角を並べた行(集団は、1行3校までで折り返して何行かになる)
class _Gyou {
  /// 上端
  final double y;

  /// 高さ
  final double h;

  final List<_Hako> hako;

  /// 行の右端(いちばん右の四角(か「+1秒」)の右のすきままで)
  final double hashi;

  /// 集団の中で、先頭から遅れた秒の行の右に出す文(「+1秒」)と、その左端
  /// (先頭と同じ秒の行と、折り返しの行はnull。2.1.0)
  final String? byou;
  final double byouX;

  const _Gyou(this.y, this.h, this.hako, this.hashi, {this.byou, this.byouX = 0});
}

/// 前の大学(集団)との間の括弧1つ分
class _Aida {
  /// 括弧の上端(前の集団の一番下の行の真ん中)と下端(次の集団の一番上の行の真ん中)
  final double y0;
  final double y1;

  /// 文(「90m」の下に「16秒」の2行。2.1.0)
  final String moji;

  /// 詰めた間か(括弧を点線にする。2.1.0から添え書きはなし)
  final bool tsume;

  /// 文の上端と高さ(ほかの文やシード権ラインと重ならないように決める)
  double top = 0;
  double h = 0;

  _Aida(this.y0, this.y1, this.moji, this.tsume);
}

/// 道の上の並べ方
class _Haichi {
  final List<_Gyou> gyou;

  /// 前の大学(集団)との間の括弧
  final List<_Aida> aida;

  /// 道の切れ目(詰めた間の、前の行の下端と次の行の上端)
  final List<({double y0, double y1})> kireme;

  /// 2校以上の集団を囲む枠
  final List<Rect> waku;

  /// シード権ラインの行の上端(引かないときはnull)
  final double? seedTop;

  /// 1位(いちばん前)の位置
  final double sentouY;

  /// 道の帯の上端
  final double michiUe;

  /// 道の帯の幅
  final double michiHaba;

  /// 括弧の左端と、間の文の左端
  final double kakkoX;
  final double mojiX;

  /// 全体の幅(画面より広いときは、横にスクロールする)
  final double haba;

  /// 全体の高さ
  final double takasa;

  _Haichi(
    this.gyou,
    this.aida,
    this.kireme,
    this.waku,
    this.seedTop,
    this.sentouY,
    this.michiUe,
    this.michiHaba,
    this.kakkoX,
    this.mojiX,
    this.haba,
    this.takasa,
  );
}

class _ModalIchiKankeiViewState extends State<ModalIchiKankeiView> {
  _IchiKankei? _b;

  /// 見ている区間(並びの番号)
  int _erabu = 0;

  /// 押した大学(narabi の番号。-1はなし)
  int _oshita = -1;

  /// 差の基準を目標順位にしているか(false: 1位との差、true: 目標順位との差。覚えない。2.0.7)
  bool _mokuhyouKijun = false;

  /// 押した大学の帯をどこまで開いているか(0: 差だけ、1: 走った選手の説明文、2: 次の区間を走る選手。
  /// 四角を押すたびに進む。2.0.7)
  int _hiraki = 0;

  /// 説明文と次の区間の選手の部分のスクロール(どちらか一方しか出さないので、1つを使い回す)
  final ScrollController _setsumeiScroll = ScrollController();

  /// 帯の中のスクロールする部分の中身と、その中の目印(次の区間の選手は持ちタイムの表、説明文は本文)。
  /// 同じ段のまま、ほかの大学に切り替えたときに、目印が同じ高さに来るようにするため(2.0.7)
  final GlobalKey _obiNakaKey = GlobalKey();
  final GlobalKey _ankaKey = GlobalKey();

  /// 今のゲームの変数(次の区間の選手のパネルで使う)
  Ghensuu? _gh;

  /// 持ちタイムを今季ベストで表示しているときの順位表(区間配置確認と同じ設定。初めて使うときに一度だけ作る)
  KonkiBestJuni? _konki;
  bool _konkiYonda = false;

  /// 押した大学の四角(下の帯が伸びて隠れるときに、道を動かして見えるようにする)
  final GlobalKey _oshitaKey = GlobalKey();

  /// 自分の大学(学連選抜の監督の年は学連選抜)の四角。説明の「オレンジの枠」の行を押したときに動かす先(2.1.0)
  final GlobalKey _jibunKey = GlobalKey();

  /// 道の縦のスクロール(右端につまんで動かせるスクロールバーを出すため。2.1.0)
  final ScrollController _michiScroll = ScrollController();

  /// 表示の倍率の段階(_bairitsu の番号。おまかせのときは使わない)
  int _dan = 2;

  /// 倍率がおまかせか(「−」「＋」を押すと外れる。覚えない)
  bool _omakase = true;

  /// おまかせのときに、道が横幅に収まるように文字を小さくするか(おまかせ ↔。覚えない。2.0.8)
  bool _habaAwase = false;

  /// 表示(0: 位置、1: 通過順位速報、2: 個人順位速報、3: 配置(区間配置確認。2.0.9)。覚えない。2.0.8)
  int _hyouji = 0;

  /// 配置で選んだ大学(学連選抜は kukanHaitiGakurenId。nullなら最初の大学。画面を閉じるまで覚える。2.0.9)
  int? _haichiUniv;

  static const TextStyle _chiisai = TextStyle(color: Colors.white54, fontSize: 11);
  static const TextStyle _seedMojiStyle = TextStyle(color: Colors.amberAccent, fontSize: 11);
  // 道の右の差の文(2.1.0から2行にし、12から11に少し小さくした)
  static const TextStyle _migiStyle = TextStyle(color: Colors.white70, fontSize: 11);

  @override
  void initState() {
    super.initState();
    final _IchiKankei? b = _IchiKankei.yomu(widget.race, made: widget.made);
    _b = b;
    // 一番あとの区間(レースの途中は終わったばかりの区間、結果画面では最終区)を開いておく
    if (b != null) _erabu = b.kukan.length - 1;
    final Box<Ghensuu> gBox = Hive.box<Ghensuu>('ghensuuBox');
    _gh = gBox.isEmpty ? null : gBox.getAt(0);
  }

  /// 今季ベストの順位表(自己ベストで表示しているときはnull)
  KonkiBestJuni? _konkiYomu() {
    if (!_konkiYonda) {
      _konkiYonda = true;
      _konki = konkiBestHyoujiChuu() ? KonkiBestJuni() : null;
    }
    return _konki;
  }

  /// [x]の次の区間を走る選手のパネルを出せるか
  /// (区間配置確認の部品は表示中の大会を見るので、表示中の大会がこの大会のときだけ)
  bool _tsugiDaseru(_IchiDaigaku x) {
    final Ghensuu? gh = _gh;
    return x.tsugiAri && gh != null && gh.hyojiracebangou == widget.race;
  }

  @override
  void dispose() {
    _setsumeiScroll.dispose();
    _michiScroll.dispose();
    super.dispose();
  }

  /// いつも出していて、つまんで動かせるスクロールバー(つまみは白っぽい色。2.1.0)
  /// (アプリの共通の見た目は明るい画面用のままなので、ふつうの Scrollbar ではつまみが黒っぽくなり、
  /// 黒い背景でほとんど見えなかった。色を決められる RawScrollbar にする)
  Widget _shiroScrollbar({
    required ScrollController controller,
    required double thickness,
    required Widget child,
  }) {
    return RawScrollbar(
      controller: controller,
      thumbVisibility: true,
      interactive: true,
      thickness: thickness,
      radius: Radius.circular(thickness / 2),
      thumbColor: Colors.white54,
      minThumbLength: 40,
      child: child,
    );
  }

  /// 自分の大学(学連選抜の監督の年は学連選抜)の四角が見える所まで、道を動かす(2.1.0)
  void _jibunHeIdou() {
    final BuildContext? c = _jibunKey.currentContext;
    if (c == null) return;
    Scrollable.ensureVisible(
      c,
      duration: const Duration(milliseconds: 300),
      alignment: 0.3,
    );
  }

  /// 大学の四角を押したとき(1回目で差の帯、2回目で走った選手の説明文、3回目で次の区間を走る選手を出し、
  /// 4回目で閉じる。次の区間の選手がいなければ3回目で閉じる。
  /// 開いたまま、ほかの四角を押すと、同じ段のままその大学に切り替える。2.0.7)
  void _hakoOsu(_IchiKukan r, int i) {
    final bool tsugi = _tsugiDaseru(r.narabi[i]);
    // 切り替える前の、押していた大学・段・帯のスクロールの量・目印の高さ
    final int maeOshita = _oshita;
    final int maeHiraki = _hiraki;
    final double? maeOffset = _setsumeiScroll.hasClients ? _setsumeiScroll.offset : null;
    final double? maeAnka = _ankaIchi();
    setState(() {
      if (r.kk < 0) {
        // スタートは、1回目で1区を走る選手を出し、2回目で閉じる(2.0.7)
        if (_oshita == i) {
          _oshita = -1;
          _hiraki = 0;
        } else {
          _oshita = i;
          _hiraki = 2;
        }
      } else if (_oshita == i) {
        if (_hiraki < (tsugi ? 2 : 1)) {
          _hiraki++;
        } else {
          _oshita = -1;
          _hiraki = 0;
        }
      } else {
        _oshita = i;
        // 次の区間の選手を出していて、切り替えた大学にいなければ、説明文まで
        if (_hiraki == 2 && !tsugi) _hiraki = 1;
      }
    });
    // 同じ段のまま、ほかの大学に切り替えたか(帯のスクロールの位置を保つ。2.0.7)
    final bool tamotsu =
        maeOshita >= 0 && maeOshita != i && _oshita == i && _hiraki == maeHiraki && _hiraki > 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 帯のスクロール: 同じ段のまま切り替えたときは、目印が切り替える前と同じ高さに来るようにする
      // (測れなければスクロールの量をそのまま保つ)。段が進んだときなどは先頭に戻す
      if (_setsumeiScroll.hasClients) {
        final ScrollPosition pos = _setsumeiScroll.position;
        double ato = 0;
        if (tamotsu && maeOffset != null) {
          final double? atoAnka = _ankaIchi();
          ato = (maeAnka != null && atoAnka != null) ? maeOffset + (atoAnka - maeAnka) : maeOffset;
        }
        _setsumeiScroll.jumpTo(ato.clamp(pos.minScrollExtent, pos.maxScrollExtent).toDouble());
      }
      // 下の帯が伸びて、押した四角が隠れるときは、道を動かして見えるようにする
      final BuildContext? c = _oshitaKey.currentContext;
      if (c != null) {
        Scrollable.ensureVisible(
          c,
          duration: const Duration(milliseconds: 200),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  /// 帯の中の目印(持ちタイムの表か、説明文の本文)の、スクロールする部分の中身の上からの高さ
  /// (測れなければnull。2.0.7)
  double? _ankaIchi() {
    final RenderObject? naka = _obiNakaKey.currentContext?.findRenderObject();
    final RenderObject? anka = _ankaKey.currentContext?.findRenderObject();
    if (naka is! RenderBox || anka is! RenderBox) return null;
    if (!naka.hasSize || !anka.hasSize || !anka.attached) return null;
    try {
      return anka.localToGlobal(Offset.zero, ancestor: naka).dy;
    } catch (_) {
      return null;
    }
  }

  /// 次の区間を走る選手のパネル(区間配置確認のカードを開いたときと同じ。上の行・距離と主将・中身。
  /// 主将はカードと同じく薄い緑にして緑の枠を付ける。学連選抜は所属大学を出す。2.0.7。
  /// 2.1.0から、中身は持ちタイムの表と能力(1行に1つ。_kirokuToNouryoku))
  Widget _tsugiPanel(BuildContext context, _IchiKukan r, _IchiDaigaku x) {
    final Ghensuu? gh = _gh;
    if (gh == null) return const SizedBox.shrink();
    final int tk = r.kk + 1;
    final String fuda = '${tk + 1}区';
    final List<double> kyoriIchiran = gh.kyori_taikai_kukangoto.length > widget.race
        ? gh.kyori_taikai_kukangoto[widget.race]
        : const <double>[];
    final String kyori = kyoriIchiran.length > tk ? '${kyoriIchiran[tk].toStringAsFixed(0)}m' : '';
    const TextStyle shita = TextStyle(color: Colors.white70, fontSize: 13);
    final SenshuData? s = x.tsugiSenshu;
    final Senshu_Gakuren_Data? g = x.tsugiGSenshu;
    if (s != null) {
      final bool shushou = shushouKaIma(s);
      final Widget panel = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          senshuHaichiTitle(
            context,
            fuda: fuda,
            fudaIro: Colors.cyanAccent,
            mei: s.name,
            gakunen: s.gakunen,
            shousaiId: s.id,
          ),
          Text([if (kyori.isNotEmpty) kyori, if (shushou) '主将'].join('　'), style: shita),
          const Divider(color: Colors.white24),
          // 中身(2.1.0から、持ちタイムの表と能力(1行に1つ)。2回目の走った選手と同じ並び。
          // 持ちタイムの表に、ほかの大学に切り替えたときに同じ高さに来るようにする目印を付ける)
          _kirokuToNouryoku(s: s, kukanIdx: tk, kirokuAnka: true) ?? const SizedBox.shrink(),
        ],
      );
      if (!shushou) return panel;
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
        decoration: BoxDecoration(
          color: shushouIroHaikei,
          border: Border.all(color: shushouIroSen, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: panel,
      );
    }
    if (g != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          senshuHaichiTitle(
            context,
            fuda: fuda,
            fudaIro: Colors.cyanAccent,
            mei: g.name,
            gakunen: g.gakunen,
            shousaiId: g.id,
          ),
          Text('$kyori 所属:${gakurenShozoku(g)}', style: shita),
          const Divider(color: Colors.white24),
          _kirokuToNouryoku(g: g, kukanIdx: tk, kirokuAnka: true) ?? const SizedBox.shrink(),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// 持ちタイムの表と能力(1行に1つ)。2回目に押したときは走った選手、3回目は次の区間を走る選手(2.1.0。
  /// 答え合わせと次の予想を同じ並びで見られるように)。[kukanIdx] はその選手の区間(この区間の経験回数に使う)。
  /// 区間配置確認のカードを開いた中身のうち、能力の行(駅伝男・平常心・調子・この区間の経験回数)は、
  /// 下の能力に全部入るので出さない。まだ見抜いていない能力は「??」。学連選抜の選手の調子は学連選抜で走ったときの調子。
  /// [kirokuAnka] がtrueなら、持ちタイムの表に、同じ段のままほかの大学に切り替えたときにそろえる目印を付ける(3回目)。
  /// 選手が分からなければnull
  Widget? _kirokuToNouryoku({
    SenshuData? s,
    Senshu_Gakuren_Data? g,
    required int kukanIdx,
    required bool kirokuAnka,
  }) {
    final Ghensuu? gh = _gh;
    if (gh == null || kukanIdx < 0) return null;
    final KonkiBestJuni? konki = _konkiYomu();
    final Widget kiroku;
    final Widget nouryoku;
    if (s != null) {
      kiroku = senshuKirokuRan(gh, s, konki);
      nouryoku = senshuNouryokuZenbu(gh, s, race: widget.race, kukanIdx: kukanIdx);
    } else if (g != null) {
      kiroku = gakurenKirokuRan(gh, g, konki);
      nouryoku = gakurenNouryokuZenbu(gh, g, race: widget.race, kukanIdx: kukanIdx);
    } else {
      return null;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('持ちタイム', style: _chiisai),
        const SizedBox(height: 2),
        // 持ちタイムの表は、区間配置確認のカードと同じく真ん中に寄せる
        Center(child: kirokuAnka ? KeyedSubtree(key: _ankaKey, child: kiroku) : kiroku),
        const Divider(height: 12, color: Colors.white24),
        const Text('能力', style: _chiisai),
        const SizedBox(height: 2),
        nouryoku,
      ],
    );
  }

  /// 説明文の上の行(「3区 佐藤 健太(2年)　区間1位 1:02:41」。
  /// 学連選抜は「3区 OP 田中 翔(3年 所属:西峰大)　区間4位相当 1:03:05」。2.0.7)
  String _senshuGyou(_IchiKukan r, _IchiDaigaku x) {
    final String ku = '${r.kk + 1}区';
    String mei = '';
    final SenshuData? s = x.senshu;
    final Senshu_Gakuren_Data? g = x.gSenshu;
    if (s != null) {
      mei = ' ${s.name}(${s.gakunen}年${shushouShirushi(s)})';
    } else if (g != null) {
      mei = ' OP ${g.name}(${g.gakunen}年 所属:${x.shozoku ?? ''})';
    }
    final int? kj = x.kukanJuni;
    final double? kt = x.kukanTime;
    final String juni = kj == null ? '' : (x.op ? '区間${kj + 1}位相当' : '区間${kj + 1}位');
    final String time = (kt != null && kt > 0 && kt < TEISUU.DEFAULTTIME)
        ? TimeDate.timeToFunByouString(kt)
        : '';
    final String ato = [juni, time].where((e) => e.isNotEmpty).join(' ');
    return ato.isEmpty ? '$ku$mei' : '$ku$mei　$ato';
  }

  /// 区間の名前(「スタート」「3区」。2.0.7)
  String _kukanMei(_IchiKukan r) => r.kk < 0 ? 'スタート' : '${r.kk + 1}区';

  /// 四角の中の順位の欄の文(学連選抜は「OP」。スタートは大学は空。2.1.0)
  String _juniMoji(_IchiKukan r, int i) {
    final _IchiDaigaku x = r.narabi[i];
    if (x.op) return 'OP';
    return r.kk < 0 ? '' : '${x.juni + 1}';
  }

  /// 四角の中の大学名(最後の「大」を省く。学連選抜は「学連」。下の帯は省かない)
  String _hakoMei(_IchiDaigaku x) => x.op ? '学連' : _michiMei(x.mei);

  /// 四角の中の欄の幅を、区間と文字の大きさごとに覚えておく(画面を開いているあいだだけ。2.1.0)
  final Map<String, _HakoHaba> _hakoHabaKioku = {};

  /// 区間[r]の四角の中の欄の幅(2.1.0。どの四角も同じ幅にそろえる)
  /// 順位の欄はその区間の一番広い順位(学連選抜の「OP」も)、大学名の欄は2文字分(_meiMojisuu)、
  /// 順位の変化の欄はその区間の一番広い変化(1区とスタートは変化がないので0)
  _HakoHaba _hakoHaba(_IchiKukan r, TextScaler scaler) {
    final String kagi = '${r.kk}:${scaler.scale(100).toStringAsFixed(2)}';
    final _HakoHaba? kioku = _hakoHabaKioku[kagi];
    if (kioku != null) return kioku;
    double juni = 0;
    double hendou = 0;
    double takasa = 0;
    for (int i = 0; i < r.narabi.length; i++) {
      final String jm = _juniMoji(r, i);
      if (jm.isNotEmpty) {
        final Size z = _ookisa(TextSpan(text: jm, style: _juniStyle), scaler);
        juni = math.max(juni, z.width);
        takasa = math.max(takasa, z.height);
      }
      final String? hm = r.narabi[i].hendouMoji;
      if (hm != null) {
        final Size z = _ookisa(TextSpan(text: hm, style: _hendouStyle), scaler);
        hendou = math.max(hendou, z.width);
        takasa = math.max(takasa, z.height);
      }
    }
    final Size mei = _ookisa(
      TextSpan(text: '国' * _meiMojisuu, style: _meiStyle),
      scaler,
    );
    takasa = math.max(takasa, mei.height);
    final _HakoHaba h = _HakoHaba(juni, mei.width, hendou, takasa);
    _hakoHabaKioku[kagi] = h;
    return h;
  }

  /// 四角の中(順位・大学名・順位の変化の欄を、決まった幅で並べる。2.1.0)
  Widget _hakoNaka(_IchiKukan r, int i, TextScaler scaler) {
    final _HakoHaba h = _hakoHaba(r, scaler);
    final _IchiDaigaku x = r.narabi[i];
    final String? hm = x.hendouMoji;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 順位(学連選抜は「OP」。順位と同じ薄い色。右寄せ)
        if (h.juni > 0) ...[
          SizedBox(
            width: h.juni,
            child: Text(
              _juniMoji(r, i),
              style: _juniStyle,
              textAlign: TextAlign.right,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          const SizedBox(width: _juniSukima),
        ],
        // 大学名(自分の大学も、文字はほかの大学と同じ。オレンジは枠だけ)
        _hakoMeiWidget(_hakoMei(x), h, scaler),
        // 前の区間からの順位の変化(↑は緑、↓は赤、→は灰色。1区とスタートは欄を作らない)
        if (h.hendou > 0) ...[
          const SizedBox(width: _hendouSukima),
          SizedBox(
            width: h.hendou,
            child: hm == null
                ? null
                : Text(
                    hm,
                    style: _hendouStyle.copyWith(color: _hendouIro(x.hendou!)),
                    maxLines: 1,
                    softWrap: false,
                  ),
          ),
        ],
      ],
    );
  }

  /// 四角の中の大学名(2文字分(_meiMojisuu)の欄に左寄せで入れる。長い名前は横だけ縮め、5割まで縮めても入らなければ
  /// 最後を「…」で省く。2.1.0)
  Widget _hakoMeiWidget(String mei, _HakoHaba h, TextScaler scaler) {
    final Size shizen = _ookisa(TextSpan(text: mei, style: _meiStyle), scaler);
    if (shizen.width <= h.mei) {
      return SizedBox(
        width: h.mei,
        child: Text(mei, style: _meiStyle, maxLines: 1, softWrap: false),
      );
    }
    String moji = mei;
    Size z = shizen;
    while (moji.length > 1 && z.width * _meiChijimiSaishou > h.mei) {
      moji = moji.substring(0, moji.length - 1);
      z = _ookisa(TextSpan(text: '$moji…', style: _meiStyle), scaler);
    }
    final String hyouji = moji == mei ? mei : '$moji…';
    // 高さは文の高さのまま、横だけを欄の幅に合わせて縮める
    return SizedBox(
      width: h.mei,
      height: z.height,
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.centerLeft,
        child: Text(hyouji, style: _meiStyle, maxLines: 1, softWrap: false),
      ),
    );
  }

  /// 順位の変化の色
  Color _hendouIro(int h) =>
      h > 0 ? Colors.lightGreenAccent : (h < 0 ? Colors.redAccent.shade100 : Colors.white54);

  /// 四角の大きさ(枠の太さの最大と余白を見込む。2.1.0から、区間の中ではどの四角も同じ大きさ)
  Size _hakoOokisa(_IchiKankei b, _IchiKukan r, int i, TextScaler scaler) {
    final _HakoHaba h = _hakoHaba(r, scaler);
    return Size(
      h.naka + _hakoYoko * 2 + _wakuSaidai * 2 + 2,
      h.takasa + _hakoTate * 2 + _wakuSaidai * 2,
    );
  }

  /// 集団の1行に並べる大学の数を、画面の幅と文字の大きさごとに覚えておく(画面を開いているあいだだけ。2.1.0)
  final Map<String, int> _gyouSuuKioku = {};

  /// 一番長い差の文の幅を、文字の大きさごとに覚えておく(画面を開いているあいだだけ。2.1.0)
  final Map<String, double> _aidaMojiHabaKioku = {};

  /// パネルで見られる全部の区間(スタートと終わった区間)の、一番長い差の文の幅(2.1.0)
  /// 道の帯の幅と1行に並べる数をこれで決める(区間を切り替えるたびに道の幅が変わらないように)
  double _aidaMojiHabaSaidai(_IchiKankei b, TextScaler scaler) {
    final String kagi = scaler.scale(100).toStringAsFixed(2);
    final double? kioku = _aidaMojiHabaKioku[kagi];
    if (kioku != null) return kioku;
    double moji = 0;
    for (final _IchiKukan r in b.kukan) {
      for (int i = 1; i < r.narabi.length; i++) {
        moji = math.max(
          moji,
          _ookisa(TextSpan(text: r.aidaBun(r.narabi[i], r.narabi[i - 1]), style: _migiStyle), scaler).width,
        );
      }
    }
    _aidaMojiHabaKioku[kagi] = moji;
    return moji;
  }

  /// 集団の1行に並べる大学の数(2.1.0)
  /// 「四角の行 + 右の括弧と差の文」が画面の幅[w]に入る一番大きい数を、3校 → 2校 → 1校の順に試して決める
  /// (1校でも入らなければ1校にして、横にスクロールする)。区間を切り替えるたびに数が変わらないように、
  /// パネルで見られる全部の区間(スタートと終わった区間)の、一番広い四角・一番長い差の文・一番長い「+○秒」で決める
  int _gyouSuuKimeru(_IchiKankei b, double w, TextScaler scaler) {
    final String kagi = '${w.toStringAsFixed(1)}:${scaler.scale(100).toStringAsFixed(2)}';
    final int? kioku = _gyouSuuKioku[kagi];
    if (kioku != null) return kioku;
    double hako = 0;
    final double moji = _aidaMojiHabaSaidai(b, scaler);
    int byouSaidai = 0;
    for (final _IchiKukan r in b.kukan) {
      int sentou = 0; // いまの集団の先頭(シード権ラインなどで分かれるところは見ない。多めに見積もる)
      for (int i = 0; i < r.narabi.length; i++) {
        hako = math.max(hako, _hakoOokisa(b, r, i, scaler).width);
        if (i == 0) continue;
        final _IchiDaigaku x = r.narabi[i];
        if (saByou(x.ruikei, r.narabi[i - 1].ruikei) <= _shuudanByou) {
          byouSaidai = math.max(byouSaidai, saByou(x.ruikei, r.narabi[sentou].ruikei));
        } else {
          sentou = i;
        }
      }
    }
    final double byouHaba = byouSaidai > 0
        ? _ookisa(TextSpan(text: '+$byouSaidai秒', style: _chiisai), scaler).width + _sukima
        : 0;
    int kekka = 1;
    for (int suu = _gyouSaidai; suu >= 1; suu--) {
      // _haichi の幅の決め方と同じ(一番広い行の右に、括弧と差の文が入るか)
      final double gyouHashi = _hakoHidari + suu * (hako + _sukima) + byouHaba;
      if (gyouHashi + _wakuYohaku + _migiYohaku + moji <= w) {
        kekka = suu;
        break;
      }
    }
    _gyouSuuKioku[kagi] = kekka;
    return kekka;
  }

  /// 文の大きさ(折り返さない。改行のある文は、行を重ねた大きさ。2.1.0から道の右の差の文が2行になったため、
  /// 行の数を1つに限らないようにした)
  Size _ookisa(TextSpan span, TextScaler scaler) {
    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final Size s = tp.size;
    tp.dispose();
    return s;
  }

  /// 前の大学との間(m。[i]は narabi[i] と narabi[i+1] の間)
  List<double> _aida(_IchiKukan r) => [
    for (int i = 0; i + 1 < r.narabi.length; i++)
      math.max(0.0, (r.narabi[i + 1].ruikei - r.narabi[i].ruikei) * r.hayasa),
  ];

  /// 飛び抜けて大きい間(_aida の番号。中央値の4倍以上を、大きい順に多くて3か所)
  Set<int> _tobinukeAida(List<double> aida) {
    if (aida.length < 2) return <int>{};
    final List<double> narabe = List<double>.of(aida)..sort();
    final int n = narabe.length;
    final double chuuou = n.isOdd ? narabe[n ~/ 2] : (narabe[n ~/ 2 - 1] + narabe[n ~/ 2]) / 2;
    final double genkai = math.max(chuuou * _tobinukeBai, _tobinukeSaitei);
    final List<int> kouho = [
      for (int i = 0; i < aida.length; i++)
        if (aida[i] >= genkai) i,
    ]..sort((a, b) => aida[b].compareTo(aida[a]));
    return kouho.take(_tobinukeSaidai).toSet();
  }

  /// おまかせの倍率の段階(詰めた間を除いた1位から最後尾までの長さが、
  /// 画面の高さのおよそ2つ分に収まる一番大きい倍率)
  int _omakaseDan(_IchiKukan r, double gamenTakasa) {
    if (r.narabi.length < 2 || r.kk < 0) return 2;
    final List<double> aida = _aida(r);
    final Set<int> tsume = _tobinukeAida(aida);
    double nokori = 0;
    for (int i = 0; i < aida.length; i++) {
      if (!tsume.contains(i)) nokori += aida[i];
    }
    int dan = 0;
    for (int i = 0; i < _bairitsu.length; i++) {
      if (nokori * _bairitsu[i] + tsume.length * _tsumePx <= gamenTakasa * _omakaseGamen) {
        dan = i;
      }
    }
    // ×2より小さくはしない(2.1.0。縦が長くなっても、10mと100mの差が見分けられるように)
    return math.max(dan, _omakaseSaitei);
  }

  /// 大学の四角と行の置き場所を決める([px] は1mあたりの高さ。[gamenTakasa] は画面の高さ。
  /// 1つの間が画面の高さを超えるところも詰める(2.0.9までは手動で倍率を選んでいるときだけ。2.1.0から、
  /// おまかせが×2より小さくならず、1つの間が画面より長くなることがあるので、おまかせでも詰める)。
  /// [gyouSuu] は集団の1行に並べる大学の数(_gyouSuuKimeru。2.1.0))
  _Haichi _haichi(
    _IchiKankei b,
    _IchiKukan r,
    double w,
    TextScaler scaler,
    double px,
    double gamenTakasa,
    int gyouSuu,
  ) {
    final int n = r.narabi.length;
    // 四角の大きさ(折り返さない1行)
    final List<Size> hakoOokisa = [
      for (int i = 0; i < n; i++) _hakoOokisa(b, r, i, scaler),
    ];
    // 行の高さ(四角の高さ。どの行も同じ)
    double gyouTakasa = 0;
    for (final Size s in hakoOokisa) {
      gyouTakasa = math.max(gyouTakasa, s.height);
    }
    // 間の文の高さ(距離と秒差の2行。2.1.0)
    final double aidaMojiTakasa = _ookisa(const TextSpan(text: '0m\n0秒', style: _migiStyle), scaler).height;
    // 詰めた間の、前の行の真ん中から次の行の真ん中までの長さ(2行の文が入るように)
    final double tsumeNagasa = math.max(
      _tsumePx,
      gyouTakasa + aidaMojiTakasa + _sukima * 2,
    );
    final double seedTakasa = _ookisa(
      const TextSpan(text: 'シード権ライン', style: _seedMojiStyle),
      scaler,
    ).height;
    final int opNozoku = r.narabi.where((x) => !x.op).length;
    // シード権ライン(スタートは引かない。2.0.7)
    final int? seed = (r.kk >= 0 && b.seed != null && opNozoku > b.seed!) ? b.seed : null;

    // 詰める間(飛び抜けて大きい間と、画面の高さを超える間。2.1.0から、おまかせでも画面の高さを超える間を詰める)
    final List<double> aida = _aida(r);
    final Set<int> tsume = _tobinukeAida(aida);
    for (int i = 0; i < aida.length; i++) {
      if (aida[i] * px > gamenTakasa) tsume.add(i);
    }

    // 1位(いちばん前)からの距離(m)
    final double base = r.narabi.first.ruikei;
    final List<double> d = [for (final _IchiDaigaku x in r.narabi) (x.ruikei - base) * r.hayasa];

    // 集団に分ける(2.1.0): 前の大学との差が1秒以内(右の括弧と同じ切り捨ての秒。「並走」か「1秒」)なら、
    // 同じ集団としてつなげる(長さの上限はなし。拡大・縮小しても変わらない)。
    // シード権ラインと、詰めた間では必ず分ける。
    // (2.0.9までは、画面の上で四角1つ分より近い大学をつなげ、長い集団は一番大きく空いた間で分けていた。
    // 倍率が小さいと100m以上離れた大学も同じ枠に入り、集団走のように見えていた)
    final List<List<int>> shuudan = [];
    for (int i = 0; i < n; i++) {
      final _IchiDaigaku x = r.narabi[i];
      final bool seedMae = seed != null && !x.op && x.juni == seed;
      final bool kiremeAto = i > 0 && tsume.contains(i - 1);
      final bool chikai =
          i > 0 && saByou(x.ruikei, r.narabi[i - 1].ruikei) <= _shuudanByou;
      if (shuudan.isNotEmpty && chikai && !seedMae && !kiremeAto) {
        shuudan.last.add(i);
      } else {
        shuudan.add([i]);
      }
    }

    // 集団ごとに置く(一番上の行は前の集団の一番下の行から、間の距離ぶん下。1行3校まで)
    final List<_Gyou> gyou = [];
    final List<_Aida> aidaList = [];
    final List<({double y0, double y1})> kireme = [];
    final List<Rect> waku = [];
    // 2校以上の集団の、行の範囲(gyou の番号。kara から made の前まで)と枠の上端・下端
    // (枠の左右は、道の幅が決まって四角を真ん中に寄せたあとで決める。2.1.0)
    final List<({int kara, int made, double ue, double shita})> wakuKumi = [];
    double? seedTop;
    // 道の帯は、いちばん上から始める(2.0.6の開発中まで、上に「○区→○区の中継所」を出していた)
    const double michiUe = 0;
    double shita = michiUe; // いま置いたものの下端
    double sentouY = michiUe + _sukima + gyouTakasa / 2;
    double? maeChuushin; // 前の集団の一番下の行の真ん中
    double maeGyouShita = michiUe; // 前の集団の一番下の行の下端
    int maeSaigo = 0; // 前の集団の最後の大学
    for (int si = 0; si < shuudan.length; si++) {
      final List<int> sh = shuudan[si];
      final int saki = sh.first;
      double top;
      final double? mc = maeChuushin;
      final bool tsumeAto = mc != null && tsume.contains(saki - 1);
      if (mc == null) {
        top = michiUe + _sukima;
      } else if (tsumeAto) {
        // 詰めた間: 決まった長さだけ空ける(道には切れ目の点線、右には点線の括弧)
        top = mc + tsumeNagasa - gyouTakasa / 2;
      } else {
        top = mc + (d[saki] - d[maeSaigo]) * px - gyouTakasa / 2;
      }
      // シード権ライン(シード権の順位の次の大学の前に引く)
      final _IchiDaigaku x0 = r.narabi[saki];
      if (seed != null && !x0.op && x0.juni == seed) {
        final double sTop = shita + _sukima;
        seedTop = sTop;
        shita = sTop + seedTakasa;
      }
      // 2校以上の集団は枠で囲むので、枠の余白のぶんも空ける
      final bool wakuAri = sh.length >= 2;
      top = math.max(
        top,
        si == 0 ? shita + _sukima + (wakuAri ? _wakuYohaku : 0) : shita + _shuudanSukima + (wakuAri ? _wakuYohaku : 0),
      );
      // 前の集団との間は、2行の差の文が括弧の中に収まる高さより狭くしない(2.1.0。文字を大きくしていても、
      // 文が少しずつ下にずれて括弧と合わなくならないように)
      if (mc != null) {
        final double mojiTakasa = _ookisa(
          TextSpan(text: r.aidaBun(r.narabi[saki], r.narabi[maeSaigo]), style: _migiStyle),
          scaler,
        ).height;
        top = math.max(top, mc + mojiTakasa + 2 - gyouTakasa / 2);
      }
      if (si == 0) sentouY = top + gyouTakasa / 2;
      // 前の集団との間の括弧(前の集団の一番下の行の真ん中から、この集団の一番上の行の真ん中まで)
      if (mc != null) {
        aidaList.add(
          _Aida(mc, top + gyouTakasa / 2, r.aidaBun(r.narabi[saki], r.narabi[maeSaigo]), tsumeAto),
        );
        if (tsumeAto) kireme.add((y0: maeGyouShita, y1: top));
      }
      final double shuudanUe = top;
      final int gyouKara = gyou.length;
      // 集団の中は、先頭からの秒差ごとに行を分ける(2.1.0。同じ秒の大学を横に並べ、[gyouSuu]校で折り返す。
      // 秒が変わった行の右に「+1秒」を出し、折り返しの行には出さない)
      final List<({List<int> ichi, int? byou})> kumi = [];
      int j = 0;
      while (j < sh.length) {
        final int byou0 = saByou(r.narabi[sh[j]].ruikei, r.narabi[saki].ruikei);
        final List<int> onaji = [];
        while (j < sh.length &&
            saByou(r.narabi[sh[j]].ruikei, r.narabi[saki].ruikei) == byou0) {
          onaji.add(sh[j]);
          j++;
        }
        for (int k = 0; k < onaji.length; k += gyouSuu) {
          kumi.add((
            ichi: onaji.sublist(k, math.min(k + gyouSuu, onaji.length)),
            byou: (k == 0 && byou0 > 0) ? byou0 : null,
          ));
        }
      }
      for (final ({List<int> ichi, int? byou}) g in kumi) {
        final List<_Hako> hako = [];
        double x = _hakoHidari;
        for (final int idx in g.ichi) {
          final Size z = hakoOokisa[idx];
          hako.add(_Hako(idx, x, z.width, z.height));
          x += z.width + _sukima;
        }
        String? byouMoji;
        double byouX = 0;
        if (g.byou != null) {
          byouMoji = '+${g.byou}秒';
          byouX = x;
          x += _ookisa(TextSpan(text: byouMoji, style: _chiisai), scaler).width + _sukima;
        }
        gyou.add(_Gyou(top, gyouTakasa, hako, x, byou: byouMoji, byouX: byouX));
        shita = top + gyouTakasa;
        top = shita + _sukima;
      }
      maeChuushin = shita - gyouTakasa / 2;
      maeGyouShita = shita;
      maeSaigo = sh.last;
      // 2校以上の集団を囲む枠(上下はここで決め、左右は四角を真ん中に寄せたあとで決める)
      if (wakuAri) {
        wakuKumi.add((
          kara: gyouKara,
          made: gyou.length,
          ue: shuudanUe - _wakuYohaku,
          shita: shita + _wakuYohaku,
        ));
        shita += _wakuYohaku;
      }
    }

    // 間の文の置き場所(括弧の真ん中。前の文と重なるときは、下にずらす)
    // (2.0.9まではシード権ラインが画面の幅いっぱいだったので、ラインと重なる文もその下にずらしていた。
    // 2.1.0からラインは道の帯の上だけに引くので、右の文はずらさない)
    double maeMojiShita = -1;
    for (final _Aida a in aidaList) {
      a.h = _ookisa(TextSpan(text: a.moji, style: _migiStyle), scaler).height;
      final double t = math.max((a.y0 + a.y1) / 2 - a.h / 2, maeMojiShita + 2);
      a.top = t;
      maeMojiShita = t + a.h;
    }

    // 幅(道の帯は、画面の幅から括弧と差の文の幅を引いた残り全部か、一番広い行の広いほう。2.1.0。
    // 差の文の幅は、区間を切り替えても道の幅が変わらないように、パネルの全部の区間で一番長い文で決める。
    // 四角の行が広くて入りきらなければ横にスクロール)
    double gyouHaba = 0;
    for (final _Gyou g in gyou) {
      gyouHaba = math.max(gyouHaba, g.hashi);
    }
    double mojiHaba = 0;
    for (final _Aida a in aidaList) {
      mojiHaba = math.max(mojiHaba, _ookisa(TextSpan(text: a.moji, style: _migiStyle), scaler).width);
    }
    final double zentaiMoji = math.max(mojiHaba, _aidaMojiHabaSaidai(b, scaler));
    final double michiHaba = math.max(w - _migiYohaku - zentaiMoji, gyouHaba + _wakuYohaku);
    final double kakkoX = michiHaba + 6;
    final double mojiX = kakkoX + 14;
    final double haba = math.max(w, mojiX + mojiHaba + 8);

    // 四角を行ごとに道の左右の真ん中に置く(2.1.0。集団が隊列のような形に見えるように)。
    // 真ん中にそろえるのは四角だけで、「+1秒」はその右に出す。「+1秒」が道からはみ出すときと、
    // 行が道より広いときは、入るところまで左に寄せる(左端は今までの並べ始めの位置まで)
    final double naka = michiHaba / 2;
    for (int gi = 0; gi < gyou.length; gi++) {
      final _Gyou g = gyou[gi];
      if (g.hako.isEmpty) continue;
      final double hakoHidari = g.hako.first.x;
      final double hakoMigi = g.hako.last.x + g.hako.last.w;
      final double hakoHaba = hakoMigi - hakoHidari;
      // 「+1秒」の分(四角の右のすきまと文の幅。なければ0)
      final double byouHaba = g.byou != null ? (g.hashi - _sukima) - hakoMigi : 0;
      double hidari = naka - hakoHaba / 2;
      hidari = math.min(hidari, michiHaba - _wakuYohaku - hakoHaba - byouHaba);
      hidari = math.max(hidari, _hakoHidari);
      final double dx = hidari - hakoHidari;
      if (dx == 0) continue;
      gyou[gi] = _Gyou(
        g.y,
        g.h,
        [for (final _Hako hk in g.hako) _Hako(hk.i, hk.x + dx, hk.w, hk.h)],
        g.hashi + dx,
        byou: g.byou,
        byouX: g.byouX + dx,
      );
    }
    // 2校以上の集団を囲む枠(道の真ん中を軸に左右同じ幅で、四角と「+1秒」を囲む。道からははみ出さない)
    for (final ({int kara, int made, double ue, double shita}) k in wakuKumi) {
      double hidari = double.infinity;
      double migi = 0;
      for (int gi = k.kara; gi < k.made; gi++) {
        final _Gyou g = gyou[gi];
        if (g.hako.isEmpty) continue;
        hidari = math.min(hidari, g.hako.first.x);
        migi = math.max(migi, g.hashi - _sukima);
      }
      if (hidari == double.infinity) continue;
      final double han = math.max(naka - hidari, migi - naka);
      waku.add(
        Rect.fromLTRB(
          math.max(0.0, naka - han - _wakuYohaku),
          k.ue,
          math.min(michiHaba, naka + han + _wakuYohaku),
          k.shita,
        ),
      );
    }

    double takasa = shita;
    for (final _Aida a in aidaList) {
      takasa = math.max(takasa, a.top + a.h);
    }
    takasa += 16;
    return _Haichi(
      gyou,
      aidaList,
      kireme,
      waku,
      seedTop,
      sentouY,
      michiUe,
      michiHaba,
      kakkoX,
      mojiX,
      haba,
      takasa,
    );
  }

  /// 押した大学の帯の文(順位・1位との差・前の大学との差)
  String? _oshitaBun(_IchiKukan r) {
    if (_oshita < 0 || _oshita >= r.narabi.length) return null;
    final _IchiDaigaku x = r.narabi[_oshita];
    // スタートは、大学名と目標順位(「青嵐大　目標3位」。2.0.7)
    if (r.kk < 0) {
      final int? t = x.mokuhyou;
      final String mokuhyou = (t == null || t < 0) ? '' : '　目標${t + 1}位${x.op ? '相当' : ''}';
      return '${x.op ? '学連選抜' : x.mei}$mokuhyou';
    }
    final String mae = r.maeBun(_oshita);
    // 順位の後ろに、前の区間からの変化を付ける(「5位(↑3) 青嵐大」「3位相当(↑2) 学連選抜」)
    final String? hm = x.hendouMoji;
    final String henka = hm == null ? '' : '($hm)';
    final int? soutou = x.soutouJuni;
    final String mei = x.op
        ? (soutou == null ? '学連選抜(OP)' : '${soutou + 1}位相当$henka 学連選抜')
        : '${x.juni + 1}位$henka ${x.mei}';
    // 1位との差か、目標順位との差(差の基準。2.0.7)
    final String sa = _mokuhyouKijun ? r.mokuhyouBun(x) : r.saBun(x);
    return mae.isEmpty ? '$mei　$sa' : '$mei　$sa　$mae';
  }

  @override
  Widget build(BuildContext context) {
    final _IchiKankei? b = _b;
    final double gamenTakasa = MediaQuery.sizeOf(context).height;
    _IchiKukan? r;
    int dan = 2;
    if (b != null) {
      r = b.kukan[_erabu.clamp(0, b.kukan.length - 1)];
      dan = _omakase ? _omakaseDan(r, gamenTakasa) : _dan.clamp(0, _bairitsu.length - 1);
    }
    final _IchiKukan? r0 = r;
    final String? oshitaBun = r0 == null ? null : _oshitaBun(r0);
    final _IchiDaigaku? x0 = (r0 != null && _oshita >= 0 && _oshita < r0.narabi.length)
        ? r0.narabi[_oshita]
        : null;
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '情報集約パネル',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: (b == null || r0 == null)
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '駅伝の結果がありません。',
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
                ),
              )
            // 上のバーを除いた高さを、上の固定の部分は3割まで、押した大学の帯は4割5分までにし、
            // 道にはいつも4分の1以上を残す(小さいスマホで文字を大きくしても、道が消えて四角を押せなくならないように。2.0.7)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final double takasa = constraints.maxHeight;
                  return Column(
                    children: [
                      // 上に固定する部分(区間の切り替えと、倍率のボタン・縮尺の棒)。
                      // 3割まで(超えるときは、この中だけでスクロールする)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: takasa * 0.3),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: _buildKotei(b, dan),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      // 通過順位速報・個人順位速報(2.0.8)
                      if (_hyouji != 0)
                        Expanded(child: _buildSokuhou(r0))
                      else ...[
                        // 縦が長くなるので、右端につまんで動かせるスクロールバーを出す(2.1.0。
                        // デスクトップで自動のスクロールバーと二重にならないように、自動のほうは止める。
                        // 黒い背景で見えるように、つまみは白っぽい色にする(_shiroScrollbar))
                        Expanded(
                          child: _shiroScrollbar(
                            controller: _michiScroll,
                            thickness: 10,
                            child: ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                              child: SingleChildScrollView(
                                controller: _michiScroll,
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                                child: _buildHontai(context, b, r0, dan, gamenTakasa),
                              ),
                            ),
                          ),
                        ),
                        // 押した大学の帯(4割5分まで。道をスクロールしていても見えるように、道の下(画面の一番下)に置く)
                        if (oshitaBun != null && x0 != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: takasa * 0.45),
                              child: _buildObi(context, r0, x0, oshitaBun),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
      ),
      // 画面の一番下の「戻る」は、道を広くするためになくした(左上の「←」と、Androidの戻る操作で閉じる。2.0.7)
    );
  }

  /// 押した大学の帯(順位と差。押すたびに、走った選手の説明文、次の区間を走る選手と進む。2.0.7)
  /// ・一番上の行(差の基準と、閉じる「×」)は固定し、その下(差の文・説明文や次の区間を走る選手・案内)は、
  ///   まとめて帯の中でスクロールする(帯の高さは置く側で抑える)
  /// ・「×」は、何かの理由で道が見えなくなっても帯を閉じられるようにするため
  Widget _buildObi(
    BuildContext context,
    _IchiKukan r0,
    _IchiDaigaku x0,
    String oshitaBun,
  ) {
    // 2回目に押したときの、走った選手の持ちタイムの表と能力(説明文の下に出す。2.1.0)
    final Widget? hashittaNaiyou = _hiraki == 1
        ? _kirokuToNouryoku(s: x0.senshu, g: x0.gSenshu, kukanIdx: r0.kk, kirokuAnka: false)
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 2, 2, 8),
      decoration: BoxDecoration(
        border: Border.all(color: _iro.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // 差の基準(1位との差か、目標順位との差か。スタートは差がないので出さない)
              Expanded(
                child: r0.kk < 0
                    ? const SizedBox.shrink()
                    : Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('差の基準', style: _chiisai),
                    _komaBotan(
                      'トップ',
                      !_mokuhyouKijun,
                      () => setState(() => _mokuhyouKijun = false),
                    ),
                    _komaBotan(
                      '目標順位',
                      _mokuhyouKijun,
                      () => setState(() => _mokuhyouKijun = true),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _oshita = -1;
                  _hiraki = 0;
                }),
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                tooltip: '閉じる',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // ここから下は、まとめて帯の中でスクロールする
          // (デスクトップで自動のスクロールバーと二重にならないように、自動のほうは止める)
          // (2.1.0から、黒い背景で見えるように、道のスクロールバーと同じ白っぽいつまみにする)
          Flexible(
            child: _shiroScrollbar(
              controller: _setsumeiScroll,
              thickness: 6,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  controller: _setsumeiScroll,
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    key: _obiNakaKey,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        oshitaBun,
                        style: const TextStyle(color: HENSUU.textcolor, fontSize: 13),
                      ),
                      if (_hiraki == 1) ...[
                        const Divider(height: 12, color: Colors.white24),
                        // 走った選手の行と、区間配置確認と同じ「詳細」(選手の詳細の画面を開く)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                _senshuGyou(r0, x0),
                                style: const TextStyle(color: Colors.yellowAccent, fontSize: 13),
                              ),
                            ),
                            if (x0.shousaiId != null)
                              TextButton(
                                onPressed: () => senshuShousaiHiraku(context, x0.shousaiId!),
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '詳細',
                                  style: TextStyle(color: HENSUU.LinkColor, fontSize: 15),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          x0.setsumei ?? '説明文はありません',
                          // ほかの大学に切り替えたときに、同じ高さに来るようにする目印
                          key: _ankaKey,
                          style: TextStyle(
                            color: HENSUU.textcolor.withOpacity(0.9),
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                        // 走った選手の持ちタイムの表と能力(3回目の次の区間を走る選手と同じ並び。2.1.0)
                        if (hashittaNaiyou != null) ...[
                          const Divider(height: 12, color: Colors.white24),
                          hashittaNaiyou,
                        ],
                      ],
                      // 次の区間を走る選手(区間配置確認のカードの上の行と、持ちタイムの表と能力。2.1.0)
                      if (_hiraki == 2) ...[
                        const Divider(height: 12, color: Colors.white24),
                        Text(r0.kk < 0 ? '1区を走る選手' : '次の区間を走る選手', style: _chiisai),
                        const SizedBox(height: 2),
                        _tsugiPanel(context, r0, x0),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        _hiraki == 0
                            ? 'もう一度押すと、走った選手の説明文が出ます'
                            : (_hiraki == 1 && _tsugiDaseru(x0)
                                  ? 'もう一度押すと、次の区間を走る選手が出ます'
                                  : 'もう一度押すと閉じます'),
                        style: _chiisai,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 小さなボタン(区間の切り替えと同じ形。[onTap] がnullなら押せない)
  Widget _komaBotan(String moji, bool on, VoidCallback? onTap) {
    final Color iro = onTap == null ? Colors.white24 : (on ? _iro : Colors.white70);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: on ? _iro.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: on ? _iro : Colors.white24),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(moji, style: TextStyle(color: iro, fontSize: 13)),
      ),
    );
  }

  /// 縮尺の棒(棒が短すぎず長すぎない、区切りのよい距離を選ぶ)
  Widget _shukushaku(double px) {
    int m = 2000;
    for (final int c in const [10, 20, 50, 100, 200, 500, 1000, 2000]) {
      if (c * px >= 40) {
        m = c;
        break;
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: m * px, height: 3, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          m < 1000 ? '${m}m' : '${m ~/ 1000}km',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  /// 区間を切り替える(押した大学の帯は閉じる。覚えない)
  void _kukanKaeru(int i) {
    setState(() {
      _erabu = i;
      _oshita = -1;
      _hiraki = 0;
    });
  }

  /// 区間を1つずつ動かす矢印([onTap] がnullなら、薄くして押せない。2.0.7)
  Widget _yajirushi(IconData icon, String setsumei, VoidCallback? onTap) {
    final bool dekiru = onTap != null;
    return Semantics(
      button: true,
      label: setsumei,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: dekiru ? _iro.withOpacity(0.6) : Colors.white24),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Icon(icon, size: 22, color: dekiru ? _iro : Colors.white24),
          ),
        ),
      ),
    );
  }

  /// 上に固定する部分(区間の切り替えと、倍率のボタン・縮尺の棒)
  /// 区間は「‹」「›」で1つずつ、真ん中を押して出る一覧で好きな区間に切り替える(区間が多くても1行。2.0.7)
  Widget _buildKotei(_IchiKankei b, int dan) {
    final int erabu = _erabu.clamp(0, b.kukan.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 配置(区間配置確認)のときは大学を選び、ほかのときは区間を選ぶ(2.0.9)
            if (_hyouji == 3)
              ..._daigakuErabi(b)
            else ...[
            _yajirushi(
              Icons.chevron_left,
              '前の区間',
              erabu > 0 ? () => _kukanKaeru(erabu - 1) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PopupMenuButton<int>(
                tooltip: '区間を選ぶ',
                initialValue: erabu,
                color: const Color(0xFF2A2A2A),
                onSelected: _kukanKaeru,
                itemBuilder: (context) => [
                  for (int i = 0; i < b.kukan.length; i++)
                    PopupMenuItem<int>(
                      value: i,
                      child: Text(
                        _kukanMei(b.kukan[i]),
                        style: TextStyle(color: i == erabu ? _iro : HENSUU.textcolor),
                      ),
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: _iro.withOpacity(0.15),
                    border: Border.all(color: _iro),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _kukanMei(b.kukan[erabu]),
                          style: const TextStyle(
                            color: _iro,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: _iro, size: 22),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _yajirushi(
              Icons.chevron_right,
              '次の区間',
              erabu < b.kukan.length - 1 ? () => _kukanKaeru(erabu + 1) : null,
            ),
            ],
            // 表示の切り替え(2.0.8。2.0.9からスタートしかないときも出す)
            const SizedBox(width: 8),
            _hyoujiBotan(b),
          ],
        ),
        // 表示の倍率(「−」「＋」と、おまかせ。覚えない)と縮尺の棒(位置のときだけ。2.0.8)
        if (_hyouji == 0) ...[
          const SizedBox(height: 8),
          Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _komaBotan(
              '−',
              false,
              dan > 0
                  ? () => setState(() {
                      _omakase = false;
                      _habaAwase = false;
                      _dan = dan - 1;
                    })
                  : null,
            ),
            Text(
              _bairitsuMei[dan],
              style: const TextStyle(
                color: HENSUU.textcolor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            _komaBotan(
              '＋',
              false,
              dan < _bairitsu.length - 1
                  ? () => setState(() {
                      _omakase = false;
                      _habaAwase = false;
                      _dan = dan + 1;
                    })
                  : null,
            ),
            // おまかせのときに押すと、幅に合わせる(おまかせ ↔)と入れ替わる(2.0.8)
            _komaBotan(
              _omakase && _habaAwase ? 'おまかせ ↔' : 'おまかせ',
              _omakase,
              () => setState(() {
                if (_omakase) {
                  _habaAwase = !_habaAwase;
                } else {
                  _omakase = true;
                }
              }),
            ),
            _shukushaku(_bairitsu[dan]),
          ],
        ),
        ],
      ],
    );
  }

  /// 次の表示(位置 → 通過 → 個人 → 配置 → 位置。スタートしかないときは、位置 → 配置 → 位置。2.0.9)
  int _tsugiHyouji(_IchiKankei b) {
    if (!b.kukan.any((x) => x.kk >= 0)) return _hyouji == 3 ? 0 : 3;
    return (_hyouji + 1) % 4;
  }

  /// 表示を切り替えるボタン(押すたびに「位置」→「通過」→「個人」→「配置」→「位置」。今の表示の名前を出す。
  /// 2.0.8。配置は2.0.9)
  Widget _hyoujiBotan(_IchiKankei b) {
    const List<String> mei = ['位置', '通過', '個人', '配置'];
    const Color iro = Colors.amberAccent;
    return Semantics(
      button: true,
      label: '表示の切り替え',
      child: Material(
        color: iro.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: iro, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            _hyouji = _tsugiHyouji(b);
            // 押した大学の帯は閉じる
            _oshita = -1;
            _hiraki = 0;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mei[_hyouji.clamp(0, 3)],
                  style: const TextStyle(
                    color: iro,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.sync, color: iro, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 配置(区間配置確認)で見ている大学(最初は自分の大学。学連選抜の監督の年は学連選抜。
  /// 自分の大学が出ていない年は、ID順の最初の大学。2.0.9)
  int _haichiUnivIma(_IchiKankei b) {
    final List<({int id, String mei})> l = b.haichiDaigaku;
    final int? erabi = _haichiUniv;
    if (erabi != null && l.any((x) => x.id == erabi)) return erabi;
    if (b.gakurenJibun && l.any((x) => x.id == kukanHaitiGakurenId)) {
      return kukanHaitiGakurenId;
    }
    final int? my = _gh?.MYunivid;
    if (my != null && l.any((x) => x.id == my)) return my;
    return l.isEmpty ? (my ?? 0) : l.first.id;
  }

  /// 大学を選ぶ欄(配置のとき。「‹」「›」は端まで行くと反対の端に回る(区間配置確認と同じ)。
  /// 大学名は1行に収め、入りきらないところは「…」で省く。一覧の中では全部出す。2.0.9)
  List<Widget> _daigakuErabi(_IchiKankei b) {
    final List<({int id, String mei})> l = b.haichiDaigaku;
    final int ima = _haichiUnivIma(b);
    final int i = l.indexWhere((x) => x.id == ima);
    void kaeru(int j) => setState(() => _haichiUniv = l[j].id);
    return [
      _yajirushi(
        Icons.chevron_left,
        '前の大学',
        l.length > 1 ? () => kaeru(i <= 0 ? l.length - 1 : i - 1) : null,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: PopupMenuButton<int>(
          tooltip: '大学を選ぶ',
          initialValue: ima,
          color: const Color(0xFF2A2A2A),
          onSelected: (id) => setState(() => _haichiUniv = id),
          itemBuilder: (context) => [
            for (final ({int id, String mei}) x in l)
              PopupMenuItem<int>(
                value: x.id,
                child: Text(
                  x.mei,
                  style: TextStyle(color: x.id == ima ? _iro : HENSUU.textcolor),
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: _iro.withOpacity(0.15),
              border: Border.all(color: _iro),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    i >= 0 ? l[i].mei : '',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _iro,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: _iro, size: 22),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      _yajirushi(
        Icons.chevron_right,
        '次の大学',
        l.length > 1 ? () => kaeru(i < 0 || i >= l.length - 1 ? 0 : i + 1) : null,
      ),
    ];
  }

  /// 通過順位速報・個人順位速報(今の速報の画面を、上のバーと下の「前・次」を外して入れる。
  /// 区間はパネルで選んだ区間。個人順位速報は、レースの途中は途中用、結果画面では結果画面用。2.0.8)
  Widget _buildSokuhou(_IchiKukan r) {
    // 配置(区間配置確認。区間に関係なく、パネルで選んだ大学。2.0.9)
    if (_hyouji == 3) {
      final _IchiKankei? b = _b;
      return ModalKukanHaitiView(
        targetUnivid: _gh?.MYunivid ?? 0,
        univid: b == null ? null : _haichiUnivIma(b),
        umekomi: true,
      );
    }
    if (r.kk < 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'スタート前なので、通過順位と個人順位はまだありません。',
            style: TextStyle(color: HENSUU.textcolor),
          ),
        ),
      );
    }
    if (_hyouji == 1) {
      return ModalKukanResultListViewPass(umekomi: true, kukan: r.kk);
    }
    return widget.made == null
        ? ModalKukanResultListView(umekomi: true, kukan: r.kk)
        : ModalKukanResultListView350(umekomi: true, kukan: r.kk);
  }

  /// スクロールする部分(説明の文と、道と大学名の四角。道の部分は横にもスクロールする)
  Widget _buildHontai(
    BuildContext context,
    _IchiKankei b,
    _IchiKukan r,
    int dan,
    double gamenTakasa,
  ) {
    const TextStyle setsumei = TextStyle(color: Colors.white70, fontSize: 12, height: 1.5);
    final double px = _bairitsu[dan];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 説明の文は短くする(おまかせと集団の説明は、説明書に書く)
        if (r.kk < 0)
          const Text('スタート前の並びです(大学のID順)。', style: setsumei)
        else ...[
          Text(
            '${r.kk + 1}区終了時点のタイム差を、区間の平均の速さで距離に換算した位置関係の図です。',
            style: setsumei,
          ),
          const Text('右の括弧は前の大学との間です(点線は途中を省略した間)。', style: setsumei),
        ],
        // オレンジの枠の行は、押すと自分の大学(学連選抜の監督の年は学連選抜)の四角まで動く(2.1.0。下線を引く)
        if (r.narabi.any((x) => x.jibun))
          GestureDetector(
            onTap: _jibunHeIdou,
            child: Text(
              'オレンジの枠: あなたの大学(押すとそこまで動きます)',
              style: setsumei.copyWith(decoration: TextDecoration.underline),
            ),
          ),
        if (b.opAri)
          b.gakurenJibun
              ? GestureDetector(
                  onTap: _jibunHeIdou,
                  child: Text(
                    'オレンジの点線の枠: 学連選抜(あなたが監督。順位に数えない。押すとそこまで動きます)',
                    style: setsumei.copyWith(decoration: TextDecoration.underline),
                  ),
                )
              : const Text('点線の枠: 学連選抜(順位に数えない)', style: setsumei),
        Text(
          r.kk < 0
              ? '大学の四角を押すと、下に1区を走る選手が出ます。'
              : (r.kk + 1 < b.zenKukansuu
                    ? '大学の四角を押すと下に差が、もう一度押すと走った選手の説明文、さらに押すと次の区間を走る選手が出ます。'
                    : '大学の四角を押すと下に差が、もう一度押すと走った選手の説明文が出ます。'),
          style: setsumei,
        ),
        if (_omakase && _habaAwase)
          const Text('道が横幅に収まるように、道の上の文字を小さくします(おまかせ ↔)。', style: setsumei),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            TextScaler scaler = MediaQuery.textScalerOf(context);
            final bool habaAwase = _omakase && _habaAwase;
            final double kihon = scaler.scale(13) / 13;
            // 集団の1行に並べる数(2.1.0)。おまかせ ↔ のときは、文字を一番小さくした(6割)ときに入る数にし、
            // 下で、その数が横幅に入るところまで文字を小さくする(文字が小さくなって3校が入るなら3校)
            final int gyouSuu = _gyouSuuKimeru(
              b,
              w,
              habaAwase ? TextScaler.linear(kihon * _habaSaishou) : scaler,
            );
            _Haichi h = _haichi(b, r, w, scaler, px, gamenTakasa, gyouSuu);
            // 幅に合わせる(おまかせ ↔)ときは、横幅に収まるまで道の上の文字を小さくして並べ直す
            // (文字の幅で四角の幅と右の文の幅が決まるので、何回か測り直す。6割まで。2.0.8)
            bool chiisaku = false;
            if (habaAwase && h.haba > w) {
              double k = 1;
              for (int n = 0; n < 4 && h.haba > w + 0.5 && k > _habaSaishou; n++) {
                k = math.max(_habaSaishou, k * w / h.haba);
                scaler = TextScaler.linear(kihon * k);
                h = _haichi(b, r, w, scaler, px, gamenTakasa, gyouSuu);
              }
              chiisaku = true;
            }
            // 道と四角と差の部分は、画面より広いときは横にもスクロールする(文は折り返さない)
            final Widget michi = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: h.haba,
                height: h.takasa,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _MichiPainter(h))),
                    // 前の大学(集団)との間の距離と秒差(括弧の真ん中。2.1.0から距離と秒差の2行。詰めた間は括弧が点線)
                    for (final _Aida a in h.aida)
                      Positioned(
                        left: h.mojiX,
                        top: a.top,
                        child: Text(a.moji, style: _migiStyle, softWrap: false),
                      ),
                    // シード権ライン(2.1.0から、道の帯の上だけに引く。右の括弧と差の文には重ならない。
                    // 文字を大きくして文が道の帯より長くなっても、はみ出さないように後ろを切る)
                    if (h.seedTop != null)
                      Positioned(
                        left: 0,
                        top: h.seedTop!,
                        width: h.michiHaba,
                        child: Row(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: h.michiHaba * 0.7),
                              child: const Text(
                                'シード権ライン',
                                style: _seedMojiStyle,
                                softWrap: false,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 8,
                                child: CustomPaint(painter: _TensenPainter()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // 集団の中で、先頭から遅れた秒の行の右の「+1秒」(2.1.0)
                    for (final _Gyou g in h.gyou)
                      if (g.byou != null)
                        Positioned(
                          left: g.byouX,
                          top: g.y,
                          height: g.h,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: 1,
                            child: Text(g.byou!, style: _chiisai, softWrap: false),
                          ),
                        ),
                    // 大学の四角
                    for (final _Gyou g in h.gyou)
                      for (final _Hako hk in g.hako)
                        Positioned(
                          left: hk.x,
                          top: g.y + (g.h - hk.h) / 2,
                          width: hk.w,
                          height: hk.h,
                          child: _hakoWidget(b, r, hk, scaler),
                        ),
                  ],
                ),
              ),
            );
            // 文字を小さくしたときは、測ったときと同じ大きさで道の上の文字を出す
            if (!chiisaku) return michi;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: scaler),
              child: michi,
            );
          },
        ),
      ],
    );
  }

  /// 大学の四角(押すと、画面の下に差を出す。押すたびに、走った選手の説明文、次の区間を走る選手と進み、
  /// その次に押すと消す。2.0.7)
  Widget _hakoWidget(_IchiKankei b, _IchiKukan r, _Hako hk, TextScaler scaler) {
    final _IchiDaigaku x = r.narabi[hk.i];
    final bool orange = x.jibun || (b.gakurenJibun && x.op);
    final bool erabareta = _oshita == hk.i;
    final bool ichii = r.kk >= 0 && identical(x, r.top);
    final Color wakuIro = erabareta
        ? _iro
        : (orange ? _jibunIro : (ichii ? Colors.white : Colors.white38));
    final double futosa = (erabareta || orange || ichii) ? _wakuSaidai : 1;
    // 学連選抜は点線の枠(押したときは水色の線の枠)
    final bool tensen = x.op && !erabareta;
    Widget naka = Container(
      padding: const EdgeInsets.symmetric(horizontal: _hakoYoko, vertical: _hakoTate),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        border: tensen ? null : Border.all(color: wakuIro, width: futosa),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: _hakoNaka(r, hk.i, scaler),
    );
    if (tensen) {
      naka = CustomPaint(
        foregroundPainter: _TensenWakuPainter(orange ? _jibunIro : Colors.white),
        child: naka,
      );
    }
    final Widget hako = GestureDetector(
      // 押した四角は、下の帯が伸びて隠れるときに見えるようにするため、印を付けておく
      key: erabareta ? _oshitaKey : null,
      behavior: HitTestBehavior.opaque,
      onTap: () => _hakoOsu(r, hk.i),
      child: naka,
    );
    // 自分の大学(学連選抜の監督の年は学連選抜)の四角にも印を付ける(説明の「オレンジの枠」の行から動く先。2.1.0)
    return orange ? KeyedSubtree(key: _jibunKey, child: hako) : hako;
  }
}

/// 点線で線を引く(パスに沿って、4px引いて3px空ける)
void _tensenDeHiku(Canvas canvas, Path path, Paint p) {
  for (final metric in path.computeMetrics()) {
    double d = 0;
    while (d < metric.length) {
      canvas.drawPath(metric.extractPath(d, math.min(d + 4, metric.length)), p);
      d += 7;
    }
  }
}

/// 道の帯・切れ目の印・いちばん前の線・間の括弧
class _MichiPainter extends CustomPainter {
  final _Haichi h;

  _MichiPainter(this.h);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint michi = Paint()..color = _michiIro;
    final double shita = size.height - 6;
    // 道の帯(詰めた間の真ん中は空ける)
    double y = h.michiUe;
    for (final k in h.kireme) {
      final double m = (k.y0 + k.y1) / 2;
      if (m - 5 > y) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(0, y, h.michiHaba, m - 5), const Radius.circular(6)),
          michi,
        );
      }
      y = m + 5;
    }
    if (shita > y) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(0, y, h.michiHaba, shita), const Radius.circular(6)),
        michi,
      );
    }
    // 切れ目の印(帯の切れ目の上下に点線)
    final Paint kiremeSen = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;
    for (final k in h.kireme) {
      final double m = (k.y0 + k.y1) / 2;
      for (double x = 0; x < h.michiHaba; x += 6) {
        final double x2 = math.min(x + 3, h.michiHaba);
        canvas.drawLine(Offset(x, m - 5), Offset(x2, m - 5), kiremeSen);
        canvas.drawLine(Offset(x, m + 5), Offset(x2, m + 5), kiremeSen);
      }
    }
    // 2校以上の集団を囲む枠(薄い線と、ほんの少し明るい塗り)
    final Paint wakuNuri = Paint()..color = const Color(0x12FFFFFF);
    final Paint wakuSen = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final Rect rc in h.waku) {
      final RRect rr = RRect.fromRectAndRadius(rc, const Radius.circular(8));
      canvas.drawRRect(rr, wakuNuri);
      canvas.drawRRect(rr, wakuSen);
    }
    // いちばん前(1位)の線
    canvas.drawLine(
      Offset(0, h.sentouY),
      Offset(h.michiHaba, h.sentouY),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );
    // 前の大学(集団)との間の括弧(詰めた間は点線)
    final Paint kakko = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final _Aida a in h.aida) {
      final Path path = Path()
        ..moveTo(h.kakkoX, a.y0)
        ..lineTo(h.kakkoX + 8, a.y0)
        ..lineTo(h.kakkoX + 8, a.y1)
        ..lineTo(h.kakkoX, a.y1);
      if (a.tsume) {
        _tensenDeHiku(canvas, path, kakko);
      } else {
        canvas.drawPath(path, kakko);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MichiPainter old) => old.h != h;
}

/// 学連選抜の四角の点線の枠
class _TensenWakuPainter extends CustomPainter {
  final Color iro;

  _TensenWakuPainter(this.iro);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = iro
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final Path waku = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          const Radius.circular(4),
        ),
      );
    _tensenDeHiku(canvas, waku, p);
  }

  @override
  bool shouldRepaint(covariant _TensenWakuPainter old) => old.iro != iro;
}

/// シード権ラインの点線
class _TensenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = Colors.amberAccent
      ..strokeWidth = 1;
    final double y = size.height / 2;
    for (double x = 0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _TensenPainter old) => false;
}
