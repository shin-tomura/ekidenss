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
// ------------------------------------------------------------

const int _gyOu = 1; // 前回の優勝校の予選敗退
const int _gyMeimon = 2; // 名門の予選敗退
const int _gyHatsu = 3; // 初出場
const int _gyRenzoku = 4; // 連続出場
const int _gyChiku = 5; // 地区大会の接戦
const int _gyKimaru = 6; // 出場校が決まる(書くことがほかにないとき)

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

  // 出場の回数目(全国高校駅伝の結果を出したあとは、記録の回数目。出す前は見込み)
  final Map<int, ({int kaime, int renzoku, int buri})> kaime = {};
  if (rec.zenkokuMada) {
    kaime.addAll(koukouShutsujouMikomi([for (final e in deru) e.code], rec.nyuugakuNendo));
  } else {
    for (final KoukouKirokuTeam t in rec.zenkoku) {
      kaime[t.kouCode] = (kaime: t.kaime, renzoku: t.renzoku, buri: t.shutsujouBuri);
    }
  }
  // 初出場は、記録を残している回が3回以上あるときだけ書く(始めたばかりは初出場ばかりなので)
  final int maeKaiSuu = koukouTaikaiKirokuYomu()
      .where((KoukouTaikaiKiroku x) => x.nyuugakuNendo < rec.nyuugakuNendo && x.zenkoku.isNotEmpty)
      .length;
  final List<int> hatsu = [
    for (final e in deru)
      if ((kaime[e.code]?.kaime ?? 0) == 1) e.code,
  ];
  final bool hatsuKaku = maeKaiSuu >= 3 && hatsu.isNotEmpty && hatsu.length <= 6;
  // 一番長く連続して出場する高校
  int renCode = -1;
  for (final e in deru) {
    final int rn = kaime[e.code]?.renzoku ?? 0;
    if (rn < 3) continue;
    if (renCode < 0 || rn > (kaime[renCode]?.renzoku ?? 0)) renCode = e.code;
  }
  // 前回の優勝校
  final int maeOu = (mae != null && mae.zenkoku.isNotEmpty) ? mae.zenkoku.first.kouCode : -1;
  final bool maeOuOchi = maeOu >= 0 && maeOu < 1000 && !deruCode.contains(maeOu);
  // 予選で敗れた名門(予選の順位が一番上の名門。前回の優勝校は除く)
  final List<KoukouMei> meibo = koukouMeiboGenzai();
  int meimonOchi = -1;
  int meimonJuni = 99;
  final List<KoukouYosenKen> yo = rec.yosen ?? const [];
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
  // 地区大会の接戦(地区代表と、県代表を除いた次の高校の差が一番小さい地区)
  ({int c, int dai, int tsugi, int sa})? sessenMoto;
  final List<List<KoukouChikuTeam>> ch = rec.chiku ?? const [];
  for (int c = 0; c < ch.length && c < koukouChikuMei.length; c++) {
    final List<KoukouChikuTeam> l = ch[c];
    final int i = l.indexWhere((KoukouChikuTeam t) => t.daihyou == 2);
    if (i < 0) continue;
    for (int j = i + 1; j < l.length; j++) {
      if (l[j].daihyou != 0) continue;
      final int sa = saByou(l[j].time, l[i].time);
      final ({int c, int dai, int tsugi, int sa})? mae0 = sessenMoto;
      if (mae0 == null || sa < mae0.sa) sessenMoto = (c: c, dai: l[i].kouCode, tsugi: l[j].kouCode, sa: sa);
      break;
    }
  }
  final ({int c, int dai, int tsugi, int sa})? sessen = sessenMoto;

  final int g = r.kataErabu([
    if (maeOuOchi) (g: _gyOu, ten: 95),
    if (meimonOchi >= 0) (g: _gyMeimon, ten: (meimonOchi < kai.zenkoku.length && kai.zenkoku[meimonOchi] > 0) ? 80 : 70),
    if (hatsuKaku) (g: _gyHatsu, ten: 60 + 5 * (hatsu.length > 3 ? 3 : hatsu.length)),
    if (renCode >= 0) (g: _gyRenzoku, ten: (kaime[renCode]?.renzoku ?? 0) >= 5 ? 65 : 50),
    if (sessen != null && sessen.sa <= 10) (g: _gyChiku, ten: sessen.sa <= 3 ? 80 : 65),
  ], _midashiYosen, _gyKimaru);

  final int n = deru.length;
  String midashi;
  switch (g) {
    case _gyOu:
      midashi = w.erabu(['前回王者の${r.kou(maeOu)}、予選で敗れる　全国高校駅伝', '${r.kou(maeOu)}、連覇ならず　全国高校駅伝の予選で敗退']);
    case _gyMeimon:
      midashi = w.erabu(['名門${r.kou(meimonOchi)}、全国への道絶たれる', '${r.kou(meimonOchi)}が予選で敗退　全国高校駅伝の出場$n校決まる']);
    case _gyHatsu:
      midashi = hatsu.length == 1
          ? '${r.kou(hatsu.first)}が全国初出場　全国高校駅伝の出場$n校決まる'
          : '${r.kou(hatsu.first)}など${hatsu.length}校が初出場　全国高校駅伝';
    case _gyRenzoku:
      midashi = '${r.kou(renCode)}、${kaime[renCode]!.renzoku}年連続の全国へ　全国高校駅伝の出場$n校決まる';
    case _gyChiku:
      final ({int c, int dai, int tsugi, int sa}) s = sessen!;
      midashi = '${koukouChikuMei[s.c]}大会、${r.kou(s.dai)}が${kinsaMoji(s.sa)}で地区代表に　全国高校駅伝';
    default:
      midashi = '全国高校駅伝の出場$n校が決まる';
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
      w.danraku(b.toString());
    } else {
      final ({int kaime, int renzoku, int buri})? m = kaime[maeOu];
      final String sj = m == null ? '' : _shutsujouMoji(m.kaime, m.renzoku, m.buri);
      w.danraku(sj.isEmpty ? '前回優勝の$mkは、予選を勝ち抜き、連覇に挑む。' : '前回優勝の$mkは、$sjの出場で連覇に挑む。');
    }
  }

  void meimonDan() {
    if (meimonOchi < 0) return;
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

  void hatsuDan() {
    if (!hatsuKaku) return;
    final List<String> mei = [for (final int c in hatsu.take(4)) r.kou(c)];
    w.danraku(hatsu.length == 1
        ? '${mei.first}は、記録を残し始めてから初めての全国出場となる。'
        : '初出場は${mei.join('、')}${hatsu.length > 4 ? 'など' : 'の'}${hatsu.length}校。新しい顔ぶれが全国の舞台に立つ。');
  }

  void renzokuDan() {
    if (renCode < 0) return;
    final ({int kaime, int renzoku, int buri}) m = kaime[renCode]!;
    w.danraku('${r.kou(renCode)}は、${m.renzoku}年連続${m.kaime}回目の出場を決めた。');
  }

  void chikuDan() {
    final ({int c, int dai, int tsugi, int sa})? s = sessen;
    if (s == null || s.sa > 30) return;
    w.danraku('${koukouChikuMei[s.c]}大会では、${r.kou(s.dai)}が${r.kou(s.tsugi)}を${kinsaMoji(s.sa)}で振り切り、'
        '地区代表の座をつかんだ。');
  }

  final List<void Function()> dan = [maeOuDan, meimonDan, hatsuDan, renzokuDan, chikuDan];
  final int atama = switch (g) {
    _gyMeimon => 1,
    _gyHatsu => 2,
    _gyRenzoku => 3,
    _gyChiku => 4,
    _ => 0,
  };
  dan[atama]();
  for (int i = 0; i < dan.length; i++) {
    if (i != atama) dan[i]();
  }
  // 記者の目
  final int renSuu = deru.where((e) => (kaime[e.code]?.renzoku ?? 0) >= 2).length;
  switch (kata) {
    case KishaKata.suuji:
      w.kishaNoMe(hatsuKaku
          ? '出場$n校のうち、初出場は${hatsu.length}校、連続出場は$renSuu校。12月下旬、全国の舞台で順位がつく。'
          : '出場$n校のうち、連続出場は$renSuu校。12月下旬、全国の舞台で順位がつく。');
    case KishaKata.joukei:
      w.kishaNoMe('予選で涙をのんだ高校の思いも背負い、$n校がたすきをつなぐ。12月下旬の本番が待ち遠しい。');
    case KishaKata.karakuchi:
      w.kishaNoMe('予選を勝ち上がっても、全国では別の戦いが待つ。地区代表として出る高校が、どこまで食い込むかにも注目したい。');
  }

  return [
    Kiji(
      category: kijiKoukouYosenCategory,
      midashi: midashi,
      lead: lead,
      honbun: w.honbun,
      hyou: [
        KijiHyou('地区代表($chikuSuu校)', const ['地区', '高校', '地区大会'], [
          for (final e in deru)
            if (e.chiku >= 0 && e.chiku < koukouChikuMei.length) _chikuDaihyouGyou(rec, r, e.code, e.chiku),
        ]),
      ],
      haishin: _haishin(nen, koukouYosenMonth, koukouYosenDay, tane),
      kisha: kisha,
      jibun: false,
      kekka: true,
    ),
  ];
}

/// 地区代表の表の1行(地区・高校・地区大会の順位とタイム。北海道は予選の2位)
List<String> _chikuDaihyouGyou(KoukouTaikaiKiroku rec, _Kakite r, int code, int c) {
  final KoukouKaiSeiseki s = koukouKaiSeisekiYomu(rec, code);
  final KoukouChikuTeam? t = s.chiku;
  final String kekka = t != null ? '${s.chikuJuni}位 ${jikanMoji(t.time)}' : (s.yosen != null ? '予選${s.yosen!.juni}位' : '');
  return [koukouChikuMei[c], r.kou(code), kekka];
}

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
