import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart'; // 大会の名前(courseRaceTitle)
import 'package:ekiden/kansuu/meisei_rireki.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_comment.dart';
import 'package:ekiden/kansuu/kiji/kiji_gakunai.dart' show gakunaiSiteMeiJibun, gakunaiKishaMei;

// ------------------------------------------------------------
// 年間表彰(3月25日の最新画面から。1.9.4)
// ・箱庭スポーツの「年間表彰」: 年間最優秀選手(MVP)・新人賞・年間最優秀チーム・躍進賞・ベストパフォーマンス賞
// ・学内メディアの「学内表彰」: 学内MVP・学内新人賞・功労賞(4年生)・伸び盛り賞
// ・対象は三大駅伝(10月・11月・正月)と対校戦の3種目(カスタム駅伝・駅伝予選・記録会は除く)
// ・点: 区間賞10・区間2位7・3位5・4〜5位3・6〜8位1(正月駅伝の区間賞は+3)。対校戦は1位8・2位6・3位5・4〜8位3。
//   同じ点なら区間賞の数、次に1万mの持ちタイムで決める
// ・読めるのは3月25日だけ(卒業で4年生のデータが変わるため。卒業生特集と同じ)。
//   大会に関係ない記事なので、正月駅伝を記事にする大会として読む(KijiKankyou.yomuRace(2))
// ・隠れた逸材や成長タイプには触れない(入学時の記録からの伸びは、因縁と同じく書いてよい)
// ------------------------------------------------------------

/// 三大駅伝の大会の番号
const List<int> _sandai = [0, 1, 2];

/// 対校戦の種目の番号(5000m・1万m・ハーフ)
const List<int> _taikousen = [6, 7, 8];

/// 今季の成績の点(選手1人分)
class _Seiseki {
  final SenshuData s;
  int ten = 0;

  /// 三大駅伝の出走数と区間賞の数
  int ekiden = 0;
  int kukanshou = 0;

  /// 対校戦の8位以内の数
  int nyuushou = 0;

  /// 点になった成績の文(「10月駅伝3区で区間賞」など)
  final List<String> naiyou = [];

  _Seiseki(this.s);
}

/// 区間順位の点([race] 正月駅伝の区間賞は加点)
int _kukanTen(int j, int race) {
  int t = j == 0 ? 10 : (j == 1 ? 7 : (j == 2 ? 5 : (j <= 4 ? 3 : (j <= 7 ? 1 : 0))));
  if (race == 2 && j == 0) t += 3;
  return t;
}

/// 対校戦の順位の点
int _taikousenTen(int j) => j == 0 ? 8 : (j == 1 ? 6 : (j == 2 ? 5 : (j <= 7 ? 3 : 0)));

/// 選手[s]の、大会[r]の今の学年の区間エントリーと順位
({int entry, int juni}) _konki(SenshuData s, int r) {
  final int g = s.gakunen - 1;
  int entry = -1;
  int juni = TEISUU.DEFAULTJUNI;
  if (s.entrykukan_race.length > r && g >= 0 && g < s.entrykukan_race[r].length) {
    entry = s.entrykukan_race[r][g];
  }
  if (s.kukanjuni_race.length > r && g >= 0 && g < s.kukanjuni_race[r].length) {
    juni = s.kukanjuni_race[r][g];
  }
  return (entry: entry, juni: juni);
}

_Seiseki _seiseki(SenshuData s) {
  final _Seiseki x = _Seiseki(s);
  for (final int r in _sandai) {
    final ({int entry, int juni}) a = _konki(s, r);
    if (a.entry < 0 || !shutsujouJuni(a.juni)) continue;
    // 学連選抜(オープン参加)で走った正月駅伝は、出走数にも点にも入れない(1.9.5)
    if (gakurenShussouJuni(r, a.juni)) continue;
    x.ekiden++;
    if (a.juni == 0) x.kukanshou++;
    x.ten += _kukanTen(a.juni, r);
    if (a.juni <= 7) {
      x.naiyou.add('${courseRaceTitle(r)}${a.entry + 1}区で${a.juni == 0 ? '区間賞' : '区間${juniMoji(a.juni)}'}');
    }
  }
  for (final int r in _taikousen) {
    final ({int entry, int juni}) a = _konki(s, r);
    if (!shutsujouJuni(a.juni)) continue;
    if (a.juni <= 7) x.nyuushou++;
    x.ten += _taikousenTen(a.juni);
    if (a.juni <= 7) x.naiyou.add('対校戦の${kijiShumokuMei[r - 6]}で${juniMoji(a.juni)}');
  }
  return x;
}

/// 点の高い順(同じ点なら区間賞の数、次に1万mの持ちタイム)
int _seisekiHikaku(KijiKankyou k, _Seiseki a, _Seiseki b) {
  if (a.ten != b.ten) return b.ten.compareTo(a.ten);
  if (a.kukanshou != b.kukanshou) return b.kukanshou.compareTo(a.kukanshou);
  return k.jikoBest(a.s, 1).compareTo(k.jikoBest(b.s, 1));
}

/// 成績の文(「10月駅伝3区で区間賞、正月駅伝2区で区間2位、対校戦の1万mで3位」)
String _naiyouMoji(_Seiseki x) => x.naiyou.isEmpty ? '' : x.naiyou.join('、');

/// 入学時の5000mからの伸び(秒。留学生や、記録がなければnull)
int? _nyuugakuNobi(KijiKankyou k, SenshuData s) {
  if (s.hirou == 1) return null;
  final double ny = s.kiroku_nyuugakuji_5000;
  final double best = k.jikoBest(s, 0);
  if (ny <= 0 || ny >= TEISUU.DEFAULTTIME || best >= TEISUU.DEFAULTTIME) return null;
  final int sa = saByou(ny, best);
  return sa > 0 ? sa : null;
}

/// 今年度(4月〜3月)に自己ベストを更新した種目(5000m・1万m・ハーフ)
List<int> _konkiBestKoushin(KijiKankyou k, SenshuData s) {
  final List<int> list = [];
  for (final int idx in const [0, 1, 2]) {
    if (s.year_bestkiroku.length <= idx || s.month_bestkiroku.length <= idx) continue;
    if (k.jikoBest(s, idx) >= TEISUU.DEFAULTTIME) continue;
    final int y = s.year_bestkiroku[idx];
    final int m = s.month_bestkiroku[idx];
    final bool konki = (y == k.gh.year && m <= 3) || (y == k.gh.year - 1 && m >= 4);
    if (konki) list.add(idx);
  }
  return list;
}

/// 選手の呼び方(大学名つき)
String _daigakuTsuki(KijiKankyou k, KijiKakite w, SenshuData s) {
  final String d = (s.univid >= 0 && s.univid < k.univ.length) ? '${daigakuMei(k.univ[s.univid])}・' : '';
  return '$d${w.senshu(s)}';
}

/// 年度の文(「2026年度」。1〜3月なので、前の年の4月からの年度)
String _nendoMoji(KijiKankyou k) => '${k.gh.month <= 3 ? k.gh.year - 1 : k.gh.year}年度';

// ------------------------------------------------------------
// 箱庭スポーツの年間表彰
// ------------------------------------------------------------

List<Kiji> nenkanHyoushouKiji(KijiKankyou k) {
  const int no = 151;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, no));
  final KishaKata kata = k.kishaKata(no);
  final String nendo = _nendoMoji(k);
  final UnivData? jibun = k.jibunUniv;
  bool jibunAri = false;

  // 全選手の今季の成績
  final List<_Seiseki> zen = [
    for (final SenshuData s in k.senshu)
      if (s.univid >= 0 && s.univid < k.univ.length && s.gakunen >= 1 && s.gakunen <= 4) _seiseki(s),
  ];
  zen.sort((a, b) => _seisekiHikaku(k, a, b));
  final List<_Seiseki> tenAri = [
    for (final _Seiseki x in zen)
      if (x.ten > 0) x,
  ];
  if (tenAri.isEmpty) return [];

  // 年間最優秀選手
  final _Seiseki mvp = tenAri.first;
  // 新人賞(1年生で点が最高。誰も点がなければ、入学時の記録からの伸びが一番大きい1年生)
  _Seiseki? shinjin;
  for (final _Seiseki x in tenAri) {
    if (x.s.gakunen == 1) {
      shinjin = x;
      break;
    }
  }
  int? shinjinNobi;
  if (shinjin == null) {
    int saidai = 0;
    for (final _Seiseki x in zen) {
      if (x.s.gakunen != 1) continue;
      final int? nobi = _nyuugakuNobi(k, x.s);
      if (nobi != null && nobi > saidai) {
        saidai = nobi;
        shinjin = x;
      }
    }
    if (shinjin != null) shinjinNobi = saidai;
  }
  // 年間最優秀チーム(今年度の名声の獲得が最多。同じなら正月駅伝の順位)
  UnivData? bestTeam;
  for (final UnivData u in k.univ) {
    if (u.meisei_yeargoto.isEmpty) continue;
    if (bestTeam == null ||
        u.meisei_yeargoto[0] > bestTeam.meisei_yeargoto[0] ||
        (u.meisei_yeargoto[0] == bestTeam.meisei_yeargoto[0] && juniRace(u, 2, 0) < juniRace(bestTeam, 2, 0))) {
      bestTeam = u;
    }
  }
  // 躍進賞(正月駅伝の順位を昨年から一番上げた大学。昨年不出場なら、出場校数を昨年の順位とみなす)
  int shutsujouSuu = 0;
  for (final UnivData u in k.univ) {
    if (shutsujouJuni(juniRace(u, 2, 0))) shutsujouSuu++;
  }
  UnivData? yakushin;
  int yakushinAge = 0;
  bool yakushinYosenKara = false;
  for (final UnivData u in k.univ) {
    final int j0 = juniRace(u, 2, 0);
    if (!shutsujouJuni(j0)) continue;
    final int j1 = juniRace(u, 2, 1);
    final bool kyonenNashi = !shutsujouJuni(j1);
    final int age = (kyonenNashi ? shutsujouSuu : j1) - j0;
    if (age > yakushinAge || (age == yakushinAge && yakushin != null && j0 < juniRace(yakushin, 2, 0))) {
      yakushinAge = age;
      yakushin = u;
      yakushinYosenKara = kyonenNashi;
    }
  }
  if (yakushinAge < 2) yakushin = null;
  // ベストパフォーマンス賞(今季の区間賞の中で、2位との差が距離あたりで一番大きかった走り)
  SenshuData? bestRun;
  int bestRace = -1;
  int bestKukan = -1;
  int bestSa = 0;
  double bestTime = 0;
  double bestTen = -1;
  for (final int r in _sandai) {
    if (k.gh.kukansuu_taikaigoto.length <= r || k.gh.kyori_taikai_kukangoto.length <= r) continue;
    final int ks = k.gh.kukansuu_taikaigoto[r];
    for (int kk = 0; kk < ks; kk++) {
      final List<SenshuData> hashitta = [];
      for (final SenshuData s in k.senshu) {
        if (s.gakunen < 1 || s.gakunen > 4) continue;
        final ({int entry, int juni}) a = _konki(s, r);
        if (a.entry != kk || !shutsujouJuni(a.juni)) continue;
        final int g = s.gakunen - 1;
        if (s.kukantime_race.length <= r || s.kukantime_race[r].length <= g) continue;
        final double t = s.kukantime_race[r][g];
        if (t <= 0 || t >= TEISUU.DEFAULTTIME) continue;
        hashitta.add(s);
      }
      if (hashitta.length < 2) continue;
      hashitta.sort((a, b) => a.kukantime_race[r][a.gakunen - 1].compareTo(b.kukantime_race[r][b.gakunen - 1]));
      final double t1 = hashitta[0].kukantime_race[r][hashitta[0].gakunen - 1];
      final double t2 = hashitta[1].kukantime_race[r][hashitta[1].gakunen - 1];
      final int sa = saByou(t2, t1);
      if (k.gh.kyori_taikai_kukangoto[r].length <= kk) continue;
      final double km = k.gh.kyori_taikai_kukangoto[r][kk] / 1000.0;
      if (km <= 0) continue;
      final double ten = sa / km;
      if (ten > bestTen) {
        bestTen = ten;
        bestRun = hashitta[0];
        bestRace = r;
        bestKukan = kk;
        bestSa = sa;
        bestTime = t1;
      }
    }
  }

  // 見出し・リード
  final String mvpMei = _daigakuTsuki(k, w, mvp.s);
  final String midashi = w.erabu([
    '$nendo 年間表彰　最優秀選手は$mvpMei',
    '本紙が選ぶ$nendoの年間表彰　MVPに$mvpMei',
  ]);
  final StringBuffer lead = StringBuffer();
  lead.write('本紙は、$nendoの大学駅伝・陸上長距離の年間表彰を発表した。');
  lead.write('対象は三大駅伝(${_sandai.map(courseRaceTitle).join('・')})と対校戦の3種目で、区間順位と種目の順位を点にして選んだ。');
  lead.write('年間最優秀選手には、${_naiyouMoji(mvp)}の$mvpMei(${mvp.s.gakunen}年)を選んだ。');

  // 年間最優秀選手
  w.koMidashi('年間最優秀選手　${w.senshu(mvp.s)}');
  final StringBuffer mb = StringBuffer();
  final UnivData mvpU = k.univ[mvp.s.univid];
  mb.write('${w.senshu(mvp.s)}は${daigakuMei(mvpU)}の${mvp.s.gakunen}年生。');
  mb.write('今季は三大駅伝を${mvp.ekiden}度走り${mvp.kukanshou > 0 ? '、区間賞${mvp.kukanshou}度' : ''}。');
  if (mvp.nyuushou > 0) mb.write('対校戦でも${mvp.nyuushou}種目で8位以内に入った。');
  if (_naiyouMoji(mvp).isNotEmpty) mb.write('${_naiyouMoji(mvp)}と、1年を通して安定して上位を走った。');
  final int? mvpNobi = _nyuugakuNobi(k, mvp.s);
  if (mvpNobi != null && mvp.s.gakunen >= 2) {
    mb.write('入学時の5000mは${jikanMoji(mvp.s.kiroku_nyuugakuji_5000)}。そこから${saMoji(mvpNobi)}縮めて、ここまで来た。');
  }
  if (mvp.s.gakunen == 4) mb.write('4年生にとっては、最後の1年での受賞となった。');
  if (tenAri.length >= 2) {
    final _Seiseki ji = tenAri[1];
    mb.write('次点は${_daigakuTsuki(k, w, ji.s)}(${ji.s.gakunen}年)${_naiyouMoji(ji).isNotEmpty ? '(${_naiyouMoji(ji)})' : ''}');
    if (tenAri.length >= 3) {
      final _Seiseki san = tenAri[2];
      mb.write('、3位は${_daigakuTsuki(k, w, san.s)}(${san.s.gakunen}年)');
    }
    mb.write('だった。');
  }
  w.danraku(mb.toString());
  w.comment(
    senshuCommentJijitsu(
      w,
      CommentBamen.hyoushou,
      myouji(mvp.s.name),
      jijitsu: [
        if (mvp.kukanshou >= 2) '区間賞を${mvp.kukanshou}度取れたのは、仲間がいい位置でつないでくれたから',
        if (mvp.s.gakunen == 4) '最後の年に選んでもらえて、4年間が報われた気がする',
        if (mvpNobi != null && mvp.s.gakunen >= 2) '入学したころの自分には、想像もできなかった賞',
      ],
    ),
  );
  if (jibun != null && mvpU.id == jibun.id) jibunAri = true;

  // 新人賞
  if (shinjin != null) {
    final _Seiseki sj = shinjin;
    w.koMidashi('新人賞　${w.senshu(sj.s)}');
    final StringBuffer sb = StringBuffer();
    sb.write('新人賞は${_daigakuTsuki(k, w, sj.s)}。');
    if (sj.ten > 0) {
      sb.write('1年目から${_naiyouMoji(sj)}と、上級生に交じって結果を残した。');
    } else if (shinjinNobi != null) {
      sb.write('1年目のレースでは点に届かなかったが、入学時の5000m${jikanMoji(sj.s.kiroku_nyuugakuji_5000)}から${saMoji(shinjinNobi)}縮め、1年生で一番の伸びを見せた。');
    }
    final String? ken = k.shusshin(sj.s);
    if (ken != null) sb.write('$ken出身。');
    w.danraku(sb.toString());
    w.comment(senshuComment(w, CommentBamen.shinjinshou, myouji(sj.s.name)));
    if (jibun != null && sj.s.univid == jibun.id) jibunAri = true;
  }

  // 年間最優秀チーム
  if (bestTeam != null) {
    final UnivData bt = bestTeam;
    w.koMidashi('年間最優秀チーム　${daigakuMei(bt)}');
    final StringBuffer tb = StringBuffer();
    tb.write('年間最優秀チームは、今年度の名声の獲得が全大学で最も多かった${daigakuMei(bt)}。');
    final List<String> juni = [
      for (final int r in _sandai)
        if (shutsujouJuni(juniRace(bt, r, 0))) '${courseRaceTitle(r)}${juniMoji(juniRace(bt, r, 0))}',
    ];
    if (shutsujouJuni(juniRace(bt, 9, 0))) juni.add('対校戦総合${juniMoji(juniRace(bt, 9, 0))}');
    if (juni.isNotEmpty) tb.write('今季は${juni.join('、')}。');
    final SandaiEkiden? sandaiBt = SandaiEkiden.tsukuru(k, kekka: true);
    if (sandaiBt != null && sandaiBt.sankan(bt, 0)) tb.write('三大駅伝をすべて制する三冠の季だった。');
    // 名声の履歴から、大きかった出来事を2つまで
    final List<MeiseiRirekiGyou> rireki = meiseiRirekiYomu(0, bt.id)..sort((a, b) => b.ryou.compareTo(a.ryou));
    final List<String> dekigoto = [
      for (final MeiseiRirekiGyou g in rireki.take(2))
        if (g.ryou > 0) g.naiyou,
    ];
    if (dekigoto.isNotEmpty) tb.write('名声を大きく押し上げたのは、${dekigoto.join('と')}だった。');
    w.danraku(tb.toString());
    if (jibun != null && bt.id == jibun.id) {
      jibunAri = true;
      w.danraku('監督にとっては、1年間の采配がそのまま評価された形だ。');
    } else {
      final String kc = kantokuComment(w, KantokuBamen.nenkanBest, bt.id);
      if (kc.isNotEmpty) w.comment(kc);
    }
  }

  // 躍進賞
  if (yakushin != null) {
    final UnivData yk = yakushin;
    final int j0 = juniRace(yk, 2, 0);
    w.koMidashi('躍進賞　${daigakuMei(yk)}');
    w.danraku(
      yakushinYosenKara
          ? '躍進賞は${daigakuMei(yk)}。昨年は正月駅伝に出場できなかったが、予選会を勝ち上がり、今年は${juniMoji(j0)}でゴールした。'
          : '躍進賞は${daigakuMei(yk)}。正月駅伝の順位を昨年の${juniMoji(juniRace(yk, 2, 1))}から${juniMoji(j0)}へ、$yakushinAgeつ上げた。',
    );
    if (jibun != null && yk.id == jibun.id) jibunAri = true;
  }

  // ベストパフォーマンス賞
  if (bestRun != null && bestRace >= 0) {
    final SenshuData br = bestRun;
    w.koMidashi('ベストパフォーマンス賞　${w.senshu(br)}');
    w.danraku(
      'ベストパフォーマンス賞は、${courseRaceTitle(bestRace)}${bestKukan + 1}区の${_daigakuTsuki(k, w, br)}(${br.gakunen}年)。'
      '${jikanMoji(bestTime)}で区間賞、2位に${kinsaMoji(bestSa)}をつけた。今季の区間賞の中で、距離あたりの差が最も大きい走りだった。',
    );
    if (br.id != mvp.s.id) {
      w.comment(senshuComment(w, CommentBamen.hyoushou, myouji(br.name)));
    }
    if (jibun != null && br.univid == jibun.id) jibunAri = true;
  }

  // 本紙の目(今季の総括)
  final SandaiEkiden? sandai = SandaiEkiden.tsukuru(k, kekka: true);
  final List<UnivData?> yuushou = [
    for (final int r in _sandai) sandai?.yuushou(r, 0),
  ];
  final bool sankan = yuushou.every((u) => u != null && u.id == yuushou[0]!.id);
  final Set<int> yuushouId = {
    for (final UnivData? u in yuushou)
      if (u != null) u.id,
  };
  final String yuushouMoji = sankan && yuushou[0] != null
      ? '三大駅伝は${daigakuMei(yuushou[0]!)}が三冠'
      : (yuushouId.isEmpty ? '三大駅伝' : '三大駅伝の優勝校は${yuushouId.length}校に分かれ');
  switch (kata) {
    case KishaKata.suuji:
      w.kishaNoMe(
        '$yuushouMoji。年間最優秀選手の${myouji(mvp.s.name)}は${mvp.ten}点で、次点とは${tenAri.length >= 2 ? '${mvp.ten - tenAri[1].ten}点差' : '大差'}だった。数字は、1年間の積み重ねを正直に映す。',
        midashi: '本紙の目',
      );
    case KishaKata.joukei:
      w.kishaNoMe(
        '$yuushouMoji。表彰の名前の後ろには、たすきを渡した仲間と、走れなかった仲間の1年がある。春からまた、新しい物語が始まる。',
        midashi: '本紙の目',
      );
    case KishaKata.karakuchi:
      w.kishaNoMe(
        '$yuushouMoji。賞を取った選手より、取れなかった大学の監督に問いたい。この1年で、何を積み上げたのか。来季の答えを待ちたい。',
        midashi: '本紙の目',
      );
  }

  // 表
  final List<List<String>> gyou = [];
  for (int i = 0; i < tenAri.length && i < 5; i++) {
    final _Seiseki x = tenAri[i];
    gyou.add([
      juniMoji(i),
      '${fullMei(x.s.name)}(${x.s.gakunen})',
      daigakuMei(k.univ[x.s.univid]),
      '${x.ten}',
      '${x.kukanshou}',
      '${x.nyuushou}',
    ]);
  }
  final List<List<String>> ichiran = [
    ['年間最優秀選手', '${fullMei(mvp.s.name)}(${daigakuMei(mvpU)})'],
  ];
  if (shinjin != null) ichiran.add(['新人賞', '${fullMei(shinjin.s.name)}(${daigakuMei(k.univ[shinjin.s.univid])})']);
  if (bestTeam != null) ichiran.add(['年間最優秀チーム', daigakuMei(bestTeam)]);
  if (yakushin != null) ichiran.add(['躍進賞', daigakuMei(yakushin)]);
  if (bestRun != null) ichiran.add(['ベストパフォーマンス賞', '${fullMei(bestRun.name)}(${daigakuMei(k.univ[bestRun.univid])})']);
  return [
    Kiji(
      category: '年間表彰',
      midashi: midashi,
      lead: lead.toString(),
      honbun: w.honbun,
      hyou: [
        KijiHyou('$nendoの年間表彰', ['賞', '受賞'], ichiran),
        KijiHyou('年間最優秀選手の争い(上位5人)', ['順位', '選手', '大学', '点', '区間賞', '対校戦入賞'], gyou),
        if (sandai != null) sandai.konkiHyou(),
      ],
      haishin: k.haishinMei(no, asa: true),
      kisha: k.kishaMei(no),
      jibun: jibunAri,
      kekka: true,
    ),
  ];
}

// ------------------------------------------------------------
// 学内メディアの学内表彰
// ------------------------------------------------------------

/// 学内MVPへの、部員のひと言({S}を受賞者の呼び方にする)
const List<String> _buinHitokoto = [
  '{S}さんの背中を、1年間ずっと追いかけてきました',
  '{S}さんが走ると、チームの空気が変わります',
  '来年は自分が{S}さんの隣に並びたいです',
  '一番練習しているのが{S}さんなので、納得の受賞です',
];

List<Kiji> gakunaiHyoushouKiji(KijiKankyou k) {
  final String? site = gakunaiSiteMeiJibun(k);
  final UnivData? u = k.jibunUniv;
  if (site == null || u == null) return [];
  const int no = 152;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, no));
  final String nendo = _nendoMoji(k);
  final List<SenshuData> buin = [
    for (final SenshuData s in k.senshu)
      if (s.univid == u.id && s.gakunen >= 1 && s.gakunen <= 4) s,
  ];
  if (buin.isEmpty) return [];
  final List<_Seiseki> zen = [for (final SenshuData s in buin) _seiseki(s)]..sort((a, b) => _seisekiHikaku(k, a, b));
  final List<_Seiseki> tenAri = [
    for (final _Seiseki x in zen)
      if (x.ten > 0) x,
  ];
  final Set<int> tsukatta = {};

  // 学内MVP
  final _Seiseki? mvp = tenAri.isEmpty ? null : tenAri.first;
  if (mvp != null) tsukatta.add(mvp.s.id);
  // 学内新人賞(1年生で点が最高。誰も点がなければ、入学時からの伸びが一番大きい1年生)
  _Seiseki? shinjin;
  int? shinjinNobi;
  for (final _Seiseki x in tenAri) {
    if (x.s.gakunen == 1 && !tsukatta.contains(x.s.id)) {
      shinjin = x;
      break;
    }
  }
  if (shinjin == null) {
    int saidai = 0;
    for (final _Seiseki x in zen) {
      if (x.s.gakunen != 1 || tsukatta.contains(x.s.id)) continue;
      final int? nobi = _nyuugakuNobi(k, x.s);
      if (nobi != null && nobi > saidai) {
        saidai = nobi;
        shinjin = x;
      }
    }
    if (shinjin != null) shinjinNobi = saidai;
  }
  if (shinjin != null) tsukatta.add(shinjin.s.id);
  // 功労賞(4年生で、4年間の駅伝(本戦)の出走が一番多い。同じなら区間賞の数)
  SenshuData? kourou;
  int kourouShussou = 0;
  int kourouKukanshou = 0;
  for (final SenshuData s in buin) {
    if (s.gakunen != 4 || tsukatta.contains(s.id)) continue;
    int shussou = 0;
    int kukanshou = 0;
    for (final int r in const [0, 1, 2, 5]) {
      if (s.entrykukan_race.length <= r) continue;
      for (int g = 0; g < 4 && g < s.entrykukan_race[r].length; g++) {
        if (s.entrykukan_race[r][g] < 0) continue;
        final int j = (s.kukanjuni_race.length > r && s.kukanjuni_race[r].length > g) ? s.kukanjuni_race[r][g] : TEISUU.DEFAULTJUNI;
        if (!shutsujouJuni(j)) continue;
        if (gakurenShussouJuni(r, j)) continue; // 学連選抜で走った正月駅伝は数えない(1.9.5)
        shussou++;
        if (j == 0) kukanshou++;
      }
    }
    if (shussou == 0) continue;
    if (shussou > kourouShussou || (shussou == kourouShussou && kukanshou > kourouKukanshou)) {
      kourou = s;
      kourouShussou = shussou;
      kourouKukanshou = kukanshou;
    }
  }
  if (kourou != null) tsukatta.add(kourou.id);
  // 伸び盛り賞(今年度に自己ベストを更新した種目が一番多い。同じなら学年の低いほう、次に5000mの持ちタイム)
  SenshuData? nobi;
  List<int> nobiShumoku = [];
  for (final SenshuData s in buin) {
    if (tsukatta.contains(s.id)) continue;
    final List<int> ks = _konkiBestKoushin(k, s);
    if (ks.isEmpty) continue;
    final bool kaeru = nobi == null ||
        ks.length > nobiShumoku.length ||
        (ks.length == nobiShumoku.length && s.gakunen < nobi.gakunen) ||
        (ks.length == nobiShumoku.length && s.gakunen == nobi.gakunen && k.jikoBest(s, 0) < k.jikoBest(nobi, 0));
    if (kaeru) {
      nobi = s;
      nobiShumoku = ks;
    }
  }
  if (nobi != null) tsukatta.add(nobi.id);
  if (mvp == null && shinjin == null && kourou == null && nobi == null) return [];

  // 見出し・リード
  final String midashi = mvp != null
      ? w.erabu(['$nendo 学内表彰　MVPは${w.senshu(mvp.s)}', '陸上競技部の$nendo　学内MVPに${w.senshu(mvp.s)}'])
      : '陸上競技部の$nendo　学内表彰';
  final StringBuffer lead = StringBuffer();
  lead.write('陸上競技部の$nendoを締めくくる学内表彰を、編集部が選んだ。');
  lead.write('対象は三大駅伝と対校戦の3種目で、区間順位と種目の順位を点にした。');
  if (mvp != null) lead.write('学内MVPは、${_naiyouMoji(mvp)}の${w.senshu(mvp.s)}。');

  // 学内MVP
  if (mvp != null) {
    w.koMidashi('学内MVP　${w.senshu(mvp.s)}');
    final StringBuffer mb = StringBuffer();
    mb.write('${w.senshu(mvp.s)}は今季、三大駅伝を${mvp.ekiden}度走り${mvp.kukanshou > 0 ? '、区間賞${mvp.kukanshou}度' : ''}。');
    if (_naiyouMoji(mvp).isNotEmpty) mb.write('${_naiyouMoji(mvp)}と、チームの柱として走った。');
    if (tenAri.length >= 2) mb.write('チーム内の2位は${w.senshu(tenAri[1].s)}${_naiyouMoji(tenAri[1]).isNotEmpty ? '(${_naiyouMoji(tenAri[1])})' : ''}だった。');
    final int? mvpNobi = _nyuugakuNobi(k, mvp.s);
    if (mvpNobi != null && mvp.s.gakunen >= 2) mb.write('入学時の5000mから${saMoji(mvpNobi)}縮めてきた。');
    w.danraku(mb.toString());
    w.comment(senshuComment(w, CommentBamen.hyoushou, myouji(mvp.s.name)));
    // 部員のひと言(受賞者以外の部員。同じ学年か下の学年を先に)
    SenshuData? hitokoto;
    for (final SenshuData s in buin) {
      if (s.id == mvp.s.id) continue;
      if (hitokoto == null || (s.gakunen <= mvp.s.gakunen && hitokoto.gakunen > mvp.s.gakunen)) hitokoto = s;
    }
    if (hitokoto != null) {
      w.comment('「${w.erabu(_buinHitokoto).replaceAll('{S}', myouji(mvp.s.name))}」と、${w.senshu(hitokoto)}は言う。');
    }
  }

  // 学内新人賞
  if (shinjin != null) {
    final _Seiseki sj = shinjin;
    w.koMidashi('学内新人賞　${w.senshu(sj.s)}');
    final StringBuffer sb = StringBuffer();
    if (sj.ten > 0) {
      sb.write('学内新人賞は${w.senshu(sj.s)}。1年目から${_naiyouMoji(sj)}と、上級生に交じって結果を残した。');
    } else if (shinjinNobi != null) {
      sb.write('学内新人賞は${w.senshu(sj.s)}。レースでは点に届かなかったが、入学時の5000m${jikanMoji(sj.s.kiroku_nyuugakuji_5000)}から${saMoji(shinjinNobi)}縮め、1年生で一番の伸びを見せた。');
    }
    final String? ken = k.shusshin(sj.s);
    if (ken != null) sb.write('$ken出身。');
    w.danraku(sb.toString());
    w.comment(senshuComment(w, CommentBamen.shinjinshou, myouji(sj.s.name)));
  }

  // 功労賞
  if (kourou != null) {
    final SenshuData kr = kourou;
    w.koMidashi('功労賞　${w.senshu(kr)}');
    w.danraku(
      '功労賞は、この春卒業する${w.senshu(kr)}。4年間で駅伝を$kourouShussou度走り${kourouKukanshou > 0 ? '、区間賞を$kourouKukanshou度取った' : '、たすきをつなぎ続けた'}。'
      'レースの日も練習の日も、チームの中心にいた4年間だった。',
    );
    w.comment(senshuComment(w, CommentBamen.sotsugyou, myouji(kr.name)));
  }

  // 伸び盛り賞
  if (nobi != null) {
    final SenshuData nb = nobi;
    w.koMidashi('伸び盛り賞　${w.senshu(nb)}');
    final List<String> shumoku = [
      for (final int idx in nobiShumoku) '${kijiShumokuMei[idx]}${jikanMoji(k.jikoBest(nb, idx))}',
    ];
    w.danraku('伸び盛り賞は${w.senshu(nb)}(${nb.gakunen}年)。今季は${shumoku.join('、')}と、${nobiShumoku.length}種目で自己ベストを更新した。');
    w.comment(senshuComment(w, CommentBamen.hyoushou, myouji(nb.name)));
  }

  final String kc = kantokuComment(w, KantokuBamen.nenkanBest, u.id);
  if (kc.isNotEmpty) w.comment(kc);
  w.danraku('受賞した皆さん、おめでとうございます。春からの新しいシーズンも、編集部は陸上競技部を追い続けます。');

  // 表(チーム内の点の上位5人)
  final List<List<String>> gyou = [];
  for (int i = 0; i < tenAri.length && i < 5; i++) {
    final _Seiseki x = tenAri[i];
    gyou.add([
      juniMoji(i),
      '${fullMei(x.s.name)}(${x.s.gakunen})',
      '${x.ten}',
      '${x.kukanshou}',
      '${x.nyuushou}',
    ]);
  }
  return [
    Kiji(
      category: '学内表彰',
      midashi: midashi,
      lead: lead.toString(),
      honbun: w.honbun,
      hyou: [
        if (gyou.isNotEmpty) KijiHyou('チーム内の今季の点(上位5人)', ['順位', '選手', '点', '区間賞', '対校戦入賞'], gyou),
      ],
      haishin: k.haishinMei(no, asa: true),
      kisha: gakunaiKishaMei(k, site, no),
      jibun: true,
      kekka: true,
      site: site,
      gakunai: true,
    ),
  ];
}
