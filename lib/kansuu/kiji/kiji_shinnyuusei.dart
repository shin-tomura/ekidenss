import 'dart:math' show sqrt;
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/koukou.dart'; // 出身校と高校時代の実績・高校の大会の記録(1.9.5)
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_gakunai.dart' show gakunaiSiteMeiJibun, gakunaiKishaMei;
import 'package:ekiden/kansuu/bokou_pipe.dart' show bokouPipeBokou; // 監督の母校から入った新入生(2.0.1)
import 'package:ekiden/kansuu/shushou.dart' show shushouNendoRetsu; // 新入生紹介号の主将(2.0.2)
import 'package:ekiden/kansuu/taikai_chouki.dart' show choukiNendo;

// ------------------------------------------------------------
// 新入生の記事(2.0.0。4月5日の最新画面のカードから。読めるのはその日だけ)
// ・箱庭スポーツの「期待のルーキー」: 新入生の世代全体を見る記事
// ・学内メディアの「新入生紹介号」: 自分の大学の新入生を1人ずつ紹介する記事
// (大会に関係ない記事なので、年間表彰と同じく正月駅伝を記事にする大会として読む。KijiKankyou.yomuRace(2))
//
// 箱庭スポーツの観点(事実ごとに点を付け、一番高いものを見出しにする。kiji_kihon.dart の作り方と同じ)
//  ・世代トップ(持ちタイム)と、その進学先。上の世代(今の2〜4年生)の世代トップとの比べ
//  ・花の1区(全国高校駅伝の1区。高校の大会の記録から): 区間賞とその進学先、直近の大会の区間賞のタイムとの比べ、
//    1区で数秒差を争った2人の進学先、1区の上位の進学先。高校の情報を出せるときは毎年必ず書く
//  ・高校総体: 5000mの優勝と日本人トップ(優勝は留学生のことが多いので、現実の報道にならう)、1500m・3000m障害の優勝
//  ・13分台の人数: 理論値(例年)と、上の世代との比べ
//  ・大学の補強: 世代上位30人を何人獲ったか、名声の順位との比べ
//  ・全国高校駅伝の優勝校のメンバーの進学先、同じ高校の同級生がそろって同じ大学へ、ほかの競技の出身、留学生
//  ・監督の母校から、その監督の大学に入った新入生(2.0.1。監督の母校パイプ。bokou_pipe.dart)。段落だけで、
//    見出しの型にはしない(前の年と同じ見出しを避ける仕組みを変えないため)。同じ高校の同級生の組と同じなら、
//    同級生の段落に「監督の母校でもある」と書き足す。スカウトのいきさつは書かず、事実だけを書く
//  ・まれな年の見出し: 世代トップ・1区の区間賞・総体5000mの優勝(か日本人トップ)の3つ(2つ)を同じ選手がそろえた
// ・飽きさせないように: 見出しの型ごとに言い回しを数通り持つ。前の年と同じ型の見出しは避ける
//   (KantokuData.yobiint3[77] に、年度と前の年の型と今年の型を詰めて残す)。リードと「記者の目」は記者の型で変える。
//   段落の順は点に乱数を足して決め、1区の段落は見出しでなければ2〜4番目のどこかに入れる
//
// 守る決まり(サプライズと、見抜く力の仕組みを壊さないため)
//  ・選ぶのも書くのも、入学時の5000m(持ちタイム)と高校時代の実績だけ。能力値・成長タイプ・上限・隠れた逸材には
//    触れない(高校の実績も入学時の記録から計算しているので、逸材は分からない。koukou.dart)
//  ・選手の性質(勝負強い・本番に強い・大舞台に強い・ラストの切れなど)は書かない。高校の大会の計算には
//    駅伝男・平常心を使っていないので、読み違えさせないように、「夏の一発勝負を制した」「この日は4位にとどまった」
//    のように、その日の出来事だけを書く
//  ・大学での活躍や伸び方は決めつけない。スカウトの経緯(勧誘・志望)は書かない
//  ・高校の情報を表示しない設定のときは、高校の観点(1区・高校総体・優勝校・同じ高校・ほかの競技)を書かない
//  ・名前のない高校生(大学に来なかった選手や下級生)は、名前を出さず「○○高の2年生」と書く。
//    「来年大学に来るかも」とは書かない。大学に来た選手の、下級生のときの大会の記録は書いてよい
//    (高校名鑑の大会の記録に出ている事実のため)
//  ・総監督(プレイヤー)の言葉は作らない。箱庭スポーツでは、自分の大学の監督のコメントも出さない
//  ・13分台の人数の「例年」は理論値: 1人が13分台になる確率は約13.6%(SenshuShokiti.dart の決め方を
//    シミュレーションで確かめた。設定で変わらない)。世代トップの持ちタイムは、真ん中が13分30秒前後で、
//    13分25秒より速いのは10年に1度ほど、13分20秒台は2年に1度ほど、13分42秒より遅いのは20年に1度ほど
// ------------------------------------------------------------

/// 箱庭スポーツの新入生の記事のカテゴリ(生成AIに渡すときの依頼文を変える)
const String kijiShinnyuuseiCategory = '新入生';

/// 学内メディアの新入生紹介号のカテゴリ
const String kijiShinnyuuseiGakunaiCategory = '新入生紹介';

/// 新入生の記事か(生成AIに渡すときの依頼文を変える)
bool kijiShinnyuuseiKa(Kiji kiji) =>
    kiji.category == kijiShinnyuuseiCategory || kiji.category == kijiShinnyuuseiGakunaiCategory;

/// 記事の番号(乱数と記者の名前に使う)
const int _no = 191;
const int _noGakunai = 192;

/// 前の年の見出しの型を残す場所(KantokuData.yobiint3の番号)
/// 値は 年度×10000 + 前の年の型×100 + 今年の型(型は1〜99。前の年がなければ99)
const int shinnyuuseiMidashiIndex = 77;

/// 13分台(秒)
const double _juusan = 840.0;

/// 1人が13分台になる確率(理論値。上の説明を参照)
const double _juusanKakuritsu = 0.136;

/// 世代上位の人数(大学の補強を数える)
const int _jouiNinzuu = 30;

// ------------------------------------------------------------
// 事実を集める
// ------------------------------------------------------------

/// 新入生1人
class _Shin {
  final SenshuData s;

  /// 世代の持ちタイムの順位(0が世代トップ。留学生は-1)
  final int juni;

  /// 出してよい高校の情報(表示しない設定のときと、出身校がないときはnull)
  final KoukouJouhou? j;

  /// 全国高校駅伝で走った区間(1〜7。0は走っていない)
  int kukan = 0;

  /// その区間の区間順位(1〜。0は分からない。31は31位以下)
  int kukanJuni = 0;

  /// その区間のタイム(秒。分からなければnull)
  double? kukanTime;

  _Shin(this.s, this.juni, this.j);

  /// 入学時の5000m(持ちタイム)
  double get t => s.kiroku_nyuugakuji_5000;

  bool get ryuugakusei => s.hirou == 1;

  /// 校名(「雷鳥館高」。なければ空)
  String get kou => j == null ? '' : koukouMeiMoji(j!);
}

/// 上の世代(今の2〜4年生)の入学時の記録
class _Ue {
  final int gakunen;
  final int juusan;
  final SenshuData? top;
  const _Ue(this.gakunen, this.juusan, this.top);
}

/// 記事の材料
class _Shiryou {
  final KijiKankyou k;
  final int nendo;

  /// 高校の情報を書けるか(表示しない設定でない)
  final bool koukouAri;

  /// 日本人の新入生(持ちタイムの順)
  final List<_Shin> nihon;

  /// 留学生の新入生
  final List<_Shin> ryuu;

  /// 選手id → 新入生
  final Map<int, _Shin> byId;

  /// この世代の高校の大会の記録(なければnull)と、それより前の世代の記録(新しい順)
  final KoukouTaikaiKiroku? rec;
  final List<KoukouTaikaiKiroku> recMae;

  /// 上の世代(2年・3年・4年の順)
  final List<_Ue> ue;

  _Shiryou(this.k, this.nendo, this.koukouAri, this.nihon, this.ryuu, this.byId, this.rec, this.recMae, this.ue);

  /// 大会の記録の選手が、この世代の新入生なら、その選手(名前のない高校生や、別の選手ならnull)
  _Shin? shin(KoukouKirokuSousha x) {
    if (!x.namaeAri || x.id < 0) return null;
    final _Shin? sh = byId[x.id];
    if (sh == null || sh.s.name != x.name) return null;
    return sh;
  }

  UnivData univ(_Shin x) => k.univ[x.s.univid];

  /// 大学の呼び方(「東西大」)
  String univMei(_Shin x) => daigakuMei(univ(x));

  /// 名声の順位(1〜)
  int meiseiJuni(int univid) => k.univ[univid].meiseijuni + 1;

  /// 13分台の人数
  int get juusanSuu => nihon.where((x) => x.t < _juusan).length;

  /// 13分台の人数の理論値(例年)
  double get juusanHeinen => nihon.length * _juusanKakuritsu;

  /// 13分台の人数が、例年からどれだけ離れているか(標準偏差のいくつ分か)
  double get juusanZure {
    final double v = nihon.length * _juusanKakuritsu * (1 - _juusanKakuritsu);
    if (v <= 0) return 0;
    return (juusanSuu - juusanHeinen) / sqrt(v);
  }

  /// 世代上位30人に入った新入生(大学ごとの人数)
  Map<int, int> get jouiKazu {
    final Map<int, int> m = {};
    for (final _Shin x in nihon.take(_jouiNinzuu)) {
      m[x.s.univid] = (m[x.s.univid] ?? 0) + 1;
    }
    return m;
  }

  /// 全国高校駅伝の1区の上位3人(記録がなければ空)
  List<KoukouKirokuSousha> get ikkuJoui {
    final KoukouTaikaiKiroku? r = rec;
    if (r == null || r.kukan.isEmpty) return const [];
    return r.kukan[0];
  }

  /// 全国高校駅伝の1区を走った新入生(区間順位の順。順位の分からない選手は後ろ)
  List<_Shin> get ikkuShin {
    final List<_Shin> l = [
      for (final _Shin x in nihon)
        if (x.kukan == 1) x,
    ];
    l.sort((a, b) {
      final int ja = a.kukanJuni <= 0 ? 999 : a.kukanJuni;
      final int jb = b.kukanJuni <= 0 ? 999 : b.kukanJuni;
      return ja != jb ? ja.compareTo(jb) : a.juni.compareTo(b.juni);
    });
    return l;
  }

  /// 1区の区間賞を取った新入生(いなければnull)
  _Shin? get ikkuKukanshou {
    final List<KoukouKirokuSousha> j = ikkuJoui;
    if (j.isNotEmpty) return shin(j.first);
    for (final _Shin x in ikkuShin) {
      if (x.kukanJuni == 1) return x;
    }
    return null;
  }

  /// 高校総体の種目[sh](0=1500m・1=5000m・2=3000m障害)の決勝(着順。記録がなければ空)
  List<KoukouKirokuSousha> soutai(int sh) {
    final KoukouTaikaiKiroku? r = rec;
    if (r == null || r.soutai.length <= sh) return const [];
    return r.soutai[sh];
  }

  /// 高校総体の種目[sh]で優勝した新入生(いなければnull。記録がなければ高校時代の実績から)
  _Shin? soutaiYuushou(int sh) {
    final List<KoukouKirokuSousha> f = soutai(sh);
    if (f.isNotEmpty) return shin(f.first);
    if (rec != null) return null;
    for (final _Shin x in [...nihon, ...ryuu]) {
      final KoukouJouhou? j = x.j;
      if (j != null && j.soutaiShumoku == sh + 1 && j.soutaiDankai == 3 && j.soutaiJuni == 1) return x;
    }
    return null;
  }

  /// 高校総体5000mの日本人トップの新入生と、その順位(優勝が留学生で、日本人トップが新入生のときだけ。なければnull)
  ({_Shin x, int juni})? get soutaiNihonjinTop {
    final List<KoukouKirokuSousha> f = soutai(1);
    if (f.isEmpty) return null;
    if (!(f.first.shurui == 1 || f.first.shurui == 3)) return null;
    for (int i = 0; i < f.length; i++) {
      final KoukouKirokuSousha y = f[i];
      if (y.shurui == 0 || y.shurui == 2) {
        final _Shin? x = shin(y);
        return x == null ? null : (x: x, juni: i + 1);
      }
    }
    return null;
  }
}

/// 材料を集める(新入生がいなければnull)
_Shiryou? _shiryouTsukuru(KijiKankyou k) {
  final int nendo = k.gh.month >= 4 ? k.gh.year : k.gh.year - 1;
  final bool koukouAri = !koukouHyoujiNashi(k.kantoku);
  bool daigakuAri(SenshuData s) => s.univid >= 0 && s.univid < k.univ.length;
  bool kirokuAri(SenshuData s) =>
      s.hirou != 1 && s.kiroku_nyuugakuji_5000 > 0 && s.kiroku_nyuugakuji_5000 < TEISUU.DEFAULTTIME;
  int jun(SenshuData a, SenshuData b) {
    final int c = a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000);
    return c != 0 ? c : a.id.compareTo(b.id);
  }

  final List<SenshuData> nihonS = [
    for (final SenshuData s in k.senshu)
      if (s.gakunen == 1 && daigakuAri(s) && kirokuAri(s)) s,
  ]..sort(jun);
  if (nihonS.isEmpty) return null;
  final Map<int, _Shin> byId = {};
  final List<_Shin> nihon = [];
  for (int i = 0; i < nihonS.length; i++) {
    final SenshuData s = nihonS[i];
    final _Shin x = _Shin(s, i, koukouHyoujiJouhou(s.samusataisei, s.hirou, k.kantoku));
    nihon.add(x);
    byId[s.id] = x;
  }
  final List<_Shin> ryuu = [];
  for (final SenshuData s in k.senshu) {
    if (s.gakunen != 1 || !daigakuAri(s) || s.hirou != 1) continue;
    final _Shin x = _Shin(s, -1, koukouHyoujiJouhou(s.samusataisei, s.hirou, k.kantoku));
    ryuu.add(x);
    byId[s.id] = x;
  }
  // 高校の大会の記録(表示しない設定のときは読まない)
  KoukouTaikaiKiroku? rec;
  final List<KoukouTaikaiKiroku> recMae = [];
  if (koukouAri) {
    for (final KoukouTaikaiKiroku r in koukouTaikaiKirokuYomu()) {
      if (r.nyuugakuNendo == nendo) {
        rec ??= r;
      } else if (r.nyuugakuNendo < nendo) {
        recMae.add(r);
      }
    }
  }
  final _Shiryou d = _Shiryou(k, nendo, koukouAri, nihon, ryuu, byId, rec, recMae, [
    for (int g = 2; g <= 4; g++) _ueTsukuru(k, g, daigakuAri, kirokuAri, jun),
  ]);
  // 全国高校駅伝で走った区間と区間順位(記録の走者から。なければ高校時代の実績から)
  final KoukouTaikaiKiroku? r = rec;
  if (r != null) {
    for (final KoukouKirokuTeam team in r.zenkoku) {
      final List<KoukouKirokuSousha>? m = team.member;
      if (m == null) continue;
      for (final KoukouKirokuSousha y in m) {
        final _Shin? x = d.shin(y);
        if (x == null || y.kukan < 1) continue;
        x.kukan = y.kukan;
        x.kukanJuni = y.kukanJuni;
        x.kukanTime = y.time > 0 ? y.time : null;
      }
    }
  }
  for (final _Shin x in [...nihon, ...ryuu]) {
    final KoukouJouhou? j = x.j;
    if (x.kukan > 0 || j == null) continue;
    if (j.keireki == 2 || !j.ekidenZenkoku || j.ekidenKukan < 1) continue;
    x.kukan = j.ekidenKukan;
    x.kukanJuni = j.ekidenKukanJuni;
  }
  return d;
}

_Ue _ueTsukuru(
  KijiKankyou k,
  int g,
  bool Function(SenshuData) daigakuAri,
  bool Function(SenshuData) kirokuAri,
  int Function(SenshuData, SenshuData) jun,
) {
  final List<SenshuData> l = [
    for (final SenshuData s in k.senshu)
      if (s.gakunen == g && daigakuAri(s) && kirokuAri(s)) s,
  ]..sort(jun);
  return _Ue(g, l.where((s) => s.kiroku_nyuugakuji_5000 < _juusan).length, l.isEmpty ? null : l.first);
}

/// 下級生のときの大会の記録(区間の上位3人・高校総体の決勝の8位まで)に、この選手が残っていれば、その文
/// (「昨年の全国高校駅伝でも、2年生ながら1区で区間3位に入っていた。」。なければ空)
String _maeKirokuBun(_Shiryou d, _Shin x) {
  for (final KoukouTaikaiKiroku r in d.recMae) {
    final int maeNen = d.nendo - r.nyuugakuNendo;
    if (maeNen < 1 || maeNen > 2) continue;
    final String itsu = maeNen == 1 ? '昨年' : '2年前';
    for (int kk = 0; kk < r.kukan.length; kk++) {
      for (int i = 0; i < r.kukan[kk].length; i++) {
        final KoukouKirokuSousha y = r.kukan[kk][i];
        if (y.id == x.s.id && y.name == x.s.name && y.gakunen < 3) {
          return '$itsuの全国高校駅伝でも、${y.gakunen}年生ながら${kk + 1}区で${i == 0 ? '区間賞を取って' : '区間${i + 1}位に入って'}いた。';
        }
      }
    }
    for (int sh = 0; sh < r.soutai.length; sh++) {
      for (int i = 0; i < r.soutai[sh].length && i < 8; i++) {
        final KoukouKirokuSousha y = r.soutai[sh][i];
        if (y.id == x.s.id && y.name == x.s.name && y.gakunen < 3) {
          return '$itsuの高校総体でも、${y.gakunen}年生ながら${koukouShumokuMei[sh + 1]}で${i == 0 ? '優勝して' : '${i + 1}位に入って'}いた。';
        }
      }
    }
  }
  return '';
}

/// 大会の記録の高校の名前から、都道府県のかっこを除いた名前(「天馬学園高」。その他の高校は「栃木県の高校」)
String _kouMijikai(String mei) {
  final int i = mei.indexOf('(');
  return i > 0 ? mei.substring(0, i) : mei;
}

/// 名前のない高校生の呼び方(「天馬学園高の2年生」)
String _nanashiMei(KoukouTaikaiKiroku r, KoukouKirokuSousha y) {
  final String kou = _kouMijikai(r.kouMei(y.kouCode));
  final bool ryuu = y.shurui == 3;
  return ryuu ? '$kouの留学生' : '$kouの${y.gakunen}年生';
}

// ------------------------------------------------------------
// 言い回し(選手の性質や、大学での伸び方を決めつける言葉は入れない)
// ------------------------------------------------------------

/// 1区の区間賞の新入生の言葉
const List<String> _ikkuKotoba = [
  '1区で勝てたことは自信になった。でも大学では、また一から積み上げたい',
  'エースが集まる1区で勝てたのは大きい。大学の駅伝でも、あの舞台に立ちたい',
  '高校駅伝の1区を走った経験を、大学の駅伝でも生かしたい',
  'あの日のスタートの緊張感は忘れられない。大学でも、最初のたすきを任される選手になりたい',
];

/// 持ちタイムの世代トップの新入生の言葉
const List<String> _sedaiKotoba = [
  '高校の記録はもう過去のもの。大学の距離に早く慣れたい',
  '持ちタイムは関係ない。大学で結果を出して、初めて認めてもらえると思う',
  '1年目から駅伝のメンバーに入ることが目標です',
  '注目してもらえるのはありがたい。でも、まずはチームの一員として認められたい',
];

/// 高校総体5000mで優勝した新入生の言葉
const List<String> _soutaiKotoba = [
  '総体で勝てたのはうれしかった。でも大学には、もっと速い先輩がたくさんいる',
  'トラックで勝てた経験を、駅伝の長い距離でも生かしたい',
  '夏の優勝はもう過去のこと。大学では一からのスタートです',
];

/// 高校総体5000mの日本人トップの新入生の言葉
const List<String> _nihonjinTopKotoba = [
  '優勝した選手には届かなかった。大学ではその差を埋めたい',
  '日本人トップと言ってもらえるのはうれしい。でも、目指しているのはもっと上です',
];

/// ほかの競技の出身の新入生の言葉
const List<String> _ishokuKotoba = [
  '陸上を本格的に始めたのは最近。毎日が新しいことばかりで楽しい',
  '高校までは別の競技だった。走ることの奥深さを、大学で知りたい',
  '経験が少ない分、覚えることはたくさんある。一つずつ身につけていきたい',
];

/// 留学生の新入生の言葉
const List<String> _ryuuKotoba = [
  '日本の駅伝を走るのが夢だった。チームの力になりたい',
  '仲間と一緒にたすきをつなぐのが楽しみです',
];

/// 日本の高校の出身の留学生の言葉
const List<String> _ryuuKoukouKotoba = [
  '日本の高校で駅伝を知った。大学でもたすきをつなぎたい',
  '高校の仲間に、大学で走る姿を見せたい',
];

/// ふつうの新入生の言葉
const List<String> _futsuuKotoba = [
  '正月駅伝を走ることが、ずっと目標だった',
  '先輩たちに少しでも早く追いつきたい',
  '4年間でどこまで行けるか、自分でも楽しみです',
  '1年目から駅伝のメンバー争いに加わりたい',
  'まずは大学の練習に慣れて、夏に力をつけたい',
  '憧れていたチームで走れるのがうれしい',
  '高校の仲間に、大学での活躍を届けたい',
  '一日一日を大切にして、4年間を走り抜きたい',
];

/// 選手の言葉の締め(「と山田は話した」の「話した」)
const List<String> _senshuShime = ['話した', '前を向いた', '意気込んだ', '笑顔を見せた', '言葉に力を込めた', '目を輝かせた'];

/// 監督の言葉の締め
const List<String> _kantokuShime = ['語った', '話した', '目を細めた', 'うなずいた'];

/// 大学の監督の、迎えた新入生への言葉(箱庭スポーツ。自分の大学の監督は出さない)
const List<String> _daigakuKantokuKotoba = [
  '大学の距離に慣れるまでは、焦らずじっくり育てたい',
  '期待はしているが、1年目から無理はさせない。4年間で大きく育ってほしい',
  'チームの中で刺激し合って、一緒に強くなってほしい',
  '高校で結果を残してきた選手。大学の舞台でどう走るか楽しみだ',
];

/// 高校の監督(名前は出さない)の、1区を走った教え子への言葉
const List<String> _koukouKantokuIkku = [
  '1区を任せられるのは、彼しかいなかった。大学での4年間が楽しみです',
  '高校駅伝を一緒に戦えたことは、私にとっても財産。大学でも走る喜びを忘れずにいてほしい',
  '高校の3年間で、本当にたくましくなった。次の舞台でも頑張ってほしい',
];

/// 高校の監督の、全国高校駅伝の優勝メンバーへの言葉
const List<String> _koukouKantokuYuushou = [
  '仲間と喜び合ったあの日を忘れずに、大学でも頑張ってほしい',
  'それぞれの場所で、今度はライバルとして高め合ってほしい',
  '高校の3年間で、本当にたくましくなった。次の舞台でも頑張ってほしい',
];

/// 学内メディア・自分の大学の監督の、新入生への言葉
const List<String> _jibunKantokuKotoba = [
  '新しい仲間を迎えて、チームの雰囲気が明るくなった。上級生にもいい刺激になる',
  '焦らず、4年間でじっくり育てたい。1年目は大学の距離に慣れることから',
  '一人ひとりの4年後が楽しみ。上級生と一緒に、新しいチームを作っていきたい',
];

// ------------------------------------------------------------
// 箱庭スポーツ「期待のルーキー」
// ------------------------------------------------------------

/// 見出しの型(前の年と同じ型を避けるために番号で残すので、番号を変えない)
const int _gSankan = 1; // 世代トップ・1区の区間賞・総体5000m(優勝か日本人トップ)を1人でそろえた
const int _gNikan = 2; // そのうち2つを1人でそろえた
const int _gIkku = 3; // 花の1区の区間賞
const int _gRival = 4; // 1区で数秒差を争った2人が別々の大学へ
const int _gSedai = 5; // 持ちタイムの世代トップ
const int _gSoutai = 6; // 高校総体5000m
const int _gKazu = 7; // 13分台の人数
const int _gHokyou = 8; // 大学の補強
const int _gYuushou = 9; // 全国高校駅伝の優勝校のメンバー
const int _gOnaji = 10; // 同じ高校の同級生がそろって同じ大学へ
const int _gIshoku = 11; // ほかの競技の出身

/// 段落の種類
enum _Dan { sedai, ikku, soutai, kazu, hokyou, yuushou, onaji, ishoku, ryuu, bokou }

/// 期待のルーキーの記事を書く
class _Rookie {
  final _Shiryou d;
  final KijiKakite w;

  /// 名前と言葉を出した選手
  final Set<int> _commentZumi = {};
  final Set<int> _jissekiZumi = {};

  /// 見出しで取り上げた大学(自分の大学なら、一覧で印を付ける)
  int? midashiUnivId;

  _Rookie(this.d, this.w);

  KijiKankyou get k => d.k;

  /// 持ちタイムの世代トップ
  _Shin get top => d.nihon.first;

  /// 1区の区間賞の新入生
  late final _Shin? ikkuW = d.koukouAri ? d.ikkuKukanshou : null;

  /// 高校総体5000mで優勝した新入生(留学生も)
  late final _Shin? soutaiW = d.koukouAri ? d.soutaiYuushou(1) : null;

  /// 高校総体5000mの日本人トップの新入生(優勝が留学生のとき)
  late final ({_Shin x, int juni})? nihonjinTop = d.koukouAri ? d.soutaiNihonjinTop : null;

  /// 高校総体5000mで優勝した日本人の新入生がいるか
  bool get soutaiNihonYuushou => soutaiW != null && !soutaiW!.ryuugakusei;

  /// 高校総体5000mの日本人の覇者(優勝した日本人の新入生か、日本人トップの新入生)
  _Shin? get soutaiNihon => soutaiNihonYuushou ? soutaiW : nihonjinTop?.x;

  /// 選手[x]の肩書き(世代トップ・花の1区の覇者・総体5000m)
  List<String> shougou(_Shin x) => [
    if (identical(x, top)) '持ちタイム世代トップ',
    if (identical(x, ikkuW)) '花の1区の覇者',
    if (identical(x, soutaiNihon)) soutaiNihonYuushou ? '総体5000m覇者' : '総体5000m日本人トップ',
  ];

  /// 肩書きを3つそろえた選手
  _Shin? get sankan => shougou(top).length == 3 ? top : null;

  /// 肩書きを2つ持つ選手
  _Shin? get nikan {
    for (final _Shin? x in [top, ikkuW, soutaiNihon]) {
      if (x != null && shougou(x).length == 2) return x;
    }
    return null;
  }

  /// 1区で数秒差を争った2人(区間賞と区間2位。どちらも新入生で、別々の大学に進んだとき)
  late final ({_Shin a, _Shin b, int sa})? rival = _rivalTsukuru();

  ({_Shin a, _Shin b, int sa})? _rivalTsukuru() {
    final List<KoukouKirokuSousha> j = d.ikkuJoui;
    if (j.length < 2) return null;
    final _Shin? a = d.shin(j[0]);
    final _Shin? b = d.shin(j[1]);
    if (a == null || b == null || a.s.univid == b.s.univid) return null;
    final int sa = saByou(j[1].time, j[0].time);
    if (sa > 3) return null;
    return (a: a, b: b, sa: sa);
  }

  /// 大学ごとの世代上位30人の人数(多い順。同じなら最上位の選手が上の大学)
  late final List<MapEntry<int, int>> hokyouJun = _hokyouJunTsukuru();

  List<MapEntry<int, int>> _hokyouJunTsukuru() {
    final Map<int, int> saijoui = {};
    for (final _Shin x in d.nihon) {
      saijoui.putIfAbsent(x.s.univid, () => x.juni);
    }
    return d.jouiKazu.entries.toList()
      ..sort((a, b) {
        final int c = b.value.compareTo(a.value);
        return c != 0 ? c : (saijoui[a.key] ?? 999).compareTo(saijoui[b.key] ?? 999);
      });
  }

  /// 補強で取り上げる大学(名声4位以下で3人以上を獲った大学を先に。なければ一番多く獲った大学)
  MapEntry<int, int>? get hokyouUniv {
    for (final MapEntry<int, int> e in hokyouJun) {
      if (e.value >= 3 && d.meiseiJuni(e.key) > 3) return e;
    }
    return hokyouJun.isEmpty ? null : hokyouJun.first;
  }

  /// 全国高校駅伝の優勝校(記録がなければnull)
  KoukouKirokuTeam? get yuushouTeam {
    final KoukouTaikaiKiroku? r = d.rec;
    if (r == null || r.zenkoku.isEmpty) return null;
    return r.zenkoku.first;
  }

  /// 優勝校の走者のうち、大学に進んだ新入生(区間の順)
  late final List<({_Shin x, int kukan})> yuushouShin = _yuushouShinTsukuru();

  List<({_Shin x, int kukan})> _yuushouShinTsukuru() {
    final KoukouKirokuTeam? t = yuushouTeam;
    if (t == null || t.member == null) return const [];
    final List<({_Shin x, int kukan})> l = [];
    for (final KoukouKirokuSousha y in t.member!) {
      if (y.kukan < 1) continue;
      final _Shin? x = d.shin(y);
      if (x != null) l.add((x: x, kukan: y.kukan));
    }
    l.sort((a, b) => a.kukan.compareTo(b.kukan));
    return l;
  }

  /// 同じ高校の同級生で、そろって同じ大学に進んだ人数が一番多い組(2人以上。優勝校は除く。なければ空)
  late final List<_Shin> onaji = _onajiTsukuru();

  List<_Shin> _onajiTsukuru() {
    final int yk = yuushouTeam?.kouCode ?? -999;
    final Map<int, List<_Shin>> m = {};
    for (final _Shin x in d.nihon) {
      final KoukouJouhou? j = x.j;
      if (j == null || j.koukou < 1 || j.koukou - 1 == yk) continue;
      m.putIfAbsent(j.koukou * 100 + x.s.univid, () => []).add(x);
    }
    List<_Shin> best = const [];
    for (final List<_Shin> l in m.values) {
      if (l.length < 2) continue;
      if (l.length > best.length || (l.length == best.length && l.first.juni < best.first.juni)) best = l;
    }
    return best;
  }

  /// 監督の母校から、その監督の大学に入った新入生(大学id → 新入生。持ちタイムの順。2.0.1。監督の母校パイプ)
  /// (高校の情報を出せないときは空)
  late final Map<int, List<_Shin>> bokouBetsu = _bokouBetsuTsukuru();

  Map<int, List<_Shin>> _bokouBetsuTsukuru() {
    if (!d.koukouAri) return const {};
    final Map<int, int> bokou = bokouPipeBokou(k.kantoku);
    if (bokou.isEmpty) return const {};
    final Map<int, List<_Shin>> m = {};
    for (final _Shin x in d.nihon) {
      final KoukouJouhou? j = x.j;
      final int? kou = bokou[x.s.univid];
      if (j == null || kou == null || j.koukou != kou) continue;
      m.putIfAbsent(x.s.univid, () => []).add(x);
    }
    return m;
  }

  /// 監督の母校から入った組で、一番目立つもの(人数の多い組。同じなら最上位の選手が上の組。なければ空)
  late final List<_Shin> bokou = _bokouTsukuru();

  List<_Shin> _bokouTsukuru() {
    List<_Shin> best = const [];
    for (final List<_Shin> l in bokouBetsu.values) {
      if (l.length > best.length || (l.length == best.length && l.first.juni < best.first.juni)) best = l;
    }
    return best;
  }

  /// 監督の母校から入った組が、同じ高校の同級生の組と同じか(同じなら、同級生の段落に書き足す)
  bool get bokouOnaji =>
      onaji.isNotEmpty &&
      bokou.isNotEmpty &&
      onaji.first.s.univid == bokou.first.s.univid &&
      onaji.first.j?.koukou == bokou.first.j?.koukou;

  /// ほかの競技の出身で、持ちタイムが世代60番手までの新入生(一番上の選手。いなければnull)
  late final _Shin? ishoku = _ishokuTsukuru();

  _Shin? _ishokuTsukuru() {
    if (!d.koukouAri) return null;
    for (final _Shin x in d.nihon) {
      if (x.juni >= 60) break;
      if (x.j?.keireki == 2) return x;
    }
    return null;
  }

  /// 1区の段落を書けるか(高校の情報を出せて、1区の記録か、1区を走った新入生がいる)
  bool get ikkuAri => d.koukouAri && (d.ikkuJoui.isNotEmpty || d.ikkuShin.isNotEmpty);

  // ---- 点 ----

  int get sedaiTen =>
      80 +
      (top.t < 810 ? 15 : 0) +
      (top.t < 805 ? 10 : 0) +
      (d.meiseiJuni(top.s.univid) >= 15 ? 10 : 0);

  int get ikkuTen {
    if (ikkuW != null) return 85;
    if (d.ikkuShin.any((x) => x.kukanJuni >= 1 && x.kukanJuni <= 10)) return 50;
    return 30;
  }

  int get soutaiTen {
    if (soutaiNihonYuushou) return 80;
    if (nihonjinTop != null) return 60;
    if (soutaiW != null) return 55;
    if (d.koukouAri && (d.soutaiYuushou(0) != null || d.soutaiYuushou(2) != null)) return 40;
    return 0;
  }

  int get kazuTen {
    final double z = d.juusanZure.abs();
    if (z >= 1.25) return 85;
    if (z >= 0.6) return 50;
    return 35;
  }

  int get hokyouTen {
    final MapEntry<int, int>? e = hokyouUniv;
    if (e == null) return 0;
    if (d.meiseiJuni(e.key) > 3) {
      if (e.value >= 4) return 70;
      if (e.value >= 3) return 55;
    }
    return 35;
  }

  int get yuushouTen {
    final int n = yuushouShin.length;
    if (n == 0) return 0;
    final int us = {for (final e in yuushouShin) e.x.s.univid}.length;
    if (n >= 3) return 55 + ((us == 1 || us == n) ? 10 : 0);
    if (n == 2) return 45 + (us == 1 ? 10 : 0);
    return 30;
  }

  int get onajiTen {
    // 監督の母校でもあるときは、少し目立つ(2.0.1)
    final int bokouKasan = bokouOnaji ? 10 : 0;
    if (onaji.length >= 3) return 70 + bokouKasan;
    if (onaji.length == 2) return ((onaji.first.j?.mei?.meimon ?? 0) >= 2 ? 45 : 40) + bokouKasan;
    return 0;
  }

  /// 監督の母校から入った新入生の段落の点(2.0.1。同級生の組と同じなら、同級生の段落に書くので0)
  int get bokouTen {
    final List<_Shin> l = bokou;
    if (l.isEmpty || bokouOnaji) return 0;
    if (l.length >= 2) return 60;
    return l.first.juni < _jouiNinzuu ? 50 : 45;
  }

  int get ishokuTen {
    final _Shin? x = ishoku;
    if (x == null) return 0;
    return 45 + (x.juni < 20 ? 15 : 0);
  }

  int get ryuuTen {
    if (d.ryuu.isEmpty) return 0;
    final bool medatsu = d.ryuu.any((x) => x.j != null && (x.kukanJuni == 1 || identical(x, soutaiW)));
    return 30 + (medatsu ? 20 : 0);
  }

  // ---- 名前と言葉 ----

  /// 選手の呼び方(初めては「山田太郎(雷鳥館高)」、2回目からは「山田」)
  /// [kakko] 初めてのときのかっこの中(省くと校名。留学生で校名がなければ「留学生」)
  String yobu(_Shin x, {String? kakko}) {
    final String kk = kakko ?? (x.kou.isNotEmpty ? x.kou : (x.ryuugakusei ? '留学生' : ''));
    return w.hito('S${x.s.id}', x.s.name, kk, '');
  }

  /// 選手の言葉(「「……」と山田は話した。」。同じ選手は1度だけ。言葉がなければ空)
  void senshuKotoba(_Shin x, List<String> kouho) {
    if (_commentZumi.contains(x.s.id)) return;
    _commentZumi.add(x.s.id);
    w.comment('「${w.erabu(kouho)}」と${yobu(x)}は${w.erabu(_senshuShime)}。');
  }

  /// 選手[x]に合う言葉の候補
  List<String> kotobaKouho(_Shin x) {
    if (x.ryuugakusei) return x.j != null ? _ryuuKoukouKotoba : _ryuuKotoba;
    if (identical(x, ikkuW)) return _ikkuKotoba;
    if (identical(x, soutaiW)) return _soutaiKotoba;
    if (identical(x, nihonjinTop?.x)) return _nihonjinTopKotoba;
    if (identical(x, top)) return _sedaiKotoba;
    if (x.j?.keireki == 2) return _ishokuKotoba;
    return _futsuuKotoba;
  }

  /// 大学の監督の言葉(自分の大学と、監督がいない大学は出さない)
  void daigakuKantoku(_Shin x) {
    final int uid = x.s.univid;
    if (uid == k.gh.MYunivid) return;
    final ({String name, int nenrei})? kt = k.kantokuMei(uid);
    if (kt == null) return;
    final String kagi = 'K$uid';
    final bool hajimete = !w.deta(kagi);
    final String yobi = w.hito(kagi, kt.name, '', '');
    final String kata = hajimete ? '${d.univMei(x)}の$yobi監督(${kt.nenrei})' : '$yobi監督';
    w.comment('「${w.erabu(_daigakuKantokuKotoba)}」と$kataは${w.erabu(_kantokuShime)}。');
  }

  /// 大学[uid]の監督の呼び方(初めては「山田太郎監督(45)」、2回目からは「山田監督」。監督がいなければnull)
  /// (大学の監督の言葉と同じ呼び方。2.0.1。監督の母校パイプ)
  String? kantokuYobi(int uid) {
    final ({String name, int nenrei})? kt = k.kantokuMei(uid);
    if (kt == null) return null;
    final String kagi = 'K$uid';
    final bool hajimete = !w.deta(kagi);
    final String yobi = w.hito(kagi, kt.name, '', '');
    return hajimete ? '$yobi監督(${kt.nenrei})' : '$yobi監督';
  }

  /// 高校の監督(名前は出さない)の言葉
  void koukouKantoku(String kou, List<String> kouho) {
    if (kou.isEmpty) return;
    w.comment('「${w.erabu(kouho)}」と$kouの監督は${w.erabu(_kantokuShime)}。');
  }

  /// 高校時代の一番の実績の文(書いた選手は2度書かない。なければ空)
  String jissekiBun(_Shin x) {
    final KoukouJouhou? j = x.j;
    if (j == null || _jissekiZumi.contains(x.s.id)) return '';
    final String jisseki = koukouJissekiBun(j);
    if (jisseki.isEmpty) return '';
    _jissekiZumi.add(x.s.id);
    return w.erabu(['高校時代は、$jisseki。', '${x.kou}時代は、$jisseki。']);
  }
}

/// 期待のルーキーの段落
extension _RookieDanraku on _Rookie {
  /// 世代トップの段落
  void sedaiDan() {
    final _Shin x = top;
    final String u = d.univMei(x);
    final String t = jikanMoji(x.t);
    final String mei = yobu(x);
    final StringBuffer b = StringBuffer();
    b.write(w.erabu([
      '新入生で最も速い5000mの持ちタイムを持つのは、$uに進んだ$mei。$tは世代トップだ。',
      '世代トップの持ちタイム$tを引っ提げて、$meiが$uの門をくぐった。',
      '持ちタイム$tで世代の先頭に立つ$meiは、進学先に$uを選んだ。',
    ]));
    // 記録の水準(理論値から。10年に1度・2年に1度・20年に1度)
    if (x.t < 805) {
      b.write(w.erabu(['例年なら、10年に1人いるかどうかという記録だ。', '10年に1人と言われる水準の記録だ。']));
    } else if (x.t < 810) {
      b.write(w.erabu(['13分20秒台の新入生が現れるのは、例年なら2年に1度ほどだ。', '13分20秒台は、例年なら2年に1人ほどしか出ない記録だ。']));
    } else if (x.t >= 822) {
      b.write(w.erabu([
        '世代トップが13分40秒台にとどまるのは珍しく、突出した選手のいない横一線の世代と言える。',
        '世代トップでも13分40秒台。例年より控えめで、横一線の世代だ。',
      ]));
    }
    // 肩書き(1区の区間賞・総体5000m)
    final List<String> sh = shougou(x)..remove('持ちタイム世代トップ');
    final String soutaiMoji = soutaiNihonYuushou ? '高校総体5000mの優勝' : '高校総体5000mの日本人トップ';
    if (sh.length == 2) {
      b.write('昨冬の全国高校駅伝1区の区間賞、昨夏の$soutaiMojiと合わせ、名実ともに世代の頂点に立つ。');
      _jissekiZumi.add(x.s.id);
    } else if (sh.length == 1) {
      b.write(
        identical(x, ikkuW)
            ? '昨冬の全国高校駅伝では1区の区間賞も取っており、記録と実績の両方で世代の先頭を走る。'
            : '昨夏の高校総体5000mでも${soutaiNihonYuushou ? '優勝' : '日本人トップ'}となり、記録と実績の両方で世代の先頭を走る。',
      );
      _jissekiZumi.add(x.s.id);
    } else {
      b.write(jissekiBun(x));
    }
    // 名声の低い大学に入った
    final int mj = d.meiseiJuni(x.s.univid);
    if (mj >= 15) {
      b.write(w.erabu(['名声$mj位の$uにとっては、願ってもない新戦力だ。', '名声$mj位の$uに、世代トップが加わった。']));
    }
    // 上の世代の世代トップとの比べ
    final List<_Ue> ue = [
      for (final _Ue e in d.ue)
        if (e.top != null) e,
    ];
    if (ue.length == 3 && ue.every((e) => e.top!.kiroku_nyuugakuji_5000 > x.t)) {
      b.write(w.erabu([
        '今の2〜4年生の、どの世代のトップの入学時の記録よりも速い。',
        '上の3つの世代のトップも、入学時にはこの記録に届いていなかった。',
      ]));
    } else if (ue.isNotEmpty && w.r.kakuritsu(50)) {
      final _Ue e = ue.last;
      final SenshuData s = e.top!;
      b.write(
        '今の${e.gakunen}年生の世代トップ、${w.senshu(s, daigaku: true)}の入学時の記録は'
        '${jikanMoji(s.kiroku_nyuugakuji_5000)}だった。',
      );
    }
    // 2番手・3番手
    if (d.nihon.length >= 3) {
      final _Shin x1 = d.nihon[1];
      final _Shin x2 = d.nihon[2];
      b.write(
        '2番手は${d.univMei(x1)}に進んだ${yobu(x1)}で${jikanMoji(x1.t)}、'
        '3番手は${d.univMei(x2)}に進んだ${yobu(x2)}で${jikanMoji(x2.t)}。',
      );
      final int sa = saByou(x1.t, x.t);
      if (sa <= 1) b.write('世代トップの座は${kinsaMoji(sa)}で分かれた。');
    }
    w.danraku(b.toString());
    senshuKotoba(x, kotobaKouho(x));
    if (w.r.kakuritsu(50)) daigakuKantoku(x);
  }

  /// 花の1区の段落
  void ikkuDan({required bool midashi}) {
    final List<KoukouKirokuSousha> j = d.ikkuJoui;
    final _Shin? xw = ikkuW;
    final Set<int> kaita = {};
    final StringBuffer b = StringBuffer();
    if (w.r.kakuritsu(40)) {
      b.write(w.erabu([
        '各校のエースが集う全国高校駅伝の1区(10km)は、「花の1区」と呼ばれる。',
        '留学生が走れない全国高校駅伝の1区は、日本人エースどうしの真っ向勝負の舞台だ。',
      ]));
    }
    if (xw != null) {
      kaita.add(xw.s.id);
      final String u = d.univMei(xw);
      final double? t = j.isNotEmpty ? j.first.time : xw.kukanTime;
      final String tMoji = t == null ? '' : jikanMoji(t);
      final String kouNo = xw.kou.isEmpty ? '' : '${xw.kou}の';
      final String mei = yobu(xw, kakko: '');
      b.write(w.erabu([
        '昨冬の全国高校駅伝で1区を制したのは、$kouNo$mei。${tMoji.isEmpty ? '' : '$tMojiで区間賞を取り、'}この春、$uに進んだ。',
        '$kouNo$meiは昨冬、全国高校駅伝の1区で${tMoji.isEmpty ? '' : '$tMojiの'}区間賞を取った。進学先は$uだ。',
      ]));
      // 直近の大会の1区の区間賞のタイムとの比べ(区間賞が一番速いときだけ)
      if (t != null) {
        final List<double> mae = [
          for (final KoukouTaikaiKiroku r in d.recMae.take(9))
            if (r.kukan.isNotEmpty && r.kukan[0].isNotEmpty) r.kukan[0].first.time,
        ];
        if (mae.length >= 2 && mae.every((m) => m > t)) {
          b.write('1区の区間賞のタイムとしては、直近${mae.length + 1}大会で最も速い。');
        }
      }
      // 持ちタイムの順位との食い違い(出来事だけを書く)
      if (xw.juni >= 4) {
        b.write(w.erabu([
          '持ちタイムでは世代${xw.juni + 1}番手ながら、高校駅伝のエース区間を制した。',
          '持ちタイムは世代${xw.juni + 1}番手。それでも、この日の1区では誰よりも速かった。',
        ]));
      }
      b.write(_maeKirokuBun(d, xw));
      // 1区で数秒差を争った2人
      final ({_Shin a, _Shin b, int sa})? rv = rival;
      if (rv != null && identical(rv.a, xw)) {
        kaita.add(rv.b.s.id);
        b.write(
          '区間2位の${yobu(rv.b)}とは${kinsaMoji(rv.sa)}の争いだった。${yobu(rv.b)}は${d.univMei(rv.b)}に進み、'
          '2人は今度は大学の駅伝で顔を合わせる。',
        );
      }
    } else if (j.isNotEmpty && !j.first.namaeAri) {
      // 区間賞は、大学に来なかった選手か下級生(名前は出さない)
      final KoukouKirokuSousha y = j.first;
      final String nn = _nanashiMei(d.rec!, y);
      b.write(
        y.gakunen >= 3
            ? '昨冬の全国高校駅伝の1区は、$nnが${jikanMoji(y.time)}で区間賞を取ったが、大学の駅伝の舞台には進まなかった。'
            : '昨冬の全国高校駅伝の1区は、$nnが${jikanMoji(y.time)}で制した。',
      );
      final List<_Shin> l = d.ikkuShin;
      if (l.isNotEmpty && l.first.kukanJuni >= 1) {
        kaita.add(l.first.s.id);
        b.write('大学に進んだ選手では、区間${l.first.kukanJuni}位で${d.univMei(l.first)}に進んだ${yobu(l.first)}が最上位だった。');
      }
    } else {
      // 大会の記録がない(古いデータ)か、区間賞の分からないとき
      final List<_Shin> l = d.ikkuShin;
      if (l.isNotEmpty && l.first.kukanJuni >= 1) {
        kaita.add(l.first.s.id);
        b.write(
          '昨冬の全国高校駅伝で1区を走った新入生では、区間${l.first.kukanJuni}位の${yobu(l.first)}が最上位。'
          '${d.univMei(l.first)}に進んだ。',
        );
      }
    }
    // 1区の区間10位以内から大学に進んだ、ほかの選手
    final List<_Shin> joui = [
      for (final _Shin x in d.ikkuShin)
        if (x.kukanJuni >= 1 && x.kukanJuni <= 10) x,
    ];
    final List<_Shin> hoka = [
      for (final _Shin x in joui)
        if (!kaita.contains(x.s.id)) x,
    ];
    if (hoka.isNotEmpty) {
      b.write(
        kaita.isEmpty
            ? '1区の区間10位以内からは、${hoka.length}人が大学へ進んだ。'
            : '1区の区間10位以内からは、ほかに${hoka.length}人が大学へ進んだ。',
      );
      final Map<int, int> kazu = {};
      for (final _Shin x in joui) {
        kazu[x.s.univid] = (kazu[x.s.univid] ?? 0) + 1;
      }
      final List<MapEntry<int, int>> l = kazu.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (l.isNotEmpty && l.first.value >= 2) {
        b.write('${daigakuMei(k.univ[l.first.key])}は、そのうち${l.first.value}人を迎えた。');
      }
    }
    if (b.isEmpty) return;
    w.danraku(b.toString());
    if (xw != null) {
      senshuKotoba(xw, _ikkuKotoba);
      if (midashi || w.r.kakuritsu(40)) koukouKantoku(xw.kou, _koukouKantokuIkku);
    }
  }

  /// 高校総体の段落
  void soutaiDan() {
    final StringBuffer b = StringBuffer();
    final List<KoukouKirokuSousha> f5 = d.soutai(1);
    final _Shin? w5 = soutaiW;
    final ({_Shin x, int juni})? jt = nihonjinTop;
    if (w5 != null && !w5.ryuugakusei) {
      final String u = d.univMei(w5);
      // 名前は候補を並べる前に1度だけ作る(候補ごとに呼ぶと、2つ目の候補が名字だけになるため。2.0.2)
      final String y5 = yobu(w5);
      b.write(w.erabu([
        '昨夏の高校総体5000mを制したのは、$y5だった。この春、$uに進んだ。',
        '$y5は昨夏、高校総体5000mで優勝し、$uに進んだ。',
      ]));
      if (f5.isNotEmpty) b.write('優勝タイムは${jikanMoji(f5.first.time)}。');
      if (identical(w5, top)) {
        b.write('持ちタイム世代トップが、夏の一発勝負でも頂点に立った。');
      } else if (w5.juni >= 3) {
        b.write(w.erabu([
          '持ちタイムでは世代${w5.juni + 1}番手ながら、夏の一発勝負を制した。',
          '持ちタイムは世代${w5.juni + 1}番手。この日は、その序列を覆した。',
        ]));
      }
      b.write(_maeKirokuBun(d, w5));
    } else if (w5 != null) {
      b.write('昨夏の高校総体5000mは、${w5.kou}の留学生${yobu(w5, kakko: '')}が制し、この春${d.univMei(w5)}に進んだ。');
    } else if (f5.isNotEmpty && !f5.first.namaeAri) {
      b.write('昨夏の高校総体5000mは、${_nanashiMei(d.rec!, f5.first)}が制した。');
    }
    if (jt != null) {
      final String yj = yobu(jt.x); // 名前は候補を並べる前に1度だけ作る(2.0.2)
      b.write(w.erabu([
        '日本人トップは${jt.juni}位の$yjで、${d.univMei(jt.x)}に進んだ。',
        '日本人トップの${jt.juni}位に入った$yjは、${d.univMei(jt.x)}へ。',
      ]));
    } else if (f5.isNotEmpty && (w5 == null || w5.ryuugakusei)) {
      // 優勝が新入生でなく、日本人トップも新入生でないときは、大学に進んだ日本人の最上位
      for (int i = 0; i < f5.length; i++) {
        final _Shin? x = d.shin(f5[i]);
        if (x == null || x.ryuugakusei) continue;
        b.write('大学に進んだ日本人では、${i + 1}位で${d.univMei(x)}に進んだ${yobu(x)}が最上位だった。');
        break;
      }
    }
    // 持ちタイム世代トップが5000mの決勝で優勝しなかったとき(出来事だけを書く)
    if (b.isNotEmpty && !identical(top, w5) && !identical(top, jt?.x)) {
      for (int i = 1; i < f5.length; i++) {
        final _Shin? x = d.shin(f5[i]);
        if (x != null && identical(x, top)) {
          final String yt = yobu(top); // 名前は候補を並べる前に1度だけ作る(2.0.2)
          b.write(w.erabu([
            'この日、持ちタイム世代トップの$ytは${i + 1}位にとどまった。雪辱の舞台は大学に移る。',
            '持ちタイム世代トップの$ytは、この日は${i + 1}位だった。',
          ]));
          break;
        }
      }
    }
    // 1500m・3000m障害の優勝
    final List<String> hoka = [];
    for (final int sh in const [0, 2]) {
      final _Shin? x = d.soutaiYuushou(sh);
      if (x == null) continue;
      hoka.add('${koukouShumokuMei[sh + 1]}は${d.univMei(x)}に進んだ${yobu(x)}');
    }
    if (hoka.isNotEmpty) {
      b.write(w.erabu([
        'ほかの種目では、${hoka.join('、')}が制した。',
        'トラックの頂点は5000mだけではない。${hoka.join('、')}が優勝した。',
      ]));
    }
    if (b.isEmpty) return;
    w.danraku(b.toString());
    if (w5 != null && !w5.ryuugakusei) {
      senshuKotoba(w5, kotobaKouho(w5));
    } else if (jt != null) {
      senshuKotoba(jt.x, _nihonjinTopKotoba);
    }
  }

  /// 13分台の人数の段落
  void kazuDan() {
    final int n = d.juusanSuu;
    final int e = d.juusanHeinen.round();
    final double z = d.juusanZure;
    final StringBuffer b = StringBuffer();
    b.write(w.erabu([
      '新入生のうち、5000mの持ちタイムが13分台の選手は$n人。',
      '持ちタイムが13分台の新入生は$n人だった。',
    ]));
    if (z >= 1.25) {
      b.write(w.erabu(['例年は$e人前後とされ、豊作の世代と言える。', '例年の$e人前後を大きく上回る、豊作の世代だ。']));
    } else if (z >= 0.6) {
      b.write('例年の$e人前後を、やや上回った。');
    } else if (z <= -1.25) {
      b.write(w.erabu(['例年の$e人前後を大きく下回った。', '例年は$e人前後とされ、13分台の少ない世代となった。']));
    } else if (z <= -0.6) {
      b.write('例年の$e人前後を、やや下回った。');
    } else {
      b.write(w.erabu(['例年の$e人前後と、ほぼ同じだ。', '例年並みの人数だ。']));
    }
    // 上の世代との比べ
    final List<_Ue> ue = d.ue;
    if (ue.length == 3 && ue.every((x) => x.top != null)) {
      b.write('今の2年生の世代は${ue[0].juusan}人、3年生は${ue[1].juusan}人、4年生は${ue[2].juusan}人だった。');
      final int mx = ue.map((x) => x.juusan).reduce((a, c) => a > c ? a : c);
      final int mn = ue.map((x) => x.juusan).reduce((a, c) => a < c ? a : c);
      if (n > mx) {
        b.write('上の3つの世代のどれよりも多い。');
      } else if (n < mn) {
        b.write('上の3つの世代のどれよりも少ない。');
      }
    }
    if (w.r.kakuritsu(50)) {
      final int m = d.nihon.where((x) => x.t < 860).length;
      b.write('14分20秒より速い選手まで広げると、$m人になる。');
    }
    w.danraku(b.toString());
  }

  /// 大学の補強の段落
  void hokyouDan() {
    final MapEntry<int, int>? e = hokyouUniv;
    if (e == null) return;
    final StringBuffer b = StringBuffer();
    final UnivData u = k.univ[e.key];
    final int mj = d.meiseiJuni(u.id);
    final int j13 = d.nihon.where((x) => x.s.univid == u.id && x.t < _juusan).length;
    if (e.value >= TEISUU.NINZUU_1GAKUNEN_INUNIV) {
      b.write('${daigakuMei(u)}は、新入生${e.value}人全員が世代上位$_jouiNinzuu人に入った。');
    } else {
      b.write(w.erabu([
        '大学別では、${daigakuMei(u)}が世代上位$_jouiNinzuu人のうち${e.value}人を獲得した。',
        '補強で目を引くのは${daigakuMei(u)}だ。世代上位$_jouiNinzuu人から${e.value}人を迎えた。',
      ]));
    }
    if (j13 >= 2) b.write('うち$j13人が13分台だ。');
    if (mj > 3) b.write('名声$mj位の大学にとっては、大きな補強となった。');
    // ほかに3人以上を獲った大学
    for (final MapEntry<int, int> o in hokyouJun) {
      if (o.key == u.id || o.value < 3) continue;
      b.write('${daigakuMei(k.univ[o.key])}も${o.value}人を加えた。');
      break;
    }
    b.write('上位$_jouiNinzuu人は、${hokyouJun.length}校に分かれた。');
    final int top3 = d.nihon.take(_jouiNinzuu).where((x) => d.meiseiJuni(x.s.univid) <= 3).length;
    b.write('名声上位3校には$top3人が入った。');
    w.danraku(b.toString());
  }

  /// 全国高校駅伝の優勝校の段落
  void yuushouDan() {
    final KoukouKirokuTeam? t = yuushouTeam;
    final List<({_Shin x, int kukan})> m = yuushouShin;
    if (t == null || m.isEmpty) return;
    final String kou = _kouMijikai(d.rec!.kouMei(t.kouCode));
    final StringBuffer b = StringBuffer();
    final String v = t.yuushouRenzoku >= 2 ? '${t.yuushouRenzoku}連覇を果たした' : '制した';
    b.write('昨冬の全国高校駅伝を$v$kouからは、${m.length}人が大学へ進んだ。');
    b.write('${[for (final e in m) '${e.kukan}区の${yobu(e.x, kakko: '')}は${d.univMei(e.x)}'].join('、')}。');
    final int us = {for (final e in m) e.x.s.univid}.length;
    if (m.length >= 2 && us == 1) {
      b.write('優勝メンバーがそろって同じ大学に進み、大学でもたすきをつなぐ。');
    } else if (m.length >= 3 && us == m.length) {
      b.write('優勝メンバーは、それぞれ別の大学で新たなスタートを切る。');
    }
    w.danraku(b.toString());
    if (w.r.kakuritsu(50)) koukouKantoku(kou, _koukouKantokuYuushou);
  }

  /// 同じ高校の同級生の段落
  void onajiDan() {
    final List<_Shin> l = onaji;
    if (l.length < 2) return;
    final String kou = l.first.kou;
    final String u = d.univMei(l.first);
    final String mei = [for (final _Shin x in l) yobu(x, kakko: '')].join(l.length == 2 ? 'と' : '、');
    final StringBuffer b = StringBuffer();
    b.write(w.erabu([
      '$kouの同級生${l.length}人は、そろって$uに進んだ。$mei${l.length >= 3 ? 'の${l.length}人' : 'の2人'}だ。',
      '$meiは、$kouで一緒に走った同級生だ。そろって$uに進み、大学でも同じチームで走る。',
    ]));
    if ((l.first.j?.mei?.meimon ?? 0) >= 3) b.write('$uは、名門の$kouから新戦力をまとめて迎えた形だ。');
    // 監督の母校でもあるとき(2.0.1。監督の母校パイプ)
    if (bokouOnaji) {
      final String? kt = kantokuYobi(l.first.s.univid);
      if (kt != null) b.write('$kouは、$uの$ktの母校でもある。');
    }
    w.danraku(b.toString());
  }

  /// 監督の母校から、その監督の大学に入った新入生の段落(2.0.1。監督の母校パイプ。事実だけを書く)
  void bokouDan() {
    final List<_Shin> l = bokou;
    if (l.isEmpty) return;
    final _Shin x = l.first;
    final String kou = x.kou;
    final String u = d.univMei(x);
    final String? kt = kantokuYobi(x.s.univid);
    if (kou.isEmpty || kt == null) return;
    final StringBuffer b = StringBuffer();
    if (l.length >= 2) {
      final String mei = [for (final _Shin y in l) yobu(y, kakko: '')].join(l.length == 2 ? 'と' : '、');
      b.write(w.erabu([
        '$uには、$ktの母校・$kouから、$meiの${l.length}人が入った。',
        '$kouの$meiは、そろって$uに進んだ。$kouは、$ktの母校だ。',
      ]));
      b.write(w.erabu(['監督にとっては、そろって母校の後輩にあたる。', '監督は、母校の後輩をまとめて迎えた形だ。']));
    } else {
      final String mei = yobu(x, kakko: '');
      b.write(w.erabu([
        '$uには、$ktの母校・$kouから$meiが入った。持ちタイムは${jikanMoji(x.t)}で、世代${x.juni + 1}番手だ。',
        '$meiは、$kouから$uに進んだ。持ちタイム${jikanMoji(x.t)}は世代${x.juni + 1}番手。$kouは、$ktの母校だ。',
      ]));
      b.write(w.erabu(['監督にとっては、母校の後輩にあたる。', '監督は、母校の後輩を迎えた形だ。']));
    }
    // ほかにも監督の母校から新入生を迎えた大学
    final int hoka = bokouBetsu.length - 1;
    if (hoka >= 1) b.write('ほかにも$hoka校が、監督の母校から新入生を迎えた。');
    w.danraku(b.toString());
  }

  /// ほかの競技の出身の段落
  void ishokuDan() {
    final _Shin? x = ishoku;
    final KoukouJouhou? j = x?.j;
    if (x == null || j == null) return;
    final String bu = koukouHokaKyougi(j);
    _jissekiZumi.add(x.s.id);
    // 名前は候補を並べる前に1度だけ作る(候補ごとに呼ぶと、2つ目の候補が名字だけになるため。2.0.2)。
    // どちらの候補も校名を文の中に書くので、名前のかっこは付けない
    final String yx = yobu(x, kakko: '');
    final String kouNo = x.kou.isNotEmpty ? '${x.kou}の' : '';
    w.danraku(w.erabu([
      '異色の経歴を持つ新入生もいる。${x.kou}時代は$buだった$yxは、持ちタイム${jikanMoji(x.t)}で${d.univMei(x)}に進んだ。'
          '世代では${x.juni + 1}番手だ。',
      '$kouNo${bu}出身の$yxは、陸上の大会の実績がないまま${d.univMei(x)}に進んだ。持ちタイムは${jikanMoji(x.t)}で、世代${x.juni + 1}番手だ。',
    ]));
    senshuKotoba(x, _ishokuKotoba);
  }

  /// 留学生の段落
  void ryuuDan() {
    final List<_Shin> l = d.ryuu;
    if (l.isEmpty) return;
    final List<String> us = [];
    for (final _Shin x in l) {
      final String u = d.univMei(x);
      if (!us.contains(u)) us.add(u);
    }
    final StringBuffer b = StringBuffer();
    b.write(w.erabu([
      '留学生は${l.length}人が加わった。${us.join('、')}が新たに迎えた。',
      '${us.join('、')}には、新たに留学生が入った。',
    ]));
    for (final _Shin x in l) {
      if (x.j == null || identical(x, soutaiW)) continue;
      b.write('${d.univMei(x)}の${yobu(x, kakko: '')}は、日本の${x.kou}で3年間を過ごした。');
      if (x.kukan >= 1 && x.kukanJuni == 1) b.write('全国高校駅伝では${x.kukan}区で区間賞を取っている。');
      break;
    }
    w.danraku(b.toString());
  }

  /// 自分の大学の段落(新入生がいなければ書かない)
  void jibunDan() {
    final UnivData? u = k.jibunUniv;
    if (u == null) return;
    final List<_Shin> l = [
      for (final _Shin x in d.nihon)
        if (x.s.univid == u.id) x,
    ];
    final int ryuu = d.ryuu.where((x) => x.s.univid == u.id).length;
    if (l.isEmpty && ryuu == 0) return;
    final String um = daigakuMei(u);
    final StringBuffer b = StringBuffer();
    if (l.isNotEmpty) {
      final _Shin x = l.first;
      final String yx = yobu(x); // 名前は候補を並べる前に1度だけ作る(2.0.2)
      b.write(w.erabu([
        '$umには${l.length + ryuu}人が入った。持ちタイムの最上位は、世代${x.juni + 1}番手の$yxで${jikanMoji(x.t)}。',
        '$umの新入生は${l.length + ryuu}人。最上位は${jikanMoji(x.t)}の$yxで、世代では${x.juni + 1}番手だ。',
      ]));
      final int c30 = l.where((y) => y.juni < _jouiNinzuu).length;
      final int c13 = l.where((y) => y.t < _juusan).length;
      if (c30 >= 2) b.write('世代上位$_jouiNinzuu人からは$c30人。');
      if (c13 >= 2) b.write('13分台は$c13人だ。');
      if (ryuu > 0) b.write('留学生も$ryuu人加わった。');
    } else {
      b.write('$umには、留学生$ryuu人が入った。');
    }
    w.danraku(b.toString());
  }
}

/// 期待のルーキーの見出し・リード・記者の目・表
extension _RookieMidashi on _Rookie {
  /// 見出しの型[g]で、最初に置く段落
  _Dan atamaDan(int g) {
    switch (g) {
      case _gSankan:
        return _Dan.sedai;
      case _gNikan:
        {
          final _Shin? x = nikan;
          if (x == null || identical(x, top)) return _Dan.sedai;
          return identical(x, ikkuW) ? _Dan.ikku : _Dan.soutai;
        }
      case _gIkku:
      case _gRival:
        return _Dan.ikku;
      case _gSoutai:
        return _Dan.soutai;
      case _gKazu:
        return _Dan.kazu;
      case _gHokyou:
        return _Dan.hokyou;
      case _gYuushou:
        return _Dan.yuushou;
      case _gOnaji:
        return _Dan.onaji;
      case _gIshoku:
        return _Dan.ishoku;
      default:
        return _Dan.sedai;
    }
  }

  /// 見出し(名前は「山田太郎」と書き、本文の名前の出し方には数えない)
  String midashiMoji(int g) {
    String mei(_Shin x) => fullMei(x.s.name);
    switch (g) {
      case _gSankan:
        {
          final _Shin x = sankan ?? top;
          final String u = d.univMei(x);
          midashiUnivId = x.s.univid;
          return w.erabu([
            '名実ともに世代の頂点　${mei(x)}が$uへ',
            '持ちタイム・1区・総体の三冠　${mei(x)}、$uで始動',
            '世代の頂点に立つ${mei(x)}、進学先は$u',
          ]);
        }
      case _gNikan:
        {
          final _Shin x = nikan ?? top;
          final List<String> sh = shougou(x);
          final String u = d.univMei(x);
          midashiUnivId = x.s.univid;
          if (sh.length < 2) return '世代トップ${jikanMoji(x.t)}の${mei(x)}、$uへ';
          return w.erabu([
            '${sh[0]}にして${sh[1]}　${mei(x)}が$uへ',
            '${sh[0]}と${sh[1]}の${mei(x)}、$uで始動',
          ]);
        }
      case _gIkku:
        {
          final _Shin x = ikkuW ?? top;
          final String u = d.univMei(x);
          midashiUnivId = x.s.univid;
          return w.erabu([
            '花の1区の覇者、$uへ　${mei(x)}',
            '高校駅伝1区区間賞の${mei(x)}、$uで始動',
            '1区を制した18歳が選んだのは$u',
          ]);
        }
      case _gRival:
        {
          final ({_Shin a, _Shin b, int sa})? rv = rival;
          if (rv == null) return midashiMoji(_gSedai);
          final String ua = d.univMei(rv.a);
          final String ub = d.univMei(rv.b);
          midashiUnivId = rv.a.s.univid == k.gh.MYunivid ? rv.a.s.univid : rv.b.s.univid;
          return w.erabu([
            '1区で${kinsaMoji(rv.sa)}の2人　今度は$uaと$ubでライバルに',
            '高校駅伝1区の激闘再び　${mei(rv.a)}は$ua、${mei(rv.b)}は$ubへ',
          ]);
        }
      case _gSoutai:
        {
          final _Shin? w5 = soutaiW;
          final ({_Shin x, int juni})? jt = nihonjinTop;
          if (w5 != null && !w5.ryuugakusei) {
            midashiUnivId = w5.s.univid;
            return w.erabu([
              '高校総体5000m覇者の${mei(w5)}、${d.univMei(w5)}へ',
              '夏の頂点に立った${mei(w5)}、${d.univMei(w5)}で始動',
            ]);
          }
          if (jt != null) {
            midashiUnivId = jt.x.s.univid;
            return w.erabu([
              '高校総体5000m日本人トップの${mei(jt.x)}、${d.univMei(jt.x)}へ',
              '総体5000m日本人トップの${mei(jt.x)}、進学先は${d.univMei(jt.x)}',
            ]);
          }
          if (w5 != null) {
            midashiUnivId = w5.s.univid;
            return '高校総体5000mを制した${w5.kou}の留学生、${d.univMei(w5)}へ';
          }
          return midashiMoji(_gSedai);
        }
      case _gKazu:
        {
          final int n = d.juusanSuu;
          final double z = d.juusanZure;
          if (z >= 0.6) {
            return w.erabu(['13分台$n人の豊作世代　各大学に新戦力', '新入生は13分台$n人　例年を上回る豊作']);
          }
          if (z <= -0.6) {
            return w.erabu(['13分台は$n人　例年を下回る世代、大学で伸びるのは誰か', '13分台$n人の新世代　横一線からの4年間']);
          }
          return w.erabu(['新入生の13分台は$n人　例年並みの世代', '13分台$n人の新世代　各大学に新戦力']);
        }
      case _gHokyou:
        {
          final MapEntry<int, int>? e = hokyouUniv;
          if (e == null) return midashiMoji(_gSedai);
          final String u = daigakuMei(k.univ[e.key]);
          midashiUnivId = e.key;
          return w.erabu([
            '$u、世代上位$_jouiNinzuu人から${e.value}人獲得',
            '新入生の補強は$uが一歩リード　上位$_jouiNinzuu人から${e.value}人',
          ]);
        }
      case _gYuushou:
        {
          final KoukouKirokuTeam? t = yuushouTeam;
          final List<({_Shin x, int kukan})> m = yuushouShin;
          if (t == null || m.isEmpty) return midashiMoji(_gSedai);
          final String kou = _kouMijikai(d.rec!.kouMei(t.kouCode));
          final Set<int> us = {for (final e in m) e.x.s.univid};
          if (m.length >= 2 && us.length == 1) {
            midashiUnivId = us.first;
            return '$kouの優勝メンバー${m.length}人、そろって${d.univMei(m.first.x)}へ';
          }
          return w.erabu([
            '高校駅伝V校の$kouから${m.length}人　それぞれの大学へ',
            '全国の頂点に立った$kouのメンバー、大学へ',
          ]);
        }
      case _gOnaji:
        {
          final List<_Shin> l = onaji;
          if (l.length < 2) return midashiMoji(_gSedai);
          final String u = d.univMei(l.first);
          midashiUnivId = l.first.s.univid;
          return w.erabu([
            '${l.first.kou}の同級生${l.length}人、そろって$uへ',
            '${l.first.kou}から$uへ　同級生${l.length}人が再び同じチームに',
          ]);
        }
      case _gIshoku:
        {
          final _Shin? x = ishoku;
          final KoukouJouhou? j = x?.j;
          if (x == null || j == null) return midashiMoji(_gSedai);
          final String bu = koukouHokaKyougi(j);
          midashiUnivId = x.s.univid;
          return w.erabu([
            '$bu出身の${mei(x)}、${d.univMei(x)}で陸上の道へ',
            '異色の経歴　$bu出身の${mei(x)}が${d.univMei(x)}に入学',
          ]);
        }
      default:
        {
          final _Shin x = top;
          final String u = d.univMei(x);
          final String t = jikanMoji(x.t);
          final int mj = d.meiseiJuni(x.s.univid);
          midashiUnivId = x.s.univid;
          final List<String> tokubetsu = [
            if (x.t < 805) '10年に1人級の$t　${mei(x)}が$uへ',
            if (mj >= 15) '名声$mj位の$uに世代トップ　${mei(x)}が入学',
          ];
          if (tokubetsu.isNotEmpty) return w.erabu(tokubetsu);
          return w.erabu([
            '世代トップ$tの${mei(x)}、$uへ',
            '$tの大物ルーキー、$uに入学',
            '新入生の持ちタイムトップは${mei(x)}　$uへ',
          ]);
        }
    }
  }

  /// リード(記者の型の書き出しと、見出しの事実)
  String leadMoji(int g, KishaKata kata) {
    final StringBuffer b = StringBuffer();
    switch (kata) {
      case KishaKata.suuji:
        b.write(w.erabu([
          if (g != _gKazu) '新入生${d.nihon.length + d.ryuu.length}人のうち、5000mの持ちタイムが13分台の選手は${d.juusanSuu}人。',
          if (g != _gSedai && g != _gSankan && g != _gNikan) '新入生の持ちタイムの世代トップは${jikanMoji(top.t)}。',
          if (g != _gHokyou) '世代上位$_jouiNinzuu人の新入生は、${hokyouJun.length}校に分かれた。',
        ]));
      case KishaKata.joukei:
        b.write(w.erabu([
          '桜の便りとともに、各大学に新しい顔がそろった。',
          '新しいジャージに袖を通した18歳たちが、各大学のグラウンドに集まった。',
          '春、大学の長距離界に新しい世代がやって来た。',
        ]));
      case KishaKata.karakuchi:
        {
          final int top3 = d.nihon.take(_jouiNinzuu).where((x) => d.meiseiJuni(x.s.univid) <= 3).length;
          b.write(
            top3 >= 11
                ? '世代上位$_jouiNinzuu人のうち$top3人を、名声上位3校が占めた。戦力の差は、簡単には縮まりそうにない。'
                : '世代上位$_jouiNinzuu人のうち、名声上位3校に入ったのは$top3人。有力な新入生は各大学に分かれた。',
          );
        }
    }
    b.write(_leadJijitsu(g));
    return b.toString();
  }

  String _leadJijitsu(int g) {
    switch (g) {
      case _gSankan:
        {
          final _Shin x = sankan ?? top;
          return '持ちタイム世代トップで、全国高校駅伝1区の区間賞、高校総体5000mの'
              '${soutaiNihonYuushou ? '優勝' : '日本人トップ'}もそろえた${yobu(x)}は、${d.univMei(x)}に進んだ。';
        }
      case _gNikan:
        {
          final _Shin x = nikan ?? top;
          final List<String> sh = shougou(x);
          if (sh.length < 2) return '持ちタイム世代トップの${yobu(x)}は、${d.univMei(x)}に進んだ。';
          return '${sh[0]}で${sh[1]}の${yobu(x)}は、${d.univMei(x)}に進んだ。';
        }
      case _gIkku:
        {
          final _Shin x = ikkuW ?? top;
          return '昨冬の全国高校駅伝で1区の区間賞を取った${yobu(x)}は、${d.univMei(x)}に進んだ。';
        }
      case _gRival:
        {
          final ({_Shin a, _Shin b, int sa})? rv = rival;
          if (rv == null) return _leadJijitsu(_gSedai);
          return '昨冬の全国高校駅伝の1区で${kinsaMoji(rv.sa)}を争った${yobu(rv.a)}と${yobu(rv.b)}は、'
              '${d.univMei(rv.a)}と${d.univMei(rv.b)}に分かれて進んだ。';
        }
      case _gSoutai:
        {
          final _Shin? w5 = soutaiW;
          final ({_Shin x, int juni})? jt = nihonjinTop;
          if (w5 != null && !w5.ryuugakusei) return '昨夏の高校総体5000mを制した${yobu(w5)}は、${d.univMei(w5)}に進んだ。';
          if (jt != null) return '昨夏の高校総体5000mで日本人トップだった${yobu(jt.x)}は、${d.univMei(jt.x)}に進んだ。';
          if (w5 != null) return '昨夏の高校総体5000mを制した${w5.kou}の留学生${yobu(w5, kakko: '')}は、${d.univMei(w5)}に進んだ。';
          return _leadJijitsu(_gSedai);
        }
      case _gKazu:
        {
          final int e = d.juusanHeinen.round();
          final double z = d.juusanZure;
          final String hikaku = z >= 0.6 ? 'を上回った' : (z <= -0.6 ? 'を下回った' : 'とほぼ同じだった');
          return '13分台は${d.juusanSuu}人で、例年の$e人前後$hikaku。';
        }
      case _gHokyou:
        {
          final MapEntry<int, int>? e = hokyouUniv;
          if (e == null) return _leadJijitsu(_gSedai);
          return '${daigakuMei(k.univ[e.key])}が世代上位$_jouiNinzuu人のうち${e.value}人を獲得し、補強で一歩リードした。';
        }
      case _gYuushou:
        {
          final KoukouKirokuTeam? t = yuushouTeam;
          if (t == null || yuushouShin.isEmpty) return _leadJijitsu(_gSedai);
          return '全国高校駅伝を制した${_kouMijikai(d.rec!.kouMei(t.kouCode))}のメンバー${yuushouShin.length}人も、'
              '大学で新たなスタートを切る。';
        }
      case _gOnaji:
        {
          final List<_Shin> l = onaji;
          if (l.length < 2) return _leadJijitsu(_gSedai);
          return '${l.first.kou}の同級生${l.length}人は、そろって${d.univMei(l.first)}に進んだ。';
        }
      case _gIshoku:
        {
          final _Shin? x = ishoku;
          final KoukouJouhou? j = x?.j;
          if (x == null || j == null) return _leadJijitsu(_gSedai);
          return '${koukouHokaKyougi(j)}出身という異色の経歴を持つ${yobu(x, kakko: '')}も、${d.univMei(x)}で陸上の道を歩み始める。';
        }
      default:
        return '持ちタイム世代トップの${yobu(top)}は、${d.univMei(top)}に進んだ。';
    }
  }

  /// 段落を書く
  void dan(_Dan dn, {required bool midashi}) {
    switch (dn) {
      case _Dan.sedai:
        sedaiDan();
      case _Dan.ikku:
        ikkuDan(midashi: midashi);
      case _Dan.soutai:
        soutaiDan();
      case _Dan.kazu:
        kazuDan();
      case _Dan.hokyou:
        hokyouDan();
      case _Dan.yuushou:
        yuushouDan();
      case _Dan.onaji:
        onajiDan();
      case _Dan.ishoku:
        ishokuDan();
      case _Dan.ryuu:
        ryuuDan();
      case _Dan.bokou:
        bokouDan();
    }
  }

  /// 記者の目
  void kishaNoMe(KishaKata kata) {
    switch (kata) {
      case KishaKata.suuji:
        w.kishaNoMe(
          '13分台${d.juusanSuu}人、世代上位$_jouiNinzuu人は${hokyouJun.length}校に分かれた。'
          '持ちタイムは、高校までの物差しにすぎない。大学の距離で、この数字がどう変わっていくかを追いたい。',
        );
      case KishaKata.joukei:
        w.kishaNoMe(w.erabu([
          '高校の記録は、ここで一度まっさらになる。4年後、この中の誰が主役になっているか。春は、まだ始まったばかりだ。',
          '高校でたすきをつないだ仲間が、今度はライバルになる。新しい物語が、この春から始まる。',
        ]));
      case KishaKata.karakuchi:
        w.kishaNoMe(
          '持ちタイムは高校までの物差しだ。大学の距離に移れば、序列が入れ替わることも珍しくない。'
          '名前だけで期待するのは、まだ早い。',
        );
    }
  }

  /// 持ちタイム上位10人の表
  KijiHyou jouiHyou() {
    return KijiHyou(
      '新入生の5000m持ちタイム上位10人',
      ['順位', '選手', '大学', '5000m', if (d.koukouAri) '出身校'],
      [
        for (final _Shin x in d.nihon.take(10))
          [
            '${x.juni + 1}',
            fullMei(x.s.name),
            d.univMei(x),
            jikanMoji(x.t),
            if (d.koukouAri) x.j == null ? '' : koukouMeiKenMoji(x.j!),
          ],
      ],
    );
  }

  /// 全国高校駅伝の1区の表(上位3人と、大学に進んだ10位以内の選手。記録がなければnull)
  KijiHyou? ikkuHyou() {
    final KoukouTaikaiKiroku? r = d.rec;
    if (r == null) return null;
    final List<({int juni, List<String> gyou})> l = [];
    final Set<int> ireta = {};
    final List<KoukouKirokuSousha> j = d.ikkuJoui;
    for (int i = 0; i < j.length; i++) {
      final KoukouKirokuSousha y = j[i];
      final _Shin? x = d.shin(y);
      if (x != null) ireta.add(x.s.id);
      l.add((
        juni: i + 1,
        gyou: [
          '${i + 1}',
          x != null ? fullMei(x.s.name) : (y.namaeAri ? fullMei(y.name) : '${y.gakunen}年生'),
          _kouMijikai(r.kouMei(y.kouCode)),
          x != null ? d.univMei(x) : '－',
          jikanMoji(y.time),
        ],
      ));
    }
    for (final _Shin x in d.ikkuShin) {
      if (ireta.contains(x.s.id) || x.kukanJuni < 1 || x.kukanJuni > 10) continue;
      l.add((
        juni: x.kukanJuni,
        gyou: [
          '${x.kukanJuni}',
          fullMei(x.s.name),
          x.kou,
          d.univMei(x),
          x.kukanTime == null ? '' : jikanMoji(x.kukanTime!),
        ],
      ));
    }
    if (l.isEmpty) return null;
    l.sort((a, b) => a.juni.compareTo(b.juni));
    return KijiHyou(
      '昨冬の全国高校駅伝の1区(上位3人と、大学に進んだ10位以内の選手)',
      ['区間順位', '選手', '高校', '大学', 'タイム'],
      [for (final e in l) e.gyou],
    );
  }

  /// 大学別の補強の表(世代上位30人を獲った大学)
  KijiHyou hokyouHyou() {
    return KijiHyou(
      '大学別の新入生(世代上位$_jouiNinzuu人の人数)',
      ['大学', '名声', '上位$_jouiNinzuu人', '13分台', '最上位'],
      [
        for (final MapEntry<int, int> e in hokyouJun)
          () {
            final _Shin best = d.nihon.firstWhere((x) => x.s.univid == e.key);
            return [
              daigakuMei(k.univ[e.key]),
              '${d.meiseiJuni(e.key)}位',
              '${e.value}',
              '${d.nihon.where((x) => x.s.univid == e.key && x.t < _juusan).length}',
              '${fullMei(best.s.name)}(${best.juni + 1}番手)',
            ];
          }(),
      ],
    );
  }
}

/// 箱庭スポーツの「期待のルーキー」(4月5日。新入生がいなければ空)
List<Kiji> shinnyuuseiKiji(KijiKankyou k) {
  final _Shiryou? d = _shiryouTsukuru(k);
  if (d == null) return [];
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, _no));
  final KishaKata kata = k.kishaKata(_no);
  final _Rookie r = _Rookie(d, w);

  // 見出しの型の候補(点に少しだけ乱数を足し、近い点なら年によって入れ替わるようにする)
  final List<({int g, int ten})> kouho = [];
  void ire(int g, int ten) {
    if (ten > 0) kouho.add((g: g, ten: ten + w.r.ikutsu(10)));
  }

  if (r.sankan != null) {
    ire(_gSankan, 150);
  } else if (r.nikan != null) {
    ire(_gNikan, 120);
  }
  if (r.ikkuW != null) ire(_gIkku, 85);
  if (r.rival != null) ire(_gRival, 75);
  ire(_gSedai, r.sedaiTen);
  if (r.soutaiW != null || r.nihonjinTop != null) ire(_gSoutai, r.soutaiTen);
  ire(_gKazu, r.kazuTen);
  if (r.hokyouTen >= 45) ire(_gHokyou, r.hokyouTen);
  if (r.yuushouTen >= 45) ire(_gYuushou, r.yuushouTen);
  if (r.onajiTen >= 40) ire(_gOnaji, r.onajiTen);
  if (r.ishokuTen > 0) ire(_gIshoku, r.ishokuTen);
  kouho.sort((a, b) => b.ten.compareTo(a.ten));
  // 前の年と同じ型なら、2番目の観点を見出しにする(三冠はめったにないので、続いてもそのまま)
  final int? mae = KijiMidashiKiroku.maeNoKata(k, shinnyuuseiMidashiIndex, d.nendo);
  int g = kouho.first.g;
  if (g == mae && g != _gSankan && kouho.length >= 2) g = kouho[1].g;
  KijiMidashiKiroku.nokosu(k, shinnyuuseiMidashiIndex, d.nendo, mae, g);

  final String midashi = r.midashiMoji(g);
  final String lead = r.leadMoji(g, kata);

  // 段落の順(見出しの段落が先頭。ほかは点に乱数を足した順。世代トップと1区はいつも入れる)
  final _Dan atama = r.atamaDan(g);
  final Map<_Dan, int> ten = {
    _Dan.sedai: r.sedaiTen,
    if (r.ikkuAri) _Dan.ikku: r.ikkuTen,
    if (r.soutaiTen > 0) _Dan.soutai: r.soutaiTen,
    _Dan.kazu: r.kazuTen,
    if (r.hokyouTen > 0) _Dan.hokyou: r.hokyouTen,
    if (r.yuushouTen > 0) _Dan.yuushou: r.yuushouTen,
    if (r.onajiTen > 0) _Dan.onaji: r.onajiTen,
    if (r.ishokuTen > 0) _Dan.ishoku: r.ishokuTen,
    if (r.ryuuTen > 0) _Dan.ryuu: r.ryuuTen,
    if (r.bokouTen > 0) _Dan.bokou: r.bokouTen,
  };
  final Map<_Dan, int> jun = {for (final MapEntry<_Dan, int> e in ten.entries) e.key: e.value + w.r.ikutsu(20)};
  bool kanarazu(_Dan x) => x == _Dan.sedai || x == _Dan.ikku;
  final List<_Dan> nokori = [
    for (final MapEntry<_Dan, int> e in ten.entries)
      if (e.key != atama && (kanarazu(e.key) || (e.key != _Dan.ryuu && e.value >= 45))) e.key,
  ]..sort((a, b) => jun[b]!.compareTo(jun[a]!));
  // 多すぎるときは、後ろ(点の低いもの)から外す
  while (nokori.length > 5) {
    final int i = nokori.lastIndexWhere((x) => !kanarazu(x));
    if (i < 0) break;
    nokori.removeAt(i);
  }
  // 段落が少ない年は、留学生の段落も入れる
  if (nokori.length < 4 && ten.containsKey(_Dan.ryuu) && atama != _Dan.ryuu) nokori.add(_Dan.ryuu);
  // 1区の段落は2〜4番目に
  final int ii = nokori.indexOf(_Dan.ikku);
  if (ii > 2) {
    nokori.removeAt(ii);
    nokori.insert(2, _Dan.ikku);
  }
  final List<_Dan> narabi = [atama, ...nokori];
  for (final _Dan dn in narabi) {
    r.dan(dn, midashi: dn == atama);
  }
  r.jibunDan();
  r.kishaNoMe(kata);

  final KijiHyou? ikkuHyou = narabi.contains(_Dan.ikku) ? r.ikkuHyou() : null;
  return [
    Kiji(
      category: kijiShinnyuuseiCategory,
      midashi: midashi,
      lead: lead,
      honbun: w.honbun,
      hyou: [
        r.jouiHyou(),
        if (ikkuHyou != null) ikkuHyou,
        if (narabi.contains(_Dan.hokyou) && r.hokyouJun.isNotEmpty) r.hokyouHyou(),
      ],
      haishin: k.haishinMei(_no, asa: true),
      kisha: k.kishaMei(_no),
      jibun: r.midashiUnivId != null && r.midashiUnivId == k.gh.MYunivid,
      kekka: false,
    ),
  ];
}

// ------------------------------------------------------------
// 学内メディア「新入生紹介号」
// ・自分の大学の新入生を1人ずつ紹介する。紹介の書き出しを、持ちタイムから・出身校から・
//   出身地と趣味から・本人の言葉からの4つの形で人ごとに変える(同じ形が続かないように。少ない形を先に)
// ・部内の持ちタイム(5000mの自己ベスト)の順位が10番目までなら、メンバー争いに触れる(見えている順位だけから書く)
// ------------------------------------------------------------

/// 学内メディアの「新入生紹介号」(4月5日。自分の大学に新入生がいなければ空)
List<Kiji> shinnyuuseiGakunaiKiji(KijiKankyou k) {
  final String? site = gakunaiSiteMeiJibun(k);
  final UnivData? u = k.jibunUniv;
  if (site == null || u == null) return [];
  final _Shiryou? d = _shiryouTsukuru(k);
  if (d == null) return [];
  final List<_Shin> shin = [
    for (final _Shin x in d.nihon)
      if (x.s.univid == u.id) x,
    for (final _Shin x in d.ryuu)
      if (x.s.univid == u.id) x,
  ];
  if (shin.isEmpty) return [];
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, _noGakunai));
  final String kisha = gakunaiKishaMei(k, site, _noGakunai);
  // 学生記者の型(学内メディアは選手に寄り添うので、辛口はなし。kiji_gakunai.dart と同じ)
  final KishaKata kata0 = kishaKataKara(kisha);
  final KishaKata kata = kata0 == KishaKata.karakuchi ? KishaKata.joukei : kata0;
  final _Rookie r = _Rookie(d, w);
  final int n = shin.length;
  final List<_Shin> nihon = [
    for (final _Shin x in shin)
      if (!x.ryuugakusei) x,
  ];

  // 部内の5000mの持ちタイムの順位(全部員の自己ベストから。1〜。持ちタイムがなければ0)
  final List<SenshuData> buin = [
    for (final SenshuData s in k.senshu)
      if (s.univid == u.id && s.gakunen >= 1 && s.gakunen <= 4 && k.jikoBest(s, 0) < TEISUU.DEFAULTTIME) s,
  ]..sort((a, b) {
      final int c = k.jikoBest(a, 0).compareTo(k.jikoBest(b, 0));
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  int buinJuni(SenshuData s) {
    final int i = buin.indexWhere((x) => x.id == s.id);
    return i < 0 ? 0 : i + 1;
  }

  final String midashi = w.erabu([
    'ようこそ、陸上競技部へ　新入生$n人を紹介',
    '新入生紹介号　$n人の新しい仲間',
    '春、$n人がたすきの輪に　新入生紹介',
  ]);
  final StringBuffer lead = StringBuffer();
  lead.write(w.erabu([
    'この春、陸上競技部に$n人の新入生が加わった。',
    '陸上競技部に、新しい仲間がやって来た。新入生は$n人だ。',
  ]));
  if (nihon.isNotEmpty) {
    final _Shin t = nihon.first;
    lead.write('持ちタイムの最上位は、世代${t.juni + 1}番手の${fullMei(t.s.name)}で${jikanMoji(t.t)}。');
    final int c13 = nihon.where((x) => x.t < _juusan).length;
    final int c30 = nihon.where((x) => x.juni < _jouiNinzuu).length;
    if (c13 > 0) lead.write('13分台は$c13人。');
    if (c30 > 0) lead.write('世代上位$_jouiNinzuu人からは$c30人が入部した。');
  }
  lead.write(w.erabu(['一人ずつ紹介する。', '新しい仲間を、一人ずつ紹介する。']));

  // 1人ずつ(紹介の形: 0持ちタイムから・1出身校から・2出身地と趣味から・3本人の言葉から)
  int maeKatachi = -1;
  final List<int> tsukattaKatachi = [0, 0, 0, 0];
  for (final _Shin x in shin) {
    final SenshuData s = x.s;
    final String yobi = myouji(s.name);
    final String? ken = k.shusshin(s);
    final String? shumi = k.shumi(s);
    final KoukouJouhou? j = x.j;
    w.koMidashi(w.senshu(s));
    final List<int> dekiru = [
      if (!x.ryuugakusei) 0,
      if (j != null) 1,
      if (ken != null || shumi != null) 2,
      3,
    ];
    List<int> kouho = [
      for (final int c in dekiru)
        if (c != maeKatachi) c,
    ];
    if (kouho.isEmpty) kouho = dekiru;
    final int sukunai = kouho.map((c) => tsukattaKatachi[c]).reduce((a, b) => a < b ? a : b);
    kouho = [
      for (final int c in kouho)
        if (tsukattaKatachi[c] == sukunai) c,
    ];
    final int katachi = w.r.erabu(kouho);
    maeKatachi = katachi;
    tsukattaKatachi[katachi]++;

    String tBun() {
      if (x.ryuugakusei) return w.erabu(['留学生として入部した。', '海を渡って、陸上競技部の一員になった。']);
      final int bj = buinJuni(s);
      final StringBuffer t = StringBuffer();
      t.write(w.erabu([
        '入学時の5000mは${jikanMoji(x.t)}で、世代では${x.juni + 1}番手。',
        '5000mの持ちタイムは${jikanMoji(x.t)}。世代${x.juni + 1}番手の記録だ。',
      ]));
      if (bj >= 1 && bj <= 3) {
        t.write(w.erabu(['部内の持ちタイムでは、いきなり$bj番目に名を連ねる。', '部内でも早くも$bj番目の持ちタイムだ。']));
      } else if (bj >= 4 && bj <= 10) {
        t.write(w.erabu([
          '部内の持ちタイムでも$bj番目で、1年目から駅伝メンバー争いに加わりそうだ。',
          '部内では$bj番目の持ちタイム。上級生とのメンバー争いが楽しみだ。',
        ]));
      }
      return t.toString();
    }

    String kouBun() {
      final KoukouJouhou? jj = j;
      if (jj == null) return '';
      final String jisseki = koukouJissekiBun(jj);
      final String mae = _maeKirokuBun(d, x);
      if (x.ryuugakusei) {
        return '日本の${koukouMeiKenMoji(jj)}で3年間を過ごした。${jisseki.isEmpty ? '' : '高校時代は、$jisseki。'}$mae';
      }
      final String moto = w.erabu([
        '${koukouMeiKenMoji(jj)}出身。${jisseki.isEmpty ? '' : '高校時代は、$jisseki。'}',
        '母校は${koukouMeiKenMoji(jj)}。${jisseki.isEmpty ? '' : '$jisseki。'}',
      ]);
      return '$moto$mae';
    }

    String kenShumiBun() {
      if (ken != null && shumi != null) {
        return w.erabu(['$ken出身で、趣味は「$shumi」。', '$ken出身。オフの日は「$shumi」で気分を切り替えるという。']);
      }
      if (ken != null) return '$ken出身。';
      if (shumi != null) return '趣味は「$shumi」。';
      return '';
    }

    final String honbun;
    switch (katachi) {
      case 1:
        honbun = '${kouBun()}${tBun()}${kenShumiBun()}';
      case 2:
        honbun = '${kenShumiBun()}${tBun()}${kouBun()}';
      default:
        honbun = '${tBun()}${kouBun()}${kenShumiBun()}';
    }
    final String comment = '「${w.erabu(r.kotobaKouho(x))}」と$yobiは${w.erabu(_senshuShime)}。';
    if (katachi == 3) {
      w.comment(comment);
      w.danraku(honbun);
    } else {
      w.danraku(honbun);
      w.comment(comment);
    }
  }

  // 監督の言葉(自分の大学の監督。総監督の言葉は作らない)
  final ({String name, int nenrei})? kt = k.kantokuMei(u.id);
  if (kt != null) {
    w.comment('「${w.erabu(_jibunKantokuKotoba)}」と${w.hito('K${u.id}', kt.name, '', '')}監督(${kt.nenrei})は${w.erabu(_kantokuShime)}。');
  }
  // 新しい年度の主将(2.0.2。4月上旬の最新画面に出す主将と同じ。文で主将と書くので、かっこに「・主将」は付けない)
  final int? shushouId = k.shushouId[u.id];
  SenshuData? shushou;
  if (shushouId != null) {
    for (final SenshuData s in k.senshu) {
      if (s.id == shushouId) shushou = s;
    }
  }
  if (shushou != null) {
    // (名前は先に作っておく。erabu は候補を全部作ってから選ぶので、候補の中で呼ぶと名前を出したことになるため)
    final String mei = w.hito('S${shushou.id}', shushou.name, '${shushou.gakunen}年', '');
    // 3年生のときから続けて主将なら「昨季に続き」(前の年度の主将の記録があるときだけ分かる)
    final bool tsuzuke =
        shushou.gakunen == 4 &&
        shushouNendoRetsu(k.kantoku, shushou, choukiNendo(k.gh)).length >= 2;
    w.danraku(
      tsuzuke
          ? w.erabu([
              '昨季に続き、主将は$meiが務める。新しい仲間を加えたチームで、新しいシーズンに挑む。',
              '主将は、昨季に続いて$meiが務める。新入生とともに、チームは新しいシーズンへ踏み出す。',
            ])
          : w.erabu([
              '新チームの主将は$meiが務める。新しい仲間を加えたチームで、新しいシーズンに挑む。',
              '新しいシーズン、チームを率いる主将は$meiだ。新入生とともに、チームは新たな一歩を踏み出す。',
            ]),
    );
  }
  // 編集部の目(学生記者の型で変える)
  final int nyuu10 = nihon.where((x) {
    final int bj = buinJuni(x.s);
    return bj >= 1 && bj <= 10;
  }).length;
  if (kata == KishaKata.suuji && nihon.isNotEmpty) {
    w.kishaNoMe(
      '新入生$n人のうち、部内の5000mの持ちタイムで10番目までに入ったのは$nyuu10人。'
      '上級生とのメンバー争いが、チームをさらに強くするはずだ。',
      midashi: '編集部の目',
    );
  } else {
    w.kishaNoMe(
      w.erabu([
        '新しい仲間が加わり、グラウンドに活気があふれている。4年後、この中から誰がチームの柱になっているだろうか。',
        '高校の記録は、ここで一度リセットされる。先輩たちの背中を追う4年間が、今日から始まる。',
      ]),
      midashi: '編集部の目',
    );
  }
  w.danraku(w.erabu([
    '新入生の皆さん、ようこそ。編集部は、これからの4年間を追い続けます。',
    '新入生の皆さん、入部おめでとうございます。4年間の歩みを、編集部も一緒に追いかけます。',
  ]));

  return [
    Kiji(
      category: kijiShinnyuuseiGakunaiCategory,
      midashi: midashi,
      lead: lead.toString(),
      honbun: w.honbun,
      hyou: [
        KijiHyou(
          '新入生一覧',
          ['選手', '5000m', '世代', '部内', if (d.koukouAri) '出身校'],
          [
            for (final _Shin x in shin)
              [
                fullMei(x.s.name),
                x.ryuugakusei ? '－' : jikanMoji(x.t),
                x.ryuugakusei ? '－' : '${x.juni + 1}番手',
                buinJuni(x.s) > 0 ? '${buinJuni(x.s)}番目' : '－',
                if (d.koukouAri) x.j == null ? '' : koukouMeiKenMoji(x.j!),
              ],
          ],
        ),
      ],
      haishin: k.haishinMei(_noGakunai, asa: true),
      kisha: kisha,
      jibun: true,
      kekka: false,
      site: site,
      gakunai: true,
    ),
  ];
}
