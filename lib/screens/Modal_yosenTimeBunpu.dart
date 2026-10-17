// 正月駅伝予選のチーム内のタイム分布(2.0.5)
// 結果画面の「チーム内のタイム分布」のカード(YosenBunpuCard。ニュース記事のカードの下)から開く。
// カードには、自分の大学(出ていなければ11位の大学)の帯を、グラフの画面と同じ横軸で抜き出して出す。
// ・大学ごとに、合計に入った1〜10番手のタイムの範囲を横向きの帯で描き、
//   10人の点・平均(合計÷10)・中央値・合計に入らなかった11・12番手(白抜き)を重ねる。
// ・右ほど速いタイム。合計は上位10人の合計なので、平均の並びがそのまま順位の並びになる。
// ・10位の大学の平均に縦の点線を引き、順位の並びでは10位と11位の間に区切りを入れる。
// ・大学を押すと、その下に選手ごとのタイムと、10番手が中央値で走っていたときの順位相当を出す。
// ・結果は記事と同じ YosenKekka(kiji_yosen.dart)から作る。
// ・並びの切り替えは覚えない(開くたびに順位の並び。予備の配列は使わない)。

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_yosen.dart';
import 'package:ekiden/kansuu/shushou.dart' show shushouShirushi;

/// 正月駅伝予選の大会番号
const int _yosenRace = 4;

/// グラフの左右の余白(帯の端の点がはみ出さないように)
const double _haji = 14;

/// 大学1校分の行のグラフの高さ
const double _gyouTakasa = 26;

/// 合計に入らなかった選手を、10番手の一番遅いタイムから何秒遅いところまで描くか
/// (大きく遅れた選手で横軸が縮みすぎないように。外は左端の三角で示す)
const double _sotoHaba = 180;

/// 平均と中央値の差を言葉にする境目(秒)
const double _heikinChuuouSaKyoukai = 5;

/// 時刻[t]の横の位置(右ほど速い)
double _xOf(double t, double hayai, double osoi, double w) =>
    _haji + (osoi - t) / (osoi - hayai) * (w - _haji * 2);

/// グラフの1校分
class _Kou {
  final YosenUnivKekka x;

  /// 走った選手のタイム(速い順。x.senshu と同じ並び)
  final List<double> t;

  /// 合計に入った人数(ふつうは10人)
  final int keisan;

  /// 合計に入った選手の平均(合計÷人数)
  final double heikin;

  /// 合計に入った選手の中央値
  final double chuuouchi;

  /// 本選に出場できたか
  final bool tsuuka;

  /// 自分の大学か
  final bool jibun;

  _Kou(
    this.x,
    this.t,
    this.keisan,
    this.heikin,
    this.chuuouchi,
    this.tsuuka,
    this.jibun,
  );

  /// 1番手のタイム
  double get ichiban => t[0];

  /// 合計に入った最後の選手(10番手)のタイム
  double get saigo => t[keisan - 1];

  /// 1番手と10番手の差
  double get haba => saigo - ichiban;

  /// 順位(0が1位)
  int get juni => x.juni;

  /// 帯と点の色
  Color get iro {
    if (jibun) return Colors.orangeAccent;
    if (tsuuka) return Colors.tealAccent;
    return Colors.grey;
  }
}

/// グラフのもとになる結果(グラフの画面と、結果画面のカードで使う)
class _Bunpu {
  final YosenKekka e;

  /// 順位の順
  final List<_Kou> kou;

  /// 10位の大学の平均(通過ラインの争いがなければnull)
  final double? senHeikin;

  /// 横軸の右端(速い側)と左端(遅い側)のタイム
  final double hayai;
  final double osoi;

  _Bunpu._(this.e, this.kou, this.senHeikin, this.hayai, this.osoi);

  /// 正月駅伝予選の結果から作る(結果がなければnull)
  static _Bunpu? yomu() {
    final KijiKankyou? k = KijiKankyou.yomuRace(_yosenRace, kekka: true);
    final YosenKekka? e = k == null ? null : YosenKekka.tsukuru(k);
    if (e == null) return null;
    final YosenUnivKekka? jibun = e.jibun;
    final List<_Kou> kou = [];
    for (final YosenUnivKekka x in e.jun) {
      final int keisan = math.min(e.keisanNinzuu, x.senshu.length);
      if (keisan <= 0) continue;
      final List<double> t = [for (final YosenSenshuKekka y in x.senshu) y.time];
      double goukei = 0;
      for (int i = 0; i < keisan; i++) {
        goukei += t[i];
      }
      final int naka = keisan ~/ 2;
      final double chuuouchi = keisan.isOdd
          ? t[naka]
          : (t[naka - 1] + t[naka]) / 2;
      kou.add(
        _Kou(
          x,
          t,
          keisan,
          goukei / keisan,
          chuuouchi,
          e.tsuuka(x),
          identical(x, jibun),
        ),
      );
    }
    if (kou.isEmpty) return null;
    double? senHeikin;
    if (e.borderAri) {
      final YosenUnivKekka sen = e.jun[e.tsuukaSuu - 1];
      for (final _Kou kk in kou) {
        if (identical(kk.x, sen)) senHeikin = kk.heikin;
      }
    }
    // 横軸の範囲。合計に入った選手は必ず入れる。
    // 合計に入らなかった選手は、10番手の一番遅いタイムから _sotoHaba 秒までにする
    final double hayai = kou.map((kk) => kk.ichiban).reduce(math.min);
    final double osoi10 = kou.map((kk) => kk.saigo).reduce(math.max);
    final double osoiZen = kou.map((kk) => kk.t.last).reduce(math.max);
    final double osoi = math.min(osoiZen, osoi10 + _sotoHaba);
    final double haba = math.max(osoi - hayai, 60.0);
    final double yoyuu = haba * 0.04;
    return _Bunpu._(
      e,
      kou,
      senHeikin,
      hayai - yoyuu,
      hayai + haba + yoyuu,
    );
  }

  /// 結果画面のカードに出し、グラフの画面で最初に開いておく大学
  /// (自分の大学が出ていれば自分の大学。出ていなければ次点の11位の大学。
  ///  全校が出場できて11位がないときは最下位の大学)
  _Kou get daihyou {
    for (final _Kou kk in kou) {
      if (kk.jibun) return kk;
    }
    if (e.borderAri) {
      for (final _Kou kk in kou) {
        if (kk.juni >= e.tsuukaSuu) return kk;
      }
    }
    return kou.last;
  }
}

/// 目盛りの縦線の間隔(秒。文字を出さないカード用。線が詰まりすぎないようにする)
double _senKankaku(double w, double hayai, double osoi) {
  final double byouAtari = (w - _haji * 2) / (osoi - hayai);
  for (final double s in const [60.0, 120.0, 300.0]) {
    if (byouAtari * s >= 12) return s;
  }
  return 600;
}

/// 目盛りのタイムの一覧
List<double> _memoriIchiran(double kankaku, double hayai, double osoi) {
  final List<double> memori = [];
  for (double m = kankaku * (hayai / kankaku).ceil(); m <= osoi; m += kankaku) {
    memori.add(m);
  }
  return memori;
}

/// グラフの画面を開く
void _bunpuGamenHiraku(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
    barrierDismissible: true, // 背景タップで閉じられるようにする
    barrierLabel: 'チーム内のタイム分布', // アクセシビリティ用ラベル
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const ModalYosenTimeBunpuView(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

// 結果画面のカードの色(ニュース記事のカード(kiji_screen.dart の KijiLinkCard)とそろえる)
const Color _cardWaku = Color(0xFF161616);
const Color _cardSen = Color(0xFF333333);
const Color _cardUsui = Color(0xFF9E9E9E);

/// 結果画面に置くカード(2.0.5)
/// ・ほかのリンクに紛れないよう、ニュース記事のカードと同じ形にして、
///   自分の大学(出ていなければ11位の大学)の帯を、グラフの画面と同じ横軸で抜き出して出す
/// ・結果は画面を出したあとで1回だけ作る(画面が出るのを遅らせない)。
///   大会が変わったら作り直すよう、置く側で key を付ける
/// ・結果がなければ出さない
class YosenBunpuCard extends StatefulWidget {
  const YosenBunpuCard({super.key});

  @override
  State<YosenBunpuCard> createState() => _YosenBunpuCardState();
}

class _YosenBunpuCardState extends State<YosenBunpuCard> {
  _Bunpu? _b;

  /// 結果を作ったか
  bool _tsukutta = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final _Bunpu? b = _Bunpu.yomu();
      if (!mounted) return;
      setState(() {
        _b = b;
        _tsukutta = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final _Bunpu? b = _b;
    if (_tsukutta && b == null) return const SizedBox.shrink();
    final _Kou? kk = b?.daihyou;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: _cardWaku,
          child: InkWell(
            onTap: () => _bunpuGamenHiraku(context),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.tealAccent, width: 5),
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
                          child: Icon(
                            Icons.candlestick_chart,
                            color: Colors.tealAccent,
                            size: 16,
                          ),
                        ),
                        TextSpan(text: ' チーム内のタイム分布'),
                      ],
                    ),
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (b != null && kk != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${kk.juni + 1}位 ${kk.x.mei}　${TimeDate.timeToJikanFunByouString(kk.x.time)}',
                      style: TextStyle(
                        color: kk.jibun ? Colors.orangeAccent : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double w = constraints.maxWidth;
                        final List<double> memori = _memoriIchiran(
                          _senKankaku(w, b.hayai, b.osoi),
                          b.hayai,
                          b.osoi,
                        );
                        return SizedBox(
                          width: w,
                          height: _gyouTakasa,
                          child: CustomPaint(
                            painter: _GyouPainter(
                              kk,
                              b.hayai,
                              b.osoi,
                              memori,
                              b.senHeikin,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'グラフを見る ›',
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

/// 並べ方(0=順位・1=幅が小さい順・2=1番手が速い順・3=10番手が速い順)
const List<String> _narabiMei = ['順位', '幅が小さい順', '1番手が速い順', '10番手が速い順'];

class ModalYosenTimeBunpuView extends StatefulWidget {
  const ModalYosenTimeBunpuView({super.key});

  @override
  State<ModalYosenTimeBunpuView> createState() =>
      _ModalYosenTimeBunpuViewState();
}

class _ModalYosenTimeBunpuViewState extends State<ModalYosenTimeBunpuView> {
  YosenKekka? _e;

  /// 順位の順
  final List<_Kou> _kou = [];

  /// 10位の大学の平均(通過ラインの争いがなければnull)
  double? _senHeikin;

  /// 横軸の右端(速い側)と左端(遅い側)のタイム
  double _hayai = 0;
  double _osoi = 1;

  /// 並べ方
  int _narabi = 0;

  /// 中身を開いている大学の id(-1 はなし)
  int _hiraku = -1;

  @override
  void initState() {
    super.initState();
    _yomu();
  }

  void _yomu() {
    final _Bunpu? b = _Bunpu.yomu();
    if (b == null) return;
    _e = b.e;
    _kou.addAll(b.kou);
    _senHeikin = b.senHeikin;
    _hayai = b.hayai;
    _osoi = b.osoi;
    // 結果画面のカードと同じ大学を開いておく
    _hiraku = b.daihyou.x.u.id;
  }

  /// 並べ替えた大学
  List<_Kou> _narabeta() {
    final List<_Kou> l = List<_Kou>.of(_kou);
    int juniDe(_Kou a, _Kou b) => a.juni.compareTo(b.juni);
    switch (_narabi) {
      case 1:
        l.sort((a, b) {
          final int c = a.haba.compareTo(b.haba);
          return c != 0 ? c : juniDe(a, b);
        });
        break;
      case 2:
        l.sort((a, b) {
          final int c = a.ichiban.compareTo(b.ichiban);
          return c != 0 ? c : juniDe(a, b);
        });
        break;
      case 3:
        l.sort((a, b) {
          final int c = a.saigo.compareTo(b.saigo);
          return c != 0 ? c : juniDe(a, b);
        });
        break;
      default:
        l.sort(juniDe);
    }
    return l;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          'チーム内のタイム分布',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: (_e == null || _kou.isEmpty)
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '正月駅伝予選の結果がありません。',
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) =>
                    _buildHontai(context, constraints.maxWidth),
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

  Widget _buildHontai(BuildContext context, double w) {
    final YosenKekka e = _e!;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    // 目盛りの間隔(文字を大きくしていても、目盛りの文字が重ならないようにする)
    final TextPainter mihon = TextPainter(
      text: const TextSpan(text: '888分', style: TextStyle(fontSize: 11)),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final double mihonHaba = mihon.width;
    final double mihonTakasa = mihon.height;
    mihon.dispose();
    final double byouAtari = (w - _haji * 2) / (_osoi - _hayai);
    double kankaku = 600;
    for (final double s in const [60.0, 120.0, 300.0]) {
      if (byouAtari * s >= mihonHaba + 10) {
        kankaku = s;
        break;
      }
    }
    final List<double> memori = [];
    for (
      double m = kankaku * (_hayai / kankaku).ceil();
      m <= _osoi;
      m += kankaku
    ) {
      memori.add(m);
    }
    final List<_Kou> narabi = _narabeta();
    final List<Widget> gyou = [];
    for (int i = 0; i < narabi.length; i++) {
      gyou.add(_buildGyou(narabi[i], memori, e));
      // 順位の並びでは、本選に出場できた大学とできなかった大学の間に区切りを入れる
      if (_narabi == 0 && e.borderAri && narabi[i].juni == e.tsuukaSuu - 1) {
        gyou.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ここまでの${e.tsuukaSuu}校が正月駅伝に出場',
                  style: const TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 12,
                  ),
                ),
                Container(
                  height: 1,
                  color: Colors.tealAccent.withOpacity(0.6),
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
          child: Row(
            children: const [
              Text(
                '← 遅い',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Spacer(),
              Text(
                '速い →',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(
          width: w,
          height: mihonTakasa + 6,
          child: CustomPaint(
            painter: _JikuPainter(_hayai, _osoi, memori, scaler),
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _buildMikata(e),
              ...gyou,
            ],
          ),
        ),
      ],
    );
  }

  /// 見方・凡例・並べ替え(一覧の一番上。スクロールで隠れる)
  Widget _buildMikata(YosenKekka e) {
    const TextStyle setsumei = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      height: 1.4,
    );
    final bool jibunAri = _kou.any((kk) => kk.jibun);
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
          const Text('・右ほど速いタイムです。帯は、合計に入った1〜10番手のタイムの範囲です。', style: setsumei),
          const Text('・平均(合計÷10)の線の並びが、そのまま順位の並びです。', style: setsumei),
          const Text('・平均の線が中央値より左なら、遅い選手に引っ張られた形です。右なら、速い選手が引き上げた形です。', style: setsumei),
          const Text('・大学を押すと、選手ごとのタイムなどが出ます。', style: setsumei),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (e.borderAri) ...[
                hanrei(const _HanreiPainter(0, Colors.tealAccent), '出場'),
                hanrei(const _HanreiPainter(0, Colors.grey), '出場できず'),
              ] else
                hanrei(const _HanreiPainter(0, Colors.tealAccent), '出場'),
              if (jibunAri)
                hanrei(const _HanreiPainter(0, Colors.orangeAccent), '自分の大学'),
              hanrei(const _HanreiPainter(1, Colors.white), '平均'),
              hanrei(const _HanreiPainter(2, Colors.white), '中央値'),
              hanrei(const _HanreiPainter(3, Colors.grey), '11・12番手(合計外)'),
              if (_senHeikin != null)
                hanrei(
                  const _HanreiPainter(4, Colors.tealAccent),
                  '${e.tsuukaSuu}位の大学の平均',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (int i = 0; i < _narabiMei.length; i++)
                ChoiceChip(
                  label: Text(_narabiMei[i]),
                  selected: _narabi == i,
                  onSelected: (selected) {
                    if (selected) setState(() => _narabi = i);
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

  /// 大学1校分の行(名前・グラフ・押したときの中身)
  Widget _buildGyou(_Kou kk, List<double> memori, YosenKekka e) {
    final bool hiraita = _hiraku == kk.x.u.id;
    return InkWell(
      onTap: () => setState(() => _hiraku = hiraita ? -1 : kk.x.u.id),
      child: Container(
        color: hiraita ? Colors.white.withOpacity(0.07) : null,
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${kk.juni + 1}位 ${kk.x.mei}　${TimeDate.timeToJikanFunByouString(kk.x.time)}',
                style: TextStyle(
                  color: kk.jibun ? Colors.orangeAccent : HENSUU.textcolor,
                  fontSize: 13,
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: _gyouTakasa,
              child: CustomPaint(
                painter: _GyouPainter(kk, _hayai, _osoi, memori, _senHeikin),
              ),
            ),
            if (hiraita) _buildNakami(kk, e),
          ],
        ),
      ),
    );
  }

  /// 押した大学の中身
  Widget _buildNakami(_Kou kk, YosenKekka e) {
    const TextStyle moji = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      height: 1.4,
    );
    final List<String> l = [];
    l.add('・合計 ${TimeDate.timeToJikanFunByouString(kk.x.time)}(上位${kk.keisan}人)');
    l.add(
      '・${kk.keisan}人の平均 ${TimeDate.timeToFunByouString(kk.heikin)}　中央値 ${TimeDate.timeToFunByouString(kk.chuuouchi)}',
    );
    final double sa = kk.heikin - kk.chuuouchi;
    if (sa >= _heikinChuuouSaKyoukai) {
      l.add('　・平均が中央値より${saMoji(sa.round())}遅く、遅い選手に引っ張られた形です。');
    } else if (sa <= -_heikinChuuouSaKyoukai) {
      l.add('　・平均が中央値より${saMoji(sa.round())}速く、速い選手が引き上げた形です。');
    }
    l.add('・1〜${kk.keisan}番手の幅 ${saMoji(kk.haba.round())}');
    if (e.borderAri) {
      if (kk.tsuuka) {
        final int sa2 = saByou(e.jun[e.tsuukaSuu].time, kk.x.time);
        l.add('・次点の${e.tsuukaSuu + 1}位とは${kinsaMoji(sa2)}');
      } else {
        final int sa2 = saByou(kk.x.time, e.jun[e.tsuukaSuu - 1].time);
        l.add('・${e.tsuukaSuu}位とは${kinsaMoji(sa2)}');
      }
    }
    // 最後の1人が中央値で走っていたら(置き換えた見積もり。11番手は10番手より遅いので、合計に入る顔ぶれは変わらない)
    if (kk.keisan >= 2 && kk.saigo > kk.chuuouchi) {
      final double moshi = kk.x.time - (kk.saigo - kk.chuuouchi);
      int juni = 1;
      for (final _Kou o in _kou) {
        if (!identical(o, kk) && o.x.time < moshi) juni++;
      }
      l.add(
        '・${kk.keisan}番手が中央値で走っていたら、合計 ${TimeDate.timeToJikanFunByouString(moshi)}($juni位相当)',
      );
    }
    final List<Widget> senshu = [];
    for (int i = 0; i < kk.x.senshu.length; i++) {
      final YosenSenshuKekka y = kk.x.senshu[i];
      final String soto = i >= kk.keisan ? '・合計外' : '';
      senshu.add(
        Text(
          '${i + 1}番手 ${y.s.name}(${y.s.gakunen}年${shushouShirushi(y.s)}) ${TimeDate.timeToFunByouString(y.time)}(全体${y.juni + 1}位$soto)',
          style: TextStyle(
            color: i >= kk.keisan ? Colors.white54 : Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final String s in l) Text(s, style: moji),
          const SizedBox(height: 4),
          ...senshu,
        ],
      ),
    );
  }
}

/// 横軸の目盛り(分)
class _JikuPainter extends CustomPainter {
  final double hayai;
  final double osoi;
  final List<double> memori;
  final TextScaler scaler;

  _JikuPainter(this.hayai, this.osoi, this.memori, this.scaler);

  @override
  void paint(Canvas canvas, Size size) {
    for (final double m in memori) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: '${(m / 60).round()}分',
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      double lx = _xOf(m, hayai, osoi, size.width) - tp.width / 2;
      lx = math.max(0.0, math.min(lx, size.width - tp.width));
      tp.paint(canvas, Offset(lx, 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _JikuPainter old) =>
      old.hayai != hayai ||
      old.osoi != osoi ||
      old.memori.length != memori.length ||
      old.scaler != scaler;
}

/// 大学1校分のグラフ
class _GyouPainter extends CustomPainter {
  final _Kou kk;
  final double hayai;
  final double osoi;
  final List<double> memori;

  /// 10位の大学の平均(なければnull)
  final double? senHeikin;

  _GyouPainter(this.kk, this.hayai, this.osoi, this.memori, this.senHeikin);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double y = size.height / 2;
    double x(double t) => _xOf(t, hayai, osoi, w);

    // 目盛りの縦線
    final Paint sen = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 1;
    for (final double m in memori) {
      final double gx = x(m);
      canvas.drawLine(Offset(gx, 0), Offset(gx, size.height), sen);
    }

    // 10位の大学の平均(点線)
    final double? sh = senHeikin;
    if (sh != null) {
      final double lx = x(sh);
      final Paint p = Paint()
        ..color = Colors.tealAccent.withOpacity(0.7)
        ..strokeWidth = 1.5;
      for (double yy = 0; yy < size.height; yy += 6) {
        canvas.drawLine(
          Offset(lx, yy),
          Offset(lx, math.min(yy + 3, size.height)),
          p,
        );
      }
    }

    // 1〜10番手の帯
    final Color c = kk.iro;
    canvas.drawRRect(
      RRect.fromLTRBR(
        x(kk.saigo) - 4,
        y - 5,
        x(kk.ichiban) + 4,
        y + 5,
        const Radius.circular(4),
      ),
      Paint()..color = c.withOpacity(kk.jibun ? 0.45 : 0.32),
    );

    // 合計に入らなかった選手(白抜き。横軸の外は左端の三角)
    final Paint nuki = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = Colors.grey.shade500;
    for (int i = kk.keisan; i < kk.t.length; i++) {
      final double t = kk.t[i];
      if (t > osoi) {
        final Path sankaku = Path()
          ..moveTo(_haji - 9, y)
          ..lineTo(_haji - 3, y - 4)
          ..lineTo(_haji - 3, y + 4)
          ..close();
        canvas.drawPath(sankaku, nuki);
      } else {
        canvas.drawCircle(Offset(x(t), y), 3.2, nuki);
      }
    }

    // 合計に入った選手
    final Paint ten = Paint()..color = c;
    for (int i = 0; i < kk.keisan; i++) {
      canvas.drawCircle(Offset(x(kk.t[i]), y), 3.2, ten);
    }

    // 中央値(ひし形)
    _hishigata(canvas, Offset(x(kk.chuuouchi), y));

    // 平均(縦の線)
    final double ax = x(kk.heikin);
    canvas.drawLine(
      Offset(ax, y - 9),
      Offset(ax, y + 9),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GyouPainter old) =>
      !identical(old.kk, kk) ||
      old.hayai != hayai ||
      old.osoi != osoi ||
      old.memori.length != memori.length ||
      old.senHeikin != senHeikin;
}

/// 中央値のひし形
void _hishigata(Canvas canvas, Offset o) {
  final Path p = Path()
    ..moveTo(o.dx, o.dy - 5.5)
    ..lineTo(o.dx + 4.5, o.dy)
    ..lineTo(o.dx, o.dy + 5.5)
    ..lineTo(o.dx - 4.5, o.dy)
    ..close();
  canvas.drawPath(p, Paint()..color = HENSUU.backgroundcolor);
  canvas.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white,
  );
}

/// 凡例の印(0=帯・1=平均の線・2=中央値・3=白抜きの丸・4=点線)
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
          Paint()..color = iro.withOpacity(0.45),
        );
        canvas.drawCircle(o, 3.2, Paint()..color = iro);
        break;
      case 1:
        canvas.drawLine(
          Offset(o.dx, o.dy - 7),
          Offset(o.dx, o.dy + 7),
          Paint()
            ..color = iro
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
        break;
      case 2:
        _hishigata(canvas, o);
        break;
      case 3:
        canvas.drawCircle(
          o,
          3.2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3
            ..color = Colors.grey.shade500,
        );
        break;
      default:
        final Paint p = Paint()
          ..color = iro.withOpacity(0.7)
          ..strokeWidth = 1.5;
        for (double yy = 0; yy < size.height; yy += 6) {
          canvas.drawLine(
            Offset(o.dx, yy),
            Offset(o.dx, math.min(yy + 3, size.height)),
            p,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _HanreiPainter old) =>
      old.shurui != shurui || old.iro != iro;
}
