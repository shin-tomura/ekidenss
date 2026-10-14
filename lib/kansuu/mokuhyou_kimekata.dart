import 'package:flutter/material.dart';
import 'package:ekiden/ghensuu.dart';

// ------------------------------------------------------------
// コンピュータの大学の目標順位の決め方(Ghensuu.spurtryokuseichousisuu2。2.0.1でここにまとめた)
//
// ・値: 93=向上心豊か(2.0.0までの初期値のまま)、94=向上心豊か(2.0.1から、画面で選んだとき)、
//   1=対校戦順位追従(2.0.1からの初期値)、2=常にシード権意識
//   (93と94は同じ決め方。main.dart の6月5日の目標順位設定と、KirokuKousin.dart の予選突破後の目標)
// ・向上心豊かは前年の順位から2〜4つ上を目標にするので、前年2〜5位の大学がそろって目標1位になる。
//   先頭の大学の後ろで襷を受けた大学はみな「目標順位を下回った」焦りで遅れ(mokuhyou_hosei.dart)、
//   先頭の大学だけがこの損を受けないため、1校が何十年も勝ち続けやすかった
//   (2.0.1の開発中に30年スキップで比べた。向上心豊かでは名声1位の大学が正月駅伝30回中25〜30回優勝、
//    対校戦順位追従では名声2位の大学が17回・1位の大学が9回で、途中で入れ替わった)
// ・2.0.1から初期値を対校戦順位追従にし、93(初期値のまま)のデータは、起動時と保存データの読み込み時に
//   1にする(mokuhyouKimekata201Ikou)。値で見分けるので印は要らず、何度呼んでもよい。
//   画面で向上心豊かを選んだら94で保存する
//   (この設定は新しいゲームでも引き継がれるので、新しいゲームで0に戻る予備の配列の印にすると、
//    新しいゲームのあとに選び直した向上心豊かが、次の起動でまた変えられてしまうため)
// ・常にシード権意識・対校戦順位追従を選んでいたデータはそのまま
// ・移行で変えたときは、最初の画面(99First.dart)か、保存データを読み込んだあと(save_load_screen.dart)に、
//   一度だけお知らせのダイアログを出す(mokuhyouKimekataOshiraseDialog)
// ------------------------------------------------------------

/// 向上心豊か(2.0.0までの初期値のまま。移行で対校戦順位追従にする)
const int mokuhyouKimekataKoujoushinShokiti = 93;

/// 向上心豊か(2.0.1から、画面で選んだとき)
const int mokuhyouKimekataKoujoushin = 94;

/// 対校戦順位追従(2.0.1からの初期値)
const int mokuhyouKimekataTaikousen = 1;

/// 常にシード権意識
const int mokuhyouKimekataSeed = 2;

/// 向上心豊かの決め方か(93・94)
bool mokuhyouKimekataKoujoushinKa(int atai) =>
    atai == mokuhyouKimekataKoujoushinShokiti ||
    atai == mokuhyouKimekataKoujoushin;

/// 正しい値か(QRコードの読み込みで使う)
bool mokuhyouKimekataTadashii(int atai) =>
    mokuhyouKimekataKoujoushinKa(atai) ||
    atai == mokuhyouKimekataTaikousen ||
    atai == mokuhyouKimekataSeed;

/// 移行で変えたことを知らせるダイアログを、まだ出していないか(メモリだけ。移行は一度しか起きない)
class MokuhyouKimekataOshirase {
  static bool dasu = false;
}

/// 2.0.1の移行: 向上心豊かが初期値のまま(93)なら、対校戦順位追従にする(保存もする)
/// 変えたときはお知らせのダイアログを出す印を立てて、trueを返す
/// (main.dart の起動のときと、save_load_screen.dart の読み込みのときに呼ぶ。版の番号では判定しない)
Future<bool> mokuhyouKimekata201Ikou(Ghensuu gh) async {
  if (gh.spurtryokuseichousisuu2 != mokuhyouKimekataKoujoushinShokiti) {
    return false;
  }
  gh.spurtryokuseichousisuu2 = mokuhyouKimekataTaikousen;
  await gh.save();
  MokuhyouKimekataOshirase.dasu = true;
  return true;
}

/// 移行で変えていれば、お知らせのダイアログを一度だけ出す
Future<void> mokuhyouKimekataOshiraseDialog(BuildContext context) async {
  if (!MokuhyouKimekataOshirase.dasu) return;
  MokuhyouKimekataOshirase.dasu = false;
  await showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'コンピュータの大学の目標順位の決め方を変えました',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '初期値だった「向上心豊か」を、新しい初期値の「対校戦順位追従設定」にしました。\n\n'
            '前年の順位から一斉に優勝を目指す決め方では、1校が何十年も勝ち続けやすかったためです。\n\n'
            '前の決め方に戻したいときは、説明画面の設定タブの「目標順位決め方設定(コンピュータの大学)」で選び直せます。',
            style: TextStyle(color: Colors.white70, height: 1.6),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
