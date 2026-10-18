// 駅伝の区間ごとのタイム分布(2.0.5)
// 結果画面(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝)の、ニュース記事のカードのすぐ下のカードから開く
// (2.0.6から、区間終了時点の位置関係と1枚にまとめたカード(Modal_ichiKankei.dart の KukanBunsekiCard)の
// 左半分。中身は kukanBunpuHanbun。2.0.5では KukanBunpuCard という1枚のカードだった)。
// ・1区が一番上、最終区が一番下。各行に、その区間を走った出場校の選手の区間タイムを、
//   区間1位からの差で点として描く(右の「1位」が区間1位、左ほど遅い)。
// ・横軸は「1kmあたりの差」(差を区間の距離で割ったもの。区間の長さが違っても比べられる)と、
//   「区間1位との差(秒)」を切り替えられる(覚えない。開くたびに1kmあたり)。
// ・帯は区間1位〜最下位、白い線は区間の中央値。区間1位は黄色、自分の大学の選手はオレンジの点。
// ・学連選抜(正月駅伝のオープン参加)の選手は白抜きの丸で出し、区間順位や中央値には数えない。
//   学連選抜の監督をした年(自分の大学が出ていない年)は、オレンジの白抜きにする。
// ・大きく遅れた選手で横軸が縮みすぎないよう、各区間で2番目に遅い選手の差のうち一番大きいものの
//   1.5倍までを描き、外は左端の三角で示す。
// ・正月駅伝は、5区と6区の間に復路の区切りを入れる。
// ・区間を押すと、その下に区間1位・2位との差・中央値・幅・自分の大学(学連選抜)の選手の成績を出す。
// ・カードには、1kmあたりの中央値の差が一番大きい区間(差が一番ついた区間)を抜き出して出し、
//   グラフの画面はその区間を開いた状態で開く。
// ・結果は記事と同じ EkidenKekka(kiji_kekka.dart)から作る。予備の配列は使わない。
// ・2.0.6から、レースの途中(区間が終わるたびの画面。mode 350)でも、1区から終わった区間までで
//   見られる(kukanBunpuYomu と ModalKukanTimeBunpuView に made(終わった区間の数)を渡す)。
//   途中のカードとグラフの画面は、差が一番ついた区間ではなく、終わったばかりの区間を出して開く。

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/kansuu/shushou.dart' show shushouShirushi;

/// グラフの左右の余白(端の点がはみ出さないように)
const double _haji = 14;

/// 区間1つ分の行のグラフの高さ
const double _gyouTakasa = 26;

/// 横軸に描く範囲(各区間で2番目に遅い選手の差のうち、一番大きいものの何倍までか)
const double _sotoBairitsu = 1.5;

/// 区間1位の点の色
const Color _ichiiIro = Colors.yellowAccent;

/// 差[v]の横の位置(右ほど区間1位に近い。[migi]は右端の差(0か、区間1位より速い学連選抜の差))
double _xOf(double v, double hidari, double migi, double w) =>
    _haji + (hidari - v) / (hidari - migi) * (w - _haji * 2);

/// 秒の差の目盛りの文字(「30秒」「1分」「1分30秒」)
String _byouMemoriMoji(int s) {
  if (s < 60) return '$s秒';
  if (s % 60 == 0) return '${s ~/ 60}分';
  return '${s ~/ 60}分${(s % 60).toString().padLeft(2, '0')}秒';
}

/// 選手の名前と学年(「山田(3年・主将)」。分からなければ空)
String _senshuMei(SenshuData? s) =>
    s == null ? '' : '${s.name}(${s.gakunen}年${shushouShirushi(s)})';

/// 区間1つ分
class _Kukan {
  /// 区間(0が1区)
  final int kk;

  /// 区間の距離(m)
  final double kyori;

  /// 出場校(区間タイムの速い順)
  final List<EkidenUnivKekka> jun;

  /// 区間タイム(速い順。jun と同じ並び)
  final List<double> t;

  /// 自分の大学の区間順位(0が1位。出ていなければnull)
  final int? jibunJuni;

  /// 学連選抜の選手の結果(正月駅伝で走ったときだけ)
  final GakurenKukanKekka? gakuren;

  /// 区間1位が区間新記録か
  final bool kukanShin;

  _Kukan(
    this.kk,
    this.kyori,
    this.jun,
    this.t,
    this.jibunJuni,
    this.gakuren,
    this.kukanShin,
  );

  /// 区間の距離(km。0のときに割り算で困らないよう、1mより短くはしない)
  double get km => math.max(kyori, 1.0) / 1000.0;

  /// 区間1位のタイム
  double get ichii => t.first;

  /// 区間の中央値(出場校の選手だけ)
  double get chuuouchi {
    final int n = t.length;
    final int h = n ~/ 2;
    return n.isOdd ? t[h] : (t[h - 1] + t[h]) / 2;
  }

  /// タイム[time]の区間1位からの差([km1]なら1kmあたりの秒、そうでなければ秒)
  double sa(double time, bool km1) => km1 ? (time - ichii) / km : time - ichii;
}

/// グラフのもとになる結果(グラフの画面と、結果画面のカードで使う)
class _KukanBunpu {
  final EkidenKekka e;

  /// 1区から順
  final List<_Kukan> kukan;

  /// 自分の大学の呼び方(出ていなければnull)
  final String? jibunMei;

  /// 学連選抜の監督をした年か(自分の大学の代わりに、学連選抜の選手をオレンジにする)
  final bool gakurenJibun;

  /// レースの途中か(2.0.6。終わったばかりの区間をカードに出して開く)
  final bool tochuu;

  _KukanBunpu._(this.e, this.kukan, this.jibunMei, this.gakurenJibun, this.tochuu);

  /// 大会[race]の結果から作る(駅伝でないときや、結果がなければnull)
  /// [made] を渡すと、レースの途中の、1区から[made]区までで作る(2.0.6)
  /// (思わぬデータで画面が止まらないよう、作れなければnull。記事と同じ)
  static _KukanBunpu? yomu(int race, {int? made}) {
    try {
      return _yomuHontai(race, made);
    } catch (e, st) {
      debugPrint('[区間ごとのタイム分布] 作れませんでした: $e\n$st');
      return null;
    }
  }

  static _KukanBunpu? _yomuHontai(int race, int? made) {
    // レースの途中は、実況(kiji_jikkyou.dart)と同じく結果の記事ではない形で読む
    final KijiKankyou? k = KijiKankyou.yomuRace(race, kekka: made == null);
    if (k == null || !k.ekiden) return null;
    if (made != null && made <= 0) return null;
    final EkidenKekka? e = EkidenKekka.tsukuru(k, made: made);
    if (e == null) return null;
    final EkidenUnivKekka? jibun = e.jibun;
    final UnivData? my = k.jibunUniv;
    final bool gakurenAri = race == 2 && gakurenKonnenAri(k.gh);
    final bool gakurenJibun =
        gakurenAri && jibun == null && my != null && gakurenKantokuChuu(k.kantoku, my);
    final List<double> kyoriIchiran = k.gh.kyori_taikai_kukangoto.length > race
        ? k.gh.kyori_taikai_kukangoto[race]
        : const <double>[];
    final List<_Kukan> kukan = [];
    for (int kk = 0; kk < e.ks; kk++) {
      final List<EkidenUnivKekka> jun = [
        for (final EkidenUnivKekka x in e.kukanJun[kk])
          if (x.kukanTime[kk] > 0 && x.kukanTime[kk] < TEISUU.DEFAULTTIME) x,
      ];
      if (jun.length < 2) continue;
      final List<double> t = [for (final EkidenUnivKekka x in jun) x.kukanTime[kk]];
      int? jibunJuni;
      for (int i = 0; i < jun.length; i++) {
        if (identical(jun[i], jibun)) jibunJuni = i;
      }
      // 区間新(記事と同じ決め方。区間1位の選手に区間新の印があり、従来の区間記録が残っているとき)
      final SenshuData? ichiiSenshu = jun[0].senshu[kk];
      final bool juraiAri =
          kk < 10 &&
          k.kantoku.yobiint4.length > kk &&
          k.kantoku.yobiint4[kk] > 0 &&
          k.kantoku.yobiint4[kk] < 360000;
      final bool kukanShin =
          ichiiSenshu != null &&
          ichiiSenshu.chokuzentaikai_zentaikukansinflag == 1 &&
          juraiAri;
      final GakurenKukanKekka? g = gakurenAri ? gakurenKukanKekka(k.gh, kk) : null;
      kukan.add(
        _Kukan(
          kk,
          kyoriIchiran.length > kk ? kyoriIchiran[kk] : 0.0,
          jun,
          t,
          jibunJuni,
          (g != null && g.kukanTime > 0 && g.kukanTime < TEISUU.DEFAULTTIME)
              ? g
              : null,
          kukanShin,
        ),
      );
    }
    if (kukan.isEmpty) return null;
    return _KukanBunpu._(
      e,
      kukan,
      jibun == null ? null : jibun.mei,
      gakurenJibun,
      made != null,
    );
  }

  /// 学連選抜の選手が走った区間があるか
  bool get gakurenAri => kukan.any((r) => r.gakuren != null);

  /// カードに出し、グラフの画面で最初に開いておく区間(並びの番号)
  /// (1kmあたりの中央値の差が一番大きい区間 = 差が一番ついた区間。
  /// レースの途中は、終わったばかりの区間。2.0.6)
  int get daihyou {
    if (tochuu) return kukan.length - 1;
    int best = 0;
    double bestSa = -1;
    for (int i = 0; i < kukan.length; i++) {
      final _Kukan r = kukan[i];
      final double s = r.sa(r.chuuouchi, true);
      if (s > bestSa) {
        bestSa = s;
        best = i;
      }
    }
    return best;
  }

  /// 横軸の範囲([km1]なら1kmあたり)
  /// hidari: 左端の差、migi: 右端の差(0か、区間1位より速い学連選抜の差)、soto: 左端の外に出る選手がいるか
  ({double hidari, double migi, bool soto}) haba(bool km1) {
    double maxZen = 0;
    double niban = 0;
    double migi = 0;
    for (final _Kukan r in kukan) {
      final int n = r.t.length;
      final double saigo = r.sa(r.t[n - 1], km1);
      final double ni = r.sa(r.t[n >= 3 ? n - 2 : n - 1], km1);
      if (saigo > maxZen) maxZen = saigo;
      if (ni > niban) niban = ni;
      final GakurenKukanKekka? g = r.gakuren;
      if (g != null) {
        final double gs = r.sa(g.kukanTime, km1);
        if (gs > maxZen) maxZen = gs;
        if (gs < migi) migi = gs;
      }
    }
    double hidari = math.min(maxZen, niban * _sotoBairitsu);
    if (hidari <= 0) hidari = maxZen > 0 ? maxZen : (km1 ? 1.0 : 10.0);
    final double yoyuu = (hidari - migi) * 0.04;
    return (
      hidari: hidari + yoyuu,
      migi: migi < 0 ? migi - yoyuu : 0.0,
      soto: maxZen > hidari + yoyuu,
    );
  }
}

/// 目盛りの差の値と文字(0は「1位」)
List<({double v, String moji})> _memoriIchiran(
  double kankaku,
  double hidari,
  bool km1,
) {
  final List<({double v, String moji})> l = [];
  for (double v = 0; v <= hidari; v += kankaku) {
    final int r = v.round();
    l.add((
      v: v,
      moji: r == 0 ? '1位' : '+${km1 ? '$r秒' : _byouMemoriMoji(r)}',
    ));
  }
  return l;
}

/// 目盛りの間隔の候補([km1]なら1kmあたりの秒、そうでなければ秒)
List<double> _kankakuKouho(bool km1) => km1
    ? const [1.0, 2.0, 5.0, 10.0, 20.0, 30.0, 60.0, 120.0]
    : const [10.0, 30.0, 60.0, 120.0, 300.0, 600.0, 1200.0, 1800.0];

/// 文字を出さない目盛りの縦線の間隔(カード用。線が詰まりすぎないようにする)
double _senKankaku(double w, double hidari, double migi, bool km1) {
  final double atari = (w - _haji * 2) / (hidari - migi);
  final List<double> kouho = _kankakuKouho(km1);
  for (final double s in kouho) {
    if (atari * s >= 12) return s;
  }
  return kouho.last;
}

/// 大学名の行に当たる、区間の見出しの行(グラフの画面の各行と、結果画面のカードで使う)
/// 「1区 21.3km」「区間1位 1時間02分11秒」「区間新」「港南大 区間5位」のかたまりに分け、
/// 入りきらないときは、かたまりの間で折り返す
Widget _midashiGyou(_KukanBunpu b, _Kukan r, {String? riyuu}) {
  const TextStyle s = TextStyle(color: HENSUU.textcolor, fontSize: 13);
  const TextStyle j = TextStyle(color: Colors.orangeAccent, fontSize: 13);
  final List<Widget> l = [
    Text('${r.kk + 1}区 ${kmMoji(r.kyori)}　', style: s),
    Text('区間1位 ${jikanMoji(r.ichii)}　', style: s),
    if (r.kukanShin)
      const Text('区間新　', style: TextStyle(color: _ichiiIro, fontSize: 13)),
  ];
  final int? jj = r.jibunJuni;
  final String? jibunMei = b.jibunMei;
  final GakurenKukanKekka? g = r.gakuren;
  if (jj != null && jibunMei != null) {
    l.add(Text('$jibunMei 区間${jj + 1}位　', style: j));
  } else if (b.gakurenJibun && g != null) {
    l.add(Text('学連選抜 区間${g.kukanJuni + 1}位相当　', style: j));
  }
  if (riyuu != null) {
    l.add(
      Text(riyuu, style: const TextStyle(color: Colors.white54, fontSize: 12)),
    );
  }
  return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: l);
}

/// グラフの画面を開く([made] はレースの途中のとき、終わった区間の数。2.0.6)
void _bunpuGamenHiraku(BuildContext context, int race, int? made) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
    barrierDismissible: true, // 背景タップで閉じられるようにする
    barrierLabel: '区間ごとのタイム分布', // アクセシビリティ用ラベル
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        ModalKukanTimeBunpuView(race: race, made: made),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

// カードの薄い文字の色(ニュース記事のカード(kiji_screen.dart の KijiLinkCard)とそろえる。
// カードの枠と線の色は、まとめたカード(Modal_ichiKankei.dart)にある)
const Color _cardUsui = Color(0xFF9E9E9E);

/// 区間ごとのタイム分布の結果(2.0.6。位置関係と1枚にまとめたカード(Modal_ichiKankei.dart の
/// KukanBunsekiCard)で、作れたかを確かめてから半分を描くために使う)
class KukanBunpuYomikomi {
  final _KukanBunpu _b;
  KukanBunpuYomikomi._(this._b);
}

/// 大会[race]の結果から作る([made] を渡すと、レースの途中の1区から[made]区まで。作れなければnull)
KukanBunpuYomikomi? kukanBunpuYomu(int race, {int? made}) {
  final _KukanBunpu? b = _KukanBunpu.yomu(race, made: made);
  return b == null ? null : KukanBunpuYomikomi._(b);
}

/// カードの見出し(アイコンと「区間ごとのタイム分布」)の幅
/// (まとめたカードで、左右に分けるか上下に分けるかを決めるのに使う)
double kukanBunpuMidashiHaba(TextScaler scaler) {
  final TextPainter tp = TextPainter(
    text: const TextSpan(text: '区間ごとのタイム分布', style: _cardMidashiStyle),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
  )..layout();
  final double w = tp.width;
  tp.dispose();
  return 16 + 4 + w;
}

const TextStyle _cardMidashiStyle = TextStyle(
  color: Colors.tealAccent,
  fontSize: 12.5,
  fontWeight: FontWeight.bold,
);

/// まとめたカードの、区間ごとのタイム分布の半分(2.0.6。2.0.5の結果画面のカード(KukanBunpuCard)の代わり)
/// ・カードに出す区間(結果画面では差が一番ついた区間、レースの途中は終わったばかりの区間)の
///   距離と自分の大学(学連選抜)の区間順位と、グラフの画面と同じ横軸(1kmあたり)の帯を出す
/// ・[haba] は中身の幅。高さを測れるよう(左右に分けるときに IntrinsicHeight を使う)、
///   LayoutBuilder と WidgetSpan は使わない
Widget kukanBunpuHanbun(
  BuildContext context,
  KukanBunpuYomikomi y, {
  required int race,
  int? made,
  required double haba,
}) {
  final _KukanBunpu b = y._b;
  final _Kukan r = b.kukan[b.daihyou];
  final ({double hidari, double migi, bool soto}) hb = b.haba(true);
  final double w = math.max(haba, 1);
  final List<double> sen = [
    for (final m in _memoriIchiran(_senKankaku(w, hb.hidari, hb.migi, true), hb.hidari, true))
      m.v,
  ];
  final int? jj = r.jibunJuni;
  final String? jibunMei = b.jibunMei;
  final GakurenKukanKekka? g = r.gakuren;
  String? jibunBun;
  if (jj != null && jibunMei != null) {
    jibunBun = '$jibunMei 区間${jj + 1}位';
  } else if (b.gakurenJibun && g != null) {
    jibunBun = '学連選抜 区間${g.kukanJuni + 1}位相当';
  }
  return InkWell(
    onTap: () => _bunpuGamenHiraku(context, race, made),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.candlestick_chart, color: Colors.tealAccent, size: 16),
              SizedBox(width: 4),
              Flexible(child: Text('区間ごとのタイム分布', style: _cardMidashiStyle)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${r.kk + 1}区 ${kmMoji(r.kyori)}',
            style: const TextStyle(color: HENSUU.textcolor, fontSize: 12.5),
          ),
          Text(
            b.tochuu ? '(終わったばかりの区間)' : '(差が一番ついた区間)',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (jibunBun != null)
            Text(
              jibunBun,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12.5),
            ),
          const SizedBox(height: 2),
          SizedBox(
            width: w,
            height: _gyouTakasa,
            child: CustomPaint(
              painter: _KukanPainter(r, true, hb.hidari, hb.migi, sen, b.gakurenJibun),
            ),
          ),
          const SizedBox(height: 4),
          const Text('グラフを見る ›', style: TextStyle(color: _cardUsui, fontSize: 12)),
        ],
      ),
    ),
  );
}

class ModalKukanTimeBunpuView extends StatefulWidget {
  /// 大会番号(0: 10月駅伝、1: 11月駅伝、2: 正月駅伝、5: カスタム駅伝)
  final int race;

  /// レースの途中のとき、終わった区間の数(結果画面からはnull。2.0.6)
  final int? made;
  const ModalKukanTimeBunpuView({super.key, required this.race, this.made});

  @override
  State<ModalKukanTimeBunpuView> createState() =>
      _ModalKukanTimeBunpuViewState();
}

class _ModalKukanTimeBunpuViewState extends State<ModalKukanTimeBunpuView> {
  _KukanBunpu? _b;

  /// 横軸が1kmあたりか(falseなら秒)
  bool _km1 = true;

  /// 中身を開いている区間(0が1区。-1はなし)
  int _hiraku = -1;

  @override
  void initState() {
    super.initState();
    final _KukanBunpu? b = _KukanBunpu.yomu(widget.race, made: widget.made);
    _b = b;
    // 結果画面のカードと同じ区間を開いておく
    if (b != null) _hiraku = b.kukan[b.daihyou].kk;
  }

  @override
  Widget build(BuildContext context) {
    final _KukanBunpu? b = _b;
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '区間ごとのタイム分布',
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
            : LayoutBuilder(
                builder: (context, constraints) =>
                    _buildHontai(context, b, constraints.maxWidth),
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

  Widget _buildHontai(BuildContext context, _KukanBunpu b, double w) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final ({double hidari, double migi, bool soto}) hb = b.haba(_km1);
    // 目盛りの間隔(文字を大きくしていても、目盛りの文字が重ならないようにする)
    final double atari = (w - _haji * 2) / (hb.hidari - hb.migi);
    final List<double> kouho = _kankakuKouho(_km1);
    List<({double v, String moji})> memori = _memoriIchiran(
      kouho.last,
      hb.hidari,
      _km1,
    );
    double mojiTakasa = 0;
    for (final double s in kouho) {
      final List<({double v, String moji})> l = _memoriIchiran(
        s,
        hb.hidari,
        _km1,
      );
      double haba = 0;
      for (final m in l) {
        final TextPainter tp = TextPainter(
          text: TextSpan(text: m.moji, style: const TextStyle(fontSize: 11)),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        haba = math.max(haba, tp.width);
        mojiTakasa = math.max(mojiTakasa, tp.height);
        tp.dispose();
      }
      if (atari * s >= haba + 8) {
        memori = l;
        break;
      }
    }
    final List<double> sen = [for (final m in memori) m.v];

    final int? ouro = b.e.ouroKukansuu;
    final List<Widget> gyou = [];
    for (final _Kukan r in b.kukan) {
      gyou.add(_buildGyou(b, r, hb, sen));
      // 正月駅伝は、5区と6区の間に復路の区切りを入れる
      if (ouro != null && r.kk == ouro - 1 && r.kk < b.kukan.last.kk) {
        gyou.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 1, color: Colors.white24),
                const Text(
                  'ここから復路',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }
    }
    return Column(
      children: [
        // 横軸(上に固定)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _km1 ? '← 区間1位から離れる(1kmあたり)' : '← 区間1位から離れる(秒)',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        ),
        SizedBox(
          width: w,
          height: mojiTakasa + 6,
          child: CustomPaint(
            painter: _JikuPainter(hb.hidari, hb.migi, memori, scaler),
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [_buildMikata(b, hb.soto), ...gyou],
          ),
        ),
      ],
    );
  }

  /// 見方・凡例・横軸の切り替え(一覧の一番上。スクロールで隠れる)
  Widget _buildMikata(_KukanBunpu b, bool soto) {
    const TextStyle setsumei = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      height: 1.4,
    );
    Widget hanrei(_HanreiPainter p, String mei) => Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: CustomPaint(size: const Size(20, 16), painter: p),
          ),
          TextSpan(text: ' $mei'),
        ],
      ),
      style: setsumei,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('・右の「1位」が区間1位で、左ほど区間1位から離れています。', style: setsumei),
          const Text('・1kmあたりの差は、差を区間の距離で割ったものです。区間の長さが違っても比べられます。', style: setsumei),
          const Text('・帯が長く、中央値の線が左にある区間ほど、差がついた区間です。', style: setsumei),
          const Text('・区間を押すと、区間1位や自分の大学の選手の成績が出ます。', style: setsumei),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              hanrei(const _HanreiPainter(0, Colors.tealAccent), '区間1位〜最下位'),
              hanrei(const _HanreiPainter(1, _ichiiIro), '区間1位'),
              if (b.jibunMei != null)
                hanrei(const _HanreiPainter(1, Colors.orangeAccent), '自分の大学'),
              hanrei(const _HanreiPainter(3, Colors.white), '中央値'),
              if (b.gakurenAri)
                hanrei(
                  _HanreiPainter(
                    2,
                    b.gakurenJibun ? Colors.orangeAccent : Colors.white,
                  ),
                  '学連選抜(OP)',
                ),
              if (soto)
                hanrei(const _HanreiPainter(4, Colors.grey), '横軸の外(大きく遅れた選手)'),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final bool v in const [true, false])
                ChoiceChip(
                  label: Text(v ? '1kmあたりの差' : '区間1位との差(秒)'),
                  selected: _km1 == v,
                  onSelected: (selected) {
                    if (selected) setState(() => _km1 = v);
                  },
                  selectedColor: Colors.orange.shade700,
                  backgroundColor: Colors.grey.shade800,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 区間1つ分の行(見出し・グラフ・押したときの中身)
  Widget _buildGyou(
    _KukanBunpu b,
    _Kukan r,
    ({double hidari, double migi, bool soto}) hb,
    List<double> sen,
  ) {
    final bool hiraita = _hiraku == r.kk;
    return InkWell(
      onTap: () => setState(() => _hiraku = hiraita ? -1 : r.kk),
      child: Container(
        color: hiraita ? Colors.white.withOpacity(0.07) : null,
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _midashiGyou(b, r),
            ),
            SizedBox(
              width: double.infinity,
              height: _gyouTakasa,
              child: CustomPaint(
                painter: _KukanPainter(
                  r,
                  _km1,
                  hb.hidari,
                  hb.migi,
                  sen,
                  b.gakurenJibun,
                ),
              ),
            ),
            if (hiraita) _buildNakami(r),
          ],
        ),
      ),
    );
  }

  /// 押した区間の中身
  Widget _buildNakami(_Kukan r) {
    const TextStyle moji = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      height: 1.4,
    );
    String km1Moji(double sa) => '1kmあたり${(sa / r.km).toStringAsFixed(1)}秒';
    final List<String> l = [];
    final EkidenUnivKekka ichi = r.jun[0];
    l.add(
      '・区間1位 ${ichi.mei} ${_senshuMei(ichi.senshu[r.kk])} ${jikanMoji(r.ichii)}${r.kukanShin ? '(区間新)' : ''}',
    );
    l.add(
      '・区間2位(${r.jun[1].mei})との差 ${saMoji(saByou(r.t[1], r.ichii))}(${km1Moji(r.t[1] - r.ichii)})',
    );
    l.add(
      '・区間の中央値 ${jikanMoji(r.chuuouchi)}(区間1位から+${saMoji(saByou(r.chuuouchi, r.ichii))})',
    );
    l.add(
      '・区間1位〜区間最下位の幅 ${saMoji(saByou(r.t.last, r.ichii))}(${km1Moji(r.t.last - r.ichii)})',
    );
    final int? jj = r.jibunJuni;
    if (jj != null) {
      final EkidenUnivKekka x = r.jun[jj];
      final String sa = jj == 0
          ? ''
          : '(区間1位から+${saMoji(saByou(r.t[jj], r.ichii))})';
      l.add(
        '・${x.mei} ${_senshuMei(x.senshu[r.kk])} 区間${jj + 1}位 ${jikanMoji(r.t[jj])}$sa',
      );
    }
    final GakurenKukanKekka? g = r.gakuren;
    if (g != null) {
      final int gs = saByou(g.kukanTime, r.ichii);
      l.add(
        '・学連選抜(OP) ${g.senshu.name}(${daigakuMeiMoji(g.shozoku)}・${g.senshu.gakunen}年) 区間${g.kukanJuni + 1}位相当 ${jikanMoji(g.kukanTime)}(区間1位から${gs < 0 ? '-' : '+'}${saMoji(gs)})',
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final String s in l) Text(s, style: moji)],
      ),
    );
  }
}

/// 横軸の目盛り
class _JikuPainter extends CustomPainter {
  final double hidari;
  final double migi;
  final List<({double v, String moji})> memori;
  final TextScaler scaler;

  _JikuPainter(this.hidari, this.migi, this.memori, this.scaler);

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in memori) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: m.moji,
          style: TextStyle(
            color: m.v == 0 ? _ichiiIro : Colors.white60,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      double lx = _xOf(m.v, hidari, migi, size.width) - tp.width / 2;
      lx = math.max(0.0, math.min(lx, size.width - tp.width));
      tp.paint(canvas, Offset(lx, 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _JikuPainter old) =>
      old.hidari != hidari ||
      old.migi != migi ||
      old.memori.length != memori.length ||
      old.scaler != scaler;
}

/// 区間1つ分のグラフ
class _KukanPainter extends CustomPainter {
  final _Kukan r;
  final bool km1;
  final double hidari;
  final double migi;

  /// 目盛りの縦線を引く差
  final List<double> sen;

  /// 学連選抜の監督をした年か(学連選抜の選手をオレンジにする)
  final bool gakurenJibun;

  _KukanPainter(
    this.r,
    this.km1,
    this.hidari,
    this.migi,
    this.sen,
    this.gakurenJibun,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double y = size.height / 2;
    double x(double v) => _xOf(math.min(v, hidari), hidari, migi, w);

    // 目盛りの縦線(区間1位の線は少し濃く)
    for (final double m in sen) {
      canvas.drawLine(
        Offset(x(m), 0),
        Offset(x(m), size.height),
        Paint()
          ..color = Colors.white.withOpacity(m == 0 ? 0.25 : 0.12)
          ..strokeWidth = 1,
      );
    }

    // 区間1位〜最下位の帯
    final double saigo = r.sa(r.t.last, km1);
    canvas.drawRRect(
      RRect.fromLTRBR(
        x(saigo) - 3,
        y - 5,
        x(0) + 3,
        y + 5,
        const Radius.circular(4),
      ),
      Paint()..color = Colors.tealAccent.withOpacity(0.22),
    );

    // 出場校の選手(区間1位と自分の大学はあとで重ねる)
    final Paint ten = Paint()..color = Colors.grey.shade400;
    for (int i = 1; i < r.t.length; i++) {
      if (i == r.jibunJuni) continue;
      _ten(canvas, r.sa(r.t[i], km1), y, w, ten, 2.6);
    }

    // 中央値(縦の線)
    final double cx = x(r.sa(r.chuuouchi, km1));
    canvas.drawLine(
      Offset(cx, y - 8),
      Offset(cx, y + 8),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // 学連選抜(白抜き)
    final GakurenKukanKekka? g = r.gakuren;
    if (g != null) {
      _ten(
        canvas,
        r.sa(g.kukanTime, km1),
        y,
        w,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = gakurenJibun ? Colors.orangeAccent : Colors.white,
        3.6,
      );
    }

    // 区間1位
    canvas.drawCircle(Offset(x(0), y), 4, Paint()..color = _ichiiIro);

    // 自分の大学(区間1位なら黄色の輪を付ける)
    final int? jj = r.jibunJuni;
    if (jj != null) {
      final double v = r.sa(r.t[jj], km1);
      if (v <= hidari) {
        canvas.drawCircle(
          Offset(x(v), y),
          4.5,
          Paint()..color = Colors.orangeAccent,
        );
        canvas.drawCircle(
          Offset(x(v), y),
          5.3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = jj == 0 ? _ichiiIro : HENSUU.backgroundcolor,
        );
      } else {
        _ten(canvas, v, y, w, Paint()..color = Colors.orangeAccent, 4.5);
      }
    }
  }

  /// 差[v]の点(横軸の外なら、左端の三角)
  void _ten(Canvas canvas, double v, double y, double w, Paint p, double hankei) {
    if (v > hidari) {
      final Path sankaku = Path()
        ..moveTo(_haji - 10, y)
        ..lineTo(_haji - 3, y - 4.5)
        ..lineTo(_haji - 3, y + 4.5)
        ..close();
      canvas.drawPath(sankaku, p);
    } else {
      canvas.drawCircle(
        Offset(_xOf(v, hidari, migi, w), y),
        hankei,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KukanPainter old) =>
      !identical(old.r, r) ||
      old.km1 != km1 ||
      old.hidari != hidari ||
      old.migi != migi ||
      old.sen.length != sen.length ||
      old.gakurenJibun != gakurenJibun;
}

/// 凡例の印(0=帯・1=点・2=白抜きの丸・3=中央値の線・4=左端の三角)
class _HanreiPainter extends CustomPainter {
  final int shurui;
  final Color iro;

  const _HanreiPainter(this.shurui, this.iro);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset o = Offset(size.width / 2, size.height / 2);
    switch (shurui) {
      case 0:
        canvas.drawRRect(
          RRect.fromLTRBR(1, o.dy - 5, size.width - 1, o.dy + 5, const Radius.circular(4)),
          Paint()..color = iro.withOpacity(0.3),
        );
        break;
      case 1:
        canvas.drawCircle(o, 4, Paint()..color = iro);
        break;
      case 2:
        canvas.drawCircle(
          o,
          3.6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = iro,
        );
        break;
      case 3:
        canvas.drawLine(
          Offset(o.dx, o.dy - 7),
          Offset(o.dx, o.dy + 7),
          Paint()
            ..color = iro
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
        break;
      default:
        final Path sankaku = Path()
          ..moveTo(o.dx - 5, o.dy)
          ..lineTo(o.dx + 2, o.dy - 4.5)
          ..lineTo(o.dx + 2, o.dy + 4.5)
          ..close();
        canvas.drawPath(sankaku, Paint()..color = iro);
    }
  }

  @override
  bool shouldRepaint(covariant _HanreiPainter old) =>
      old.shurui != shurui || old.iro != iro;
}
