import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kansuu/time_date.dart';

// ------------------------------------------------------------
// 今季ベスト(1.9.1)
// ・今の学年(今年度)のレースのうち、自己ベストを更新するのと同じレースでの一番速い記録
//   (レースごと・学年ごとのタイム kukantime_race から出すので、保存する値は増やしていない。
//    既存のセーブデータでも、更新した直後から出せる)
// ・年間強化練習は年度ごとに変わるので、自己ベストは年度によって上乗せの具合が違う。
//   今季ベストは同じ年度の記録だけなので、今の実力を比べやすい
// ・種目(time_bestkirokuの番号)ごとに数えるレース
//   0 5000m: 6インカレ5000・10 5000記録会
//   1 1万m: 7インカレ1万・11 1万記録会
//   2 ハーフ: 8インカレハーフ・12市民ハーフ
//   3 フル: 17フルマラソン
//   4 登り1万: 13、5 下り1万: 14、6 ロード1万: 15、7 クロカン1万: 16
//   (11月駅伝予選・正月駅伝予選と駅伝の区間は、自己ベストと同じく数えない)
// ・表示の切り替え(自己ベスト/今季ベスト)は KantokuData.yobiint2[77]
//   (0=自己ベスト(初期値)・1=今季ベスト)。どの画面の切り替えも同じ値を使う
//   選手画面は切り替えに関係なく両方出す
// ・コンピュータの大学の出場メンバー選び・通常の区間配置・11月駅伝予選の組分けは、
//   切り替えに関係なく、今季ベスト(なければ自己ベスト)で比べる(hikakuMochiTime)
// ------------------------------------------------------------

/// 種目[idx](time_bestkirokuの番号)の今季ベストに数えるレースの番号
const List<List<int>> _konkiBestRace = [
  [6, 10], // 5000m
  [7, 11], // 1万m
  [8, 12], // ハーフ
  [17], // フル
  [13], // 登り1万
  [14], // 下り1万
  [15], // ロード1万
  [16], // クロカン1万
];

/// 今季ベストを出す種目の数(time_bestkirokuの0〜7)
const int konkiBestShumokuSuu = 8;

/// レースごと・学年ごとのタイム[kukantimeRace]から、[gakunen]年(今年度)の
/// 種目[idx]の今季ベストを出す(なければ TEISUU.DEFAULTTIME)
double konkiBestRace(List<List<double>> kukantimeRace, int gakunen, int idx) {
  if (idx < 0 || idx >= _konkiBestRace.length) return TEISUU.DEFAULTTIME;
  if (gakunen < 1 || gakunen > TEISUU.GAKUNENSUU) return TEISUU.DEFAULTTIME;
  double best = TEISUU.DEFAULTTIME;
  for (final int race in _konkiBestRace[idx]) {
    if (kukantimeRace.length <= race ||
        kukantimeRace[race].length < gakunen) {
      continue;
    }
    final double t = kukantimeRace[race][gakunen - 1];
    if (t > 0 && t < best) best = t;
  }
  return best;
}

/// 選手[s]の種目[idx]の今季ベスト(なければ TEISUU.DEFAULTTIME)
double konkiBest(SenshuData s, int idx) =>
    konkiBestRace(s.kukantime_race, s.gakunen, idx);

/// 学連選抜の選手[g]の種目[idx]の今季ベスト(なければ TEISUU.DEFAULTTIME)
/// (学連選抜のデータは正月駅伝のエントリーのときの写しだが、それより後の今季の個人種目は
///  3月のフルマラソンだけなので、正月駅伝のあいだは元の選手と同じになる)
double konkiBestGakuren(Senshu_Gakuren_Data g, int idx) =>
    konkiBestRace(g.kukantime_race, g.gakunen, idx);

/// 自己ベスト(なければ TEISUU.DEFAULTTIME)
double _jikoBest(List<double> timeBestkiroku, int idx) {
  if (idx < 0 || timeBestkiroku.length <= idx) return TEISUU.DEFAULTTIME;
  return timeBestkiroku[idx];
}

/// コンピュータの大学の判断に使う持ちタイム(今季ベスト。なければ自己ベスト)
/// 出場メンバー選び・通常の区間配置・11月駅伝予選の組分けで使う(表示の切り替えには関係しない)
double hikakuMochiTime(SenshuData s, int idx) {
  final double t = konkiBest(s, idx);
  if (t < TEISUU.DEFAULTTIME) return t;
  return _jikoBest(s.time_bestkiroku, idx);
}

/// 学連選抜の選手のコンピュータの区間配置に使う持ちタイム(今季ベスト。なければ自己ベスト)
double hikakuMochiTimeGakuren(Senshu_Gakuren_Data g, int idx) {
  final double t = konkiBestGakuren(g, idx);
  if (t < TEISUU.DEFAULTTIME) return t;
  return _jikoBest(g.time_bestkiroku, idx);
}

// ------------------------------------------------------------
// 表示の切り替え(自己ベスト/今季ベスト)
// ------------------------------------------------------------

KantokuData? _kantoku() =>
    Hive.box<KantokuData>('kantokuBox').get('KantokuData');

/// 持ちタイムを今季ベストで表示しているか(KantokuData.yobiint2[77]が1)
bool konkiBestHyoujiChuu() {
  final KantokuData? kantoku = _kantoku();
  return kantoku != null &&
      kantoku.yobiint2.length > 77 &&
      kantoku.yobiint2[77] == 1;
}

/// 持ちタイムの表示を切り替える([konki]がtrueなら今季ベスト、falseなら自己ベスト)
Future<void> konkiBestHyoujiSettei(bool konki) async {
  final KantokuData? kantoku = _kantoku();
  if (kantoku == null || kantoku.yobiint2.length <= 77) return;
  kantoku.yobiint2[77] = konki ? 1 : 0;
  await kantoku.save();
}

// ------------------------------------------------------------
// 今季ベストの順位
// ------------------------------------------------------------

/// 今季ベストの学内順位・全体順位・区間内順位を出すための表
/// 画面や文を作るときに1回作って使い回す(全選手の今季ベストを先に出しておく)
/// 順位は1始まり。同じタイムは同じ順位。今季ベストがないときは0
class KonkiBestJuni {
  /// 選手id → 種目ごとの今季ベスト
  final Map<int, List<double>> _best = {};

  /// 種目ごとの、全選手の今季ベスト(記録のあるものだけ、速い順)
  final List<List<double>> _zentai = List.generate(
    konkiBestShumokuSuu,
    (_) => <double>[],
  );

  /// 大学id → 種目ごとの、その大学の選手の今季ベスト(記録のあるものだけ、速い順)
  final Map<int, List<List<double>>> _gakunai = {};

  KonkiBestJuni() {
    for (final SenshuData s in Hive.box<SenshuData>('senshuBox').values) {
      final List<double> b = List.generate(
        konkiBestShumokuSuu,
        (idx) => konkiBest(s, idx),
      );
      _best[s.id] = b;
      final List<List<double>> univ = _gakunai.putIfAbsent(
        s.univid,
        () => List.generate(konkiBestShumokuSuu, (_) => <double>[]),
      );
      for (int idx = 0; idx < konkiBestShumokuSuu; idx++) {
        if (b[idx] < TEISUU.DEFAULTTIME) {
          _zentai[idx].add(b[idx]);
          univ[idx].add(b[idx]);
        }
      }
    }
    for (final List<double> l in _zentai) {
      l.sort();
    }
    for (final List<List<double>> univ in _gakunai.values) {
      for (final List<double> l in univ) {
        l.sort();
      }
    }
  }

  /// 選手[s]の種目[idx]の今季ベスト(なければ TEISUU.DEFAULTTIME)
  double best(SenshuData s, int idx) {
    final List<double>? b = _best[s.id];
    if (b == null || idx < 0 || idx >= b.length) return konkiBest(s, idx);
    return b[idx];
  }

  /// 速い順のタイムの並び[sorted]の中での[time]の順位(1始まり。自分より速いタイムの数+1)
  static int _juni(List<double> sorted, double time) {
    int lo = 0;
    int hi = sorted.length;
    while (lo < hi) {
      final int mid = (lo + hi) ~/ 2;
      if (sorted[mid] < time) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo + 1;
  }

  /// 今季ベスト[time]の、全選手(学生全体)の中での順位(記録がなければ0)
  int zentai(double time, int idx) {
    if (time >= TEISUU.DEFAULTTIME || idx < 0 || idx >= konkiBestShumokuSuu) {
      return 0;
    }
    return _juni(_zentai[idx], time);
  }

  /// 今季ベスト[time]の、大学[univid]の選手の中での順位(記録がなければ0)
  int gakunai(double time, int idx, int univid) {
    if (time >= TEISUU.DEFAULTTIME || idx < 0 || idx >= konkiBestShumokuSuu) {
      return 0;
    }
    final List<List<double>>? univ = _gakunai[univid];
    if (univ == null) return 1;
    return _juni(univ[idx], time);
  }

  /// 今季ベスト[time]の、[hikaku]の選手(区間を走る選手など)の中での順位(記録がなければ0)
  /// [zenninHitsuyou]がtrueなら、[hikaku]の誰か一人でも今季ベストがないときは0
  /// (夏の学内タイムトライアルの4種目は、自己ベストのときと同じく、全員に記録があるときだけ出す)
  int hikakuJuni(
    double time,
    int idx,
    Iterable<SenshuData> hikaku, {
    bool zenninHitsuyou = false,
  }) {
    if (time >= TEISUU.DEFAULTTIME) return 0;
    int juni = 1;
    for (final SenshuData d in hikaku) {
      final double t = best(d, idx);
      if (t >= TEISUU.DEFAULTTIME) {
        if (zenninHitsuyou) return 0;
        continue;
      }
      if (t < time) juni++;
    }
    return juni;
  }
}

// ------------------------------------------------------------
// 文
// ------------------------------------------------------------

/// タイムの文(フルは時間分秒、ほかは分秒)
String konkiBestTimeBun(double time, int idx) => idx == 3
    ? TimeDate.timeToJikanFunByouString(time)
    : TimeDate.timeToFunByouString(time);

/// 今季ベストがないときの文(自己ベストがあれば参考に添える。生成AIに渡すテキストと区間配置確認の画面で使う)
String konkiKirokuNashiBun(double jikoBest, int idx) {
  if (jikoBest >= TEISUU.DEFAULTTIME) return '今季記録無(自己ベストも記録無)';
  return '今季記録無(自己ベスト ${konkiBestTimeBun(jikoBest, idx)})';
}

/// 生成AIに渡すテキストで、持ちタイムを今季ベストで書いたときの説明
const String konkiBestChuui =
    '※この一覧の持ちタイムは「今季ベスト」(今年度のレースでの最高記録)です。'
    '今季まだ走っていない種目は「今季記録無」と書き、参考に自己ベストを添えています。'
    '順位も今季ベストで比べたものです。';
