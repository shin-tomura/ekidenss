import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/konki_best.dart' show hikakuMochiTime;

// ------------------------------------------------------------
// 「スキップして統計データ取得」の、エース・準エースが走った区間(2.1.3)
// 各大学のエースや準エースが、駅伝のどの区間に配置されたかを見るため。
// ・エース・準エースの決め方: その大学の全選手(区間エントリーされていない選手も、留学生も含む)を、
//   5000m・1万m・ハーフ・ロード1万の学内順位の平均で並べた1番手と2番手
//   ・持ちタイムは、コンピュータの大学が区間配置で比べるのと同じ今季ベスト(なければ自己ベスト。hikakuMochiTime)
//   ・同じタイムは同じ順位。記録のない種目は、その種目の最下位(記録のある人数+1位)
//   ・平均が同じなら1万mの速いほう、それも同じなら選手のidの順
// ・数えるのは10月駅伝・11月駅伝・正月駅伝・カスタム駅伝の、当日変更のあとに実際に走った区間
//   (KirokuKousin.dart の区間別タイム統計と同じところで数える)。走らなかったら「走らず」
// ・学連選抜は数えない(いくつもの大学の寄せ集めなので)。KirokuKousin で学連選抜の選手の結果を
//   大学の選手のデータに写す前に数えるので、出場していない大学は、走った選手がいないとして飛ばす
// ・区間別タイム統計と同じくメモリだけに持ち、保存はしない。統計を取り始めるとき
//   (Modal_Skip.dart のスキップ予約)に0に戻し、スキップの最後(main.dart)に統計の文へ書き足す
// ------------------------------------------------------------

/// エース・準エースを決める種目(time_bestkiroku の番号。5000m・1万m・ハーフ・ロード1万)
const List<int> _aceShumoku = [0, 1, 2, 6];

/// 1万m(平均が同じときに比べる種目)
const int _ichiman = 1;

/// 数える駅伝(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝)と、統計の文での名前
const List<int> _aceRace = [0, 1, 2, 5];
const Map<int, String> _aceRaceMei = {0: '10月駅伝', 1: '11月駅伝', 2: '正月駅伝'};

/// 区間の数の上限
const int _kukanMax = 10;

/// 駅伝1つ分の集計
class _AceToukei {
  /// 数えた回数(駅伝が開かれた回数)
  int kaisuu = 0;

  /// [0]エース・[1]準エースを数えたチームののべ数
  final List<int> teamSuu = [0, 0];

  /// [0]エース・[1]準エースが走った区間ごとの回数
  final List<List<int>> kukan = [
    List.filled(_kukanMax, 0),
    List.filled(_kukanMax, 0),
  ];

  /// [0]エース・[1]準エースが走らなかった回数
  final List<int> hashirazu = [0, 0];
}

final Map<int, _AceToukei> _toukei = {
  for (final int r in _aceRace) r: _AceToukei(),
};

/// 統計を0に戻す(スキップ予約のとき)
void toukeiAceReset() {
  for (final int r in _aceRace) {
    _toukei[r] = _AceToukei();
  }
}

/// 持ちタイム(記録がなければnull)
double? _mochiTime(SenshuData s, int idx) {
  final double t = hikakuMochiTime(s, idx);
  if (t <= 0 || t >= TEISUU.DEFAULTTIME) return null;
  return t;
}

/// 1つの大学の選手[list]を、学内順位の平均の良い順に並べる
List<SenshuData> _aceJun(List<SenshuData> list) {
  final List<double> goukei = List.filled(list.length, 0.0);
  for (final int idx in _aceShumoku) {
    final List<double?> time = [for (final SenshuData s in list) _mochiTime(s, idx)];
    final int kirokuAri = time.where((t) => t != null).length;
    for (int i = 0; i < list.length; i++) {
      final double? t = time[i];
      if (t == null) {
        goukei[i] += kirokuAri + 1;
        continue;
      }
      // 自分より速い選手の数+1(同じタイムは同じ順位)
      int hayai = 0;
      for (final double? u in time) {
        if (u != null && u < t) hayai++;
      }
      goukei[i] += hayai + 1;
    }
  }
  final List<int> jun = List.generate(list.length, (i) => i)
    ..sort((a, b) {
      final int c = goukei[a].compareTo(goukei[b]);
      if (c != 0) return c;
      final double ta = _mochiTime(list[a], _ichiman) ?? TEISUU.DEFAULTTIME;
      final double tb = _mochiTime(list[b], _ichiman) ?? TEISUU.DEFAULTTIME;
      final int c2 = ta.compareTo(tb);
      if (c2 != 0) return c2;
      return list[a].id.compareTo(list[b].id);
    });
  return [for (final int i in jun) list[i]];
}

/// 選手[s]が駅伝[racebangou]で走った区間(0が1区。走っていなければ-1)
int _hashittaKukan(SenshuData s, int racebangou, int kukansuu) {
  if (s.entrykukan_race.length <= racebangou) return -1;
  final List<int> l = s.entrykukan_race[racebangou];
  if (s.gakunen < 1 || l.length < s.gakunen) return -1;
  final int k = l[s.gakunen - 1];
  return (k >= 0 && k < kukansuu && k < _kukanMax) ? k : -1;
}

/// 駅伝[racebangou]で、各大学のエース・準エースが走った区間を数える
/// ([kukansuu]はその駅伝の区間数、[senshuList]は全選手。KirokuKousin.dart の区間別タイム統計と同じところで呼ぶ)
void toukeiAceAtsumeru(int racebangou, int kukansuu, Iterable<SenshuData> senshuList) {
  final _AceToukei? t = _toukei[racebangou];
  if (t == null) return;
  final Map<int, List<SenshuData>> univBetsu = {};
  for (final SenshuData s in senshuList) {
    if (s.gakunen < 1 || s.gakunen > TEISUU.GAKUNENSUU) continue;
    univBetsu.putIfAbsent(s.univid, () => []).add(s);
  }
  t.kaisuu++;
  for (final List<SenshuData> list in univBetsu.values) {
    // 走った選手がいない大学は、出場していないので数えない
    if (!list.any((s) => _hashittaKukan(s, racebangou, kukansuu) >= 0)) continue;
    final List<SenshuData> narabi = _aceJun(list);
    for (int i = 0; i < 2 && i < narabi.length; i++) {
      t.teamSuu[i]++;
      final int k = _hashittaKukan(narabi[i], racebangou, kukansuu);
      if (k >= 0) {
        t.kukan[i][k]++;
      } else {
        t.hashirazu[i]++;
      }
    }
  }
}

/// 割合と回数の文(「14.0%(84)」)
String _wariai(int kazu, int bunbo) {
  if (bunbo <= 0) return '-';
  return '${(kazu * 100.0 / bunbo).toStringAsFixed(1)}%($kazu)';
}

/// 統計の文(スキップの最後に、区間別タイム統計のあとに書き足す)
/// [kukansuuTaikaigoto]は大会ごとの区間数(Ghensuu.kukansuu_taikaigoto)、[customMei]はカスタム駅伝の名前
String toukeiAceBun({
  required List<int> kukansuuTaikaigoto,
  required String customMei,
}) {
  final StringBuffer sb = StringBuffer();
  sb.write('\n\n\n==エース・準エースが走った区間==\n');
  sb.write('(各大学の全選手を、5000m・1万m・ハーフ・ロード1万の学内順位の平均で並べた1番手と2番手。');
  sb.write('持ちタイムは今季ベスト、なければ自己ベスト。留学生も含み、学連選抜は数えません)\n');
  for (final int r in _aceRace) {
    final _AceToukei t = _toukei[r]!;
    sb.write('\n${_aceRaceMei[r] ?? customMei}\n');
    if (t.kaisuu == 0 || t.teamSuu[0] == 0) {
      sb.write('(統計をとっている間に開催されなかったので、統計はありません)\n');
      continue;
    }
    sb.write('開催 ${t.kaisuu}回・のべ${t.teamSuu[0]}チーム\n');
    final int kukansuu = (r < kukansuuTaikaigoto.length ? kukansuuTaikaigoto[r] : _kukanMax)
        .clamp(1, _kukanMax);
    for (int k = 0; k < kukansuu; k++) {
      sb.write(
        '${k + 1}区 エース ${_wariai(t.kukan[0][k], t.teamSuu[0])} '
        '準エース ${_wariai(t.kukan[1][k], t.teamSuu[1])}\n',
      );
    }
    sb.write(
      '走らず エース ${_wariai(t.hashirazu[0], t.teamSuu[0])} '
      '準エース ${_wariai(t.hashirazu[1], t.teamSuu[1])}\n',
    );
  }
  return sb.toString();
}
