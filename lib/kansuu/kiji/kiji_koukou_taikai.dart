import 'dart:math' show sqrt;
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/koukou.dart'; // 出身校と高校の大会の記録(1.9.5)
import 'package:ekiden/kansuu/koukou_meibo.dart' show koukouChikuMei;
import 'package:ekiden/kansuu/scout_com.dart'
    show isComScoutOn, comScoutKotoshiChikuMeguri, comScoutChikuJunban, comScoutSenshuChiku;
import 'package:ekiden/kansuu/bokou_pipe.dart' show BokouPipe; // 監督の母校パイプ(2.0.1)
import 'package:ekiden/kansuu/kyouka_project.dart' show KyoukaProject, kyoukaProjectChuu; // 強化プロジェクト(2.0.1)
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';

// ------------------------------------------------------------
// スカウト前の高校の大会の記事(2.0.1。箱庭スポーツ「スカウト解禁」)
// ・新入生のスカウトの画面を開いたとき、1ラウンド目の前に出す(1.9.9からの「今年の高校の大会」の結果の画面の
//   代わり。結果の画面は、記事の最後のボタンと高校名鑑から見られる)。スカウトの画面の上の帯の新聞のアイコンからも読める
// ・進学先が決まる前の記事なので、4月5日の「期待のルーキー」(進学先が決まったあとの記事)とは分ける:
//   「チームの駅伝の物語」(全国高校駅伝の優勝校・接戦)、「世代の層」(13分台の人数)、「名門校のそろい踏み」と、
//   「スカウトの見どころ」(地区めぐりの最初の地区・監督の母校・強化プロジェクト)を中心にする。
//   個人の話(1区の区間賞・高校総体・世代トップ)は短く触れ、表に出す
// ・見出しの型は、前の年と同じ型を避ける(KantokuData.yobiint3[85]。kiji_kihon.dart の KijiMidashiKiroku)
// ・守る決まり(期待のルーキーと同じ):
//   ・大学名は書かない(進学先はまだ決まっていない。仮の振り分けの大学を見せないため)。
//     ただし、見どころの監督の母校・強化プロジェクトの大学は書く(どちらも画面に出ている事実)
//   ・選ぶのも書くのも、入学時の5000m(持ちタイム)と高校時代の実績だけ。能力値・成長タイプ・上限・
//     隠れた逸材には触れない(高校の大会の結果も入学時の記録から計算しているので、逸材は分からない)
//   ・選手の性質(勝負強い・本番に強いなど)は書かない。その日の出来事だけを書く
//   ・名前のない高校生は、名前を出さず「○○高の2年生」と書く。「来年大学に来るかも」とは書かない
//   ・高校の情報を表示しない設定のときは、記事を作らない(今までの結果の画面と同じ)
// ・スキップ中はスカウトの画面に来ないので、作らない
// ------------------------------------------------------------

/// 記事の番号(乱数と記者の名前に使う)
const int _no = 197;

/// 記事のカテゴリ(生成AIに渡すときの依頼文を変える)
const String kijiKoukouTaikaiCategory = '高校の大会';

/// スカウト前の高校の大会の記事か(生成AIに渡すときの依頼文を変える)
bool kijiKoukouTaikaiKa(Kiji kiji) => kiji.category == kijiKoukouTaikaiCategory;

/// 前の年の見出しの型を残す場所(KantokuData.yobiint3の番号。値は KijiMidashiKiroku の形)
const int koukouTaikaiMidashiIndex = 85;

/// 13分台(秒)
const double _juusan = 840.0;

/// 1人が13分台になる確率(理論値。kiji_shinnyuusei.dart と同じ)
const double _juusanKakuritsu = 0.136;

/// 世代上位の人数(名門校のそろい踏みを数える)
const int _jouiNinzuu = 30;

/// 見出しの型(前の年と同じ型を避けるために番号で残すので、番号を変えない)
const int _gYuushou = 1; // 全国高校駅伝の優勝校(連覇・初優勝・○年ぶり)
const int _gSessen = 2; // 全国高校駅伝の接戦(1・2位が10秒以内)
const int _gKazu = 3; // 世代の層(13分台の人数)
const int _gMeimon = 4; // 名門校のそろい踏み(同じ高校から有力な3年生が何人も)

/// 優勝校の監督(名前は出さない)の言葉
const List<String> _yuushouKantokuKotoba = [
  '3年生が最後までチームを引っ張ってくれた',
  'それぞれが自分の区間で役目を果たしてくれた',
  '大学でも、ここで学んだことを生かしてほしい',
];

/// 大会の記録の高校の名前から、都道府県のかっこを除いた名前(「天馬学園高」。その他の高校は「栃木県の高校」)
String _kouMijikai(String mei) {
  final int i = mei.indexOf('(');
  return i > 0 ? mei.substring(0, i) : mei;
}

/// 新入生1人(今年大学に進む高校3年生)
class _San {
  final SenshuData s;

  /// 世代の持ちタイムの順位(0が世代トップ)
  final int juni;

  /// 出してよい高校の情報
  final KoukouJouhou? j;

  _San(this.s, this.juni, this.j);

  double get t => s.kiroku_nyuugakuji_5000;

  /// 校名(「雷鳥館高」。なければ空)
  String get kou => j == null ? '' : koukouMeiMoji(j!);
}

/// スカウト前の高校の大会の記事を書く
class _Kakite {
  final KijiKankyou k;
  final KijiKakite w;
  final KoukouTaikaiKiroku rec;
  final List<_San> san; // 持ちタイムの順
  final Map<int, _San> byId;

  _Kakite(this.k, this.w, this.rec, this.san, this.byId);

  /// 大会の記録の選手が、今年の新入生なら、その選手(名前のない高校生や、別の選手ならnull)
  _San? shin(KoukouKirokuSousha y) {
    if (!y.namaeAri || y.id < 0) return null;
    final _San? x = byId[y.id];
    if (x == null || x.s.name != y.name) return null;
    return x;
  }

  /// 選手の呼び方(初めては「山田太郎(雷鳥館高)」、2回目からは「山田」)
  String yobu(_San x, {String? kakko}) =>
      w.hito('S${x.s.id}', x.s.name, kakko ?? x.kou, '');

  /// 大会の記録の選手の呼び方(新入生なら名前、名前のない高校生なら「天馬学園高の2年生」)
  String yobuKiroku(KoukouKirokuSousha y) {
    final _San? x = shin(y);
    if (x != null) return yobu(x, kakko: _kouMijikai(rec.kouMei(y.kouCode)));
    final String kou = _kouMijikai(rec.kouMei(y.kouCode));
    if (y.shurui == 3 || y.shurui == 1) return '$kouの留学生';
    return '$kouの${y.gakunen}年生';
  }

  // ---- 材料 ----

  KoukouKirokuTeam? get yuushou => rec.zenkoku.isEmpty ? null : rec.zenkoku.first;

  /// 1・2位の差(秒。分からなければnull)
  int? get sessenSa => rec.zenkoku.length < 2 ? null : saByou(rec.zenkoku[1].time, rec.zenkoku[0].time);

  int get juusanSuu => san.where((x) => x.t < _juusan).length;

  double get juusanHeinen => san.length * _juusanKakuritsu;

  double get juusanZure {
    final double v = san.length * _juusanKakuritsu * (1 - _juusanKakuritsu);
    if (v <= 0) return 0;
    return (juusanSuu - juusanHeinen) / sqrt(v);
  }

  /// 世代上位30人を一番多く出した高校の3年生(2人以上。同じなら最上位の選手が上の高校。なければ空)
  late final List<_San> meimon = _meimonTsukuru();

  List<_San> _meimonTsukuru() {
    final Map<int, List<_San>> m = {};
    for (final _San x in san.take(_jouiNinzuu)) {
      final KoukouJouhou? j = x.j;
      if (j == null || j.koukou < 1) continue;
      m.putIfAbsent(j.koukou, () => []).add(x);
    }
    List<_San> best = const [];
    for (final List<_San> l in m.values) {
      if (l.length < 2) continue;
      if (l.length > best.length || (l.length == best.length && l.first.juni < best.first.juni)) best = l;
    }
    return best;
  }

  // ---- 点 ----

  int get yuushouTen {
    final KoukouKirokuTeam? t = yuushou;
    if (t == null) return 0;
    int ten = 60;
    if (t.yuushouRenzoku >= 2) ten += 15;
    if (t.yuushouKaime == 1) ten += 15;
    if (t.yuushouBuri >= 5) ten += 10;
    return ten;
  }

  int get sessenTen {
    final int? sa = sessenSa;
    if (sa == null) return 0;
    if (sa <= 3) return 85;
    if (sa <= 10) return 70;
    return 0;
  }

  int get kazuTen {
    if (san.isEmpty) return 0;
    final double z = juusanZure.abs();
    if (z >= 1.25) return 80;
    if (z >= 0.6) return 55;
    return 30;
  }

  int get meimonTen {
    if (meimon.length >= 4) return 80;
    if (meimon.length == 3) return 65;
    if (meimon.length == 2) return 40;
    return 0;
  }

  // ---- 見出し・リード ----

  String midashiMoji(int g) {
    final KoukouKirokuTeam? t = yuushou;
    final String kou = t == null ? '' : _kouMijikai(rec.kouMei(t.kouCode));
    switch (g) {
      case _gSessen:
        return w.erabu([
          '全国高校駅伝、わずか${kinsaMoji(sessenSa ?? 0)}の決着　$kouが競り勝つ',
          '$kou、${kinsaMoji(sessenSa ?? 0)}で全国制覇　大学スカウト解禁',
        ]);
      case _gKazu:
        final int n = juusanSuu;
        if (juusanZure >= 0) {
          return w.erabu(['13分台$n人の豊作世代　大学スカウト解禁', '豊作の世代、13分台は$n人　スカウト解禁']);
        }
        return w.erabu(['13分台は$n人、横一線の世代　大学スカウト解禁', '突出した選手の少ない世代　スカウト解禁']);
      case _gMeimon:
        final String mk = meimon.first.kou;
        return w.erabu([
          '$mkから有力3年生${meimon.length}人　大学スカウト解禁',
          '$mkに有力3年生${meimon.length}人　スカウトの行方は',
        ]);
      default:
        if (t == null) return '大学の新入生スカウト解禁';
        if (t.yuushouRenzoku >= 2) {
          return w.erabu(['$kou、全国高校駅伝${t.yuushouRenzoku}連覇　スカウト解禁', '全国高校駅伝${t.yuushouRenzoku}連覇の$kou　3年生の進路に注目']);
        }
        if (t.yuushouKaime == 1) {
          return w.erabu(['$kou、悲願の全国初優勝　スカウト解禁', '全国高校駅伝は$kouが初優勝　3年生の進路に注目']);
        }
        return w.erabu(['全国高校駅伝は$kouが制す　大学スカウト解禁', '$kou、全国の頂点に　3年生の進路に注目']);
    }
  }

  String leadMoji(KishaKata kata) {
    return switch (kata) {
      KishaKata.suuji =>
        '大学の新入生スカウトが解禁された。今年大学に進む高校3年生は${san.length}人。'
            '13分台は$juusanSuu人を数える。昨冬の全国高校駅伝と昨夏の高校総体の結果から、この世代を振り返る。',
      KishaKata.joukei =>
        '春、大学の新入生スカウトが始まった。昨夏の高校総体、昨冬の全国高校駅伝と、'
            '高校最後の1年を駆け抜けた3年生たちが、次の舞台を選ぶ季節だ。',
      KishaKata.karakuchi =>
        '大学の新入生スカウトが解禁された。高校の記録は、大学での活躍を約束するものではない。'
            'それでも、昨冬と昨夏の大会の結果は、この世代を知る手がかりになる。',
    };
  }
}

/// 段落
extension _Danraku on _Kakite {
  /// 全国高校駅伝の段落(優勝校・2位との差・優勝メンバーの3年生・1区の区間賞)
  void ekidenDan() {
    final KoukouKirokuTeam? t = yuushou;
    if (t == null) return;
    final String kou = _kouMijikai(rec.kouMei(t.kouCode));
    final StringBuffer b = StringBuffer();
    b.write('昨冬の全国高校駅伝は、$kouが${jikanMoji(t.time)}で制した。');
    if (t.yuushouRenzoku >= 2) {
      b.write('${t.yuushouRenzoku}連覇となった。');
    } else if (t.yuushouKaime == 1) {
      b.write('初めての全国制覇だ。');
    } else if (t.yuushouBuri >= 2) {
      b.write('${t.yuushouBuri}年ぶりの頂点だった。');
    }
    final int? sa = sessenSa;
    if (sa != null && rec.zenkoku.length >= 2) {
      final String kou2 = _kouMijikai(rec.kouMei(rec.zenkoku[1].kouCode));
      if (sa <= 10) {
        b.write('2位の$kou2とは、わずか${kinsaMoji(sa)}だった。');
      } else {
        b.write('2位の$kou2には${saMoji(sa)}の差をつけた。');
      }
    }
    // 優勝メンバーのうち、今年大学に進む3年生(区間の順)
    final List<({_San x, int kukan})> m = [];
    for (final KoukouKirokuSousha y in t.member ?? const <KoukouKirokuSousha>[]) {
      if (y.kukan < 1) continue;
      final _San? x = shin(y);
      if (x != null) m.add((x: x, kukan: y.kukan));
    }
    m.sort((a, b) => a.kukan.compareTo(b.kukan));
    if (m.isNotEmpty) {
      final String mei = [for (final e in m) '${e.kukan}区の${yobu(e.x, kakko: '')}'].join('、');
      b.write(m.length == 1 ? '優勝メンバーからは、$meiが大学へ進む。' : '優勝メンバーからは、$meiの${m.length}人が大学へ進む。');
    }
    w.danraku(b.toString());
    if (w.r.kakuritsu(50)) {
      w.comment('「${w.erabu(_yuushouKantokuKotoba)}」と$kouの監督は振り返った。');
    }
    // 花の1区(区間賞を短く)
    if (rec.kukan.isNotEmpty && rec.kukan[0].isNotEmpty) {
      final KoukouKirokuSousha y = rec.kukan[0].first;
      final String yy = yobuKiroku(y); // 名前は候補を並べる前に1度だけ作る(2.0.2)
      w.danraku(w.erabu([
        '花の1区は、$yyが${jikanMoji(y.time)}で区間賞を取った。',
        'エースが集う1区の区間賞は、$yyの${jikanMoji(y.time)}だった。',
      ]));
    }
  }

  /// 高校総体の段落(5000mの優勝と日本人トップ、1500m・3000m障害の優勝を短く)
  void soutaiDan() {
    if (rec.soutai.length < 2 || rec.soutai[1].isEmpty) return;
    final List<KoukouKirokuSousha> f = rec.soutai[1];
    final KoukouKirokuSousha w1 = f.first;
    final bool ryuu = w1.shurui == 1 || w1.shurui == 3;
    final StringBuffer b = StringBuffer();
    b.write('昨夏の高校総体5000mは、${yobuKiroku(w1)}が${jikanMoji(w1.time)}で制した。');
    if (ryuu) {
      for (int i = 1; i < f.length; i++) {
        final KoukouKirokuSousha y = f[i];
        if (y.shurui == 0 || y.shurui == 2) {
          b.write('日本人トップは${i + 1}位の${yobuKiroku(y)}だった。');
          break;
        }
      }
    }
    final List<String> hoka = [
      for (final int sh in const [0, 2])
        if (rec.soutai.length > sh && rec.soutai[sh].isNotEmpty)
          '${koukouShumokuMei[sh + 1]}は${yobuKiroku(rec.soutai[sh].first)}',
    ];
    if (hoka.isNotEmpty) b.write('${hoka.join('、')}が優勝した。');
    w.danraku(b.toString());
  }

  /// 世代の層の段落(持ちタイムの世代トップと13分台の人数)
  void kazuDan() {
    if (san.isEmpty) return;
    final _San top = san.first;
    final StringBuffer b = StringBuffer();
    b.write('持ちタイムの世代トップは、${yobu(top)}の${jikanMoji(top.t)}。');
    final int n = juusanSuu;
    final int heinen = juusanHeinen.round();
    if (juusanZure >= 0.6) {
      b.write('13分台は$n人で、例年の$heinen人ほどを上回る。');
    } else if (juusanZure <= -0.6) {
      b.write('13分台は$n人で、例年の$heinen人ほどを下回る。');
    } else {
      b.write('13分台は$n人で、例年並みだ。');
    }
    w.danraku(b.toString());
  }

  /// 名門校のそろい踏みの段落
  void meimonDan() {
    final List<_San> l = meimon;
    if (l.length < 2) return;
    final String kou = l.first.kou;
    final String mei = [for (final _San x in l) yobu(x, kakko: '')].join(l.length == 2 ? 'と' : '、');
    final StringBuffer b = StringBuffer();
    b.write('$kouからは、持ちタイムで世代上位$_jouiNinzuu人に入る3年生が${l.length}人いる。$meiだ。');
    if ((l.first.j?.mei?.meimon ?? 0) >= 3) b.write('名門の層の厚さを示した。');
    w.danraku(b.toString());
  }

  /// スカウトの見どころ(地区めぐりの最初の地区・監督の母校・強化プロジェクト。書くことがなければ書かない)
  void midokoroDan() {
    final List<String> bun = [];
    // 地区めぐりの最初の地区と、その地区の持ちタイムの最上位
    if (isComScoutOn(k.kantoku) && comScoutKotoshiChikuMeguri(k.kantoku, k.gh.year)) {
      final List<int> junban = comScoutChikuJunban(k.gh.year);
      if (junban.isNotEmpty && junban.first >= 0 && junban.first < koukouChikuMei.length) {
        final int c = junban.first;
        final String chiku = koukouChikuMei[c];
        final StringBuffer b = StringBuffer('今年のスカウトは、$chiku地区から始まる。');
        for (final _San x in san) {
          if (comScoutSenshuChiku(x.s) == c) {
            b.write('$chiku地区の持ちタイムの最上位は、${yobu(x)}の${jikanMoji(x.t)}だ。');
            break;
          }
        }
        bun.add(b.toString());
      }
    }
    // 監督の母校(母校パイプが効くときだけ。持ちタイムの良い後輩のいる大学から2校まで)
    if (isComScoutOn(k.kantoku)) {
      final BokouPipe pipe = BokouPipe.yomu(k.kantoku, k.gh.MYunivid);
      if (!pipe.kikanai) {
        final Set<int> deta = {};
        for (final _San x in san) {
          if (deta.length >= 2) break;
          final KoukouJouhou? j = x.j;
          if (j == null || j.koukou < 1) continue;
          for (final MapEntry<int, int> e in pipe.bokou.entries) {
            if (e.value != j.koukou || deta.contains(e.key)) continue;
            if (e.key < 0 || e.key >= k.univ.length) continue;
            final ({String name, int nenrei})? kt = k.kantokuMei(e.key);
            if (kt == null) continue;
            deta.add(e.key);
            final String yobi = w.hito('K${e.key}', kt.name, '', '');
            final String um = daigakuMei(k.univ[e.key]);
            // 後輩の名前も候補を並べる前に1度だけ作る(候補ごとに呼ぶと、2つ目の候補が名字だけになるため。2.0.2)
            final String yx = yobu(x, kakko: '');
            bun.add(w.erabu([
              '$umの$yobi監督の母校・${x.kou}からは、$yx(${jikanMoji(x.t)})が大学へ進む。母校の後輩の行き先が注目される。',
              '${x.kou}の$yx(${jikanMoji(x.t)})にとって、$umの$yobi監督は高校の先輩にあたる。',
            ]));
            break;
          }
        }
      }
    }
    // 強化プロジェクト中の大学
    final KyoukaProject? p = kyoukaProjectChuu(k.kantoku, k.gh.month >= 4 ? k.gh.year : k.gh.year - 1);
    if (p != null && p.univid >= 0 && p.univid < k.univ.length) {
      bun.add('強化プロジェクトに取り組む${daigakuMei(k.univ[p.univid])}が、どこまで有望な3年生を集めるかも見どころだ。');
    }
    if (bun.isEmpty) return;
    w.koMidashi('スカウトの見どころ');
    for (final String s in bun) {
      w.danraku(s);
    }
  }

  /// 記者の目
  void kishaNoMe(KishaKata kata) {
    switch (kata) {
      case KishaKata.suuji:
        w.kishaNoMe('13分台$juusanSuu人。数字の上では、例年${juusanZure >= 0.6 ? 'より厚い' : (juusanZure <= -0.6 ? 'より薄い' : '並みの')}世代だ。'
            'どの大学がこの世代の力をどれだけ集めるか、スカウトの結果を待ちたい。');
      case KishaKata.joukei:
        w.kishaNoMe(w.erabu([
          '高校でたすきをつないだ仲間が、春には別々の大学の門をくぐるかもしれない。新しい物語が、ここから始まる。',
          '高校最後の冬を駆け抜けた3年生たちが、次の舞台を選ぶ。その一つ一つの決断に、注目したい。',
        ]));
      case KishaKata.karakuchi:
        w.kishaNoMe('持ちタイムも高校の大会の結果も、大学の距離では物差しの一つにすぎない。'
            '名前だけで選手を追うのは、まだ早い。');
    }
  }
}

/// 表
extension _Hyou on _Kakite {
  /// 持ちタイム上位10人(大学の欄はない。進学先はまだ決まっていない)
  KijiHyou jouiHyou() {
    return KijiHyou('高校3年生の5000m持ちタイム上位10人', const ['順位', '選手', '出身校', '5000m'], [
      for (final _San x in san.take(10))
        ['${x.juni + 1}', fullMei(x.s.name), x.j == null ? '' : koukouMeiKenMoji(x.j!), jikanMoji(x.t)],
    ]);
  }

  /// 全国高校駅伝の上位8校
  KijiHyou? ekidenHyou() {
    if (rec.zenkoku.isEmpty) return null;
    return KijiHyou('昨冬の全国高校駅伝(上位8校)', const ['順位', '高校', 'タイム'], [
      for (int i = 0; i < rec.zenkoku.length && i < 8; i++)
        ['${i + 1}', _kouMijikai(rec.kouMei(rec.zenkoku[i].kouCode)), jikanMoji(rec.zenkoku[i].time)],
    ]);
  }
}

/// 箱庭スポーツの「スカウト解禁」の記事(新入生のスカウトの画面で、1ラウンド目の前に出す)
/// 高校の情報を表示しない設定のときと、今年の新入生の世代の大会の記録がないときは空
List<Kiji> koukouTaikaiKiji() {
  try {
    final KijiKankyou? k = KijiKankyou.yomuRace(2);
    if (k == null) return [];
    if (koukouHyoujiNashi(k.kantoku)) return [];
    final int? nendo = koukouImaNoNendo();
    if (nendo == null) return [];
    KoukouTaikaiKiroku? rec;
    for (final KoukouTaikaiKiroku r in koukouTaikaiKirokuYomu()) {
      if (r.nyuugakuNendo == nendo) {
        rec = r;
        break;
      }
    }
    if (rec == null) return [];
    // 今年大学に進む日本人の3年生(新入生。持ちタイムの順)
    final List<SenshuData> l = [
      for (final SenshuData s in k.senshu)
        if (s.gakunen == 1 &&
            s.hirou != 1 &&
            s.kiroku_nyuugakuji_5000 > 0 &&
            s.kiroku_nyuugakuji_5000 < TEISUU.DEFAULTTIME)
          s,
    ]..sort((a, b) {
        final int c = a.kiroku_nyuugakuji_5000.compareTo(b.kiroku_nyuugakuji_5000);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    final List<_San> san = [];
    final Map<int, _San> byId = {};
    for (int i = 0; i < l.length; i++) {
      final _San x = _San(l[i], i, koukouHyoujiJouhou(l[i].samusataisei, l[i].hirou, k.kantoku));
      san.add(x);
      byId[x.s.id] = x;
    }
    final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, _no));
    final KishaKata kata = k.kishaKata(_no);
    final _Kakite r = _Kakite(k, w, rec, san, byId);

    // 見出しの型(点に少しだけ乱数を足す。前の年と同じ型なら2番目)
    final List<({int g, int ten})> kouho = [];
    void ire(int g, int ten) {
      if (ten > 0) kouho.add((g: g, ten: ten + w.r.ikutsu(10)));
    }

    ire(_gYuushou, r.yuushouTen);
    ire(_gSessen, r.sessenTen);
    ire(_gKazu, r.kazuTen);
    if (r.meimonTen >= 60) ire(_gMeimon, r.meimonTen);
    if (kouho.isEmpty) return [];
    kouho.sort((a, b) => b.ten.compareTo(a.ten));
    final int? mae = KijiMidashiKiroku.maeNoKata(k, koukouTaikaiMidashiIndex, nendo);
    int g = kouho.first.g;
    if (g == mae && kouho.length >= 2) g = kouho[1].g;
    KijiMidashiKiroku.nokosu(k, koukouTaikaiMidashiIndex, nendo, mae, g);

    final String midashi = r.midashiMoji(g);
    final String lead = r.leadMoji(kata);

    // 段落(見出しの段落を先に。ほかは決まった順。0=全国高校駅伝・1=高校総体・2=世代の層・3=名門校)
    final int atama = g == _gKazu ? 2 : (g == _gMeimon ? 3 : 0);
    for (final int d in [atama, ...[0, 1, 2, 3].where((int x) => x != atama)]) {
      switch (d) {
        case 0:
          r.ekidenDan();
        case 1:
          r.soutaiDan();
        case 2:
          r.kazuDan();
        default:
          r.meimonDan();
      }
    }
    r.midokoroDan();
    r.kishaNoMe(kata);

    final KijiHyou? ekidenHyou = r.ekidenHyou();
    return [
      Kiji(
        category: kijiKoukouTaikaiCategory,
        midashi: midashi,
        lead: lead,
        honbun: w.honbun,
        hyou: [
          r.jouiHyou(),
          if (ekidenHyou != null) ekidenHyou,
        ],
        haishin: k.haishinMei(_no, asa: true),
        kisha: k.kishaMei(_no),
        jibun: false,
        kekka: true,
      ),
    ];
  } catch (e, st) {
    // 飾りの記事なので、作れなくてもスカウトは続ける(結果の画面を出す)
    print('スカウト解禁の記事を作れませんでした: $e\n$st');
    return [];
  }
}
