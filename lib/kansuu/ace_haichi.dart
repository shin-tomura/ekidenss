import 'dart:math' as math; // 偏差値(標準偏差)
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/konki_best.dart' show hikakuMochiTime, hikakuMochiTimeGakuren;

// ------------------------------------------------------------
// エース・準エースと、全体の上位10人の決め方(2.1.3)
// 「スキップして統計データ取得」のエース・準エースが走った区間(toukei_ace.dart)と、
// レース前の画面の「エースの配置」(screens/Modal_aceHaichi.dart)で同じ決め方を使う。
//
// ・物差しは駅伝ごとに、その駅伝の区間の距離で決める(AceOmomi)
//   ・区間ごとに合う種目(aceKukanShumoku): 1〜3区は距離の種目(7.5km以下は5000m、15km以下は1万m、
//     それより長いとハーフ。記事の kukanKihonShumoku と同じ区切り)、4区以降は15km以下ならロード1万、
//     15km超ならハーフ(区間適性の見立ての tekiseiNarabiShumoku と同じ。4区以降は単独走でロード適性がまるごと効くため)
//   ・山登り・山下り・アップダウンの区間も距離の種目で見る(山の適性は区間適性の見立てで見る。
//     エースは、ふつうに思う「その駅伝の主力」に近づけるため)
//   ・種目ごとの重みは、その種目で見る区間の距離の合計の割合(初期のコースなら、正月駅伝はハーフだけ、
//     11月駅伝は1万m・ロード1万・ハーフがほぼ3分の1ずつ、10月駅伝はロード1万が半分・1万mと5000m)
// ・持ちタイム(今季ベスト。なければ自己ベスト。hikakuMochiTime)を、種目ごとに全選手(全大学・全学年。留学生も含む)の
//   中での偏差値にし(AceKijun。求め方はレーダーチャートと同じで、1〜10点への換算と頭打ちはしない)、
//   重みで平均した点数の高い順に並べる
//   ・記録のない種目は除き、残りの重みで平均する(対校戦と夏のタイムトライアルは全員が走るので、ふつうはそろう。
//     重みのある種目の記録が1つもなければ一番下)
//   ・点数が同じなら、重みが一番大きい種目の持ちタイムの速いほう(正月駅伝ならハーフ)、それも同じなら選手のidの順
//   ・エース・準エース: 1つの大学の全選手(区間エントリーされていない選手も、留学生も含む)の中での1番手・2番手
//   ・全体の上位10人: その駅伝に区間エントリーされた全選手(補欠・当日変更で外れた選手と、
//     正月駅伝は学連選抜の選手も含む)の中での上位10人
// ・2.1.3の開発中のいきさつ: はじめは5000m・1万m・ハーフ・ロード1万の学内順位の平均で決めていたが、
//   バランス型の選手がエースになりやすく、タイム差も見られなかったので偏差値にした(記録のない種目の換算もやめた)。
//   そのあと、得意な2種目の平均、1万m・ハーフ・ロード1万の平均と試したが、どの駅伝でも同じ物差しだと、
//   長い区間ばかりの正月駅伝で10kmが得意な選手がエースになるので、駅伝ごとの物差しにした
// ・体調・調子は使わない(持ちタイムと区間エントリーは、ほかの画面でも見られる)
// ------------------------------------------------------------

/// 使う種目(time_bestkiroku の番号。5000m・1万m・ハーフ・ロード1万)
const List<int> aceShumoku = [0, 1, 2, 6];

/// 種目の呼び方(aceShumoku の並び)
const List<String> aceShumokuMei = ['5000m', '1万m', 'ハーフ', 'ロード1万'];

/// 重みが同じときに、点数が同じ選手を比べる種目を選ぶ順(長い種目から。aceShumoku の中の位置)
const List<int> _hikakuJun = [2, 3, 1, 0];

/// 区間[k](0が1区)の距離[kyori](m)に合う種目(time_bestkiroku の番号)
int aceKukanShumoku(int k, double kyori) {
  final int kihon = kyori <= 7500 ? 0 : (kyori <= 15000 ? 1 : 2);
  if (kihon <= 1 && k >= 3) return 6;
  return kihon;
}

/// 駅伝ごとの物差しの重み(aceShumoku の並び。合計1)と、点数が同じときに比べる種目
class AceOmomi {
  final List<double> omomi;

  /// 点数が同じときに比べる種目(aceShumoku の中の位置。重みが一番大きい種目)
  final int hikaku;

  const AceOmomi._(this.omomi, this.hikaku);

  /// 区間の距離[kukanKyori](m。0が1区)の最初の[kukansuu]区間から作る
  factory AceOmomi.tsukuru(List<double> kukanKyori, int kukansuu) {
    final List<double> w = List.filled(aceShumoku.length, 0.0);
    double goukei = 0.0;
    for (int k = 0; k < kukansuu && k < kukanKyori.length; k++) {
      final double d = kukanKyori[k];
      if (d <= 0) continue;
      final int j = aceShumoku.indexOf(aceKukanShumoku(k, d));
      if (j < 0) continue;
      w[j] += d;
      goukei += d;
    }
    if (goukei <= 0) {
      // 区間の距離が読めなければ、1万mだけで見る
      w[1] = 1.0;
      goukei = 1.0;
    }
    final List<double> omomi = [for (final double v in w) v / goukei];
    int hikaku = _hikakuJun.first;
    for (final int j in _hikakuJun) {
      if (omomi[j] > omomi[hikaku]) hikaku = j;
    }
    return AceOmomi._(omomi, hikaku);
  }

  /// 重みの文(「ハーフ 61%・ロード1万 35%…」。重みの大きい順。重みのない種目は書かない)
  String moji() {
    final List<int> jun = [for (int j = 0; j < omomi.length; j++) if (omomi[j] > 0) j]
      ..sort((a, b) => omomi[b].compareTo(omomi[a]));
    return [for (final int j in jun) '${aceShumokuMei[j]} ${(omomi[j] * 100).round()}%'].join('・');
  }
}

/// 有効な持ちタイムか(記録がなければnull)
double? _yuukou(double t) => (t > 0 && t < TEISUU.DEFAULTTIME) ? t : null;

/// 選手[s]の4種目の持ちタイム(aceShumoku の並び。記録がなければnull)
List<double?> aceMochiTimesSenshu(SenshuData s) => [
  for (final int idx in aceShumoku) _yuukou(hikakuMochiTime(s, idx)),
];

/// 学連選抜の選手[g]の4種目の持ちタイム(aceShumoku の並び。記録がなければnull)
List<double?> aceMochiTimesGakuren(Senshu_Gakuren_Data g) => [
  for (final int idx in aceShumoku) _yuukou(hikakuMochiTimeGakuren(g, idx)),
];

/// 偏差値の物差し(4種目それぞれの、全選手の持ちタイムの平均と標準偏差)
class AceKijun {
  final List<double> heikin;
  final List<double> hensa;
  const AceKijun._(this.heikin, this.hensa);

  /// 全選手[zen]から作る(学連選抜の選手は元の大学の選手と同じ人なので、大学の選手のデータだけで作る)
  factory AceKijun.tsukuru(Iterable<SenshuData> zen) {
    final List<List<double>> pool = [for (int j = 0; j < aceShumoku.length; j++) <double>[]];
    for (final SenshuData s in zen) {
      final List<double?> t = aceMochiTimesSenshu(s);
      for (int j = 0; j < aceShumoku.length; j++) {
        final double? x = t[j];
        if (x != null) pool[j].add(x);
      }
    }
    final List<double> heikin = [];
    final List<double> hensa = [];
    for (final List<double> l in pool) {
      if (l.isEmpty) {
        heikin.add(0.0);
        hensa.add(0.0);
        continue;
      }
      final double m = l.reduce((a, b) => a + b) / l.length;
      final double v = l.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / l.length;
      heikin.add(m);
      hensa.add(math.sqrt(v));
    }
    return AceKijun._(heikin, hensa);
  }

  /// 種目[j](aceShumoku の中の位置)のタイム[t]の偏差値(速いほど高い。標準偏差が0なら50)
  double hensachi(int j, double t) =>
      hensa[j] == 0 ? 50.0 : 50.0 + 10.0 * (heikin[j] - t) / hensa[j];

  /// 持ちタイム[times](aceShumoku の並び)の点数(重み[o]で平均した偏差値。記録のない種目は除き、
  /// 残りの重みで平均する。重みのある種目の記録が1つもなければnull)
  double? tensuu(List<double?> times, AceOmomi o) {
    double wa = 0.0;
    double omomi = 0.0;
    for (int j = 0; j < times.length && j < o.omomi.length; j++) {
      final double? t = times[j];
      if (t == null || o.omomi[j] <= 0) continue;
      wa += o.omomi[j] * hensachi(j, t);
      omomi += o.omomi[j];
    }
    if (omomi <= 0) return null;
    return wa / omomi;
  }
}

/// 選手ごとの持ちタイム[times]を、駅伝の物差し[o]での点数の高い順に並べた番号([times]の添字)
/// [ids] は点数も比べる種目のタイムも同じときに比べる選手のid
List<int> aceJun(AceKijun kijun, AceOmomi o, List<List<double?>> times, List<int> ids) {
  final List<double?> ten = [for (final List<double?> t in times) kijun.tensuu(t, o)];
  return List.generate(times.length, (i) => i)
    ..sort((a, b) {
      final double ta = ten[a] ?? double.negativeInfinity;
      final double tb = ten[b] ?? double.negativeInfinity;
      final int c = tb.compareTo(ta);
      if (c != 0) return c;
      final double ia = times[a][o.hikaku] ?? TEISUU.DEFAULTTIME;
      final double ib = times[b][o.hikaku] ?? TEISUU.DEFAULTTIME;
      final int c2 = ia.compareTo(ib);
      if (c2 != 0) return c2;
      return ids[a].compareTo(ids[b]);
    });
}

/// 1つの大学の選手[list]を、駅伝の物差し[o]での点数の高い順に並べる(1番手がエース、2番手が準エース)
/// [kijun] は全選手で作った偏差値の物差し
List<SenshuData> aceJunSenshu(AceKijun kijun, AceOmomi o, List<SenshuData> list) {
  final List<int> jun = aceJun(
    kijun,
    o,
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

  /// 選手のid(選手の詳細の小窓を開くのに使う。学連選抜の選手も元の大学の選手と同じid)
  final int id;

  const AceSenshu(this.name, this.gakunen, this.daigaku, this.code, this.id);
}

/// 大学1つ分のエース・準エース(小窓の一番下の一覧。2.1.3)
class AceUniv {
  final String daigaku;

  /// [0]エース・[1]準エース(選手が1人の大学は1人だけ)
  final List<AceSenshu> ace;

  const AceUniv(this.daigaku, this.ace);
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

  /// この駅伝の物差しの重み
  final AceOmomi omomi;

  /// 出場した大学ごとのエース・準エース(大学のidの順。区間配置確認と同じ並び)
  final List<AceUniv> univAce;

  const AceHaichiKekka({
    required this.kukansuu,
    required this.univSuu,
    required this.kukan,
    required this.hoketsu,
    required this.hazureta,
    required this.entryGai,
    required this.jibun,
    required this.joui,
    required this.univAce,
    required this.omomi,
  });
}

/// 選手[s]の駅伝[race]の区間の値(読めなければ-2)
int _code(List<List<int>> entry, int gakunen, int race) {
  if (gakunen < 1 || entry.length <= race || entry[race].length < gakunen) return -2;
  return entry[race][gakunen - 1];
}

/// 駅伝[race]の「エースの配置」を集計する
/// [univMei] は大学idから呼び方を引く表、[gakuren] は学連選抜の選手(出場しないときは空)
/// [kukanKyori] はその駅伝の区間の距離(m。0が1区。物差しの重みを決める)
AceHaichiKekka aceHaichiKeisan({
  required int race,
  required int kukansuu,
  required List<double> kukanKyori,
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

  // 偏差値の物差し(全選手で作る)と、駅伝の区間の距離で決める重み
  final AceKijun kijun = AceKijun.tsukuru(senshu);
  final AceOmomi omomi = AceOmomi.tsukuru(kukanKyori, ks);
  // 大学ごとに分ける
  final Map<int, List<SenshuData>> univBetsu = {};
  for (final SenshuData s in senshu) {
    if (s.gakunen < 1 || s.gakunen > TEISUU.GAKUNENSUU) continue;
    univBetsu.putIfAbsent(s.univid, () => []).add(s);
  }
  final List<int> univJun = univBetsu.keys.toList()..sort();

  int univSuu = 0;
  List<AceSenshu> jibun = const [];
  final List<AceUniv> univAce = [];
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
    final List<SenshuData> narabi = aceJunSenshu(kijun, omomi, list);
    final List<AceSenshu> ace = [];
    for (int i = 0; i < 2 && i < narabi.length; i++) {
      final SenshuData s = narabi[i];
      final int code = _code(s.entrykukan_race, s.gakunen, race);
      kazoeru(i, code);
      ace.add(AceSenshu(s.name, s.gakunen, mei, code, s.id));
    }
    if (u == myUnivid) jibun = ace;
    univAce.add(AceUniv(mei, ace));
    for (final SenshuData s in list) {
      final int code = _code(s.entrykukan_race, s.gakunen, race);
      if (aceBasho(code, ks) == AceBasho.entryGai) continue;
      taishou.add(AceSenshu(s.name, s.gakunen, mei, code, s.id));
      taishouTime.add(aceMochiTimesSenshu(s));
      taishouId.add(s.id);
    }
  }
  for (final Senshu_Gakuren_Data g in gakuren) {
    final int code = _code(g.entrykukan_race, g.gakunen, race);
    if (aceBasho(code, ks) == AceBasho.entryGai) continue;
    final String? moto = univMei[g.univid];
    taishou.add(
      AceSenshu(g.name, g.gakunen, moto == null || moto.isEmpty ? '学連選抜' : '学連選抜($moto)', code, g.id),
    );
    taishouTime.add(aceMochiTimesGakuren(g));
    taishouId.add(g.id);
  }
  final List<int> jun = aceJun(kijun, omomi, taishouTime, taishouId);
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
    univAce: univAce,
    omomi: omomi,
  );
}
