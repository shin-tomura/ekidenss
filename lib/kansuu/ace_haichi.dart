import 'dart:math' as math; // 持ちタイムの換算(距離の比の1.06乗)
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/konki_best.dart' show hikakuMochiTime, hikakuMochiTimeGakuren;

// ------------------------------------------------------------
// エース・準エースと、全体の上位10人の決め方(2.1.3)
// 「スキップして統計データ取得」のエース・準エースが走った区間(toukei_ace.dart)と、
// レース前の画面の「エースの配置」(screens/Modal_aceHaichi.dart)で同じ決め方を使う。
//
// ・5000m・1万m・ハーフ・ロード1万の4種目で、それぞれ持ちタイムの順位を付け、4つの順位の平均の良い順に並べる
//   ・エース・準エース: 1つの大学の全選手(区間エントリーされていない選手も、留学生も含む)の中での1番手・2番手
//   ・全体の上位10人: その駅伝に区間エントリーされた全選手(補欠・当日変更で外れた選手と、
//     正月駅伝は学連選抜の選手も含む)の中での上位10人
// ・持ちタイムは、コンピュータの大学が区間配置で比べるのと同じ今季ベスト(なければ自己ベスト。hikakuMochiTime)
// ・記録のない種目は、近い種目の記録から換算する(記事の tenbouMochiTime や区間配置の見積もりと同じく、
//   距離の比の1.06乗を掛ける)
//   ・5000m・1万m・ハーフは、ほかの2つのうち距離の近いほうから。どちらもなければ、ロード1万を1万mとみなして換算する
//   ・ロード1万がなければ、1万m(換算したものも)をそのまま使う(距離が同じなので)
//   ・4種目とも記録がなければ、その種目の最下位(記録のある人数+1位)
//   (2.1.3の開発中は、記録のない種目を最下位にしていた。1万mやハーフの記録がまだない1年生が、
//    強くても上位に入れなかったので換算にした)
// ・同じタイムは同じ順位。平均が同じなら1万m(換算したものも)の速いほう、それも同じなら選手のidの順
// ・体調・調子は使わない(持ちタイムと区間エントリーは、ほかの画面でも見られる)
// ------------------------------------------------------------

/// 4種目の距離(m)。並びは aceMochiTimes の並び(5000m・1万m・ハーフ・ロード1万)
const List<double> _kyori = [5000.0, 10000.0, 21097.5, 10000.0];

/// 有効な持ちタイムか(記録がなければnull)
double? _yuukou(double t) => (t > 0 && t < TEISUU.DEFAULTTIME) ? t : null;

/// 4種目(5000m・1万m・ハーフ・ロード1万)の持ちタイム(記録がなければ換算。換算もできなければnull)
/// [mochi] は time_bestkiroku の番号の種目の持ちタイム(記録がなければnull)
List<double?> aceMochiTimes(double? Function(int idx) mochi) {
  final List<double?> track = [mochi(0), mochi(1), mochi(2)];
  final double? road = mochi(6);
  double? kansan(int i) {
    final double? t = track[i];
    if (t != null) return t;
    final List<int> kouho = [0, 1, 2]
      ..remove(i)
      ..sort((a, b) => (_kyori[a] - _kyori[i]).abs().compareTo((_kyori[b] - _kyori[i]).abs()));
    for (final int c in kouho) {
      final double? tc = track[c];
      if (tc != null) return tc * math.pow(_kyori[i] / _kyori[c], 1.06).toDouble();
    }
    // トラックの記録がなければ、ロード1万を1万mとみなして換算する
    if (road != null) return road * math.pow(_kyori[i] / 10000.0, 1.06).toDouble();
    return null;
  }

  final double? ichiman = kansan(1);
  return [kansan(0), ichiman, kansan(2), road ?? ichiman];
}

/// 選手[s]の4種目の持ちタイム
List<double?> aceMochiTimesSenshu(SenshuData s) =>
    aceMochiTimes((int idx) => _yuukou(hikakuMochiTime(s, idx)));

/// 学連選抜の選手[g]の4種目の持ちタイム
List<double?> aceMochiTimesGakuren(Senshu_Gakuren_Data g) =>
    aceMochiTimes((int idx) => _yuukou(hikakuMochiTimeGakuren(g, idx)));

/// 並んだタイム[narabi](速い順)のうち、[t]より速いものの数
int _hayaiKazu(List<double> narabi, double t) {
  int lo = 0;
  int hi = narabi.length;
  while (lo < hi) {
    final int mid = (lo + hi) >> 1;
    if (narabi[mid] < t) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// 選手ごとの4種目の持ちタイム[times]を、順位の平均の良い順に並べた番号([times]の添字)
/// [ids] は平均も1万mも同じときに比べる選手のid
List<int> aceJuniJun(List<List<double?>> times, List<int> ids) {
  final int n = times.length;
  final List<double> goukei = List.filled(n, 0.0);
  for (int j = 0; j < 4; j++) {
    final List<double> ari = [
      for (final List<double?> l in times)
        if (l[j] != null) l[j]!,
    ]..sort();
    for (int i = 0; i < n; i++) {
      final double? t = times[i][j];
      goukei[i] += t == null ? ari.length + 1 : _hayaiKazu(ari, t) + 1;
    }
  }
  return List.generate(n, (i) => i)
    ..sort((a, b) {
      final int c = goukei[a].compareTo(goukei[b]);
      if (c != 0) return c;
      final double ta = times[a][1] ?? TEISUU.DEFAULTTIME;
      final double tb = times[b][1] ?? TEISUU.DEFAULTTIME;
      final int c2 = ta.compareTo(tb);
      if (c2 != 0) return c2;
      return ids[a].compareTo(ids[b]);
    });
}

/// 1つの大学の選手[list]を、学内順位の平均の良い順に並べる(1番手がエース、2番手が準エース)
List<SenshuData> aceJunSenshu(List<SenshuData> list) {
  final List<int> jun = aceJuniJun(
    [for (final SenshuData s in list) aceMochiTimesSenshu(s)],
    [for (final SenshuData s in list) s.id],
  );
  return [for (final int i in jun) list[i]];
}

// ------------------------------------------------------------
// レース前の画面の「エースの配置」の集計(screens/Modal_aceHaichi.dart で出す)
// ・区間の値(entrykukan_race): 0〜区間数-1が区間、-1が補欠、-2が一次エントリー外、
//   -100以下が当日変更で外れた選手(-(100+区間))
// ・出場している大学は、一次エントリーされた選手(区間の値が-2でない選手)がいる大学
//   (一次エントリーのときに、全大学の全選手をいったん-2にするので、出場していない大学は全員-2)
// ・正月駅伝の学連選抜の選手は、元の大学の選手のデータでは-2のまま(結果を写すのはレースのあと)なので、
//   学連選抜のデータ(gakurenSenshuBox)から読む
// ------------------------------------------------------------

/// 区間の値の分け方
enum AceBasho { kukan, hoketsu, hazureta, entryGai }

/// 区間の値[code]の分け方
AceBasho aceBasho(int code, int kukansuu) {
  if (code >= 0 && code < kukansuu) return AceBasho.kukan;
  if (code <= -100) return AceBasho.hazureta;
  if (code == -1) return AceBasho.hoketsu;
  return AceBasho.entryGai;
}

/// 区間の値[code]の文(「2区」「補欠」「当日変更で外れた」「一次エントリー外」)
String aceBashoMoji(int code, int kukansuu) {
  switch (aceBasho(code, kukansuu)) {
    case AceBasho.kukan:
      return '${code + 1}区';
    case AceBasho.hoketsu:
      return '補欠';
    case AceBasho.hazureta:
      return '当日変更で外れた';
    case AceBasho.entryGai:
      return '一次エントリー外';
  }
}

/// 小窓に出す選手1人分
class AceSenshu {
  final String name;
  final int gakunen;

  /// 大学の呼び方(学連選抜の選手は「学連選抜(○○大)」)
  final String daigaku;

  /// 区間の値
  final int code;

  const AceSenshu(this.name, this.gakunen, this.daigaku, this.code);
}

/// 「エースの配置」の集計の結果
class AceHaichiKekka {
  final int kukansuu;

  /// エース・準エースを数えた大学の数
  final int univSuu;

  /// [0]エース・[1]準エース・[2]上位10人 の、区間ごとの人数
  final List<List<int>> kukan;

  /// [0]エース・[1]準エース・[2]上位10人 の、補欠・当日変更で外れた・一次エントリー外の人数
  final List<int> hoketsu;
  final List<int> hazureta;
  final List<int> entryGai;

  /// 自分の大学のエース・準エース(出場していなければ空)
  final List<AceSenshu> jibun;

  /// 全体の上位10人(並びの順)
  final List<AceSenshu> joui;

  const AceHaichiKekka({
    required this.kukansuu,
    required this.univSuu,
    required this.kukan,
    required this.hoketsu,
    required this.hazureta,
    required this.entryGai,
    required this.jibun,
    required this.joui,
  });
}

/// 選手[s]の駅伝[race]の区間の値(読めなければ-2)
int _code(List<List<int>> entry, int gakunen, int race) {
  if (gakunen < 1 || entry.length <= race || entry[race].length < gakunen) return -2;
  return entry[race][gakunen - 1];
}

/// 駅伝[race]の「エースの配置」を集計する
/// [univMei] は大学idから呼び方を引く表、[gakuren] は学連選抜の選手(出場しないときは空)
AceHaichiKekka aceHaichiKeisan({
  required int race,
  required int kukansuu,
  required Iterable<SenshuData> senshu,
  required Iterable<Senshu_Gakuren_Data> gakuren,
  required Map<int, String> univMei,
  required int myUnivid,
}) {
  final int ks = kukansuu.clamp(1, 10);
  final List<List<int>> kukan = [List.filled(ks, 0), List.filled(ks, 0), List.filled(ks, 0)];
  final List<int> hoketsu = [0, 0, 0];
  final List<int> hazureta = [0, 0, 0];
  final List<int> entryGai = [0, 0, 0];
  void kazoeru(int retsu, int code) {
    switch (aceBasho(code, ks)) {
      case AceBasho.kukan:
        kukan[retsu][code]++;
        break;
      case AceBasho.hoketsu:
        hoketsu[retsu]++;
        break;
      case AceBasho.hazureta:
        hazureta[retsu]++;
        break;
      case AceBasho.entryGai:
        entryGai[retsu]++;
        break;
    }
  }

  // 大学ごとに分ける
  final Map<int, List<SenshuData>> univBetsu = {};
  for (final SenshuData s in senshu) {
    if (s.gakunen < 1 || s.gakunen > TEISUU.GAKUNENSUU) continue;
    univBetsu.putIfAbsent(s.univid, () => []).add(s);
  }
  final List<int> univJun = univBetsu.keys.toList()..sort();

  int univSuu = 0;
  List<AceSenshu> jibun = const [];
  // 全体の上位10人を選ぶ対象(区間エントリーされた全選手)
  final List<AceSenshu> taishou = [];
  final List<List<double?>> taishouTime = [];
  final List<int> taishouId = [];
  for (final int u in univJun) {
    final List<SenshuData> list = univBetsu[u]!;
    // 一次エントリーされた選手がいない大学は、出場していない
    if (!list.any((s) => _code(s.entrykukan_race, s.gakunen, race) != -2)) continue;
    univSuu++;
    final String mei = univMei[u] ?? '';
    final List<SenshuData> narabi = aceJunSenshu(list);
    final List<AceSenshu> ace = [];
    for (int i = 0; i < 2 && i < narabi.length; i++) {
      final SenshuData s = narabi[i];
      final int code = _code(s.entrykukan_race, s.gakunen, race);
      kazoeru(i, code);
      ace.add(AceSenshu(s.name, s.gakunen, mei, code));
    }
    if (u == myUnivid) jibun = ace;
    for (final SenshuData s in list) {
      final int code = _code(s.entrykukan_race, s.gakunen, race);
      if (aceBasho(code, ks) == AceBasho.entryGai) continue;
      taishou.add(AceSenshu(s.name, s.gakunen, mei, code));
      taishouTime.add(aceMochiTimesSenshu(s));
      taishouId.add(s.id);
    }
  }
  for (final Senshu_Gakuren_Data g in gakuren) {
    final int code = _code(g.entrykukan_race, g.gakunen, race);
    if (aceBasho(code, ks) == AceBasho.entryGai) continue;
    final String moto = univMei[g.univid];
    taishou.add(
      AceSenshu(g.name, g.gakunen, moto == null || moto.isEmpty ? '学連選抜' : '学連選抜($moto)', code),
    );
    taishouTime.add(aceMochiTimesGakuren(g));
    taishouId.add(g.id);
  }
  final List<int> jun = aceJuniJun(taishouTime, taishouId);
  final List<AceSenshu> joui = [
    for (int i = 0; i < 10 && i < jun.length; i++) taishou[jun[i]],
  ];
  for (final AceSenshu s in joui) {
    kazoeru(2, s.code);
  }
  return AceHaichiKekka(
    kukansuu: ks,
    univSuu: univSuu,
    kukan: kukan,
    hoketsu: hoketsu,
    hazureta: hazureta,
    entryGai: entryGai,
    jibun: jibun,
    joui: joui,
  );
}
