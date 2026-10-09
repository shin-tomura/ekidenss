import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/konki_best.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart'; // 大会の名前(courseRaceTitle)
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_comment.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart' show EkidenKekka, EkidenUnivKekka;
import 'package:ekiden/kansuu/kiji/kiji_yosen.dart'
    show YosenKekka, YosenUnivKekka, YosenSenshuKekka;

// ------------------------------------------------------------
// 学内メディア「○○スポーツ」の記事(1.9.3)
// 自分の大学の選手への感情移入を高めるため、箱庭スポーツ(ニュースサイト)とは別に、
// 自分の大学の陸上競技部を追う学内メディアの記事を作る。サイトの名前は「大学名+スポーツ」
// (大学名の最後の「大学」は除く。箱庭スポーツと同じ名前になるときだけ「○○大学スポーツ」)
//
// 記事(どれも自分の大学のことだけ)
//  1. 駅伝の結果号(結果画面): チームの結果と、走った全員を1人ずつ振り返る記事
//  2. 駅伝の展望号(直前順位予想の画面): 区間エントリー全員の選手名鑑と、4年生・初出走の選手の特集
//  3. 当日変更号(目標順位の確認の画面。駅伝の1区のスタート前): 当日変更で入った選手と外れた選手。
//     当日変更がなければ、予定どおりのメンバーで挑む短い記事
//  4. 復路スタート直前号(正月駅伝の6区のスタート前): 往路の振り返りと、復路を走る選手
//  5. 卒業生特集(3月25日の最新画面): 自分の大学の4年生全員の4年間の歩み
//     (卒業の処理のあとは卒業選手のデータが大学ごとに10人くらいしか残らないので、この日だけ)
//  6. 駅伝予選(11月駅伝予選・正月駅伝予選)の結果号と展望号: 弱い大学は予選にしか出られない年も
//     あるので、予選でも全員を紹介する。予選の出走歴も数える(選手名鑑・卒業生特集)が、
//     「初めての駅伝」「駅伝デビュー」は今まで通り本戦(駅伝)だけで決める
//
// 守る決まり(箱庭スポーツと同じ)
//  ・能力値は書かない(見抜く力の仕組みを壊さないため)。成長タイプ・上限・サプライズも書かない
//    (伸びたことは、持ちタイムや区間順位など見えている事実からだけ書く)
//  ・総監督(プレイヤー)の言葉は作らない。当日変更の理由も書かない(決めたのは総監督なので)
//  ・趣味は、趣味非表示設定のときは書かない
//  ・文体は常体だが、学内メディアらしく選手に寄り添う温かい言い方にする(苦しんだ区間も前向きに書く)
// ------------------------------------------------------------

/// 大学[u]の学内メディアの名前(「○○スポーツ」)
String gakunaiSiteMei(UnivData u) {
  String n = u.name.trim();
  if (n.endsWith('大学')) n = n.substring(0, n.length - 2);
  if (n.isEmpty) return '学内スポーツ';
  if ('$nスポーツ' == kijiSiteMei) return '$n大学スポーツ';
  return '$nスポーツ';
}

/// 自分の大学の学内メディアの名前(大学がなければnull)
String? gakunaiSiteMeiJibun(KijiKankyou k) {
  final UnivData? u = k.jibunUniv;
  return u == null ? null : gakunaiSiteMei(u);
}

// ------------------------------------------------------------
// 共通の部品
// ------------------------------------------------------------

/// 年度の中の大会の順(11月駅伝予選6月・10月駅伝・正月駅伝予選10月・11月駅伝・正月駅伝・カスタム駅伝2月)
const List<int> _raceJun = [3, 0, 4, 1, 2, 5];

/// 駅伝の本戦(予選ではない)か
bool _honsen(int race) => race == 0 || race == 1 || race == 2 || race == 5;

/// 駅伝を1回走った記録
class _Shussou {
  final int race;
  final int gakunen;
  final int kukan;

  /// 区間順位(0が1位。分からなければnull)
  final int? juni;

  const _Shussou(this.race, this.gakunen, this.kukan, this.juni);
}

/// 選手[s]の駅伝の出走歴(古い順。区間を走った大会だけ)
/// [imaNozoku] 今の学年の、記事にする大会とそれより後の大会を除く(レース前の記事)
/// [yosenMo] 駅伝予選も入れる(入れないときは本戦だけ)
List<_Shussou> _shussouReki(
  KijiKankyou k,
  SenshuData s, {
  required bool imaNozoku,
  bool yosenMo = false,
}) {
  final List<_Shussou> list = [];
  final int imaJun = _raceJun.indexOf(k.race);
  for (int g = 1; g <= s.gakunen; g++) {
    for (int ji = 0; ji < _raceJun.length; ji++) {
      final int race = _raceJun[ji];
      if (!yosenMo && !_honsen(race)) continue;
      if (imaNozoku && g == s.gakunen && imaJun >= 0 && ji >= imaJun) continue;
      if (s.entrykukan_race.length <= race) continue;
      if (s.entrykukan_race[race].length < g) continue;
      final int e = s.entrykukan_race[race][g - 1];
      if (e < 0) continue;
      int? juni;
      if (s.kukanjuni_race.length > race && s.kukanjuni_race[race].length >= g) {
        final int j = s.kukanjuni_race[race][g - 1];
        if (j >= 0 && j < TEISUU.DEFAULTJUNI) juni = j;
      }
      list.add(_Shussou(race, g, e, juni));
    }
  }
  return list;
}

/// 出走1回の言い方(「2年の11月駅伝3区(区間5位)」「2年の11月駅伝予選2組(組5位)」
/// 「2年の正月駅伝予選(全体35位)」)
String _shussouMoji(_Shussou x) {
  final String mei = '${x.gakunen}年の${courseRaceTitle(x.race)}';
  final int? j = x.juni;
  if (x.race == 4) return j == null ? mei : '$mei(全体${j + 1}位)';
  if (x.race == 3) {
    return '$mei${x.kukan + 1}組${j == null ? '' : '(組${j + 1}位)'}';
  }
  return '$mei${x.kukan + 1}区${j == null ? '' : '(区間${j + 1}位)'}';
}

/// 予選の出走の回数の一言(「予選も2度走っている。」。なければ空)
String _yosenKaisuuBun(KijiKankyou k, SenshuData s, {required bool imaNozoku}) {
  final int n = _shussouReki(k, s, imaNozoku: imaNozoku, yosenMo: true)
      .where((x) => !_honsen(x.race))
      .length;
  return n > 0 ? '駅伝予選も$n度走っている。' : '';
}

/// 種目[idx]の持ちタイムの文(「1万m28分31秒(チーム内3位)」。記録がなければnull)
String? _mochiTimeMoji(KijiKankyou k, SenshuData s, int idx) {
  final double t = k.jikoBest(s, idx);
  if (t >= TEISUU.DEFAULTTIME) return null;
  final int gj = idx < s.gakunaijuni_bestkiroku.length
      ? s.gakunaijuni_bestkiroku[idx]
      : TEISUU.DEFAULTJUNI;
  final String juni = (gj >= 0 && gj < TEISUU.DEFAULTJUNI)
      ? '(チーム内${gj + 1}位)'
      : '';
  return '${kijiShumokuMei[idx]}${jikanMoji(t)}$juni';
}

/// 区間[kk]で見る種目の持ちタイムの文(記録のある最初の種目。なければnull)
String? _kukanMochiTime(KijiKankyou k, SenshuData s, int kk) {
  for (final int idx in kukanShumoku(k.gh, k.race, kk)) {
    final String? m = _mochiTimeMoji(k, s, idx);
    if (m != null) return m;
  }
  return null;
}

/// 区間[kk]で見る主な種目の、今季に自己ベストを出したかどうかの一言(なければ空)
String _konkiNoBun(KijiKankyou k, SenshuData s, int kk) {
  final int idx = kukanShumoku(k.gh, k.race, kk).first;
  final double jiko = k.jikoBest(s, idx);
  final double konki = konkiBest(s, idx);
  if (jiko >= TEISUU.DEFAULTTIME || konki >= TEISUU.DEFAULTTIME) return '';
  if (byou(konki) <= byou(jiko)) {
    return '今季、${kijiShumokuMei[idx]}の自己ベストを更新している。';
  }
  return '';
}

/// 自分の大学の選手で、大会のエントリーが[jouken]に合う選手(id順)
List<SenshuData> _jibunSenshu(KijiKankyou k, bool Function(int entry) jouken) {
  final UnivData? u = k.jibunUniv;
  if (u == null) return [];
  return [
    for (final SenshuData s in k.senshu)
      if (s.univid == u.id && jouken(k.entry(s))) s,
  ];
}

/// 区間[kk]を走る(走った)自分の大学の選手(いなければnull)
SenshuData? _kukanNoSenshu(KijiKankyou k, int kk) {
  final List<SenshuData> l = _jibunSenshu(k, (e) => e == kk);
  return l.isEmpty ? null : l.first;
}

/// 当日変更で区間[kk]から外れた自分の大学の選手(いなければnull)
/// (外れた選手には区間の値に -(100+区間) の印が残る)
SenshuData? _hazuretaSenshu(KijiKankyou k, int kk) {
  final List<SenshuData> l = _jibunSenshu(k, (e) => e == -(100 + kk));
  return l.isEmpty ? null : l.first;
}

/// 従来の記録(秒。エントリーの時点で控えたもの。なければnull)
/// [i] 0〜9は大会の区間記録、10〜19は学内の区間記録(kiji_kekka.dart と同じ)
int? _juraiKiroku(KijiKankyou k, int i) {
  if (i < 0 || i >= 20 || k.kantoku.yobiint4.length <= i) return null;
  final int t = k.kantoku.yobiint4[i];
  if (t <= 0 || t >= 360000) return null;
  return t;
}

/// 記者の名前(学生記者。年・大会・記事で決まる)
String _kishaMei(KijiKankyou k, String site, int no) {
  final KijiRand r = KijiRand(kijiTane(k.gh, k.race, no, 91));
  final List<String> mae = [
    for (final String n in k.gh.name_mae)
      if (n.isNotEmpty) n,
  ];
  final List<String> ato = [
    for (final String n in k.gh.name_ato)
      if (n.isNotEmpty) n,
  ];
  if (mae.isEmpty || ato.isEmpty) return '$site編集部';
  return '$site ${r.erabu(mae)}${r.erabu(ato)}(${1 + r.ikutsu(4)}年)';
}

/// 学内メディアの記事を作るときの共通の仕上げ
Kiji _kansei(
  KijiKankyou k,
  String site,
  int no,
  KijiKakite w, {
  required String category,
  required String midashi,
  required String lead,
  required bool kekka,
  List<KijiHyou> hyou = const [],
}) {
  return Kiji(
    category: category,
    midashi: midashi,
    lead: lead,
    honbun: w.honbun,
    hyou: hyou,
    haishin: k.haishinMei(no, asa: !kekka),
    kisha: _kishaMei(k, site, no),
    jibun: true,
    kekka: kekka,
    site: site,
    gakunai: true,
  );
}

/// 選手[s]の、レース前の出走歴の一言(「駅伝は3度目」「2年連続の5区」など)
/// [kk] 今回の区間
String _maeNoShussouBun(KijiKankyou k, SenshuData s, int kk, String yobi) {
  final List<_Shussou> reki = _shussouReki(k, s, imaNozoku: true);
  final String yosen = _yosenKaisuuBun(k, s, imaNozoku: true);
  if (reki.isEmpty) {
    if (k.ichinenDake) return yosen;
    return (s.gakunen == 1
            ? '$yobiにとって、これが大学駅伝デビュー戦となる。'
            : '$yobiは${s.gakunen}年目で、初めての駅伝出走をつかんだ。') +
        yosen;
  }
  final StringBuffer sb = StringBuffer();
  // 同じ大会の同じ区間を、何年続けて走るか
  int renzoku = 0;
  for (int n = 1; n <= 3; n++) {
    if (k.entryMae(s, k.race, n) == kk) {
      renzoku++;
    } else {
      break;
    }
  }
  final int maeE = k.entryMae(s, k.race, 1);
  final int? maeJ = k.kukanJuniMae(s, k.race, 1);
  if (renzoku >= 1) {
    sb.write('${renzoku + 1}年連続の${kk + 1}区となる。');
    if (maeJ != null) sb.write('昨年は区間${maeJ + 1}位だった。');
  } else if (maeE >= 0) {
    sb.write(
      '昨年の${k.raceMei}は${maeE + 1}区${maeJ != null ? '(区間${maeJ + 1}位)' : ''}を走った。',
    );
  } else {
    sb.write('直近では、${_shussouMoji(reki.last)}を走った。');
  }
  sb.write('駅伝は${reki.length + 1}度目の出走。');
  final int kukanshou = reki.where((x) => x.juni == 0).length;
  if (kukanshou > 0) sb.write('区間賞は$kukanshou度獲得している。');
  sb.write(yosen);
  return sb.toString();
}

/// 選手[s]を区間[kk]の選手として紹介する段落(持ちタイム・出走歴・4年生・出身地と趣味)
void _shoukai(KijiKakite w, SenshuData s, int kk) {
  final KijiKankyou k = w.k;
  final String yobi = myouji(s.name);
  final StringBuffer sb = StringBuffer();
  final String? mochi = _kukanMochiTime(k, s, kk);
  if (mochi != null) sb.write('持ちタイムは$mochi。');
  sb.write(_konkiNoBun(k, s, kk));
  sb.write(_maeNoShussouBun(k, s, kk, yobi));
  if (s.gakunen == 4) {
    sb.write(
      k.race == 2 ? '最後の正月駅伝に挑む。' : '4年生にとっては、これが最後の${k.raceMei}だ。',
    );
  }
  w.danraku(sb.toString());
  w.danraku(shusshinShumiBun(k, s, w.r, yobi));
}

/// 意気込みのコメントの場面(4年生・初出走・そのほか)
CommentBamen _ikigomiBamen(KijiKankyou k, SenshuData s) {
  if (s.gakunen == 4) return CommentBamen.gakunaiYonenIkigomi;
  if (!k.ichinenDake && _shussouReki(k, s, imaNozoku: true).isEmpty) {
    return CommentBamen.gakunaiDebutIkigomi;
  }
  return CommentBamen.gakunaiIkigomi;
}

/// 自分の大学のこの大会の目標順位(決まっていなければnull。0が1位)
int? _mokuhyou(KijiKankyou k, UnivData u, int n) {
  if (u.mokuhyojuni.length <= k.race) return null;
  final int m = u.mokuhyojuni[k.race];
  return (m >= 0 && m < n) ? m : null;
}

// ------------------------------------------------------------
// 1. 駅伝の結果号
// ------------------------------------------------------------

/// 駅伝と駅伝予選の結果号(自分の大学が出ていなければ空)
List<Kiji> gakunaiKekkaKiji(KijiKankyou k) {
  if (k.race == 3 || k.race == 4) {
    final String? site = gakunaiSiteMeiJibun(k);
    return site == null ? [] : _yosenKekkaKiji(k, site);
  }
  if (!k.ekiden) return [];
  final String? site = gakunaiSiteMeiJibun(k);
  if (site == null) return [];
  final EkidenKekka? e = EkidenKekka.tsukuru(k);
  if (e == null) return [];
  final EkidenUnivKekka? m = e.jibun;
  if (m == null) return [];
  return [_kekkaTop(e, m, site), _kekkaZenin(e, m, site)];
}

Kiji _kekkaTop(EkidenKekka e, EkidenUnivKekka m, String site) {
  final KijiKankyou k = e.k;
  const int no = 101;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int race = k.race;
  final int ks = e.ks;
  final int r = m.juni;
  final int? mokuhyou = _mokuhyou(k, m.u, e.n);
  final bool tassei = mokuhyou != null && r <= mokuhyou;
  final bool hatsuKaisai = hatsuKaisaiKekka(k, race);
  final int mae = juniRace(m.u, race, 1);
  final bool maeAri = !hatsuKaisai && shutsujouJuni(mae);
  final int? seed = e.seedSuu;
  final bool seedNow = seed != null && r < seed;
  final bool seedMae = seed != null && maeAri && mae < seed;

  // 見出し
  String midashi;
  if (r == 0) {
    midashi = w.erabu([
      '${k.raceMei}制覇！　全員でつかんだ頂点',
      '歓喜の優勝　${k.taikaiMei}',
    ]);
  } else if (seed != null && seedNow && !seedMae) {
    midashi = 'シード権獲得！　${k.raceMei}は${juniMoji(r)}';
  } else if (tassei) {
    midashi = w.erabu([
      '目標達成！　${k.raceMei}は${juniMoji(r)}',
      '${juniMoji(r)}で目標クリア　たすきに込めた思い実る',
    ]);
  } else if (mokuhyou != null) {
    midashi = w.erabu([
      '${k.raceMei}は${juniMoji(r)}　悔しさを次への力に',
      '目標には届かず${juniMoji(r)}　それでも前へ',
    ]);
  } else {
    midashi = '${k.raceMei}は${juniMoji(r)}　全員でつないだたすき';
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}に出場した陸上競技部は、${jikanMoji(m.time)}の${juniMoji(r)}でゴールした。',
  );
  if (r == 0) {
    lead.write(hatsuKaisai ? '初めて開催された大会で、初代王者に輝いた。' : '選手たちの笑顔がはじけた。');
  } else {
    lead.write('トップとは${kinsaMoji(saByou(m.time, e.jun.first.time))}だった。');
  }
  if (mokuhyou != null) {
    lead.write(
      tassei
          ? '掲げていた目標の${juniMoji(mokuhyou)}を${r < mokuhyou ? '上回った' : 'クリアした'}。'
          : '目標の${juniMoji(mokuhyou)}にはあと${r - mokuhyou}つ届かなかったが、最後までたすきをつないだ。',
    );
  }
  if (maeAri) {
    if (mae > r) {
      lead.write('前回の${juniMoji(mae)}から${mae - r}つ順位を上げた。');
    } else if (mae == r) {
      lead.write('前回と同じ${juniMoji(r)}だった。');
    }
  }
  if (seed != null) {
    if (seedNow && !seedMae) {
      lead.write('上位$seed校に与えられるシード権もつかんだ。');
    } else if (seedNow && seedMae) {
      lead.write('シード権も守った。');
    } else if (!seedNow && seedMae) {
      lead.write('シード権は失ったが、来季は予選会から再び挑む。');
    }
  }

  // 本文: レースの流れ
  w.koMidashi('レースを振り返って');
  final SenshuData? s1 = m.senshu[0];
  if (s1 != null) {
    w.danraku(
      '1区の${w.senshu(s1)}が${juniMoji(m.tuuka[0])}でたすきを渡し、レースが動き出した。',
    );
  }
  // 一番高い順位にいた区間と、一番順位を上げた区間
  int saikou = 0;
  for (int kk = 1; kk < ks; kk++) {
    if (m.tuuka[kk] < m.tuuka[saikou]) saikou = kk;
  }
  int jouGain = 0;
  int jouKukan = -1;
  for (int kk = 1; kk < ks; kk++) {
    final int g = m.tuuka[kk - 1] - m.tuuka[kk];
    if (g > jouGain) {
      jouGain = g;
      jouKukan = kk;
    }
  }
  if (jouKukan >= 1 && jouGain >= 2) {
    final SenshuData? s = m.senshu[jouKukan];
    if (s != null) {
      w.danraku(
        '${jouKukan + 1}区では${w.senshu(s)}が$jouGain人を抜き、チームを${juniMoji(m.tuuka[jouKukan])}に押し上げた。',
      );
    }
  }
  if (saikou < ks - 1 && m.tuuka[saikou] < m.tuuka[ks - 1]) {
    w.danraku('${saikou + 1}区を終えた時点では${juniMoji(m.tuuka[saikou])}につける場面もあった。');
  }
  final int? ouro = e.ouroKukansuu;
  if (ouro != null) {
    // 復路の順位(復路のタイムの順)
    final double fukuro = m.time - m.ruikei[ouro - 1];
    int fj = 0;
    for (final EkidenUnivKekka x in e.jun) {
      if (x.time - x.ruikei[ouro - 1] < fukuro) fj++;
    }
    w.danraku('往路は${juniMoji(m.tuuka[ouro - 1])}、復路は${juniMoji(fj)}だった。');
  }
  final List<String> kukanshou = [
    for (int kk = 0; kk < ks; kk++)
      if (m.kukanJuni[kk] == 0 && m.senshu[kk] != null)
        '${kk + 1}区の${w.senshu(m.senshu[kk]!)}',
  ];
  if (kukanshou.isNotEmpty) {
    w.danraku('${kukanshou.join('、')}が区間賞に輝いた。');
  }
  // 監督のコメント
  KantokuBamen kb;
  bool kuyashii = false;
  if (r == 0) {
    kb = KantokuBamen.yuushou;
  } else if (seed != null && !seedNow && seedMae) {
    kb = KantokuBamen.seedSoushitsu;
    kuyashii = true;
  } else if (seed != null && seedNow && !seedMae) {
    kb = KantokuBamen.seedKakutoku;
  } else if (tassei) {
    kb = KantokuBamen.mokuhyouTassei;
  } else {
    kb = KantokuBamen.mokuhyouMitassei;
    kuyashii = true;
  }
  w.comment(kantokuComment(w, kb, m.u.id, kuyashii: kuyashii));
  w.danraku('走った$ks人の一人ひとりの走りは、別の記事「全員の走り」で振り返る。');
  final String tsugi = race == 0
      ? '次は11月駅伝。チームはさらに強くなって戻ってくる。'
      : (race == 1
            ? '次はいよいよ正月駅伝。部員全員で、もう一段上を目指す。'
            : (race == 2 ? 'この経験を胸に、チームは新たなシーズンへ向かう。' : ''));
  w.danraku(tsugi);

  final List<List<String>> gyou = [
    ['総合順位', juniMoji(r)],
    ['タイム', jikanMoji(m.time)],
    if (r > 0) ['トップとの差', saMoji(saByou(m.time, e.jun.first.time))],
    if (mokuhyou != null) ['目標順位', juniMoji(mokuhyou)],
    if (maeAri) ['前回', juniMoji(mae)],
  ];
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝',
    midashi: midashi,
    lead: lead.toString(),
    kekka: true,
    hyou: [KijiHyou('${k.taikaiMei}の結果', ['項目', '結果'], gyou)],
  );
}

Kiji _kekkaZenin(EkidenKekka e, EkidenUnivKekka m, String site) {
  final KijiKankyou k = e.k;
  const int no = 102;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int race = k.race;
  final int ks = e.ks;
  final int n = e.n;

  final String midashi = w.erabu([
    '全員の走りを振り返る　${k.raceMei}を駆けた$ks人',
    '$ks人がつないだたすき　${k.raceMei}全区間リポート',
  ]);
  final String lead =
      '${k.taikaiMei}でたすきをつないだ$ks人の走りを、1区から順に振り返る。';

  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = m.senshu[kk];
    if (s == null) continue;
    w.koMidashi('${kk + 1}区　${w.senshu(s)}');
    final String yobi = w.senshu(s);
    final int kj = m.kukanJuni[kk];
    final int ima = m.tuuka[kk];
    final StringBuffer sb = StringBuffer();
    sb.write('${e.kukanMei(kk)}を任された$yobiは、区間${kj + 1}位の${jikanMoji(m.kukanTime[kk])}で走った。');
    if (kk == 0) {
      sb.write('${juniMoji(ima)}で2区へたすきを渡した。');
    } else {
      final int maeJ = m.tuuka[kk - 1];
      final String ato = kk == ks - 1 ? 'フィニッシュした' : '次の区間へつないだ';
      if (maeJ > ima) {
        sb.write('${juniMoji(maeJ)}でたすきを受けると、${maeJ - ima}つ順位を上げて${juniMoji(ima)}で$ato。');
      } else if (maeJ == ima) {
        sb.write('${juniMoji(ima)}を守って$ato。');
      } else {
        sb.write('${juniMoji(maeJ)}でたすきを受け、${juniMoji(ima)}で$ato。');
      }
    }
    if (kj == 0) {
      final bool shin =
          s.chokuzentaikai_zentaikukansinflag == 1 && _juraiKiroku(k, kk) != null;
      sb.write(shin ? '見事な区間賞で、区間新記録まで打ち立てた。' : '見事な区間賞だった。');
    }
    if (s.chokuzentaikai_univkukansinflag == 1 && _juraiKiroku(k, kk + 10) != null) {
      sb.write('学内の区間記録も塗り替えた。');
    }
    // 昨年の同じ大会との比べ
    final int maeE = k.entryMae(s, race, 1);
    final int? maeKj = k.kukanJuniMae(s, race, 1);
    final bool debut = _shussouReki(k, s, imaNozoku: true).isEmpty;
    if (maeE == kk && maeKj != null) {
      if (maeKj > kj) {
        sb.write('昨年の同じ${kk + 1}区は区間${maeKj + 1}位。${maeKj - kj}つ順位を上げ、1年間の成長を示した。');
      } else if (maeKj == kj) {
        sb.write('昨年と同じ区間${kj + 1}位で、2年続けてこの区間の役目を果たした。');
      } else {
        sb.write('2年続けて${kk + 1}区を任された。昨年の区間${maeKj + 1}位には届かなかったが、この経験は次につながる。');
      }
    } else if (maeE >= 0) {
      sb.write('昨年は${maeE + 1}区${maeKj != null ? '(区間${maeKj + 1}位)' : ''}を走った。');
    } else if (debut && !k.ichinenDake) {
      sb.write('これが駅伝デビュー戦だった。');
    }
    if (s.gakunen == 4) {
      sb.write(race == 2 ? 'これが最後の正月駅伝だった。' : '4年生として最後の${k.raceMei}だった。');
    }
    // 当日変更で入った選手
    final bool iri = _hazuretaSenshu(k, kk) != null;
    if (iri) {
      sb.write(kj <= n ~/ 3 ? '当日変更での起用に、見事に応えた。' : '当日変更での起用だった。');
    }
    final bool kurushii = n >= 6 && kj >= (n * 3) ~/ 4;
    if (kurushii) sb.write('苦しい走りになったが、最後までたすきを運び切った。');
    w.danraku(sb.toString());
    w.danraku(shusshinShumiBun(k, s, w.r, myouji(s.name)));
    // コメント
    CommentBamen bamen;
    bool kuyashii = false;
    if (kj == 0) {
      bamen = CommentBamen.kukanshou;
    } else if (kk > 0 && m.tuuka[kk - 1] - ima >= 3) {
      bamen = CommentBamen.oinuki;
    } else if (iri && kj <= n ~/ 3) {
      bamen = CommentBamen.toujitsuKiyou;
    } else if (s.gakunen == 4 && race == 2) {
      bamen = CommentBamen.yonenSaigo;
    } else if (kurushii) {
      bamen = CommentBamen.brake;
      kuyashii = true;
    } else if (debut && !k.ichinenDake && s.gakunen == 1 && kj <= n ~/ 2) {
      bamen = CommentBamen.ichinenKousou;
    } else {
      bamen = CommentBamen.gakunaiKekka;
    }
    w.comment(senshuComment(w, bamen, myouji(s.name), kuyashii: kuyashii));
  }

  // 走れなかった仲間(補欠のままの選手と、当日変更で外れた選手)
  final List<SenshuData> sasaeta = _jibunSenshu(k, (e) => e == -1 || e <= -100);
  if (sasaeta.isNotEmpty) {
    w.koMidashi('支えた仲間たち');
    final List<String> namae = [for (final SenshuData s in sasaeta) w.senshu(s)];
    w.danraku(
      '${namae.join('、')}は、エントリーされながら今回は出番がなかった。'
      '給水や付き添いでチームを支え、レースを一緒に戦った。',
    );
    w.comment(
      senshuComment(w, CommentBamen.gakunaiHoketsu, myouji(sasaeta.first.name)),
    );
  }

  final List<List<String>> gyou = [];
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = m.senshu[kk];
    final int maeE = s == null ? -2 : k.entryMae(s, race, 1);
    final int? maeKj = s == null ? null : k.kukanJuniMae(s, race, 1);
    gyou.add([
      '${kk + 1}区',
      s == null ? '-' : '${fullMei(s.name)}(${s.gakunen})',
      juniMoji(m.kukanJuni[kk]),
      jikanMoji(m.kukanTime[kk]),
      juniMoji(m.tuuka[kk]),
      maeE >= 0 ? '${maeE + 1}区${maeKj != null ? ' ${maeKj + 1}位' : ''}' : '-',
    ]);
  }
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝',
    midashi: midashi,
    lead: lead,
    kekka: true,
    hyou: [
      KijiHyou('全区間の成績', ['区間', '選手', '区間順位', 'タイム', '通過', '昨年'], gyou),
    ],
  );
}

// ------------------------------------------------------------
// 2. 駅伝の展望号(選手名鑑と特集)
// ------------------------------------------------------------

/// 駅伝と駅伝予選の展望号(自分の大学が出ていない・区間エントリーがまだのときは空)
List<Kiji> gakunaiTenbouKiji(KijiKankyou k) {
  final bool yosen = k.race == 3 || k.race == 4;
  if (!k.ekiden && !yosen) return [];
  final String? site = gakunaiSiteMeiJibun(k);
  final UnivData? u = k.jibunUniv;
  if (site == null || u == null || !k.shutsujou(u)) return [];
  if (yosen) return _yosenTenbouKiji(k, site, u);
  final int ks = k.kukansuu;
  final List<SenshuData?> hashiru = [
    for (int kk = 0; kk < ks; kk++) _kukanNoSenshu(k, kk),
  ];
  if (hashiru.every((s) => s == null)) return [];
  final List<SenshuData> hoketsu = _jibunSenshu(k, (e) => e == -1);
  final List<Kiji> list = [_meikan(k, site, u, hashiru, hoketsu)];
  final Kiji? tokushuu = _tenbouTokushuu(k, site, hashiru);
  if (tokushuu != null) list.add(tokushuu);
  return list;
}

Kiji _meikan(
  KijiKankyou k,
  String site,
  UnivData u,
  List<SenshuData?> hashiru,
  List<SenshuData> hoketsu,
) {
  const int no = 111;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int ks = hashiru.length;
  final String midashi = w.erabu([
    '${k.raceMei}へ　たすきをつなぐ$ks人の選手名鑑',
    '区間エントリー$ks人を紹介　${k.taikaiMei}',
  ]);
  final String lead =
      '${k.taikaiMei}の区間エントリーが決まった。たすきをつなぐ$ks人'
      '${hoketsu.isEmpty ? '' : 'と、補欠の${hoketsu.length}人'}を紹介する。';
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = hashiru[kk];
    if (s == null) continue;
    w.koMidashi('${kukanYobikata(k.gh, k.race, kk, ks)}　${w.senshu(s)}');
    _shoukai(w, s, kk);
    w.comment(senshuComment(w, _ikigomiBamen(k, s), myouji(s.name)));
  }
  if (hoketsu.isNotEmpty) {
    w.koMidashi('補欠');
    final List<String> namae = [for (final SenshuData s in hoketsu) w.senshu(s)];
    w.danraku(
      '補欠には${namae.join('、')}が入った。'
      '${k.race == 2 ? '往路・復路の当日変更での出番に備える。' : '当日変更での出番に備える。'}',
    );
  }
  w.comment(
    kantokuComment(
      w,
      juniRace(u, k.race, 0) == 0 ? KantokuBamen.tenbouHonmei : KantokuBamen.tenbouChousen,
      u.id,
    ),
  );

  final List<List<String>> gyou = [];
  for (int kk = 0; kk < ks; kk++) {
    final SenshuData? s = hashiru[kk];
    if (s == null) continue;
    final int kai = _shussouReki(k, s, imaNozoku: true).length;
    gyou.add([
      '${kk + 1}区',
      '${fullMei(s.name)}(${s.gakunen})',
      k.shusshin(s) ?? (s.hirou == 1 ? '留学生' : '-'),
      _kukanMochiTime(k, s, kk) ?? '-',
      kai == 0 ? '初' : '${kai + 1}度目',
    ]);
  }
  for (final SenshuData s in hoketsu) {
    final int kai = _shussouReki(k, s, imaNozoku: true).length;
    gyou.add([
      '補欠',
      '${fullMei(s.name)}(${s.gakunen})',
      k.shusshin(s) ?? (s.hirou == 1 ? '留学生' : '-'),
      _mochiTimeMoji(k, s, 1) ?? '-',
      kai == 0 ? '初' : '${kai + 1}度目',
    ]);
  }
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝・展望',
    midashi: midashi,
    lead: lead,
    kekka: false,
    hyou: [
      KijiHyou('選手名鑑', ['区間', '選手', '出身', '持ちタイム', '駅伝'], gyou),
    ],
  );
}

/// 4年生と、初めて駅伝を走る選手の特集(どちらもいなければnull)
Kiji? _tenbouTokushuu(KijiKankyou k, String site, List<SenshuData?> hashiru) {
  const int no = 112;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final List<int> yonen = [];
  final List<int> debut = [];
  for (int kk = 0; kk < hashiru.length; kk++) {
    final SenshuData? s = hashiru[kk];
    if (s == null) continue;
    if (s.gakunen == 4) {
      yonen.add(kk);
    } else if (!k.ichinenDake && _shussouReki(k, s, imaNozoku: true).isEmpty) {
      debut.add(kk);
    }
  }
  if (yonen.isEmpty && debut.isEmpty) return null;
  final String midashi = yonen.isNotEmpty
      ? (k.race == 2
            ? '最後の正月駅伝へ　4年生${yonen.length}人の思い'
            : '4年生${yonen.length}人、最後の${k.raceMei}へ')
      : '初めての駅伝へ　${debut.length}人の挑戦';
  final List<String> bu = [
    if (yonen.isNotEmpty) '最後の舞台に立つ4年生',
    if (debut.isNotEmpty) '初めて駅伝を走る選手',
  ];
  final String lead = '${k.taikaiMei}に挑む選手のうち、${bu.join('と、')}を紹介する。';
  if (yonen.isNotEmpty) {
    w.koMidashi('4年生');
    final List<String> l = [
      for (final int kk in yonen) '${kk + 1}区の${w.senshu(hashiru[kk]!)}',
    ];
    w.danraku(
      '${l.join('、')}は、4年間の集大成として${k.raceMei}を走る。'
      '${k.race == 2 ? 'このメンバーでたすきをつなぐのは、これが最後になる。' : 'チームを引っ張ってきた4年生が、背中で後輩たちに伝える。'}',
    );
    final SenshuData s = hashiru[yonen.last]!;
    w.comment(senshuComment(w, CommentBamen.gakunaiYonenIkigomi, myouji(s.name)));
  }
  if (debut.isNotEmpty) {
    w.koMidashi('初めての駅伝');
    final List<String> l = [
      for (final int kk in debut) '${kk + 1}区の${w.senshu(hashiru[kk]!)}',
    ];
    w.danraku('${l.join('、')}は、これが初めての駅伝になる。先輩たちに続き、新しい力がチームに加わる。');
    final SenshuData s = hashiru[debut.first]!;
    w.comment(senshuComment(w, CommentBamen.gakunaiDebutIkigomi, myouji(s.name)));
  }
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝・展望',
    midashi: midashi,
    lead: lead,
    kekka: false,
  );
}

// ------------------------------------------------------------
// 3. 当日変更号(駅伝の1区のスタート前)と、4. 復路スタート直前号(正月駅伝の6区のスタート前)
// ------------------------------------------------------------

/// 当日変更のあとの記事([kukan] 今のスタート前の区間。0なら1区、正月駅伝の5なら6区)
List<Kiji> gakunaiChokuzenKiji(KijiKankyou k, int kukan) {
  if (!k.ekiden) return [];
  final String? site = gakunaiSiteMeiJibun(k);
  final UnivData? u = k.jibunUniv;
  if (site == null || u == null || !k.shutsujou(u)) return [];
  if (kukan == 0) return [_toujitsu(k, site)];
  if (k.race == 2 && kukan == 5 && k.kukansuu > 5) {
    final Kiji? f = _fukuro(k, site, u);
    return f == null ? [] : [f];
  }
  return [];
}

/// 区間[hajime]から[owari]の前までの、走る選手の表
KijiHyou _hashiruHyou(KijiKankyou k, String title, int hajime, int owari, Set<int> kawatta) {
  final List<List<String>> gyou = [];
  for (int kk = hajime; kk < owari; kk++) {
    final SenshuData? s = _kukanNoSenshu(k, kk);
    gyou.add([
      '${kk + 1}区',
      s == null ? '-' : '${fullMei(s.name)}(${s.gakunen})',
      s == null ? '-' : (_kukanMochiTime(k, s, kk) ?? '-'),
      kawatta.contains(kk) ? '当日変更' : '',
    ]);
  }
  return KijiHyou(title, ['区間', '選手', '持ちタイム', ''], gyou);
}

/// 区間[hajime]から[owari]の前までで、当日変更があった区間
List<int> _kawattaKukan(KijiKankyou k, int hajime, int owari) => [
  for (int kk = hajime; kk < owari; kk++)
    if (_hazuretaSenshu(k, kk) != null) kk,
];

/// 入った選手と外れた選手を書く
void _irekaeKaku(KijiKakite w, List<int> kawatta) {
  final KijiKankyou k = w.k;
  final int ks = k.kukansuu;
  final List<SenshuData> hazureta = [];
  for (final int kk in kawatta) {
    final SenshuData? iri = _kukanNoSenshu(k, kk);
    final SenshuData? deta = _hazuretaSenshu(k, kk);
    if (deta != null) hazureta.add(deta);
    if (iri == null) continue;
    w.koMidashi('${kukanYobikata(k.gh, k.race, kk, ks)}　${w.senshu(iri)}');
    w.danraku('当日変更で${kk + 1}区に入った。');
    _shoukai(w, iri, kk);
    w.comment(senshuComment(w, CommentBamen.gakunaiIri, myouji(iri.name)));
  }
  if (hazureta.isNotEmpty) {
    w.koMidashi('仲間に思いを託して');
    final List<String> namae = [for (final SenshuData s in hazureta) w.senshu(s)];
    w.danraku(
      '代わって区間エントリーから外れたのは${namae.join('、')}。'
      'スタートラインに立つ仲間を、チームの一員として送り出す。',
    );
    w.comment(
      senshuComment(w, CommentBamen.gakunaiHazureta, myouji(hazureta.first.name)),
    );
  }
}

Kiji _toujitsu(KijiKankyou k, String site) {
  const int no = 121;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int ks = k.kukansuu;
  // 正月駅伝の1区のスタート前に変えられるのは往路だけ
  final int owari = (k.race == 2 && ks > 5) ? 5 : ks;
  final List<int> kawatta = _kawattaKukan(k, 0, owari);
  final String henkou = k.race == 2 ? '往路の当日変更' : '当日変更';
  String midashi;
  final StringBuffer lead = StringBuffer();
  if (kawatta.isNotEmpty) {
    final SenshuData? iri0 = _kukanNoSenshu(k, kawatta.first);
    midashi = iri0 == null
        ? '$henkouで${kawatta.length}人が入れ替え'
        : '$henkouで${kawatta.length}人が入れ替え　${myouji(iri0.name)}が${kawatta.first + 1}区へ';
    lead.write(
      '${k.taikaiMei}のスタートを前に、$henkouで${kawatta.length}区間の選手が入れ替わった。'
      '新たにたすきを託された選手と、仲間に思いを託した選手を紹介する。',
    );
    _irekaeKaku(w, kawatta);
  } else {
    midashi = w.erabu(['予定どおりの顔ぶれで号砲へ　${k.raceMei}', '$henkouなし　区間エントリーどおりに挑む']);
    lead.write(
      '${k.taikaiMei}のスタートを前に、$henkouは行わず、区間エントリーどおりのメンバーで挑むことが決まった。',
    );
    final SenshuData? s1 = _kukanNoSenshu(k, 0);
    if (s1 != null) {
      w.danraku('1区は${w.senshu(s1)}。チームの流れを作る大役を担う。');
      w.comment(senshuComment(w, _ikigomiBamen(k, s1), myouji(s1.name)));
    }
    w.danraku('選手一人ひとりの紹介は、展望号の選手名鑑で読める。');
  }
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝・スタート直前',
    midashi: midashi,
    lead: lead.toString(),
    kekka: false,
    hyou: [_hashiruHyou(k, '走る選手', 0, ks, kawatta.toSet())],
  );
}

/// 往路(1〜5区)の結果(累計タイムがそろっていなければnull)
({int juni, int saTop, int saNi, bool top, List<int> kukanJuni})? _ouroKekka(
  KijiKankyou k,
  UnivData u,
) {
  const int ouro = 5;
  bool yuukou(UnivData x) =>
      k.shutsujou(x) &&
      x.time_taikai_total.length >= ouro &&
      x.time_taikai_total[ouro - 1] > 0 &&
      x.time_taikai_total[ouro - 1] < TEISUU.DEFAULTTIME;
  if (!yuukou(u)) return null;
  final List<UnivData> list = [for (final UnivData x in k.univ) if (yuukou(x)) x];
  if (list.length < 2) return null;
  list.sort((a, b) => a.time_taikai_total[ouro - 1].compareTo(b.time_taikai_total[ouro - 1]));
  final int juni = list.indexWhere((x) => x.id == u.id);
  final double my = u.time_taikai_total[ouro - 1];
  final int saTop = saByou(my, list.first.time_taikai_total[ouro - 1]);
  final int saNi = saByou(list[1].time_taikai_total[ouro - 1], my);
  // 区間ごとの区間順位(区間タイム=累計の差の順)
  double kukanTime(UnivData x, int kk) => kk == 0
      ? x.time_taikai_total[0]
      : x.time_taikai_total[kk] - x.time_taikai_total[kk - 1];
  final List<int> kukanJuni = [
    for (int kk = 0; kk < ouro; kk++)
      list.where((x) => kukanTime(x, kk) < kukanTime(u, kk)).length,
  ];
  return (juni: juni, saTop: saTop, saNi: saNi, top: juni == 0, kukanJuni: kukanJuni);
}

Kiji? _fukuro(KijiKankyou k, String site, UnivData u) {
  const int no = 131;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int ks = k.kukansuu;
  final ({int juni, int saTop, int saNi, bool top, List<int> kukanJuni})? o =
      _ouroKekka(k, u);
  final List<int> kawatta = _kawattaKukan(k, 5, ks);
  final int fukuroNin = ks - 5;

  String midashi;
  final StringBuffer lead = StringBuffer();
  if (o != null) {
    midashi = o.top
        ? w.erabu(['往路首位で折り返し　復路の$fukuroNin人に託す', '首位で迎える復路　$fukuroNin人の挑戦'])
        : w.erabu([
            '往路は${juniMoji(o.juni)}　復路の$fukuroNin人に託す',
            '往路${juniMoji(o.juni)}から、復路で前へ',
          ]);
    lead.write(
      o.top
          ? '${k.taikaiMei}の往路を、陸上競技部は首位で終えた。2位とは${kinsaMoji(o.saNi)}。'
          : '${k.taikaiMei}の往路を、陸上競技部は${juniMoji(o.juni)}で終えた。トップとは${kinsaMoji(o.saTop)}。',
    );
  } else {
    midashi = '復路の$fukuroNin人に託す　${k.raceMei}';
    lead.write('${k.taikaiMei}は、いよいよ復路を迎える。');
  }
  lead.write('復路を走る$fukuroNin人を紹介する。');

  // 往路の振り返り
  if (o != null) {
    w.koMidashi('往路の振り返り');
    final List<String> l = [];
    for (int kk = 0; kk < 5; kk++) {
      final SenshuData? s = _kukanNoSenshu(k, kk);
      if (s == null) continue;
      l.add('${kk + 1}区${w.senshu(s)}(区間${o.kukanJuni[kk] + 1}位)');
    }
    if (l.isNotEmpty) w.danraku('往路は、${l.join('、')}がたすきをつないだ。');
  }
  // 復路の当日変更
  if (kawatta.isNotEmpty) {
    w.danraku('復路のスタートを前に、当日変更で${kawatta.length}区間の選手が入れ替わった。');
    _irekaeKaku(w, kawatta);
  }
  // 復路を走る選手(当日変更で入った選手は上で紹介した)
  w.koMidashi('復路を走る$fukuroNin人');
  for (int kk = 5; kk < ks; kk++) {
    if (kawatta.contains(kk)) continue;
    final SenshuData? s = _kukanNoSenshu(k, kk);
    if (s == null) continue;
    final String yobi = w.senshu(s);
    final String? mochi = _kukanMochiTime(k, s, kk);
    w.danraku(
      '${kukanYobikata(k.gh, k.race, kk, ks)}は$yobi。'
      '${mochi == null ? '' : '持ちタイムは$mochi。'}'
      '${_maeNoShussouBun(k, s, kk, myouji(s.name))}'
      '${s.gakunen == 4 ? '最後の正月駅伝を走る。' : ''}',
    );
  }
  final SenshuData? anka = _kukanNoSenshu(k, ks - 1);
  if (anka != null && !kawatta.contains(ks - 1)) {
    w.comment(senshuComment(w, _ikigomiBamen(k, anka), myouji(anka.name)));
  }
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝・復路スタート直前',
    midashi: midashi,
    lead: lead.toString(),
    kekka: false,
    hyou: [_hashiruHyou(k, '復路を走る選手', 5, ks, kawatta.toSet())],
  );
}

// ------------------------------------------------------------
// 5. 卒業生特集(3月25日)
// ------------------------------------------------------------

/// 後輩のひと言(同じ区間を走った後輩)。{S}は先輩の名字、{K}は区間
const List<String> _kouhaiOnajiKukan = [
  '{S}さんが走った{K}を、今度は自分が走りたい。{S}さんの背中を追い続けます',
  '{K}の走り方は、全部{S}さんから教わった。その思いをつないでいきたい',
  '{S}さんの{K}の走りは、ずっと目標でした。来年は自分が結果で恩返しします',
];

/// 後輩のひと言(同じ出身地の後輩)。{S}は先輩の名字、{P}は出身地
const List<String> _kouhaiOnajiShusshin = [
  '同じ{P}出身の{S}さんは、入学したときからの目標でした',
  '{S}さんには、地元の話でいつも緊張をほぐしてもらった。寂しくなります',
  '{P}から一緒に出てきた先輩として、ずっと頼りにしていました',
];

/// 卒業生特集(自分の大学の4年生がいなければ空)
List<Kiji> gakunaiSotsugyouKiji(KijiKankyou k) {
  final String? site = gakunaiSiteMeiJibun(k);
  final UnivData? u = k.jibunUniv;
  if (site == null || u == null) return [];
  final List<SenshuData> yonen = [
    for (final SenshuData s in k.senshu)
      if (s.univid == u.id && s.gakunen == 4) s,
  ];
  if (yonen.isEmpty) return [];
  final List<SenshuData> kouhai = [
    for (final SenshuData s in k.senshu)
      if (s.univid == u.id && s.gakunen >= 1 && s.gakunen <= 3) s,
  ];
  const int no = 141;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, 99, no));
  final int n = yonen.length;

  final String midashi = w.erabu([
    'ありがとう、$n人の4年生　4年間の歩み',
    '卒業生特集　たすきに込めた$n人の4年間',
  ]);
  final StringBuffer lead = StringBuffer();
  lead.write('この春、陸上競技部の4年生$n人が卒業する。');
  lead.write('4年間、たすきに思いを込めてきた$n人の歩みを、一人ずつ振り返る。');
  // この代が在学した4年間の正月駅伝の最高順位
  int? saikou;
  for (int i = 0; i < 4; i++) {
    final int j = juniRace(u, 2, i);
    if (shutsujouJuni(j) && (saikou == null || j < saikou)) saikou = j;
  }
  if (saikou != null) {
    lead.write('この4年間の正月駅伝の最高順位は${juniMoji(saikou)}だった。');
  }

  final Set<int> tsukattaKouhai = {};
  final List<List<String>> gyou = [];
  for (final SenshuData s in yonen) {
    final String yobi = myouji(s.name);
    final String? ken = k.shusshin(s);
    w.koMidashi(w.senshu(s));
    // 入学から今までの持ちタイム
    final StringBuffer sb = StringBuffer();
    final double nyuugaku = s.kiroku_nyuugakuji_5000;
    final bool nyuugakuAri = s.hirou != 1 && nyuugaku > 0 && nyuugaku < TEISUU.DEFAULTTIME;
    if (s.hirou == 1) {
      sb.write('留学生として入学し、4年間チームとともに走った。');
    } else if (nyuugakuAri) {
      sb.write('入学時の5000mは${jikanMoji(nyuugaku)}。');
    }
    final List<String> best = [
      for (final int idx in const [0, 1, 2])
        if (k.jikoBest(s, idx) < TEISUU.DEFAULTTIME)
          '${kijiShumokuMei[idx]}${jikanMoji(k.jikoBest(s, idx))}',
    ];
    if (best.isNotEmpty) sb.write('今では${best.join('、')}の自己ベストを持つ。');
    final double best5000 = k.jikoBest(s, 0);
    if (nyuugakuAri && best5000 < TEISUU.DEFAULTTIME) {
      final int chijime = saByou(nyuugaku, best5000);
      if (chijime > 0) sb.write('5000mは入学時から${saMoji(chijime)}縮めた。');
    }
    w.danraku(sb.toString());
    // 駅伝の出走歴(本戦と予選を分けて数える。1.9.3で予選も数えるようにした)
    final List<_Shussou> zenbu = _shussouReki(k, s, imaNozoku: false, yosenMo: true);
    final List<_Shussou> reki = [
      for (final _Shussou x in zenbu)
        if (_honsen(x.race)) x,
    ];
    final List<_Shussou> yosen = [
      for (final _Shussou x in zenbu)
        if (!_honsen(x.race)) x,
    ];
    if (reki.isEmpty && yosen.isEmpty) {
      w.danraku(
        '4年間、駅伝の舞台に立つことはかなわなかった。それでも、練習でもレースの日でも、'
        '$yobiはチームを支え続けた。',
      );
    } else if (reki.isEmpty) {
      w.danraku(
        '本戦の舞台に立つことはかなわなかったが、駅伝予選を${yosen.length}度走り、'
        '本戦への切符を目指してチームのために力を尽くした。'
        '最後の予選は、${_shussouMoji(yosen.last)}だった。',
      );
    } else {
      final StringBuffer sr = StringBuffer();
      final _Shussou hajime = reki.first;
      final _Shussou saigo = reki.last;
      if (reki.length == 1) {
        sr.write('4年間でただ一度の駅伝は、${_shussouMoji(hajime)}だった。');
      } else {
        sr.write(
          '${hajime.gakunen}年の${courseRaceTitle(hajime.race)}で、${hajime.kukan + 1}区を走って駅伝デビュー。',
        );
        sr.write('4年間で駅伝を${reki.length}度走った。');
        sr.write('最後の駅伝は、${_shussouMoji(saigo)}だった。');
      }
      final int kukanshou = reki.where((x) => x.juni == 0).length;
      if (kukanshou > 0) sr.write('区間賞は$kukanshou度獲得した。');
      if (yosen.isNotEmpty) sr.write('駅伝予選も${yosen.length}度走った。');
      w.danraku(sr.toString());
    }
    w.danraku(shusshinShumiBun(k, s, w.r, yobi));
    w.comment(senshuComment(w, CommentBamen.sotsugyou, yobi));
    // 後輩のひと言(同じ区間を走った後輩、いなければ同じ出身地の後輩)
    SenshuData? kh;
    String? kukanMoji;
    // (本戦の区間と、11月駅伝予選の組。正月駅伝予選は全員が同じ1区間なので数えない)
    for (final _Shussou x in zenbu) {
      if (x.race == 4) continue;
      for (final SenshuData t in kouhai) {
        if (tsukattaKouhai.contains(t.id)) continue;
        if (_shussouReki(k, t, imaNozoku: false, yosenMo: true)
            .any((y) => y.race == x.race && y.kukan == x.kukan)) {
          kh = t;
          kukanMoji = '${courseRaceTitle(x.race)}の${x.kukan + 1}${x.race == 3 ? '組' : '区'}';
          break;
        }
      }
      if (kh != null) break;
    }
    String? kouhaiBun;
    if (kh != null && kukanMoji != null) {
      kouhaiBun = w
          .erabu(_kouhaiOnajiKukan)
          .replaceAll('{S}', yobi)
          .replaceAll('{K}', kukanMoji);
    } else if (ken != null) {
      for (final SenshuData t in kouhai) {
        if (tsukattaKouhai.contains(t.id)) continue;
        if (k.shusshin(t) == ken) {
          kh = t;
          break;
        }
      }
      if (kh != null) {
        kouhaiBun = w
            .erabu(_kouhaiOnajiShusshin)
            .replaceAll('{S}', yobi)
            .replaceAll('{P}', ken);
      }
    }
    if (kh != null && kouhaiBun != null) {
      tsukattaKouhai.add(kh.id);
      w.comment('「$kouhaiBun」と、後輩の${w.senshu(kh)}は先輩を送り出した。');
    }
    // 表の行
    int? saikouKukan;
    for (final _Shussou x in reki) {
      final int? j = x.juni;
      if (j != null && (saikouKukan == null || j < saikouKukan)) saikouKukan = j;
    }
    gyou.add([
      fullMei(s.name),
      ken ?? (s.hirou == 1 ? '留学生' : '-'),
      _mochiTimeMoji(k, s, 0)?.replaceFirst('5000m', '') ?? '-',
      _mochiTimeMoji(k, s, 1)?.replaceFirst('1万m', '') ?? '-',
      '${reki.length}回',
      '${yosen.length}回',
      saikouKukan == null ? '-' : '区間${saikouKukan + 1}位',
    ]);
  }
  w.comment(kantokuComment(w, KantokuBamen.sotsugyou, u.id));
  w.danraku('4年生の皆さん、4年間お疲れさまでした。新しい場所での活躍を、陸上競技部の後輩たちと一緒に応援しています。');
  return [
    Kiji(
      category: '卒業生特集',
      midashi: midashi,
      lead: lead.toString(),
      honbun: w.honbun,
      hyou: [
        KijiHyou(
          '卒業する4年生',
          ['選手', '出身', '5000m', '1万m', '駅伝', '駅伝予選', '最高区間順位'],
          gyou,
        ),
      ],
      haishin: k.haishinMei(no, asa: true),
      kisha: _kishaMei(k, site, no),
      jibun: true,
      kekka: true,
      site: site,
      gakunai: true,
    ),
  ];
}

// ------------------------------------------------------------
// 6. 駅伝予選(11月駅伝予選・正月駅伝予選)の結果号と展望号
// ------------------------------------------------------------

/// 選手[s]の、大会[race]の去年のタイム(なければnull)
double? _kyonenTime(SenshuData s, int race) {
  final int g = s.gakunen - 2;
  if (g < 0 || s.kukantime_race.length <= race) return null;
  if (s.kukantime_race[race].length <= g) return null;
  final double t = s.kukantime_race[race][g];
  return (t > 0 && t < TEISUU.DEFAULTTIME) ? t : null;
}

/// 予選で比べる持ちタイムの種目(11月駅伝予選は1万m、正月駅伝予選はハーフ)
int _yosenShumoku(KijiKankyou k) => k.race == 3 ? 1 : 2;

/// 予選の本戦の名前
String _yosenHonsenMei(KijiKankyou k) => k.race == 3 ? '11月駅伝' : '正月駅伝';

/// 通過する大学の数(kiji_yosen.dart の YosenKekka と同じ)
int _yosenTsuukaSuu(KijiKankyou k) => k.race == 3 ? 7 : 10;

/// 記事にする予選より前に、予選を走ったことがあるか
bool _yosenKeiken(KijiKankyou k, SenshuData s) =>
    _shussouReki(k, s, imaNozoku: true, yosenMo: true)
        .any((x) => !_honsen(x.race));

/// 予選の結果号(自分の大学が出ていなければ空)
List<Kiji> _yosenKekkaKiji(KijiKankyou k, String site) {
  final YosenKekka? e = YosenKekka.tsukuru(k);
  if (e == null) return [];
  final YosenUnivKekka? m = e.jibun;
  if (m == null) return [];
  return [_yosenTop(e, m, site), _yosenZenin(e, m, site)];
}

/// 通過ラインとの差(通過したときは次点との差、落選したときは最後の通過校との差。
/// 通過ラインの争いがなければnull)
({int sa, YosenUnivKekka aite})? _yosenSa(YosenKekka e, YosenUnivKekka m) {
  if (!e.borderAri) return null;
  final int ts = e.tsuukaSuu;
  if (e.tsuuka(m)) {
    final YosenUnivKekka aite = e.jun[ts];
    return (sa: saByou(aite.time, m.time), aite: aite);
  }
  final YosenUnivKekka aite = e.jun[ts - 1];
  return (sa: saByou(m.time, aite.time), aite: aite);
}

Kiji _yosenTop(YosenKekka e, YosenUnivKekka m, String site) {
  final KijiKankyou k = e.k;
  const int no = 151;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final int r = m.juni;
  final int ts = e.tsuukaSuu;
  final bool tsuuka = e.tsuuka(m);
  final String honsen = e.honsenMei;
  final int nin = e.keisanNinzuu;
  final bool hatsuHonsen =
      !e.honsenMikaisai && shutsujouKaisuu(m.u, e.honsen) == 0;
  final ({int sa, YosenUnivKekka aite})? sa = _yosenSa(e, m);
  final bool kinsa = sa != null && sa.sa <= e.jitenSaJougen;
  final bool hatsuKaisai = hatsuKaisaiKekka(k, k.race);
  final int mae = juniRace(m.u, k.race, 1);
  final bool maeAri = !hatsuKaisai && shutsujouJuni(mae);

  // 見出し
  String midashi;
  if (tsuuka) {
    if (r == 0) {
      midashi = '$honsen予選をトップ通過！';
    } else if (hatsuHonsen) {
      midashi = w.erabu([
        '悲願の初出場！　$honsenへの切符をつかむ',
        '$honsenに初出場決める　予選${juniMoji(r)}',
      ]);
    } else {
      midashi = w.erabu([
        '$honsenへの切符をつかんだ！　予選${juniMoji(r)}',
        '予選突破！　$honsen出場決める',
      ]);
    }
  } else if (sa != null && kinsa) {
    midashi = '${kinsaMoji(sa.sa)}届かず　$honsen予選${juniMoji(r)}';
  } else {
    midashi = w.erabu([
      '$honsen予選は${juniMoji(r)}　悔しさを来年へ',
      '予選${juniMoji(r)}、本戦には届かず　それでも前へ',
    ]);
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write('${k.taikaiMei}に挑んだ陸上競技部は、合計${jikanMoji(m.time)}の${juniMoji(r)}となり、');
  lead.write(
    tsuuka
        ? '$honsenへの${hatsuHonsen ? '初めての' : ''}出場を決めた。'
        : '上位$ts校に与えられる$honsenへの出場権には届かなかった。',
  );
  if (sa != null) {
    if (tsuuka) {
      lead.write(
        '${r == ts - 1 ? 'ぎりぎりの通過で、' : ''}次点の${sa.aite.mei}とは${kinsaMoji(sa.sa)}だった。',
      );
    } else {
      lead.write(
        '通過ラインの${sa.aite.mei}とは${kinsaMoji(sa.sa)}。'
        '合計に入る$nin人で割れば、${hitoriAtariMoji(sa.sa, nin)}だった。',
      );
    }
  }
  if (maeAri) {
    if (mae > r) {
      lead.write('前回の予選の${juniMoji(mae)}から${mae - r}つ順位を上げた。');
    } else if (mae == r) {
      lead.write('前回と同じ${juniMoji(r)}だった。');
    } else {
      lead.write('前回の予選は${juniMoji(mae)}だった。');
    }
  }

  // 本文
  w.koMidashi('レースを振り返って');
  if (k.race == 3) {
    final List<String> suii = [
      for (int kk = 0; kk < e.ks; kk++) juniMoji(m.tuuka[kk]),
    ];
    w.danraku('組を終えるごとのチームの順位は、${suii.join('→')}と推移した。');
    YosenSenshuKekka? best;
    for (final YosenSenshuKekka y in m.senshu) {
      if (best == null || y.juni < best.juni) best = y;
    }
    if (best != null) {
      w.danraku('${best.kumi + 1}組の${w.senshu(best.s)}が組${best.juni + 1}位と、チームを引っ張った。');
    }
  } else if (m.senshu.isNotEmpty) {
    final YosenSenshuKekka top = m.senshu.first;
    w.danraku('${w.senshu(top.s)}が全体${top.juni + 1}位でチームトップだった。');
    if (m.senshu.length >= nin) {
      final YosenSenshuKekka s10 = m.senshu[nin - 1];
      w.danraku('合計に入る$nin番手は${w.senshu(s10.s)}で、全体${s10.juni + 1}位だった。');
    }
  }
  w.comment(
    kantokuComment(
      w,
      tsuuka
          ? KantokuBamen.yosenTsuuka
          : (kinsa ? KantokuBamen.yosenJiten : KantokuBamen.yosenRakusen),
      m.u.id,
      kuyashii: !tsuuka,
    ),
  );
  w.danraku('走った${m.senshu.length}人の一人ひとりの走りは、別の記事「全員の走り」で振り返る。');
  w.danraku(
    tsuuka
        ? '本戦の$honsenでも、このチームの走りから目が離せない。'
        : '悔しさを胸に、チームはまた一から積み上げる。',
  );

  final List<List<String>> gyou = [
    ['順位', juniMoji(r)],
    ['合計タイム', jikanMoji(m.time)],
    if (sa != null) [tsuuka ? '次点との差' : '通過ラインとの差', saMoji(sa.sa)],
    if (maeAri) ['前回の予選', juniMoji(mae)],
  ];
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝予選',
    midashi: midashi,
    lead: lead.toString(),
    kekka: true,
    hyou: [KijiHyou('${k.taikaiMei}の結果', ['項目', '結果'], gyou)],
  );
}

Kiji _yosenZenin(YosenKekka e, YosenUnivKekka m, String site) {
  final KijiKankyou k = e.k;
  const int no = 152;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final bool kumiAri = k.race == 3;
  final bool tsuuka = e.tsuuka(m);
  final ({int sa, YosenUnivKekka aite})? sa = _yosenSa(e, m);
  final bool kinsa = sa != null && sa.sa <= e.jitenSaJougen;
  final int nin = e.keisanNinzuu;
  final int idx = _yosenShumoku(k);
  // 11月駅伝予選は組の順(組の中はタイム順)、正月駅伝予選はチームの中の順
  final List<YosenSenshuKekka> list = List<YosenSenshuKekka>.of(m.senshu);
  if (kumiAri) {
    list.sort((a, b) {
      final int c = a.kumi.compareTo(b.kumi);
      return c != 0 ? c : a.time.compareTo(b.time);
    });
  }
  final int n = list.length;
  final String midashi = kumiAri
      ? w.erabu([
          '組ごとに振り返る　${e.honsenMei}予選を走った$n人',
          '$n人の走りを振り返る　${e.honsenMei}予選',
        ])
      : w.erabu([
          '全員の走りを振り返る　正月駅伝予選を駆けた$n人',
          '$n人の走りを振り返る　正月駅伝予選',
        ]);
  final String lead =
      '${k.taikaiMei}を走った$n人の走りを、${kumiAri ? '1組から順に' : 'チームの中の順に'}振り返る。';

  final List<List<String>> gyou = [];
  for (final YosenSenshuKekka y in list) {
    final SenshuData s = y.s;
    if (kumiAri) {
      w.koMidashi('${y.kumi + 1}組　${w.senshu(s)}');
    } else {
      w.koMidashi('${y.univJuni + 1}番手　${w.senshu(s)}');
    }
    final String yobi = w.senshu(s);
    final StringBuffer sb = StringBuffer();
    if (kumiAri) {
      sb.write('$yobiは組${y.juni + 1}位、${jikanMoji(y.time)}で走った。');
      if (y.juni == 0) sb.write('組トップの快走だった。');
    } else {
      sb.write('$yobiは全体${y.juni + 1}位、${jikanMoji(y.time)}でゴールした。');
      if (y.juni == 0) sb.write('全体トップの快走だった。');
      if (y.univJuni >= nin) sb.write('チームの合計には入らなかったが、最後まで走り抜いた。');
    }
    if (e.shinkiroku(s)) sb.write(kumiAri ? '組の新記録だった。' : '大会新記録だった。');
    final double jiko = k.jikoBest(s, idx);
    if (jiko < TEISUU.DEFAULTTIME && byou(y.time) < byou(jiko)) {
      sb.write('${kijiShumokuMei[idx]}の自己ベスト(${jikanMoji(jiko)})を上回るタイムだった。');
    }
    final int maeE = k.entryMae(s, k.race, 1);
    final double? kt = _kyonenTime(s, k.race);
    if (maeE >= 0 && kt != null) {
      final int d = saByou(kt, y.time);
      if (d > 0) {
        sb.write('昨年の予選より${saMoji(d)}速く、1年間の成長を示した。');
      } else if (d == 0) {
        sb.write('昨年の予選とほぼ同じタイムだった。');
      } else {
        sb.write('昨年の予選のタイムには届かなかったが、この経験は次につながる。');
      }
    } else if (!k.ichinenDake && !_yosenKeiken(k, s)) {
      sb.write('これが初めての予選だった。');
    }
    if (s.gakunen == 4) {
      if (kumiAri) {
        sb.write('4年生として最後の11月駅伝予選だった。');
      } else {
        sb.write(
          tsuuka
              ? '最後の正月駅伝予選で、本戦への切符をつかんだ。'
              : '本戦へのラストチャンスだった正月駅伝予選を、最後まで走り切った。',
        );
      }
    }
    w.danraku(sb.toString());
    w.danraku(shusshinShumiBun(k, s, w.r, myouji(s.name)));
    // コメント
    CommentBamen bamen;
    bool kuyashii = false;
    if (y.juni == 0) {
      bamen = CommentBamen.yosenKojinTop;
    } else if (s.gakunen == 4) {
      bamen = CommentBamen.yonenSaigo;
    } else if (y.univJuni == 0) {
      bamen = tsuuka
          ? CommentBamen.yosenTsuuka
          : (kinsa ? CommentBamen.yosenJiten : CommentBamen.yosenRakusen);
      kuyashii = !tsuuka;
    } else {
      bamen = CommentBamen.gakunaiYosen;
    }
    w.comment(senshuComment(w, bamen, myouji(s.name), kuyashii: kuyashii));
    gyou.add([
      kumiAri ? '${y.kumi + 1}組' : '${y.univJuni + 1}',
      '${fullMei(s.name)}(${s.gakunen})',
      kumiAri ? '組${y.juni + 1}位' : '${y.juni + 1}位',
      jikanMoji(y.time),
      kt != null && maeE >= 0 ? jikanMoji(kt) : '-',
    ]);
  }
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝予選',
    midashi: midashi,
    lead: lead,
    kekka: true,
    hyou: [
      KijiHyou(
        '全員の成績',
        [kumiAri ? '組' : '番手', '選手', kumiAri ? '組順位' : '全体順位', 'タイム', '昨年'],
        gyou,
      ),
    ],
  );
}

/// 予選の展望号(走る選手が決まっていなければ空)
List<Kiji> _yosenTenbouKiji(KijiKankyou k, String site, UnivData u) {
  final int ks = k.kukansuu;
  final List<SenshuData> hashiru = _jibunSenshu(k, (e) => e >= 0 && e < ks);
  if (hashiru.isEmpty) return [];
  final int idx = _yosenShumoku(k);
  // 11月駅伝予選は組の順、組の中と正月駅伝予選は持ちタイムの順(記録のない選手は後ろ)
  hashiru.sort((a, b) {
    final int c = k.race == 3 ? k.entry(a).compareTo(k.entry(b)) : 0;
    return c != 0 ? c : k.jikoBest(a, idx).compareTo(k.jikoBest(b, idx));
  });
  final List<Kiji> list = [_yosenMeikan(k, site, u, hashiru)];
  final Kiji? t = _yosenTokushuu(k, site, hashiru);
  if (t != null) list.add(t);
  return list;
}

Kiji _yosenMeikan(
  KijiKankyou k,
  String site,
  UnivData u,
  List<SenshuData> hashiru,
) {
  const int no = 161;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final bool kumiAri = k.race == 3;
  final String honsen = _yosenHonsenMei(k);
  final int idx = _yosenShumoku(k);
  final int n = hashiru.length;
  final String midashi = w.erabu([
    '$honsen予選へ　$n人の選手名鑑',
    '$honsenへの切符をかけて　予選を走る$n人',
  ]);
  final StringBuffer lead = StringBuffer();
  lead.write('${k.taikaiMei}を走る$n人が決まった。$honsenへの切符をかけて走る$n人を紹介する。');
  final int mae = juniRace(u, k.race, 0);
  if (!mikaisai(k, k.race) && shutsujouJuni(mae)) {
    lead.write(
      mae < _yosenTsuukaSuu(k)
          ? '前回の予選は${juniMoji(mae)}で通過している。'
          : '前回の予選は${juniMoji(mae)}で、通過ラインに届かなかった。',
    );
  }
  for (final SenshuData s in hashiru) {
    final int kk = k.entry(s);
    w.koMidashi(kumiAri ? '${kk + 1}組　${w.senshu(s)}' : w.senshu(s));
    final String yobi = myouji(s.name);
    final StringBuffer sb = StringBuffer();
    final String? mochi = _kukanMochiTime(k, s, kk);
    if (mochi != null) sb.write('持ちタイムは$mochi。');
    sb.write(_konkiNoBun(k, s, kk));
    final List<_Shussou> zenbu = _shussouReki(k, s, imaNozoku: true, yosenMo: true);
    final int yosenKai = zenbu.where((x) => !_honsen(x.race)).length;
    final int honsenKai = zenbu.where((x) => _honsen(x.race)).length;
    final int maeE = k.entryMae(s, k.race, 1);
    if (maeE >= 0) {
      final _Shussou x = _Shussou(k.race, s.gakunen - 1, maeE, k.kukanJuniMae(s, k.race, 1));
      final double? kt = _kyonenTime(s, k.race);
      sb.write('昨年は${_shussouMoji(x)}を走った${kt == null ? '' : '(${jikanMoji(kt)})'}。');
    }
    if (yosenKai == 0) {
      if (!k.ichinenDake) sb.write('$yobiにとって、これが初めての予選となる。');
    } else {
      sb.write('予選は${yosenKai + 1}度目。');
    }
    if (honsenKai > 0) sb.write('駅伝の本戦も$honsenKai度走っている。');
    if (s.gakunen == 4) {
      sb.write(
        kumiAri ? '4年生にとっては、これが最後の11月駅伝予選だ。' : '最後の正月駅伝予選。本戦へのラストチャンスに挑む。',
      );
    }
    w.danraku(sb.toString());
    w.danraku(shusshinShumiBun(k, s, w.r, yobi));
    w.comment(
      senshuComment(
        w,
        s.gakunen == 4 ? CommentBamen.gakunaiYonenIkigomi : CommentBamen.gakunaiYosenIkigomi,
        yobi,
      ),
    );
  }
  w.comment(kantokuComment(w, KantokuBamen.tenbouChousen, u.id));

  final List<List<String>> gyou = [];
  for (int i = 0; i < hashiru.length; i++) {
    final SenshuData s = hashiru[i];
    final int yosenKai = _shussouReki(k, s, imaNozoku: true, yosenMo: true)
        .where((x) => !_honsen(x.race))
        .length;
    gyou.add([
      kumiAri ? '${k.entry(s) + 1}組' : '${i + 1}',
      '${fullMei(s.name)}(${s.gakunen})',
      k.shusshin(s) ?? (s.hirou == 1 ? '留学生' : '-'),
      _mochiTimeMoji(k, s, idx)?.replaceFirst(kijiShumokuMei[idx], '') ?? '-',
      yosenKai == 0 ? '初' : '${yosenKai + 1}度目',
    ]);
  }
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝予選・展望',
    midashi: midashi,
    lead: lead.toString(),
    kekka: false,
    hyou: [
      KijiHyou(
        '選手名鑑',
        [kumiAri ? '組' : '', '選手', '出身', kijiShumokuMei[idx], '予選'],
        gyou,
      ),
    ],
  );
}

/// 予選の、4年生と初めて予選を走る選手の特集(どちらもいなければnull)
Kiji? _yosenTokushuu(KijiKankyou k, String site, List<SenshuData> hashiru) {
  const int no = 162;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final bool kumiAri = k.race == 3;
  final List<SenshuData> yonen = [
    for (final SenshuData s in hashiru)
      if (s.gakunen == 4) s,
  ];
  final List<SenshuData> hatsu = [
    for (final SenshuData s in hashiru)
      if (s.gakunen != 4 && !k.ichinenDake && !_yosenKeiken(k, s)) s,
  ];
  if (yonen.isEmpty && hatsu.isEmpty) return null;
  String namae(SenshuData s) =>
      kumiAri ? '${k.entry(s) + 1}組の${w.senshu(s)}' : w.senshu(s);
  final String midashi = yonen.isNotEmpty
      ? (kumiAri
            ? '4年生${yonen.length}人、最後の11月駅伝予選へ'
            : '本戦へのラストチャンス　4年生${yonen.length}人の思い')
      : '初めての予選へ　${hatsu.length}人の挑戦';
  final List<String> bu = [
    if (yonen.isNotEmpty) '最後の予選に挑む4年生',
    if (hatsu.isNotEmpty) '初めて予選を走る選手',
  ];
  final String lead = '${k.taikaiMei}に挑む選手のうち、${bu.join('と、')}を紹介する。';
  if (yonen.isNotEmpty) {
    w.koMidashi('4年生');
    w.danraku(
      '${[for (final SenshuData s in yonen) namae(s)].join('、')}は、'
      '${kumiAri ? '最後の11月駅伝予選に挑む。' : '最後の正月駅伝予選に挑む。本戦の舞台に立てる、最後の機会だ。'}',
    );
    w.comment(senshuComment(w, CommentBamen.gakunaiYonenIkigomi, myouji(yonen.last.name)));
  }
  if (hatsu.isNotEmpty) {
    w.koMidashi('初めての予選');
    w.danraku(
      '${[for (final SenshuData s in hatsu) namae(s)].join('、')}は、これが初めての予選になる。'
      '新しい力が、チームの合計を押し上げる。',
    );
    w.comment(senshuComment(w, CommentBamen.gakunaiYosenIkigomi, myouji(hatsu.first.name)));
  }
  return _kansei(
    k,
    site,
    no,
    w,
    category: '駅伝予選・展望',
    midashi: midashi,
    lead: lead,
    kekka: false,
  );
}
