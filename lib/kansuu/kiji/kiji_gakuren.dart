import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/univ_gakuren_data.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/kansuu/gakuren_kantoku.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_comment.dart';

// ------------------------------------------------------------
// 学連選抜を追う専門メディア「学連選抜通信」(1.9.7。正月駅伝だけ)
//
// 記事(どれも今年の学連選抜のことだけ)
//  1. 展望号(学連選抜編成の画面のカードと、直前順位予想の画面の展望記事の切り替え):
//     チームの紹介(監督・目標・顔ぶれ・区間配置・自分の大学から選ばれた選手)と、走る全員の選手名鑑
//     ・自分の大学が正月駅伝に出られない年は、直前順位予想の画面を通らないので、
//       1月5日に必ず通る学連選抜編成の画面にカードを置いた
//     ・学連選抜編成の画面は区間エントリーの前の場面なので、大学の選手との比べ(区間内の順位など)は書かない。
//       持ちタイムは、学連選抜の中の順番と、学生全体の順位(選手画面の「全体」)で書く
//  2. 区間ごとの速報(レース画面の「実況・速報」のカードと、結果画面の記事の画面の切り替え):
//     区間が終わるたびに1本。学連選抜の走者の走り・順位相当の上げ下げ・トップやシード権相当との差・
//     指示の成否・中継所での一言・次の走者
//  3. 結果号(結果画面の記事の画面の切り替え): チームの結果と、走った全員の振り返り
//
// 守る決まり(箱庭スポーツ・学内メディアと同じ)
//  ・能力値は書かない。総監督(プレイヤー)の言葉は作らない(指揮を執ったことと、目標だけ書く)
//  ・学連選抜の選ばれ方の決まり(各校の予選のタイムの順など)は説明書に書いていないので、記事でも触れない。
//    「予選会でチーム内○番手」のような事実だけを書く
//  ・オープン参加なので、順位はいつも「○位相当」と書く
//  ・目標順位は6区のスタート前に決め直せるので、目標との比べは、読んだときの一番新しい区間の速報と、
//    結果号でだけ書く(前の区間の速報を読み返したときに、そのときと違う目標で書かないように)
// ------------------------------------------------------------

/// サイト名
const String gakurenSiteMei = '学連選抜通信';

/// 正月駅伝と正月駅伝予選の大会の番号
const int _race = 2;
const int _yosen = 4;

/// 正月駅伝のシード権の数(大学の中に入れたときの「シード権の圏内」の線)
const int _seedSuu = 10;

/// 学連選抜の走者1人分
class _GSenshu {
  /// 学連選抜の選手のデータ
  final Senshu_Gakuren_Data g;

  /// 元の選手(所属大学の選手のデータ。見つからなければnull)
  final SenshuData? s;

  /// 走る区間(0が1区)
  final int kukan;

  /// 所属大学(見つからなければnull)
  final UnivData? u;

  _GSenshu(this.g, this.s, this.kukan, this.u);

  /// 所属大学の呼び方(「東西大」)
  String get shozoku {
    final UnivData? x = u;
    return x == null ? '所属校' : daigakuMei(x);
  }
}

/// 元の選手(id の選手。見つからなければnull)
SenshuData? _motoSenshu(KijiKankyou k, int id) {
  if (id >= 0 && id < k.senshu.length && k.senshu[id].id == id) {
    return k.senshu[id];
  }
  for (final SenshuData s in k.senshu) {
    if (s.id == id) return s;
  }
  return null;
}

/// 今年の学連選抜の走者(区間の順。正月駅伝でないときや、学連選抜がいないときは空)
List<_GSenshu> _gSenshuList(KijiKankyou k) {
  if (k.race != _race || !gakurenKonnenAri(k.gh)) return [];
  final int ks = k.kukansuu;
  final List<_GSenshu> list = [];
  for (final Senshu_Gakuren_Data g in Hive.box<Senshu_Gakuren_Data>(
    'gakurenSenshuBox',
  ).values) {
    final int kk = gakurenEntry(g);
    if (kk < 0 || kk >= ks) continue;
    list.add(
      _GSenshu(
        g,
        _motoSenshu(k, g.id),
        kk,
        (g.univid >= 0 && g.univid < k.univ.length) ? k.univ[g.univid] : null,
      ),
    );
  }
  list.sort((a, b) => a.kukan.compareTo(b.kukan));
  return list;
}

/// 区間[kk]を走る学連選抜の走者(いなければnull)
_GSenshu? _kukanNoSenshu(List<_GSenshu> list, int kk) {
  for (final _GSenshu x in list) {
    if (x.kukan == kk) return x;
  }
  return null;
}

/// 走者の呼び方(初めては「山田太郎(3年)」、2回目からは「山田」)
/// [daigaku] 初めて出すときに「東西大の」を前に付けるか
String _mei(KijiKakite w, _GSenshu x, {bool daigaku = false}) {
  final SenshuData? s = x.s;
  if (s != null) return w.senshu(s, daigaku: daigaku);
  return w.hito(
    'G${x.g.id}',
    x.g.name,
    '${x.g.gakunen}年',
    daigaku ? '${x.shozoku}の' : '',
  );
}

/// 正月駅伝予選の全体順位(0が1位)とタイム(走っていなければnull。タイムがなければ DEFAULTTIME)
({int juni, double time})? _yosenKekka(Senshu_Gakuren_Data g) {
  final int gi = g.gakunen - 1;
  if (gi < 0 ||
      g.kukanjuni_race.length <= _yosen ||
      g.kukanjuni_race[_yosen].length <= gi) {
    return null;
  }
  final int j = g.kukanjuni_race[_yosen][gi];
  if (j < 0 || j >= TEISUU.DEFAULTJUNI) return null;
  double t = TEISUU.DEFAULTTIME;
  if (g.kukantime_race.length > _yosen && g.kukantime_race[_yosen].length > gi) {
    t = g.kukantime_race[_yosen][gi];
  }
  return (juni: j, time: t);
}

/// 予選会での、所属大学の中のタイムの順番(0がチームトップ。分からなければnull)
int? _teamNaiBan(KijiKankyou k, _GSenshu x, double time) {
  if (time <= 0 || time >= TEISUU.DEFAULTTIME) return null;
  int mae = 0;
  bool ari = false;
  for (final SenshuData s in k.senshu) {
    if (s.univid != x.g.univid || s.gakunen < 1 || s.gakunen > 4) continue;
    final int gi = s.gakunen - 1;
    if (s.entrykukan_race.length <= _yosen ||
        s.entrykukan_race[_yosen].length <= gi ||
        s.entrykukan_race[_yosen][gi] < 0) {
      continue;
    }
    if (s.kukantime_race.length <= _yosen || s.kukantime_race[_yosen].length <= gi) {
      continue;
    }
    final double t = s.kukantime_race[_yosen][gi];
    if (t <= 0 || t >= TEISUU.DEFAULTTIME) continue;
    ari = true;
    if (t < time) mae++;
  }
  return ari ? mae : null;
}

/// 予選会の一言(「予選会は全体12位(1時間03分21秒)で、チーム内2番手」。走っていなければ空)
String _yosenMoji(KijiKankyou k, _GSenshu x) {
  final ({int juni, double time})? y = _yosenKekka(x.g);
  if (y == null) return '';
  final bool timeAri = y.time > 0 && y.time < TEISUU.DEFAULTTIME;
  final int? ban = timeAri ? _teamNaiBan(k, x, y.time) : null;
  final String banMoji = ban == null
      ? ''
      : (ban == 0 ? '、チームトップ' : '、チーム内${ban + 1}番手');
  return '予選会は全体${juniMoji(y.juni)}${timeAri ? '(${jikanMoji(y.time)})' : ''}$banMoji';
}

/// 前の学年までに正月駅伝を走った回数(大学のチームでと、学連選抜で)と、
/// 昨年も学連選抜で走ったか
({int daigaku, int gakuren, bool kyonenGakuren}) _shougatsuReki(SenshuData? s) {
  if (s == null) return (daigaku: 0, gakuren: 0, kyonenGakuren: false);
  int d = 0;
  int gk = 0;
  bool kyonen = false;
  for (int gi = 0; gi < s.gakunen - 1; gi++) {
    if (s.entrykukan_race.length <= _race || s.entrykukan_race[_race].length <= gi) {
      continue;
    }
    if (s.entrykukan_race[_race][gi] < 0) continue;
    final int j = (s.kukanjuni_race.length > _race && s.kukanjuni_race[_race].length > gi)
        ? s.kukanjuni_race[_race][gi]
        : TEISUU.DEFAULTJUNI;
    if (gakurenShussouJuni(_race, j)) {
      gk++;
      if (gi == s.gakunen - 2) kyonen = true;
    } else if (shutsujouJuni(j)) {
      d++;
    }
  }
  return (daigaku: d, gakuren: gk, kyonenGakuren: kyonen);
}

/// 自己ベスト(元の選手。なければ学連選抜の選手のデータ。記録がなければ DEFAULTTIME)
double _best(KijiKankyou k, _GSenshu x, int idx) {
  final SenshuData? s = x.s;
  if (s != null) return k.jikoBest(s, idx);
  if (idx < 0 || x.g.time_bestkiroku.length <= idx) return TEISUU.DEFAULTTIME;
  final double t = x.g.time_bestkiroku[idx];
  return t > 0 ? t : TEISUU.DEFAULTTIME;
}

/// 区間[kk]の距離に合った種目の持ちタイムの文(「ハーフ1時間02分10秒」。記録がなければnull)
String? _mochiMoji(KijiKankyou k, _GSenshu x, int kk) {
  final int idx = kukanKihonShumoku(k.gh, _race, kk);
  final double t = _best(k, x, idx);
  if (t >= TEISUU.DEFAULTTIME) return null;
  return '${kijiShumokuMei[idx]}${jikanMoji(t)}';
}

/// 学連選抜の中での、種目[idx]の持ちタイムの順番(0が一番速い。記録がなければnull)
int? _gakurenNaiBan(KijiKankyou k, List<_GSenshu> list, _GSenshu x, int idx) {
  final double t = _best(k, x, idx);
  if (t >= TEISUU.DEFAULTTIME) return null;
  int mae = 0;
  for (final _GSenshu y in list) {
    if (y.g.id == x.g.id) continue;
    if (_best(k, y, idx) < t) mae++;
  }
  return mae;
}

/// 学生全体での、種目[idx]の持ちタイムの順位(0が1位。分からなければnull)
int? _zentaiJuni(_GSenshu x, int idx) {
  final SenshuData? s = x.s;
  if (s == null || idx < 0 || s.zentaijuni_bestkiroku.length <= idx) return null;
  final int j = s.zentaijuni_bestkiroku[idx];
  return (j >= 0 && j < TEISUU.DEFAULTJUNI) ? j : null;
}

/// プレイヤーが学連選抜の監督をしているか
bool _kantokuChuu(KijiKankyou k) {
  final UnivData? my = k.jibunUniv;
  return my != null && gakurenKantokuChuu(k.kantoku, my);
}

/// 学連選抜の目標順位(0が1位。監督をしていればプレイヤーが決めた順位、コンピュータが監督なら10位)
int _mokuhyou(KijiKankyou k) {
  final UnivData? my = k.jibunUniv;
  return my == null ? 9 : gakurenMokuhyou(k.kantoku, my);
}

/// 自分の大学から選ばれた走者(いなければnull)
_GSenshu? _jibunNoSenshu(KijiKankyou k, List<_GSenshu> list) {
  final UnivData? my = k.jibunUniv;
  if (my == null) return null;
  for (final _GSenshu x in list) {
    if (x.g.univid == my.id) return x;
  }
  return null;
}

/// 区間[kk]の終了時点の、出場した大学の累計タイム(速い順)
List<({UnivData u, double t})> _daigakuJun(KijiKankyou k, int kk) {
  final List<({UnivData u, double t})> list = [];
  for (final UnivData u in k.univ) {
    if (!k.shutsujou(u)) continue;
    if (u.time_taikai_total.length <= kk) continue;
    final double t = u.time_taikai_total[kk];
    if (t <= 0 || t >= TEISUU.DEFAULTTIME) continue;
    list.add((u: u, t: t));
  }
  list.sort((a, b) => a.t.compareTo(b.t));
  return list;
}

/// 学連選抜のチームのデータ(なければnull。目標を下回った・上回ったの印を読む)
UnivGakurenData? _gakurenUniv() {
  final Box<UnivGakurenData> box = Hive.box<UnivGakurenData>('gakurenUnivBox');
  return box.isEmpty ? null : box.values.first;
}

/// 区間[kk]の走者が、目標を下回った位置でたすきを受けて突っ込んだか(1)・上回ってほっと一息か(-1)・どちらでもないか(0)
int _mokuhyouFlag(UnivGakurenData? u, int kk) {
  if (u == null || kk <= 0) return 0;
  if (u.mokuhyojuniwositamawatteruflag.length <= kk - 1) return 0;
  final int f = u.mokuhyojuniwositamawatteruflag[kk - 1];
  return f == 1 ? 1 : (f < 0 ? -1 : 0);
}

/// 記者の名前(年・大会・記事で決まる)
String _kishaMei(KijiKankyou k, int no) {
  final KijiRand r = KijiRand(kijiTane(k.gh, k.race, no, 93));
  final List<String> mae = [
    for (final String n in k.gh.name_mae)
      if (n.isNotEmpty) n,
  ];
  final List<String> ato = [
    for (final String n in k.gh.name_ato)
      if (n.isNotEmpty) n,
  ];
  if (mae.isEmpty || ato.isEmpty) return '$gakurenSiteMei 編集部';
  return '$gakurenSiteMei ${r.erabu(mae)}${r.erabu(ato)}';
}

/// 記事を作るときの共通の仕上げ
Kiji _kansei(
  KijiKankyou k,
  int no,
  KijiKakite w, {
  required String category,
  required String midashi,
  required String lead,
  required bool kekka,
  List<KijiHyou> hyou = const [],
  String? haishin,
  String? kisha,
}) {
  return Kiji(
    category: category,
    midashi: midashi,
    lead: lead,
    honbun: w.honbun,
    hyou: hyou,
    haishin: haishin ?? k.haishinMei(no, asa: !kekka),
    kisha: kisha ?? _kishaMei(k, no),
    jibun: false,
    kekka: kekka,
    site: gakurenSiteMei,
  );
}

/// 人の名前を「、」でつなぐ(4人以上なら「○人」)
String _narabe(KijiKakite w, List<_GSenshu> l) {
  return [for (final _GSenshu x in l) '${_mei(w, x)}(${x.shozoku})'].join('、');
}

// ------------------------------------------------------------
// 1. 展望号
// ------------------------------------------------------------

/// 学連選抜通信の展望号(今年の学連選抜がいなければ空)
List<Kiji> gakurenTenbouKiji(KijiKankyou k) {
  final List<_GSenshu> list = _gSenshuList(k);
  if (list.isEmpty) return [];
  return [_tenbouTop(k, list), _tenbouMeikan(k, list)];
}

Kiji _tenbouTop(KijiKankyou k, List<_GSenshu> list) {
  const int no = 301;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int n = list.length;
  final int ks = k.kukansuu;
  final UnivData? my = k.jibunUniv;
  final String myMei = my == null ? '' : daigakuMei(my);
  final bool kantoku = _kantokuChuu(k) && my != null;
  final int mk = _mokuhyou(k);
  final int kousuu = {for (final _GSenshu x in list) x.g.univid}.length;
  // エース(ハーフの持ちタイムが一番速い選手。ハーフの記録がそろわなければ1万m、5000m)
  _GSenshu? ace;
  int aceIdx = 2;
  for (final int idx in const [2, 1, 0]) {
    for (final _GSenshu x in list) {
      final double t = _best(k, x, idx);
      if (t >= TEISUU.DEFAULTTIME) continue;
      if (ace == null || t < _best(k, ace, idx)) ace = x;
    }
    if (ace != null) {
      aceIdx = idx;
      break;
    }
  }
  // 予選会で一番上位だった選手
  _GSenshu? yosenTop;
  int yosenTopJ = TEISUU.DEFAULTJUNI;
  for (final _GSenshu x in list) {
    final ({int juni, double time})? y = _yosenKekka(x.g);
    if (y != null && y.juni < yosenTopJ) {
      yosenTopJ = y.juni;
      yosenTop = x;
    }
  }
  final _GSenshu? jibun = _jibunNoSenshu(k, list);

  // 見出し
  String midashi = kantoku
      ? '$myMeiの総監督が率いる学連選抜、目標は${juniMoji(mk)}相当'
      : w.erabu([
          '学連選抜、$kousuu校の思いを背負って${k.raceMei}へ',
          '予選会の悔しさを力に　学連選抜が${k.raceMei}に挑む',
        ]);
  if (ace != null) midashi += '　エースは${myouji(ace.g.name)}(${ace.shozoku})';

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}に、予選会で本戦への出場を逃した大学の選手で編成する学連選抜が、オープン参加で出場する。',
  );
  lead.write('$kousuu校から選ばれた$n人が、たすきをつなぐ。');
  if (kantoku) {
    lead.write('指揮を執るのは、本戦出場を逃した$myMeiの総監督。目標は${juniMoji(mk)}相当に据えた。');
    if (mk == 0) {
      lead.write('1位相当に導けば、監督の手腕が評価され、$myMeiの名声も大きく上がる。');
    }
  } else {
    lead.write('目標は${juniMoji(mk)}相当だ。');
  }
  lead.write('順位はつかず、大学の中に入れた場合の「○位相当」で記録される。');

  // 本文: チームの顔ぶれ
  w.koMidashi('チームの顔ぶれ');
  final StringBuffer kb = StringBuffer();
  final List<String> uchiwake = [
    for (int g = 4; g >= 1; g--)
      if (list.any((x) => x.g.gakunen == g))
        '$g年生${list.where((x) => x.g.gakunen == g).length}人',
  ];
  if (uchiwake.isNotEmpty) kb.write('$n人の内訳は、${uchiwake.join('、')}。');
  if (ace != null) {
    final double t = _best(k, ace, aceIdx);
    kb.write(
      '持ちタイムで一番速いのは${_mei(w, ace, daigaku: true)}で、'
      '${kijiShumokuMei[aceIdx]}${jikanMoji(t)}。',
    );
    final int? zj = _zentaiJuni(ace, aceIdx);
    if (zj != null && zj < 100) kb.write('学生全体でも${zj + 1}番目の記録だ。');
  }
  if (yosenTop != null && (ace == null || yosenTop.g.id != ace.g.id)) {
    kb.write('予選会で最も上位だったのは${_mei(w, yosenTop, daigaku: true)}で、全体${juniMoji(yosenTopJ)}だった。');
  }
  w.danraku(kb.toString());
  // 正月駅伝の経験と4年生
  final List<_GSenshu> gakurenKeiken = [
    for (final _GSenshu x in list)
      if (_shougatsuReki(x.s).gakuren > 0) x,
  ];
  final List<_GSenshu> daigakuKeiken = [
    for (final _GSenshu x in list)
      if (_shougatsuReki(x.s).daigaku > 0) x,
  ];
  final List<_GSenshu> yonen = [
    for (final _GSenshu x in list)
      if (x.g.gakunen == 4) x,
  ];
  final StringBuffer eb = StringBuffer();
  if (gakurenKeiken.isNotEmpty) {
    eb.write('${_narabe(w, gakurenKeiken)}は、学連選抜として正月駅伝を走った経験がある。');
  }
  if (daigakuKeiken.isNotEmpty) {
    eb.write('${_narabe(w, daigakuKeiken)}は、大学のチームで正月駅伝を走った経験を持つ。');
  }
  if (yonen.length >= 4) {
    eb.write('4年生${yonen.length}人にとっては、最後の正月駅伝になる。');
  } else if (yonen.isNotEmpty) {
    eb.write('4年生の${[for (final _GSenshu x in yonen) _mei(w, x)].join('、')}にとっては、最後の正月駅伝になる。');
  }
  w.danraku(eb.toString());

  // 本文: 区間配置(1区・山の区間・アンカー・エースの区間)
  w.koMidashi('区間配置');
  final StringBuffer hb = StringBuffer();
  final Set<int> kaita = {};
  final _GSenshu? ikku = _kukanNoSenshu(list, 0);
  if (ikku != null) {
    hb.write('1区は${_mei(w, ikku, daigaku: true)}。');
    kaita.add(0);
  }
  for (int kk = 1; kk < ks - 1; kk++) {
    final KukanTokuchou t = kukanTokuchou(k.gh, _race, kk);
    if (t != KukanTokuchou.yamaNobori && t != KukanTokuchou.yamaKudari) continue;
    final _GSenshu? x = _kukanNoSenshu(list, kk);
    if (x == null) continue;
    hb.write('${kukanYobikata(k.gh, _race, kk, ks)}は${_mei(w, x, daigaku: true)}が担う。');
    kaita.add(kk);
  }
  if (ace != null && !kaita.contains(ace.kukan)) {
    hb.write('エースの${_mei(w, ace)}は${ace.kukan + 1}区に入った。');
    kaita.add(ace.kukan);
  }
  final _GSenshu? anchor = _kukanNoSenshu(list, ks - 1);
  if (anchor != null && !kaita.contains(ks - 1)) {
    hb.write('アンカーの${ks}区は${_mei(w, anchor, daigaku: true)}。');
  }
  w.danraku(hb.toString());

  // 本文: 自分の大学から選ばれた選手(いれば)。いなければエースの意気込み
  if (jibun != null && my != null) {
    w.koMidashi('${daigakuMei(my)}から');
    final String yosen = _yosenMoji(k, jibun);
    w.danraku(
      '本戦出場を逃した${daigakuMei(my)}からは、${_mei(w, jibun)}が選ばれ、'
      '${kukanYobikata(k.gh, _race, jibun.kukan, ks)}を走る。'
      '${yosen.isEmpty ? '' : '$yosenだった。'}'
      '${kantoku ? '総監督にとっては、自分の大学の選手を、学連選抜の一員として送り出すことになる。' : ''}',
    );
    w.comment(
      senshuCommentJijitsu(
        w,
        CommentBamen.gakurenIkigomi,
        myouji(jibun.g.name),
        jijitsu: ['${daigakuMei(my)}のみんなの分まで走りたい'],
      ),
    );
  } else if (ace != null) {
    w.comment(
      senshuCommentJijitsu(
        w,
        CommentBamen.gakurenIkigomi,
        myouji(ace.g.name),
        jijitsu: ['${ace.shozoku}の代表として、恥ずかしくない走りをしたい'],
      ),
    );
  }

  // 表: 区間配置
  final List<List<String>> gyou = [
    for (final _GSenshu x in list)
      [
        '${x.kukan + 1}区',
        '${fullMei(x.g.name)}(${x.g.gakunen})',
        x.shozoku,
        _yosenKekka(x.g) == null ? '-' : '全体${juniMoji(_yosenKekka(x.g)!.juni)}',
        _mochiMoji(k, x, x.kukan) ?? '-',
      ],
  ];
  return _kansei(
    k,
    no,
    w,
    category: '学連選抜・展望',
    midashi: midashi,
    lead: lead.toString(),
    kekka: false,
    hyou: [
      KijiHyou('学連選抜の区間配置', ['区間', '選手', '所属', '予選会', '持ちタイム'], gyou),
    ],
  );
}

Kiji _tenbouMeikan(KijiKankyou k, List<_GSenshu> list) {
  const int no = 302;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int n = list.length;
  final int ks = k.kukansuu;
  final String midashi = w.erabu([
    '学連選抜$n人の選手名鑑　それぞれの大学の思いを胸に',
    '選手名鑑　学連選抜の$n人',
  ]);
  final String lead =
      '${k.taikaiMei}を走る学連選抜の$n人を、区間の順に紹介する。持ちタイムは、区間の距離に合った種目の自己ベスト。';
  for (final _GSenshu x in list) {
    final int kk = x.kukan;
    w.koMidashi('${kk + 1}区　${_mei(w, x)}・${x.shozoku}');
    final StringBuffer sb = StringBuffer();
    sb.write(
      '${kukanYobikata(k.gh, _race, kk, ks)}(${kmMoji(k.gh.kyori_taikai_kukangoto[_race][kk])})を任された。',
    );
    final String yosen = _yosenMoji(k, x);
    if (yosen.isNotEmpty) sb.write('$yosenの走りだった。');
    final int idx = kukanKihonShumoku(k.gh, _race, kk);
    final String? mochi = _mochiMoji(k, x, kk);
    final int? ban = _gakurenNaiBan(k, list, x, idx);
    if (mochi != null) {
      sb.write('${mochi.replaceFirst(kijiShumokuMei[idx], '${kijiShumokuMei[idx]}の持ちタイムは')}'
          '${ban == null ? '。' : 'で、学連選抜の中では${ban + 1}番目。'}');
    }
    final ({int daigaku, int gakuren, bool kyonenGakuren}) reki = _shougatsuReki(x.s);
    if (reki.kyonenGakuren) {
      sb.write('昨年も学連選抜で正月駅伝を走った。');
    } else if (reki.gakuren > 0) {
      sb.write('学連選抜で正月駅伝を走った経験がある。');
    }
    if (reki.daigaku > 0) sb.write('大学のチームで正月駅伝を走った経験も持つ。');
    if (x.g.gakunen == 4) {
      sb.write('4年生にとっては、最後の正月駅伝だ。');
    } else if (x.g.gakunen == 1) {
      sb.write('1年生ながら、学連選抜の一員に選ばれた。');
    }
    w.danraku(sb.toString());
    final SenshuData? s = x.s;
    if (s != null) w.danraku(shusshinShumiBun(k, s, w.r, myouji(s.name)));
    // 意気込み(因縁があれば、その事実を入れる)
    final String jijitsu = x.g.gakunen == 4
        ? '最後の正月駅伝。${x.shozoku}の仲間の分まで走りたい'
        : (reki.kyonenGakuren
              ? '去年も学連選抜で走った。あのときの経験を生かしたい'
              : (x.g.gakunen == 1
                    ? '1年生でこの舞台に立てるとは思っていなかった'
                    : '${x.shozoku}の代表として走る。恥ずかしい走りはできない'));
    w.comment(
      senshuCommentJijitsu(
        w,
        CommentBamen.gakurenIkigomi,
        myouji(x.g.name),
        jijitsu: [jijitsu],
      ),
    );
  }
  return _kansei(
    k,
    no,
    w,
    category: '学連選抜・選手名鑑',
    midashi: midashi,
    lead: lead,
    kekka: false,
  );
}

// ------------------------------------------------------------
// 2. 区間ごとの速報
// ------------------------------------------------------------

/// 学連選抜通信の区間ごとの速報(終わった区間の分。終わったばかりの区間が先頭。
/// 今年の学連選抜がいなければ空)
List<Kiji> gakurenSokuhouKiji(KijiKankyou k) {
  final List<_GSenshu> list = _gSenshuList(k);
  if (list.isEmpty) return [];
  final int ks = k.kukansuu;
  final int done = k.gh.nowracecalckukan < ks ? k.gh.nowracecalckukan : ks;
  if (done <= 0) return [];
  final UnivGakurenData? gu = _gakurenUniv();
  final List<Kiji> out = [];
  for (int kk = done - 1; kk >= 0; kk--) {
    final Kiji? kiji = _sokuhou(k, list, gu, kk, saishin: kk == done - 1);
    if (kiji != null) out.add(kiji);
  }
  return out;
}

/// 区間[kk]の速報([saishin] 読んだときの一番新しい区間か。目標との比べはそのときだけ書く)
Kiji? _sokuhou(
  KijiKankyou k,
  List<_GSenshu> list,
  UnivGakurenData? gu,
  int kk, {
  required bool saishin,
}) {
  final GakurenKukanKekka? r = gakurenKukanKekka(k.gh, kk);
  final _GSenshu? x = _kukanNoSenshu(list, kk);
  if (r == null || x == null) return null;
  final int no = 320 + kk;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int ks = k.kukansuu;
  final bool saigo = kk == ks - 1;
  final bool ouroOwari = ks >= 6 && kk == 4;
  final int j = r.kukanJuni;
  final int t = r.tuukaJuni;
  final int? mae = r.maeTuukaJuni;
  final int d = mae == null ? 0 : mae - t;
  final List<({UnivData u, double t})> jun = _daigakuJun(k, kk);
  final int n = jun.length;
  final bool kantoku = _kantokuChuu(k);
  final int mk = _mokuhyou(k);
  final String kukanMei = kukanYobikata(k.gh, _race, kk, ks);
  final String kyori = kmMoji(k.gh.kyori_taikai_kukangoto[_race][kk]);

  // 見出し
  final String hyouka = j == 0
      ? '区間1位相当の快走'
      : (d >= 3
            ? '$d校を抜く力走'
            : (j <= 4 ? '区間${juniMoji(j)}相当の好走' : '区間${juniMoji(j)}相当'));
  final String midashi =
      '【${kk + 1}区】${myouji(x.g.name)}(${x.shozoku})、$hyouka　'
      '${saigo ? '${juniMoji(t)}相当でゴール' : '${juniMoji(t)}相当で${kk + 2}区へ'}';

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write('$kukanMei($kyori)。');
  if (mae != null) lead.write('${juniMoji(mae)}相当でたすきを受けた');
  lead.write(
    '${_mei(w, x, daigaku: true)}は、区間${juniMoji(j)}相当(${jikanMoji(r.kukanTime)})で走り、'
    '${juniMoji(t)}相当で${saigo ? 'ゴールした' : 'たすきをつないだ'}。',
  );

  // 本文: 走り
  final StringBuffer sb = StringBuffer();
  final String yobi = _mei(w, x);
  final Senshu_Gakuren_Data g = x.g;
  if (kk == 0) {
    if (g.startchokugotobidasiflag == 1) {
      final bool seikou = g.startchokugotobidasiseikouflag == 1;
      final String mae2 = (kantoku && g.sijiflag == 1) ? '指示どおりスタート直後に飛び出し、' : 'スタート直後に自ら飛び出し、';
      sb.write('$yobiは$mae2${seikou ? '狙いどおりの展開に持ち込んだ。' : '後半は苦しい走りになった。'}');
    }
  } else if (kantoku && g.sijiflag == 1) {
    sb.write(
      g.sijiseikouflag == 1
          ? '前半から突っ込む指示に、$yobiはしっかり応えた。'
          : '前半から突っ込む指示だったが、$yobiは後半に苦しんだ。',
    );
  } else if (kantoku && g.sijiflag == 2) {
    sb.write(
      g.sijiseikouflag == 1
          ? '前半を抑える指示どおり、$yobiは後半に伸びた。'
          : '前半を抑える指示だったが、$yobiは思うように上げられなかった。',
    );
  } else {
    final int f = _mokuhyouFlag(gu, kk);
    if (f == 1) {
      sb.write('目標の順位相当を下回ってたすきを受けた$yobiは、前半から突っ込み、後半にその分が響いた。');
    } else if (f == -1) {
      sb.write('目標を上回る位置でたすきを受けた$yobiは、少し気持ちが緩んだか。');
    }
  }
  if (mae != null) {
    if (d >= 3) {
      sb.write('$d校を抜き去り、${juniMoji(mae)}相当から${juniMoji(t)}相当に浮上した。');
    } else if (d > 0) {
      sb.write('${juniMoji(mae)}相当から${juniMoji(t)}相当に順位を上げた。');
    } else if (d == 0) {
      sb.write('${juniMoji(t)}相当を守った。');
    } else {
      sb.write('${juniMoji(mae)}相当から${juniMoji(t)}相当に下げたが、最後までたすきを運んだ。');
    }
  }
  if (j == 0) {
    sb.write('区間1位相当の走りで、所属する${x.shozoku}に名声をもたらした。');
  }
  w.danraku(sb.toString());

  // 本文: 差(トップ・シード権の圏内にあたる10位相当・目標)
  final List<String> saList = [];
  if (n > 0 && t > 0) {
    saList.add('トップの${daigakuMei(jun[0].u)}とは${kinsaMoji(saByou(r.tuukaTime, jun[0].t))}');
  }
  // 目標がシード権の線と同じ10位相当なら、目標の文だけにする
  final bool mokuhyouKaku = saishin && mk >= 0 && mk < n && mk != t;
  if (n > _seedSuu && !(mokuhyouKaku && mk == _seedSuu - 1)) {
    final double line = jun[_seedSuu - 1].t;
    saList.add(
      t >= _seedSuu
          ? 'シード権の圏内にあたる${_seedSuu}位相当まで${kinsaMoji(saByou(r.tuukaTime, line))}'
          : 'シード権の圏内にあたる${_seedSuu}位相当以内を走っている',
    );
  }
  if (mokuhyouKaku) {
    final double line = jun[mk].t;
    final int yoyu = saByou(line, r.tuukaTime);
    saList.add(
      t < mk
          ? '目標の${juniMoji(mk)}相当より前で、${yoyu <= 0 ? 'わずかに先行している' : '${saMoji(yoyu)}の余裕がある'}'
          : '目標の${juniMoji(mk)}相当まで${kinsaMoji(saByou(r.tuukaTime, line))}',
    );
  }
  if (saList.isNotEmpty) w.danraku('${saList.join('、')}。');

  // 本文: 予選会からの歩みと4年生
  final StringBuffer ab = StringBuffer();
  final ({int juni, double time})? y = _yosenKekka(g);
  if (y != null && j <= 4) {
    ab.write('予選会では全体${juniMoji(y.juni)}だった$yobiが、本戦の舞台で区間${juniMoji(j)}相当の走りを見せた。');
  }
  if (g.gakunen == 4) ab.write('4年生にとって、これが最後の正月駅伝だった。');
  w.danraku(ab.toString());

  // 中継所での一言
  final bool kurushii = n >= 6 && j >= (n * 3) ~/ 4;
  final CommentBamen bamen = j == 0
      ? CommentBamen.kukanshou
      : (d >= 3 ? CommentBamen.oinuki : (kurushii ? CommentBamen.brake : CommentBamen.gakurenKekka));
  w.comment(
    senshuCommentJijitsu(
      w,
      bamen,
      myouji(g.name),
      jijitsu: [
        kurushii
            ? '区間${juniMoji(j)}相当。${x.shozoku}のみんなに申し訳ない'
            : '区間${juniMoji(j)}相当。${x.shozoku}のみんなに、いい報告ができる',
      ],
      kuyashii: kurushii,
    ),
  );

  // 本文: 次の走者(最終区はゴール)
  if (!saigo) {
    final _GSenshu? tsugi = _kukanNoSenshu(list, kk + 1);
    w.koMidashi(ouroOwari ? '往路を終えて' : '次は${kk + 2}区');
    final StringBuffer nb = StringBuffer();
    if (ouroOwari) nb.write('学連選抜は往路を${juniMoji(t)}相当で終えた。');
    if (tsugi != null) {
      final String tsugiMei = kukanYobikata(k.gh, _race, kk + 1, ks);
      nb.write(
        '${ouroOwari ? '復路の' : ''}$tsugiMei(${kmMoji(k.gh.kyori_taikai_kukangoto[_race][kk + 1])})は'
        '${_mei(w, tsugi, daigaku: true)}。',
      );
      final String? mochi = _mochiMoji(k, tsugi, kk + 1);
      if (mochi != null) nb.write('持ちタイムは$mochi。');
      final ({int juni, double time})? ty = _yosenKekka(tsugi.g);
      if (ty != null) nb.write('予選会は全体${juniMoji(ty.juni)}だった。');
    }
    w.danraku(nb.toString());
  } else {
    w.koMidashi('ゴール');
    final StringBuffer gb = StringBuffer();
    gb.write('学連選抜は、総合${juniMoji(t)}相当(${jikanMoji(r.tuukaTime)})でゴールした。');
    if (saishin && mk >= 0) {
      gb.write(t <= mk ? '目標の${juniMoji(mk)}相当を達成した。' : '目標の${juniMoji(mk)}相当には届かなかった。');
    }
    gb.write('詳しくは、結果号でお伝えする。');
    w.danraku(gb.toString());
  }

  // 表: ここまでの区間成績
  final List<List<String>> gyou = [];
  for (int i = 0; i <= kk; i++) {
    final GakurenKukanKekka? ri = gakurenKukanKekka(k.gh, i);
    if (ri == null) continue;
    gyou.add([
      '${i + 1}区',
      ri.senshu.name.isEmpty ? '-' : '${fullMei(ri.senshu.name)}(${ri.senshu.gakunen})',
      daigakuMeiMoji(ri.shozoku),
      '${juniMoji(ri.kukanJuni)}相当',
      '${juniMoji(ri.tuukaJuni)}相当',
    ]);
  }
  return _kansei(
    k,
    no,
    w,
    category: '学連選抜・速報',
    midashi: midashi,
    lead: lead.toString(),
    kekka: true,
    hyou: [
      KijiHyou('学連選抜の区間成績(${kk + 1}区まで)', ['区間', '選手', '所属', '区間', '通過'], gyou),
    ],
    haishin: '${k.gh.year}年${k.gh.month}月${k.gh.day}日 ${kk + 1}区終了時点',
    kisha: _kishaMei(k, 320),
  );
}

// ------------------------------------------------------------
// 3. 結果号
// ------------------------------------------------------------

/// 学連選抜通信の結果号(今年の学連選抜が最終区まで走っていなければ空)
List<Kiji> gakurenKekkaKiji(KijiKankyou k) {
  final List<_GSenshu> list = _gSenshuList(k);
  if (list.isEmpty) return [];
  final int ks = k.kukansuu;
  final List<GakurenKukanKekka?> kekka = [
    for (int kk = 0; kk < ks; kk++) gakurenKukanKekka(k.gh, kk),
  ];
  if (kekka.isEmpty || kekka.last == null) return [];
  final UnivGakurenData? gu = _gakurenUniv();
  return [_kekkaTop(k, list, kekka), _kekkaZenin(k, list, kekka, gu)];
}

/// 区間結果の表
KijiHyou _kekkaHyou(List<GakurenKukanKekka?> kekka) {
  final List<List<String>> gyou = [
    for (int kk = 0; kk < kekka.length; kk++)
      if (kekka[kk] != null)
        [
          '${kk + 1}区',
          kekka[kk]!.senshu.name.isEmpty
              ? '-'
              : '${fullMei(kekka[kk]!.senshu.name)}(${kekka[kk]!.senshu.gakunen})',
          daigakuMeiMoji(kekka[kk]!.shozoku),
          '${juniMoji(kekka[kk]!.kukanJuni)}相当',
          jikanMoji(kekka[kk]!.kukanTime),
          '${juniMoji(kekka[kk]!.tuukaJuni)}相当',
        ],
  ];
  return KijiHyou('学連選抜の区間成績', ['区間', '選手', '所属', '区間', 'タイム', '通過'], gyou);
}

Kiji _kekkaTop(KijiKankyou k, List<_GSenshu> list, List<GakurenKukanKekka?> kekka) {
  const int no = 311;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int ks = k.kukansuu;
  final GakurenKukanKekka saigo = kekka.last!;
  final int sougou = saigo.tuukaJuni;
  final UnivData? my = k.jibunUniv;
  final String myMei = my == null ? '' : daigakuMei(my);
  final bool kantoku = _kantokuChuu(k) && my != null;
  final int mk = _mokuhyou(k);
  final bool tassei = sougou <= mk;
  final bool yuushouKantoku = my != null && gakurenYuushouKantoku(k.gh, k.kantoku, my);
  // 区間1位相当の区間
  final List<int> ichii = [
    for (int kk = 0; kk < ks; kk++)
      if (kekka[kk] != null && kekka[kk]!.kukanJuni == 0) kk,
  ];
  // 区間順位相当が一番良かった区間と、一番順位相当を上げた区間
  int bestKk = -1;
  int ueKk = -1;
  int ueKazu = 0;
  for (int kk = 0; kk < ks; kk++) {
    final GakurenKukanKekka? r = kekka[kk];
    if (r == null) continue;
    if (bestKk < 0 || r.kukanJuni < kekka[bestKk]!.kukanJuni) bestKk = kk;
    final int? mae = r.maeTuukaJuni;
    if (mae != null && mae - r.tuukaJuni > ueKazu) {
      ueKazu = mae - r.tuukaJuni;
      ueKk = kk;
    }
  }
  // 往路と復路の順位相当(正月駅伝で6区間以上のとき)
  int? ouro;
  int? fukuro;
  if (ks >= 6 && kekka[4] != null) {
    ouro = kekka[4]!.tuukaJuni;
    final double gFukuro = saigo.tuukaTime - kekka[4]!.tuukaTime;
    int mae = 0;
    for (final UnivData u in k.univ) {
      if (!k.shutsujou(u) || u.time_taikai_total.length < ks) continue;
      final double a = u.time_taikai_total[4];
      final double b = u.time_taikai_total[ks - 1];
      if (a <= 0 || b <= 0 || a >= TEISUU.DEFAULTTIME || b >= TEISUU.DEFAULTTIME) continue;
      if (b - a < gFukuro) mae++;
    }
    fukuro = mae;
  }
  final _GSenshu? jibun = _jibunNoSenshu(k, list);

  // 見出し
  String midashi;
  if (yuushouKantoku) {
    midashi = '学連選抜が1位相当！　$myMei総監督の采配実る';
  } else {
    midashi = '学連選抜は${juniMoji(sougou)}相当';
    if (tassei) midashi += '　目標の${juniMoji(mk)}相当を達成';
    if (ichii.isNotEmpty) {
      final GakurenKukanKekka r = kekka[ichii.first]!;
      midashi += '　${ichii.first + 1}区${myouji(r.senshu.name)}が区間1位相当';
    }
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}にオープン参加した学連選抜は、${jikanMoji(saigo.tuukaTime)}で総合${juniMoji(sougou)}相当だった。',
  );
  lead.write(tassei ? '目標の${juniMoji(mk)}相当を達成した。' : '目標の${juniMoji(mk)}相当には届かなかった。');
  if (sougou < _seedSuu) lead.write('大学の中に入れば、シード権の圏内にあたる。');
  if (kantoku) {
    lead.write('今回は$myMeiの総監督が指揮を執った。');
    if (yuushouKantoku) {
      lead.write('目標に掲げた1位相当を達成し、監督の手腕が評価されて、$myMeiの名声も大きく高まった。');
    }
  }

  // 本文: レースの流れ
  w.koMidashi('レースの流れ');
  final StringBuffer rb = StringBuffer();
  if (ouro != null && fukuro != null) {
    rb.write('往路は${juniMoji(ouro)}相当、復路は${juniMoji(fukuro)}相当だった。');
  }
  final GakurenKukanKekka? r1 = kekka[0];
  final _GSenshu? x1 = _kukanNoSenshu(list, 0);
  if (r1 != null && x1 != null) {
    rb.write('1区の${_mei(w, x1, daigaku: true)}は区間${juniMoji(r1.kukanJuni)}相当で滑り出した。');
  }
  if (ueKk > 0 && ueKazu >= 2) {
    final _GSenshu? xu = _kukanNoSenshu(list, ueKk);
    if (xu != null) {
      rb.write('${ueKk + 1}区の${_mei(w, xu, daigaku: true)}は$ueKazu校を抜き、チームの順位相当を押し上げた。');
    }
  }
  w.danraku(rb.toString());
  // 区間1位相当(その選手の大学に名声が入る)
  if (ichii.isNotEmpty) {
    w.koMidashi('区間1位相当');
    final List<String> l = [];
    for (final int kk in ichii) {
      final _GSenshu? x = _kukanNoSenshu(list, kk);
      if (x == null) continue;
      l.add('${kk + 1}区の${_mei(w, x, daigaku: true)}');
    }
    w.danraku('${l.join('、')}が区間1位相当の走りを見せ、所属する大学に名声をもたらした。');
  }
  // 本文: 自分の大学から選ばれた選手
  if (jibun != null && my != null && kekka[jibun.kukan] != null) {
    final GakurenKukanKekka r = kekka[jibun.kukan]!;
    w.koMidashi('${daigakuMei(my)}から');
    w.danraku(
      '${daigakuMei(my)}から選ばれた${_mei(w, jibun)}は、${jibun.kukan + 1}区で区間${juniMoji(r.kukanJuni)}相当だった。',
    );
    w.comment(
      senshuCommentJijitsu(
        w,
        r.kukanJuni == 0 ? CommentBamen.kukanshou : CommentBamen.gakurenKekka,
        myouji(jibun.g.name),
        jijitsu: ['来年は${daigakuMei(my)}のチームで、この舞台に戻ってきたい'],
      ),
    );
  }
  // 一番良かった選手のコメント
  if (bestKk >= 0 && (jibun == null || jibun.kukan != bestKk)) {
    final GakurenKukanKekka r = kekka[bestKk]!;
    final _GSenshu? xb = _kukanNoSenshu(list, bestKk);
    if (xb != null) {
      w.comment(
        senshuCommentJijitsu(
          w,
          r.kukanJuni == 0 ? CommentBamen.kukanshou : CommentBamen.gakurenKekka,
          myouji(xb.g.name),
          jijitsu: ['区間${juniMoji(r.kukanJuni)}相当。${xb.shozoku}のみんなに、いい報告ができる'],
        ),
      );
    }
  }
  w.danraku(
    '学連選抜は、予選会で本戦への出場を逃した大学の選手で編成されるチームで、順位はつかない。'
    'それぞれの大学に戻れば、来年は予選会を突破して、大学のチームでこの舞台に戻ることが目標になる。',
  );
  return _kansei(
    k,
    no,
    w,
    category: '学連選抜・結果',
    midashi: midashi,
    lead: lead.toString(),
    kekka: true,
    hyou: [_kekkaHyou(kekka)],
  );
}

Kiji _kekkaZenin(
  KijiKankyou k,
  List<_GSenshu> list,
  List<GakurenKukanKekka?> kekka,
  UnivGakurenData? gu,
) {
  const int no = 312;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int ks = k.kukansuu;
  final int n = _daigakuJun(k, ks - 1).length;
  final bool kantoku = _kantokuChuu(k);
  final int sougou = kekka.last!.tuukaJuni;
  final String midashi = w.erabu([
    '学連選抜、${list.length}人の走りを振り返る',
    'たすきをつないだ${list.length}人　学連選抜の全区間',
  ]);
  final String lead = '総合${juniMoji(sougou)}相当だった学連選抜の${list.length}人の走りを、区間の順に振り返る。';
  for (int kk = 0; kk < ks; kk++) {
    final GakurenKukanKekka? r = kekka[kk];
    final _GSenshu? x = _kukanNoSenshu(list, kk);
    if (r == null || x == null) continue;
    final Senshu_Gakuren_Data g = x.g;
    final bool saigo = kk == ks - 1;
    w.koMidashi('${kk + 1}区　${_mei(w, x)}・${x.shozoku}');
    final String yobi = myouji(g.name);
    final StringBuffer sb = StringBuffer();
    sb.write('区間${juniMoji(r.kukanJuni)}相当、${jikanMoji(r.kukanTime)}。');
    final int? mae = r.maeTuukaJuni;
    if (mae == null) {
      sb.write('${juniMoji(r.tuukaJuni)}相当でたすきを渡した。');
    } else if (mae > r.tuukaJuni) {
      sb.write('${juniMoji(mae)}相当から${juniMoji(r.tuukaJuni)}相当へ、${mae - r.tuukaJuni}つ順位相当を上げた。');
    } else if (mae == r.tuukaJuni) {
      sb.write('${juniMoji(r.tuukaJuni)}相当を守って${saigo ? 'ゴールした' : 'つないだ'}。');
    } else {
      sb.write('${juniMoji(mae)}相当から${juniMoji(r.tuukaJuni)}相当に下げたが、最後までたすきを運んだ。');
    }
    // 指示と、目標を下回った・上回ったときの走り
    if (kk == 0) {
      if (g.startchokugotobidasiflag == 1) {
        final bool seikou = g.startchokugotobidasiseikouflag == 1;
        sb.write(
          (kantoku && g.sijiflag == 1 ? '指示どおりスタート直後に飛び出し、' : 'スタート直後に自ら飛び出し、') +
              (seikou ? '狙いどおりの展開に持ち込んだ。' : '後半は苦しんだ。'),
        );
      }
    } else if (kantoku && (g.sijiflag == 1 || g.sijiflag == 2)) {
      final bool seikou = g.sijiseikouflag == 1;
      sb.write(
        g.sijiflag == 1
            ? (seikou ? '前半から突っ込む指示に応えた。' : '前半から突っ込む指示だったが、後半に苦しんだ。')
            : (seikou ? '前半を抑える指示どおり、後半に伸びた。' : '前半を抑える指示だったが、思うように上げられなかった。'),
      );
    } else {
      final int f = _mokuhyouFlag(gu, kk);
      if (f == 1) sb.write('目標の順位相当を下回ってたすきを受け、前半から突っ込んだ。');
      if (f == -1) sb.write('目標を上回る位置でたすきを受け、少し気持ちが緩んだか。');
    }
    final ({int juni, double time})? y = _yosenKekka(g);
    if (y != null) sb.write('予選会では全体${juniMoji(y.juni)}だった。');
    if (r.kukanJuni == 0) sb.write('区間1位相当で、${x.shozoku}に名声をもたらした。');
    if (g.gakunen == 4) sb.write('4年生として、最後の正月駅伝だった。');
    w.danraku(sb.toString());
    // コメント
    final int? m = r.maeTuukaJuni;
    final int d = m == null ? 0 : m - r.tuukaJuni;
    final bool kurushii = n >= 6 && r.kukanJuni >= (n * 3) ~/ 4;
    final CommentBamen bamen = r.kukanJuni == 0
        ? CommentBamen.kukanshou
        : (d >= 3 ? CommentBamen.oinuki : (kurushii ? CommentBamen.brake : CommentBamen.gakurenKekka));
    w.comment(
      senshuCommentJijitsu(
        w,
        bamen,
        yobi,
        jijitsu: [
          kurushii
              ? '区間${juniMoji(r.kukanJuni)}相当。${x.shozoku}のみんなに申し訳ない'
              : '区間${juniMoji(r.kukanJuni)}相当。${x.shozoku}の仲間に、いい報告ができる',
        ],
        kuyashii: kurushii,
      ),
    );
  }
  return _kansei(
    k,
    no,
    w,
    category: '学連選抜・全員の走り',
    midashi: midashi,
    lead: lead,
    kekka: true,
  );
}
