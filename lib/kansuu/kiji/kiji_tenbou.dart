import 'dart:math' as math; // 持ちタイムの換算(距離の比の1.06乗)
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/ikku_pace.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_comment.dart';

// ------------------------------------------------------------
// 展望の記事(1.9.2。直前順位予想の画面の「展望記事」)
//
// 区間エントリーが出そろったあとの、レース当日の朝の記事。公開されている情報
// (持ちタイム・過去の成績・区間エントリー・1区のペース予想・予想陣の予想)だけで書く
//
// 戦力の見方(本紙の戦力分析)
//  ・チームの平均: 駅伝は一次エントリーの上位(区間の数の人数)、11月駅伝予選は走る8人、
//    正月駅伝予選は上位10人の、区間の距離に合わせた持ちタイムの平均(1.9.2)
//    ・区間を距離で分け(7.5km以下は5000m、15km以下は1万m、それより長いとハーフ)、
//      区間の距離の合計で3つの種目の重みを出す(tenbouOmomi)
//    ・選手ごとに、3つの種目の持ちタイムを重みが一番大きい種目(主な種目)に換算して、
//      重みで平均する(tenbouSougouTime)。記録がない種目は、距離の近いほかの種目の記録から換算する
//      (tenbouMochiTime。換算は区間配置の見積もりと同じく距離の比の1.06乗)
//    ・重みが1つの種目だけなら「ハーフ平均」、混ざっていれば「1万m換算平均」のように書く。
//      今のコースなら11月駅伝予選は1万m、正月駅伝予選はハーフだけになる
//    ・主な種目が1万m以外のときは、参考に1万m平均も表に出す
//  ・区間ごとの持ちタイム(駅伝): 区間ごとに、距離と特徴に合った種目(kukanShumoku)の
//    持ちタイムで、その区間を走る選手を並べた順位の合計
//  ・前評判: 駅伝は2つの順位の合計、予選はチームの平均の順
//
// 記事(出せるものだけ並べる)
//  駅伝: 1.優勝争い 2.自分の大学 3.区間の見どころ(1区のペース予想も)
//        4.シード権争い(11月駅伝は上位8校、正月駅伝は上位10校) 5.当日変更の読み(全体の持ちタイム上位の選手が補欠のとき)
//  予選: 1.通過争い 2.注目選手(組ごと・個人) 3.自分の大学
//
// スタート直前号(1.9.2。目標順位の確認の画面の「スタート直前号」。駅伝の1区のスタート前だけ)
//  当日変更(コンピュータの大学の戦略的変更を含む)のあとの、実際に走る選手で書く。
//  チームの平均は走る選手で出し、1区のペース予想には当日の調子を入れる。言い回しの乱数は展望と分ける
//  記事: 1.当日変更の結果 2.優勝争い 3.自分の大学 4.区間の見どころ 5.シード権争い
//
// 1.9.4: 選手の因縁(kiji_kihon.dart の senshuInnen。レース前は kekka: false)を、自分の大学の
//  注目選手・エースのコメント・各区間の持ちタイム1位の紹介に入れる。当日変更の記事と自分の大学の
//  当日変更には、外れた理由(体調不良・調子)と温存していたエースの投入(ToujituJijou)を書く。
//  自分の大学の記事の最後に、記者の型で見方が変わる「本紙の見立て」を付ける
// ------------------------------------------------------------

/// 予想陣(直前順位予想の画面の3人)の予想
class KijiYosouJin {
  /// 名前(「オッシー」)
  final String mei;

  /// 予想の特徴(「基本走力重視」)
  final String tokuchou;

  /// 予想の順の大学id
  final List<int> univJun;

  /// 区間(組)ごとの区間賞予想の選手id(正月駅伝予選は個人1位予想の1つ)
  final List<int> kukanshou;

  const KijiYosouJin(this.mei, this.tokuchou, this.univJun, this.kukanshou);
}

/// 展望の、大学1校分
class TenbouUniv {
  final UnivData u;

  /// 一次エントリーの選手(エントリーしていない選手は入らない)
  final List<SenshuData> ichiji = [];

  /// 走る予定の選手(区間・組に入っている選手)
  final List<SenshuData> hashiru = [];

  /// チームの平均(Tenbou.heikinShumoku の種目。出せないときは TEISUU.DEFAULTTIME)
  double heikin = TEISUU.DEFAULTTIME;

  /// チームの平均の順位(0が1位)
  int heikinJuni = 0;

  /// 参考の1万m平均(主な種目が1万m以外のときだけ。出せないときは TEISUU.DEFAULTTIME)
  double sankouIchiman = TEISUU.DEFAULTTIME;

  /// 区間ごとの持ちタイムの順位の合計(駅伝)
  int kukanTen = 0;

  /// 区間ごとの持ちタイムの順位の合計の順位(駅伝。0が1位)
  int kukanJuni = 0;

  /// 前評判の順位(0が1位)
  int juni = 0;

  TenbouUniv(this.u);

  String get mei => daigakuMei(u);
}

/// 種目(time_bestkiroku の0〜2)の距離(m。持ちタイムの換算に使う)
const List<double> _shumokuKyori = [5000.0, 10000.0, 21097.5];

/// 選手の種目[idx](0=5000m・1=1万m・2=ハーフ)の持ちタイム(1.9.2)
/// 記録がなければ、距離の近いほかの種目の記録から換算する(区間配置の見積もり
/// (kukan_haichi.dart)と同じく、距離の比の1.06乗を掛ける)。どれもなければnull
double? tenbouMochiTime(KijiKankyou k, SenshuData s, int idx) {
  final int i = (idx < 0 || idx > 2) ? 1 : idx;
  final double t = k.jikoBest(s, i);
  if (t < TEISUU.DEFAULTTIME) return t;
  final List<int> kouho = [0, 1, 2]
    ..remove(i)
    ..sort(
      (a, b) => (_shumokuKyori[a] - _shumokuKyori[i]).abs().compareTo(
        (_shumokuKyori[b] - _shumokuKyori[i]).abs(),
      ),
    );
  for (final int c in kouho) {
    final double tc = k.jikoBest(s, c);
    if (tc < TEISUU.DEFAULTTIME) {
      return tc *
          math.pow(_shumokuKyori[i] / _shumokuKyori[c], 1.06).toDouble();
    }
  }
  return null;
}

/// 大会の区間の距離から出した、5000m・1万m・ハーフの重み(合計1。1.9.2)
/// 区間を距離で分け(7.5km以下は5000m、15km以下は1万m、それより長いとハーフ)、
/// それぞれの区間の距離の合計の割合にする
List<double> tenbouOmomi(KijiKankyou k) {
  final List<double> w = [0.0, 0.0, 0.0];
  double goukei = 0.0;
  for (int kk = 0; kk < k.kukansuu; kk++) {
    final double kyori = k.gh.kyori_taikai_kukangoto[k.race][kk];
    if (kyori <= 0) continue;
    final int c = kyori <= 7500 ? 0 : (kyori <= 15000 ? 1 : 2);
    w[c] += kyori;
    goukei += kyori;
  }
  if (goukei <= 0) return [0.0, 1.0, 0.0];
  return [for (final double v in w) v / goukei];
}

/// 重みが一番大きい種目(主な種目。同じなら距離の長い種目)
int tenbouOmoNaShumoku(List<double> omomi) {
  int m = 1;
  for (int c = 0; c < 3; c++) {
    if (omomi[c] > omomi[m] || (omomi[c] == omomi[m] && c > m)) m = c;
  }
  return m;
}

/// 選手の、区間の距離に合わせた持ちタイム(主な種目[omo]のタイムにそろえた値。1.9.2)
/// 3つの種目の持ちタイム(記録がなければほかの種目から換算)を主な種目に換算し、重み[omomi]で
/// 平均する。どの種目の記録もなければnull
double? tenbouSougouTime(
  KijiKankyou k,
  SenshuData s,
  List<double> omomi,
  int omo,
) {
  double v = 0.0;
  for (int c = 0; c < 3; c++) {
    if (omomi[c] <= 0) continue;
    final double? t = tenbouMochiTime(k, s, c);
    if (t == null) return null;
    v += omomi[c] *
        t *
        math.pow(_shumokuKyori[omo] / _shumokuKyori[c], 1.06).toDouble();
  }
  return v;
}

/// 展望のための戦力のまとめ
class Tenbou {
  final KijiKankyou k;

  /// 前評判の順
  final List<TenbouUniv> jun;

  /// 区間(組)ごとに比べた種目(time_bestkiroku の番号)
  final List<int> shumoku;

  /// 区間(組)ごとの走る予定の選手(その種目の持ちタイム順。記録のない選手は後ろ)
  final List<List<SenshuData>> kukanJun;

  /// チームの平均を出す人数
  final int heikinNinzuu;

  /// チームの平均をそろえた種目(主な種目。time_bestkiroku の番号)
  final int heikinShumoku;

  /// 5000m・1万m・ハーフの重み(区間の距離の合計の割合)
  final List<double> omomi;

  /// スタート直前号か(当日変更のあと。実際に走る選手で書く)
  final bool chokuzen;

  Tenbou._(
    this.k,
    this.jun,
    this.shumoku,
    this.kukanJun,
    this.heikinNinzuu,
    this.heikinShumoku,
    this.omomi,
    this.chokuzen,
  );

  /// [chokuzen] スタート直前号(当日変更のあと)として作るか
  static Tenbou? tsukuru(KijiKankyou k, {bool chokuzen = false}) {
    final int ks = k.kukansuu;
    if (ks <= 0) return null;
    final int race = k.race;
    final List<TenbouUniv> list = [];
    final Map<int, TenbouUniv> byId = {};
    for (final UnivData u in k.univ) {
      if (!k.shutsujou(u)) continue;
      final TenbouUniv x = TenbouUniv(u);
      list.add(x);
      byId[u.id] = x;
    }
    for (final SenshuData s in k.senshu) {
      final TenbouUniv? x = byId[s.univid];
      if (x == null) continue;
      final int e = k.entry(s);
      if (e == -2 || e <= -100) continue;
      x.ichiji.add(s);
      if (e >= 0 && e < ks) x.hashiru.add(s);
    }
    list.removeWhere((x) => x.hashiru.isEmpty);
    if (list.length < 2) return null;

    // チームの平均(区間の距離の合計で5000m・1万m・ハーフを重み付けし、主な種目にそろえる)
    final int ninzuu = race == 3 ? 8 : (race == 4 ? 10 : ks);
    final List<double> omomi = tenbouOmomi(k);
    final int heikinShumoku = tenbouOmoNaShumoku(omomi);
    // 上位[ninzuu]人の平均([idx]が null なら区間の距離に合わせた値、そうでなければ種目[idx]。
    // 半分の人数も記録がなければ出さない)
    double heikinDasu(List<SenshuData> senshu, int? idx) {
      final List<double> t = [];
      for (final SenshuData s in senshu) {
        final double? m = idx == null
            ? tenbouSougouTime(k, s, omomi, heikinShumoku)
            : tenbouMochiTime(k, s, idx);
        if (m != null) t.add(m);
      }
      t.sort();
      final int n = t.length < ninzuu ? t.length : ninzuu;
      if (n == 0 || n * 2 < ninzuu) return TEISUU.DEFAULTTIME;
      double goukei = 0;
      for (int i = 0; i < n; i++) {
        goukei += t[i];
      }
      return goukei / n;
    }

    for (final TenbouUniv x in list) {
      // 駅伝の展望は一次エントリーの上位(補欠に回った主力も入れる)、
      // スタート直前号と予選は実際に走る選手
      final List<SenshuData> taishou =
          (k.ekiden && !chokuzen) ? x.ichiji : x.hashiru;
      x.heikin = heikinDasu(taishou, null);
      if (heikinShumoku != 1) x.sankouIchiman = heikinDasu(taishou, 1);
    }
    final List<TenbouUniv> heikinJun = List<TenbouUniv>.of(list)
      ..sort((a, b) => a.heikin.compareTo(b.heikin));
    for (int i = 0; i < heikinJun.length; i++) {
      heikinJun[i].heikinJuni = i;
    }

    // 区間(組)ごとの種目と、持ちタイムの順
    final List<int> shumoku = [];
    final List<List<SenshuData>> kukanJun = [];
    for (int kk = 0; kk < ks; kk++) {
      final List<SenshuData> hashiru = [
        for (final TenbouUniv x in list)
          for (final SenshuData s in x.hashiru)
            if (k.entry(s) == kk) s,
      ];
      // 走る選手の半分以上が記録を持っている種目で比べる(実況と共通。kiji_kihon.dart。1.9.5)
      final int idx = kukanHikakuShumoku(k, kk, hashiru);
      shumoku.add(idx);
      hashiru.sort((a, b) {
        final int c = k.jikoBest(a, idx).compareTo(k.jikoBest(b, idx));
        return c != 0 ? c : a.id.compareTo(b.id);
      });
      kukanJun.add(hashiru);
    }

    // 区間ごとの持ちタイムの順位の合計(駅伝)と前評判
    if (k.ekiden) {
      for (final TenbouUniv x in list) {
        int ten = 0;
        for (int kk = 0; kk < ks; kk++) {
          int j = list.length;
          for (int i = 0; i < kukanJun[kk].length; i++) {
            if (kukanJun[kk][i].univid == x.u.id) {
              j = i;
              break;
            }
          }
          ten += j;
        }
        x.kukanTen = ten;
      }
      final List<TenbouUniv> kukanJunUniv = List<TenbouUniv>.of(list)
        ..sort((a, b) {
          final int c = a.kukanTen.compareTo(b.kukanTen);
          return c != 0 ? c : a.heikin.compareTo(b.heikin);
        });
      for (int i = 0; i < kukanJunUniv.length; i++) {
        kukanJunUniv[i].kukanJuni = i;
      }
      list.sort((a, b) {
        final int c = (a.heikinJuni + a.kukanJuni).compareTo(
          b.heikinJuni + b.kukanJuni,
        );
        return c != 0 ? c : a.heikin.compareTo(b.heikin);
      });
    } else {
      list.sort((a, b) => a.heikin.compareTo(b.heikin));
    }
    for (int i = 0; i < list.length; i++) {
      list[i].juni = i;
    }
    return Tenbou._(
      k,
      list,
      shumoku,
      kukanJun,
      ninzuu,
      heikinShumoku,
      omomi,
      chokuzen,
    );
  }

  int get ks => k.kukansuu;

  int get n => jun.length;

  /// 自分の大学(出場していなければnull)
  TenbouUniv? get jibun {
    for (final TenbouUniv x in jun) {
      if (x.u.id == k.gh.MYunivid) return x;
    }
    return null;
  }

  /// 大学(idから。出場していなければnull)
  TenbouUniv? univ(int id) {
    for (final TenbouUniv x in jun) {
      if (x.u.id == id) return x;
    }
    return null;
  }

  /// 大学の呼び方(idから)
  String univMei(int univid) => (univid >= 0 && univid < k.univ.length)
      ? daigakuMei(k.univ[univid])
      : '';

  /// 区間(組)[kk]の比べる種目の持ちタイム
  double mochi(SenshuData s, int kk) => k.jikoBest(s, shumoku[kk]);

  /// 区間(組)[kk]の中での持ちタイムの順位(0が1位。いなければ-1)
  int kukanNoJuni(SenshuData s, int kk) {
    for (int i = 0; i < kukanJun[kk].length; i++) {
      if (kukanJun[kk][i].id == s.id) return i;
    }
    return -1;
  }

  /// 選手の、区間の距離に合わせた持ちタイム(チームの平均と同じ値。記録がなければnull)
  double? sougou(SenshuData s) =>
      tenbouSougouTime(k, s, omomi, heikinShumoku);

  /// 大学のエース(走る予定の選手で、区間の距離に合わせた持ちタイムが一番いい選手)
  SenshuData? ace(TenbouUniv x) {
    SenshuData? best;
    double bt = TEISUU.DEFAULTTIME;
    for (final SenshuData s in x.hashiru) {
      final double? t = sougou(s);
      if (t != null && t < bt) {
        bt = t;
        best = s;
      }
    }
    return best;
  }

  /// 区間(組)の呼び方
  String kukanMei(int kk) => kukanYobikata(k.gh, k.race, kk, ks);

  /// 持ちタイムの文(「1万m28分10秒」。記録がなければ空)
  String mochiMoji(SenshuData s, int idx) {
    final double t = k.jikoBest(s, idx);
    if (t >= TEISUU.DEFAULTTIME) return '';
    return '${kijiShumokuMei[idx]}${jikanMoji(t)}';
  }

  /// チームの平均を出した選手の言い方(「上位10人」。スタート直前号は「走る10人」)
  String get heikinTaishouMoji =>
      chokuzen ? '走る$heikinNinzuu人' : '上位$heikinNinzuu人';

  /// 重みが2つ以上の種目に分かれているか
  bool get omomiTsuki => omomi.where((v) => v > 0).length >= 2;

  /// チームの平均の名前(「ハーフ」。重みが混ざっていれば「1万m換算」。後ろに「平均」を付けて使う)
  String get heikinMei => omomiTsuki
      ? '${kijiShumokuMei[heikinShumoku]}換算'
      : kijiShumokuMei[heikinShumoku];

  /// 重みの文(「5000m20%・1万m45%・ハーフ35%」。重みのない種目は書かない)
  String get omomiMoji => [
    for (int c = 0; c < 3; c++)
      if (omomi[c] > 0) '${kijiShumokuMei[c]}${(omomi[c] * 100).round()}%',
  ].join('・');

  /// チームの平均の文
  String heikinMoji(TenbouUniv x) =>
      x.heikin >= TEISUU.DEFAULTTIME ? '-' : jikanMoji(x.heikin);

  /// 参考の1万m平均の文
  String sankouMoji(TenbouUniv x) => x.sankouIchiman >= TEISUU.DEFAULTTIME
      ? '-'
      : jikanMoji(x.sankouIchiman);
}

/// 予想陣の印(1番手◎・2番手○・3番手▲。それより下は「-」)
String _shirushi(KijiYosouJin y, int univid) {
  final int i = y.univJun.indexOf(univid);
  if (i == 0) return '◎';
  if (i == 1) return '○';
  if (i == 2) return '▲';
  return '-';
}

/// 予想陣が3人とも同じ選手を推しているか(その選手のid。そろっていなければnull)
int? _soroiKukanshou(Tenbou t, List<KijiYosouJin> yosou, int kk) {
  if (yosou.length < 2) return null;
  int? id;
  for (final KijiYosouJin y in yosou) {
    if (y.kukanshou.length <= kk) return null;
    final int v = y.kukanshou[kk];
    if (id != null && id != v) return null;
    id = v;
  }
  if (id == null || id < 0 || id >= t.k.senshu.length) return null;
  // 古い予想が残っていないか(その区間を走る選手か)を確かめる
  final SenshuData s = t.k.senshu[id];
  if (t.k.entry(s) != kk) return null;
  return id;
}

// ------------------------------------------------------------
// 記事の入口
// ------------------------------------------------------------

/// 展望の記事の一覧(並べる順)。[yosou] 予想陣の予想(なければ空)
/// [chokuzen] スタート直前号(当日変更のあと。駅伝だけ)
List<Kiji> tenbouKiji(
  KijiKankyou k,
  List<KijiYosouJin> yosou, {
  bool chokuzen = false,
}) {
  if (chokuzen && !k.ekiden) return [];
  final Tenbou? t = Tenbou.tsukuru(k, chokuzen: chokuzen);
  if (t == null) return [];
  final List<Kiji> list = [];
  if (chokuzen) {
    final Kiji? kekka = _toujitsuKekkaTenbou(t);
    if (kekka != null) list.add(kekka);
    list.add(_yuushouTenbou(t, yosou));
    final Kiji? jibun = _jibunTenbou(t, yosou);
    if (jibun != null) list.add(jibun);
    list.add(_kukanTenbou(t, yosou));
    final Kiji? seed = _seedTenbou(t, yosou);
    if (seed != null) list.add(seed);
  } else if (k.ekiden) {
    list.add(_yuushouTenbou(t, yosou));
    final Kiji? jibun = _jibunTenbou(t, yosou);
    if (jibun != null) list.add(jibun);
    list.add(_kukanTenbou(t, yosou));
    final Kiji? seed = _seedTenbou(t, yosou);
    if (seed != null) list.add(seed);
    final Kiji? henkou = _toujitsuTenbou(t);
    if (henkou != null) list.add(henkou);
  } else {
    list.add(_tsuukaTenbou(t, yosou));
    final Kiji? jibun = _jibunTenbou(t, yosou);
    if (jibun != null) list.add(jibun);
    final Kiji? chuumoku = _chuumokuTenbou(t, yosou);
    if (chuumoku != null) list.add(chuumoku);
  }
  return list;
}

/// 記事を作るときの共通の仕上げ(展望は朝の配信)
Kiji _kansei(
  KijiKankyou k,
  int no,
  KijiKakite w, {
  required String category,
  required String midashi,
  required String lead,
  List<KijiHyou> hyou = const [],
  bool jibun = false,
  bool chokuzen = false,
}) {
  final int bangou = no + (chokuzen ? 20 : 10);
  return Kiji(
    category: chokuzen ? category.replaceFirst('展望', '直前') : category,
    midashi: midashi,
    lead: lead,
    honbun: w.honbun,
    hyou: hyou,
    haishin: k.haishinMei(bangou, asa: true),
    kisha: k.kishaMei(bangou),
    jibun: jibun,
    kekka: false,
  );
}

/// 記事の言い回しの乱数の番号(スタート直前号は展望と分ける)
int _taneNo(Tenbou t, int no) => no + (t.chokuzen ? 20 : 10);

/// 大会の始まりの言い方([chokuzen] スタート直前号)
String _gouhou(KijiKankyou k, KijiKakite w, [bool chokuzen = false]) {
  if (chokuzen) {
    return k.race == 2
        ? '${k.taikaiMei}は、まもなく往路の号砲が鳴る。'
        : w.erabu([
            '${k.taikaiMei}は、まもなく号砲が鳴る。',
            '${k.taikaiMei}のスタートが迫った。',
          ]);
  }
  if (k.race == 2) {
    return w.erabu([
      '${k.taikaiMei}は、きょう往路の号砲が鳴る。',
      '${k.taikaiMei}が、きょう往路のスタートを迎える。',
    ]);
  }
  return w.erabu([
    '${k.taikaiMei}は、きょう号砲が鳴る。',
    '${k.taikaiMei}が、きょう行われる。',
    'いよいよきょう、${k.taikaiMei}が行われる。',
  ]);
}

/// 前評判の表
KijiHyou _maeHyoubanHyou(Tenbou t, List<KijiYosouJin> yosou, {required bool ekiden}) {
  final KijiKankyou k = t.k;
  final List<List<String>> gyou = [];
  for (final TenbouUniv x in t.jun) {
    final int mae = juniRace(x.u, k.race, 0);
    gyou.add([
      '${x.juni + 1}',
      x.mei,
      t.heikinMoji(x),
      if (t.heikinShumoku != 1) t.sankouMoji(x),
      if (ekiden) '${x.kukanJuni + 1}',
      shutsujouJuni(mae) ? juniMoji(mae) : '-',
      if (yosou.isNotEmpty) yosou.map((y) => _shirushi(y, x.u.id)).join(),
    ]);
  }
  return KijiHyou(
    t.omomiTsuki
        ? '本紙の戦力分析(${t.heikinMei}平均は${t.heikinTaishouMoji}。区間の距離の合計で'
              '${t.omomiMoji}に重み付けし、${kijiShumokuMei[t.heikinShumoku]}にそろえた持ちタイム。'
              '記録がない種目は、ほかの種目の記録から換算)'
        : '本紙の戦力分析(${t.heikinMei}平均は${t.heikinTaishouMoji}。'
              '${t.heikinMei}の記録がない選手は、ほかの種目の記録から換算)',
    [
      '前評判',
      '大学',
      '${t.heikinMei}平均',
      if (t.heikinShumoku != 1) '1万m平均(参考)',
      if (ekiden) '区間別',
      '前回',
      if (yosou.isNotEmpty) '予想陣(${yosou.map((y) => y.mei.substring(0, 1)).join()})',
    ],
    gyou,
  );
}

// ------------------------------------------------------------
// 駅伝 1. 優勝争い
// ------------------------------------------------------------

Kiji _yuushouTenbou(Tenbou t, List<KijiYosouJin> yosou) {
  final KijiKankyou k = t.k;
  const int no = 1;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, _taneNo(t, no)));
  final int race = k.race;
  final TenbouUniv hon = t.jun[0];
  final TenbouUniv tai = t.jun[1];

  // 事実を集める
  TenbouUniv? ouja; // 前回の優勝校
  for (final TenbouUniv x in t.jun) {
    if (juniRace(x.u, race, 0) == 0) ouja = x;
  }
  // 前回までの連覇(大会の前なので、全期間の優勝回数は前回までの分)。
  // 数を言い切れないとき(残っている記録が全部優勝で、それより前にも優勝がある)は数を出さない
  final ({int kaisuu, bool kakutei})? oujaRz = ouja == null
      ? null
      : renzokuKakutei(
          ouja.u,
          race,
          0,
          (j) => j == 0,
          juniKaisuu(ouja.u, race, 0),
        );
  final int oujaRenzoku = oujaRz?.kaisuu ?? 0;
  final bool oujaFumei = oujaRz != null && !oujaRz.kakutei;
  // 三冠・二冠がかかる大学
  TenbouUniv? sankan;
  TenbouUniv? nikan;
  for (final TenbouUniv x in t.jun) {
    if (race == 2 && juniRace(x.u, 0, 0) == 0 && juniRace(x.u, 1, 0) == 0) {
      sankan = x;
    } else if ((race == 1 && juniRace(x.u, 0, 0) == 0) ||
        (race == 2 && (juniRace(x.u, 0, 0) == 0 || juniRace(x.u, 1, 0) == 0))) {
      nikan ??= x;
    }
  }
  // 三大駅伝(1.9.3): 今季の優勝校と、三冠の連続(前の季まで)
  final SandaiEkiden? sd = SandaiEkiden.tsukuru(k, kekka: false);
  final UnivData? y10 = sd?.yuushou(0, 0);
  final UnivData? y11 = sd?.yuushou(1, 0);
  final ({int kaisuu, bool kakutei})? sankanRz = (sankan != null && sd != null)
      ? sd.sankanRenzoku(sankan.u, 1)
      : null;
  // 三冠がかかる大学が、前の季から三冠を続けているか(言い切れるときだけ)
  final int sankanTsuzuki =
      (sankanRz != null && sankanRz.kakutei) ? sankanRz.kaisuu : 0;
  // 予想陣の本命
  final List<int> honmeiYosou = [
    for (final KijiYosouJin y in yosou)
      if (y.univJun.isNotEmpty) y.univJun.first,
  ];
  final bool yosouIcchi =
      honmeiYosou.length >= 2 && honmeiYosou.every((id) => id == honmeiYosou.first);
  final bool yosouWareru =
      honmeiYosou.length >= 3 && honmeiYosou.toSet().length == honmeiYosou.length;
  // 今回が初めての開催か(ゲームを始めた年など。全校が初出場なので、初出場を並べない)
  final bool hatsuKaisai = mikaisai(k, race);
  // 初出場・久しぶりの出場
  final List<TenbouUniv> hatsu = [
    for (final TenbouUniv x in t.jun)
      if (!hatsuKaisai && shutsujouKaisuu(x.u, race) == 0) x,
  ];
  final List<String> hisashiburi = [];
  for (final TenbouUniv x in t.jun) {
    if (shutsujouKaisuu(x.u, race) == 0) continue;
    if (shutsujouJuni(juniRace(x.u, race, 0))) continue;
    final int? i = saigoNoKai(x.u, race, 1, shutsujouJuni);
    if (i != null && i >= 2) hisashiburi.add('${x.mei}(${i + 1}年ぶり)');
  }

  // 見出し
  String midashi;
  if (sankan != null) {
    midashi = sankanTsuzuki >= 1
        ? '${sankan.mei}、${sankanTsuzuki + 1}年連続の三冠へ'
        : w.erabu([
            '${sankan.mei}、三冠へ最後の戦い',
            '三冠かかる${sankan.mei}',
          ]);
    midashi += sankan.u.id == hon.u.id ? '　戦力も一枚上' : '　${hon.mei}が阻むか';
  } else if (ouja != null && ouja.u.id == hon.u.id && oujaFumei) {
    midashi = w.erabu([
      '${ouja.mei}が本命　連覇をさらに伸ばすか',
      '連覇を続ける${ouja.mei}が本命',
    ]);
  } else if (ouja != null && ouja.u.id == hon.u.id) {
    midashi = oujaRenzoku >= 2
        ? '${ouja.mei}、${oujaRenzoku + 1}連覇へ本命'
        : w.erabu(['${ouja.mei}が連覇へ本命', '前回王者${ouja.mei}、連覇へ視界良好']);
  } else if (ouja != null && oujaFumei) {
    midashi = '${hon.mei}が本命　連覇を続ける${ouja.mei}は記録を伸ばせるか';
  } else if (ouja != null) {
    midashi = '${hon.mei}が本命　前回王者${ouja.mei}は${oujaRenzoku >= 2 ? '${oujaRenzoku + 1}連覇' : '連覇'}なるか';
  } else if (nikan != null && nikan.u.id == hon.u.id) {
    midashi = '${nikan.mei}、今季二冠へ本命';
  } else if (hatsuKaisai) {
    midashi = w.erabu([
      '初代王者へ、${hon.mei}が本命',
      '初開催の${k.raceMei}、${hon.mei}が優勝候補筆頭',
    ]);
  } else {
    midashi = w.erabu([
      '${hon.mei}が優勝候補筆頭　${tai.mei}が追う',
      '本命${hon.mei}、対抗${tai.mei}',
    ]);
  }
  if (yosouWareru && sankan == null) midashi += '　予想陣の本命は割れる';

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(_gouhou(k, w, t.chokuzen));
  lead.write(
    t.chokuzen
        ? '当日変更を終えて各校のオーダーが固まり、本紙の戦力分析では${hon.mei}が優勝候補の筆頭に挙がった。'
        : '出場${t.n}校の区間エントリーが出そろい、本紙の戦力分析では${hon.mei}が優勝候補の筆頭に挙がった。',
  );
  if (hatsuKaisai) {
    lead.write('今回が初めての開催で、${t.n}校が初代王者の座を争う。');
  }
  if (k.ichinenDake) {
    lead.write('今大会は、1年生だけが出場できる。');
  }
  if (hon.heikinJuni == 0 && hon.kukanJuni == 0) {
    lead.write('${t.heikinMei}平均、区間ごとの持ちタイムのどちらでも出場校トップだ。');
  } else if (hon.heikinJuni == 0) {
    lead.write(
      '${t.chokuzen ? t.heikinTaishouMoji : '一次エントリー上位${t.heikinNinzuu}人'}の'
      '${t.heikinMei}平均は${t.heikinMoji(hon)}で出場校トップ。',
    );
  } else if (hon.kukanJuni == 0) {
    lead.write('区間ごとの持ちタイムを比べると、多くの区間で他校を上回る。');
  }
  if (sankan != null) {
    lead.write(
      sankanTsuzuki >= 1
          ? '10月駅伝、11月駅伝を制した${sankan.mei}は、${sankanTsuzuki + 1}年連続の三冠に挑む。'
          : (sankanRz != null && !sankanRz.kakutei)
          ? '10月駅伝、11月駅伝を制した${sankan.mei}は、続けてきた三冠をさらに伸ばせるか。'
          // 三冠がまだ珍しいデータのときだけ「史上まれな」(全大学の通算が、達成すれば3回まで)
          : '10月駅伝、11月駅伝を制した${sankan.mei}は、'
                '${sd != null && sd.sankanGoukei <= 2 ? '史上まれな' : ''}三冠に挑む。',
    );
  } else if (ouja != null) {
    lead.write(
      oujaFumei
          ? '連覇を続ける前回王者の${ouja.mei}は、さらに記録を伸ばせるか。'
          : oujaRenzoku >= 2
          ? '前回王者の${ouja.mei}は${oujaRenzoku + 1}連覇がかかる。'
          : '前回王者の${ouja.mei}は連覇を狙う。',
    );
  }
  if (race == 2 && sankan == null && y10 != null && y11 != null && y10.id != y11.id) {
    // 10月駅伝と11月駅伝の優勝校が違う(1.9.3。どちらも出場していれば、ともに二冠目を狙う)
    final List<String> deru = [
      for (final UnivData u in [y10, y11])
        if (t.jun.any((x) => x.u.id == u.id)) daigakuMei(u),
    ];
    lead.write(
      '今季の三大駅伝は、10月駅伝を${daigakuMei(y10)}、11月駅伝を${daigakuMei(y11)}が制した。'
      '${deru.length == 2 ? '両校とも二冠目を狙う。' : (deru.length == 1 ? '${deru.first}が二冠目を狙う。' : '')}',
    );
  } else if (nikan != null && sankan == null) {
    lead.write(
      race == 1
          ? '10月駅伝を制した${nikan.mei}は、今季二冠目を狙う。'
          : '今季すでに一冠を手にしている${nikan.mei}は、二冠目を狙う。',
    );
  }

  // 本文: 優勝争い
  w.koMidashi('優勝争い');
  {
    final StringBuffer sb = StringBuffer();
    final SenshuData? a = t.ace(hon);
    sb.write('本命の${hon.mei}は');
    final int mae = juniRace(hon.u, race, 0);
    if (shutsujouJuni(mae)) {
      sb.write('前回${juniMoji(mae)}。');
    } else if (!hatsuKaisai && shutsujouKaisuu(hon.u, race) == 0) {
      sb.write('初出場ながら、');
    }
    if (a != null) {
      final int kk = k.entry(a);
      final String m = t.mochiMoji(a, t.heikinShumoku);
      sb.write(
        'エースの${w.senshu(a)}${m.isEmpty ? '' : '($m)'}を${t.kukanMei(kk)}に置いた。',
      );
    }
    sb.write(
      w.erabu([
        '区間配置に穴が少なく、大きく崩れる姿は想像しにくい。',
        '選手層の厚さは出場校随一で、どの区間でも上位で戦える。',
        '序盤から主導権を握れば、そのまま押し切る力がある。',
      ]),
    );
    w.danraku(sb.toString());
    w.comment(kantokuComment(w, KantokuBamen.tenbouHonmei, hon.u.id));
  }
  {
    final StringBuffer sb = StringBuffer();
    final SenshuData? a = t.ace(tai);
    sb.write('対抗は${tai.mei}。');
    if (tai.heikinJuni < hon.heikinJuni) {
      sb.write('${t.heikinMei}平均では${hon.mei}を上回り、');
    } else if (tai.kukanJuni < hon.kukanJuni) {
      sb.write('区間ごとの持ちタイムでは${hon.mei}を上回り、');
    }
    if (a != null) {
      sb.write('${t.kukanMei(k.entry(a))}の${w.senshu(a)}で流れを引き寄せたい。');
    } else {
      sb.write('総合力で食らいつく。');
    }
    w.danraku(sb.toString());
    w.comment(kantokuComment(w, KantokuBamen.tenbouChousen, tai.u.id));
  }
  // ダークホース(区間ごとの持ちタイムの順位が、チームの平均の順位より大きく良い大学)
  TenbouUniv? ana;
  for (final TenbouUniv x in t.jun) {
    if (x.juni < 2 || x.juni > 6) continue;
    if (x.heikinJuni - x.kukanJuni >= 3) {
      ana = x;
      break;
    }
  }
  if (ana != null) {
    w.danraku(
      '不気味なのは${ana.mei}だ。${t.heikinMei}平均は${ana.heikinJuni + 1}番手にとどまるが、'
      '区間ごとの持ちタイムでは${ana.kukanJuni + 1}番手。適材適所の配置がはまれば、上位をかき回す。',
    );
  } else if (t.n >= 3) {
    final TenbouUniv san = t.jun[2];
    w.danraku(
      '${san.mei}が3番手で続く。${w.erabu(['上位2校の背中は見えている。', '展開次第では優勝争いに加わる力がある。'])}',
    );
  }
  if (ouja != null && ouja.u.id != hon.u.id && ouja.u.id != tai.u.id) {
    w.danraku(
      '前回王者の${ouja.mei}は、本紙の前評判では${ouja.juni + 1}番手。'
      '${w.erabu(['王者の意地を見せられるか。', '経験を武器に、下馬評を覆せるか。'])}',
    );
  }

  // 本文: 予想陣の見立て
  if (yosou.isNotEmpty) {
    w.koMidashi('予想陣の見立て');
    final List<String> bun = [];
    for (final KijiYosouJin y in yosou) {
      if (y.univJun.length < 2) continue;
      bun.add(
        '${y.tokuchou}の${y.mei}は◎${t.univMei(y.univJun[0])}、○${t.univMei(y.univJun[1])}',
      );
    }
    if (bun.isNotEmpty) {
      final StringBuffer sb = StringBuffer('${bun.join('。')}。');
      if (yosouIcchi) {
        sb.write('3人そろって${t.univMei(honmeiYosou.first)}を本命に推した。');
      } else if (yosouWareru) {
        sb.write('本命は3人とも分かれ、混戦を予感させる。');
      }
      w.danraku(sb.toString());
    }
  }

  // シード権争いは、別の記事(_seedTenbou)に書く
  final int? seed = race == 1 ? 8 : (race == 2 ? 10 : null);
  if (seed != null && t.n > seed) {
    w.danraku('上位$seed校に与えられるシード権の争いは、別稿で詳しく展望する。');
  }

  // 本文: 出場校の話題
  if (hatsu.isNotEmpty || hisashiburi.isNotEmpty) {
    w.koMidashi('出場校');
    if (hatsu.isNotEmpty) {
      w.danraku(
        '${hatsu.map((x) => x.mei).join('、')}は初出場。'
        '${w.erabu(['大舞台でどんな走りを見せるか。', '新たな歴史の第一歩を刻む。'])}',
      );
    }
    if (hisashiburi.isNotEmpty) {
      w.danraku('${hisashiburi.join('、')}が久しぶりにこの舞台に戻ってきた。');
    }
  }

  return _kansei(
    k,
    no,
    w,
    chokuzen: t.chokuzen,
    category: '駅伝・展望',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      _maeHyoubanHyou(t, yosou, ekiden: true),
      // 三大駅伝の優勝校(11月駅伝・正月駅伝。1.9.3。1.9.4から今季と過去の季の表)
      if (sd != null && race >= 1) sd.konkiHyou(),
    ],
    jibun: hon.u.id == k.gh.MYunivid,
  );
}

// ------------------------------------------------------------
// 駅伝 2. 区間の見どころ
// ------------------------------------------------------------

Kiji _kukanTenbou(Tenbou t, List<KijiYosouJin> yosou) {
  final KijiKankyou k = t.k;
  const int no = 2;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, _taneNo(t, no)));
  final int race = k.race;
  final int ks = t.ks;

  // 前回の区間賞の選手(今回も走る選手)
  final List<({SenshuData s, int maeKukan, int imaKukan})> maeKukanshou = [];
  for (int kk = 0; kk < ks; kk++) {
    for (final SenshuData s in t.kukanJun[kk]) {
      if (k.kukanJuniMae(s, race, 1) == 0) {
        final int mk = k.entryMae(s, race, 1);
        if (mk >= 0) maeKukanshou.add((s: s, maeKukan: mk, imaKukan: kk));
      }
    }
  }
  // 1区のペース予想(直前順位予想の画面の予想と同じ。当日の調子は入れない)
  final IkkuPaceYosou? pace = ikkuPaceTaishou(race)
      ? ikkuPaceYosou(
          gh: k.gh,
          racebangou: race,
          sortedSenshu: k.senshu,
          sortedUniv: k.univ,
          kantoku: k.kantoku,
          // スタート直前号は、目標順位の確認の画面の予想と同じく当日の調子を入れる
          chousiIreru: t.chokuzen,
        )
      : null;

  // 見出し
  String midashi;
  ({SenshuData s, int maeKukan, int imaKukan})? onaji;
  for (final x in maeKukanshou) {
    if (x.maeKukan == x.imaKukan) {
      onaji = x;
      break;
    }
  }
  if (onaji != null) {
    midashi =
        '${myouji(onaji.s.name)}(${t.univMei(onaji.s.univid)})、${onaji.imaKukan + 1}区で2年連続区間賞狙う';
  } else if (pace != null) {
    midashi =
        '1区は${ikkuPaceMidashiMoji[pace.midashi]}の予想　${myouji(pace.pacemaker.name)}(${t.univMei(pace.pacemaker.univid)})が鍵';
  } else if (t.kukanJun[0].isNotEmpty) {
    final SenshuData a = t.kukanJun[0].first;
    midashi = '1区は${myouji(a.name)}(${t.univMei(a.univid)})が持ちタイムトップ';
  } else {
    midashi = '区間エントリー発表　各区間の見どころ';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    t.chokuzen
        ? '${k.taikaiMei}は当日変更を終え、各区間を走る選手が決まった。'
        : '${k.taikaiMei}の区間エントリーが発表された。',
  );
  lead.write(
    w.erabu([
      '各区間の持ちタイムから、見どころを探った。',
      '区間ごとの持ちタイムを比べ、勝負の鍵を握る区間を占う。',
    ]),
  );
  if (maeKukanshou.isNotEmpty) {
    lead.write('前回の区間賞のうち${maeKukanshou.length}人が今回もエントリーされている。');
  }

  // 1区のペース
  if (pace != null) {
    w.koMidashi('1区の流れ');
    final StringBuffer sb = StringBuffer();
    sb.write(
      '1区は、${w.senshu(pace.pacemaker, daigaku: true)}が集団を引っ張る展開が予想される。'
      '集団は${ikkuPaceMoji(k.gh, race, pace.pace, atoMoji: '前後')}で進む'
      '${ikkuPaceMidashiMoji[pace.midashi]}になりそうだ。',
    );
    if (pace.taikou.isNotEmpty) {
      final IkkuTaikou ta = pace.taikou.first;
      sb.write(
        'ただ、その日の勢い次第では${w.senshu(ta.senshu, daigaku: true)}が前に出る可能性もあり、'
        'そうなれば${ikkuPaceMidashiMoji[ta.midashi]}に変わる。',
      );
    }
    if (pace.midashi >= 3) {
      sb.write('速い流れに無理について行けば、後半に失速する選手も出そうだ。');
    } else if (pace.midashi <= 1) {
      sb.write('力のある選手には物足りない流れになりそうで、仕掛けどころが注目される。');
    }
    w.danraku(sb.toString());
  }

  // 区間ごと
  w.koMidashi('各区間');
  for (int kk = 0; kk < ks; kk++) {
    final List<SenshuData> j = t.kukanJun[kk];
    if (j.isEmpty) continue;
    final int idx = t.shumoku[kk];
    final StringBuffer sb = StringBuffer();
    final SenshuData a = j[0];
    final String ma = t.mochiMoji(a, idx);
    sb.write(
      '${t.kukanMei(kk)}(${kmMoji(k.gh.kyori_taikai_kukangoto[race][kk])})は、',
    );
    if (ma.isEmpty) {
      sb.write('持ちタイムの比べにくい区間だ。');
    } else {
      sb.write('${kijiShumokuMei[idx]}の持ちタイムで${w.senshu(a, daigaku: true)}($ma)がトップ。');
      // 持ちタイム1位の選手の因縁(点の高いものだけ。1.9.4)
      final List<Innen> ai = senshuInnen(k, a, kk, kekka: false);
      if (ai.isNotEmpty && ai.first.ten >= 55) sb.write(ai.first.bun);
      final List<String> tsuzuku = [
        for (final SenshuData s in j.skip(1).take(2))
          if (t.mochiMoji(s, idx).isNotEmpty)
            '${w.senshu(s)}(${t.univMei(s.univid)})',
      ];
      if (tsuzuku.isNotEmpty) sb.write('${tsuzuku.join('、')}が続く。');
    }
    // 前回の区間賞
    for (final x in maeKukanshou) {
      if (x.imaKukan != kk) continue;
      if (x.maeKukan == kk) {
        sb.write('前回この区間で区間賞の${w.senshu(x.s, daigaku: true)}は、2年連続の区間賞を狙う。');
      } else {
        sb.write('前回${x.maeKukan + 1}区で区間賞の${w.senshu(x.s, daigaku: true)}は、今回この区間を任された。');
      }
    }
    // 予想陣がそろって推す選手
    final int? soroi = _soroiKukanshou(t, yosou, kk);
    if (soroi != null) {
      sb.write('予想陣が3人そろって区間賞に推すのは${w.senshu(k.senshu[soroi], daigaku: true)}だ。');
    }
    // 区間記録(1区・山の区間・最終区)
    final KukanTokuchou tk = kukanTokuchou(k.gh, race, kk);
    if (kk == 0 ||
        kk == ks - 1 ||
        tk == KukanTokuchou.yamaNobori ||
        tk == KukanTokuchou.yamaKudari) {
      final kr = kukanKiroku(k, kk); // 区間記録(kiji_kihon.dart。1.9.5)
      if (kr != null) {
        // 記録した年から回の数を出す(正月駅伝・カスタム駅伝は年度で数える。1.9.3)
        final int? kai = kr.year > 0 ? k.kaiNoKazu(kr.year) : null;
        sb.write(
          '区間記録は${kai != null ? '第$kai回大会で' : ''}'
          '${fullMei(kr.name)}${kr.univ.isEmpty ? '' : '(${daigakuMeiMoji(kr.univ)})'}が'
          'マークした${jikanMoji(kr.time)}。',
        );
      }
    }
    w.danraku(sb.toString());
  }

  // 区間ごとの持ちタイム1位の表
  final List<List<String>> gyou = [];
  for (int kk = 0; kk < ks; kk++) {
    final List<SenshuData> j = t.kukanJun[kk];
    final int idx = t.shumoku[kk];
    final SenshuData? a = j.isEmpty ? null : j[0];
    final double at = a == null ? TEISUU.DEFAULTTIME : t.mochi(a, kk);
    gyou.add([
      '${kk + 1}区',
      kmMoji(k.gh.kyori_taikai_kukangoto[race][kk]),
      kijiShumokuMei[idx],
      a == null ? '-' : '${fullMei(a.name)}(${a.gakunen})',
      a == null ? '-' : t.univMei(a.univid),
      at >= TEISUU.DEFAULTTIME ? '-' : jikanMoji(at),
    ]);
  }
  return _kansei(
    k,
    no,
    w,
    chokuzen: t.chokuzen,
    category: '駅伝・展望',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        '区間ごとの持ちタイム1位',
        ['区間', '距離', '比べた種目', '選手', '大学', 'タイム'],
        gyou,
      ),
    ],
  );
}

// ------------------------------------------------------------
// 駅伝 シード権争い(11月駅伝は上位8校、正月駅伝は上位10校)
// 展望は本戦の前なので、本戦の記録の[0]は前回の本戦。今年の予選(11月駅伝予選・
// 正月駅伝予選)はもう終わっているので、予選の記録の[0]は今年の予選
// ------------------------------------------------------------

/// 大学の前回の本戦の総合タイム(なければ TEISUU.DEFAULTTIME)
double _maeSougouTime(UnivData u, int race) {
  if (u.time_race.length <= race || u.time_race[race].isEmpty) {
    return TEISUU.DEFAULTTIME;
  }
  final double t = u.time_race[race][0];
  return t > 0 ? t : TEISUU.DEFAULTTIME;
}

Kiji? _seedTenbou(Tenbou t, List<KijiYosouJin> yosou) {
  final KijiKankyou k = t.k;
  final int race = k.race;
  final int? seed = race == 1 ? 8 : (race == 2 ? 10 : null);
  if (seed == null || t.n <= seed) return null;
  const int no = 5;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, race, _taneNo(t, no)));
  final int yosenRace = race == 1 ? 3 : 4;
  final String yosenMei = race == 1 ? '11月駅伝予選' : '正月駅伝予選';
  final TenbouUniv saigo = t.jun[seed - 1]; // 前評判でシード権の最後の枠
  final TenbouUniv soto = t.jun[seed]; // 前評判でシード権の1つ外

  // 事実を集める
  // 当落線上(前評判でシード権の最後の枠の上下3校ずつ)
  final List<TenbouUniv> kyoukai = [
    for (final TenbouUniv x in t.jun)
      if (x.juni >= seed - 3 && x.juni <= seed + 2) x,
  ];
  // 前回までの連続シード(今回の前まで)
  int renzokuSeed(TenbouUniv x) =>
      renzokuKaisuu(x.u, race, 0, (j) => j < seed);
  // 連続シードの数を言い切れるか(言い切れないときは数を出さない。全期間のシードの回数は前回までの分)
  bool renzokuSeedKakutei(TenbouUniv x) => renzokuKakutei(
    x.u,
    race,
    0,
    (j) => j < seed,
    seedKaisuu(x.u, race, seed),
  ).kakutei;
  // 前回シード権を取っていて、前評判でシード権の外にいる大学(連続シードの長い順)
  final List<TenbouUniv> kiken = [
    for (final TenbouUniv x in t.jun)
      if (juniRace(x.u, race, 0) < seed && x.juni >= seed) x,
  ]..sort((a, b) => renzokuSeed(b).compareTo(renzokuSeed(a)));
  final TenbouUniv? kiken0 = kiken.isEmpty ? null : kiken.first;
  // 今年の予選を勝ち上がってきた大学(前評判の順)
  final List<TenbouUniv> yosenGumi = [
    for (final TenbouUniv x in t.jun)
      if (shutsujouJuni(juniRace(x.u, yosenRace, 0))) x,
  ];
  final List<TenbouUniv> yosenSeedKen = [
    for (final TenbouUniv x in yosenGumi)
      if (x.juni < seed) x,
  ];
  TenbouUniv? yosenTop; // 今年の予選のトップ通過
  for (final TenbouUniv x in yosenGumi) {
    if (juniRace(x.u, yosenRace, 0) == 0) yosenTop = x;
  }
  // 前回のシード権ライン(前回の最後のシード校と、最初に逃した大学)
  UnivData? maeSaigo;
  UnivData? maeSoto;
  for (final UnivData u in k.univ) {
    final int j = juniRace(u, race, 0);
    if (j == seed - 1) maeSaigo = u;
    if (j == seed) maeSoto = u;
  }
  int? maeSa;
  if (maeSaigo != null && maeSoto != null) {
    final double a = _maeSougouTime(maeSaigo, race);
    final double b = _maeSougouTime(maeSoto, race);
    if (a < TEISUU.DEFAULTTIME && b < TEISUU.DEFAULTTIME) maeSa = saByou(b, a);
  }
  // 境目の2校のチームの平均の比べ
  String heikinHikaku = '';
  if (saigo.heikin < TEISUU.DEFAULTTIME && soto.heikin < TEISUU.DEFAULTTIME) {
    final int d = saByou(soto.heikin, saigo.heikin);
    if (d > 0) {
      heikinHikaku = '${t.heikinMei}平均の差は${saMoji(d)}しかない。';
    } else if (d < 0) {
      heikinHikaku = '${t.heikinMei}平均では、むしろ${soto.mei}が${saMoji(d)}上回る。';
    } else {
      heikinHikaku = '${t.heikinMei}平均はほぼ同じだ。';
    }
  }
  final TenbouUniv? jibun = t.jibun;
  final bool jibunKyoukai = jibun != null && kyoukai.contains(jibun);

  // 見出し
  String midashi;
  if (kiken0 != null && renzokuSeed(kiken0) >= 3) {
    midashi = renzokuSeedKakutei(kiken0)
        ? '${kiken0.mei}、${renzokuSeed(kiken0) + 1}年連続シードへ正念場　前評判${kiken0.juni + 1}番手'
        : '${kiken0.mei}、長く続く連続シードへ正念場　前評判${kiken0.juni + 1}番手';
  } else if (kiken0 != null) {
    midashi = w.erabu([
      '前回シードの${kiken0.mei}に黄信号　前評判${kiken0.juni + 1}番手',
      '${kiken0.mei}、シード権死守なるか　前評判${kiken0.juni + 1}番手',
    ]);
  } else if (yosenSeedKen.isNotEmpty) {
    midashi = '予選組の${yosenSeedKen.first.mei}、シード圏内の評価';
  } else {
    midashi = w.erabu([
      'シード権争い　ボーダーは${saigo.mei}と${soto.mei}',
      '$seed枠目を巡る争い　${saigo.mei}・${soto.mei}が当落線上',
    ]);
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}では、上位$seed校に来年のシード権が与えられる。'
    'シード権を逃せば、来年は$yosenMeiからの出直しとなる。',
  );
  lead.write(
    '本紙の戦力分析では、$seed番手の${saigo.mei}と${seed + 1}番手の${soto.mei}が'
    'ちょうど境目にいる。$heikinHikaku',
  );
  if (kiken0 != null) {
    final int r = renzokuSeed(kiken0);
    lead.write(
      '前回${juniMoji(juniRace(kiken0.u, race, 0))}の${kiken0.mei}は'
      '${!renzokuSeedKakutei(kiken0) ? '長くシード権を守ってきたが、' : (r >= 2 ? '$r年連続でシード権を守ってきたが、' : '')}'
      '前評判では${kiken0.juni + 1}番手にとどまる。',
    );
  }

  // 本文: 当落線上
  final Set<int> commentZumi = {};
  w.koMidashi('当落線上');
  w.danraku(
    '前評判${kyoukai.first.juni + 1}番手から${kyoukai.last.juni + 1}番手までの'
    '${kyoukai.map((x) => x.mei).join('、')}が、シード権を争う構図だ。'
    '${w.erabu(['数秒の差で順位が入れ替わる、厳しい争いになりそうだ。', 'どこが抜け出すか、最後まで目が離せない。'])}',
  );
  for (final TenbouUniv x in [saigo, soto]) {
    final StringBuffer sb = StringBuffer();
    sb.write('${x.mei}は');
    final int mae = juniRace(x.u, race, 0);
    final int yosen = juniRace(x.u, yosenRace, 0);
    if (shutsujouJuni(yosen)) {
      sb.write('$yosenMeiを${juniMoji(yosen)}で通過して本戦に臨む。');
    } else if (shutsujouJuni(mae)) {
      sb.write('前回${juniMoji(mae)}。');
    } else if (!mikaisai(k, race) && shutsujouKaisuu(x.u, race) == 0) {
      sb.write('初出場。');
    }
    final SenshuData? a = t.ace(x);
    if (a != null) {
      final String m1 = t.mochiMoji(a, t.heikinShumoku);
      sb.write(
        'エースの${w.senshu(a)}${m1.isEmpty ? '' : '($m1)'}を${t.kukanMei(k.entry(a))}に置いた。',
      );
    }
    if (x.u.id == saigo.u.id) {
      sb.write(w.erabu(['逃げ切れるか。', '大きな失敗をしなければ、圏内に踏みとどまれる。']));
    } else {
      sb.write(w.erabu(['逆転でのシード権獲得を狙う。', '一つ前の大学をとらえられるか。']));
    }
    w.danraku(sb.toString());
  }
  w.comment(kantokuComment(w, KantokuBamen.tenbouSeed, soto.u.id));
  commentZumi.add(soto.u.id);
  if (jibun != null &&
      jibunKyoukai &&
      jibun.u.id != saigo.u.id &&
      jibun.u.id != soto.u.id) {
    w.danraku('${jibun.mei}も前評判${jibun.juni + 1}番手で、シード権争いの渦中にいる。');
  }

  // 本文: 前回のシード校
  if (kiken.isNotEmpty) {
    w.koMidashi('前回のシード校');
    for (final TenbouUniv x in kiken.take(2)) {
      final int r = renzokuSeed(x);
      w.danraku(
        '前回${juniMoji(juniRace(x.u, race, 0))}の${x.mei}は前評判${x.juni + 1}番手。'
        '${!renzokuSeedKakutei(x) ? '長く続く連続シードが途切れる恐れもある。' : (r >= 2 ? '続けてきた$r年連続のシード権が途切れる恐れもある。' : 'シード権を守れるかが焦点だ。')}',
      );
    }
    final TenbouUniv k0 = kiken.first;
    if (!commentZumi.contains(k0.u.id)) {
      w.comment(kantokuComment(w, KantokuBamen.tenbouSeed, k0.u.id));
      commentZumi.add(k0.u.id);
    }
  }

  // 本文: 予選組
  if (yosenGumi.isNotEmpty) {
    w.koMidashi('予選組');
    final StringBuffer sb = StringBuffer();
    sb.write('$yosenMeiを勝ち上がった${yosenGumi.length}校のうち、');
    if (yosenSeedKen.isEmpty) {
      sb.write('前評判でシード圏内に入った大学はない。');
      sb.write('最上位の評価は${yosenGumi.first.mei}(前評判${yosenGumi.first.juni + 1}番手)だ。');
    } else {
      sb.write(
        '前評判でシード圏内にいるのは'
        '${yosenSeedKen.map((x) => '${x.mei}(${x.juni + 1}番手)').join('、')}。',
      );
    }
    if (yosenTop != null) {
      sb.write('予選トップ通過の${yosenTop.mei}は、前評判${yosenTop.juni + 1}番手だ。');
    }
    sb.write(w.erabu(['予選の勢いを本戦につなげられるか。', '予選からの連戦をどう乗り切るかも鍵になる。']));
    w.danraku(sb.toString());
  }

  // 本文: 予想陣と前回のシード権ライン
  final List<String> yosouBun = [
    for (final KijiYosouJin y in yosou)
      if (y.univJun.length > seed)
        '${y.mei}は${t.univMei(y.univJun[seed - 1])}',
  ];
  if (yosouBun.isNotEmpty || maeSa != null) {
    w.koMidashi('見立て');
    if (yosouBun.isNotEmpty) {
      w.danraku('予想陣が$seed位、つまり最後のシード校に挙げたのは、${yosouBun.join('、')}。');
    }
    if (maeSaigo != null && maeSoto != null && maeSa != null) {
      w.danraku(
        '前回は${daigakuMei(maeSaigo)}が$seed位に滑り込み、${seed + 1}位の${daigakuMei(maeSoto)}との差は'
        '${saMoji(maeSa)}だった。'
        '${w.erabu(['今回も、わずかな差が明暗を分けそうだ。', '一人ひとりの1秒が、来年の戦い方を変える。'])}',
      );
    }
  }

  // シード権ライン付近の前評判の表(シード権ラインの区切りの行を入れる)
  final List<List<String>> gyou = [];
  for (final TenbouUniv x in kyoukai) {
    final int mae = juniRace(x.u, race, 0);
    final int yosen = juniRace(x.u, yosenRace, 0);
    gyou.add([
      '${x.juni + 1}',
      x.mei,
      t.heikinMoji(x),
      '${x.kukanJuni + 1}',
      shutsujouJuni(mae) ? juniMoji(mae) : '-',
      shutsujouJuni(yosen)
          ? '予選${juniMoji(yosen)}'
          : (shutsujouJuni(mae) && mae < seed ? 'シード' : '-'),
    ]);
    if (x.juni == seed - 1) {
      gyou.add(['', '― シード権ライン ―', '', '', '', '']);
    }
  }
  return _kansei(
    k,
    no,
    w,
    chokuzen: t.chokuzen,
    category: '駅伝・展望',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        'シード権ライン付近の前評判(上位$seed校がシード権)',
        ['前評判', '大学', '${t.heikinMei}平均', '区間別', '前回', '今季の出場'],
        gyou,
      ),
    ],
    jibun: jibunKyoukai,
  );
}

// ------------------------------------------------------------
// スタート直前号 当日変更の結果(1.9.2)
// ・外れた選手には区間の値に -(100+区間) の印が残るので、誰がどの区間で入れ替わったかが分かる
// ・入った選手が出場全選手の中で1万mかハーフの持ちタイム10番手以内なら大きく取り上げ、
//   補欠のまま出番がなかった持ちタイム上位の選手(自分の大学は除く)も書く
// ・1区が入れ替わったときは、区間エントリーどおりの1区の予想と比べてペースの見出しの変化を書く
// ------------------------------------------------------------

/// 当日変更の1件
class _Henkou {
  final TenbouUniv x;

  /// 外れた選手
  final SenshuData deta;

  /// 入った選手(見つからなければnull)
  final SenshuData? haitta;

  /// 区間(0が1区)
  final int kk;

  const _Henkou(this.x, this.deta, this.haitta, this.kk);
}

/// 当日変更の一覧(前評判の順、同じ大学の中は区間の順)
List<_Henkou> _henkouIchiran(Tenbou t) {
  final KijiKankyou k = t.k;
  final List<_Henkou> l = [];
  for (final TenbouUniv x in t.jun) {
    for (final SenshuData s in k.senshu) {
      if (s.univid != x.u.id) continue;
      final int e = k.entry(s);
      if (e > -100) continue;
      final int kk = -e - 100;
      if (kk < 0 || kk >= t.ks) continue;
      SenshuData? haitta;
      for (final SenshuData h in x.hashiru) {
        if (k.entry(h) == kk) haitta = h;
      }
      l.add(_Henkou(x, s, haitta, kk));
    }
  }
  l.sort((a, b) {
    final int c = a.x.juni.compareTo(b.x.juni);
    return c != 0 ? c : a.kk.compareTo(b.kk);
  });
  return l;
}

/// 当日変更の選手の持ちタイム([idx] 区間の距離に合った種目。記録がなければ近い種目。どれもなければnull)
({int idx, double time})? _henkouMochi(KijiKankyou k, SenshuData s, int idx) {
  final List<int> jun = idx == 0
      ? const [0, 1, 2]
      : (idx == 1 ? const [1, 0, 2] : const [2, 1, 0]);
  for (final int c in jun) {
    final double t = k.jikoBest(s, c);
    if (t < TEISUU.DEFAULTTIME) return (idx: c, time: t);
  }
  return null;
}

/// 当日変更の選手の持ちタイムの文(「ハーフ1時間02分10秒」。記録がなければ「記録なし」)
String _henkouMochiMoji(KijiKankyou k, SenshuData s, int idx) {
  final ({int idx, double time})? m = _henkouMochi(k, s, idx);
  if (m == null) return '記録なし';
  return '${kijiShumokuMei[m.idx]}${jikanMoji(m.time)}';
}

/// 持ちタイムを添えた選手の呼び方
/// (初めては「山田太郎(3年・ハーフ1時間02分10秒)」、2回目からは「山田(ハーフ1時間02分10秒)」)
String _senshuMochi(KijiKakite w, SenshuData s, String mochi) {
  if (w.deta('S${s.id}')) return '${w.senshu(s)}($mochi)';
  return w.hito('S${s.id}', s.name, '${s.gakunen}年・$mochi', '');
}

Kiji? _toujitsuKekkaTenbou(Tenbou t) {
  final KijiKankyou k = t.k;
  const int no = 6;
  final List<_Henkou> henkou = _henkouIchiran(t);
  if (henkou.isEmpty) return null;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, _taneNo(t, no)));
  final int race = k.race;
  final Set<int> daigaku = {for (final _Henkou h in henkou) h.x.u.id};
  // 当日変更の事情(大学ごと・区間ごと。外れた理由と温存していたエースの投入。1.9.4)
  final Map<int, Map<int, ToujituJijou>> jijouZen = {};
  for (final TenbouUniv x in t.jun) {
    if (!daigaku.contains(x.u.id)) continue;
    final List<SenshuData?> kukanSenshu = [
      for (int kk = 0; kk < t.ks; kk++)
        x.hashiru.where((s) => k.entry(s) == kk).firstOrNull,
    ];
    jijouZen[x.u.id] = toujituJijou(k, x.u, kukanSenshu);
  }
  ToujituJijou? jijouOf(_Henkou h) => jijouZen[h.x.u.id]?[h.kk];
  final int taichouKazu = henkou.where((h) => jijouOf(h)?.riyuu == HazuretaRiyuu.taichouFuryou).length;
  // 外れた理由の一言(「体調不良」「調子が上がらなかったこと」。理由を書かないときは空)
  String riyuuMoji(_Henkou h) {
    final ToujituJijou? j = jijouOf(h);
    if (j == null) return '';
    if (j.riyuu == HazuretaRiyuu.taichouFuryou) return '体調不良';
    if (j.riyuu == HazuretaRiyuu.chousi) return '調子が上がらなかったこと';
    return '';
  }

  // 出場全選手(一次エントリー。補欠と外れた選手を含む)の、1万mとハーフの持ちタイムの順
  final List<SenshuData> zenin = [
    for (final TenbouUniv x in t.jun) ...x.ichiji,
    for (final _Henkou h in henkou) h.deta,
  ];
  List<SenshuData> jun(int idx) => [
    for (final SenshuData s in zenin)
      if (k.jikoBest(s, idx) < TEISUU.DEFAULTTIME) s,
  ]..sort((a, b) => k.jikoBest(a, idx).compareTo(k.jikoBest(b, idx)));
  final List<SenshuData> junIchiman = jun(1);
  final List<SenshuData> junHalf = jun(2);
  // 全体の持ちタイム上位(10番手以内)なら「1万m全体3位」の言い方(そうでなければnull)
  String? jouiMoji(SenshuData s) {
    final int a = junIchiman.indexWhere((d) => d.id == s.id);
    final int b = junHalf.indexWhere((d) => d.id == s.id);
    final int ai = a < 0 ? 9999 : a;
    final int bi = b < 0 ? 9999 : b;
    final int best = ai <= bi ? ai : bi;
    if (best >= _hoketsuJougenJuni) return null;
    return '${ai <= bi ? '1万m' : 'ハーフ'}全体${best + 1}位';
  }

  // 持ちタイム上位の選手が入った変更
  final List<_Henkou> omo = [
    for (final _Henkou h in henkou)
      if (h.haitta != null && jouiMoji(h.haitta!) != null) h,
  ];
  // 持ちタイム上位の選手が外れた変更(入った選手も上位の変更は、上の omo で書く)
  final List<_Henkou> hazushi = [
    for (final _Henkou h in henkou)
      if (jouiMoji(h.deta) != null && !omo.contains(h)) h,
  ];
  // 入った選手と外れた選手の持ちタイムを、区間の距離に合った種目で比べる文
  // (2人とも名前を出したあとに使う。[suisoku] 外れた選手のほうが速いとき、起用の読みを添えるか)
  String hikakuBun(_Henkou h, {bool suisoku = true}) {
    final SenshuData? hs = h.haitta;
    if (hs == null) return '';
    final int idx = kukanKihonShumoku(k.gh, race, h.kk);
    final ({int idx, double time})? mi = _henkouMochi(k, hs, idx);
    final ({int idx, double time})? mo = _henkouMochi(k, h.deta, idx);
    if (mi == null && mo == null) return '';
    final String yi = w.senshu(hs);
    final String yo = w.senshu(h.deta);
    if (mi != null && mo != null && mi.idx == idx && mo.idx == idx) {
      final String mei = kijiShumokuMei[idx];
      // 正なら入った選手のほうが速い
      final int sa = saByou(mo.time, mi.time);
      if (sa > 0) {
        return '$meiの持ちタイムは$yiが${jikanMoji(mi.time)}で、'
            '$yoの${jikanMoji(mo.time)}を${saMoji(sa)}上回る。';
      }
      if (sa < 0) {
        return '$meiの持ちタイムは$yiが${jikanMoji(mi.time)}で、'
            '外れた$yoの${jikanMoji(mo.time)}のほうが${saMoji(sa)}速い。'
            '${suisoku ? w.erabu(['当日の状態を見極めての起用か。', '調子を優先した起用とみられる。']) : ''}';
      }
      return '$meiの持ちタイムは、$yiと$yoがともに${jikanMoji(mi.time)}で並ぶ。';
    }
    return '持ちタイムは、$yiが${_henkouMochiMoji(k, hs, idx)}、'
        '$yoが${_henkouMochiMoji(k, h.deta, idx)}。';
  }
  // 持ちタイム上位なのに補欠のまま出番がなかった選手(自分の大学は除く)
  final List<({TenbouUniv x, SenshuData s})> demasezu = [];
  for (final TenbouUniv x in t.jun) {
    if (x.u.id == k.gh.MYunivid) continue;
    for (final SenshuData s in x.ichiji) {
      if (k.entry(s) == -1 && jouiMoji(s) != null) {
        demasezu.add((x: x, s: s));
      }
    }
  }
  // 1区の変更があれば、区間エントリーどおりの予想と比べる
  final Map<int, int> ikkuModoshi = {
    for (final _Henkou h in henkou)
      if (h.kk == 0 && h.haitta != null) h.haitta!.id: h.deta.id,
  };
  IkkuPaceYosou? paceAto;
  IkkuPaceYosou? paceMae;
  if (ikkuModoshi.isNotEmpty && ikkuPaceTaishou(race)) {
    paceAto = ikkuPaceYosou(
      gh: k.gh,
      racebangou: race,
      sortedSenshu: k.senshu,
      sortedUniv: k.univ,
      kantoku: k.kantoku,
    );
    paceMae = ikkuPaceYosou(
      gh: k.gh,
      racebangou: race,
      sortedSenshu: k.senshu,
      sortedUniv: k.univ,
      kantoku: k.kantoku,
      irekae: ikkuModoshi,
    );
  }

  // 見出し
  String midashi;
  if (omo.length == 1) {
    final _Henkou h = omo.first;
    midashi = w.erabu([
      '${h.x.mei}、${myouji(h.haitta!.name)}を${h.kk + 1}区に投入　${jouiMoji(h.haitta!)}',
      '${jouiMoji(h.haitta!)}の${myouji(h.haitta!.name)}が${h.kk + 1}区へ　${h.x.mei}が当日変更',
    ]);
  } else if (omo.length >= 2) {
    midashi = '持ちタイム上位の${omo.length}人が当日変更で出場へ';
  } else if (hazushi.length == 1) {
    final _Henkou h = hazushi.first;
    midashi = w.erabu([
      '${h.x.mei}、${jouiMoji(h.deta)}の${myouji(h.deta.name)}が外れる',
      '${h.x.mei}、主力の${myouji(h.deta.name)}を${h.kk + 1}区から外す',
    ]);
  } else if (hazushi.length >= 2) {
    midashi = '持ちタイム上位の${hazushi.length}人が当日変更で外れる';
  } else {
    midashi = '当日変更は${daigaku.length}校で計${henkou.length}人';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}は${race == 2 ? '往路の' : ''}当日変更が発表され、'
    '${daigaku.length}校が計${henkou.length}人を入れ替えた。',
  );
  if (omo.isNotEmpty) {
    lead.write(
      w.erabu([
        '区間エントリーで補欠に回っていた主力が、次々とオーダーに名を連ねた。',
        '補欠に温存されていた実力者たちが、ついにベールを脱いだ。',
      ]),
    );
  } else if (hazushi.isNotEmpty) {
    lead.write('持ちタイム上位の主力が、オーダーから外れる動きもあった。');
  }
  if (taichouKazu >= 1) {
    lead.write(
      taichouKazu == henkou.length
          ? '${taichouKazu == 1 ? '変更は' : '変更はいずれも'}体調不良によるものだった。'
          : 'このうち$taichouKazu人は、体調不良による変更だった。',
    );
  }

  // 本文: 投入された主力
  if (omo.isNotEmpty) {
    w.koMidashi('投入された主力');
    if (omo.length <= 2) {
      for (int i = 0; i < omo.length; i++) {
        final _Henkou h = omo[i];
        final SenshuData hs = h.haitta!;
        // 名前は出す順に作る(初めては学年つき、2回目からは名字)
        final String yobi = w.senshu(hs);
        final String deta = w.senshu(h.deta);
        final ToujituJijou? hj = jijouOf(h);
        final String onzon = hj != null && hj.onzonAce ? '補欠に温存していた' : '';
        final StringBuffer sb = StringBuffer(
          i == 0
              ? '${_zenpyouMoji(t, h.x)}${h.x.mei}は、持ちタイムが${jouiMoji(hs)}の$onzon$yobiを'
                    '${t.kukanMei(h.kk)}に起用し、区間エントリーで入っていた$detaと入れ替えた。'
              : '${h.x.mei}も、持ちタイムが${jouiMoji(hs)}の$onzon$yobiを'
                    '${t.kukanMei(h.kk)}に入れ、$detaと入れ替えた。',
        );
        // 外れた理由(体調不良・調子)があれば、その穴を埋めた形と書く(1.9.4)
        if (hj != null && hj.riyuu == HazuretaRiyuu.taichouFuryou) {
          sb.write(
            hj.onzonAce
                ? (hj.fukuroAceOuro
                      ? '$detaが体調不良で走れなくなり、復路に温存していた切り札を往路に前倒しで使うことになった。'
                      : '$detaが体調不良で走れなくなり、温存していた切り札でその穴を埋めた形だ。')
                : '$detaが体調不良で走れなくなったための変更だ。',
          );
        } else if (hj != null && hj.riyuu == HazuretaRiyuu.chousi) {
          sb.write('$detaは調子が上がらず、外れた。');
        }
        sb.write(hikakuBun(h, suisoku: hj == null || hj.riyuu == HazuretaRiyuu.irekae));
        // 外れた選手も持ちタイム上位なら、主力同士の入れ替え
        final String? detaJoui = jouiMoji(h.deta);
        if (detaJoui != null) {
          sb.write('${w.senshu(h.deta)}も持ちタイムが$detaJouiで、主力同士の入れ替えとなった。');
        }
        if (i > 0) {
          sb.write(w.erabu(['勝負の一手が、どう出るか。', '流れを変える起用となるか。']));
        }
        w.danraku(sb.toString());
      }
    } else {
      final List<String> narabi = [
        for (final _Henkou h in omo)
          '${h.x.mei}の${w.senshu(h.haitta!)}(${jouiMoji(h.haitta!)}、${h.kk + 1}区)',
      ];
      w.danraku(
        '当日変更で起用された主な選手は、${narabi.join('、')}。'
        '${w.erabu(['各校の切り札が、そろって表舞台に立つ。', '戦略的エントリーの答えが、ここで明らかになった。'])}',
      );
    }
  }
  // 本文の小見出し: 主力の投入のあとに、外れた主力・補欠のままの主力を書くとき
  if (omo.isNotEmpty && (hazushi.isNotEmpty || demasezu.isNotEmpty)) {
    w.koMidashi(
      demasezu.isEmpty
          ? '外れた主力'
          : (hazushi.isEmpty ? '補欠のままの主力' : '起用されなかった主力'),
    );
  }
  // 本文: 外れた主力(入った選手は持ちタイム上位ではない)
  if (hazushi.isNotEmpty) {
    final StringBuffer sb = StringBuffer(omo.isEmpty ? '' : '一方、');
    if (hazushi.length == 1) {
      final _Henkou h = hazushi.first;
      final SenshuData? hs = h.haitta;
      final String deta = w.senshu(h.deta);
      if (hs == null) {
        sb.write('${h.x.mei}は、持ちタイムが${jouiMoji(h.deta)}の$detaを${h.kk + 1}区から外した。');
      } else {
        final String yobi = w.senshu(hs);
        sb.write(
          '${h.x.mei}は、持ちタイムが${jouiMoji(h.deta)}の$detaを${h.kk + 1}区から外し、'
          '$yobiを起用した。',
        );
        sb.write(hikakuBun(h, suisoku: false));
      }
    } else {
      final List<String> narabi = [
        for (final _Henkou h in hazushi.take(3))
          '${h.x.mei}の${w.senshu(h.deta)}(${jouiMoji(h.deta)}、${h.kk + 1}区)',
      ];
      sb.write(
        '${narabi.join('、')}${hazushi.length > 3 ? 'ら${hazushi.length}人' : ''}は、'
        '当日変更でオーダーから外れた。',
      );
    }
    // 外れた理由(体調不良・調子)が分かれば書く(1.9.4)
    final List<String> riyuuAri = [
      for (final _Henkou h in hazushi)
        if (riyuuMoji(h).isNotEmpty) '${myouji(h.deta.name)}は${riyuuMoji(h)}',
    ];
    if (riyuuAri.isEmpty) {
      sb.write(w.erabu(['理由は明らかにされていない。', '状態を見ての判断か。']));
    } else if (riyuuAri.length == hazushi.length) {
      sb.write(hazushi.length == 1 ? '${riyuuMoji(hazushi.first)}による変更だ。' : '${riyuuAri.join('、')}による変更だ。');
    } else {
      sb.write('${riyuuAri.join('、')}による変更で、ほかは理由が明らかにされていない。');
    }
    // 外れた選手は、正月駅伝の復路にも出られない
    if (race == 2) sb.write('外れた選手は、復路にも出られない。');
    w.danraku(sb.toString());
  }
  // 本文: 出番がなかった実力者(正月駅伝は、往路で使わなかった補欠を復路で使える)
  if (demasezu.isNotEmpty) {
    final List<String> narabi = [
      for (final d in demasezu.take(3))
        '${d.x.mei}の${w.senshu(d.s)}(${jouiMoji(d.s)})',
    ];
    // 温存の印(コンピュータの大学の戦略的エントリー)や体調不良が分かれば、そのことを書く(1.9.4)
    final List<String> wake = [];
    for (final d in demasezu.take(3)) {
      if (d.s.kazetaisei < 0) {
        wake.add(race == 2 && d.s.kazetaisei == -2 ? '${myouji(d.s.name)}は復路に備えた温存' : '${myouji(d.s.name)}は温存');
      } else if (d.s.chousi <= 0) {
        wake.add('${myouji(d.s.name)}は体調不良');
      }
    }
    w.danraku(
      '${hazushi.isEmpty ? '一方、' : 'また、'}${narabi.join('、')}は'
      '${race == 2 ? '往路は補欠のままで、復路での起用があるか注目される。' : '補欠のままで、今回は出番がない。'}'
      '${wake.isEmpty ? w.erabu(['故障なのか、温存なのか。', '理由は明らかにされていない。']) : '${wake.join('、')}とみられる。'}',
    );
  }
  // 本文: 1区の流れの変化
  if (paceAto != null && paceMae != null) {
    w.koMidashi('1区の流れ');
    final IkkuPaceYosou ato = paceAto;
    final IkkuPaceYosou mae = paceMae;
    final StringBuffer sb = StringBuffer('1区でも当日変更があった。');
    if (ato.midashi != mae.midashi) {
      sb.write(
        '区間エントリーどおりなら${ikkuPaceMidashiMoji[mae.midashi]}とみられていた集団のペースは、'
        '${ikkuPaceMidashiMoji[ato.midashi]}になりそうだ。',
      );
    } else {
      sb.write('集団のペースは、変わらず${ikkuPaceMidashiMoji[ato.midashi]}の予想だ。');
    }
    if (ato.pacemaker.id != mae.pacemaker.id) {
      sb.write('集団を引っ張りそうなのは、${w.senshu(ato.pacemaker, daigaku: true)}に替わった。');
    }
    w.danraku(sb.toString());
  }
  // 本文: 変更の多かった大学
  final Map<int, int> kazu = {};
  for (final _Henkou h in henkou) {
    kazu[h.x.u.id] = (kazu[h.x.u.id] ?? 0) + 1;
  }
  int ooiId = -1;
  int ooiKazu = 0;
  kazu.forEach((id, n) {
    if (n > ooiKazu) {
      ooiKazu = n;
      ooiId = id;
    }
  });
  if (ooiKazu >= 2 && daigaku.length >= 2) {
    w.danraku('最も多く入れ替えたのは${t.univMei(ooiId)}で、$ooiKazu人を変更した。');
  }

  // 表(選手は「山田太郎(3年・ハーフ1時間02分10秒)」。持ちタイムは区間の距離に合った種目)
  String hyouMei(SenshuData s, int kk) =>
      '${fullMei(s.name)}(${s.gakunen}年・'
      '${_henkouMochiMoji(k, s, kukanKihonShumoku(k.gh, race, kk))})'
      '${jouiMoji(s) == null ? '' : '※'}';
  // 載せるのは主な選手の変更だけ(入った選手か外れた選手が、持ちタイムの全体10番手以内)。
  // 区間の順(1区が一番上)に並べ、同じ区間は前評判の順。目に入りやすいよう、入った選手を左に置く
  final List<_Henkou> omoHenkou = [
    for (final _Henkou h in henkou)
      if (omo.contains(h) || hazushi.contains(h)) h,
  ]..sort((a, b) {
      final int c = a.kk.compareTo(b.kk);
      return c != 0 ? c : a.x.juni.compareTo(b.x.juni);
    });
  final List<List<String>> gyou = [
    for (final _Henkou h in omoHenkou)
      [
        '${h.kk + 1}区',
        h.x.mei,
        h.haitta == null ? '-' : hyouMei(h.haitta!, h.kk),
        hyouMei(h.deta, h.kk),
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    chokuzen: t.chokuzen,
    category: '駅伝・展望',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      if (gyou.isNotEmpty)
        KijiHyou(
          '当日変更の主な選手(持ちタイムは区間の距離に合った種目。※は1万mかハーフで全体10番手以内)',
          ['区間', '大学', '入った選手', '外れた選手'],
          gyou,
        ),
    ],
    jibun: daigaku.contains(k.gh.MYunivid),
  );
}

// ------------------------------------------------------------
// 駅伝 当日変更の読み(1.9.2で、全体の持ちタイム上位の選手が補欠のときだけにした)
// ・一次エントリーに入っている全大学の選手(補欠を含む)の中で、1万mかハーフの持ちタイム
//   (実際の記録。換算はしない)が全体10番手以内の選手が補欠に入っていたら取り上げる
//   (自分の大学は除く。自分の大学の記事で書く)。該当がいなければ記事を出さない
// ・1〜2人なら1人ずつ言い回しを変えて書き、3人以上なら1段落にまとめて表に任せる
// ------------------------------------------------------------

/// 全体の持ちタイム上位で補欠に入った選手
class _HoketsuJitsuryokusha {
  final TenbouUniv x;
  final SenshuData s;

  /// 1万mの全体の順位(0が1位。記録がなければnull)
  final int? juniIchiman;

  /// ハーフの全体の順位(0が1位。記録がなければnull)
  final int? juniHalf;

  const _HoketsuJitsuryokusha(this.x, this.s, this.juniIchiman, this.juniHalf);

  /// よいほうの順位
  int get yoiJuni {
    final int a = juniIchiman ?? 9999;
    final int b = juniHalf ?? 9999;
    return a <= b ? a : b;
  }

  /// よいほうの種目(1=1万m・2=ハーフ)
  int get yoiShumoku =>
      (juniIchiman ?? 9999) <= (juniHalf ?? 9999) ? 1 : 2;
}

/// 全体の持ちタイム上位として取り上げる順位(この順位より上。10なら10番手以内)
const int _hoketsuJougenJuni = 10;

/// 大学の前評判の言い方(「優勝候補筆頭の」「シード権を争う」など)
String _zenpyouMoji(Tenbou t, TenbouUniv x) {
  final int race = t.k.race;
  final int? seed = race == 1 ? 8 : (race == 2 ? 10 : null);
  if (x.juni == 0) return '優勝候補筆頭の';
  if (x.juni <= 2) return '上位をうかがう';
  if (seed != null && x.juni >= seed - 2 && x.juni <= seed + 1) {
    return 'シード権を争う';
  }
  return '前評判${x.juni + 1}番手の';
}

Kiji? _toujitsuTenbou(Tenbou t) {
  final KijiKankyou k = t.k;
  const int no = 3;
  // 出場全選手(一次エントリー。補欠を含む)の、1万mとハーフの持ちタイムの順
  final List<SenshuData> zenin = [
    for (final TenbouUniv x in t.jun) ...x.ichiji,
  ];
  List<SenshuData> jun(int idx) => [
    for (final SenshuData s in zenin)
      if (k.jikoBest(s, idx) < TEISUU.DEFAULTTIME) s,
  ]..sort((a, b) => k.jikoBest(a, idx).compareTo(k.jikoBest(b, idx)));
  final List<SenshuData> junIchiman = jun(1);
  final List<SenshuData> junHalf = jun(2);
  int? juniDe(List<SenshuData> l, SenshuData s) {
    final int i = l.indexWhere((d) => d.id == s.id);
    return i < 0 ? null : i;
  }

  // 全体10番手以内で補欠の選手(自分の大学は除く)
  final List<_HoketsuJitsuryokusha> hoketsu = [];
  for (final TenbouUniv x in t.jun) {
    if (x.u.id == k.gh.MYunivid) continue;
    for (final SenshuData s in x.ichiji) {
      if (k.entry(s) != -1) continue;
      final _HoketsuJitsuryokusha h = _HoketsuJitsuryokusha(
        x,
        s,
        juniDe(junIchiman, s),
        juniDe(junHalf, s),
      );
      if (h.yoiJuni < _hoketsuJougenJuni) hoketsu.add(h);
    }
  }
  if (hoketsu.isEmpty) return null;
  hoketsu.sort((a, b) {
    final int c = a.yoiJuni.compareTo(b.yoiJuni);
    return c != 0 ? c : a.x.juni.compareTo(b.x.juni);
  });
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, _taneNo(t, no)));
  final int kazu = hoketsu.length;
  final _HoketsuJitsuryokusha h0 = hoketsu.first;

  // 「1万m全体3位」の言い方と、持ちタイムを添えた言い方
  String juniMei(_HoketsuJitsuryokusha h) =>
      '${kijiShumokuMei[h.yoiShumoku]}全体${h.yoiJuni + 1}位';
  String mochiTsuki(_HoketsuJitsuryokusha h) =>
      '${juniMei(h)}の持ちタイム(${jikanMoji(k.jikoBest(h.s, h.yoiShumoku))})';

  // 見出し
  String midashi;
  if (kazu == 1) {
    midashi = w.erabu([
      '${h0.x.mei}、${myouji(h0.s.name)}を補欠に　${juniMei(h0)}',
      '${juniMei(h0)}の${myouji(h0.s.name)}(${h0.x.mei})が補欠',
    ]);
  } else if (kazu == 2) {
    midashi = '持ちタイム上位の2人が補欠に　当日変更に注目';
  } else {
    midashi = '$kazu人の実力者が補欠に　当日変更の駆け引き';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}の区間エントリーで、出場全選手の中で1万mかハーフの持ちタイムが'
    '$_hoketsuJougenJuni番手以内の選手${kazu == 1 ? 'が' : 'のうち$kazu人が'}補欠に回った。',
  );
  lead.write(
    w.erabu([
      '故障か、それとも当日変更での起用をにらんだ温存か。',
      '体調の問題なのか、当日変更を見越した作戦なのか。',
    ]),
  );
  lead.write('当日変更を前提にした、いわゆる戦略的エントリーとの見方もある。');

  // 本文
  if (kazu <= 2) {
    for (int i = 0; i < kazu; i++) {
      final _HoketsuJitsuryokusha h = hoketsu[i];
      final String yobi = w.senshu(h.s);
      if (i == 0) {
        w.danraku(
          '${_zenpyouMoji(t, h.x)}${h.x.mei}は、${mochiTsuki(h)}を持つ$yobiを補欠に置いた。'
          '${w.erabu(['どの区間に入るかで、レースの流れが変わりそうだ。', '起用される区間が、勝負の分かれ目になりそうだ。'])}',
        );
      } else {
        w.danraku(
          '${_zenpyouMoji(t, h.x)}${h.x.mei}の$yobiも、${mochiTsuki(h)}を持ちながら補欠に入った。'
          '${w.erabu(['当日の起用があれば、一気に流れを変えうる存在だ。', 'こちらも当日変更での起用があるか注目される。'])}',
        );
      }
    }
  } else {
    final List<String> narabi = [
      for (final _HoketsuJitsuryokusha h in hoketsu)
        '${h.x.mei}の${w.senshu(h.s)}(${juniMei(h)})',
    ];
    w.danraku(
      '補欠に入ったのは、${narabi.join('、')}。'
      '${w.erabu(['各校の当日変更の一手が、レースの流れを大きく左右しそうだ。', 'どの大学が、どの区間で切り札を切るのか。駆け引きは当日の朝まで続く。'])}',
    );
  }
  w.danraku('当日変更は、レース当日の朝に発表される。');

  // 表
  String timeMoji(SenshuData s, int idx) {
    final double v = k.jikoBest(s, idx);
    return v >= TEISUU.DEFAULTTIME ? '-' : jikanMoji(v);
  }

  String juniMoji2(_HoketsuJitsuryokusha h) => [
    if (h.juniIchiman != null && h.juniIchiman! < _hoketsuJougenJuni)
      '1万m${h.juniIchiman! + 1}位',
    if (h.juniHalf != null && h.juniHalf! < _hoketsuJougenJuni)
      'ハーフ${h.juniHalf! + 1}位',
  ].join('・');

  final List<List<String>> gyou = [
    for (final _HoketsuJitsuryokusha h in hoketsu)
      [
        h.x.mei,
        '${fullMei(h.s.name)}(${h.s.gakunen})',
        timeMoji(h.s, 1),
        timeMoji(h.s, 2),
        juniMoji2(h),
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    chokuzen: t.chokuzen,
    category: '駅伝・展望',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        '補欠に入った持ちタイム上位の選手',
        ['大学', '選手', '1万m', 'ハーフ', '全体順位'],
        gyou,
      ),
    ],
  );
}

// ------------------------------------------------------------
// 4. 自分の大学(駅伝・予選)
// ------------------------------------------------------------

Kiji? _jibunTenbou(Tenbou t, List<KijiYosouJin> yosou) {
  final TenbouUniv? m = t.jibun;
  if (m == null) return null;
  final KijiKankyou k = t.k;
  const int no = 4;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, _taneNo(t, no)));
  final int race = k.race;
  final int ks = t.ks;
  final String mm = m.mei;
  final int r = m.juni;
  final int mae = juniRace(m.u, race, 0);
  final bool maeAri = shutsujouJuni(mae);
  final int? seed = race == 1 ? 8 : (race == 2 ? 10 : null);
  final int? ts = race == 3 ? 7 : (race == 4 ? 10 : null);
  final SenshuData? a = t.ace(m);
  final bool ouja = maeAri && mae == 0 && k.ekiden;
  // 記者の型(1.9.4)
  final KishaKata kata = k.kishaKata(_taneNo(t, no));
  // 走る選手の因縁(駅伝だけ。レース前なので kekka: false。1.9.4)
  final Map<int, List<Innen>> innen = {};
  if (k.ekiden) {
    for (final SenshuData s in m.hashiru) {
      final int kk = k.entry(s);
      if (kk >= 0 && kk < ks) innen[s.id] = senshuInnen(k, s, kk, kekka: false);
    }
  }
  // 注目選手(因縁の点が一番高い選手。エースと別の選手を優先する)
  SenshuData? chuumoku;
  int chuumokuTen = 0;
  for (final SenshuData s in m.hashiru) {
    final List<Innen> l = innen[s.id] ?? const [];
    if (l.isEmpty) continue;
    final int ten = l.first.ten - (a != null && s.id == a.id ? 20 : 0);
    if (ten > chuumokuTen) {
      chuumokuTen = ten;
      chuumoku = s;
    }
  }
  if (chuumoku != null && (innen[chuumoku.id]?.first.ten ?? 0) < 45) chuumoku = null;

  // 見出し
  String midashi;
  if (ts != null) {
    midashi = r < ts - 2
        ? '$mm、本戦切符へ好位置　前評判${r + 1}番手'
        : (r < ts + 2
              ? '$mm、通過ライン上の激戦へ　前評判${r + 1}番手'
              : '$mm、逆転通過へ挑む　前評判${r + 1}番手');
  } else if (r == 0) {
    midashi = w.erabu(['$mmが優勝候補筆頭', '$mm、頂点へ本命']);
  } else if (ouja) {
    midashi = '前回王者$mm、連覇へ挑む　前評判${r + 1}番手';
  } else if (seed != null && r >= seed - 2 && r <= seed + 1) {
    midashi = '$mm、シード権争いへ　前評判${r + 1}番手';
  } else {
    midashi = '$mmは前評判${r + 1}番手';
  }
  if (a != null && k.entry(a) >= 0) {
    midashi += race == 4
        ? '　エースは${myouji(a.name)}'
        : '　エース${myouji(a.name)}は${k.entry(a) + 1}${race == 3 ? '組' : '区'}';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    t.chokuzen
        ? '${k.taikaiMei}に挑む$mmは、当日変更を終えてオーダーが固まった。'
        : '${k.taikaiMei}に挑む$mmの${race == 4 ? 'エントリー' : '区間エントリー'}が決まった。',
  );
  lead.write('本紙の戦力分析では、出場${t.n}校中${r + 1}番手の評価だ。');
  if (maeAri) {
    lead.write('前回は${juniMoji(mae)}だった。');
  } else if (shutsujouKaisuu(m.u, race) == 0) {
    lead.write(mikaisai(k, race) ? '今回が初めての開催となる。' : '今回が初めての出場となる。');
  }
  if (ts != null) {
    lead.write('上位$ts校が手にする本戦への切符を目指す。');
  } else if (seed != null) {
    lead.write(r < seed ? 'シード権の確保は十分に射程圏内だ。' : 'シード権の獲得へ、一つでも上の順位を目指す。');
  }

  // 本文
  w.koMidashi('布陣');
  if (a != null) {
    final int kk = k.entry(a);
    final String m1 = t.mochiMoji(a, t.heikinShumoku);
    w.danraku(
      'エースの${w.senshu(a)}${m1.isEmpty ? '' : '($m1)'}は'
      '${race == 4 ? '個人でも上位を狙う。' : '${t.kukanMei(kk)}に入った。'}'
      '${race == 4 ? '' : (t.kukanNoJuni(a, kk) == 0 ? 'この${race == 3 ? '組' : '区間'}の持ちタイムでトップだ。' : '')}',
    );
  }
  // スタート直前号: 自分の大学の当日変更(外れた理由と持ちタイムの比べは ToujituJijou。1.9.4)
  if (t.chokuzen) {
    final List<_Henkou> jibunHenkou = [
      for (final _Henkou h in _henkouIchiran(t))
        if (h.x.u.id == m.u.id) h,
    ];
    final List<SenshuData?> kukanSenshu = [
      for (int kk = 0; kk < ks; kk++)
        m.hashiru.where((s) => k.entry(s) == kk).firstOrNull,
    ];
    final Map<int, ToujituJijou> jijou = toujituJijou(k, m.u, kukanSenshu);
    if (jibunHenkou.isEmpty) {
      w.danraku('当日変更はせず、区間エントリーどおりのオーダーで臨む。');
    } else if (jijou.isNotEmpty) {
      for (final int kk in jijou.keys.toList()..sort()) {
        final ToujituJijou j = jijou[kk]!;
        final StringBuffer sb = StringBuffer(toujituJijouBun(j, w));
        if (j.riyuu == HazuretaRiyuu.taichouFuryou) {
          sb.write('${myouji(j.hairi.name)}は、${myouji(j.hazureta.name)}の分まで走ることになる。');
        }
        w.danraku(sb.toString());
      }
    } else {
      // 選手には、区間の距離に合った種目の持ちタイムを添える
      final List<String> bun = [];
      for (final _Henkou h in jibunHenkou) {
        final SenshuData? haitta = h.haitta;
        final int idx = kukanKihonShumoku(k.gh, race, h.kk);
        if (haitta == null) {
          final String deta = _senshuMochi(w, h.deta, _henkouMochiMoji(k, h.deta, idx));
          bun.add('${h.kk + 1}区の$detaを外し');
        } else {
          // 名前は出す順に作る(入った選手が先)
          final String hairu = _senshuMochi(w, haitta, _henkouMochiMoji(k, haitta, idx));
          final String deta = _senshuMochi(w, h.deta, _henkouMochiMoji(k, h.deta, idx));
          bun.add('${h.kk + 1}区に$hairuを起用して$detaを外し');
        }
      }
      w.danraku('当日変更では、${bun.join('、')}た。');
    }
  }
  // 1区のペース(駅伝)
  if (ikkuPaceTaishou(race)) {
    SenshuData? s1;
    for (final SenshuData s in m.hashiru) {
      if (k.entry(s) == 0) s1 = s;
    }
    final IkkuPaceYosou? pace = ikkuPaceYosou(
      gh: k.gh,
      racebangou: race,
      sortedSenshu: k.senshu,
      sortedUniv: k.univ,
      kantoku: k.kantoku,
      chousiIreru: t.chokuzen,
    );
    if (s1 != null && pace != null) {
      final IkkuAishou ai = pace.aishou(s1.id);
      final String yobi = w.senshu(s1);
      String bun = '';
      switch (ai) {
        case IkkuAishou.hipparu:
          bun = '1区の$yobiは、集団を引っ張る役回りになりそうだ。';
          break;
        case IkkuAishou.osokuSon:
          bun = '1区の$yobiにとって、予想される${ikkuPaceMidashiMoji[pace.midashi]}はやや物足りない流れになりそうだ。';
          break;
        case IkkuAishou.sukoshiToku:
          bun = '1区の$yobiは、予想される流れにうまく乗れれば好走が期待できる。';
          break;
        case IkkuAishou.sonTokuNashi:
          bun = '1区の$yobiは、速めの流れにも対応できそうだ。';
          break;
        case IkkuAishou.daiShissoku:
          bun = '1区の$yobiは、予想される速い流れに無理について行くと、後半の失速が心配だ。';
          break;
        case IkkuAishou.tobidashi:
          bun = '1区の$yobiが、スタートからどう動くか注目される。';
          break;
      }
      w.danraku(bun);
    }
  }
  // 1年生と4年生
  final List<SenshuData> ichinen = [
    for (final SenshuData s in m.hashiru)
      if (s.gakunen == 1) s,
  ];
  if (ichinen.isNotEmpty && !k.ichinenDake) {
    w.danraku(
      ichinen.length >= 3
          ? '${ichinen.length}人の1年生がメンバー入りし、新しい力が台頭している。'
          : '1年生の${ichinen.map((s) => w.senshu(s)).join('、')}がメンバーに名を連ねた。',
    );
  }
  if (race == 2) {
    final List<SenshuData> yonen = [
      for (final SenshuData s in m.hashiru)
        if (s.gakunen == 4) s,
    ];
    if (yonen.isNotEmpty) {
      w.danraku(
        '4年生の${yonen.map((s) => w.senshu(s)).join('、')}にとっては、最後の正月駅伝となる。',
      );
    }
  }
  // 補欠の主力(駅伝)
  if (k.ekiden) {
    final List<SenshuData> jun = List<SenshuData>.of(m.ichiji)
      ..sort((x, y) {
        final double tx = t.sougou(x) ?? TEISUU.DEFAULTTIME;
        final double ty = t.sougou(y) ?? TEISUU.DEFAULTTIME;
        return tx.compareTo(ty);
      });
    for (int i = 0; i < jun.length && i < 3; i++) {
      if (k.entry(jun[i]) == -1) {
        w.danraku(
          t.chokuzen
              ? 'チーム${i + 1}番手の${w.senshu(jun[i])}は補欠のままで、今回は出番がない。'
              : 'チーム${i + 1}番手の${w.senshu(jun[i])}は補欠に入った。当日変更での起用があるかも注目される。',
        );
        break;
      }
    }
  }
  // 前回の区間賞(駅伝)
  if (k.ekiden) {
    for (final SenshuData s in m.hashiru) {
      if (k.kukanJuniMae(s, race, 1) != 0) continue;
      final int mk = k.entryMae(s, race, 1);
      if (mk < 0) continue;
      final int kk = k.entry(s);
      w.danraku(
        mk == kk
            ? '前回${kk + 1}区で区間賞の${w.senshu(s)}は、同じ区間で連続区間賞を狙う。'
            : '前回${mk + 1}区で区間賞の${w.senshu(s)}は、今回${kk + 1}区を任された。',
      );
      break;
    }
  }
  // 予想陣の評価
  if (yosou.isNotEmpty) {
    final String shirushi = yosou.map((y) => _shirushi(y, m.u.id)).join();
    final int hon = shirushi.split('').where((c) => c == '◎').length;
    if (hon >= 1) {
      w.danraku('予想陣のうち$hon人が$mmを本命に推している。');
    } else {
      final List<String> jun = [
        for (final KijiYosouJin y in yosou)
          if (y.univJun.contains(m.u.id))
            '${y.mei}は${y.univJun.indexOf(m.u.id) + 1}番手',
      ];
      if (jun.isNotEmpty) w.danraku('予想陣の評価は、${jun.join('、')}。');
    }
  }
  // 注目選手(因縁のある選手。1.9.4)
  if (chuumoku != null && k.ekiden) {
    final Innen ci = innen[chuumoku.id]!.first;
    final int kk = k.entry(chuumoku);
    final String yobi = w.senshu(chuumoku);
    w.danraku(
      w.erabu([
        '${t.kukanMei(kk)}の$yobiには、因縁がある。${ci.bun}',
        '注目したいのは${t.kukanMei(kk)}の$yobiだ。${ci.bun}',
      ]),
    );
    w.comment(
      senshuCommentJijitsu(
        w,
        CommentBamen.ikigomi,
        myouji(chuumoku.name),
        jijitsu: [ci.kotoba],
      ),
    );
    if (a == null || chuumoku.id != a.id) {
      w.danraku(shusshinShumiBun(k, chuumoku, w.r, myouji(chuumoku.name)));
    }
  }
  // エースのコメント(因縁と持ちタイムの事実入り。1.9.4)
  if (a != null && (chuumoku == null || chuumoku.id != a.id)) {
    final int kk = k.entry(a);
    final List<Innen> ai = innen[a.id] ?? const [];
    w.comment(
      senshuCommentJijitsu(
        w,
        CommentBamen.ikigomi,
        myouji(a.name),
        jijitsu: [
          if (ai.isNotEmpty) ai.first.kotoba,
          if (k.ekiden && kk >= 0 && t.kukanNoJuni(a, kk) == 0)
            '持ちタイムでは区間のトップ。自分の走りをすれば、結果はついてくると思う',
          if (k.ekiden && kk >= 0 && t.kukanNoJuni(a, kk) > 0)
            'エースと言われるけど、区間には自分より速い選手がいる。挑戦者のつもりで走る',
        ],
      ),
    );
    w.danraku(shusshinShumiBun(k, a, w.r, myouji(a.name)));
  } else if (a != null) {
    w.danraku(shusshinShumiBun(k, a, w.r, myouji(a.name)));
  }
  final bool honmei = ts != null ? r < ts - 2 : (r <= 1 || ouja);
  w.comment(
    kantokuComment(
      w,
      honmei ? KantokuBamen.tenbouHonmei : KantokuBamen.tenbouChousen,
      m.u.id,
    ),
  );

  // 本紙の見立て(記者の型で見方が変わる。駅伝だけ。1.9.4)
  if (k.ekiden) {
    final StringBuffer me = StringBuffer();
    // 区間内の持ちタイムの順位が一番低い区間(鍵を握る区間)
    int kagiKk = -1;
    int kagiJuni = -1;
    SenshuData? kagiS;
    for (final SenshuData s in m.hashiru) {
      final int kk = k.entry(s);
      if (kk < 0 || kk >= ks) continue;
      final int j = t.kukanNoJuni(s, kk);
      if (j > kagiJuni) {
        kagiJuni = j;
        kagiKk = kk;
        kagiS = s;
      }
    }
    switch (kata) {
      case KishaKata.suuji:
        me.write('本紙の戦力分析は${r + 1}番手。区間ごとの持ちタイムの順位を足すと${m.kukanJuni + 1}番手だ。');
        if (maeAri) {
          me.write(
            mae + 1 > r + 1
                ? '前回の${juniMoji(mae)}より評価は高く、数字の上では上積みが見込める。'
                : (mae + 1 < r + 1 ? '前回の${juniMoji(mae)}より評価は低い。数字を覆す走りがいる。' : '前回と同じ${juniMoji(mae)}相当の評価だ。'),
          );
        }
        if (seed != null) {
          me.write(r < seed ? 'シード権のラインまでは、順位にして${seed - r}つの余裕がある。' : 'シード権のラインまで、順位を${r - seed + 1}つ上げる必要がある。');
        }
        break;
      case KishaKata.joukei:
        if (chuumoku != null) {
          final String my = myouji(chuumoku.name);
          me.write('この大学の今日を語るなら、${k.entry(chuumoku) + 1}区の$myだ。');
          me.write(innen[chuumoku.id]!.first.midashiKu.isNotEmpty ? '${innen[chuumoku.id]!.first.midashiKu}走りが、チームの流れを決める。' : 'その走りが、チームの流れを決める。');
        } else if (a != null) {
          me.write('この大学の今日を語るなら、エースの${myouji(a.name)}だ。たすきを受けたときの順位より、渡すときの順位を見たい。');
        } else {
          me.write('$ks人全員でつなぐ駅伝になる。');
        }
        break;
      case KishaKata.karakuchi:
        if (kagiS != null && kagiKk >= 0) {
          me.write('鍵を握るのは${kagiKk + 1}区だ。${myouji(kagiS.name)}の持ちタイムは区間内${kagiJuni + 1}番目。');
          me.write('ここで流れを止めなければ、前評判${r + 1}番手より上の景色が見える。');
        } else {
          me.write('前評判${r + 1}番手。評価どおりに走れるかどうかは、1区の入りで決まる。');
        }
        break;
    }
    w.kishaNoMe(me.toString(), midashi: '本紙の見立て');
  }

  // 布陣の表(区間(組)の中は持ちタイム順)
  final List<List<String>> gyou = [];
  for (int kk = 0; kk < ks; kk++) {
    final int idx = t.shumoku[kk];
    for (int i = 0; i < t.kukanJun[kk].length; i++) {
      final SenshuData s = t.kukanJun[kk][i];
      if (s.univid != m.u.id) continue;
      final double mt = t.mochi(s, kk);
      gyou.add([
        if (race != 4) (race == 3 ? '${kk + 1}組' : '${kk + 1}区'),
        '${fullMei(s.name)}(${s.gakunen})',
        kijiShumokuMei[idx],
        mt >= TEISUU.DEFAULTTIME ? '-' : jikanMoji(mt),
        mt >= TEISUU.DEFAULTTIME ? '-' : '${i + 1}番目',
      ]);
    }
  }
  return _kansei(
    k,
    no,
    w,
    chokuzen: t.chokuzen,
    category: '${k.ekiden ? '駅伝' : '駅伝予選'}・展望・$mm',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        '$mmの布陣',
        [
          if (race != 4) (race == 3 ? '組' : '区間'),
          '選手',
          '種目',
          '持ちタイム',
          race == 4 ? '全体' : (race == 3 ? '組内' : '区間内'),
        ],
        gyou,
      ),
    ],
    jibun: true,
  );
}

// ------------------------------------------------------------
// 予選 1. 通過争い
// ------------------------------------------------------------

Kiji _tsuukaTenbou(Tenbou t, List<KijiYosouJin> yosou) {
  final KijiKankyou k = t.k;
  const int no = 1;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, _taneNo(t, no)));
  final int race = k.race;
  final int ts = race == 3 ? 7 : 10;
  final int honsen = race == 3 ? 1 : 2;
  final String honsenMei = race == 3 ? '11月駅伝' : '正月駅伝';
  final TenbouUniv hon = t.jun[0];
  // 本戦がまだ一度も行われていないか(ゲームを始めた年など)
  final bool honsenMikaisai = mikaisai(k, honsen);

  // 前回の本戦に出ていた大学(予選の前なので、本戦の記録の[0]が前回)
  final List<TenbouUniv> maeHonsen = [
    for (final TenbouUniv x in t.jun)
      if (shutsujouJuni(juniRace(x.u, honsen, 0))) x,
  ];
  // 本戦に出たことがなく、前評判で通過圏の大学
  final List<TenbouUniv> hatsuNerau = [
    for (final TenbouUniv x in t.jun)
      if (!honsenMikaisai &&
          x.juni < ts &&
          shutsujouKaisuu(x.u, honsen) == 0)
        x,
  ];
  // 前回の予選でトップ通過
  TenbouUniv? maeTop;
  for (final TenbouUniv x in t.jun) {
    if (juniRace(x.u, race, 0) == 0) maeTop = x;
  }
  // 通過ラインの前後(前評判の通過ラインの上下2校ずつ)
  final List<TenbouUniv> kyoukai = [
    for (final TenbouUniv x in t.jun)
      if (x.juni >= ts - 2 && x.juni <= ts + 1) x,
  ];
  // 通過ラインの前後のチームの平均の差(秒)
  int lineSa = 0;
  if (t.n > ts) {
    final double a = t.jun[ts - 1].heikin;
    final double b = t.jun[ts].heikin;
    if (a < TEISUU.DEFAULTTIME && b < TEISUU.DEFAULTTIME) {
      lineSa = saByou(b, a);
    }
  }

  // 見出し
  String midashi;
  TenbouUniv? kiken; // 前回の本戦に出ていて、前評判で通過圏の外の大学
  for (final TenbouUniv x in maeHonsen) {
    if (x.juni >= ts) {
      kiken = x;
      break;
    }
  }
  if (kiken != null) {
    midashi =
        '前回$honsenMei出場の${kiken.mei}に黄信号　前評判${kiken.juni + 1}番手';
    midashi += '　本命は${hon.mei}';
  } else if (t.n > ts && lineSa <= 3) {
    midashi = '通過ラインは大激戦　${kyoukai.map((x) => x.mei).take(3).join('・')}が当落線上';
  } else {
    midashi = w.erabu([
      '${hon.mei}がトップ通過候補',
      '${hon.mei}が本命　$ts枠を巡る争い',
    ]);
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(_gouhou(k, w, t.chokuzen));
  lead.write('上位$ts校に$honsenMeiの出場権が与えられる。');
  if (honsenMikaisai) {
    lead.write('$honsenMeiは今回が初めての開催で、どの大学も初出場を懸けて走る。');
  }
  lead.write(
    '出場${t.n}校のエントリーをもとにした本紙の戦力分析では、${hon.mei}が'
    '${race == 3 ? '走る8人' : '上位10人'}の${t.heikinMei}平均${t.heikinMoji(hon)}でトップに立つ。',
  );
  if (t.n > ts) {
    lead.write(
      '通過ラインの$ts番手${t.jun[ts - 1].mei}と${ts + 1}番手${t.jun[ts].mei}の${t.heikinMei}平均の差は'
      '${saMoji(lineSa)}しかない。',
    );
  }

  // 本文: 有力校
  w.koMidashi('有力校');
  {
    final StringBuffer sb = StringBuffer();
    sb.write('トップ通過候補の${hon.mei}は');
    final SenshuData? a = t.ace(hon);
    if (a != null) {
      final String m1 = t.mochiMoji(a, t.heikinShumoku);
      sb.write('エースの${w.senshu(a)}${m1.isEmpty ? '' : '($m1)'}を中心に、');
    }
    sb.write(w.erabu(['選手層の厚さで他校を上回る。', '大きな穴のない布陣を組んだ。']));
    if (maeTop != null && maeTop.u.id == hon.u.id) {
      sb.write('前回もトップ通過を果たしている。');
    }
    w.danraku(sb.toString());
  }
  if (t.n >= 3) {
    w.danraku(
      '${t.jun[1].mei}、${t.jun[2].mei}が続き、'
      '${w.erabu(['上位争いは三つどもえの様相だ。', 'トップ通過を争う。'])}',
    );
  }
  if (maeTop != null && maeTop.u.id != hon.u.id) {
    w.danraku('前回トップ通過の${maeTop.mei}は、前評判${maeTop.juni + 1}番手。');
  }

  // 本文: 通過ライン
  if (t.n > ts) {
    w.koMidashi('通過ライン');
    w.danraku(
      '最大の焦点は$ts枠目の争いだ。前評判で当落線上にいるのは'
      '${kyoukai.map((x) => '${x.mei}(${x.juni + 1}番手)').join('、')}。'
      '${w.erabu(['わずかな差が明暗を分けそうだ。', '一人ひとりの粘りが、結果を左右する。'])}',
    );
    final TenbouUniv kyou = t.jun[ts - 1];
    w.comment(kantokuComment(w, KantokuBamen.tenbouChousen, kyou.u.id));
  }

  // 本文: 前回の本戦組・初の本戦を狙う大学
  if (maeHonsen.isNotEmpty || hatsuNerau.isNotEmpty) {
    w.koMidashi('出場校');
    if (maeHonsen.isNotEmpty) {
      w.danraku(
        '前回の$honsenMeiに出場した'
        '${maeHonsen.map((x) => '${x.mei}(前回${juniMoji(juniRace(x.u, honsen, 0))})').join('、')}は、'
        '予選からの出直しとなる。',
      );
    }
    if (hatsuNerau.isNotEmpty) {
      w.danraku(
        '${hatsuNerau.map((x) => x.mei).join('、')}は前評判で通過圏にいて、初の$honsenMei出場を狙う。',
      );
    }
  }
  // 予想陣
  if (yosou.isNotEmpty) {
    final List<String> bun = [
      for (final KijiYosouJin y in yosou)
        if (y.univJun.isNotEmpty)
          '${y.mei}は${t.univMei(y.univJun.first)}',
    ];
    if (bun.isNotEmpty) {
      w.danraku('予想陣のトップ通過予想は、${bun.join('、')}。');
    }
  }

  return _kansei(
    k,
    no,
    w,
    chokuzen: t.chokuzen,
    category: '駅伝予選・展望',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [_maeHyoubanHyou(t, yosou, ekiden: false)],
    jibun: hon.u.id == k.gh.MYunivid,
  );
}

// ------------------------------------------------------------
// 予選 2. 注目選手
// ------------------------------------------------------------

Kiji? _chuumokuTenbou(Tenbou t, List<KijiYosouJin> yosou) {
  final KijiKankyou k = t.k;
  const int no = 2;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, _taneNo(t, no)));
  final int race = k.race;
  final int ks = t.ks;
  if (t.kukanJun.isEmpty || t.kukanJun[0].isEmpty) return null;

  if (race == 3) {
    // 持ちタイムが一番速い組
    int hayai = 0;
    double hayaiT = TEISUU.DEFAULTTIME;
    for (int kk = 0; kk < ks; kk++) {
      if (t.kukanJun[kk].isEmpty) continue;
      final double tt = t.mochi(t.kukanJun[kk].first, kk);
      if (tt < hayaiT) {
        hayaiT = tt;
        hayai = kk;
      }
    }
    final SenshuData a = t.kukanJun[hayai].first;
    final String midashi = w.erabu([
      '${hayai + 1}組に${myouji(a.name)}(${t.univMei(a.univid)})　各組の注目選手',
      '各組の見どころ　${hayai + 1}組は${myouji(a.name)}が持ちタイムトップ',
    ]);
    final StringBuffer lead = StringBuffer();
    lead.write(
      '${k.taikaiMei}は全$ks組で行われ、各校が1組に2人ずつ選手を送り込む。'
      '組ごとの持ちタイムから、注目選手を探った。',
    );
    for (int kk = 0; kk < ks; kk++) {
      final List<SenshuData> j = t.kukanJun[kk];
      if (j.isEmpty) continue;
      final int idx = t.shumoku[kk];
      final StringBuffer sb = StringBuffer();
      final String ma = t.mochiMoji(j[0], idx);
      sb.write(
        '${kk + 1}組は${w.senshu(j[0], daigaku: true)}${ma.isEmpty ? '' : '($ma)'}が持ちタイムトップ。',
      );
      final List<String> tsuzuku = [
        for (final SenshuData s in j.skip(1).take(2))
          if (t.mochiMoji(s, idx).isNotEmpty) '${w.senshu(s)}(${t.univMei(s.univid)})',
      ];
      if (tsuzuku.isNotEmpty) sb.write('${tsuzuku.join('、')}が続く。');
      final int? soroi = _soroiKukanshou(t, yosou, kk);
      if (soroi != null) {
        sb.write('予想陣は3人そろって${w.senshu(k.senshu[soroi], daigaku: true)}の組トップを予想した。');
      }
      if (kk == ks - 1) sb.write('最終組は各校のエースがそろい、通過争いの行方を決める。');
      w.danraku(sb.toString());
    }
    w.comment(senshuComment(w, CommentBamen.ikigomi, myouji(a.name)));
    final List<List<String>> gyou = [];
    for (int kk = 0; kk < ks; kk++) {
      final int idx = t.shumoku[kk];
      for (final SenshuData s in t.kukanJun[kk].take(3)) {
        final double mt = t.mochi(s, kk);
        gyou.add([
          '${kk + 1}組',
          '${fullMei(s.name)}(${s.gakunen})',
          t.univMei(s.univid),
          mt >= TEISUU.DEFAULTTIME ? '-' : '${kijiShumokuMei[idx]} ${jikanMoji(mt)}',
        ]);
      }
    }
    return _kansei(
      k,
      no,
      w,
      chokuzen: t.chokuzen,
      category: '駅伝予選・展望',
      midashi: midashi,
      lead: lead.toString(),
      hyou: [
        KijiHyou('各組の持ちタイム上位3人', ['組', '選手', '大学', '持ちタイム'], gyou),
      ],
      jibun: a.univid == k.gh.MYunivid,
    );
  }

  // 正月駅伝予選: 個人の争い
  final List<SenshuData> j = t.kukanJun[0];
  final int idx = t.shumoku[0];
  final SenshuData a = j[0];
  SenshuData? ryuu; // 持ちタイム上位の留学生
  SenshuData? nihon; // 持ちタイムが一番いい日本人
  for (final SenshuData s in j.take(10)) {
    if (s.hirou == 1) {
      ryuu ??= s;
    } else {
      nihon ??= s;
    }
  }
  // 前回の個人トップ(今回も走る選手)
  SenshuData? maeTop;
  for (final SenshuData s in j) {
    if (k.kukanJuniMae(s, race, 1) == 0) maeTop = s;
  }
  final String midashi = maeTop != null
      ? '前回個人トップの${myouji(maeTop.name)}(${t.univMei(maeTop.univid)})、連覇狙う'
      : w.erabu([
          '個人争いは${myouji(a.name)}(${t.univMei(a.univid)})が中心',
          '${myouji(a.name)}(${t.univMei(a.univid)})が持ちタイムトップ　個人の争い',
        ]);
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}は全選手が一斉にスタートし、各校の上位10人の合計タイムで争う。'
    '個人の争いでは、${kijiShumokuMei[idx]}の持ちタイムで${w.senshu(a, daigaku: true)}'
    '${t.mochiMoji(a, idx).isEmpty ? '' : '(${t.mochiMoji(a, idx)})'}がトップに立つ。',
  );
  final List<String> tsuzuku = [
    for (final SenshuData s in j.skip(1).take(4))
      if (t.mochiMoji(s, idx).isNotEmpty) '${w.senshu(s, daigaku: true)}(${t.mochiMoji(s, idx)})',
  ];
  if (tsuzuku.isNotEmpty) {
    w.danraku('持ちタイムの上位には${tsuzuku.join('、')}が並ぶ。');
  }
  if (ryuu != null && nihon != null && ryuu.id == a.id) {
    w.danraku('日本人トップ争いでは、${w.senshu(nihon, daigaku: true)}が最上位の持ちタイムを持つ。');
  }
  if (maeTop != null) {
    w.danraku('前回個人トップの${w.senshu(maeTop, daigaku: true)}も出場し、2年連続の個人トップを狙う。');
  }
  final int? soroi = _soroiKukanshou(t, yosou, 0);
  if (soroi != null) {
    w.danraku('予想陣は3人そろって${w.senshu(k.senshu[soroi], daigaku: true)}の個人1位を予想した。');
  }
  w.comment(senshuComment(w, CommentBamen.ikigomi, myouji(a.name)));
  final List<List<String>> gyou = [
    for (final SenshuData s in j.take(10))
      [
        fullMei(s.name),
        '${s.gakunen}',
        t.univMei(s.univid),
        t.mochi(s, 0) >= TEISUU.DEFAULTTIME ? '-' : jikanMoji(t.mochi(s, 0)),
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    chokuzen: t.chokuzen,
    category: '駅伝予選・展望',
    midashi: midashi,
    lead: lead.toString(),
    hyou: [
      KijiHyou(
        '${kijiShumokuMei[idx]}の持ちタイム上位10人',
        ['選手', '学年', '大学', 'タイム'],
        gyou,
      ),
    ],
    jibun: a.univid == k.gh.MYunivid,
  );
}
