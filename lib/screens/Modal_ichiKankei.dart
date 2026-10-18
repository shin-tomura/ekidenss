// 駅伝の区間終了時点の位置関係(2.0.6)
// レースの途中の区間ごとの画面(mode 350)と、結果画面(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝)の、
// 区間ごとのタイム分布と1枚にまとめたカード(KukanBunsekiCard。右半分)から開く。
// ・幅のある道の帯に、大学名を四角で囲んで、1位からの距離の位置(四角の真ん中)に置き、
//   道の右に1位との差(タイムと距離)を出す。
// ・画面の上で四角が重なる大学は、横に並べて集団のように見せる(倍率で分かれ方が変わり、拡大するとばらける)。
//   横に並びきらないときは、次の行に回す(集団の中の位置は、四角1つ分の高さまでずれる)。
//   道の右の差は、横に並んだ組(行)ごとに、先頭の大学の差と「ほか○校」で出す。
// ・大学の四角を押すと、その大学の順位・1位との差・前の大学(1位は次の大学)との差を、
//   画面の下(「戻る」の上)に固定した帯に出す。
// ・区間の切り替えと、表示の倍率のボタン・縮尺の棒は、画面の上に固定する(どちらも折り返す)。
//   固定の部分は画面の高さの4割までで、超えるときは固定の部分の中だけでスクロールする。
// ・距離は「1位が区間を走り終えたとき、ほかの大学がどれだけ後ろにいるか」を、その区間の出場校の
//   区間タイムの平均から出した速さ(全員で同じ。学連選抜は平均に入れない)で、タイム差から換算したもの。
//   速さを全員で1つにするので、距離はタイム差に比例し、順位と位置の並びが逆にならない
//   (ゲームとしての見せ方。1位が着いた時点か最後の大学が着いた時点か、などは考えない)。
// ・1区から終わった区間まで切り替えられる(覚えない。開くたびに一番あとの区間)。
// ・前の大学との間のうち、飛び抜けて大きい間(その区間の間の中央値の4倍以上。大きい順に多くて3か所。
//   _tobinukeAida)だけを詰めて、道に切れ目の印と、その間の距離を出す。倍率ではなくデータで決めるので、
//   だいたい同じくらい空いているときは詰めない。手動で倍率を選んでいるときは、1つの間が
//   画面の高さを超えるところも詰める(拡大しすぎて、何もない道を延々とスクロールしないように)。
//   (最初は「画面で144pxを超えたら」詰めていたが、おまかせの倍率とぶつかり、出場校の少ない大会や
//   差の開いた区間で、ほとんどの間が詰められて位置関係がつかめなかったので、2.0.6の開発中に変えた)
// ・表示の倍率(1mあたりの高さ)は「−」「＋」で6段階に変えられる(文字の大きさは変わらない)。
//   開いたときは「おまかせ」(区間ごとに、詰めた間を除いた1位から最後尾までの長さが、画面の高さの
//   およそ2つ分に収まる一番大きい倍率。大きく遅れた大学に引っぱられて先頭のほうが縮こまらないように)。
//   「−」「＋」を押すとおまかせが外れ、区間を切り替えてもその倍率のまま。
//   覚えない(画面を閉じたらおまかせに戻る)。倍率のボタンの横に縮尺の棒を出す。
// ・11月駅伝は8位、正月駅伝は10位の下にシード権ラインを引く(10月駅伝とカスタム駅伝はなし)。
//   ラインをまたいでは横に並べない。
// ・四角の見た目: 自分の大学はオレンジの塗り、1位は太い白の枠、学連選抜(正月駅伝のオープン参加)は
//   点線の枠(学連選抜の監督をした年はオレンジの点線)。学連選抜は順位とシード権ラインに数えない。
// ・差は「+33秒 約180m」の形(1kmまでは10m単位、1km以上は「約1.2km」)。秒は画面と同じく切り捨ててから
//   引き(saByou)、距離はその秒から出す。1位との差が0秒なら「トップと並走」。
// ・結果は記事と同じ EkidenKekka(kiji_kekka.dart)から作る。レースの途中は1区から終わった区間まで。
//   新しく保存するものはない。作れなければカードを出さない。
// ・2.0.6の開発中に、点と名前の行の形から四角の形に変え、2枚あったカード(タイム分布と位置関係)を1枚にした。

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/screens/Modal_kukanTimeBunpu.dart'
    show KukanBunpuYomikomi, kukanBunpuYomu, kukanBunpuHanbun, kukanBunpuMidashiHaba;

/// 表示の倍率の段階(1mあたりの高さ(px))と名前(×1は、最初に作ったときの決め打ちの倍率)
const List<double> _bairitsu = [0.1, 0.2, 0.4, 0.8, 1.6, 3.2];
const List<String> _bairitsuMei = ['×1/4', '×1/2', '×1', '×2', '×4', '×8'];

/// おまかせの倍率: 1位から最後尾までが、画面の高さのこの倍に収まる一番大きい倍率
const double _omakaseGamen = 2.0;

/// 飛び抜けて大きい間: その区間の間の中央値の、この倍以上
const double _tobinukeBai = 4;

/// 飛び抜けて大きい間として詰めるのは、大きい順に多くてこの数まで
const int _tobinukeSaidai = 3;

/// 飛び抜けて大きい間の下限(m。並走が多くて中央値が0に近いときに、小さな間を詰めないように)
const double _tobinukeSaitei = 50;

/// 詰めたところの高さ(px)
const double _tsumePx = 52;

/// 道の帯の幅(画面の幅に対する割合。四角が広いときは、四角が入るまで広げる)
const double _michiWariai = 0.6;

/// 道の帯の幅の上限(画面の幅に対する割合。右の差の文の場所を残す)
const double _michiSaidai = 0.75;

/// 四角どうし・行どうしのすきま
const double _sukima = 4;

/// 四角の中の余白(横・縦)
const double _hakoYoko = 6;
const double _hakoTate = 3;

/// 四角の枠の太さの最大(四角の大きさを決めるときに、これだけ見込む)
const double _wakuSaidai = 2;

/// 道の帯の色
const Color _michiIro = Color(0xFF1C1C1C);

/// カードと位置関係の色
const Color _iro = Colors.lightBlueAccent;

/// 自分の大学の色(区間ごとのタイム分布と同じ)
const Color _jibunIro = Colors.orangeAccent;

/// 距離の文(「約180m」「約1.2km」)
String _kyoriMoji(double m) {
  final int r = (m / 10).round() * 10;
  if (r < 1000) return '約${r}m';
  return '約${(m / 1000).toStringAsFixed(1)}km';
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

  const _IchiDaigaku(this.mei, this.ruikei, this.juni, this.jibun, this.op);
}

/// 区間1つ分の位置関係
class _IchiKukan {
  /// 区間(0が1区)
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

  /// 1位との差の文(「トップ」「+33秒 約180m」「トップと並走」「トップより5秒前 約30m」)
  String saBun(_IchiDaigaku x) {
    if (identical(x, top)) return 'トップ';
    final int s = sa(x);
    if (s == 0) return 'トップと並走';
    if (s < 0) return 'トップより${saMoji(s)}前 ${_kyoriMoji(-s * hayasa)}';
    return '+${saMoji(s)} ${_kyoriMoji(s * hayasa)}';
  }

  /// 2つの大学の差の文(「+5秒 約30m」。0秒は「並走」)
  String futatsuBun(_IchiDaigaku osoi, _IchiDaigaku hayai) {
    final int s = saByou(osoi.ruikei, hayai.ruikei);
    if (s <= 0) return '並走';
    return '+${saMoji(s)} ${_kyoriMoji(s * hayasa)}';
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

  _IchiKankei._(this.kukan, this.seed, this.gakurenJibun, this.zenKukansuu, this.race);

  /// 大会[race]の結果から作る([made] を渡すと、レースの途中の1区から[made]区まで)
  /// (思わぬデータで画面が止まらないよう、作れなければnull)
  static _IchiKankei? yomu(int race, {int? made}) {
    try {
      return _yomuHontai(race, made);
    } catch (e, st) {
      debugPrint('[区間終了時点の位置関係] 作れませんでした: $e\n$st');
      return null;
    }
  }

  static _IchiKankei? _yomuHontai(int race, int? made) {
    // レースの途中は、実況(kiji_jikkyou.dart)と同じく結果の記事ではない形で読む
    final KijiKankyou? k = KijiKankyou.yomuRace(race, kekka: made == null);
    if (k == null || !k.ekiden) return null;
    if (made != null && made <= 0) return null;
    final EkidenKekka? e = EkidenKekka.tsukuru(k, made: made);
    if (e == null) return null;
    final UnivData? my = k.jibunUniv;
    final bool gakurenAri = race == 2 && gakurenKonnenAri(k.gh);
    final bool gakurenJibun =
        gakurenAri && e.jibun == null && my != null && gakurenKantokuChuu(k.kantoku, my);
    final List<double> kyoriIchiran = k.gh.kyori_taikai_kukangoto.length > race
        ? k.gh.kyori_taikai_kukangoto[race]
        : const <double>[];
    final List<_IchiKukan> kukan = [];
    for (int kk = 0; kk < e.ks; kk++) {
      final double kyori = kyoriIchiran.length > kk ? kyoriIchiran[kk] : 0.0;
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
          _IchiDaigaku(l[i].mei, l[i].ruikei[kk], i, l[i].u.id == k.gh.MYunivid, false),
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
        narabi.insert(basho, _IchiDaigaku('学連選抜', g.tuukaTime, -1, false, true));
      }
      kukan.add(_IchiKukan(kk, kyori / heikin, narabi));
    }
    if (kukan.isEmpty) return null;
    return _IchiKankei._(kukan, e.seedSuu, gakurenJibun, k.kukansuu, race);
  }

  /// 区間[r]のいちばん上の印の文(中継所・往路のゴール・ゴール)
  String ueMoji(_IchiKukan r) {
    if (r.kk >= zenKukansuu - 1) return 'ゴール';
    if (race == 2 && zenKukansuu >= 6 && r.kk == 4) return '往路のゴール';
    return '${r.kk + 1}区→${r.kk + 2}区の中継所';
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
    barrierLabel: '区間終了時点の位置関係', // アクセシビリティ用ラベル
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


// カードの色(ニュース記事のカード(kiji_screen.dart の KijiLinkCard)とそろえる)
const Color _cardWaku = Color(0xFF161616);
const Color _cardSen = Color(0xFF333333);
const Color _cardUsui = Color(0xFF9E9E9E);

/// カードの位置関係の半分の文(一番あとの区間の、自分の大学(学連選抜の監督の年は学連選抜)の位置。
/// 出ていなければ1位と2位)
String _ichiCardBun(_IchiKankei b, _IchiKukan r) {
  _IchiDaigaku? jibun;
  _IchiDaigaku? ni;
  for (final _IchiDaigaku x in r.narabi) {
    if (x.jibun || (b.gakurenJibun && x.op)) jibun = x;
    if (!x.op && x.juni == 1) ni = x;
  }
  final _IchiDaigaku top = r.top;
  final _IchiDaigaku? ni2 = ni;
  String niBun() {
    if (ni2 == null) return '';
    final String s = r.futatsuBun(ni2, top);
    return s == '並走' ? '2位の${ni2.mei}と並走' : '2位の${ni2.mei}とは$s';
  }

  if (jibun == null) return '${top.mei}がトップ　${niBun()}';
  if (identical(jibun, top)) return '${top.mei} トップ　${niBun()}';
  if (jibun.op) return '学連選抜 ${r.saBun(jibun)}';
  return '${jibun.mei} ${jibun.juni + 1}位　${r.saBun(jibun)}';
}

/// カードの位置関係の半分(押すと位置関係の画面を開く)
Widget _ichiHanbun(BuildContext context, _IchiKankei b, int race, int? made) {
  final _IchiKukan r = b.kukan.last;
  return InkWell(
    onTap: () => _ichiGamenHiraku(context, race, made),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 見出し(高さを測れるように、WidgetSpan ではなく Row にする)
          const Row(
            children: [
              Icon(Icons.directions_run, color: _iro, size: 16),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  '位置関係',
                  style: TextStyle(color: _iro, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${r.kk + 1}区終了時点',
            style: const TextStyle(color: HENSUU.textcolor, fontSize: 12.5),
          ),
          Text(
            _ichiCardBun(b, r),
            style: const TextStyle(color: _jibunIro, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          const Text('位置関係を見る ›', style: TextStyle(color: _cardUsui, fontSize: 12)),
        ],
      ),
    ),
  );
}

/// 区間ごとのタイム分布と、区間終了時点の位置関係を1枚にまとめたカード(2.0.6)
/// ・左半分が区間ごとのタイム分布(Modal_kukanTimeBunpu.dart)、右半分が位置関係。それぞれ別に押せる
/// ・半分の幅に「区間ごとのタイム分布」の見出しが1行で収まらないとき(文字を大きくしているときなど)は、
///   左右ではなく上下に分ける(文字の大きさとカードの幅で測って決める)
/// ・片方が作れないときは、作れたほうだけでカードの幅を使う。両方とも作れなければ出さない
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
  KukanBunpuYomikomi? _bunpu;
  _IchiKankei? _ichi;

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
        _bunpu = bunpu;
        _ichi = ichi;
        _tsukutta = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final KukanBunpuYomikomi? bunpu = _bunpu;
    final _IchiKankei? ichi = _ichi;
    if (!_tsukutta || (bunpu == null && ichi == null)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: _cardWaku,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.tealAccent, width: 5),
                top: BorderSide(color: _cardSen),
                right: BorderSide(color: _cardSen),
                bottom: BorderSide(color: _cardSen),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double w = constraints.maxWidth;
                // 片方だけのときは、カードの幅を全部使う
                if (ichi == null) {
                  return kukanBunpuHanbun(context, bunpu!, race: widget.race, made: widget.made, haba: w - 16);
                }
                if (bunpu == null) return _ichiHanbun(context, ichi, widget.race, widget.made);
                // 半分の幅(中の余白8ずつを除く)に、タイム分布の見出しが1行で収まるか
                // (ふつうの文字なら、幅360ほどの電話でも左右に収まる)
                final double hanbun = (w - 1) / 2;
                final bool yoko =
                    kukanBunpuMidashiHaba(MediaQuery.textScalerOf(context)) <= hanbun - 16;
                if (yoko) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: hanbun,
                          child: kukanBunpuHanbun(
                            context,
                            bunpu,
                            race: widget.race,
                            made: widget.made,
                            haba: hanbun - 16,
                          ),
                        ),
                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: _cardSen,
                        ),
                        SizedBox(
                          width: hanbun,
                          child: _ichiHanbun(context, ichi, widget.race, widget.made),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    kukanBunpuHanbun(context, bunpu, race: widget.race, made: widget.made, haba: w - 16),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: _cardSen,
                    ),
                    _ichiHanbun(context, ichi, widget.race, widget.made),
                  ],
                );
              },
            ),
          ),
        ),
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

/// 横に並べた組(行)
class _Gyou {
  /// 上端
  final double y;

  /// 高さ(四角と、右の差の文の高いほう)
  double h;

  /// 次の四角の左端
  double x;

  final List<_Hako> hako = [];

  _Gyou(this.y, this.h, this.x);
}

/// 道の上の並べ方
class _Haichi {
  final List<_Gyou> gyou;

  /// 切れ目の印の文(上端・文)
  final List<({double top, String moji})> kireme;

  /// 道の切れ目(詰めたところの上と下)
  final List<({double y0, double y1})> kiremeMichi;

  /// シード権ラインの行の上端(引かないときはnull)
  final double? seedTop;

  /// 1位(いちばん前)の位置
  final double sentouY;

  /// 道の帯の上端
  final double michiUe;

  /// 道の帯の幅
  final double michiHaba;

  /// 全体の高さ
  final double takasa;

  _Haichi(
    this.gyou,
    this.kireme,
    this.kiremeMichi,
    this.seedTop,
    this.sentouY,
    this.michiUe,
    this.michiHaba,
    this.takasa,
  );
}

class _ModalIchiKankeiViewState extends State<ModalIchiKankeiView> {
  _IchiKankei? _b;

  /// 見ている区間(並びの番号)
  int _erabu = 0;

  /// 押した大学(narabi の番号。-1はなし)
  int _oshita = -1;

  /// 表示の倍率の段階(_bairitsu の番号。おまかせのときは使わない)
  int _dan = 2;

  /// 倍率がおまかせか(「−」「＋」を押すと外れる。覚えない)
  bool _omakase = true;

  static const TextStyle _chiisai = TextStyle(color: Colors.white54, fontSize: 11);
  static const TextStyle _seedMojiStyle = TextStyle(color: Colors.amberAccent, fontSize: 11);
  static const TextStyle _migiStyle = TextStyle(color: Colors.white70, fontSize: 12);

  @override
  void initState() {
    super.initState();
    final _IchiKankei? b = _IchiKankei.yomu(widget.race, made: widget.made);
    _b = b;
    // 一番あとの区間(レースの途中は終わったばかりの区間、結果画面では最終区)を開いておく
    if (b != null) _erabu = b.kukan.length - 1;
  }

  /// 四角の中の文(順位と大学名)
  TextSpan _hakoSpan(_IchiKankei b, _IchiKukan r, int i) {
    final _IchiDaigaku x = r.narabi[i];
    final bool orange = x.jibun || (b.gakurenJibun && x.op);
    return TextSpan(
      children: [
        TextSpan(
          text: x.op ? 'OP ' : '${x.juni + 1} ',
          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
        ),
        TextSpan(
          text: x.op ? '学連選抜' : x.mei,
          style: TextStyle(
            color: orange ? _jibunIro : HENSUU.textcolor,
            fontSize: 13,
            fontWeight: orange ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// 道の右の差の文(行の先頭の大学の差と「ほか○校」)
  TextSpan _migiSpan(_IchiKukan r, _Gyou g) {
    final _IchiDaigaku x = r.narabi[g.hako.first.i];
    final int hoka = g.hako.length - 1;
    return TextSpan(
      children: [
        TextSpan(text: r.saBun(x), style: _migiStyle),
        if (hoka > 0)
          TextSpan(
            text: ' ほか$hoka校',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
      ],
    );
  }

  /// 文の大きさ(幅は[maxW]まで)
  Size _ookisa(TextSpan span, double maxW, TextScaler scaler) {
    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: math.max(maxW, 1));
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
    if (r.narabi.length < 2) return 2;
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
    return dan;
  }

  /// 大学の四角と行の置き場所を決める([px] は1mあたりの高さ。[gamenTakasa] は画面の高さ。
  /// 手動で倍率を選んでいるとき([omakase] がfalse)は、1つの間が画面の高さを超えるところも詰める)
  _Haichi _haichi(
    _IchiKankei b,
    _IchiKukan r,
    double w,
    TextScaler scaler,
    double px,
    double gamenTakasa,
    bool omakase,
  ) {
    final int n = r.narabi.length;
    // 四角の大きさ(四角が道の帯からはみ出さないよう、文は道の帯の幅の上限で折り返す)
    final double hakoMojiSaidai = w * _michiSaidai - _sukima * 2 - _hakoYoko * 2 - _wakuSaidai * 2 - 2;
    final List<Size> hakoOokisa = [
      for (int i = 0; i < n; i++)
        () {
          final Size s = _ookisa(_hakoSpan(b, r, i), hakoMojiSaidai, scaler);
          return Size(
            s.width + _hakoYoko * 2 + _wakuSaidai * 2 + 2,
            s.height + _hakoTate * 2 + _wakuSaidai * 2,
          );
        }(),
    ];
    double hakoHabaSaidai = 0;
    double hakoTakasaSaidai = 0;
    for (final Size s in hakoOokisa) {
      hakoHabaSaidai = math.max(hakoHabaSaidai, s.width);
      hakoTakasaSaidai = math.max(hakoTakasaSaidai, s.height);
    }
    final double michiHaba = math.min(
      math.max(w * _michiWariai, hakoHabaSaidai + _sukima * 2),
      w * _michiSaidai,
    );
    final double migiHaba = math.max(w - michiHaba - 8, 1);

    final double ueTakasa = _ookisa(TextSpan(text: b.ueMoji(r), style: _chiisai), w, scaler).height;
    final double kiremeTakasa = _ookisa(const TextSpan(text: '〜', style: _chiisai), w, scaler).height;
    final double seedTakasa = _ookisa(
      const TextSpan(text: 'シード権ライン', style: _seedMojiStyle),
      w,
      scaler,
    ).height;
    final int opNozoku = r.narabi.where((x) => !x.op).length;
    final int? seed = (b.seed != null && opNozoku > b.seed!) ? b.seed : null;

    // 詰める間(飛び抜けて大きい間と、手動のときに画面の高さを超える間)
    final List<double> aida = _aida(r);
    final Set<int> tsume = _tobinukeAida(aida);
    if (!omakase) {
      for (int i = 0; i < aida.length; i++) {
        if (aida[i] * px > gamenTakasa) tsume.add(i);
      }
    }

    // 各大学の本当の位置(四角の真ん中)
    final double michiUe = ueTakasa + 4;
    final double sentouY = michiUe + _sukima + hakoTakasaSaidai / 2;
    final List<double> ty = [sentouY];
    final List<({double y0, double y1})> kiremeMichi = [];
    double y = sentouY;
    for (int i = 1; i < n; i++) {
      if (tsume.contains(i - 1)) {
        final double y0 = y;
        y += _tsumePx;
        kiremeMichi.add((y0: y0, y1: y));
      } else {
        y += aida[i - 1] * px;
      }
      ty.add(y);
    }

    // 四角を行に並べる(画面の上で重なる大学は横に並べる)
    final List<_Gyou> gyou = [];
    final List<({double top, String moji})> kireme = [];
    double? seedTop;
    double shita = michiUe; // いま置いたものの下端
    _Gyou? ima;
    int kiremeBan = 0;
    for (int i = 0; i < n; i++) {
      final _IchiDaigaku x = r.narabi[i];
      // 詰めた間のあとは、新しい行にし、切れ目の印の文を置く
      if (i > 0 && tsume.contains(i - 1) && kiremeBan < kiremeMichi.length) {
        final ({double y0, double y1}) k = kiremeMichi[kiremeBan++];
        final double kTop = math.max((k.y0 + k.y1) / 2 - kiremeTakasa / 2, shita + _sukima);
        kireme.add((top: kTop, moji: '〜 ${_kyoriMoji(aida[i - 1])} 〜'));
        shita = kTop + kiremeTakasa;
        ima = null;
      }
      // シード権ライン(シード権の順位の次の大学の前に引く。またいでは横に並べない)
      if (seed != null && !x.op && x.juni == seed) {
        final double sTop = shita + _sukima;
        seedTop = sTop;
        shita = sTop + seedTakasa;
        ima = null;
      }
      final Size s = hakoOokisa[i];
      final double nozomi = ty[i] - s.height / 2; // 四角の上端(本当の位置に置いたとき)
      final _Gyou? g0 = ima;
      if (g0 != null &&
          nozomi < g0.y + g0.h + _sukima &&
          g0.x + s.width <= michiHaba - _sukima) {
        // 前の四角と重なるので、横に並べる
        g0.hako.add(_Hako(i, g0.x, s.width, s.height));
        g0.x += s.width + _sukima;
      } else {
        final double top = math.max(nozomi, shita + _sukima);
        final _Gyou g = _Gyou(top, s.height, _sukima + s.width + _sukima);
        g.hako.add(_Hako(i, _sukima, s.width, s.height));
        gyou.add(g);
        ima = g;
      }
      // 行の高さ(四角と、右の差の文の高いほう)
      final _Gyou g1 = ima!;
      double hakoH = 0;
      for (final _Hako hk in g1.hako) {
        hakoH = math.max(hakoH, hk.h);
      }
      g1.h = math.max(hakoH, _ookisa(_migiSpan(r, g1), migiHaba, scaler).height);
      shita = g1.y + g1.h;
    }
    final double takasa = math.max(shita, y) + 16;
    return _Haichi(gyou, kireme, kiremeMichi, seedTop, sentouY, michiUe, michiHaba, takasa);
  }

  /// 押した大学の帯の文(順位・1位との差・前の大学との差)
  String? _oshitaBun(_IchiKukan r) {
    if (_oshita < 0 || _oshita >= r.narabi.length) return null;
    final _IchiDaigaku x = r.narabi[_oshita];
    final String mae = r.maeBun(_oshita);
    final String mei = x.op ? '学連選抜(OP)' : '${x.juni + 1}位 ${x.mei}';
    return mae.isEmpty ? '$mei　${r.saBun(x)}' : '$mei　${r.saBun(x)}　$mae';
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
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '区間終了時点の位置関係',
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
            : Column(
                children: [
                  // 上に固定する部分(区間の切り替えと、倍率のボタン・縮尺の棒)。
                  // 画面の高さの4割まで(超えるときは、この中だけでスクロールする)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: gamenTakasa * 0.4),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: _buildKotei(b, dan),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: _buildHontai(context, b, r0, dan, gamenTakasa),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: HENSUU.backgroundcolor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 押した大学の差(スクロールしていても見えるように、下に固定する)
            if (oshitaBun != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: _iro.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  oshitaBun,
                  style: const TextStyle(color: HENSUU.textcolor, fontSize: 13),
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("戻る", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
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

  /// 上に固定する部分(区間の切り替えと、倍率のボタン・縮尺の棒。どちらも折り返す)
  Widget _buildKotei(_IchiKankei b, int dan) {
    final int erabu = _erabu.clamp(0, b.kukan.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区間の切り替え(覚えない)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (int i = 0; i < b.kukan.length; i++)
              _komaBotan(
                '${b.kukan[i].kk + 1}区',
                i == erabu,
                () => setState(() {
                  _erabu = i;
                  _oshita = -1;
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // 表示の倍率(「−」「＋」と、おまかせ。覚えない)と縮尺の棒
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
                      _dan = dan + 1;
                    })
                  : null,
            ),
            _komaBotan('おまかせ', _omakase, () => setState(() => _omakase = true)),
            _shukushaku(_bairitsu[dan]),
          ],
        ),
      ],
    );
  }

  /// スクロールする部分(説明の文と、道と大学名の四角)
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
        Text(
          '1位が${r.kk + 1}区を走り終えたとき、ほかの大学がどれだけ後ろにいるかを、'
          '${r.kk + 1}区の平均の速さ(1kmあたり${saMoji(r.pace)})で距離に直しています。',
          style: setsumei,
        ),
        if (_omakase)
          const Text(
            'おまかせ: 大きく空いたところを除いて、1位から最後尾までが画面のおよそ2つ分に収まる倍率で出します。',
            style: setsumei,
          ),
        const Text('画面の上で重なる大学は、横に並べています(拡大するとばらけます)。', style: setsumei),
        if (r.narabi.any((x) => x.jibun))
          const Text('オレンジ: あなたの大学', style: setsumei),
        if (b.opAri)
          Text(
            b.gakurenJibun
                ? 'オレンジの点線の枠: 学連選抜(あなたが監督。順位に数えない)'
                : '点線の枠: 学連選抜(順位に数えない)',
            style: setsumei,
          ),
        const Text('大学の四角を押すと、画面の下に差が出ます。', style: setsumei),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final TextScaler scaler = MediaQuery.textScalerOf(context);
            final _Haichi h = _haichi(b, r, w, scaler, px, gamenTakasa, _omakase);
            final double migiX = h.michiHaba + 8;
            final double migiHaba = math.max(w - migiX, 1);
            return SizedBox(
              width: w,
              height: h.takasa,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: _MichiPainter(h))),
                  // いちばん上の印(中継所・ゴール)
                  Positioned(
                    left: 0,
                    top: 0,
                    width: w,
                    child: Text(b.ueMoji(r), style: _chiisai),
                  ),
                  // 詰めたところの距離
                  for (final k in h.kireme)
                    Positioned(
                      left: 0,
                      top: k.top,
                      width: h.michiHaba,
                      child: Text(k.moji, style: _chiisai, textAlign: TextAlign.center),
                    ),
                  // シード権ライン
                  if (h.seedTop != null)
                    Positioned(
                      left: 0,
                      top: h.seedTop!,
                      width: w,
                      child: Row(
                        children: [
                          const Text('シード権ライン', style: _seedMojiStyle),
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
                  // 大学の四角と、行ごとの差
                  for (final _Gyou g in h.gyou) ...[
                    for (final _Hako hk in g.hako)
                      Positioned(
                        left: hk.x,
                        top: g.y,
                        width: hk.w,
                        height: hk.h,
                        child: _hakoWidget(b, r, hk),
                      ),
                    Positioned(
                      left: migiX,
                      top: g.y,
                      width: migiHaba,
                      child: Text.rich(_migiSpan(r, g)),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// 大学の四角(押すと、画面の下に差を出す。もう一度押すと消す)
  Widget _hakoWidget(_IchiKankei b, _IchiKukan r, _Hako hk) {
    final _IchiDaigaku x = r.narabi[hk.i];
    final bool orange = x.jibun || (b.gakurenJibun && x.op);
    final bool erabareta = _oshita == hk.i;
    final bool ichii = identical(x, r.top);
    final Color wakuIro = erabareta
        ? _iro
        : (orange ? _jibunIro : (ichii ? Colors.white : Colors.white38));
    final double futosa = (erabareta || orange || ichii) ? _wakuSaidai : 1;
    // 学連選抜は点線の枠(押したときは水色の線の枠)
    final bool tensen = x.op && !erabareta;
    Widget naka = Container(
      padding: const EdgeInsets.symmetric(horizontal: _hakoYoko, vertical: _hakoTate),
      decoration: BoxDecoration(
        color: orange ? _jibunIro.withOpacity(0.18) : const Color(0xFF101010),
        border: tensen ? null : Border.all(color: wakuIro, width: futosa),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.centerLeft,
      child: Text.rich(_hakoSpan(b, r, hk.i)),
    );
    if (tensen) {
      naka = CustomPaint(
        foregroundPainter: _TensenWakuPainter(orange ? _jibunIro : Colors.white),
        child: naka,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _oshita = _oshita == hk.i ? -1 : hk.i),
      child: naka,
    );
  }
}

/// 道の帯・切れ目の印・いちばん前の線
class _MichiPainter extends CustomPainter {
  final _Haichi h;

  _MichiPainter(this.h);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint michi = Paint()..color = _michiIro;
    final double ue = h.michiUe;
    final double shita = size.height - 6;
    // 道の帯(切れ目のところは空ける)
    double y = ue;
    for (final k in h.kiremeMichi) {
      final double m = (k.y0 + k.y1) / 2;
      if (m - 7 > y) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(0, y, h.michiHaba, m - 7), const Radius.circular(6)),
          michi,
        );
      }
      y = m + 7;
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
    for (final k in h.kiremeMichi) {
      final double m = (k.y0 + k.y1) / 2;
      for (double x = 0; x < h.michiHaba; x += 6) {
        final double x2 = math.min(x + 3, h.michiHaba);
        canvas.drawLine(Offset(x, m - 7), Offset(x2, m - 7), kiremeSen);
        canvas.drawLine(Offset(x, m + 7), Offset(x2, m + 7), kiremeSen);
      }
    }
    // いちばん前(1位)の線
    canvas.drawLine(
      Offset(0, h.sentouY),
      Offset(h.michiHaba, h.sentouY),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );
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
    for (final metric in waku.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 4, metric.length)), p);
        d += 7;
      }
    }
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
