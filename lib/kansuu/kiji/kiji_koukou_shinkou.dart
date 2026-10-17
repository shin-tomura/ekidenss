import 'package:ekiden/constants.dart' show LocationDatabase; // 地方版の都道府県の名前(2.0.4)
import 'package:ekiden/kansuu/koukou.dart'; // 高校の大会の記録(1.9.5・2.0.4)
import 'package:ekiden/kansuu/koukou_meibo.dart' show KoukouMei, koukouChikuMei, koukouKenChiku;
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';

// ------------------------------------------------------------
// 高校の大会の記事(2.0.4。箱庭スポーツ)
// ・高校の大会の結果が出る日(koukou.dart の koukouTaikaiHinichi)に合わせた3本:
//   7月下旬「高校総体」、11月中旬「全国高校駅伝の都道府県予選と地区大会」、12月下旬「全国高校駅伝」
// ・その日の画面のお知らせのカードと、高校名鑑・今年度の高校の大会の画面から読める。出した大会の分だけ、新しい順。
//   今の高校3年生の世代の回(7月下旬から次の4月まで)と、4月から次の7月下旬までは今年度に大学に入った世代の回で書く
//   (koukouKijiNoKai)。記事は開くたびに記録から作る。乱数・配信日時・記者は大会の年と記事の番号で決めるので、
//   いつ読み返しても同じ記事になる
// ・見出しの型は、前の年と同じ型を避ける(KantokuData.yobiint4[76]〜[78]。kiji_kihon.dart の KijiMidashiKiroku)
// ・地方版(都道府県を選んで読む「箱庭スポーツ ○○版」): 7月下旬の高校総体(県大会・地区大会)と、
//   11月中旬の全国高校駅伝の都道府県予選(地区大会も)。下の「地方版」を参照。
//   名前のない選手ばかりの記事になるので、2.0.4の開発中に出さないことにした(koukou.dart の koukouChihoubanAri)
// ・守る決まり(スカウト解禁の記事と同じ):
//   ・能力値・選手の性質・成長タイプ・隠れた逸材には触れない。持ちタイムも書かない(大学に入るときの記録なので、
//     4月の記事に任せる)。書くのは大会の順位とタイムだけ
//   ・名前のない高校生は、名前を出さず「○○高の2年生」と書く。「来年大学に来るかも」とは書かない
//   ・名前の出ている3年生(来年の新入生)の進学先は書かない(まだ決まっていない)
//   ・都道府県予選は、その日の条件(気温や風)が都道府県ごとに違うので、県どうしのタイムは比べない
//   ・高校の情報を表示しない設定のときは、記事を作らない
// ------------------------------------------------------------

/// 記事のカテゴリ
const String kijiKoukouSoutaiCategory = '高校総体';
const String kijiKoukouYosenCategory = '全国高校駅伝・予選';
const String kijiKoukouZenkokuCategory = '全国高校駅伝';

/// 地方版の記事のカテゴリ(都道府県ごとの高校総体と、全国高校駅伝の都道府県予選)
const String kijiKoukouChihouSoutaiCategory = '高校総体・地方版';
const String kijiKoukouChihouYosenCategory = '高校駅伝予選・地方版';

/// 高校の大会の記事か(生成AIに渡すときの依頼文を変える。地方版も含む)
bool kijiKoukouShinkouKa(Kiji kiji) =>
    kiji.category == kijiKoukouSoutaiCategory ||
    kiji.category == kijiKoukouYosenCategory ||
    kiji.category == kijiKoukouZenkokuCategory ||
    kiji.category == kijiKoukouChihouSoutaiCategory ||
    kiji.category == kijiKoukouChihouYosenCategory;

/// 記事の番号(乱数と記者の名前に使う)
const int _noSoutai = 201;
const int _noYosen = 202;
const int _noZenkoku = 203;

/// 前の年の見出しの型を残す場所(KantokuData.yobiint4の番号。値は KijiMidashiKiroku の形)
const int _midashiSoutai = 76;
const int _midashiYosen = 77;
const int _midashiZenkoku = 78;

/// 優勝校の監督(名前は出さない)の言葉
const List<String> _yuushouKantokuKotoba = [
  '7人それぞれが自分の区間で役目を果たしてくれた',
  '3年生が最後までチームを引っ張ってくれた',
  '苦しい場面でも、たすきをつなぐことだけを考えて走ってくれた',
];

// ------------------------------------------------------------
// 共通の部品
// ------------------------------------------------------------

/// 大会の記録の高校の名前から、都道府県のかっこを除いた名前(「天馬学園高」。その他の高校は「栃木県の高校」)
String _kouMijikai(String mei) {
  final int i = mei.indexOf('(');
  return i > 0 ? mei.substring(0, i) : mei;
}

/// 乱数の種(大会の年・記事の番号・都道府県。いつ読み返しても同じ記事にするため、今の日付は使わない)
int _tane(int nen, int no, [int ken = -1]) => nen * 7919 + 99 * 104729 + no * 1299709 + (ken + 1) * 15485863;

/// 記者の名前(大会の年と記事で決まる)
String _kishaMei(KijiKankyou k, int tane, String site) {
  final KijiRand r = KijiRand(tane + 77);
  final List<String> mae = [
    for (final String n in k.gh.name_mae)
      if (n.isNotEmpty) n,
  ];
  final List<String> ato = [
    for (final String n in k.gh.name_ato)
      if (n.isNotEmpty) n,
  ];
  if (mae.isEmpty || ato.isEmpty) return '$site 高校陸上取材班';
  return '$site ${r.erabu(mae)}${r.erabu(ato)}';
}

/// 配信日時の文(大会の日の午後。[nen]は大会の年)
String _haishin(int nen, int month, int day, int tane) {
  final KijiRand r = KijiRand(tane + 31);
  final int ji = 14 + r.ikutsu(6);
  final int fun = r.ikutsu(60);
  return '$nen年$month月$day日 $ji:${fun.toString().padLeft(2, '0')} 配信';
}

/// 留学生か(大学に入った留学生と、名前のない留学生)
bool _ryuu(KoukouKirokuSousha y) => y.shurui == 1 || y.shurui == 3;

/// 名前を出す選手か(大学に入った選手と、来年の新入生の土台の選手。名前が空なら出さない)
bool _namae(KoukouKirokuSousha y) => y.namaeDeru && y.name.isNotEmpty;

/// 高校の大会の記事を書く(選手の呼び方など)
class _Kakite {
  final KijiKankyou k;
  final KijiKakite w;
  final KoukouTaikaiKiroku rec;

  _Kakite(this.k, this.w, this.rec);

  /// 大会の年(高校3年生の年度。7月・11月・12月の大会の年)
  int get nen => rec.nyuugakuNendo - 1;

  /// 高校の短い名前(「雷鳥館高」)
  String kou(int code) => _kouMijikai(rec.kouMei(code));

  /// 選手の呼び方(名前の出ている選手は、初めては「山田太郎(雷鳥館高)」、2回目からは「山田」。
  /// 名前のない選手は「雷鳥館高の2年生」「雷鳥館高の留学生」)
  String yobu(KoukouKirokuSousha y, {bool kouAri = true}) {
    if (_namae(y)) return w.hito('H${y.id}', y.name, kouAri ? kou(y.kouCode) : '', '');
    return nanashi(y);
  }

  /// 名前のない選手の呼び方(名前の出ている選手も、この形で呼べる)
  String nanashi(KoukouKirokuSousha y) {
    if (_ryuu(y)) return '${kou(y.kouCode)}の留学生';
    return '${kou(y.kouCode)}の${y.gakunen}年生';
  }

  /// 見出しに書く選手の名前(名前の出ている選手はフルネーム。名前を出したことにはしない)
  String atama(KoukouKirokuSousha y) => _namae(y) ? fullMei(y.name) : nanashi(y);

  /// 表の選手の欄
  String hyouMei(KoukouKirokuSousha y) {
    if (_namae(y)) return fullMei(y.name);
    return _ryuu(y) ? '留学生' : '${y.gakunen}年生';
  }

  /// 地方版の見出しの型を選ぶ(点に少しだけ乱数を足して一番高いもの。都道府県が多いので、前の年の型は残さない。
  /// 候補がなければ[nashi])
  int kataErabuChihou(List<({int g, int ten})> kouho, int nashi) {
    int g = nashi;
    int best = -1;
    for (final ({int g, int ten}) e in kouho) {
      if (e.ten <= 0) continue;
      final int t = e.ten + w.r.ikutsu(10);
      if (t > best) {
        best = t;
        g = e.g;
      }
    }
    return g;
  }

  /// 見出しの型を選ぶ(点に少しだけ乱数を足す。前の年と同じ型なら2番目。候補がなければ[nashi])
  int kataErabu(List<({int g, int ten})> kouho0, int index, int nashi) {
    final List<({int g, int ten})> kouho = [
      for (final ({int g, int ten}) e in kouho0)
        if (e.ten > 0) (g: e.g, ten: e.ten + w.r.ikutsu(10)),
    ]..sort((a, b) => b.ten.compareTo(a.ten));
    final int? mae = KijiMidashiKiroku.maeNoKata(k, index, nen, yobiint4: true);
    int g = kouho.isEmpty ? nashi : kouho.first.g;
    if (g == mae && kouho.length >= 2) g = kouho[1].g;
    KijiMidashiKiroku.nokosu(k, index, nen, mae, g, yobiint4: true);
    return g;
  }
}

/// 出場の回数目の文(「初出場」「3年連続5回目」「5年ぶり3回目」「5回目」。分からなければ空)
String _shutsujouMoji(int kaime, int renzoku, int buri) {
  if (kaime < 1) return '';
  if (kaime == 1) return '初出場';
  if (renzoku >= 2) return '$renzoku年連続$kaime回目';
  if (buri >= 2) return '$buri年ぶり$kaime回目';
  return '$kaime回目';
}

/// 前の回(1年前の世代。なければnull)
KoukouTaikaiKiroku? _maeNoKai(KoukouTaikaiKiroku rec) {
  for (final KoukouTaikaiKiroku r in koukouTaikaiKirokuYomu()) {
    if (r.nyuugakuNendo == rec.nyuugakuNendo - 1) return r;
  }
  return null;
}

/// 都道府県予選と地区大会で決まった全国高校駅伝の出場校(県代表は都道府県の順、地区代表は地区の順)
/// [chiku] は地区代表の地区の番号(県代表は-1)。北海道(地区大会がない地区)は予選の2位が地区代表
List<({int code, int chiku})> _shutsujouKou(KoukouTaikaiKiroku rec) {
  final List<({int code, int chiku})> l = [];
  final List<KoukouYosenKen>? yo = rec.yosen;
  if (yo == null) return l;
  for (int ken = 0; ken < yo.length; ken++) {
    for (final KoukouYosenTeam t in yo[ken].teams) {
      if (t.juni == 1) l.add((code: t.kouCode, chiku: -1));
    }
  }
  final List<List<KoukouChikuTeam>>? ch = rec.chiku;
  for (int c = 0; c < koukouChikuMei.length; c++) {
    final List<int> kens = [
      for (int ken = 0; ken < koukouKenChiku.length; ken++)
        if (koukouKenChiku[ken] == c) ken,
    ];
    if (kens.length <= 1) {
      if (kens.length == 1 && kens.first < yo.length) {
        for (final KoukouYosenTeam t in yo[kens.first].teams) {
          if (t.juni == 2) l.add((code: t.kouCode, chiku: c));
        }
      }
    } else if (ch != null && c < ch.length) {
      for (final KoukouChikuTeam t in ch[c]) {
        if (t.daihyou == 2) l.add((code: t.kouCode, chiku: c));
      }
    }
  }
  return l;
}

// ------------------------------------------------------------
// 7月下旬「高校総体」
// ------------------------------------------------------------

/// 見出しの型(前の年と同じ型を避けるために番号で残すので、番号を変えない)
const int _gsGo = 1; // 5000mの優勝
const int _gsNikan = 2; // 2種目の優勝
const int _gsMeimon = 3; // 決勝に何人も送り込んだ高校
const int _gsNinen = 4; // 2年生の優勝

List<Kiji> _soutaiKiji(KijiKankyou k, KoukouTaikaiKiroku rec) {
  final List<List<KoukouKirokuSousha>> f = rec.soutai;
  if (f.length < 3 || f[1].isEmpty) return [];
  final int nen = rec.nyuugakuNendo - 1;
  final int tane = _tane(nen, _noSoutai);
  final KijiKakite w = KijiKakite(k, tane);
  final _Kakite r = _Kakite(k, w, rec);
  final String kisha = _kishaMei(k, tane, kijiSiteMei);
  final KishaKata kata = kishaKataKara(kisha);
  String ev(int sh) => koukouShumokuMei[sh + 1];

  KoukouKirokuSousha? yuushou(int sh) => f[sh].isEmpty ? null : f[sh].first;
  // 日本人のトップ(留学生が優勝した種目で使う。何位か)
  ({KoukouKirokuSousha y, int juni})? nihonTop(int sh) {
    for (int i = 0; i < f[sh].length; i++) {
      if (!_ryuu(f[sh][i])) return (y: f[sh][i], juni: i + 1);
    }
    return null;
  }

  // 2種目の優勝(同じ選手が2つの種目で優勝。記録の中だけの番号が-1の古い記録は見分けられない)
  ({KoukouKirokuSousha y, int a, int b})? nikan;
  for (int a = 0; a < 3 && nikan == null; a++) {
    for (int b = a + 1; b < 3; b++) {
      final KoukouKirokuSousha? ya = yuushou(a);
      final KoukouKirokuSousha? yb = yuushou(b);
      if (ya != null && yb != null && ya.id != -1 && ya.id == yb.id && ya.kouCode == yb.kouCode) {
        nikan = (y: ya, a: a, b: b);
        break;
      }
    }
  }
  // 決勝に一番多く選手を送り込んだ名簿の高校(同じ選手の掛け持ちは1人と数える。同じなら最上位の順位が上の高校)
  final Map<int, Set<int>> kouNin = {};
  final Map<int, int> kouBest = {};
  for (int sh = 0; sh < 3; sh++) {
    for (int i = 0; i < f[sh].length; i++) {
      final KoukouKirokuSousha y = f[sh][i];
      if (y.kouCode < 0 || y.kouCode >= 1000) continue;
      kouNin.putIfAbsent(y.kouCode, () => <int>{}).add(y.id == -1 ? -1000 - sh * 100 - i : y.id);
      kouBest[y.kouCode] = (kouBest[y.kouCode] ?? 99) < i ? kouBest[y.kouCode]! : i;
    }
  }
  int meimonCode = -1;
  for (final MapEntry<int, Set<int>> e in kouNin.entries) {
    if (meimonCode < 0) {
      meimonCode = e.key;
      continue;
    }
    final int n = e.value.length;
    final int m = kouNin[meimonCode]!.length;
    if (n > m || (n == m && (kouBest[e.key] ?? 99) < (kouBest[meimonCode] ?? 99))) meimonCode = e.key;
  }
  final int meimonNin = meimonCode < 0 ? 0 : kouNin[meimonCode]!.length;
  final List<KoukouMei> meibo = koukouMeiboGenzai();
  final bool meimonMeimon = meimonCode >= 0 && meimonCode < meibo.length && meibo[meimonCode].meimon >= 3;
  // 2年生以下の優勝(名前のない選手。5000m → 1500m → 3000m障害の順に探す)
  int ninenSh = -1;
  for (final int sh in const [1, 0, 2]) {
    final KoukouKirokuSousha? y = yuushou(sh);
    if (y != null && !_namae(y) && !_ryuu(y) && y.gakunen <= 2) {
      ninenSh = sh;
      break;
    }
  }

  // 見出しの型
  final int g = r.kataErabu([
    (g: _gsGo, ten: 60),
    if (nikan != null) (g: _gsNikan, ten: 90),
    if (meimonNin >= 4) (g: _gsMeimon, ten: meimonNin >= 5 ? 75 : 60),
    if (ninenSh >= 0) (g: _gsNinen, ten: ninenSh == 1 ? 80 : 65),
  ], _midashiSoutai, _gsGo);

  final KoukouKirokuSousha w5 = f[1].first;
  String midashi;
  switch (g) {
    case _gsNikan:
      final ({KoukouKirokuSousha y, int a, int b}) n = nikan!;
      midashi = w.erabu([
        '${r.atama(n.y)}、${ev(n.a)}と${ev(n.b)}の2冠　高校総体',
        '高校総体、${r.atama(n.y)}が${ev(n.a)}・${ev(n.b)}を制す',
      ]);
    case _gsMeimon:
      final String mk = r.kou(meimonCode);
      midashi = meimonMeimon
          ? w.erabu(['$mk、高校総体の決勝に$meimonNin人　名門の層の厚さ', '名門$mk、決勝に$meimonNin人を送り込む　高校総体'])
          : w.erabu(['$mk、高校総体の決勝に$meimonNin人', '$mk、決勝に$meimonNin人を送り込む　高校総体']);
    case _gsNinen:
      final KoukouKirokuSousha y = yuushou(ninenSh)!;
      midashi = w.erabu([
        '${r.kou(y.kouCode)}の${y.gakunen}年生、高校総体${ev(ninenSh)}を制す',
        '${y.gakunen}年生が${ev(ninenSh)}の頂点に　高校総体',
      ]);
    default:
      final ({KoukouKirokuSousha y, int juni})? jt = nihonTop(1);
      if (_ryuu(w5) && jt != null) {
        midashi = '高校総体5000m、${r.atama(w5)}が制す　日本人トップは${r.atama(jt.y)}';
      } else {
        midashi = w.erabu(['高校総体5000m、${r.atama(w5)}が頂点に', '${r.atama(w5)}、高校総体5000mを制す']);
      }
  }

  final String lead = switch (kata) {
    KishaKata.suuji => '高校総体の陸上で、長距離の3種目(1500m・5000m・3000m障害)の決勝が行われた。'
        '5000mの優勝タイムは${jikanMoji(w5.time)}だった。',
    KishaKata.joukei => '真夏のトラックに、高校生たちの熱戦が続いた。高校総体の長距離3種目の決勝が行われ、'
        'それぞれの頂点が決まった。',
    KishaKata.karakuchi => '高校総体の長距離3種目の決勝が行われた。夏のトラックの結果は、冬の駅伝の結果を約束するものではない。'
        'それでも、各校の今の力ははっきりと出た。',
  };

  // 種目の段落(優勝・留学生が勝った種目の日本人トップ・2位との差)
  void shumokuDan(int sh) {
    final KoukouKirokuSousha? y = yuushou(sh);
    if (y == null) return;
    final StringBuffer b = StringBuffer();
    final String yy = r.yobu(y);
    b.write(w.erabu([
      '${ev(sh)}は、$yyが${jikanMoji(y.time)}で優勝した。',
      '${ev(sh)}を制したのは$yyで、タイムは${jikanMoji(y.time)}だった。',
    ]));
    if (_ryuu(y)) {
      final ({KoukouKirokuSousha y, int juni})? jt = nihonTop(sh);
      if (jt != null) b.write('日本人トップは${jt.juni}位の${r.yobu(jt.y)}(${jikanMoji(jt.y.time)})。');
    } else if (f[sh].length >= 2) {
      final KoukouKirokuSousha y2 = f[sh][1];
      final int sa = saByou(y2.time, y.time);
      final String y2y = r.yobu(y2);
      b.write(sa <= 1 ? '2位の$y2yとは、わずか${kinsaMoji(sa)}だった。' : '2位は$y2yで、${saMoji(sa)}差だった。');
    }
    w.danraku(b.toString());
  }

  // 段落(見出しの段落を先に)
  if (g == _gsNikan) {
    final ({KoukouKirokuSousha y, int a, int b}) n = nikan!;
    final String yy = r.yobu(n.y);
    w.danraku('$yyが、${ev(n.a)}(${jikanMoji(f[n.a].first.time)})と${ev(n.b)}(${jikanMoji(f[n.b].first.time)})の'
        '2種目を制した。');
  }
  if (g == _gsMeimon) {
    final String mk = r.kou(meimonCode);
    w.danraku('$mkは、3種目の決勝に合わせて$meimonNin人が残った。${meimonMeimon ? '名門の層の厚さを見せた。' : ''}');
  }
  final List<int> jun = g == _gsNinen ? [ninenSh, ...[1, 0, 2].where((int x) => x != ninenSh)] : const [1, 0, 2];
  for (final int sh in jun) {
    shumokuDan(sh);
  }
  if (g != _gsMeimon && meimonNin >= 3) {
    w.danraku('高校別では、${r.kou(meimonCode)}が3種目の決勝に合わせて$meimonNin人を送り込んだ。');
  }
  // 決勝に残った2年生以下(名前のない選手)
  final Set<int> kagakunen = {};
  for (int sh = 0; sh < 3; sh++) {
    for (final KoukouKirokuSousha y in f[sh]) {
      if (!_namae(y) && !_ryuu(y) && y.gakunen <= 2 && y.id != -1) kagakunen.add(y.id);
    }
  }
  if (kagakunen.length >= 2) {
    w.danraku('決勝には、2年生以下も${kagakunen.length}人が残った。来年の夏が楽しみな顔ぶれだ。');
  }
  // 記者の目
  final Set<int> sannen = {};
  int zentai = 0;
  for (int sh = 0; sh < 3; sh++) {
    zentai += f[sh].length;
    for (final KoukouKirokuSousha y in f[sh]) {
      if (y.gakunen == 3 && y.id != -1) sannen.add(y.id);
    }
  }
  switch (kata) {
    case KishaKata.suuji:
      w.kishaNoMe('3種目の決勝を走ったのは、のべ$zentai人。そのうち3年生は${sannen.length}人だった。'
          '秋からは、全国高校駅伝への予選が始まる。');
    case KishaKata.joukei:
      w.kishaNoMe(w.erabu([
        'トラックの夏が終わり、秋からは全国高校駅伝への道が始まる。3年生たちは、仲間と最後の冬に向かう。',
        '夏の主役たちが、次はたすきを手にする。全国高校駅伝の予選は11月だ。',
      ]));
    case KishaKata.karakuchi:
      w.kishaNoMe('夏の勝者が、冬の駅伝でも主役になるとは限らない。トラックとロードは別物だ。秋の予選を待ちたい。');
  }

  return [
    Kiji(
      category: kijiKoukouSoutaiCategory,
      midashi: midashi,
      lead: lead,
      honbun: w.honbun,
      hyou: [
        for (final int sh in const [1, 0, 2])
          if (f[sh].isNotEmpty)
            KijiHyou('高校総体 ${ev(sh)} 決勝(上位8人)', const ['順位', '選手', '高校', 'タイム'], [
              for (int i = 0; i < f[sh].length && i < 8; i++)
                ['${i + 1}', r.hyouMei(f[sh][i]), r.kou(f[sh][i].kouCode), jikanMoji(f[sh][i].time)],
            ]),
      ],
      haishin: _haishin(nen, koukouSoutaiMonth, koukouSoutaiDay, tane),
      kisha: kisha,
      jibun: false,
      kekka: true,
    ),
  ];
}

// ------------------------------------------------------------
// 11月中旬「全国高校駅伝の都道府県予選と地区大会」
// ・主役は都道府県代表(強い高校が多い)。前回王者・前回の入賞校・全国優勝経験のある高校が勝ち上がったかを先に書く
// ・地区代表は、初出場と10年以上ぶりの出場のときだけ書く(地区大会の接戦などは書かない。2.0.4)
// ・予選で敗れた高校は、前回王者・名門と、30年以上続いた連続出場が途切れた高校を書く
// ・連続出場の年数・初出場・何年ぶりは、記録を残し始めてからの数
// ------------------------------------------------------------

const int _gyOu = 1; // 前回の優勝校の予選敗退
const int _gyMeimon = 2; // 名門の予選敗退
const int _gyHatsu = 3; // 初出場
const int _gyRenzoku = 4; // 都道府県代表の30年以上の連続出場(2.0.4の開発中は、地区代表も含む3年以上だった)
// 5は地区大会の接戦(2.0.4の開発中に使わなくなった。番号は使い回さない)
const int _gyKimaru = 6; // 出場校が決まる(書くことがほかにないとき。前回上位の高校が勝ち上がったこと)
const int _gyTogire = 7; // 30年以上続いた連続出場が途切れる
const int _gyHisashiburi = 8; // 10年以上ぶりの出場
const int _gyMaeOuDai = 9; // 前回王者が代表に(連覇へ)

/// 長く続いた連続出場とみなす年数(途切れたときと、都道府県代表で続いているとき)
const int _nagaiRenzoku = 30;

/// 超久々の出場とみなす年数(何年ぶり)
const int _hisashiburiNen = 10;

List<Kiji> _yosenKiji(KijiKankyou k, KoukouTaikaiKiroku rec, KoukouTaikaiKiroku? mae) {
  if (rec.yosenMada) return [];
  final List<({int code, int chiku})> deru = _shutsujouKou(rec);
  if (deru.isEmpty) return [];
  final int nen = rec.nyuugakuNendo - 1;
  final int tane = _tane(nen, _noYosen);
  final KijiKakite w = KijiKakite(k, tane);
  final _Kakite r = _Kakite(k, w, rec);
  final String kisha = _kishaMei(k, tane, kijiSiteMei);
  final KishaKata kata = kishaKataKara(kisha);
  final int kenSuu = deru.where((e) => e.chiku < 0).length;
  final int chikuSuu = deru.length - kenSuu;
  final Set<int> deruCode = {for (final e in deru) e.code};
  final List<KoukouYosenKen> yo = rec.yosen ?? const [];
  // 高校の番号 → 予選を走った都道府県(都道府県代表の「○○県代表」と表の都道府県の欄)
  final Map<int, int> kouKen = {
    for (int ken = 0; ken < yo.length; ken++)
      for (final KoukouYosenTeam t in yo[ken].teams) t.kouCode: ken,
  };
  // 代表の呼び方(「栃木県代表」「地区代表」)
  String daihyouMei(({int code, int chiku}) e) {
    if (e.chiku >= 0) return '地区代表';
    final int ken = kouKen[e.code] ?? -1;
    final String km = _kenMei(ken);
    return km.isEmpty ? '都道府県代表' : '$km代表';
  }

  // 出場の回数目(全国高校駅伝の結果を出したあとは、記録の回数目。出す前は見込み)
  final Map<int, ({int kaime, int renzoku, int buri})> kaime = {};
  if (rec.zenkokuMada) {
    kaime.addAll(koukouShutsujouMikomi([for (final e in deru) e.code], rec.nyuugakuNendo));
  } else {
    for (final KoukouKirokuTeam t in rec.zenkoku) {
      kaime[t.kouCode] = (kaime: t.kaime, renzoku: t.renzoku, buri: t.shutsujouBuri);
    }
  }
  int renOf(int code) => kaime[code]?.renzoku ?? 0;
  int buriOf(int code) => kaime[code]?.buri ?? 0;
  // 初出場は、記録を残している回が3回以上あるときだけ書く(始めたばかりは初出場ばかりなので)
  final int maeKaiSuu = koukouTaikaiKirokuYomu()
      .where((KoukouTaikaiKiroku x) => x.nyuugakuNendo < rec.nyuugakuNendo && x.zenkoku.isNotEmpty)
      .length;
  final List<({int code, int chiku})> hatsu = [
    for (final e in deru)
      if ((kaime[e.code]?.kaime ?? 0) == 1) e,
  ];
  final bool hatsuKaku = maeKaiSuu >= 3 && hatsu.isNotEmpty && hatsu.length <= 6;
  // 10年以上ぶりの出場(長い順)
  final List<({int code, int chiku})> hisashiburi = [
    for (final e in deru)
      if (buriOf(e.code) >= _hisashiburiNen) e,
  ]..sort((a, b) => buriOf(b.code).compareTo(buriOf(a.code)));
  // 都道府県代表の30年以上の連続出場(長い順)
  final List<({int code, int chiku})> kenRenzoku = [
    for (final e in deru)
      if (e.chiku < 0 && renOf(e.code) >= _nagaiRenzoku) e,
  ]..sort((a, b) => renOf(b.code).compareTo(renOf(a.code)));
  // 前回の全国の順位(高校の番号 → 順位)
  final Map<int, int> maeJuni = {};
  if (mae != null) {
    for (int j = 0; j < mae.zenkoku.length; j++) {
      maeJuni.putIfAbsent(mae.zenkoku[j].kouCode, () => j + 1);
    }
  }
  // 前回の優勝校
  final int maeOu = (mae != null && mae.zenkoku.isNotEmpty) ? mae.zenkoku.first.kouCode : -1;
  final bool maeOuOchi = maeOu >= 0 && maeOu < 1000 && !deruCode.contains(maeOu);
  ({int code, int chiku})? maeOuDeru;
  for (final e in deru) {
    if (e.code == maeOu) maeOuDeru = e;
  }
  // 30年以上続いた連続出場が途切れた高校(一番長い高校)
  final Map<int, int> togireMap = koukouRenzokuTogire(deruCode, rec.nyuugakuNendo);
  int togire = -1;
  for (final MapEntry<int, int> e in togireMap.entries) {
    if (e.value < _nagaiRenzoku) continue;
    if (togire < 0 || e.value > togireMap[togire]!) togire = e.key;
  }
  // 予選で敗れた名門(予選の順位が一番上の名門。前回の優勝校は除く)
  final List<KoukouMei> meibo = koukouMeiboGenzai();
  int meimonOchi = -1;
  int meimonJuni = 99;
  for (int ken = 0; ken < yo.length; ken++) {
    for (final KoukouYosenTeam t in yo[ken].teams) {
      final int c = t.kouCode;
      if (c < 0 || c >= meibo.length || meibo[c].meimon < 3) continue;
      if (deruCode.contains(c) || c == maeOu) continue;
      if (t.juni < meimonJuni) {
        meimonJuni = t.juni;
        meimonOchi = c;
      }
    }
  }
  final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
  // 都道府県代表の、前回の入賞校(8位以内。前回の優勝校は除く。前回の順の4校まで)と、全国優勝の経験がある高校
  final List<({int code, int chiku})> kenJoui = [
    for (final e in deru)
      if (e.chiku < 0 && e.code != maeOu && (maeJuni[e.code] ?? 99) <= 8) e,
  ]..sort((a, b) => maeJuni[a.code]!.compareTo(maeJuni[b.code]!));
  final List<({int code, int chiku})> kenYuushou = [
    for (final e in deru)
      if (e.chiku < 0 &&
          e.code != maeOu &&
          (maeJuni[e.code] ?? 99) > 8 &&
          e.code >= 0 &&
          e.code < kai.zenkoku.length &&
          kai.zenkoku[e.code] > 0)
        e,
  ]..sort((a, b) => kai.zenkoku[b.code].compareTo(kai.zenkoku[a.code]));

  final int g = r.kataErabu([
    if (maeOuOchi) (g: _gyOu, ten: 95),
    if (togire >= 0 && togire != maeOu) (g: _gyTogire, ten: 85),
    if (meimonOchi >= 0 && meimonOchi != togire)
      (g: _gyMeimon, ten: (meimonOchi < kai.zenkoku.length && kai.zenkoku[meimonOchi] > 0) ? 80 : 70),
    if (hisashiburi.isNotEmpty) (g: _gyHisashiburi, ten: buriOf(hisashiburi.first.code) >= 20 ? 85 : 75),
    if (hatsuKaku) (g: _gyHatsu, ten: 60 + 5 * (hatsu.length > 3 ? 3 : hatsu.length)),
    if (maeOuDeru != null) (g: _gyMaeOuDai, ten: 55),
    if (kenRenzoku.isNotEmpty) (g: _gyRenzoku, ten: 50),
  ], _midashiYosen, _gyKimaru);

  final int n = deru.length;
  String midashi;
  switch (g) {
    case _gyOu:
      midashi = w.erabu(['前回王者の${r.kou(maeOu)}、予選で敗れる　全国高校駅伝', '${r.kou(maeOu)}、連覇ならず　全国高校駅伝の予選で敗退']);
    case _gyTogire:
      final int nn = togireMap[togire] ?? 0;
      midashi = w.erabu(['${r.kou(togire)}、連続出場が$nn年で途切れる　全国高校駅伝', '${r.kou(togire)}の連続出場、$nn年で止まる　全国高校駅伝の予選']);
    case _gyMeimon:
      midashi = w.erabu(['名門${r.kou(meimonOchi)}、全国への道絶たれる', '${r.kou(meimonOchi)}が予選で敗退　全国高校駅伝の出場$n校決まる']);
    case _gyHisashiburi:
      final int c = hisashiburi.first.code;
      midashi = w.erabu(['${r.kou(c)}、${buriOf(c)}年ぶりの全国へ　全国高校駅伝の出場$n校決まる', '${r.kou(c)}が${buriOf(c)}年ぶりに全国切符　全国高校駅伝']);
    case _gyHatsu:
      midashi = hatsu.length == 1
          ? '${r.kou(hatsu.first.code)}が全国初出場　全国高校駅伝の出場$n校決まる'
          : '${r.kou(hatsu.first.code)}など${hatsu.length}校が初出場　全国高校駅伝';
    case _gyMaeOuDai:
      midashi = '前回王者の${r.kou(maeOu)}、${daihyouMei(maeOuDeru!)}に　全国高校駅伝の連覇へ';
    case _gyRenzoku:
      final ({int code, int chiku}) e = kenRenzoku.first;
      midashi = '${r.kou(e.code)}、${renOf(e.code)}年連続の${daihyouMei(e)}　全国高校駅伝の出場$n校決まる';
    default:
      midashi = kenJoui.length >= 2
          ? '前回上位の${r.kou(kenJoui[0].code)}・${r.kou(kenJoui[1].code)}が代表に　全国高校駅伝の出場$n校決まる'
          : '全国高校駅伝の出場$n校が決まる';
  }

  final String lead = switch (kata) {
    KishaKata.suuji => '全国高校駅伝の都道府県予選と地区大会が終わり、12月の本大会に出る$n校が決まった。'
        '都道府県代表が$kenSuu校、地区代表が$chikuSuu校だ。',
    KishaKata.joukei => '冬の全国の舞台へ、たすきの行き先が決まった。全国高校駅伝の都道府県予選と地区大会が行われ、'
        '$n校が出場を決めた。',
    KishaKata.karakuchi => '全国高校駅伝の都道府県予選と地区大会が行われ、出場$n校が決まった。予選は一発勝負。'
        '力があっても、届かないことがある。',
  };

  // 段落
  // 前回王者(予選で敗れたか、代表として連覇に挑むか)
  void maeOuDan() {
    if (maeOu < 0 || maeOu >= 1000) return;
    final String mk = r.kou(maeOu);
    if (maeOuOchi) {
      final KoukouKaiSeiseki s = koukouKaiSeisekiYomu(rec, maeOu);
      final StringBuffer b = StringBuffer('前回の全国高校駅伝を制した$mkは、');
      final KoukouYosenTeam? y = s.yosen;
      if (y != null) b.write('都道府県予選で${y.juni}位に終わり、');
      if (s.chiku != null && s.chikuJuni >= 1) b.write('地区大会でも${s.chikuJuni}位で、');
      b.write('連覇への挑戦の舞台に立てなかった。');
      final int nn = togireMap[maeOu] ?? 0;
      if (nn >= _nagaiRenzoku) b.write('$nn年続いた連続出場も途切れた。');
      w.danraku(b.toString());
    } else {
      final ({int code, int chiku})? e = maeOuDeru;
      if (e == null) return;
      final ({int kaime, int renzoku, int buri})? m = kaime[maeOu];
      final String sj = m == null ? '' : _shutsujouMoji(m.kaime, m.renzoku, m.buri);
      w.danraku(sj.isEmpty
          ? '前回優勝の$mkは、${daihyouMei(e)}として連覇に挑む。'
          : '前回優勝の$mkは、${daihyouMei(e)}として$sjの出場を決め、連覇に挑む。');
    }
  }

  // 都道府県代表の顔ぶれ(前回の入賞校と、全国優勝の経験がある高校)
  void kenDan() {
    final List<String> bun = [];
    if (kenJoui.isNotEmpty) {
      final List<String> mei = [
        for (final e in kenJoui.take(4)) '前回${maeJuni[e.code]}位の${r.kou(e.code)}',
      ];
      bun.add('都道府県代表では、${mei.join('、')}${kenJoui.length > 4 ? 'など' : ''}が順当に勝ち上がった。');
    }
    if (kenYuushou.isNotEmpty) {
      final List<String> mei = [
        for (final e in kenYuushou.take(3)) '${r.kou(e.code)}(全国優勝${kai.zenkoku[e.code]}回)',
      ];
      bun.add('全国優勝の経験がある${mei.join('、')}も、都道府県代表として出場する。');
    }
    if (bun.isNotEmpty) w.danraku(bun.join());
  }

  // 初出場(都道府県代表も地区代表も)
  void hatsuDan() {
    if (!hatsuKaku) return;
    final List<String> mei = [for (final e in hatsu.take(4)) '${r.kou(e.code)}(${daihyouMei(e)})'];
    w.danraku(hatsu.length == 1
        ? '${mei.first}は、記録を残し始めてから初めての全国出場となる。'
        : '初出場は${mei.join('、')}${hatsu.length > 4 ? 'など' : 'の'}${hatsu.length}校。新しい顔ぶれが全国の舞台に立つ。');
  }

  // 10年以上ぶりの出場(都道府県代表も地区代表も。長い順に3校まで)
  void hisashiburiDan() {
    if (hisashiburi.isEmpty) return;
    final List<String> mei = [
      for (final e in hisashiburi.take(3)) '${r.kou(e.code)}(${daihyouMei(e)})は${buriOf(e.code)}年ぶり',
    ];
    w.danraku('${mei.join('、')}の全国出場となる。');
  }

  // 都道府県代表の30年以上の連続出場(1文だけ)
  void renzokuDan() {
    if (kenRenzoku.isEmpty) return;
    final ({int code, int chiku}) e = kenRenzoku.first;
    final ({int kaime, int renzoku, int buri})? m = kaime[e.code];
    if (m == null) return;
    w.danraku('${r.kou(e.code)}は、${m.renzoku}年連続${m.kaime}回目の出場を決めた。');
  }

  // 予選で敗れた高校(30年以上続いた連続出場が途切れた高校と、名門。前回の優勝校は前回王者の段落で書く)
  void ochiDan() {
    if (togire >= 0 && togire != maeOu) {
      final String mk = r.kou(togire);
      final KoukouKaiSeiseki s = koukouKaiSeisekiYomu(rec, togire);
      // 名門なら、名門の予選敗退の段落の代わりに、ここで名門と書く
      final int yu = togire < kai.zenkoku.length ? kai.zenkoku[togire] : 0;
      final bool meimon = togire == meimonOchi;
      final StringBuffer b = StringBuffer(
        meimon ? (yu > 0 ? '全国優勝$yu回の名門$mkは、' : '名門の$mkは、') : '$mkは、',
      );
      final KoukouYosenTeam? y = s.yosen;
      if (y != null) b.write('都道府県予選で${y.juni}位に終わり、');
      b.write('${togireMap[togire]}年続いた全国高校駅伝の連続出場が途切れた。');
      w.danraku(b.toString());
    }
    if (meimonOchi >= 0 && meimonOchi != togire) {
      final String mk = r.kou(meimonOchi);
      final KoukouKaiSeiseki s = koukouKaiSeisekiYomu(rec, meimonOchi);
      final int yu = meimonOchi < kai.zenkoku.length ? kai.zenkoku[meimonOchi] : 0;
      final StringBuffer b = StringBuffer(yu > 0 ? '全国優勝$yu回の名門$mkは、' : '名門の$mkは、');
      final KoukouYosenTeam? y = s.yosen;
      if (y != null) b.write('都道府県予選で${y.juni}位。');
      if (s.chiku != null && s.chikuJuni >= 1) {
        b.write('地区大会でも${s.chikuJuni}位にとどまり、全国への切符を逃した。');
      } else {
        b.write('全国への切符を逃した。');
      }
      w.danraku(b.toString());
    }
  }

  final List<void Function()> dan = [maeOuDan, kenDan, hatsuDan, hisashiburiDan, renzokuDan, ochiDan];
  final int atama = switch (g) {
    _gyTogire || _gyMeimon => 5,
    _gyHisashiburi => 3,
    _gyHatsu => 2,
    _gyRenzoku => 4,
    _gyOu || _gyMaeOuDai => 0,
    _ => 1,
  };
  dan[atama]();
  for (int i = 0; i < dan.length; i++) {
    if (i != atama) dan[i]();
  }
  // 記者の目
  final int renSuu = deru.where((e) => renOf(e.code) >= 2).length;
  switch (kata) {
    case KishaKata.suuji:
      w.kishaNoMe(hatsuKaku
          ? '出場$n校のうち、初出場は${hatsu.length}校、連続出場は$renSuu校。12月下旬、全国の舞台で順位がつく。'
          : '出場$n校のうち、連続出場は$renSuu校。12月下旬、全国の舞台で順位がつく。');
    case KishaKata.joukei:
      w.kishaNoMe('予選で涙をのんだ高校の思いも背負い、$n校がたすきをつなぐ。12月下旬の本番が待ち遠しい。');
    case KishaKata.karakuchi:
      w.kishaNoMe('都道府県の代表になっても、全国では別の戦いが待つ。前回の上位校に、どの代表校が割って入るかに注目したい。');
  }

  return [
    Kiji(
      category: kijiKoukouYosenCategory,
      midashi: midashi,
      lead: lead,
      honbun: w.honbun,
      hyou: [
        KijiHyou('都道府県代表($kenSuu校)', const ['都道府県', '高校', '出場', '前回'], [
          for (final e in deru)
            if (e.chiku < 0)
              [
                koukouKenMijikai(kouKen[e.code] ?? -1),
                r.kou(e.code),
                _shutsujouMojiKaime(kaime[e.code]),
                maeJuni[e.code] == null ? '' : '${maeJuni[e.code]}位',
              ],
        ]),
        KijiHyou('地区代表($chikuSuu校)', const ['地区', '高校', '出場', '前回'], [
          for (final e in deru)
            if (e.chiku >= 0 && e.chiku < koukouChikuMei.length)
              [
                koukouChikuMei[e.chiku],
                r.kou(e.code),
                _shutsujouMojiKaime(kaime[e.code]),
                maeJuni[e.code] == null ? '' : '${maeJuni[e.code]}位',
              ],
        ]),
      ],
      haishin: _haishin(nen, koukouYosenMonth, koukouYosenDay, tane),
      kisha: kisha,
      jibun: false,
      kekka: true,
    ),
  ];
}

/// 出場の回数目の文(回数目が分からなければ空。_shutsujouMoji の、見込みの記録から作る形)
String _shutsujouMojiKaime(({int kaime, int renzoku, int buri})? m) =>
    m == null ? '' : _shutsujouMoji(m.kaime, m.renzoku, m.buri);

// ------------------------------------------------------------
// 12月下旬「全国高校駅伝」
// ------------------------------------------------------------

const int _gzYuushou = 1; // 優勝校(連覇・初優勝・○年ぶり)
const int _gzSessen = 2; // 1・2位の接戦
const int _gzIkku = 3; // 1区の区間賞
const int _gzChiku = 4; // 地区代表の躍進
const int _gzMaeOu = 5; // 前回王者の後退

List<Kiji> _zenkokuKiji(KijiKankyou k, KoukouTaikaiKiroku rec, KoukouTaikaiKiroku? mae) {
  if (rec.zenkokuMada || rec.zenkoku.isEmpty) return [];
  final int nen = rec.nyuugakuNendo - 1;
  final int tane = _tane(nen, _noZenkoku);
  final KijiKakite w = KijiKakite(k, tane);
  final _Kakite r = _Kakite(k, w, rec);
  final String kisha = _kishaMei(k, tane, kijiSiteMei);
  final KishaKata kata = kishaKataKara(kisha);
  final List<KoukouKirokuTeam> z = rec.zenkoku;
  final KoukouKirokuTeam t = z.first;
  final String kou1 = r.kou(t.kouCode);
  final int? sa = z.length >= 2 ? saByou(z[1].time, t.time) : null;
  final KoukouKirokuSousha? ikku = (rec.kukan.isNotEmpty && rec.kukan[0].isNotEmpty) ? rec.kukan[0].first : null;
  // 地区代表で一番上の高校(優勝校は除く)
  int chikuJ = -1;
  for (int j = 1; j < z.length && j < 3; j++) {
    if (z[j].daihyou >= 1) {
      chikuJ = j;
      break;
    }
  }
  // 前回の優勝校の今回の順位(出ていなければ0)
  final int maeOu = (mae != null && mae.zenkoku.isNotEmpty) ? mae.zenkoku.first.kouCode : -1;
  int maeOuJuni = 0;
  for (int j = 0; j < z.length; j++) {
    if (z[j].kouCode == maeOu) {
      maeOuJuni = j + 1;
      break;
    }
  }
  final int maeKaiSuu = koukouTaikaiKirokuYomu()
      .where((KoukouTaikaiKiroku x) => x.nyuugakuNendo < rec.nyuugakuNendo && x.zenkoku.isNotEmpty)
      .length;

  int yuushouTen = 60;
  if (t.yuushouRenzoku >= 2) yuushouTen += 15;
  if (t.yuushouKaime == 1) yuushouTen += 15;
  if (t.yuushouBuri >= 5) yuushouTen += 10;
  final int g = r.kataErabu([
    (g: _gzYuushou, ten: yuushouTen),
    if (sa != null && sa <= 10) (g: _gzSessen, ten: sa <= 3 ? 85 : 70),
    if (ikku != null && (_namae(ikku) || ikku.gakunen <= 2) && !_ryuu(ikku)) (g: _gzIkku, ten: ikku.gakunen <= 2 ? 65 : 60),
    if (chikuJ >= 0) (g: _gzChiku, ten: chikuJ == 1 ? 75 : 65),
    if (maeOu >= 0 && maeOu != t.kouCode && maeOuJuni >= 9) (g: _gzMaeOu, ten: 60),
  ], _midashiZenkoku, _gzYuushou);

  String midashi;
  switch (g) {
    case _gzSessen:
      midashi = w.erabu(['全国高校駅伝、わずか${kinsaMoji(sa ?? 0)}の決着　$kou1が競り勝つ', '$kou1、${kinsaMoji(sa ?? 0)}で全国制覇']);
    case _gzIkku:
      midashi = w.erabu(['花の1区は${r.atama(ikku!)}が区間賞　全国高校駅伝', '${r.atama(ikku!)}、1区で区間賞　全国高校駅伝は$kou1が優勝']);
    case _gzChiku:
      final KoukouKirokuTeam ct = z[chikuJ];
      midashi = '地区代表の${r.kou(ct.kouCode)}が${chikuJ + 1}位　全国高校駅伝は$kou1が制す';
    case _gzMaeOu:
      midashi = '前回王者の${r.kou(maeOu)}は$maeOuJuni位　全国高校駅伝は$kou1が制す';
    default:
      if (t.yuushouRenzoku >= 2) {
        midashi = w.erabu(['$kou1、全国高校駅伝${t.yuushouRenzoku}連覇', '全国高校駅伝は$kou1が${t.yuushouRenzoku}連覇']);
      } else if (t.yuushouKaime == 1) {
        midashi = w.erabu(['$kou1、悲願の全国初優勝', '全国高校駅伝は$kou1が初優勝']);
      } else if (t.yuushouBuri >= 2) {
        midashi = '$kou1、${t.yuushouBuri}年ぶりの全国制覇　全国高校駅伝';
      } else {
        midashi = w.erabu(['全国高校駅伝は$kou1が制す', '$kou1、全国高校駅伝の頂点に']);
      }
  }

  final String lead = switch (kata) {
    KishaKata.suuji => '全国高校駅伝(7区間42.195km)が行われ、$kou1が${jikanMoji(t.time)}で優勝した。'
        '${sa == null || z.length < 2 ? '' : '2位の${r.kou(z[1].kouCode)}とは${sa <= 10 ? kinsaMoji(sa) : '${saMoji(sa)}差'}だった。'}',
    KishaKata.joukei => '7人でつなぐ42.195km。全国高校駅伝が行われ、$kou1が頂点に立った。',
    KishaKata.karakuchi => '全国高校駅伝が行われ、$kou1が${jikanMoji(t.time)}で制した。'
        '7区間のどこかでつまずけば、頂点は遠のく。その差がはっきり出た大会だった。',
  };

  // 優勝の段落(タイム・連覇など・2位との差・出場の回数目・優勝メンバーの名前の出ている3年生)
  void yuushouDan() {
    final StringBuffer b = StringBuffer();
    b.write('優勝した$kou1のタイムは${jikanMoji(t.time)}。');
    if (t.yuushouRenzoku >= 2) {
      b.write('${t.yuushouRenzoku}連覇となった。');
    } else if (t.yuushouKaime == 1) {
      b.write('初めての全国制覇だ。');
    } else if (t.yuushouBuri >= 2) {
      b.write('${t.yuushouBuri}年ぶりの頂点だった。');
    }
    if (sa != null && z.length >= 2) {
      final String k2 = r.kou(z[1].kouCode);
      b.write(sa <= 10 ? '2位の$k2とは、わずか${kinsaMoji(sa)}だった。' : '2位の$k2には${saMoji(sa)}の差をつけた。');
    }
    if (t.daihyou >= 1 && t.daihyou - 1 < koukouChikuMei.length) {
      b.write('地区代表(${koukouChikuMei[t.daihyou - 1]})からの優勝だった。');
    }
    final List<KoukouKirokuSousha> m = [
      for (final KoukouKirokuSousha y in t.member ?? const <KoukouKirokuSousha>[])
        if (y.kukan >= 1 && _namae(y)) y,
    ]..sort((a, b) => a.kukan.compareTo(b.kukan));
    if (m.isNotEmpty) {
      final String mei = [
        for (final KoukouKirokuSousha y in m.take(4))
          '${y.kukan}区の${r.yobu(y, kouAri: false)}${y.kukanJuni >= 1 ? '(区間${y.kukanJuni == 1 ? '賞' : '${y.kukanJuni}位'})' : ''}',
      ].join('、');
      b.write('3年生では、$meiがたすきをつないだ。');
    }
    w.danraku(b.toString());
    if (w.r.kakuritsu(50)) {
      w.comment('「${w.erabu(_yuushouKantokuKotoba)}」と$kou1の監督は振り返った。');
    }
  }

  // 1区の段落(区間賞と2位との差)
  void ikkuDan() {
    if (ikku == null) return;
    final String yy = r.yobu(ikku);
    final StringBuffer b = StringBuffer(w.erabu([
      '花の1区は、$yyが${jikanMoji(ikku.time)}で区間賞を取った。',
      'エースが集う1区の区間賞は、$yyの${jikanMoji(ikku.time)}だった。',
    ]));
    if (rec.kukan[0].length >= 2) {
      final KoukouKirokuSousha y2 = rec.kukan[0][1];
      final int s2 = saByou(y2.time, ikku.time);
      final String y2y = r.yobu(y2);
      b.write(s2 <= 3 ? '区間2位の$y2yとは${kinsaMoji(s2)}だった。' : '区間2位は$y2yだった。');
    }
    w.danraku(b.toString());
  }

  // ほかの区間賞(2区〜7区)
  void kukanshouDan() {
    final List<String> l = [];
    for (int kk = 1; kk < rec.kukan.length; kk++) {
      if (rec.kukan[kk].isEmpty) continue;
      final KoukouKirokuSousha y = rec.kukan[kk].first;
      l.add('${kk + 1}区が${r.yobu(y)}');
    }
    if (l.isEmpty) return;
    w.danraku('ほかの区間賞は、${l.join('、')}だった。');
  }

  // 上位校(2・3位と、地区代表の躍進)
  void jouiDan() {
    if (z.length < 3) return;
    final StringBuffer b = StringBuffer();
    b.write('2位は${r.kou(z[1].kouCode)}、3位は${r.kou(z[2].kouCode)}。');
    if (chikuJ >= 0) {
      final KoukouKirokuTeam ct = z[chikuJ];
      final int c = ct.daihyou - 1;
      if (c >= 0 && c < koukouChikuMei.length) {
        b.write('${chikuJ + 1}位の${r.kou(ct.kouCode)}は、${koukouChikuMei[c]}大会を勝ち上がった地区代表だった。');
      }
    }
    w.danraku(b.toString());
  }

  // 前回王者と、初出場の入賞
  void sonotaDan() {
    final List<String> bun = [];
    if (maeOu >= 0 && maeOu < 1000 && maeOu != t.kouCode) {
      bun.add(maeOuJuni >= 1 ? '前回王者の${r.kou(maeOu)}は$maeOuJuni位だった。' : '前回王者の${r.kou(maeOu)}は、予選で敗れて出場できなかった。');
    }
    if (maeKaiSuu >= 3) {
      for (int j = 1; j < z.length && j < 8; j++) {
        if (z[j].kaime == 1) {
          bun.add('初出場の${r.kou(z[j].kouCode)}は${j + 1}位に入った。');
          break;
        }
      }
    }
    if (bun.isNotEmpty) w.danraku(bun.join());
  }

  final List<void Function()> dan = [yuushouDan, ikkuDan, jouiDan, sonotaDan, kukanshouDan];
  final int atama = switch (g) {
    _gzIkku => 1,
    _gzChiku => 2,
    _gzMaeOu => 3,
    _ => 0,
  };
  dan[atama]();
  for (int i = 0; i < dan.length; i++) {
    if (i != atama) dan[i]();
  }
  // 記者の目
  final int chikuNyuushou = [for (int j = 0; j < z.length && j < 8; j++) if (z[j].daihyou >= 1) j].length;
  switch (kata) {
    case KishaKata.suuji:
      w.kishaNoMe('優勝タイムは${jikanMoji(t.time)}。上位8校のうち、地区代表は$chikuNyuushou校だった。'
          '3年生にとっては、これが高校最後の駅伝になる。');
    case KishaKata.joukei:
      w.kishaNoMe(w.erabu([
        '3年生にとっては、高校最後の駅伝。それぞれのたすきの重みが、42.195kmに詰まっていた。',
        'たすきをつないだ7人と、それを支えた仲間たち。高校駅伝の1年が、ここで締めくくられた。',
      ]));
    case KishaKata.karakuchi:
      w.kishaNoMe('7区間のうち1つでもつまずけば、頂点は遠のく。今年もそれがはっきりした大会だった。');
  }

  return [
    Kiji(
      category: kijiKoukouZenkokuCategory,
      midashi: midashi,
      lead: lead,
      honbun: w.honbun,
      hyou: [
        KijiHyou('全国高校駅伝(上位8校)', const ['順位', '高校', 'タイム', '出場'], [
          for (int j = 0; j < z.length && j < 8; j++)
            ['${j + 1}', r.kou(z[j].kouCode), jikanMoji(z[j].time), _shutsujouMoji(z[j].kaime, z[j].renzoku, z[j].shutsujouBuri)],
        ]),
        KijiHyou('区間賞', const ['区間', '選手', '高校', 'タイム'], [
          for (int kk = 0; kk < rec.kukan.length; kk++)
            if (rec.kukan[kk].isNotEmpty)
              [
                '${kk + 1}区',
                r.hyouMei(rec.kukan[kk].first),
                r.kou(rec.kukan[kk].first.kouCode),
                jikanMoji(rec.kukan[kk].first.time),
              ],
        ]),
      ],
      haishin: _haishin(nen, koukouZenkokuMonth, koukouZenkokuDay, tane),
      kisha: kisha,
      jibun: false,
      kekka: true,
    ),
  ];
}

// ------------------------------------------------------------
// 地方版(2.0.4。都道府県を選んで読む「箱庭スポーツ ○○版」)
// ・7月下旬「高校総体」: その都道府県の県大会の各種目の優勝と、地区大会を勝ち上がって全国大会に進んだ選手、
//   全国大会の決勝の順位(全国大会と同じ日に出るので書く)
// ・11月中旬「全国高校駅伝の都道府県予選」: 代表校と2・3位、地区大会、区間賞、優勝校の走者。
//   記事の日付のあとに出る全国高校駅伝の結果は書かない
// ・記録は今の世代の回だけにある(koukou.dart の koukouChihouKirokuYomu)。都道府県が多いので、
//   見出しの型は前の年と重ねる仕組みを使わない(点と乱数で選ぶ)
// ------------------------------------------------------------

/// 記事の番号(乱数と記者の名前に使う。都道府県の番号も乱数に入れる)
const int _noChihouSoutai = 204;
const int _noChihouYosen = 205;

/// 地方版のサイトの名前(「箱庭スポーツ 栃木版」)
String kijiKoukouChihouSiteMei(int ken) => '$kijiSiteMei ${koukouKenMijikai(ken)}版';

/// 都道府県の名前(「栃木県」。分からなければ空)
String _kenMei(int ken) =>
    (ken >= 0 && ken < LocationDatabase.allPrefectures.length) ? LocationDatabase.allPrefectures[ken] : '';

/// 地区の都道府県の数(1なら地区大会がない。北海道)
int _chikuKenSuu(int c) => koukouKenChiku.where((int x) => x == c).length;

/// 同じ選手か(記録の中の番号と高校の番号で見る)
bool _onajiSousha(KoukouKirokuSousha a, KoukouKirokuSousha b) => a.id == b.id && a.kouCode == b.kouCode;

/// 名前を並べる(4人までは全員、5人以上は3人と「など○人」)
String _narabe(List<String> l, String tani) {
  if (l.length <= 4) return l.join('、');
  return '${l.take(3).join('、')}など${l.length}$tani';
}

/// 見出しの型(地方版の高校総体)
const int _gcZenkokuOu = 1; // 全国大会の優勝
const int _gcKesshou = 2; // 全国大会の決勝に何人も
const int _gcKesshouHitori = 3; // 全国大会の決勝に1人
const int _gcDokusen = 4; // 県大会の上位独占
const int _gcNinen = 5; // 2年生以下の県大会の優勝
const int _gcKenOu = 6; // 県大会の5000mの優勝(書くことがほかにないとき)

List<Kiji> _chihouSoutaiKiji(KijiKankyou k, KoukouTaikaiKiroku rec, KoukouChihouKiroku ck, int ken) {
  if (ken < 0 || ken >= ck.soutaiKen.length) return [];
  final List<List<KoukouKirokuSousha>> kenK = ck.soutaiKen[ken];
  if (kenK.length < 3 || kenK[1].isEmpty) return [];
  final int c = ken < koukouKenChiku.length ? koukouKenChiku[ken] : -1;
  final bool chikuAri = c >= 0 && c < koukouChikuMei.length && _chikuKenSuu(c) >= 2;
  final List<List<KoukouKirokuSousha>> chikuK =
      (c >= 0 && c < ck.soutaiChiku.length) ? ck.soutaiChiku[c] : const <List<KoukouKirokuSousha>>[];
  final int nen = rec.nyuugakuNendo - 1;
  final int tane = _tane(nen, _noChihouSoutai, ken);
  final KijiKakite w = KijiKakite(k, tane);
  final _Kakite r = _Kakite(k, w, rec);
  final String site = kijiKoukouChihouSiteMei(ken);
  final String kisha = _kishaMei(k, tane, site);
  final KishaKata kata = kishaKataKara(kisha);
  final String kenMei = _kenMei(ken);
  final String kenTaikai = '$kenMei大会';
  final String chikuTaikai = chikuAri ? '${koukouChikuMei[c]}大会' : '';
  String ev(int sh) => koukouShumokuMei[sh + 1];

  // 種目ごとの、全国大会に進んだこの都道府県の選手(県大会の記録と、地区大会の順位。北海道は県大会の上位6人)
  List<({KoukouKirokuSousha y, int chikuJuni})> heMotomeru(int sh) {
    final List<({KoukouKirokuSousha y, int chikuJuni})> l = [];
    if (!chikuAri) {
      for (final KoukouKirokuSousha y in kenK[sh]) {
        l.add((y: y, chikuJuni: 0));
      }
      return l;
    }
    if (sh >= chikuK.length) return l;
    final Set<int> tsukatta = {};
    for (int j = 0; j < chikuK[sh].length; j++) {
      for (int i = 0; i < kenK[sh].length; i++) {
        if (tsukatta.contains(i) || !_onajiSousha(kenK[sh][i], chikuK[sh][j])) continue;
        tsukatta.add(i);
        l.add((y: kenK[sh][i], chikuJuni: j + 1));
        break;
      }
    }
    return l;
  }

  final List<List<({KoukouKirokuSousha y, int chikuJuni})>> he = [for (int sh = 0; sh < 3; sh++) heMotomeru(sh)];
  // 種目ごとの、全国大会の決勝に残ったこの都道府県の選手(決勝の順位)
  final List<List<({KoukouKirokuSousha y, int juni})>> ke = [
    for (int sh = 0; sh < 3; sh++)
      [
        if (sh < rec.soutai.length)
          for (int j = 0; j < rec.soutai[sh].length; j++)
            if (he[sh].any((e) => _onajiSousha(e.y, rec.soutai[sh][j]))) (y: rec.soutai[sh][j], juni: j + 1),
      ],
  ];
  int heSuu = 0;
  int keSuu = 0;
  final Set<String> keHito = {};
  for (int sh = 0; sh < 3; sh++) {
    heSuu += he[sh].length;
    keSuu += ke[sh].length;
    for (final e in ke[sh]) {
      keHito.add('${e.y.id}_${e.y.kouCode}');
    }
  }
  // 全国大会の優勝(5000m → 1500m → 3000m障害の順に探す)
  ({KoukouKirokuSousha y, int sh})? ou;
  for (final int sh in const [1, 0, 2]) {
    if (ke[sh].isNotEmpty && ke[sh].first.juni == 1) {
      ou = (y: ke[sh].first.y, sh: sh);
      break;
    }
  }
  // 決勝に1人だけ(一番上の順位)
  ({KoukouKirokuSousha y, int sh, int juni})? hitori;
  if (keHito.length == 1) {
    for (int sh = 0; sh < 3; sh++) {
      for (final e in ke[sh]) {
        final ({KoukouKirokuSousha y, int sh, int juni})? mae = hitori;
        if (mae == null || e.juni < mae.juni) hitori = (y: e.y, sh: sh, juni: e.juni);
      }
    }
  }
  // 県大会の上位独占(同じ名簿の高校が1〜3位)
  ({int sh, int code})? dokusen;
  for (final int sh in const [1, 0, 2]) {
    final List<KoukouKirokuSousha> l = kenK[sh];
    if (l.length >= 3 && l[0].kouCode < 1000 && l[0].kouCode == l[1].kouCode && l[0].kouCode == l[2].kouCode) {
      dokusen = (sh: sh, code: l[0].kouCode);
      break;
    }
  }
  // 2年生以下の県大会の優勝(名前のない日本人)
  int ninenSh = -1;
  for (final int sh in const [1, 0, 2]) {
    if (kenK[sh].isEmpty) continue;
    final KoukouKirokuSousha y = kenK[sh].first;
    if (!_namae(y) && !_ryuu(y) && y.gakunen <= 2) {
      ninenSh = sh;
      break;
    }
  }

  final int g = r.kataErabuChihou([
    if (ou != null) (g: _gcZenkokuOu, ten: 100),
    if (keHito.length >= 2) (g: _gcKesshou, ten: 70 + 5 * (keHito.length > 5 ? 5 : keHito.length)),
    if (hitori != null) (g: _gcKesshouHitori, ten: 60),
    if (dokusen != null) (g: _gcDokusen, ten: 55),
    if (ninenSh >= 0) (g: _gcNinen, ten: 50),
  ], _gcKenOu);

  final KoukouKirokuSousha w5 = kenK[1].first;
  String midashi;
  switch (g) {
    case _gcZenkokuOu:
      final ({KoukouKirokuSousha y, int sh}) o = ou!;
      midashi = w.erabu([
        '${r.atama(o.y)}、高校総体${ev(o.sh)}で日本一',
        '$kenMeiから日本一　${r.atama(o.y)}が高校総体${ev(o.sh)}を制す',
      ]);
    case _gcKesshou:
      midashi = w.erabu([
        '高校総体の決勝に$kenMeiから${keHito.length}人',
        '$kenMeiの${keHito.length}人、高校総体の決勝へ',
      ]);
    case _gcKesshouHitori:
      final ({KoukouKirokuSousha y, int sh, int juni}) h = hitori!;
      midashi = '${r.atama(h.y)}、高校総体${ev(h.sh)}で${h.juni}位';
    case _gcDokusen:
      final ({int sh, int code}) d = dokusen!;
      midashi = '${r.kou(d.code)}、高校総体$kenTaikaiの${ev(d.sh)}で上位独占';
    case _gcNinen:
      final KoukouKirokuSousha y = kenK[ninenSh].first;
      midashi = '${r.kou(y.kouCode)}の${y.gakunen}年生、高校総体$kenTaikaiの${ev(ninenSh)}を制す';
    default:
      midashi = w.erabu([
        '${r.atama(w5)}、高校総体$kenTaikaiの5000mを制す',
        '高校総体$kenTaikai、5000mは${r.atama(w5)}が頂点に',
      ]);
  }

  final String taikai = chikuAri ? '$kenTaikaiと$chikuTaikai' : kenTaikai;
  final String lead = switch (kata) {
    KishaKata.suuji => '高校総体の陸上の長距離3種目(1500m・5000m・3000m障害)で、$taikaiの結果が出そろった。'
        '${heSuu > 0 ? '$kenMeiからは、のべ$heSuu人が全国大会に進んだ。' : '$kenMeiから全国大会に進んだ選手はいなかった。'}',
    KishaKata.joukei => '夏の全国の舞台を目指して、$kenMeiの高校生たちがトラックを駆けた。'
        '高校総体の長距離3種目の$taikaiを振り返る。',
    KishaKata.karakuchi => chikuAri
        ? '高校総体の全国大会に進めるのは、$kenTaikaiの上位6人のうち、さらに$chikuTaikaiで上位6人に入った選手だけだ。'
            '$kenMeiの長距離3種目を振り返る。'
        : '高校総体の全国大会に進めるのは、$kenTaikaiの上位6人だけだ。$kenMeiの長距離3種目を振り返る。',
  };

  // 全国大会の優勝の段落(見出しが全国大会の優勝のとき)
  if (g == _gcZenkokuOu) {
    final ({KoukouKirokuSousha y, int sh}) o = ou!;
    w.danraku('${r.yobu(o.y)}が、全国大会の${ev(o.sh)}の決勝を${jikanMoji(o.y.time)}で制し、日本一に輝いた。');
  }
  // 種目の段落(県大会の優勝・地区大会を勝ち上がった選手・全国大会の決勝)
  void shumokuDan(int sh) {
    if (kenK[sh].isEmpty) return;
    final KoukouKirokuSousha y = kenK[sh].first;
    final StringBuffer b = StringBuffer();
    b.write(w.erabu([
      '${ev(sh)}の$kenTaikaiは、${r.yobu(y)}が${jikanMoji(y.time)}で制した。',
      '$kenTaikaiの${ev(sh)}を制したのは${r.yobu(y)}で、タイムは${jikanMoji(y.time)}だった。',
    ]));
    if (kenK[sh].length >= 2) {
      final KoukouKirokuSousha y2 = kenK[sh][1];
      final int sa = saByou(y2.time, y.time);
      if (sa <= 1) b.write('2位の${r.yobu(y2)}とは、わずか${kinsaMoji(sa)}だった。');
    }
    if (chikuAri) {
      final List<String> mei = [for (final e in he[sh]) '${r.yobu(e.y)}(${e.chikuJuni}位)'];
      b.write(mei.isEmpty
          ? '$chikuTaikaiでは上位6人に入れず、$kenMeiの選手は全国大会に届かなかった。'
          : '$chikuTaikaiでは、${_narabe(mei, '人')}が上位6人に入り、全国大会に進んだ。');
    } else if (he[sh].isNotEmpty) {
      b.write('上位6人が全国大会に進んだ。');
    }
    final List<({KoukouKirokuSousha y, int juni})> kl = ke[sh];
    if (kl.length == 1 && kl.first.juni == 1) {
      // 優勝だけ(見出しの段落で書いた種目は書かない)
      if (!(g == _gcZenkokuOu && ou?.sh == sh)) b.write('全国大会の決勝では、${r.yobu(kl.first.y)}が優勝した。');
    } else if (kl.isNotEmpty) {
      final List<String> mei = [
        for (final e in kl)
          e.juni == 1 ? '${r.yobu(e.y)}が優勝' : '${r.yobu(e.y)}が${e.juni}位',
      ];
      b.write('全国大会の決勝では、${mei.join('、')}だった。');
    } else if (he[sh].isNotEmpty) {
      b.write('全国大会では、決勝に残れなかった。');
    }
    w.danraku(b.toString());
  }

  final int sentou = switch (g) {
    _gcZenkokuOu => ou!.sh,
    _gcKesshouHitori => hitori!.sh,
    _gcDokusen => dokusen!.sh,
    _gcNinen => ninenSh,
    _ => 1,
  };
  shumokuDan(sentou);
  for (final int sh in const [1, 0, 2]) {
    if (sh != sentou) shumokuDan(sh);
  }
  // 高校別(県大会の上位6人に一番多く入った名簿の高校。同じ選手の掛け持ちは1人と数える)
  final Map<int, Set<int>> kouNin = {};
  for (int sh = 0; sh < 3; sh++) {
    for (final KoukouKirokuSousha y in kenK[sh]) {
      if (y.kouCode < 0 || y.kouCode >= 1000) continue;
      kouNin.putIfAbsent(y.kouCode, () => <int>{}).add(y.id);
    }
  }
  int ooiCode = -1;
  for (final MapEntry<int, Set<int>> e in kouNin.entries) {
    if (ooiCode < 0 || e.value.length > kouNin[ooiCode]!.length) ooiCode = e.key;
  }
  if (ooiCode >= 0 && kouNin[ooiCode]!.length >= 4 && g != _gcDokusen) {
    w.danraku('高校別では、${r.kou(ooiCode)}が3種目の上位6人に合わせて${kouNin[ooiCode]!.length}人を送り込んだ。');
  }
  // 記者の目
  switch (kata) {
    case KishaKata.suuji:
      w.kishaNoMe(heSuu > 0
          ? '3種目で全国大会に進んだ$kenMeiの選手は、のべ$heSuu人。そのうち決勝に残ったのは、のべ$keSuu人だった。'
              '秋からは、全国高校駅伝の予選が始まる。'
          : '3種目とも、$kenMeiの選手は全国大会に届かなかった。秋からは、全国高校駅伝の予選が始まる。');
    case KishaKata.joukei:
      w.kishaNoMe(w.erabu([
        'トラックの夏が終わり、秋からは全国高校駅伝への道が始まる。$kenMeiの代表の座をかけた予選は11月だ。',
        '夏の主役たちが、次はたすきを手にする。$kenMeiの全国高校駅伝の予選は11月に行われる。',
      ]));
    case KishaKata.karakuchi:
      w.kishaNoMe('県大会で勝っても、全国の決勝はさらに遠い。夏のトラックの結果が、冬の駅伝の結果になるとも限らない。');
  }

  // 表のその後の欄(全国大会の決勝の順位・全国大会・地区大会まで)
  String sonoato(int sh, KoukouKirokuSousha y) {
    for (final e in ke[sh]) {
      if (_onajiSousha(e.y, y)) return '全国${e.juni}位';
    }
    for (final e in he[sh]) {
      if (identical(e.y, y)) return '全国大会';
    }
    return chikuAri ? '$chikuTaikaiまで' : '';
  }

  return [
    Kiji(
      category: kijiKoukouChihouSoutaiCategory,
      midashi: midashi,
      lead: lead,
      honbun: w.honbun,
      hyou: [
        for (final int sh in const [1, 0, 2])
          if (kenK[sh].isNotEmpty)
            KijiHyou('高校総体 $kenTaikai ${ev(sh)}(上位6人)', const ['順位', '選手', '高校', 'タイム', 'その後'], [
              for (int i = 0; i < kenK[sh].length; i++)
                [
                  '${i + 1}',
                  r.hyouMei(kenK[sh][i]),
                  r.kou(kenK[sh][i].kouCode),
                  jikanMoji(kenK[sh][i].time),
                  sonoato(sh, kenK[sh][i]),
                ],
            ]),
      ],
      haishin: _haishin(nen, koukouSoutaiMonth, koukouSoutaiDay, tane),
      kisha: kisha,
      jibun: false,
      kekka: true,
      site: site,
    ),
  ];
}

/// 見出しの型(地方版の全国高校駅伝の都道府県予選)
const int _gcyNiKou = 1; // 地区代表もこの都道府県から(2校が全国へ)
const int _gcyHatsu = 2; // 初めての代表
const int _gcyRenzoku = 3; // 連続の代表
const int _gcySessen = 4; // 2位との接戦
const int _gcyDokusou = 5; // 独走
const int _gcyKimaru = 6; // 代表が決まる(書くことがほかにないとき)

List<Kiji> _chihouYosenKiji(KijiKankyou k, KoukouTaikaiKiroku rec, KoukouChihouKiroku ck, int ken) {
  if (rec.yosenMada) return [];
  final List<KoukouYosenKen>? yo = rec.yosen;
  final List<KoukouChihouYosen>? cyAll = ck.yosen;
  if (yo == null || cyAll == null || ken < 0 || ken >= yo.length || ken >= cyAll.length) return [];
  final KoukouYosenKen yk = yo[ken];
  if (yk.teams.isEmpty) return [];
  final KoukouChihouYosen cy = cyAll[ken];
  final int c = ken < koukouKenChiku.length ? koukouKenChiku[ken] : -1;
  final bool chikuAri = c >= 0 && c < koukouChikuMei.length && _chikuKenSuu(c) >= 2;
  final int nen = rec.nyuugakuNendo - 1;
  final int tane = _tane(nen, _noChihouYosen, ken);
  final KijiKakite w = KijiKakite(k, tane);
  final _Kakite r = _Kakite(k, w, rec);
  final String site = kijiKoukouChihouSiteMei(ken);
  final String kisha = _kishaMei(k, tane, site);
  final KishaKata kata = kishaKataKara(kisha);
  final String kenMei = _kenMei(ken);
  final String chikuTaikai = chikuAri ? '${koukouChikuMei[c]}大会' : '';

  final KoukouYosenTeam t1 = yk.teams.first;
  final String kou1 = r.kou(t1.kouCode);
  final KoukouYosenTeam? t2 = yk.teams.length >= 2 ? yk.teams[1] : null;
  final KoukouYosenTeam? t3 = yk.teams.length >= 3 ? yk.teams[2] : null;
  final int? sa = t2 == null ? null : saByou(t2.time, t1.time);
  final Set<int> kenCode = {for (final KoukouYosenTeam t in yk.teams) t.kouCode};
  // 地区大会のこの都道府県の高校(順位つき)と、地区代表(北海道は予選の2位)
  final List<KoukouChikuTeam> chL = (chikuAri && rec.chiku != null && c < rec.chiku!.length)
      ? rec.chiku![c]
      : const <KoukouChikuTeam>[];
  final List<({KoukouChikuTeam t, int juni})> chKen = [
    for (int j = 0; j < chL.length; j++)
      if (kenCode.contains(chL[j].kouCode)) (t: chL[j], juni: j + 1),
  ];
  int chikuDai = -1;
  if (chikuAri) {
    for (final e in chKen) {
      if (e.t.daihyou == 2) chikuDai = e.t.kouCode;
    }
  } else if (t2 != null) {
    chikuDai = t2.kouCode;
  }
  // 前の回までの代表(連続の年数は、記録で確かめられるときだけ書く)
  final List<KoukouTaikaiKiroku> zen = koukouTaikaiKirokuYomu();
  KoukouTaikaiKiroku? kaiNo(int n) {
    for (final KoukouTaikaiKiroku x in zen) {
      if (x.nyuugakuNendo == n) return x;
    }
    return null;
  }

  int maeDaihyou(KoukouTaikaiKiroku? x) {
    final List<KoukouYosenKen>? y = x?.yosen;
    if (x == null || x.yosenMada || y == null || ken >= y.length || y[ken].teams.isEmpty) return -1;
    return y[ken].teams.first.kouCode;
  }

  int renzoku = 1;
  bool renzokuKaku = false;
  for (int n = rec.nyuugakuNendo - 1; n > rec.nyuugakuNendo - 20; n--) {
    final int m = maeDaihyou(kaiNo(n));
    if (m < 0) break;
    if (m != t1.kouCode) {
      renzokuKaku = true;
      break;
    }
    renzoku++;
  }
  // 初めての代表(記録を残している前の回が3回以上あり、どの回でも代表になっていない名簿の高校)
  final List<int> maeDai = [
    for (final KoukouTaikaiKiroku x in zen)
      if (x.nyuugakuNendo < rec.nyuugakuNendo && maeDaihyou(x) >= 0) maeDaihyou(x),
  ];
  final KoukouYuushouKaisuu kai = koukouYuushouKaisuuYomu();
  final bool hatsu = maeDai.length >= 3 &&
      t1.kouCode >= 0 &&
      t1.kouCode < kai.ken.length &&
      kai.ken[t1.kouCode] == 1 &&
      !maeDai.contains(t1.kouCode);

  final int g = r.kataErabuChihou([
    if (chikuDai >= 0) (g: _gcyNiKou, ten: chikuAri ? 85 : 45),
    if (hatsu) (g: _gcyHatsu, ten: 80),
    if (renzokuKaku && renzoku >= 3) (g: _gcyRenzoku, ten: 60 + 2 * (renzoku > 10 ? 10 : renzoku)),
    if (sa != null && sa <= 10) (g: _gcySessen, ten: sa <= 3 ? 85 : 72),
    if (sa != null && sa >= 120) (g: _gcyDokusou, ten: 50),
  ], _gcyKimaru);

  String midashi;
  switch (g) {
    case _gcyNiKou:
      midashi = chikuAri
          ? '$kenMeiから2校が全国へ　${r.kou(chikuDai)}が地区代表に'
          : '$kou1と${r.kou(chikuDai)}、全国高校駅伝へ　$kenMei予選';
    case _gcyHatsu:
      midashi = w.erabu(['$kou1、初の$kenMei代表　全国高校駅伝', '全国高校駅伝$kenMei予選、$kou1が初の代表に']);
    case _gcyRenzoku:
      midashi = '$kou1、$renzoku年連続の$kenMei代表　全国高校駅伝';
    case _gcySessen:
      midashi = '全国高校駅伝$kenMei予選、$kou1が${kinsaMoji(sa ?? 0)}で競り勝つ';
    case _gcyDokusou:
      midashi = '$kou1が独走で$kenMei代表に　2位に${saMoji(sa ?? 0)}差';
    default:
      midashi = w.erabu(['全国高校駅伝$kenMei予選、$kou1が制す', '$kou1、全国高校駅伝の$kenMei代表に']);
  }

  final String saBun =
      sa == null || t2 == null ? '' : '2位の${r.kou(t2.kouCode)}とは${sa <= 10 ? kinsaMoji(sa) : '${saMoji(sa)}差'}だった。';
  final String lead = switch (kata) {
    KishaKata.suuji => '全国高校駅伝の$kenMei予選(7区間42.195km)が行われ、$kou1が${jikanMoji(t1.time)}で優勝した。'
        '$kenMei代表として、12月の全国高校駅伝に出る。$saBun',
    KishaKata.joukei => '冬の全国の舞台へ、$kenMeiのたすきが託された。全国高校駅伝の$kenMei予選が行われ、'
        '$kou1が代表の座をつかんだ。',
    KishaKata.karakuchi => chikuAri
        ? '全国高校駅伝の$kenMei予選が行われ、$kou1が制した。予選で全国への切符を手にできるのは、優勝校だけだ。'
            '2位と3位の高校には、$chikuTaikaiでの最後の挑戦が残る。'
        : '全国高校駅伝の$kenMei予選が行われ、$kou1が制した。$kenMeiから全国に出られるのは、2位までだ。',
  };

  // 優勝の段落(タイム・連続・2位との差・優勝校の3年生)
  void yuushouDan() {
    final StringBuffer b = StringBuffer('優勝した$kou1のタイムは${jikanMoji(t1.time)}。');
    if (hatsu) {
      b.write('記録を残し始めてから、初めての代表だ。');
    } else if (renzokuKaku && renzoku >= 2) {
      b.write('$renzoku年連続の代表となった。');
    }
    if (kata != KishaKata.suuji) b.write(saBun);
    // 優勝校の区間賞の数
    final int shou = cy.kukanshou.where((KoukouChihouSousha e) => e.s.kouCode == t1.kouCode).length;
    if (shou >= 3) b.write('7区間のうち$shou区間で区間賞を取った。');
    final List<KoukouKirokuSousha> m = [
      for (final KoukouChihouSousha e in cy.yuushou)
        if (e.s.kukan >= 1 && _namae(e.s)) e.s,
    ];
    if (m.isNotEmpty) {
      final String mei = [
        for (final KoukouKirokuSousha y in m.take(4))
          '${y.kukan}区の${r.yobu(y, kouAri: false)}${y.kukanJuni >= 1 ? '(区間${y.kukanJuni == 1 ? '賞' : '${y.kukanJuni}位'})' : ''}',
      ].join('、');
      b.write('3年生では、$meiがたすきをつないだ。');
    }
    w.danraku(b.toString());
    if (w.r.kakuritsu(40)) {
      w.comment('「${w.erabu(_yuushouKantokuKotoba)}」と$kou1の監督は振り返った。');
    }
  }

  // 2・3位と地区大会(北海道は予選の2位が地区代表)
  void tsugiDan() {
    if (t2 == null) return;
    final String kou2 = r.kou(t2.kouCode);
    if (!chikuAri) {
      w.danraku('2位の$kou2も、地区代表として全国高校駅伝に出る。');
      return;
    }
    final StringBuffer b = StringBuffer(
      t3 == null ? '2位の$kou2は、$chikuTaikaiに進んだ。' : '2位の$kou2と3位の${r.kou(t3.kouCode)}は、$chikuTaikaiに進んだ。',
    );
    if (chKen.isNotEmpty) {
      b.write('$chikuTaikaiでは、${[for (final e in chKen) '${r.kou(e.t.kouCode)}が${e.juni}位'].join('、')}。');
      b.write(chikuDai >= 0
          ? '${r.kou(chikuDai)}が地区代表の座をつかみ、$kenMeiからは2校が全国に出る。'
          : '$kenMeiの高校は、地区代表に届かなかった。');
    }
    w.danraku(b.toString());
  }

  // 区間賞(1区と、ほかの区間)
  void kukanshouDan() {
    if (cy.kukanshou.isEmpty) return;
    final StringBuffer b = StringBuffer();
    final KoukouChihouSousha ikku = cy.kukanshou.first;
    if (ikku.s.kukan == 1) {
      b.write('1区の区間賞は${r.yobu(ikku.s)}で、${jikanMoji(ikku.s.time)}だった。');
    }
    final List<String> l = [
      for (final KoukouChihouSousha e in cy.kukanshou)
        if (e.s.kukan >= 2) '${e.s.kukan}区が${r.yobu(e.s)}',
    ];
    if (l.isNotEmpty) b.write('${ikku.s.kukan == 1 ? 'ほかの区間賞は、' : '区間賞は、'}${l.join('、')}だった。');
    w.danraku(b.toString());
  }

  // 地区大会の区間賞(この都道府県の高校の選手)
  void chikuShouDan() {
    if (!chikuAri) return;
    final List<List<KoukouChihouSousha>>? cs = ck.chikuKukanshou;
    if (cs == null || c >= cs.length) return;
    final List<String> l = [
      for (final KoukouChihouSousha e in cs[c])
        if (kenCode.contains(e.s.kouCode)) '${e.s.kukan}区の${r.yobu(e.s)}',
    ];
    if (l.isEmpty) return;
    w.danraku('$chikuTaikaiでは、${_narabe(l, '人')}が区間賞を取った。');
  }

  // ほかの高校の3年生(区間順位の良い順に3人まで。優勝校の選手は優勝の段落で書く)
  void sannenDan() {
    final List<KoukouChihouSousha> l = [
      for (final KoukouChihouSousha e in cy.namae)
        if (e.s.kukan >= 1 && e.s.kouCode != t1.kouCode && _namae(e.s)) e,
    ]..sort((a, b) {
        final int x = a.s.kukanJuni.compareTo(b.s.kukanJuni);
        return x != 0 ? x : a.teamJuni.compareTo(b.teamJuni);
      });
    if (l.isEmpty) return;
    final String mei = [
      for (final KoukouChihouSousha e in l.take(3))
        '${e.teamJuni}位の${r.kou(e.s.kouCode)}の${r.yobu(e.s, kouAri: false)}が${e.s.kukan}区で'
            '${e.s.kukanJuni == 1 ? '区間賞' : '区間${e.s.kukanJuni}位'}',
    ].join('、');
    w.danraku('ほかの高校の3年生では、$meiだった。');
  }

  final List<void Function()> dan = [yuushouDan, tsugiDan, kukanshouDan, chikuShouDan, sannenDan];
  final int atama = g == _gcyNiKou ? 1 : 0;
  dan[atama]();
  for (int i = 0; i < dan.length; i++) {
    if (i != atama) dan[i]();
  }
  // 記者の目
  switch (kata) {
    case KishaKata.suuji:
      w.kishaNoMe('$kenMei予選の出場は${yk.shussouSuu}校。$kou1の優勝タイムは${jikanMoji(t1.time)}だった。'
          '全国高校駅伝は12月下旬に行われる。');
    case KishaKata.joukei:
      w.kishaNoMe(w.erabu([
        '$kenMeiの仲間の思いも乗せたたすきが、12月の全国の舞台へ向かう。',
        '予選で敗れた高校の分まで、$kenMeiのたすきをつないでほしい。全国高校駅伝は12月下旬だ。',
      ]));
    case KishaKata.karakuchi:
      w.kishaNoMe('予選を勝っても、全国では力の差を突きつけられることもある。12月までの1か月で、どこまで仕上げられるか。');
  }

  // 予選の結果の表の備考
  String bikou(KoukouYosenTeam t) {
    if (t.juni == 1) return '$kenMei代表';
    if (t.kouCode == chikuDai) return '地区代表';
    if (chikuAri && t.juni <= 3) return '$chikuTaikaiへ';
    return '';
  }

  return [
    Kiji(
      category: kijiKoukouChihouYosenCategory,
      midashi: midashi,
      lead: lead,
      honbun: w.honbun,
      hyou: [
        KijiHyou('全国高校駅伝 $kenMei予選', const ['順位', '高校', 'タイム', '備考'], [
          for (final KoukouYosenTeam t in yk.teams) ['${t.juni}', r.kou(t.kouCode), jikanMoji(t.time), bikou(t)],
        ]),
        if (cy.kukanshou.isNotEmpty)
          KijiHyou('$kenMei予選の区間賞', const ['区間', '選手', '高校', 'タイム'], [
            for (final KoukouChihouSousha e in cy.kukanshou)
              ['${e.s.kukan}区', r.hyouMei(e.s), r.kou(e.s.kouCode), jikanMoji(e.s.time)],
          ]),
        if (cy.yuushou.isNotEmpty)
          KijiHyou('優勝した$kou1の走者', const ['区間', '選手', '区間順位', 'タイム'], [
            for (final KoukouChihouSousha e in cy.yuushou)
              ['${e.s.kukan}区', r.hyouMei(e.s), e.s.kukanJuni >= 1 ? '${e.s.kukanJuni}位' : '', jikanMoji(e.s.time)],
          ]),
        if (chKen.isNotEmpty)
          KijiHyou('$chikuTaikai($kenMeiの高校)', const ['順位', '高校', 'タイム', '備考'], [
            for (final e in chKen)
              [
                '${e.juni}',
                r.kou(e.t.kouCode),
                jikanMoji(e.t.time),
                e.t.daihyou == 1 ? '$kenMei代表' : (e.t.daihyou == 2 ? '地区代表' : ''),
              ],
          ]),
      ],
      haishin: _haishin(nen, koukouYosenMonth, koukouYosenDay, tane),
      kisha: kisha,
      jibun: false,
      kekka: true,
      site: site,
    ),
  ];
}

/// 地方版の記事(2.0.4。都道府県[ken]の、出した大会の分だけ。新しい順: 全国高校駅伝の予選・高校総体)
/// 高校の情報を表示しない設定のときと、地方版の記録がないとき(7月下旬に計算した回でないときなど)は空
List<Kiji> koukouChihouKiji(int ken) {
  if (!koukouChihoubanAri) return []; // 地方版を出さないあいだ(2.0.4)
  final KijiKankyou? k = KijiKankyou.yomuRace(2);
  if (k == null || koukouHyoujiNashi(k.kantoku)) return [];
  final KoukouTaikaiKiroku? rec = koukouKijiNoKai();
  if (rec == null) return [];
  final KoukouChihouKiroku? ck = koukouChihouKirokuYomu(rec.nyuugakuNendo);
  if (ck == null) return [];
  final List<Kiji> l = [];
  try {
    l.addAll(_chihouYosenKiji(k, rec, ck, ken));
  } catch (e, st) {
    print('地方版の全国高校駅伝の予選の記事を作れませんでした: $e\n$st');
  }
  try {
    l.addAll(_chihouSoutaiKiji(k, rec, ck, ken));
  } catch (e, st) {
    print('地方版の高校総体の記事を作れませんでした: $e\n$st');
  }
  return l;
}

/// 地方版の記事を読めるか(今年度の高校の大会の記事を書く回に、地方版の記録があるか。2.0.4)
bool koukouChihouAri() {
  if (!koukouChihoubanAri) return false; // 地方版を出さないあいだ(2.0.4。入口のカードとボタンも出ない)
  final KoukouTaikaiKiroku? rec = koukouKijiNoKai();
  if (rec == null) return false;
  return koukouChihouKirokuYomu(rec.nyuugakuNendo) != null;
}

// ------------------------------------------------------------
// 入口
// ------------------------------------------------------------

/// 今年度の高校の大会の記事(箱庭スポーツ。出した大会の分だけ、新しい順。全国高校駅伝・予選と地区大会・高校総体)
/// 高校の情報を表示しない設定のときと、記事を書く回がないときは空
List<Kiji> koukouShinkouKiji() {
  final KijiKankyou? k = KijiKankyou.yomuRace(2);
  if (k == null || koukouHyoujiNashi(k.kantoku)) return [];
  final KoukouTaikaiKiroku? rec = koukouKijiNoKai();
  if (rec == null) return [];
  final KoukouTaikaiKiroku? mae = _maeNoKai(rec);
  final List<Kiji> l = [];
  // 1本作れなくても、ほかの記事は出す(飾りの記事なので)
  try {
    l.addAll(_zenkokuKiji(k, rec, mae));
  } catch (e, st) {
    print('全国高校駅伝の記事を作れませんでした: $e\n$st');
  }
  try {
    l.addAll(_yosenKiji(k, rec, mae));
  } catch (e, st) {
    print('全国高校駅伝の予選の記事を作れませんでした: $e\n$st');
  }
  try {
    l.addAll(_soutaiKiji(k, rec));
  } catch (e, st) {
    print('高校総体の記事を作れませんでした: $e\n$st');
  }
  return l;
}
