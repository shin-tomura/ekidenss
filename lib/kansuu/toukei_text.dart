import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/univ_data.dart';

// 「スキップして統計データ取得」の統計データ(アプリに出す文)を作る関数(1.8.7)
// 集計そのものは main.dart(4年生卒業直前データ。Skipに保存)と
// KirokuKousin.dart(区間別タイム統計。toukei.dart。メモリだけ)で行う

/// 4年生卒業直前データの1グループ分の文
/// 1行目に人数と持ちタイムの平均、2行目に最速を書く
/// (配列はSkipの集計と同じ並びで、0→5000m、1→10000m、2→ハーフ、3→フル)
String toukeiGroupBun(
  String namae,
  List<int> count,
  List<double> totaltime,
  List<double> besttime,
) {
  if (count.isEmpty || count[0] <= 0) {
    return "$namae 0人\n";
  }
  String heikin(int i) =>
      count[i] > 0 ? _toukeiTimeString(i, totaltime[i] / count[i]) : "-";
  String saisoku(int i) => _toukeiTimeString(i, besttime[i]);
  return "$namae ${count[0]}人 平均 5千${heikin(0)}・1万${heikin(1)}・ハーフ${heikin(2)}・フル${heikin(3)}\n"
      "　最速 5千${saisoku(0)}・1万${saisoku(1)}・ハーフ${saisoku(2)}・フル${saisoku(3)}\n";
}

String _toukeiTimeString(int shumoku, double time) {
  return shumoku == 3
      ? TimeDate.timeToJikanFunByouString(time)
      : TimeDate.timeToFunByouString(time);
}

/// 留学生を受け入れている大学の、留学生の優秀度の内訳
/// (留学生は優秀度ごとに分けずにまとめて集計するので、どんな顔ぶれの値かを示す。
/// 書き出すときの大学の設定で数える。UnivData.rは1最高優秀・2優秀・3普通・4やや優秀でない、0は受け入れなし)
String ryuugakuseiUchiwakeBun(List<UnivData> sortedUnivsById) {
  const List<String> yuushuudoMei = ['最高優秀', '優秀', '普通', 'やや優秀でない'];
  final List<int> kosuu = List.filled(4, 0);
  for (
    int i = 0;
    i < TEISUU.UNIVSUU && i < sortedUnivsById.length;
    i++
  ) {
    final int r = sortedUnivsById[i].r;
    if (r >= 1 && r <= 4) {
      kosuu[r - 1]++;
    }
  }
  if (kosuu.every((k) => k == 0)) {
    return "留学生のいる大学 なし\n";
  }
  final String uchiwake = [
    for (int i = 0; i < 4; i++) "${yuushuudoMei[i]}${kosuu[i]}校",
  ].join("・");
  return "留学生のいる大学 $uchiwake\n";
}
