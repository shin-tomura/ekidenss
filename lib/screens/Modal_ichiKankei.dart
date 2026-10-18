// 駅伝の区間終了時点の位置関係(2.0.6)
// レースの途中の区間ごとの画面(mode 350)と、結果画面(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝)の
// 「区間終了時点の位置関係」のカード(IchiKankeiCard。区間ごとのタイム分布のカードのすぐ下)から開く。
// ・縦の道に、各大学を1位からの距離の位置に点で置き、右に順位・大学名・1位との差(タイムと距離)を出す。
//   名前の行が重なるときは行だけを下にずらし、細い線で点とつなぐ。
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
// ・学連選抜(正月駅伝のオープン参加)は白抜きの点で出し、順位とシード権ラインに数えない。
//   学連選抜の監督をした年は、オレンジの白抜き(区間ごとのタイム分布と同じ)。
// ・差は「+33秒 約180m」の形(1kmまでは10m単位、1km以上は「約1.2km」)。秒は画面と同じく切り捨ててから
//   引き(saByou)、距離はその秒から出す。1位との差が0秒なら「トップと並走」。
//   名前の行を押すと、前の大学(1位は2位の大学)との差も出す。
// ・結果は記事と同じ EkidenKekka(kiji_kekka.dart)から作る。レースの途中は1区から終わった区間まで。
//   新しく保存するものはない。作れなければカードを出さない。

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';

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

/// 道の横の位置
const double _michiX = 18;

/// 名前の行の左端
const double _mojiX = 38;

/// カードと位置関係の色
const Color _iro = Colors.lightBlueAccent;

/// 自分の大学の色(区間ごとのタイム分布と同じ)
const Color _jibunIro = Colors.orangeAccent;

/// 1位の点の色
const Color _ichiiIro = Colors.yellowAccent;

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

/// 区間終了時点の位置関係のカード(2.0.6)
/// ・区間ごとのタイム分布のカード(Modal_kukanTimeBunpu.dart の KukanBunpuCard)と同じ形で、そのすぐ下に置く
/// ・一番あとの区間(レースの途中は終わったばかりの区間、結果画面では最終区)の、
///   自分の大学(学連選抜の監督の年は学連選抜。出ていなければ1位と2位)の位置を出す
/// ・結果は画面を出したあとで1回だけ作る。区間が変わったら作り直すよう、置く側で key を付ける
/// ・結果がなければ出さない
class IchiKankeiCard extends StatefulWidget {
  final int race;

  /// レースの途中のとき、終わった区間の数(結果画面ではnull)
  final int? made;
  const IchiKankeiCard({super.key, required this.race, this.made});

  @override
  State<IchiKankeiCard> createState() => _IchiKankeiCardState();
}

class _IchiKankeiCardState extends State<IchiKankeiCard> {
  _IchiKankei? _b;

  /// 結果を作ったか
  bool _tsukutta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final _IchiKankei? b = _IchiKankei.yomu(widget.race, made: widget.made);
      if (!mounted) return;
      setState(() {
        _b = b;
        _tsukutta = true;
      });
    });
  }

  /// カードの2行目(自分の大学(学連選抜の監督の年は学連選抜)の位置。出ていなければ1位と2位)
  String _ichiBun(_IchiKankei b, _IchiKukan r) {
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

  @override
  Widget build(BuildContext context) {
    final _IchiKankei? b = _b;
    if (_tsukutta && b == null) return const SizedBox.shrink();
    final _IchiKukan? r = b == null ? null : b.kukan.last;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: _cardWaku,
          child: InkWell(
            onTap: () => _ichiGamenHiraku(context, widget.race, widget.made),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: _iro, width: 5),
                  top: BorderSide(color: _cardSen),
                  right: BorderSide(color: _cardSen),
                  bottom: BorderSide(color: _cardSen),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text.rich(
                    TextSpan(
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(Icons.directions_run, color: _iro, size: 16),
                        ),
                        TextSpan(text: ' 区間終了時点の位置関係'),
                      ],
                    ),
                    style: TextStyle(
                      color: _iro,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (b != null && r != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${r.kk + 1}区終了時点',
                      style: const TextStyle(color: HENSUU.textcolor, fontSize: 13),
                    ),
                    Text(
                      _ichiBun(b, r),
                      style: const TextStyle(color: _jibunIro, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    '位置関係を見る ›',
                    style: TextStyle(color: _cardUsui, fontSize: 12),
                  ),
                ],
              ),
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

/// 道の上の並べ方(名前の行の位置と、点の位置)
class _Haichi {
  /// 点の縦の位置(narabi と同じ並び)
  final List<double> tenY;

  /// 名前の行の上端と高さ
  final List<double> gyouTop;
  final List<double> gyouTakasa;

  /// 切れ目の印の文の行(上端・文)
  final List<({double top, String moji})> kireme;

  /// 道の切れ目(詰めたところの上と下)
  final List<({double y0, double y1})> kiremeMichi;

  /// シード権ラインの行の上端(引かないときはnull)
  final double? seedTop;

  /// いちばん上の印の文の高さ
  final double ueTakasa;

  /// 全体の高さ
  final double takasa;

  _Haichi(
    this.tenY,
    this.gyouTop,
    this.gyouTakasa,
    this.kireme,
    this.kiremeMichi,
    this.seedTop,
    this.ueTakasa,
    this.takasa,
  );
}

class _ModalIchiKankeiViewState extends State<ModalIchiKankeiView> {
  _IchiKankei? _b;

  /// 見ている区間(並びの番号)
  int _erabu = 0;

  /// 押して差を出している名前の行(-1はなし)
  int _oshita = -1;

  /// 表示の倍率の段階(_bairitsu の番号。おまかせのときは使わない)
  int _dan = 2;

  /// 倍率がおまかせか(「−」「＋」を押すと外れる。覚えない)
  bool _omakase = true;

  static const TextStyle _chiisai = TextStyle(color: Colors.white54, fontSize: 11);
  static const TextStyle _seedMojiStyle = TextStyle(color: Colors.amberAccent, fontSize: 11);

  @override
  void initState() {
    super.initState();
    final _IchiKankei? b = _IchiKankei.yomu(widget.race, made: widget.made);
    _b = b;
    // 一番あとの区間(レースの途中は終わったばかりの区間、結果画面では最終区)を開いておく
    if (b != null) _erabu = b.kukan.length - 1;
  }

  /// 名前の行の文
  TextSpan _gyouSpan(_IchiKankei b, _IchiKukan r, int i) {
    final _IchiDaigaku x = r.narabi[i];
    final bool orange = x.jibun || (b.gakurenJibun && x.op);
    return TextSpan(
      children: [
        TextSpan(
          text: x.op ? 'OP  ' : '${x.juni + 1}  ',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        TextSpan(
          text: x.op ? '学連選抜' : x.mei,
          style: TextStyle(
            color: orange ? _jibunIro : HENSUU.textcolor,
            fontSize: 13,
            fontWeight: orange ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        TextSpan(
          text: '  ${r.saBun(x)}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        if (_oshita == i)
          TextSpan(
            text: '\n${r.maeBun(i)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
      ],
    );
  }

  double _takasaOf(TextSpan span, double w, TextScaler scaler) {
    final TextPainter tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: math.max(w, 1));
    final double h = tp.height;
    tp.dispose();
    return h;
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

  /// 点と名前の行の位置を決める([px] は1mあたりの高さ。[gamenTakasa] は画面の高さ。
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
    final double mojiHaba = w - _mojiX - 4;
    final double ueTakasa = _takasaOf(TextSpan(text: b.ueMoji(r), style: _chiisai), mojiHaba, scaler);
    final double kiremeTakasa = _takasaOf(const TextSpan(text: '〜', style: _chiisai), mojiHaba, scaler);
    final double seedTakasa = _takasaOf(
      const TextSpan(text: 'シード権ライン', style: _seedMojiStyle),
      mojiHaba,
      scaler,
    );
    final int opNozoku = r.narabi.where((x) => !x.op).length;
    final int? seed = (b.seed != null && opNozoku > b.seed!) ? b.seed : null;

    final List<double> tenY = [];
    final List<double> gyouTop = [];
    final List<double> gyouTakasa = [];
    final List<({double top, String moji})> kireme = [];
    final List<({double y0, double y1})> kiremeMichi = [];
    double? seedTop;

    // 詰める間(飛び抜けて大きい間と、手動のときに画面の高さを超える間)
    final List<double> aida = _aida(r);
    final Set<int> tsume = _tobinukeAida(aida);
    if (!omakase) {
      for (int i = 0; i < aida.length; i++) {
        if (aida[i] * px > gamenTakasa) tsume.add(i);
      }
    }

    double y = ueTakasa + 14;
    double shitaHashi = ueTakasa + 4; // 前の行の下端
    final double base = r.narabi.first.ruikei;
    double maeD = 0;
    for (int i = 0; i < r.narabi.length; i++) {
      final _IchiDaigaku x = r.narabi[i];
      final double d = (x.ruikei - base) * r.hayasa;
      if (i > 0) {
        final double dd = d - maeD;
        if (tsume.contains(i - 1)) {
          final double y0 = y;
          y += _tsumePx;
          kiremeMichi.add((y0: y0, y1: y));
          final double kTop = math.max((y0 + y) / 2 - kiremeTakasa / 2, shitaHashi + 2);
          kireme.add((top: kTop, moji: '〜 ${_kyoriMoji(dd)} 〜'));
          shitaHashi = kTop + kiremeTakasa;
        } else {
          y += dd * px;
        }
      }
      maeD = d;
      // シード権ライン(シード権の順位の次の大学の前に引く)
      if (seed != null && !x.op && x.juni == seed) {
        final double sTop = shitaHashi + 2;
        seedTop = sTop;
        shitaHashi = sTop + seedTakasa;
      }
      final double h = _takasaOf(_gyouSpan(b, r, i), mojiHaba, scaler);
      final double top = math.max(y - h / 2, shitaHashi + 2);
      tenY.add(y);
      gyouTop.add(top);
      gyouTakasa.add(h);
      shitaHashi = top + h;
    }
    final double takasa = math.max(shitaHashi, y) + 20;
    return _Haichi(tenY, gyouTop, gyouTakasa, kireme, kiremeMichi, seedTop, ueTakasa, takasa);
  }

  @override
  Widget build(BuildContext context) {
    final _IchiKankei? b = _b;
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
        child: b == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '駅伝の結果がありません。',
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                child: _buildHontai(context, b),
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: HENSUU.backgroundcolor,
        child: ElevatedButton(
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

  Widget _buildHontai(BuildContext context, _IchiKankei b) {
    final int erabu = _erabu.clamp(0, b.kukan.length - 1);
    final _IchiKukan r = b.kukan[erabu];
    const TextStyle setsumei = TextStyle(color: Colors.white70, fontSize: 12, height: 1.5);
    // 表示の倍率(おまかせのときは区間ごとに選ぶ)
    final double gamenTakasa = MediaQuery.sizeOf(context).height;
    final int dan = _omakase
        ? _omakaseDan(r, gamenTakasa)
        : _dan.clamp(0, _bairitsu.length - 1);
    final double px = _bairitsu[dan];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区間の切り替え(覚えない)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (int i = 0; i < b.kukan.length; i++)
              GestureDetector(
                onTap: () => setState(() {
                  _erabu = i;
                  _oshita = -1;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: i == erabu ? _iro.withOpacity(0.2) : Colors.transparent,
                    border: Border.all(color: i == erabu ? _iro : Colors.white24),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${b.kukan[i].kk + 1}区',
                    style: TextStyle(
                      color: i == erabu ? _iro : Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '1位が${r.kk + 1}区を走り終えたとき、ほかの大学がどれだけ後ろにいるかを、'
          '${r.kk + 1}区の平均の速さ(1kmあたり${saMoji(r.pace)})で距離に直しています。',
          style: setsumei,
        ),
        if (r.narabi.any((x) => x.jibun))
          const Text('オレンジ: あなたの大学', style: setsumei),
        if (b.opAri)
          Text(
            b.gakurenJibun
                ? 'オレンジの白抜き: 学連選抜(あなたが監督。順位に数えない)'
                : '白抜き: 学連選抜(順位に数えない)',
            style: setsumei,
          ),
        const Text('名前の行を押すと、前の大学との差が出ます。', style: setsumei),
        const SizedBox(height: 10),
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
            _shukushaku(px),
          ],
        ),
        if (_omakase)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'おまかせ: 大きく空いたところを除いて、1位から最後尾までが画面のおよそ2つ分に収まる倍率で出します。',
              style: setsumei,
            ),
          ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            final TextScaler scaler = MediaQuery.textScalerOf(context);
            final _Haichi h = _haichi(b, r, w, scaler, px, gamenTakasa, _omakase);
            final double mojiHaba = w - _mojiX - 4;
            return SizedBox(
              width: w,
              height: h.takasa,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MichiPainter(r, h, b.gakurenJibun),
                    ),
                  ),
                  // いちばん上の印(中継所・ゴール)
                  Positioned(
                    left: _mojiX,
                    top: 0,
                    width: mojiHaba,
                    child: Text(b.ueMoji(r), style: _chiisai),
                  ),
                  // 詰めたところの距離
                  for (final k in h.kireme)
                    Positioned(
                      left: _mojiX,
                      top: k.top,
                      width: mojiHaba,
                      child: Text(k.moji, style: _chiisai),
                    ),
                  // シード権ライン
                  if (h.seedTop != null)
                    Positioned(
                      left: _mojiX,
                      top: h.seedTop!,
                      width: mojiHaba,
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
                  // 名前の行(押すと、前の大学との差を出す)
                  for (int i = 0; i < r.narabi.length; i++)
                    Positioned(
                      left: _mojiX,
                      top: h.gyouTop[i],
                      width: mojiHaba,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _oshita = _oshita == i ? -1 : i),
                        child: Text.rich(_gyouSpan(b, r, i)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 道・点・点と名前の行をつなぐ線
class _MichiPainter extends CustomPainter {
  final _IchiKukan r;
  final _Haichi h;
  final bool gakurenJibun;

  _MichiPainter(this.r, this.h, this.gakurenJibun);

  @override
  void paint(Canvas canvas, Size size) {
    if (h.tenY.isEmpty) return;
    final double ue = h.tenY.first;
    final double shita = math.max(h.tenY.last + 10, ue + 10);
    // 道(切れ目のところは空ける)
    final Paint michi = Paint()
      ..color = Colors.white24
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    double y = ue - 6;
    for (final k in h.kiremeMichi) {
      final double a = (k.y0 + k.y1) / 2 - 6;
      final double c = (k.y0 + k.y1) / 2 + 6;
      if (a > y) canvas.drawLine(Offset(_michiX, y), Offset(_michiX, a), michi);
      y = c;
    }
    if (shita > y) canvas.drawLine(Offset(_michiX, y), Offset(_michiX, shita), michi);
    // 切れ目の印(2本の斜めの線)
    final Paint kiremeSen = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.2;
    for (final k in h.kiremeMichi) {
      final double m = (k.y0 + k.y1) / 2;
      canvas.drawLine(Offset(_michiX - 7, m - 3), Offset(_michiX + 7, m - 7), kiremeSen);
      canvas.drawLine(Offset(_michiX - 7, m + 7), Offset(_michiX + 7, m + 3), kiremeSen);
    }
    // いちばん上の印(中継所・ゴール)の横線
    canvas.drawLine(
      Offset(_michiX - 12, ue),
      Offset(_michiX + 12, ue),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.5,
    );
    // 点と名前の行をつなぐ線(行をずらしたときだけ)
    final Paint tsunagi = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (int i = 0; i < r.narabi.length && i < h.tenY.length; i++) {
      final double gy = h.gyouTop[i] + h.gyouTakasa[i] / 2;
      if ((gy - h.tenY[i]).abs() > 1) {
        canvas.drawLine(Offset(_michiX + 6, h.tenY[i]), Offset(_mojiX - 3, gy), tsunagi);
      }
    }
    // 点(後ろの大学から描いて、前の大学を上に重ねる)
    for (int i = r.narabi.length - 1; i >= 0; i--) {
      if (i >= h.tenY.length) continue;
      final _IchiDaigaku x = r.narabi[i];
      final Offset c = Offset(_michiX, h.tenY[i]);
      if (x.op) {
        canvas.drawCircle(c, 5, Paint()..color = HENSUU.backgroundcolor);
        canvas.drawCircle(
          c,
          5,
          Paint()
            ..color = gakurenJibun ? _jibunIro : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      } else {
        final Color iro = x.jibun
            ? _jibunIro
            : (x.juni == 0 ? _ichiiIro : Colors.white70);
        canvas.drawCircle(c, 5.5, Paint()..color = iro);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MichiPainter old) =>
      old.r != r || old.h != h || old.gakurenJibun != gakurenJibun;
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
