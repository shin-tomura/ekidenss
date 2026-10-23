import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/ace_haichi.dart' show AceKijun, aceJunSenshu; // エース・準エースの決め方(2.1.3)

// ------------------------------------------------------------
// 「スキップして統計データ取得」の、エース・準エースが走った区間(2.1.3)
// 各大学のエースや準エースが、駅伝のどの区間に配置されたかを見るため。
// ・エース・準エースの決め方: その大学の全選手(区間エントリーされていない選手も、留学生も含む)を、
//   5000m・1万m・ハーフ・ロード1万の持ちタイムの全選手の中での偏差値のうち、得意な2種目の平均で並べた1番手と2番手
//   (決め方は、レース前の画面の「エースの配置」と同じ ace_haichi.dart の aceJunSenshu。持ちタイムは今季ベスト、
//    なければ自己ベスト。偏差値の物差しは、駅伝ごとにその時点の全選手で作る)
// ・数えるのは10月駅伝・11月駅伝・正月駅伝・カスタム駅伝の、当日変更のあとに実際に走った区間
//   (KirokuKousin.dart の区間別タイム統計と同じところで数える)。走らなかったら「走らず」
// ・学連選抜は数えない(いくつもの大学の寄せ集めなので)。KirokuKousin で学連選抜の選手の結果を
//   大学の選手のデータに写す前に数えるので、出場していない大学は、走った選手がいないとして飛ばす
// ・区間別タイム統計と同じくメモリだけに持ち、保存はしない。統計を取り始めるとき
//   (Modal_Skip.dart のスキップ予約)に0に戻し、スキップの最後(main.dart)に統計の文へ書き足す
// ------------------------------------------------------------

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
  // 偏差値の物差し(その時点の全選手で作る)
  final AceKijun kijun = AceKijun.tsukuru(senshuList);
  for (final List<SenshuData> list in univBetsu.values) {
    // 走った選手がいない大学は、出場していないので数えない
    if (!list.any((s) => _hashittaKukan(s, racebangou, kukansuu) >= 0)) continue;
    final List<SenshuData> narabi = aceJunSenshu(kijun, list);
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
  sb.write('(5000m・1万m・ハーフ・ロード1万の持ちタイムを全選手の中での偏差値にし、');
  sb.write('得意な2種目の平均が学内で1番目・2番目の選手。持ちタイムは今季ベスト、なければ自己ベスト。');
  sb.write('留学生も含み、学連選抜は数えません)\n');
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
