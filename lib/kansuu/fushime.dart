import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kiroku.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/rekidai_kiroku.dart'; // 歴代10位までの記録
import 'package:ekiden/kansuu/custom_seigen.dart' show customRaceBangou, customIchinenDake;
import 'package:ekiden/kansuu/taikai_chouki.dart' show ouroRace, fukuroRace;
import 'package:ekiden/kansuu/oufuku_kiroku.dart' show shougatsuKukansuu;
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart'
    show kirokuKaketeiru, gakurenShussouJuni, jikanMoji, saMoji, byou;

// ------------------------------------------------------------
// 結果画面の、自分の大学の選手の節目と記録の更新(2.1.4)
//
// 結果画面のお知らせ(kekka_oshirase.dart)の下に、自分の大学の選手の出来事を数行で出す
// (画面は kekka_oshirase.dart の FushimeOshirase)。押さなくても進めるので、テンポは変えない。
// ・駅伝(10月・11月・正月・カスタム)
//   ・チーム: 大会新(総合)・総合の学内新・往路と復路の学内新(正月駅伝)
//   ・選手: 区間新・学内区間新・初めての区間賞・三大駅伝12回すべてに出走(4年生の正月駅伝)・
//     同じ区間を3年以上続けて・駅伝デビュー(本戦の初めての出走)
// ・個人の種目(対校戦・記録会・夏のTT・フルマラソン): 歴代新(全体の歴代1位)・学内新・日本人学内新・
//   学内歴代2位と3位(記録画面の歴代と同じ、一人1件の並び)
// ・記録の更新は、前からの記録を抜いたときだけ出す(記録が少ないうちは、何を走っても新記録や
//   歴代入りになってしまうため。記事が「前の記録があるときだけ新記録と書く」のと同じ考え方)
//   ・駅伝の区間記録と総合記録は、エントリーのときに控えた従来の記録(KantokuData.yobiint4)で確かめる
//   ・個人の種目は、記録の並びの中の、今回より前の記録(年月が今日でないもの)と、その選手の今回より前の
//     自己ベスト(同じ種目の大会の、学年ごとのタイム)で確かめる。前の記録の持ち主が本人なら「自身の記録」と書く
//   ・前の記録の持ち主は、名前・学年と、今から何年前か(「昨年」「3年前」)で書く(記録の年は年度ではなく、
//     ゲームの年なので、「○年」とは書かない)
// ・「初めて」「デビュー」は、前の学年の記録が欠けている選手(新しいゲームの2〜4年生など)には出さない
//   (記事と同じ kirokuKaketeiru)。学連選抜(オープン参加)での出走は、大学のチームの出走に数えない
// ・セーブ済みの結果・記録・フラグ(chokuzentaikai_〜)から画面を描くたびに作る(セーブデータは増やさない)
// ・思わぬデータに当たっても画面が止まらないよう、失敗したら何も出さない
// ------------------------------------------------------------

/// 節目・記録の更新1つ
class Fushime {
  const Fushime({
    required this.midashi,
    required this.bun,
    required this.juuyou,
    required this.matome,
    this.hito = true,
  });

  /// 頭に色を付けて出す短い言葉(「学内新」「駅伝デビュー」)
  final String midashi;

  /// 中身(「田中 蓮(3年) 5区 1時間10分12秒。昨年の記録を18秒更新しました。」)
  final String bun;

  /// 大きいほど先に出す
  final int juuyou;

  /// 行に入りきらなかったときに、まとめて数える名前(「駅伝デビュー」)
  final String matome;

  /// 選手のことか(まとめるときに「○人」と数える。チームのことなら「○件」)
  final bool hito;
}

/// 出す行と、入りきらなかった分のまとめの文
class FushimeMatome {
  const FushimeMatome(this.miseru, this.nokori);
  final List<Fushime> miseru;

  /// 「ほかに、駅伝デビュー2人・初の区間賞1人。」(なければ空)
  final String nokori;
}

/// 結果画面に出す行の数
const int fushimeGyousuu = 3;

/// [l]を大きい順に並べ、[saidai]行まで出して、残りをまとめる
FushimeMatome fushimeMatome(List<Fushime> l, {int saidai = fushimeGyousuu}) {
  // 大きい順(同じ大きさなら、作った順(区間の順・速い順)のまま)
  final List<int> bangou = List<int>.generate(l.length, (i) => i)
    ..sort((a, b) {
      final int c = l[b].juuyou.compareTo(l[a].juuyou);
      return c != 0 ? c : a.compareTo(b);
    });
  final List<Fushime> jun = [for (final int i in bangou) l[i]];
  if (jun.length <= saidai) return FushimeMatome(jun, '');
  final List<Fushime> miseru = jun.sublist(0, saidai);
  // 残りを、名前ごとに数える(大きい順)
  final List<String> namae = [];
  final Map<String, int> kazu = {};
  final Map<String, bool> hito = {};
  for (final Fushime f in jun.sublist(saidai)) {
    if (!kazu.containsKey(f.matome)) namae.add(f.matome);
    kazu[f.matome] = (kazu[f.matome] ?? 0) + 1;
    hito[f.matome] = f.hito;
  }
  final String nokori = namae
      .map((n) => '$n${kazu[n]}${(hito[n] ?? true) ? '人' : '件'}')
      .join('・');
  return FushimeMatome(miseru, 'ほかに、$nokori。');
}

// ------------------------------------------------------------
// 共通の部品
// ------------------------------------------------------------

/// 今回の大会の記録か(記録の年月が今日の年月)
bool _kondo(Ghensuu gh, RekidaiKiroku k) => k.year == gh.year && k.month == gh.month;

/// 記録[k]が今から何年前か(「昨年」「3年前」。同じ年なら「今年5月」)
String fushimeItsu(Ghensuu gh, RekidaiKiroku k) {
  final int d = gh.year - k.year;
  if (d <= 0) return '今年${k.month}月';
  if (d == 1) return '昨年';
  return '$d年前';
}

/// 選手[s]が今回出した記録としての見分けの文字列(歴代の記録の senshuKagi と同じ形)
String _senshuKagi(Ghensuu gh, SenshuData s, String univname) => RekidaiKiroku(
  time: 0,
  year: gh.year,
  month: gh.month,
  univname: univname,
  name: s.name,
  gakunen: s.gakunen,
).senshuKagi;

/// 選手の名前と学年(「田中 蓮(3年)」)
String _namae(SenshuData s) => '${s.name}(${s.gakunen}年)';

/// 更新した差の文(「18秒更新しました」。1秒に満たないときは「わずかに更新しました」)
String _koushinMoji(int sa) => sa <= 0 ? 'わずかに更新しました' : '${saMoji(sa)}更新しました';

/// 従来の記録(秒。エントリーのときに控えたもの。なければnull)
int? _jurai(KantokuData? kantoku, int i) {
  if (kantoku == null || i < 0 || kantoku.yobiint4.length <= i) return null;
  final int t = kantoku.yobiint4[i];
  if (t <= 0 || t >= TEISUU.DEFAULTTIME.toInt()) return null;
  return t;
}

/// タイムがあるか
bool _timeAri(double t) => t > 0 && t < TEISUU.DEFAULTTIME;

/// 選手[s]の学年[g](1から)の大会[race]の区間(出走していなければ負)
int _entry(SenshuData s, int race, int g) {
  if (g < 1 || s.entrykukan_race.length <= race || s.entrykukan_race[race].length < g) return -1;
  return s.entrykukan_race[race][g - 1];
}

/// 選手[s]の学年[g](1から)の大会[race]の区間順位・個人順位(0が1位。なければ DEFAULTJUNI)
int _juni(SenshuData s, int race, int g) {
  if (g < 1 || s.kukanjuni_race.length <= race || s.kukanjuni_race[race].length < g) {
    return TEISUU.DEFAULTJUNI;
  }
  return s.kukanjuni_race[race][g - 1];
}

/// 選手[s]の学年[g](1から)の大会[race]のタイム(なければ DEFAULTTIME)
double _time(SenshuData s, int race, int g) {
  if (g < 1 || s.kukantime_race.length <= race || s.kukantime_race[race].length < g) {
    return TEISUU.DEFAULTTIME;
  }
  return s.kukantime_race[race][g - 1];
}

/// 駅伝の本戦(予選ではない)か
bool fushimeHonsen(int race) => race == 0 || race == 1 || race == 2 || race == customRaceBangou;

/// 1年の中の駅伝の並び(記事と同じ。11月駅伝予選・10月駅伝・正月駅伝予選・11月駅伝・正月駅伝・カスタム駅伝)
const List<int> _raceJun = [3, 0, 4, 1, 2, 5];

/// 選手[s]が、学年[g]の大会[race]を大学のチームとして走ったか(学連選抜のオープン参加は数えない)
bool fushimeChiimuShussou(SenshuData s, int race, int g) {
  if (_entry(s, race, g) < 0) return false;
  return !gakurenShussouJuni(race, _juni(s, race, g));
}

/// 選手[s]が、今の学年の大会[race]より前に、駅伝の本戦を大学のチームとして走った回数と、区間賞の回数
({int shussou, int kukanshou}) _maeHonsen(SenshuData s, int race) {
  int shussou = 0;
  int kukanshou = 0;
  final int imaJun = _raceJun.indexOf(race);
  for (int g = 1; g <= s.gakunen; g++) {
    for (int ji = 0; ji < _raceJun.length; ji++) {
      final int r = _raceJun[ji];
      if (!fushimeHonsen(r)) continue;
      if (g == s.gakunen && ji >= imaJun) continue; // 今回とそれより後の大会
      if (!fushimeChiimuShussou(s, r, g)) continue;
      shussou++;
      if (_juni(s, r, g) == 0) kukanshou++;
    }
  }
  return (shussou: shussou, kukanshou: kukanshou);
}

KantokuData? _kantoku() => Hive.isBoxOpen('kantokuBox')
    ? Hive.box<KantokuData>('kantokuBox').get('KantokuData')
    : null;

Kiroku? _kiroku() =>
    Hive.isBoxOpen('kirokuBox') ? Hive.box<Kiroku>('kirokuBox').get('KirokuData') : null;

/// 歴代[l]から、今回より前の記録で一番速いもの(なければnull)
RekidaiKiroku? _maeIchiban(Ghensuu gh, List<RekidaiKiroku> l) {
  for (final RekidaiKiroku k in l) {
    if (!_kondo(gh, k)) return k;
  }
  return null;
}

// ------------------------------------------------------------
// 入口
// ------------------------------------------------------------

/// 結果画面に出す、自分の大学の節目と記録の更新(出すことがなければ空)
/// [univ] 大学(IDの順)、[senshu] 全選手
List<Fushime> fushimeIchiran(Ghensuu gh, List<UnivData> univ, List<SenshuData> senshu) {
  try {
    final int race = gh.hyojiracebangou;
    if (gh.MYunivid < 0 || gh.MYunivid >= univ.length) return [];
    final UnivData u = univ[gh.MYunivid];
    if (fushimeHonsen(race)) return _ekiden(gh, u, senshu, race);
    final int? k = fushimeKirokuBangou(race);
    if (k != null) return _kojin(gh, u, senshu, race, k);
    return [];
  } catch (_) {
    return [];
  }
}

/// 個人の種目の大会[race]の個人記録の番号(個人記録のない大会はnull。KirokuKousin.dart と同じ対応。
/// 駅伝予選は自己ベストにも学内記録にも入らないので、ここでもnull)
int? fushimeKirokuBangou(int race) {
  if (race >= 6 && race <= 8) return race - 6; // 対校戦 5000m・1万m・ハーフ
  if (race >= 10 && race <= 12) return race - 10; // 記録会 5000m・1万m・市民ハーフ
  if (race >= 13 && race <= 16) return race - 9; // 夏のTT 登り・下り・ロード・クロカン
  if (race == 17) return 3; // フルマラソン
  return null;
}

/// 個人記録[k]になる大会(KirokuKousin.dart の対応の逆。駅伝予選は入らない)
const Map<int, List<int>> fushimeShumokuRace = {
  0: [6, 10],
  1: [7, 11],
  2: [8, 12],
  3: [17],
  4: [13],
  5: [14],
  6: [15],
  7: [16],
};

/// 選手[s]の個人記録[k]の、今回(今の学年の大会[race])より前の自己ベスト(なければnull)
double? _maeBest(SenshuData s, int k, int race) {
  double? best;
  for (final int r in fushimeShumokuRace[k] ?? const <int>[]) {
    for (int g = 1; g <= s.gakunen; g++) {
      if (r == race && g == s.gakunen) continue;
      if (_entry(s, r, g) < 0) continue;
      final double t = _time(s, r, g);
      if (!_timeAri(t)) continue;
      if (best == null || t < best) best = t;
    }
  }
  return best;
}

// ------------------------------------------------------------
// 駅伝
// ------------------------------------------------------------

List<Fushime> _ekiden(Ghensuu gh, UnivData u, List<SenshuData> senshu, int race) {
  if (u.taikaientryflag.length <= race || u.taikaientryflag[race] != 1) return [];
  final KantokuData? kantoku = _kantoku();
  final Kiroku? kiroku = _kiroku();
  final List<Fushime> l = [];

  // チームの総合
  final double sougou = (u.time_race.length > race && u.time_race[race].isNotEmpty)
      ? u.time_race[race][0]
      : TEISUU.DEFAULTTIME;
  if (_timeAri(sougou)) {
    final int? juraiZentai = _jurai(kantoku, 20);
    final int? juraiGakunai = _jurai(kantoku, 21);
    if (u.chokuzentaikai_zentaitaikaisinflag == 1 && juraiZentai != null) {
      final RekidaiKiroku? mae = _maeIchiban(gh, rekidaiZentaiTaikai(gh, race).yomu());
      final String dare = (mae != null && (byou(mae.time) - juraiZentai).abs() <= 1)
          ? '${fushimeItsu(gh, mae)}に${mae.univname}大学が出した記録'
          : '前の記録';
      l.add(
        Fushime(
          midashi: '大会新',
          bun: '総合${jikanMoji(sougou)}。$dareを${_koushinMoji(juraiZentai - byou(sougou))}。',
          juuyou: 100,
          matome: '大会新',
          hito: false,
        ),
      );
    } else if (u.chokuzentaikai_univtaikaisinflag == 1 && juraiGakunai != null) {
      final RekidaiKiroku? mae = _maeIchiban(gh, rekidaiUnivTaikai(u, race).yomu());
      final String dare = (mae != null && (byou(mae.time) - juraiGakunai).abs() <= 1)
          ? '${fushimeItsu(gh, mae)}の記録'
          : '前の記録';
      l.add(
        Fushime(
          midashi: '総合の学内新',
          bun: '総合${jikanMoji(sougou)}。$dareを${_koushinMoji(juraiGakunai - byou(sougou))}。',
          juuyou: 80,
          matome: '総合の学内新',
          hito: false,
        ),
      );
    }
  }
  // 正月駅伝の往路・復路の学内記録(記録の並びの1番目が今回で、前の記録があるとき)
  if (race == 2 &&
      gh.kukansuu_taikaigoto.length > 2 &&
      gh.kukansuu_taikaigoto[2] == shougatsuKukansuu) {
    for (final int r in const [ouroRace, fukuroRace]) {
      if (u.time_univtaikaikiroku.length <= r) continue;
      final List<RekidaiKiroku> rekidai = rekidaiUnivTaikai(u, r).yomu();
      if (rekidai.isEmpty || !_kondo(gh, rekidai.first)) continue;
      final RekidaiKiroku? mae = _maeIchiban(gh, rekidai);
      if (mae == null) continue;
      final String mei = r == ouroRace ? '往路' : '復路';
      l.add(
        Fushime(
          midashi: '$meiの学内新',
          bun:
              '$mei${jikanMoji(rekidai.first.time)}。${fushimeItsu(gh, mae)}の記録を'
              '${_koushinMoji(byou(mae.time) - byou(rekidai.first.time))}。',
          juuyou: 75,
          matome: '$meiの学内新',
          hito: false,
        ),
      );
    }
  }

  // 選手(区間の順)
  final List<SenshuData> soushasha = [
    for (final SenshuData s in senshu)
      if (s.univid == u.id && fushimeChiimuShussou(s, race, s.gakunen)) s,
  ]..sort((a, b) => _entry(a, race, a.gakunen).compareTo(_entry(b, race, b.gakunen)));
  for (final SenshuData s in soushasha) {
    final Fushime? f = _ekidenSenshu(gh, u, s, race, kantoku, kiroku);
    if (f != null) l.add(f);
  }
  return l;
}

/// 駅伝を走った選手[s]の節目(一番大きいものを1つ。なければnull)
Fushime? _ekidenSenshu(
  Ghensuu gh,
  UnivData u,
  SenshuData s,
  int race,
  KantokuData? kantoku,
  Kiroku? kiroku,
) {
  final int g = s.gakunen;
  final int kk = _entry(s, race, g);
  if (kk < 0 || kk >= 10) return null;
  final double t = _time(s, race, g);
  if (!_timeAri(t)) return null;
  final String basho = '${_namae(s)} ${kk + 1}区';

  // 区間新(全体)
  final int? juraiZentai = _jurai(kantoku, kk);
  if (s.chokuzentaikai_zentaikukansinflag == 1 && juraiZentai != null) {
    String dare = '区間記録';
    if (kiroku != null) {
      final RekidaiKiroku? maeK = _maeIchiban(
        gh,
        rekidaiAwaseru(
          ichii: ichiiZentaiKukan(gh, race, kk).yomu(),
          nihonjin: rekidaiZentaiKukan(kiroku, false, race, kk).yomu(),
          ryuugakusei: rekidaiZentaiKukan(kiroku, true, race, kk).yomu(),
        ),
      );
      if (maeK != null && (byou(maeK.time) - juraiZentai).abs() <= 1) {
        dare = maeK.senshuKagi == _senshuKagi(gh, s, u.name)
            ? '${fushimeItsu(gh, maeK)}に自身が出した区間記録'
            : '${fushimeItsu(gh, maeK)}に${maeK.univname}大学の${maeK.name}(${maeK.gakunen}年)が出した区間記録';
      }
    }
    return Fushime(
      midashi: '区間新',
      bun: '$basho ${jikanMoji(t)}。$dareを${_koushinMoji(juraiZentai - byou(t))}。',
      juuyou: 90,
      matome: '区間新',
    );
  }

  // 学内区間新
  final int? juraiGakunai = _jurai(kantoku, kk + 10);
  if (s.chokuzentaikai_univkukansinflag == 1 && juraiGakunai != null) {
    String dare = '学内の区間記録';
    if (kiroku != null) {
      final RekidaiKiroku? maeK = _maeIchiban(
        gh,
        rekidaiAwaseru(
          ichii: ichiiUnivKukan(u, race, kk).yomu(),
          nihonjin: rekidaiUnivKukan(kiroku, false, u.id, race, kk).yomu(),
          ryuugakusei: rekidaiUnivKukan(kiroku, true, u.id, race, kk).yomu(),
        ),
      );
      if (maeK != null && (byou(maeK.time) - juraiGakunai).abs() <= 1) {
        dare = maeK.senshuKagi == _senshuKagi(gh, s, '')
            ? '${fushimeItsu(gh, maeK)}に自身が出した学内記録'
            : '${fushimeItsu(gh, maeK)}に${maeK.name}(${maeK.gakunen}年)が出した学内記録';
      }
    }
    return Fushime(
      midashi: '学内区間新',
      bun: '$basho ${jikanMoji(t)}。$dareを${_koushinMoji(juraiGakunai - byou(t))}。',
      juuyou: 70,
      matome: '学内区間新',
    );
  }

  // ここから先は「初めて」「続けて」を数えるので、前の学年の記録が欠けている選手には出さない
  if (kirokuKaketeiru(s)) return null;
  final ({int shussou, int kukanshou}) maeHonsen = _maeHonsen(s, race);

  // 初めての区間賞
  if (_juni(s, race, g) == 0 && maeHonsen.kukanshou == 0) {
    return Fushime(
      midashi: '初の区間賞',
      bun: '$basho。初めての区間賞です。',
      juuyou: 50,
      matome: '初の区間賞',
    );
  }

  // 三大駅伝12回すべてに出走(4年生の正月駅伝)
  if (race == 2 && g == 4) {
    bool zenbu = true;
    for (int gg = 1; gg <= 4 && zenbu; gg++) {
      for (final int r in const [0, 1, 2]) {
        if (!fushimeChiimuShussou(s, r, gg)) {
          zenbu = false;
          break;
        }
      }
    }
    if (zenbu) {
      return Fushime(
        midashi: '12回出走',
        bun: '${_namae(s)}。三大駅伝の12回をすべて走りました。',
        juuyou: 45,
        matome: '12回出走',
      );
    }
  }

  // 同じ区間を3年以上続けて
  int renzoku = 0;
  for (int gg = g; gg >= 1; gg--) {
    if (!fushimeChiimuShussou(s, race, gg) || _entry(s, race, gg) != kk) break;
    renzoku++;
  }
  if (renzoku >= 3) {
    return Fushime(
      midashi: '$renzoku年連続',
      bun: '${_namae(s)}。$renzoku年続けて${kk + 1}区を走りました。',
      juuyou: 40 + renzoku,
      matome: '同じ区間の連続',
    );
  }

  // 駅伝デビュー(本戦の初めての出走。1年生だけのカスタム駅伝では出さない)
  if (maeHonsen.shussou == 0 && !(race == customRaceBangou && customIchinenDake())) {
    return Fushime(
      midashi: '駅伝デビュー',
      bun: '$basho。初めての駅伝です。',
      juuyou: 30,
      matome: '駅伝デビュー',
    );
  }
  return null;
}

// ------------------------------------------------------------
// 個人の種目(対校戦・記録会・夏のTT・フルマラソン)
// ------------------------------------------------------------

/// 前の記録の書き方と、更新した差(秒)。前の記録がなければnull
/// [l] 速い順の歴代(一人1件)、[ichi] その中の選手[s]の今回の記録の位置、[maeBest] 選手の前の自己ベスト
/// [univname] 全体の記録なら選手の大学名(学内の記録なら空)
({String dare, int sa})? _maeKojin(
  Ghensuu gh,
  List<RekidaiKiroku> l,
  int ichi,
  SenshuData s,
  double t,
  double? maeBest,
  String univname,
) {
  // 今回の記録より下の、前からの記録で一番速いもの(本人の前の記録は、一人1件なので並びにはない)
  RekidaiKiroku? hoka;
  for (int i = ichi + 1; i < l.length; i++) {
    if (_kondo(gh, l[i])) continue;
    if (l[i].senshuKagi == _senshuKagi(gh, s, univname)) continue;
    hoka = l[i];
    break;
  }
  if (maeBest != null && (hoka == null || maeBest < hoka.time)) {
    if (maeBest <= t) return null;
    return (dare: '自身の記録', sa: byou(maeBest) - byou(t));
  }
  if (hoka == null) return null;
  final String daigaku = univname.isEmpty ? '' : '${hoka.univname}大学の';
  return (
    dare: '${fushimeItsu(gh, hoka)}に$daigaku${hoka.name}(${hoka.gakunen}年)が出した記録',
    sa: byou(hoka.time) - byou(t),
  );
}

List<Fushime> _kojin(Ghensuu gh, UnivData u, List<SenshuData> senshu, int race, int k) {
  final Kiroku? kiroku = _kiroku();
  if (kiroku == null) return [];
  // 全体・学内の歴代(記録画面と同じ、日本人+留学生を合わせた一人1件の並び)と、学内の日本人の歴代
  final List<RekidaiKiroku> zentai = rekidaiAwaseru(
    ichii: ichiiZentaiKojin(gh, k).yomu(),
    nihonjin: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, false, k).yomu()),
    ryuugakusei: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, true, k).yomu()),
    hitoriIkken: true,
  );
  final List<RekidaiKiroku> gakunai = rekidaiAwaseru(
    ichii: ichiiUnivKojin(u, k).yomu(),
    nihonjin: rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, false, u.id, k).yomu()),
    ryuugakusei: rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, true, u.id, k).yomu()),
    hitoriIkken: true,
  );
  final List<RekidaiKiroku> nihonjin = rekidaiHitoriIkken(
    rekidaiUnivKojin(kiroku, false, u.id, k).yomu(),
  );

  // 走った自分の大学の選手(速い順)
  final List<SenshuData> soushasha = [
    for (final SenshuData s in senshu)
      if (s.univid == u.id && _entry(s, race, s.gakunen) >= 0 && _timeAri(_time(s, race, s.gakunen)))
        s,
  ]..sort((a, b) => _time(a, race, a.gakunen).compareTo(_time(b, race, b.gakunen)));

  int ichiDoko(List<RekidaiKiroku> l, SenshuData s, double t) => l.indexWhere(
    (x) => _kondo(gh, x) && x.name == s.name && (x.time - t).abs() < 0.05,
  );

  final List<Fushime> l = [];
  for (final SenshuData s in soushasha) {
    final double t = _time(s, race, s.gakunen);
    final double? maeBest = _maeBest(s, k, race);
    final String naka = '${_namae(s)} ${jikanMoji(t)}。';

    // 歴代新(全体の歴代1位)
    if (s.chokuzentaikai_kojinrekidaisinflag == 1) {
      final int zIchi = ichiDoko(zentai, s, t);
      if (zIchi == 0) {
        final ({String dare, int sa})? mae = _maeKojin(gh, zentai, zIchi, s, t, maeBest, u.name);
        if (mae != null) {
          l.add(
            Fushime(
              midashi: '歴代新',
              bun: '$naka${mae.dare}を${_koushinMoji(mae.sa)}。',
              juuyou: 95,
              matome: '歴代新',
            ),
          );
          continue;
        }
      }
    }

    // 学内新・学内歴代2位と3位
    final int ichi = ichiDoko(gakunai, s, t);
    if (ichi == 0 && s.chokuzentaikai_kojinunivsinflag == 1) {
      final ({String dare, int sa})? mae = _maeKojin(gh, gakunai, ichi, s, t, maeBest, '');
      if (mae != null) {
        l.add(
          Fushime(
            midashi: '学内新',
            bun: '$naka${mae.dare}を${_koushinMoji(mae.sa)}。',
            juuyou: 85,
            matome: '学内新',
          ),
        );
        continue;
      }
    }

    // 日本人学内新(留学生が学内記録を持っているとき)
    if (s.hirou != 1 && ichi != 0) {
      final int jIchi = ichiDoko(nihonjin, s, t);
      if (jIchi == 0) {
        final ({String dare, int sa})? mae = _maeKojin(gh, nihonjin, jIchi, s, t, maeBest, '');
        if (mae != null) {
          l.add(
            Fushime(
              midashi: '日本人学内新',
              bun: '$naka${mae.dare}を${_koushinMoji(mae.sa)}。',
              juuyou: 70,
              matome: '日本人学内新',
            ),
          );
          continue;
        }
      }
    }

    // 学内歴代2位・3位(前からの記録を抜いたとき。前の自己ベストより速かった記録を抜いても、抜いたことにはしない)
    if (ichi == 1 || ichi == 2) {
      bool nuita = false;
      for (int i = ichi + 1; i < gakunai.length; i++) {
        final RekidaiKiroku x = gakunai[i];
        if (_kondo(gh, x)) continue;
        if (maeBest == null || x.time < maeBest) {
          nuita = true;
          break;
        }
      }
      if (nuita) {
        l.add(
          Fushime(
            midashi: '学内歴代${ichi + 1}位',
            bun: naka,
            juuyou: 60 - ichi,
            matome: '学内歴代3位以内',
          ),
        );
      }
    }
  }
  return l;
}
