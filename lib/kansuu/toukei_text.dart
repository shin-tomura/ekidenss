import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/time_date.dart';
import 'package:ekiden/univ_data.dart';

// 「スキップして統計データ取得」の統計データ(アプリに出す文)を作る関数(1.8.7)
// 集計そのものは main.dart(4年生卒業直前データ。Skipに保存)と
// KirokuKousin.dart(区間別タイム統計。toukei.dart。メモリだけ)で行う

/// 4年生卒業直前データの1グループ分の文
/// 1項目1行で、人数、持ちタイムの平均(4種目)、最速(4種目)の順に書く
/// (書き方はコンソールのログと同じ。日本人全体は1.8.6までのアプリの出力と同じになる。
/// 人数が0人のときは人数の行だけ)
/// [ninzuuMei]は人数の行の名前(日本人と留学生は「総数」、入学時5000mの帯は「サンプル数」)
/// (配列はSkipの集計と同じ並びで、0→5000m、1→10000m、2→ハーフ、3→フル)
String toukeiGroupBun(
  String namae,
  String ninzuuMei,
  List<int> count,
  List<double> totaltime,
  List<double> besttime,
) {
  final int ninzuu = count.isEmpty ? 0 : count[0];
  String bun = "$namae$ninzuuMei $ninzuu\n";
  if (ninzuu <= 0) {
    return bun;
  }
  for (int i = 0; i < 4; i++) {
    if (count[i] > 0) {
      bun +=
          "$namae${_shumokuMei[i]}平均 ${_toukeiTimeString(i, totaltime[i] / count[i])}\n";
    }
  }
  for (int i = 0; i < 4; i++) {
    bun +=
        "$namae${_shumokuMei[i]}最速 ${_toukeiTimeString(i, besttime[i])}\n";
  }
  return bun;
}

const List<String> _shumokuMei = ['5000m', '10000m', 'ハーフ', 'フル'];

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
