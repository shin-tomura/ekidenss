import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/screens/Modal_courseshoukai.dart'; // 大会の名前(courseRaceTitle)
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_comment.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart' show EkidenKekka, EkidenUnivKekka;
import 'package:ekiden/kansuu/kiji/kiji_yosen.dart'
    show YosenKekka, YosenUnivKekka, YosenSenshuKekka;
import 'package:ekiden/kansuu/kiji/kiji_taikousen.dart'
    show
        TaikousenKekka,
        TaikousenUnivKekka,
        TaikousenSenshuKekka,
        taikousenSougouMeisei,
        taikousenKojinMeisei,
        taikousenMeiseiHikaku;

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
//  7. 対校戦の結果号(5000m・1万m・ハーフの種目ごとの結果画面): 8位以内の入賞者全員と、
//     チーム内3位までの選手と、昨年の同じ種目から一番順位を上げた「伸び盛り」の選手を紹介する。
//     ハーフのあとは、3種目を合わせた総合の記事も先に置く。成長は昨年の同じ種目との比べで伝え、
//     昨年のない1年生は、5000mだけ入学時の記録と比べる。対校戦の総合は8位まででも名声が大きいので、
//     5000m・1万mのあとは「総合争い」(8位のラインとの点差と名声の大きさ)を書き、
//     ハーフのあとの総合の記事には、大学が得た名声を書く
//
// 守る決まり(箱庭スポーツと同じ)
//  ・能力値は書かない(見抜く力の仕組みを壊さないため)。成長タイプ・上限・サプライズも書かない
//    (伸びたことは、持ちタイムや区間順位など見えている事実からだけ書く)
//  ・総監督(プレイヤー)の言葉は作らない。当日変更の理由も書かない(決めたのは総監督なので)
//  ・趣味は、趣味非表示設定のときは書かない
//  ・文体は常体だが、学内メディアらしく選手に寄り添う温かい言い方にする(苦しんだ区間も前向きに書く)
//  ・「自己ベストを更新した」「今季、自己ベストを更新している」とは書かない(選手は毎年伸びるので、
//    ほとんどの選手に付いてしまい、特別なことに聞こえないため。1年生には初めての記録のこともある)。
//    予選は自己ベストに数えないので、予選のタイムが自己ベストを上回ったときだけは書く
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

/// 駅伝と駅伝予選と対校戦の結果号(自分の大学が出ていなければ空)
List<Kiji> gakunaiKekkaKiji(KijiKankyou k) {
  if (k.race == 3 || k.race == 4) {
    final String? site = gakunaiSiteMeiJibun(k);
    return site == null ? [] : _yosenKekkaKiji(k, site);
  }
  if (k.taikousen) {
    final String? site = gakunaiSiteMeiJibun(k);
    return site == null ? [] : _taikousenKiji(k, site);
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

// ------------------------------------------------------------
// 7. 対校戦の結果号(種目ごとの記事と、ハーフのあとの総合の記事)
// ------------------------------------------------------------

/// 対校戦の名声のかかる(入賞の)順位の数(個人・総合とも8位まで。kiji_taikousen.dart と同じ)
const int _taikousenNyuushouSuu = 8;

/// 対校戦の総合の記録の番号(UnivData.juni_race・mokuhyojuni・taikaibetujunibetukaisuu の番号)
const int _taikousenSougou = 9;

/// 種目の記事で紹介する、チーム内の上位の人数(入賞者がこれより多ければ、入賞者を全員紹介する)
const int _taikousenShoukaiSuu = 3;

/// 大学[u]の対校戦の総合の目標順位(0が1位。全大学とも8位。[n] 大学の数)
int _taikousenMokuhyou(UnivData u, int n) =>
    (u.mokuhyojuni.length > _taikousenSougou &&
        u.mokuhyojuni[_taikousenSougou] >= 0 &&
        u.mokuhyojuni[_taikousenSougou] < n)
    ? u.mokuhyojuni[_taikousenSougou]
    : _taikousenNyuushouSuu - 1;

/// 5000m・1万mのあとの、総合争いの文(今の総合順位・8位のラインとの点差・名声の大きさ)
String _taikousenSougouArasoiBun(TaikousenKekka e, TaikousenUnivKekka m) {
  final int sh = e.shumoku;
  final int n = e.n;
  final int r = m.juni;
  final int mk = _taikousenMokuhyou(m.u, n);
  final String nokori = sh == 0 ? '残る1万mとハーフ' : '最終種目のハーフ';
  // 残りの種目を走る延べ人数(対校戦は全員が3種目を走るので、この種目の人数×残りの種目の数)
  final int nobe = sh <= 1 ? m.ninzuu[sh] * (2 - sh) : 0;
  final StringBuffer sb = StringBuffer();
  sb.write('総合のポイントは、出場した全員の順位で決まる。');
  sb.write('${kijiShumokuMei[sh]}を終えて、陸上競技部は${m.goukei}点で総合${juniMoji(r)}。');
  if (r == 0) {
    final TaikousenUnivKekka ni = e.jun[1];
    sb.write('首位に立っている。2位の${ni.mei}とは${_tensa(m.goukei - ni.goukei)}。');
  } else if (r <= mk) {
    sb.write('目標の${juniMoji(mk)}以内につけている。');
    if (mk + 1 < n) {
      final TaikousenUnivKekka soto = e.jun[mk + 1];
      sb.write('${juniMoji(mk + 1)}の${soto.mei}とは${_tensa(m.goukei - soto.goukei)}。');
    }
  } else {
    final TaikousenUnivKekka line = e.jun[mk];
    final int sa = line.goukei - m.goukei;
    sb.write('目標の${juniMoji(mk)}の${line.mei}とは${_tensa(sa)}。');
    if (sa > 0 && nobe > 0) {
      final int x = (sa + nobe - 1) ~/ nobe;
      sb.write(
        '$nokoriを走る${sh == 0 ? '延べ' : ''}$nobe人が、1人あたり${_tsu(x)}ずつ順位を上げれば届く計算だ。',
      );
    }
  }
  final String? hikaku = taikousenMeiseiHikaku(e.k, _taikousenNyuushouSuu - 1);
  if (hikaku != null) {
    sb.write('総合の名声は8位まで与えられ、8位の名声でも、$hikaku。');
  }
  return sb.toString();
}

/// 対校戦の結果号(種目ごとの記事。ハーフのあとは総合の記事を先に置く。
/// 自分の大学の選手が走っていなければ空)
List<Kiji> _taikousenKiji(KijiKankyou k, String site) {
  final TaikousenKekka? e = TaikousenKekka.tsukuru(k);
  if (e == null) return [];
  final TaikousenUnivKekka? m = e.jibun;
  if (m == null) return [];
  // 自分の大学の選手の結果(全体の順位の順)
  final List<TaikousenSenshuKekka> mine = [
    for (final TaikousenSenshuKekka x in e.kojin)
      if (x.s.univid == m.u.id) x,
  ];
  if (mine.isEmpty) return [];
  final Kiji shumoku = _taikousenShumokuKiji(e, m, mine, site);
  if (!e.saigo) return [shumoku];
  return [_taikousenSougouKiji(e, m, site), shumoku];
}

/// 点差の言い方(同点なら「同点」)
String _tensa(int sa) => sa <= 0 ? '同点' : '$sa点差';

/// 順位をいくつ上げたかの数の言い方(9までは「3つ」、10からは「12」)
String _tsu(int d) => d < 10 ? '$dつ' : '$d';

/// 1年生の5000mの、入学時の記録との比べの一言(入学時の記録より速いときだけ。なければ空)
/// (昨年の対校戦がない1年生の、昨年との比べの代わり。留学生には入学時の記録がない)
String _nyuugakuHikakuBun(SenshuData s, double time) {
  if (s.gakunen != 1 || s.hirou == 1) return '';
  final double nyuugaku = s.kiroku_nyuugakuji_5000;
  if (nyuugaku <= 0 || nyuugaku >= TEISUU.DEFAULTTIME) return '';
  final int d = saByou(nyuugaku, time);
  if (d <= 0) return '';
  return '入学時の記録(${jikanMoji(nyuugaku)})より${saMoji(d)}速いタイムだった。';
}

/// 小見出しに出す選手の名前(「山田太郎(2年)」)。本文では2回目からの呼び方(名字)で書けるように、
/// 名前を出したことにしておく
String _koMidashiMei(KijiKakite w, SenshuData s) {
  w.senshu(s);
  return '${fullMei(s.name)}(${s.gakunen}年)';
}

/// 対校戦の種目の記事(入賞者全員と、チーム内3位までの選手と、伸び盛りの選手を紹介する)
Kiji _taikousenShumokuKiji(
  TaikousenKekka e,
  TaikousenUnivKekka m,
  List<TaikousenSenshuKekka> mine,
  String site,
) {
  final KijiKankyou k = e.k;
  final int sh = e.shumoku;
  final int no = 171 + sh;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final String sm = kijiShumokuMei[sh];
  final TaikousenSenshuKekka top = mine.first;
  final String topMei = myouji(top.s.name);
  final int nyuushou = mine
      .where((x) => x.juni < _taikousenNyuushouSuu)
      .length;
  // 紹介する選手(入賞者全員と、チーム内3位まで。どちらも全体の順位の順の先頭から並ぶ)
  final int shoukaiSuu = nyuushou > _taikousenShoukaiSuu
      ? nyuushou
      : _taikousenShoukaiSuu;
  final List<TaikousenSenshuKekka> shoukai = mine.take(shoukaiSuu).toList();
  // 伸び盛り(昨年の同じ種目から一番順位を上げた選手。同じなら今回の順位が上の選手)
  TaikousenSenshuKekka? nobiKouho;
  int nobiSa = 0;
  for (final TaikousenSenshuKekka x in mine) {
    final int? kj = k.kukanJuniMae(x.s, k.race, 1);
    if (kj == null) continue;
    if (kj - x.juni > nobiSa) {
      nobiSa = kj - x.juni;
      nobiKouho = x;
    }
  }
  final TaikousenSenshuKekka? nobi = nobiKouho;
  final int nobiId = nobi == null ? -1 : nobi.s.id;
  // 伸び盛りの選手が、入賞者・チーム内3位までに入っていないか(入っていなければ別に紹介する)
  final bool nobiBetsu =
      nobi != null && !shoukai.any((x) => x.s.id == nobiId);

  // 見出し
  String midashi;
  if (top.juni == 0) {
    midashi = w.erabu(['$topMeiが$sm優勝！', '$smを制した！　$topMeiが頂点に']);
    if (nyuushou >= 2) midashi += '　$nyuushou人が入賞';
  } else if (nyuushou >= 2) {
    midashi = w.erabu(['$smで$nyuushou人が入賞！', '$smに$nyuushou人の入賞者']);
  } else if (nyuushou == 1) {
    midashi = w.erabu([
      '$topMeiが$sm${juniMoji(top.juni)}入賞',
      '$sm、$topMeiが${juniMoji(top.juni)}で入賞',
    ]);
  } else {
    midashi = w.erabu([
      '$smは$topMeiがチームトップの${juniMoji(top.juni)}',
      '$sm、$topMeiが全体${juniMoji(top.juni)}でチームを引っ張る',
    ]);
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write('${k.taikaiMei}の$smが行われ、陸上競技部からは${mine.length}人が出場した。');
  if (top.juni == 0) {
    lead.write('${w.senshu(top.s)}が${jikanMoji(top.time)}で優勝を飾った。');
  } else if (top.juni < _taikousenNyuushouSuu) {
    lead.write('チームトップの${w.senshu(top.s)}が全体${juniMoji(top.juni)}に入り、入賞を果たした。');
  } else {
    lead.write('チームトップは全体${juniMoji(top.juni)}の${w.senshu(top.s)}だった。');
  }
  if (nyuushou >= 2) {
    lead.write('名声のかかる8位以内には、チームから$nyuushou人が入った。');
  } else if (nyuushou == 0) {
    lead.write('8位以内の入賞には届かなかったが、全員が1つでも前を目指して走った。');
  }
  lead.write(
    'この種目の大学のポイントは${m.point[sh]}点で、大学別${juniMoji(e.shumokuJuni(m, sh))}。',
  );
  lead.write(
    e.saigo
        ? '3種目を合わせた総合は${juniMoji(m.juni)}だった。'
        : 'ここまでの総合は${juniMoji(m.juni)}につけている。',
  );

  // 本文: 紹介する選手(全体の順位の順)
  for (int i = 0; i < shoukai.length; i++) {
    final TaikousenSenshuKekka x = shoukai[i];
    final String mei = _koMidashiMei(w, x.s);
    if (x.juni == 0) {
      w.koMidashi('優勝　$mei');
    } else if (x.juni < _taikousenNyuushouSuu) {
      w.koMidashi('${juniMoji(x.juni)}入賞　$mei');
    } else {
      w.koMidashi('${i == 0 ? 'チームトップ' : 'チーム${i + 1}番手'}　$mei');
    }
    _taikousenSenshuKaku(
      w,
      e,
      x,
      i,
      nobiSa: x.s.id == nobiId ? nobiSa : null,
    );
  }
  // 本文: 伸び盛りの選手(上で紹介していなければ)
  if (nobi != null && nobiBetsu) {
    w.koMidashi('伸び盛り　${_koMidashiMei(w, nobi.s)}');
    _taikousenSenshuKaku(w, e, nobi, mine.indexOf(nobi), nobiSa: nobiSa);
  }

  // 本文: 総合争い(5000m・1万mのあと)・チームのポイント(ハーフのあと)
  final int hoka = mine.length - shoukai.length - (nobiBetsu ? 1 : 0);
  final StringBuffer pt = StringBuffer();
  if (e.saigo) {
    w.koMidashi('チームのポイント');
    pt.write('この種目のポイントは、出場した全員の順位で決まる。');
  } else {
    w.koMidashi('総合争い');
    w.danraku(_taikousenSougouArasoiBun(e, m));
  }
  if (hoka > 0) {
    pt.write('ほかの$hoka人も、1つでも前を目指して走り切った。全員の成績は下の表のとおり。');
  }
  pt.write(
    sh == 0
        ? '対校戦は、このあと1万m、ハーフと続く。'
        : (sh == 1
              ? '最終種目のハーフへ、チームの戦いは続く。'
              : '3種目を合わせた総合の結果は、別の記事で伝える。'),
  );
  w.danraku(pt.toString());

  // 表
  String kyonenMoji(SenshuData s) {
    final int? kj = k.kukanJuniMae(s, k.race, 1);
    return kj == null ? '-' : juniMoji(kj);
  }

  final List<List<String>> gyou = [
    for (int i = 0; i < mine.length; i++)
      [
        '${i + 1}',
        '${fullMei(mine[i].s.name)}(${mine[i].s.gakunen})',
        juniMoji(mine[i].juni),
        jikanMoji(mine[i].time),
        kyonenMoji(mine[i].s),
      ],
  ];
  return _kansei(
    k,
    site,
    no,
    w,
    category: '対校戦',
    midashi: midashi,
    lead: lead.toString(),
    kekka: true,
    hyou: [
      KijiHyou(
        '$smの全員の成績',
        ['チーム内', '選手', '全体順位', 'タイム', '昨年'],
        gyou,
      ),
    ],
  );
}

/// 対校戦の選手1人の走りを書く(段落・出身地と趣味・コメント)
/// [teamJun] チームの中の順(0がチームトップ)
/// [nobiSa] 伸び盛りの選手なら、昨年の同じ種目から上げた順位の数(そうでなければnull)
void _taikousenSenshuKaku(
  KijiKakite w,
  TaikousenKekka e,
  TaikousenSenshuKekka x,
  int teamJun, {
  int? nobiSa,
}) {
  final KijiKankyou k = e.k;
  final SenshuData s = x.s;
  final int sh = e.shumoku;
  final String sm = kijiShumokuMei[sh];
  final String yobi = w.senshu(s);
  final bool nyuushou = x.juni < _taikousenNyuushouSuu;
  final int? kj = k.kukanJuniMae(s, k.race, 1);
  final double? kt = _kyonenTime(s, k.race);
  final StringBuffer sb = StringBuffer();
  if (x.juni == 0) {
    sb.write('$yobiは${jikanMoji(x.time)}で$smを制した。');
  } else {
    sb.write('$yobiは全体${juniMoji(x.juni)}、${jikanMoji(x.time)}でゴールした。');
    if (nyuushou) {
      sb.write('名声のかかる8位以内に入り、入賞を果たした。');
    } else if (teamJun == 0) {
      sb.write('チームトップの走りだった。');
    }
  }
  // 昨年の同じ種目との比べ
  if (kj != null) {
    if (kj > x.juni) {
      sb.write('昨年の$smの${juniMoji(kj)}から、順位を${_tsu(kj - x.juni)}上げた。');
      if (nobiSa != null) sb.write('チームで一番の伸びだ。');
    } else if (kj == x.juni) {
      sb.write('昨年と同じ${juniMoji(kj)}だった。');
    } else {
      sb.write('昨年の$smは${juniMoji(kj)}だった。');
    }
    if (kt != null) {
      final int d = saByou(kt, x.time);
      if (d > 0) sb.write('タイムは昨年より${saMoji(d)}速かった。');
    }
  } else if (s.gakunen == 1) {
    sb.write('大学に入って初めての対校戦だった。');
    if (sh == 0) sb.write(_nyuugakuHikakuBun(s, x.time));
  }
  if (s.gakunen == 4) sb.write('4年生にとっては、これが最後の対校戦だ。');
  w.danraku(sb.toString());
  w.danraku(shusshinShumiBun(k, s, w.r, w.senshu(s)));
  // コメント
  final CommentBamen bamen = x.juni == 0
      ? CommentBamen.taikousenKojinYuushou
      : (nyuushou
            ? CommentBamen.gakunaiNyuushou
            : (nobiSa != null
                  ? CommentBamen.gakunaiNobi
                  : CommentBamen.gakunaiTaikousen));
  w.comment(senshuComment(w, bamen, w.senshu(s)));
}

/// 対校戦の総合の記事(ハーフのあと)
Kiji _taikousenSougouKiji(
  TaikousenKekka e,
  TaikousenUnivKekka m,
  String site,
) {
  final KijiKankyou k = e.k;
  const int no = 181;
  final KijiKakite w = KijiKakite(k, kijiTane(k.gh, k.race, no));
  final UnivData u = m.u;
  final int r = m.juni;
  final int n = e.n;
  // 総合の目標順位(0が1位。全大学とも8位)
  final int mk = _taikousenMokuhyou(u, n);
  final bool tassei = r <= mk;
  final bool hatsuKaisai = e.hatsuKaisai;
  final int mae = juniRace(u, _taikousenSougou, 1);
  final bool maeAri = !hatsuKaisai && shutsujouJuni(mae);
  // 総合優勝の回数(今回の分は、ハーフのあとに足されている)
  final int kaisuu = juniKaisuu(u, _taikousenSougou, 0);
  final List<int> shJ = [for (int ev = 0; ev < 3; ev++) e.shumokuJuni(m, ev)];
  // 5000mのあと・1万mのあとの総合の順位
  final int j5 = e.madeJun(0).indexWhere((x) => x.u.id == u.id);
  final int j10 = e.madeJun(1).indexWhere((x) => x.u.id == u.id);
  // 3種目の入賞者(種目の順。種目の中は順位の順)
  final List<({int ev, SenshuData s, int juni})> nyuushou = [];
  for (int ev = 0; ev < 3; ev++) {
    final List<({int ev, SenshuData s, int juni})> l = [];
    for (final SenshuData s in k.senshu) {
      if (s.univid != u.id) continue;
      final int? j = k.kukanJuniMae(s, 6 + ev, 0);
      if (j != null && j < _taikousenNyuushouSuu) l.add((ev: ev, s: s, juni: j));
    }
    l.sort((a, b) => a.juni.compareTo(b.juni));
    nyuushou.addAll(l);
  }

  // 見出し
  String midashi;
  if (r == 0) {
    if (hatsuKaisai) {
      midashi = '初代王者に！　対校戦で総合優勝';
    } else if (kaisuu <= 1) {
      midashi = w.erabu(['対校戦で初の総合優勝！', '悲願の頂点！　対校戦で初の総合優勝']);
    } else {
      midashi = w.erabu(['対校戦で総合優勝！', '対校戦の頂点に！　$kaisuu度目の総合優勝']);
    }
  } else if (tassei) {
    midashi = w.erabu([
      '対校戦は総合${juniMoji(r)}　目標の${juniMoji(mk)}以内を達成',
      '総合${juniMoji(r)}！　対校戦で目標達成',
    ]);
  } else if (r == mk + 1) {
    midashi = '対校戦は総合${juniMoji(r)}　目標まであと一つ';
  } else {
    midashi = w.erabu([
      '対校戦は総合${juniMoji(r)}　悔しさを駅伝シーズンへ',
      '総合${juniMoji(r)}、目標には届かず　それでも前へ',
    ]);
  }

  // リード
  final StringBuffer lead = StringBuffer();
  lead.write(
    '${k.taikaiMei}は最終種目のハーフを終え、陸上競技部は5000m・1万m・ハーフの合計${m.goukei}点で、'
    '総合${juniMoji(r)}となった。',
  );
  if (r == 0) {
    lead.write(
      hatsuKaisai ? '初めて開催された大会で、初代王者に輝いた。' : '全員で積み上げたポイントで、頂点に立った。',
    );
    if (n >= 2) {
      lead.write('2位の${e.jun[1].mei}とは${_tensa(m.goukei - e.jun[1].goukei)}だった。');
    }
  } else if (tassei) {
    lead.write('目標の${juniMoji(mk)}以内を達成した。');
  } else {
    lead.write('目標の${juniMoji(mk)}には届かなかった。');
  }
  if (maeAri) {
    if (mae > r) {
      lead.write('前回の${juniMoji(mae)}から順位を${_tsu(mae - r)}上げた。');
    } else if (mae == r) {
      lead.write('前回と同じ${juniMoji(r)}だった。');
    } else {
      lead.write('前回は${juniMoji(mae)}だった。');
    }
  }
  // 目標順位のラインの争い(ぎりぎりで達成したときと、届かなかったとき)
  if (r != 0 && r == mk && mk + 1 < n) {
    final TaikousenUnivKekka soto = e.jun[mk + 1];
    lead.write('${juniMoji(mk + 1)}の${soto.mei}とは${_tensa(m.goukei - soto.goukei)}の争いだった。');
  } else if (!tassei) {
    final TaikousenUnivKekka line = e.jun[mk];
    lead.write('目標の${juniMoji(mk)}の${line.mei}とは${_tensa(line.goukei - m.goukei)}だった。');
  }

  // 本文: 3種目の戦い
  w.koMidashi('3種目の戦い');
  final StringBuffer sb = StringBuffer();
  sb.write(
    '種目ごとのポイントは、'
    '${[for (int ev = 0; ev < 3; ev++) '${kijiShumokuMei[ev]}が${m.point[ev]}点(大学別${juniMoji(shJ[ev])})'].join('、')}だった。',
  );
  if (j5 >= 0 && j10 >= 0) {
    sb.write(
      '総合の順位は、5000mを終えて${juniMoji(j5)}、1万mを終えて${juniMoji(j10)}と推移し、'
      '最後のハーフで${juniMoji(r)}が決まった。',
    );
  }
  // 大学別の順位が一番良かった種目(1つに決まるときだけ)
  final int yoi = shJ.reduce((a, b) => a < b ? a : b);
  final List<int> yoiEv = [
    for (int ev = 0; ev < 3; ev++)
      if (shJ[ev] == yoi) ev,
  ];
  if (yoiEv.length == 1) {
    sb.write('3種目のうち、大学別の順位が最も良かったのは${kijiShumokuMei[yoiEv.first]}だった。');
  }
  w.danraku(sb.toString());
  final KantokuBamen kb = r == 0
      ? KantokuBamen.taikousenYuushou
      : (tassei
            ? (r == mk ? KantokuBamen.taikousenHachii : KantokuBamen.mokuhyouTassei)
            : (r == mk + 1
                  ? KantokuBamen.taikousenHachiiNogasu
                  : KantokuBamen.taikousenMitassei));
  w.comment(kantokuComment(w, kb, u.id, kuyashii: !tassei));

  // 本文: 大学の名声(総合は8位まで。個人は種目ごとに8位まで)
  w.koMidashi('大学の名声');
  final StringBuffer ms = StringBuffer();
  if (r < taikousenSougouMeisei.length) {
    ms.write('この総合${juniMoji(r)}で、大学の名声は${taikousenSougouMeisei[r]}高まった。');
    final String? hikaku = taikousenMeiseiHikaku(k, r);
    if (hikaku != null) ms.write('これは、$hikaku。');
  } else {
    ms.write('総合の名声は${taikousenSougouMeisei.length}位まで与えられ、今回は届かなかった。');
  }
  final int kojinMeisei = nyuushou.fold<int>(
    0,
    (t, x) => t +
        (x.juni < taikousenKojinMeisei.length ? taikousenKojinMeisei[x.juni] : 0),
  );
  if (kojinMeisei > 0) {
    ms.write('3種目の個人の入賞でも、合わせて$kojinMeiseiの名声を得た。');
  }
  w.danraku(ms.toString());

  // 本文: 入賞した選手
  if (nyuushou.isNotEmpty) {
    w.koMidashi('入賞した選手たち');
    w.danraku(
      '名声のかかる8位以内には、3種目で延べ${nyuushou.length}人が入賞した。'
      '${[for (final x in nyuushou) '${kijiShumokuMei[x.ev]}${x.juni == 0 ? '優勝' : juniMoji(x.juni)}の${w.senshu(x.s)}'].join('、')}が、'
      'チームのポイントを押し上げた。',
    );
  } else {
    w.koMidashi('全員でつかんだポイント');
    w.danraku(
      '3種目とも8位以内の入賞者は出なかったが、出場した全員の順位がポイントになり、'
      'チームの総合順位を支えた。',
    );
  }
  w.danraku(
    '${tassei ? 'この結果を自信に' : 'この悔しさを胸に'}、チームは夏の鍛錬を経て、駅伝シーズンへ向かう。'
    'ハーフの入賞者やチーム内の上位の選手の走りは、別の記事で振り返る。',
  );

  // 表
  final List<List<String>> gyou = [
    for (int ev = 0; ev < 3; ev++)
      [
        kijiShumokuMei[ev],
        '${m.point[ev]}',
        '大学別${juniMoji(shJ[ev])}',
        '${nyuushou.where((x) => x.ev == ev).length}人',
      ],
    ['総合', '${m.goukei}', juniMoji(r), '${nyuushou.length}人'],
  ];
  return _kansei(
    k,
    site,
    no,
    w,
    category: '対校戦',
    midashi: midashi,
    lead: lead.toString(),
    kekka: true,
    hyou: [
      KijiHyou('${k.taikaiMei}の成績', ['種目', 'ポイント', '順位', '入賞'], gyou),
    ],
  );
}
