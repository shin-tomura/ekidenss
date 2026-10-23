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
import 'package:ekiden/kansuu/oufuku_kiroku.dart' show shougatsuKukansuu, ouroTime, fukuroTime;
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart'
    show kirokuKaketeiru, gakurenShussouJuni, jikanMoji, saMoji, byou;

// ------------------------------------------------------------
// 結果画面の、自分の大学の選手の節目と記録の更新(2.1.4)
//
// 結果画面のお知らせ(kekka_oshirase.dart)の下に、自分の大学の選手の出来事を出す
// (画面は kekka_oshirase.dart の FushimeOshirase)。押さなくても進めるので、テンポは変えない。
// ・1人(チームの総合・往路・復路はそれぞれ1つ)を1行にまとめる。一番大きい出来事を頭に出し、
//   ほかの出来事は「学内区間新も。」のように短く添える
// ・大きい順に3行まで出し、3行を超えるときは「すべて見る」で別窓に全部を出す
// ・大きさの段(上から): 全体の1位(大会新・往路新・復路新・区間新・歴代新) → 学内の1位(総合・往路・復路・
//   区間・個人の学内新と日本人学内新) → 全体の歴代2〜10位 → 初めての区間賞・三大駅伝12回出走・同じ区間の連続
//   → 学内の歴代2〜10位 → 駅伝デビュー。同じ段の中は順位の高い順
// ・駅伝(10月・11月・正月・カスタム)
//   ・チーム: 総合(全体の大会記録と学内)、正月駅伝の往路・復路(全体と学内)の歴代10位まで
//   ・選手: 区間記録(全体と学内)の歴代10位まで・初めての区間賞・三大駅伝12回すべてに出走(4年生の正月駅伝)・
//     同じ区間を3年以上続けて・駅伝デビュー(本戦の初めての出走)
// ・個人の種目(対校戦・記録会・夏のTT・フルマラソン): 全体と学内の歴代10位まで(記録画面の歴代と同じ、
//   日本人+留学生を合わせた一人1件の並び)と、日本人学内新
// ・記録の更新は、前からの記録を抜いたときだけ出す(記録が少ないうちは、何を走っても新記録や
//   歴代入りになってしまうため。記事が「前の記録があるときだけ新記録と書く」のと同じ考え方)
//   ・1位(新記録)のうち、駅伝の区間記録と総合記録は、エントリーのときに控えた従来の記録(KantokuData.yobiint4)で
//     確かめる。そのほかは、記録の並びの中の、今回より前の記録(年月が今回の大会でないもの)で確かめる
//   ・歴代2〜10位は、今回の記録より下に前からの記録があり(抜いた)、前からの記録が順位の数以上あったとき
//     だけ出す(「歴代3位」と出すのは、前からの記録が3件以上あったとき。記録の並びが10件そろっていれば、
//     あったものとする)。学内の区間の歴代は1年に1件ずつしか増えないので、最初の数年に軽い知らせばかりに
//     ならないように
//   ・個人の種目の前の記録の持ち主が本人かは、その選手の今回より前の自己ベスト(同じ種目の大会の、学年ごとの
//     タイム)で見る。学内の記録は、学内記録を付け始めた年度(大学を移ったとき)からの自己ベストだけで見る
//   ・前の記録の持ち主は、名前・学年と、今から何年前か(「昨年」「3年前」)で書く(記録の年は年度ではなく、
//     ゲームの年なので、「○年」とは書かない)
// ・「初めて」「デビュー」「連続」は、前の学年の記録が欠けている選手(新しいゲームの2〜4年生など)には出さない
//   (記事と同じ kirokuKaketeiru)。学連選抜(オープン参加)での出走は、大学のチームの出走に数えない
// ・記録と選手は、通算の番号(2.1.4から記録に残す。rekidai_kiroku.dart の senshuTsuusanBangou)だけで結びつける。
//   今回の記録が並びの何番目かを探すのも、前の記録の持ち主を「自身」と言うかも、番号で見る。番号のない記録
//   (2.1.4より前に出た記録)は、前からの記録としては数え、持ち主の名前も書くが、「自身」とは言わない
// ・セーブ済みの結果・記録から画面を描くたびに作る(セーブデータは増やさない)。駅伝の新記録は結果画面の印
//   (chokuzentaikai_〜)も使い、個人の種目は記録の年月で見る(記事でも同じ判定を使うため)
// ・記事(学内メディアの対校戦の結果号・学内TT特集)には、今までどおり、歴代新・学内新・日本人学内新・
//   学内歴代2位と3位だけを渡す(fushimeKojinKoushin)
// ・行の中の選手名(走った選手と、前の記録の持ち主)は、押すとその選手を開けるようにする(2.1.4。[Fushime.link]。
//   開けるかどうかと開き方は、画面の側(screens/kiroku_link.dart)で決める。番号のない記録の持ち主はリンクにしない)
// ・思わぬデータに当たっても画面が止まらないよう、失敗したら何も出さない
// ------------------------------------------------------------

/// 行の中の、押すと選手を開く文字(2.1.4。[moji]は[Fushime.bun]の中の「田中 蓮(3年)」、[bangou]は通算の番号)
typedef FushimeLink = ({String moji, int bangou});

/// 結果画面の1行(1人、またはチームの総合・往路・復路を1行にまとめたもの)
class Fushime {
  const Fushime({
    required this.midashi,
    required this.bun,
    required this.juuyou,
    this.link = const [],
  });

  /// 頭に色を付けて出す短い言葉(「学内新」「駅伝デビュー」)
  final String midashi;

  /// 中身(「田中 蓮(3年) 5区 1時間10分12秒。昨年の記録を18秒更新しました。初の区間賞も。」)
  final String bun;

  /// 大きいほど先に出す
  final int juuyou;

  /// [bun]の中の、押すと選手を開く文字(前から順に。走った選手、前の記録の持ち主。チームの行はなし)
  final List<FushimeLink> link;
}

/// 結果画面に、すぐに出す行の数(これを超えるときは「すべて見る」で別窓に全部を出す)
const int fushimeGyousuu = 3;

/// 出来事1つ(同じ[kagi]の出来事は、1行にまとめる)
class _Koto {
  const _Koto({
    required this.kagi,
    required this.juuyou,
    required this.midashi,
    required this.bun,
    required this.soe,
    this.link = const [],
  });

  /// まとめる単位(選手は「S」+選手の番号、チームは「総合」「往路」「復路」)
  final String kagi;
  final int juuyou;
  final String midashi;

  /// 行の頭の出来事にしたときの中身
  final String bun;

  /// ほかの出来事に添えるときの短い言葉(「学内区間新」)
  final String soe;

  /// [bun]の中の、押すと選手を開く文字(行の頭の出来事にしたときに使う)
  final List<FushimeLink> link;
}

// ---- 大きさ(段ごと。同じ段の中は順位の高い順) ----
// 全体の1位
const int _jTaikaiShin = 100;
const int _jOufukuShin = 99;
const int _jKukanShin = 98;
const int _jRekidaiShin = 97;
// 学内の1位
const int _jSougouGakunaiShin = 90;
const int _jOufukuGakunaiShin = 89;
const int _jGakunaiKukanShin = 88;
const int _jGakunaiShin = 87;
const int _jNihonjinGakunaiShin = 86;

/// 全体の歴代2〜10位([ichi] は0から。2位が78、10位が70)
int _jZentaiRekidai(int ichi) => 80 - (ichi + 1);
// 初めての区間賞・12回出走・連続
const int _jHatsuKukanshou = 60;
const int _jJuunikai = 59;

/// 同じ区間の連続(4年連続が57、3年連続が56)
int _jRenzoku(int nen) => 53 + nen;

/// 学内の歴代2〜10位([ichi] は0から。2位が48、10位が40)
int _jGakunaiRekidai(int ichi) => 50 - (ichi + 1);
// 駅伝デビュー
const int _jDebut = 30;

/// 出来事を1人1行にまとめ、大きい順に並べる(同じ大きさなら、作った順(区間の順・速い順)のまま)
List<Fushime> _matomeru(List<_Koto> l) {
  final List<String> kagiJun = [];
  final Map<String, List<_Koto>> kagiBetsu = {};
  for (final _Koto k in l) {
    if (!kagiBetsu.containsKey(k.kagi)) kagiJun.add(k.kagi);
    kagiBetsu.putIfAbsent(k.kagi, () => []).add(k);
  }
  final List<Fushime> gyou = [];
  for (final String kagi in kagiJun) {
    final List<_Koto> kl = List<_Koto>.from(kagiBetsu[kagi] ?? const <_Koto>[])
      ..sort((a, b) => b.juuyou.compareTo(a.juuyou));
    if (kl.isEmpty) continue;
    final _Koto atama = kl.first;
    final List<String> soe = [for (final _Koto k in kl.skip(1)) k.soe];
    gyou.add(
      Fushime(
        midashi: atama.midashi,
        bun: soe.isEmpty ? atama.bun : '${atama.bun}${soe.join('・')}も。',
        juuyou: atama.juuyou,
        link: atama.link,
      ),
    );
  }
  final List<int> bangou = List<int>.generate(gyou.length, (i) => i)
    ..sort((a, b) {
      final int c = gyou[b].juuyou.compareTo(gyou[a].juuyou);
      return c != 0 ? c : a.compareTo(b);
    });
  return [for (final int i in bangou) gyou[i]];
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

/// 選手[s]の通算の番号(2.1.4。記録と選手は、この番号だけで結びつける。rekidai_kiroku.dart)
int _bangou(Ghensuu gh, SenshuData s) => senshuTsuusanBangou(gh, s);

/// 記録[k]が選手[s]のものか(番号のない記録(2.1.4より前に出た記録)は、結びつけない)
bool _honnin(Ghensuu gh, RekidaiKiroku k, SenshuData s) {
  final int? b = k.bangou;
  return b != null && b == _bangou(gh, s);
}

/// 選手の名前と学年(「田中 蓮(3年)」)
String _namae(SenshuData s) => '${s.name}(${s.gakunen}年)';

/// 走った選手[s]のリンク(行の中の「田中 蓮(3年)」)
FushimeLink _linkHonnin(Ghensuu gh, SenshuData s) => (moji: _namae(s), bangou: _bangou(gh, s));

/// 前の記録の持ち主のリンク(行の中の「山本 翔(4年)」。本人のときと、番号のない記録はなし)
List<FushimeLink> _linkMae(RekidaiKiroku? mae, bool jishin) {
  if (mae == null || jishin) return const [];
  final int? b = mae.bangou;
  if (b == null) return const [];
  return [(moji: '${mae.name}(${mae.gakunen}年)', bangou: b)];
}

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

/// 歴代[l]の[ichi]番目(0から。2位以下なので1以上)にある今回の記録を、「歴代○位」として出せるか
/// ・今回の記録より下に、前からの記録がある(抜いた)。[maeBest](選手の前の自己ベスト)があれば、
///   それより速かった記録を抜いたときだけ(自分の前の記録より遅い記録は、前から抜いていたので)
/// ・前からの記録が、順位の数以上あった(並びが10件そろっていれば、あったものとする。今回の記録に
///   押し出された前の記録は並びに残らないので、数えられないため)
bool _rekidaiDaseru(
  List<RekidaiKiroku> l,
  int ichi,
  bool Function(RekidaiKiroku) kondo, {
  double? maeBest,
}) {
  if (ichi < 1 || ichi >= TEISUU.SUU_REKIDAIKIROKUJUNISUU) return false;
  bool nuita = false;
  for (int i = ichi + 1; i < l.length; i++) {
    final RekidaiKiroku x = l[i];
    if (kondo(x)) continue;
    if (maeBest == null || x.time < maeBest) {
      nuita = true;
      break;
    }
  }
  if (!nuita) return false;
  final int maeNoKazu = l.length >= TEISUU.SUU_REKIDAIKIROKUJUNISUU
      ? TEISUU.SUU_REKIDAIKIROKUJUNISUU
      : l.where((x) => !kondo(x)).length;
  return maeNoKazu >= ichi + 1;
}

// ------------------------------------------------------------
// 学内記録を付け始めた年度(2.1.4)
// ------------------------------------------------------------

/// 学内記録を付け始めた年度を残す KantokuData.yobiint4 の番号(2.1.4)
/// 学内記録は総監督をしている大学の分しか残さないので、大学を移ると、移った大学の学内記録はそこから付き始める。
/// 選手の前の自己ベストのうち、この年度より前のものは学内記録に載っていないので、「自身の記録」と見なさない
/// (年度で区切るので、移った年度のうち移る前に走った記録は、載っていたものとして扱う)
const int gakunaiKirokuHajimeBangou = 79;

/// 今日の年度(4月〜12月はその年、1月〜3月は前の年。学年は4月に上がる)
int _nendo(Ghensuu gh) => gh.month >= 4 ? gh.year : gh.year - 1;

/// 総監督の大学を移ったときに、移った大学の学内記録を付け始めた年度を残す(大学画面から。保存もする)
Future<void> gakunaiKirokuHajimeNendoKaku(Ghensuu gh) async {
  final KantokuData? kantoku = _kantoku();
  if (kantoku == null || kantoku.yobiint4.length <= gakunaiKirokuHajimeBangou) return;
  kantoku.yobiint4[gakunaiKirokuHajimeBangou] = _nendo(gh);
  await kantoku.save();
}

/// 今の大学の学内記録を付け始めた年度(分からなければ0。今の年度より後の値は、前のゲームの残りとみなして0)
int _gakunaiHajimeNendo(Ghensuu gh) {
  final KantokuData? kantoku = _kantoku();
  if (kantoku == null || kantoku.yobiint4.length <= gakunaiKirokuHajimeBangou) return 0;
  final int n = kantoku.yobiint4[gakunaiKirokuHajimeBangou];
  if (n <= 0 || n > _nendo(gh)) return 0;
  return n;
}

// ------------------------------------------------------------
// 入口
// ------------------------------------------------------------

/// 結果画面に出す、自分の大学の節目と記録の更新(1人1行、大きい順。出すことがなければ空)
/// [univ] 大学(IDの順)、[senshu] 全選手
List<Fushime> fushimeIchiran(Ghensuu gh, List<UnivData> univ, List<SenshuData> senshu) {
  try {
    final int race = gh.hyojiracebangou;
    if (gh.MYunivid < 0 || gh.MYunivid >= univ.length) return [];
    final UnivData u = univ[gh.MYunivid];
    if (fushimeHonsen(race)) return _matomeru(_ekiden(gh, u, senshu, race));
    if (fushimeKirokuBangou(race) != null) return _matomeru(_kojin(gh, u, senshu, race));
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
/// [hajimeNendo] これより前の年度の記録は見ない(学内記録を付け始めた年度。0なら全部見る)
double? _maeBest(Ghensuu gh, SenshuData s, int k, int race, {int hajimeNendo = 0}) {
  double? best;
  for (final int r in fushimeShumokuRace[k] ?? const <int>[]) {
    for (int g = 1; g <= s.gakunen; g++) {
      if (r == race && g == s.gakunen) continue;
      if (hajimeNendo > 0 && _nendo(gh) - (s.gakunen - g) < hajimeNendo) continue;
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

List<_Koto> _ekiden(Ghensuu gh, UnivData u, List<SenshuData> senshu, int race) {
  if (u.taikaientryflag.length <= race || u.taikaientryflag[race] != 1) return [];
  final KantokuData? kantoku = _kantoku();
  final Kiroku? kiroku = _kiroku();
  final List<_Koto> l = [];
  bool kondo(RekidaiKiroku x) => _kondo(gh, x);

  // チームの総合
  final double sougou = (u.time_race.length > race && u.time_race[race].isNotEmpty)
      ? u.time_race[race][0]
      : TEISUU.DEFAULTTIME;
  if (_timeAri(sougou)) {
    final String t = jikanMoji(sougou);
    // 全体の大会記録の歴代
    final List<RekidaiKiroku> zentai = rekidaiZentaiTaikai(gh, race).yomu();
    final int zIchi = zentai.indexWhere(
      (x) => kondo(x) && x.univname == u.name && (x.time - sougou).abs() < 0.05,
    );
    final int? juraiZentai = _jurai(kantoku, 20);
    bool shin = false;
    if (u.chokuzentaikai_zentaitaikaisinflag == 1 && juraiZentai != null) {
      shin = true;
      final RekidaiKiroku? mae = _maeIchiban(gh, zentai);
      final String dare = (mae != null && (byou(mae.time) - juraiZentai).abs() <= 1)
          ? '${fushimeItsu(gh, mae)}に${mae.univname}大学が出した記録'
          : '前の記録';
      l.add(
        _Koto(
          kagi: '総合',
          juuyou: _jTaikaiShin,
          midashi: '大会新',
          bun: '総合$t。$dareを${_koushinMoji(juraiZentai - byou(sougou))}。',
          soe: '大会新',
        ),
      );
    } else if (_rekidaiDaseru(zentai, zIchi, kondo)) {
      l.add(
        _Koto(
          kagi: '総合',
          juuyou: _jZentaiRekidai(zIchi),
          midashi: '大会歴代${zIchi + 1}位',
          bun: '総合$t。この大会の歴代${zIchi + 1}位の記録です。',
          soe: '大会歴代${zIchi + 1}位',
        ),
      );
    }
    // 学内の総合の歴代
    final List<RekidaiKiroku> gakunai = rekidaiUnivTaikai(u, race).yomu();
    final int gIchi = gakunai.indexWhere((x) => kondo(x) && (x.time - sougou).abs() < 0.05);
    final int? juraiGakunai = _jurai(kantoku, 21);
    if (u.chokuzentaikai_univtaikaisinflag == 1 && juraiGakunai != null) {
      if (!shin) {
        final RekidaiKiroku? mae = _maeIchiban(gh, gakunai);
        final String dare = (mae != null && (byou(mae.time) - juraiGakunai).abs() <= 1)
            ? '${fushimeItsu(gh, mae)}の記録'
            : '前の記録';
        l.add(
          _Koto(
            kagi: '総合',
            juuyou: _jSougouGakunaiShin,
            midashi: '総合の学内新',
            bun: '総合$t。$dareを${_koushinMoji(juraiGakunai - byou(sougou))}。',
            soe: '総合の学内新',
          ),
        );
      }
    } else if (_rekidaiDaseru(gakunai, gIchi, kondo)) {
      l.add(
        _Koto(
          kagi: '総合',
          juuyou: _jGakunaiRekidai(gIchi),
          midashi: '総合の学内歴代${gIchi + 1}位',
          bun: '総合$t。学内の歴代${gIchi + 1}位の記録です。',
          soe: '総合の学内歴代${gIchi + 1}位',
        ),
      );
    }
  }

  // 正月駅伝の往路・復路(全体と学内。記録の並びの1番目が今回で、前の記録があれば新記録)
  if (race == 2 &&
      gh.kukansuu_taikaigoto.length > 2 &&
      gh.kukansuu_taikaigoto[2] == shougatsuKukansuu) {
    for (final int r in const [ouroRace, fukuroRace]) {
      final String mei = r == ouroRace ? '往路' : '復路';
      final double? time = r == ouroRace ? ouroTime(u) : fukuroTime(u, shougatsuKukansuu);
      if (time == null || !_timeAri(time)) continue;
      final String t = jikanMoji(time);
      bool shin = false;
      // 全体
      if (gh.time_zentaitaikaikiroku.length > r) {
        final List<RekidaiKiroku> zentai = rekidaiZentaiTaikai(gh, r).yomu();
        final int zIchi = zentai.indexWhere(
          (x) => kondo(x) && x.univname == u.name && (x.time - time).abs() < 0.05,
        );
        final RekidaiKiroku? mae = _maeIchiban(gh, zentai);
        if (zIchi == 0 && mae != null) {
          shin = true;
          l.add(
            _Koto(
              kagi: mei,
              juuyou: _jOufukuShin,
              midashi: '$mei新',
              bun:
                  '$mei$t。${fushimeItsu(gh, mae)}に${mae.univname}大学が出した記録を'
                  '${_koushinMoji(byou(mae.time) - byou(time))}。',
              soe: '$mei新',
            ),
          );
        } else if (_rekidaiDaseru(zentai, zIchi, kondo)) {
          l.add(
            _Koto(
              kagi: mei,
              juuyou: _jZentaiRekidai(zIchi),
              midashi: '$mei歴代${zIchi + 1}位',
              bun: '$mei$t。$meiの歴代${zIchi + 1}位の記録です。',
              soe: '$mei歴代${zIchi + 1}位',
            ),
          );
        }
      }
      // 学内
      if (u.time_univtaikaikiroku.length > r) {
        final List<RekidaiKiroku> gakunai = rekidaiUnivTaikai(u, r).yomu();
        final int gIchi = gakunai.indexWhere((x) => kondo(x) && (x.time - time).abs() < 0.05);
        final RekidaiKiroku? mae = _maeIchiban(gh, gakunai);
        if (gIchi == 0 && mae != null) {
          if (!shin) {
            l.add(
              _Koto(
                kagi: mei,
                juuyou: _jOufukuGakunaiShin,
                midashi: '$meiの学内新',
                bun:
                    '$mei$t。${fushimeItsu(gh, mae)}の記録を'
                    '${_koushinMoji(byou(mae.time) - byou(time))}。',
                soe: '$meiの学内新',
              ),
            );
          }
        } else if (_rekidaiDaseru(gakunai, gIchi, kondo)) {
          l.add(
            _Koto(
              kagi: mei,
              juuyou: _jGakunaiRekidai(gIchi),
              midashi: '$meiの学内歴代${gIchi + 1}位',
              bun: '$mei$t。学内の歴代${gIchi + 1}位の記録です。',
              soe: '$meiの学内歴代${gIchi + 1}位',
            ),
          );
        }
      }
    }
  }

  // 選手(区間の順)
  final List<SenshuData> soushasha = [
    for (final SenshuData s in senshu)
      if (s.univid == u.id && fushimeChiimuShussou(s, race, s.gakunen)) s,
  ]..sort((a, b) => _entry(a, race, a.gakunen).compareTo(_entry(b, race, b.gakunen)));
  for (final SenshuData s in soushasha) {
    l.addAll(_ekidenSenshu(gh, u, s, race, kantoku, kiroku));
  }
  return l;
}

/// 駅伝の区間[kk]で学内区間新を出した、自分の大学[u]の選手[s]の、前の学内区間記録
/// (今回より前の記録で一番速いもの。エントリーのときに控えた従来の記録[jurai](秒)と合わなければnull)。
/// 前の記録の持ち主が本人なら jishin が true。結果画面と学内メディアの駅伝の結果号で使う
({RekidaiKiroku mae, bool jishin})? fushimeGakunaiKukanMae(
  Ghensuu gh,
  UnivData u,
  SenshuData s,
  int race,
  int kk,
  int jurai,
) {
  try {
    final Kiroku? kiroku = _kiroku();
    if (kiroku == null) return null;
    final RekidaiKiroku? mae = _maeIchiban(gh, _gakunaiKukanRekidai(u, kiroku, race, kk));
    if (mae == null || (byou(mae.time) - jurai).abs() > 1) return null;
    return (mae: mae, jishin: _honnin(gh, mae, s));
  } catch (_) {
    return null;
  }
}

/// 全体の区間記録の歴代(記録画面と同じ、日本人+留学生を合わせた並び)
List<RekidaiKiroku> _zentaiKukanRekidai(Ghensuu gh, Kiroku kiroku, int race, int kk) => rekidaiAwaseru(
  ichii: ichiiZentaiKukan(gh, race, kk).yomu(),
  nihonjin: rekidaiZentaiKukan(kiroku, false, race, kk).yomu(),
  ryuugakusei: rekidaiZentaiKukan(kiroku, true, race, kk).yomu(),
);

/// 学内の区間記録の歴代(同じく合わせた並び)
List<RekidaiKiroku> _gakunaiKukanRekidai(UnivData u, Kiroku kiroku, int race, int kk) => rekidaiAwaseru(
  ichii: ichiiUnivKukan(u, race, kk).yomu(),
  nihonjin: rekidaiUnivKukan(kiroku, false, u.id, race, kk).yomu(),
  ryuugakusei: rekidaiUnivKukan(kiroku, true, u.id, race, kk).yomu(),
);

/// 駅伝を走った選手[s]の出来事(区間記録の歴代・初めての区間賞・12回出走・連続・デビュー)
List<_Koto> _ekidenSenshu(
  Ghensuu gh,
  UnivData u,
  SenshuData s,
  int race,
  KantokuData? kantoku,
  Kiroku? kiroku,
) {
  final List<_Koto> l = [];
  final int g = s.gakunen;
  final int kk = _entry(s, race, g);
  if (kk < 0 || kk >= TEISUU.SUU_MAXKUKANSUU) return l;
  final double t = _time(s, race, g);
  if (!_timeAri(t)) return l;
  final String kagi = 'S${s.id}';
  final FushimeLink honnin = _linkHonnin(gh, s);
  final String basho = '${_namae(s)} ${kk + 1}区';
  final String naka = '$basho ${jikanMoji(t)}。';
  bool kondo(RekidaiKiroku x) => _kondo(gh, x);
  int ichiDoko(List<RekidaiKiroku> rl) => rl.indexWhere((x) => kondo(x) && _honnin(gh, x, s));

  // 区間新(全体)・区間の歴代2〜10位
  bool kukanShin = false;
  final int? juraiZentai = _jurai(kantoku, kk);
  final List<RekidaiKiroku> zentai =
      kiroku == null ? const <RekidaiKiroku>[] : _zentaiKukanRekidai(gh, kiroku, race, kk);
  if (s.chokuzentaikai_zentaikukansinflag == 1 && juraiZentai != null) {
    kukanShin = true;
    String dare = '区間記録';
    List<FushimeLink> maeLink = const [];
    final RekidaiKiroku? maeK = _maeIchiban(gh, zentai);
    if (maeK != null && (byou(maeK.time) - juraiZentai).abs() <= 1) {
      final bool jishin = _honnin(gh, maeK, s);
      dare = jishin
          ? '${fushimeItsu(gh, maeK)}に自身が出した区間記録'
          : '${fushimeItsu(gh, maeK)}に${maeK.univname}大学の${maeK.name}(${maeK.gakunen}年)が出した区間記録';
      maeLink = _linkMae(maeK, jishin);
    }
    l.add(
      _Koto(
        kagi: kagi,
        juuyou: _jKukanShin,
        midashi: '区間新',
        bun: '$naka$dareを${_koushinMoji(juraiZentai - byou(t))}。',
        soe: '区間新',
        link: [honnin, ...maeLink],
      ),
    );
  } else {
    final int zIchi = ichiDoko(zentai);
    if (_rekidaiDaseru(zentai, zIchi, kondo)) {
      l.add(
        _Koto(
          kagi: kagi,
          juuyou: _jZentaiRekidai(zIchi),
          midashi: '区間歴代${zIchi + 1}位',
          bun: '$naka${kk + 1}区の歴代${zIchi + 1}位の記録です。',
          soe: '区間歴代${zIchi + 1}位',
          link: [honnin],
        ),
      );
    }
  }

  // 学内区間新(区間新なら書かない)・学内の区間の歴代2〜10位
  final int? juraiGakunai = _jurai(kantoku, kk + 10);
  if (s.chokuzentaikai_univkukansinflag == 1 && juraiGakunai != null) {
    if (!kukanShin) {
      String dare = '学内の区間記録';
      List<FushimeLink> maeLink = const [];
      final ({RekidaiKiroku mae, bool jishin})? maeK = fushimeGakunaiKukanMae(
        gh,
        u,
        s,
        race,
        kk,
        juraiGakunai,
      );
      if (maeK != null) {
        dare = maeK.jishin
            ? '${fushimeItsu(gh, maeK.mae)}に自身が出した学内記録'
            : '${fushimeItsu(gh, maeK.mae)}に${maeK.mae.name}(${maeK.mae.gakunen}年)が出した学内記録';
        maeLink = _linkMae(maeK.mae, maeK.jishin);
      }
      l.add(
        _Koto(
          kagi: kagi,
          juuyou: _jGakunaiKukanShin,
          midashi: '学内区間新',
          bun: '$naka$dareを${_koushinMoji(juraiGakunai - byou(t))}。',
          soe: '学内区間新',
          link: [honnin, ...maeLink],
        ),
      );
    }
  } else if (kiroku != null && u.time_univkukankiroku.length > race) {
    final List<RekidaiKiroku> gakunai = _gakunaiKukanRekidai(u, kiroku, race, kk);
    final int gIchi = ichiDoko(gakunai);
    if (_rekidaiDaseru(gakunai, gIchi, kondo)) {
      l.add(
        _Koto(
          kagi: kagi,
          juuyou: _jGakunaiRekidai(gIchi),
          midashi: '学内区間歴代${gIchi + 1}位',
          bun: '$naka学内の${kk + 1}区の歴代${gIchi + 1}位の記録です。',
          soe: '学内区間歴代${gIchi + 1}位',
          link: [honnin],
        ),
      );
    }
  }

  // ここから先は「初めて」「続けて」を数えるので、前の学年の記録が欠けている選手には出さない
  if (kirokuKaketeiru(s)) return l;
  final ({int shussou, int kukanshou}) maeHonsen = _maeHonsen(s, race);

  // 初めての区間賞
  if (_juni(s, race, g) == 0 && maeHonsen.kukanshou == 0) {
    l.add(
      _Koto(
        kagi: kagi,
        juuyou: _jHatsuKukanshou,
        midashi: '初の区間賞',
        bun: '$basho。初めての区間賞です。',
        soe: '初の区間賞',
        link: [honnin],
      ),
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
      l.add(
        _Koto(
          kagi: kagi,
          juuyou: _jJuunikai,
          midashi: '12回出走',
          bun: '${_namae(s)}。三大駅伝の12回をすべて走りました。',
          soe: '三大駅伝12回出走',
          link: [honnin],
        ),
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
    l.add(
      _Koto(
        kagi: kagi,
        juuyou: _jRenzoku(renzoku),
        midashi: '$renzoku年連続',
        bun: '${_namae(s)}。$renzoku年続けて${kk + 1}区を走りました。',
        soe: '$renzoku年連続の${kk + 1}区',
        link: [honnin],
      ),
    );
  }

  // 駅伝デビュー(本戦の初めての出走。1年生だけのカスタム駅伝では出さない)
  if (maeHonsen.shussou == 0 && !(race == customRaceBangou && customIchinenDake())) {
    l.add(
      _Koto(
        kagi: kagi,
        juuyou: _jDebut,
        midashi: '駅伝デビュー',
        bun: '$basho。初めての駅伝です。',
        soe: '駅伝デビュー',
        link: [honnin],
      ),
    );
  }
  return l;
}

// ------------------------------------------------------------
// 個人の種目(対校戦・記録会・夏のTT・フルマラソン)
// 結果画面と記事(学内メディアの対校戦の結果号・学内TT特集、箱庭スポーツの夏のTT特集)で同じ判定を使う。
// 結果画面の印(chokuzentaikai_〜)は一番新しい大会の分しか残らないので使わず、記録の並びの中の、
// その大会の年月の記録で判定する(夏のTTの4種目は日が違うので、学内TT特集では種目ごとの月で見る)
// ------------------------------------------------------------

/// 個人の種目の記録の更新の種類(記事に渡すもの)
enum KojinKoushinShurui {
  /// 全体の歴代1位(歴代新)
  rekidaiShin,

  /// 学内の歴代1位(学内新)
  gakunaiShin,

  /// 学内の日本人の歴代1位(留学生が学内記録を持っているとき)
  nihonjinShin,

  /// 学内歴代2位・3位
  gakunaiJuni,
}

/// 個人の種目の記録の更新1つ
class KojinKoushin {
  const KojinKoushin({
    required this.s,
    required this.shurui,
    required this.time,
    this.mae,
    this.jishin = false,
    this.sa = 0,
    this.juni = 0,
  });

  final SenshuData s;
  final KojinKoushinShurui shurui;
  final double time;

  /// 前の記録(ほかの選手のもの。本人の前の記録なら null で [jishin] が true)
  final RekidaiKiroku? mae;
  final bool jishin;

  /// 前の記録から縮めた秒(学内歴代2位・3位では0)
  final int sa;

  /// 学内歴代の順位(0が1位。学内歴代2位・3位のときの1か2)
  final int juni;
}

/// 前の記録と、更新した差(秒)。前の記録がなければnull
/// [l] 速い順の歴代(一人1件)、[ichi] その中の選手[s]の今回の記録の位置、[maeBest] 選手の前の自己ベスト
/// [kondo] 今回の大会の記録か
({RekidaiKiroku? mae, bool jishin, int sa})? _maeKojin(
  Ghensuu gh,
  List<RekidaiKiroku> l,
  int ichi,
  SenshuData s,
  double t,
  double? maeBest,
  bool Function(RekidaiKiroku) kondo,
) {
  // 並びに前からの記録が1つもなければ(記録を付け始めたばかり・リセットした直後)、出さない
  if (!l.any((x) => !kondo(x))) return null;
  // 今回の記録より下の、前からの記録で一番速いもの(本人の前の記録は、一人1件なので並びにはない)
  RekidaiKiroku? hoka;
  for (int i = ichi + 1; i < l.length; i++) {
    if (kondo(l[i])) continue;
    if (_honnin(gh, l[i], s)) continue;
    hoka = l[i];
    break;
  }
  if (maeBest != null && (hoka == null || maeBest < hoka.time)) {
    if (maeBest <= t) return null;
    return (mae: null, jishin: true, sa: byou(maeBest) - byou(t));
  }
  if (hoka == null) return null;
  return (mae: hoka, jishin: false, sa: byou(hoka.time) - byou(t));
}

/// 全体の歴代(記録画面と同じ、日本人+留学生を合わせた一人1件の並び)
List<RekidaiKiroku> _zentaiKojinRekidai(Ghensuu gh, Kiroku kiroku, int k) => rekidaiAwaseru(
  ichii: ichiiZentaiKojin(gh, k).yomu(),
  nihonjin: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, false, k).yomu()),
  ryuugakusei: rekidaiHitoriIkken(rekidaiZentaiKojin(kiroku, true, k).yomu()),
  hitoriIkken: true,
);

/// 学内の歴代(同じく一人1件)
List<RekidaiKiroku> _gakunaiKojinRekidai(UnivData u, Kiroku kiroku, int k) => rekidaiAwaseru(
  ichii: ichiiUnivKojin(u, k).yomu(),
  nihonjin: rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, false, u.id, k).yomu()),
  ryuugakusei: rekidaiHitoriIkken(rekidaiUnivKojin(kiroku, true, u.id, k).yomu()),
  hitoriIkken: true,
);

/// 個人の種目で走った選手1人の、記録の更新(全部。どれもなければ空の結果)
class _KojinKekka {
  _KojinKekka(this.s, this.t);
  final SenshuData s;
  final double t;

  /// 全体の歴代1位
  KojinKoushin? rekidaiShin;

  /// 全体の歴代の順位(0から。2〜10位を出せるときだけ1〜9、なければ-1)
  int zentaiJuni = -1;

  /// 学内の歴代1位
  KojinKoushin? gakunaiShin;

  /// 学内の日本人の歴代1位
  KojinKoushin? nihonjinShin;

  /// 学内の歴代の順位(0から。2〜10位を出せるときだけ1〜9、なければ-1)
  int gakunaiJuni = -1;
}

/// 個人の種目の大会[race]での、自分の大学[u]の選手の記録の更新(速い順。どれもない選手も入れる)
/// [tsuki] 大会の月(今日の大会ならnull。学内TT特集では、夏のTTの種目ごとの月を渡す)
List<_KojinKekka> _kojinBunseki(
  Ghensuu gh,
  UnivData u,
  List<SenshuData> senshu,
  int race, {
  int? tsuki,
}) {
  final int? k = fushimeKirokuBangou(race);
  final Kiroku? kiroku = _kiroku();
  if (k == null || kiroku == null) return [];
  final int m = tsuki ?? gh.month;
  bool kondo(RekidaiKiroku x) => x.year == gh.year && x.month == m;
  final List<RekidaiKiroku> zentai = _zentaiKojinRekidai(gh, kiroku, k);
  final List<RekidaiKiroku> gakunai = _gakunaiKojinRekidai(u, kiroku, k);
  final List<RekidaiKiroku> nihonjin = rekidaiHitoriIkken(
    rekidaiUnivKojin(kiroku, false, u.id, k).yomu(),
  );
  // 学内記録を付け始めた年度(大学を移ったあと。それより前の自己ベストは学内記録に載っていない)
  final int hajime = _gakunaiHajimeNendo(gh);

  // 走った自分の大学の選手(速い順)
  final List<SenshuData> soushasha = [
    for (final SenshuData s in senshu)
      if (s.univid == u.id && _entry(s, race, s.gakunen) >= 0 && _timeAri(_time(s, race, s.gakunen)))
        s,
  ]..sort((a, b) => _time(a, race, a.gakunen).compareTo(_time(b, race, b.gakunen)));

  // 今回の記録の位置(番号で探す)
  int ichiDoko(List<RekidaiKiroku> l, SenshuData s, double t) =>
      l.indexWhere((x) => kondo(x) && _honnin(gh, x, s));

  final List<_KojinKekka> kekka = [];
  for (final SenshuData s in soushasha) {
    final double t = _time(s, race, s.gakunen);
    final _KojinKekka x = _KojinKekka(s, t);
    kekka.add(x);
    // 前の自己ベスト(全体の記録は全大学の分を残しているので全部、学内の記録は付け始めた年度から)
    final double? maeBestZentai = _maeBest(gh, s, k, race);
    final double? maeBest = _maeBest(gh, s, k, race, hajimeNendo: hajime);

    // 全体の歴代
    final int zIchi = ichiDoko(zentai, s, t);
    if (zIchi == 0) {
      final ({RekidaiKiroku? mae, bool jishin, int sa})? mae =
          _maeKojin(gh, zentai, 0, s, t, maeBestZentai, kondo);
      if (mae != null) {
        x.rekidaiShin = KojinKoushin(
          s: s,
          shurui: KojinKoushinShurui.rekidaiShin,
          time: t,
          mae: mae.mae,
          jishin: mae.jishin,
          sa: mae.sa,
        );
      }
    } else if (_rekidaiDaseru(zentai, zIchi, kondo, maeBest: maeBestZentai)) {
      x.zentaiJuni = zIchi;
    }

    // 学内の歴代
    final int gIchi = ichiDoko(gakunai, s, t);
    if (gIchi == 0) {
      final ({RekidaiKiroku? mae, bool jishin, int sa})? mae =
          _maeKojin(gh, gakunai, 0, s, t, maeBest, kondo);
      if (mae != null) {
        x.gakunaiShin = KojinKoushin(
          s: s,
          shurui: KojinKoushinShurui.gakunaiShin,
          time: t,
          mae: mae.mae,
          jishin: mae.jishin,
          sa: mae.sa,
        );
      }
    } else if (_rekidaiDaseru(gakunai, gIchi, kondo, maeBest: maeBest)) {
      x.gakunaiJuni = gIchi;
    }

    // 日本人学内新(留学生が学内記録を持っているとき)
    if (s.hirou != 1 && gIchi != 0 && ichiDoko(nihonjin, s, t) == 0) {
      final ({RekidaiKiroku? mae, bool jishin, int sa})? mae =
          _maeKojin(gh, nihonjin, 0, s, t, maeBest, kondo);
      if (mae != null) {
        x.nihonjinShin = KojinKoushin(
          s: s,
          shurui: KojinKoushinShurui.nihonjinShin,
          time: t,
          mae: mae.mae,
          jishin: mae.jishin,
          sa: mae.sa,
        );
      }
    }
  }
  return kekka;
}

/// 個人の種目の大会[race]での、自分の大学[u]の選手の記録の更新(記事に渡すもの。1人に一番大きいもの1つ。速い順)
/// 記事には今までどおり、歴代新・学内新・日本人学内新・学内歴代2位と3位だけを書く
/// [tsuki] 大会の月(今日の大会ならnull。学内TT特集では、夏のTTの種目ごとの月を渡す)
List<KojinKoushin> fushimeKojinKoushin(
  Ghensuu gh,
  UnivData u,
  List<SenshuData> senshu,
  int race, {
  int? tsuki,
}) {
  try {
    final List<KojinKoushin> l = [];
    for (final _KojinKekka x in _kojinBunseki(gh, u, senshu, race, tsuki: tsuki)) {
      final KojinKoushin? k =
          x.rekidaiShin ??
          x.gakunaiShin ??
          x.nihonjinShin ??
          ((x.gakunaiJuni == 1 || x.gakunaiJuni == 2)
              ? KojinKoushin(
                  s: x.s,
                  shurui: KojinKoushinShurui.gakunaiJuni,
                  time: x.t,
                  juni: x.gakunaiJuni,
                )
              : null);
      if (k != null) l.add(k);
    }
    return l;
  } catch (_) {
    return [];
  }
}

/// 個人の種目の大会[race]で、全体の歴代記録を塗り替えた選手(どの大学でも。なければnull)
/// [tsuki] 大会の月(今日の大会ならnull)。箱庭スポーツの夏のTT特集で使う
KojinKoushin? fushimeZentaiShin(
  Ghensuu gh,
  List<UnivData> univ,
  List<SenshuData> senshu,
  int race, {
  int? tsuki,
}) {
  try {
    final int? k = fushimeKirokuBangou(race);
    final Kiroku? kiroku = _kiroku();
    if (k == null || kiroku == null) return null;
    final int m = tsuki ?? gh.month;
    bool kondo(RekidaiKiroku x) => x.year == gh.year && x.month == m;
    final List<RekidaiKiroku> zentai = _zentaiKojinRekidai(gh, kiroku, k);
    if (zentai.isEmpty || !kondo(zentai.first)) return null;
    final RekidaiKiroku ichiban = zentai.first;
    if (ichiban.bangou == null) return null;
    for (final SenshuData s in senshu) {
      // 番号で選手を探す
      if (!_honnin(gh, ichiban, s) || _entry(s, race, s.gakunen) < 0) continue;
      final double t = _time(s, race, s.gakunen);
      if (!_timeAri(t)) continue;
      if (s.univid < 0 || s.univid >= univ.length) continue;
      final ({RekidaiKiroku? mae, bool jishin, int sa})? mae =
          _maeKojin(gh, zentai, 0, s, t, _maeBest(gh, s, k, race), kondo);
      if (mae == null) return null;
      return KojinKoushin(
        s: s,
        shurui: KojinKoushinShurui.rekidaiShin,
        time: t,
        mae: mae.mae,
        jishin: mae.jishin,
        sa: mae.sa,
      );
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// 前の記録の持ち主のリンク(結果画面。[_dare]で名前を書くときだけ)
List<FushimeLink> _linkMaeKojin(KojinKoushin x) => _linkMae(x.mae, x.jishin);

/// 前の記録の言い方(結果画面。「昨年に山本 翔(4年)が出した記録」)
String _dare(Ghensuu gh, KojinKoushin x) {
  final RekidaiKiroku? mae = x.mae;
  if (x.jishin) return '自身の記録';
  if (mae == null) return '前の記録';
  final String daigaku = x.shurui == KojinKoushinShurui.rekidaiShin ? '${mae.univname}大学の' : '';
  return '${fushimeItsu(gh, mae)}に$daigaku${mae.name}(${mae.gakunen}年)が出した記録';
}

/// 結果画面の出来事(個人の種目)
List<_Koto> _kojin(Ghensuu gh, UnivData u, List<SenshuData> senshu, int race) {
  final List<_Koto> l = [];
  for (final _KojinKekka x in _kojinBunseki(gh, u, senshu, race)) {
    final String kagi = 'S${x.s.id}';
    final FushimeLink honnin = _linkHonnin(gh, x.s);
    final String naka = '${_namae(x.s)} ${jikanMoji(x.t)}。';
    final KojinKoushin? rs = x.rekidaiShin;
    if (rs != null) {
      l.add(
        _Koto(
          kagi: kagi,
          juuyou: _jRekidaiShin,
          midashi: '歴代新',
          bun: '$naka${_dare(gh, rs)}を${_koushinMoji(rs.sa)}。',
          soe: '歴代新',
          link: [honnin, ..._linkMaeKojin(rs)],
        ),
      );
    } else if (x.zentaiJuni >= 1) {
      l.add(
        _Koto(
          kagi: kagi,
          juuyou: _jZentaiRekidai(x.zentaiJuni),
          midashi: '歴代${x.zentaiJuni + 1}位',
          bun: '$naka全体の歴代${x.zentaiJuni + 1}位の記録です。',
          soe: '歴代${x.zentaiJuni + 1}位',
          link: [honnin],
        ),
      );
    }
    final KojinKoushin? gs = x.gakunaiShin;
    if (gs != null) {
      // 歴代新なら学内新でもあるので書かない
      if (rs == null) {
        l.add(
          _Koto(
            kagi: kagi,
            juuyou: _jGakunaiShin,
            midashi: '学内新',
            bun: '$naka${_dare(gh, gs)}を${_koushinMoji(gs.sa)}。',
            soe: '学内新',
            link: [honnin, ..._linkMaeKojin(gs)],
          ),
        );
      }
    } else if (x.gakunaiJuni >= 1) {
      l.add(
        _Koto(
          kagi: kagi,
          juuyou: _jGakunaiRekidai(x.gakunaiJuni),
          midashi: '学内歴代${x.gakunaiJuni + 1}位',
          bun: '$naka学内の歴代${x.gakunaiJuni + 1}位の記録です。',
          soe: '学内歴代${x.gakunaiJuni + 1}位',
          link: [honnin],
        ),
      );
    }
    final KojinKoushin? ns = x.nihonjinShin;
    if (ns != null) {
      l.add(
        _Koto(
          kagi: kagi,
          juuyou: _jNihonjinGakunaiShin,
          midashi: '日本人学内新',
          bun: '$naka${_dare(gh, ns)}を${_koushinMoji(ns.sa)}。',
          soe: '日本人学内新',
          link: [honnin, ..._linkMaeKojin(ns)],
        ),
      );
    }
  }
  return l;
}
