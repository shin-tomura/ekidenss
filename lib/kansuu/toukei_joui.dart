import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_data.dart';

// ------------------------------------------------------------
// 「スキップして統計データ取得」の、学年の上位に入った人数(入学時5000mの記録ごと。2.0.0)
// 入学時の記録が良くない選手が、どのくらいトップクラスまで上り詰めるかを見るため。
// (4年生卒業直前データの最速は各帯の1人だけなので、「たまに」なのかが分からなかった)
// ・毎年3月25日(4年生卒業直前データと同じとき。main.dart から呼ぶ)に、その年の日本人の4年生を、
//   種目ごとに持ちタイムの順に並べ、上位10人と上位30人に入った選手を、入学時5000mの記録の帯ごとに数える
// ・帯は4年生卒業直前データと同じ8つ(13分台・14分00秒台〜14分50秒台(10秒ごと)・15分台)
// ・保存先は KantokuData.yobiint5[61]〜[76]([61]〜[68]が上位10人、[69]〜[76]が上位30人。
//   どちらも帯の順)。1つの番号に4種目分を3桁ずつ詰める(一の位から5000m・10000m・ハーフ・フル。
//   1種目999人まで。30年回しても上位30人は900人なので足りる)
// ・統計を取り始めるとき(Modal_Skip.dart のスキップ予約)に0に戻す
// ------------------------------------------------------------

/// 保存先の最初の番号(KantokuData.yobiint5)
const int toukeiJouiIndex = 61;

/// 数える上位の人数(この並びで保存する)
const List<int> toukeiJouiNinzuu = [10, 30];

/// 入学時5000mの記録の帯の数
const int toukeiJouiObiSuu = 8;

/// 帯の名前(4年生卒業直前データと同じ)
const List<String> toukeiJouiObiMei = [
  '13分台入学',
  '14分00秒台入学',
  '14分10秒台入学',
  '14分20秒台入学',
  '14分30秒台入学',
  '14分40秒台入学',
  '14分50秒台入学',
  '15分台入学',
];

/// 帯の区切り(入学時5000mの記録(秒)がこれ未満なら、その帯。main.dart の集計と同じ)
const List<double> _obiKugiri = [840.0, 850.0, 860.0, 870.0, 880.0, 890.0, 900.0];

const List<String> _shumokuMei = ['5000m', '10000m', 'ハーフ', 'フル'];

/// 1種目分の桁(3桁ずつ)
const List<int> _keta = [1, 1000, 1000000, 1000000000];

/// 使う番号の数
const int _bangouSuu = 16; // toukeiJouiNinzuu.length × toukeiJouiObiSuu

/// 入学時5000mの記録の帯の番号(0=13分台 … 7=15分台)
int toukeiJouiObi(double nyuugakuji5000) {
  for (int i = 0; i < _obiKugiri.length; i++) {
    if (nyuugakuji5000 < _obiKugiri[i]) return i;
  }
  return toukeiJouiObiSuu - 1;
}

bool _tsukaeru(KantokuData kantoku) =>
    kantoku.yobiint5.length >= toukeiJouiIndex + _bangouSuu;

/// 統計を取り始めるときに0に戻す(保存は呼び出し側で行う)
void toukeiJouiReset(KantokuData kantoku) {
  if (!_tsukaeru(kantoku)) return;
  for (int i = 0; i < _bangouSuu; i++) {
    kantoku.yobiint5[toukeiJouiIndex + i] = 0;
  }
}

/// [kubun](0=上位10人・1=上位30人)・[obi]・[shumoku](0=5000m〜3=フル)の人数
int toukeiJouiKazu(KantokuData kantoku, int kubun, int obi, int shumoku) {
  if (!_tsukaeru(kantoku)) return 0;
  final int atai =
      kantoku.yobiint5[toukeiJouiIndex + kubun * toukeiJouiObiSuu + obi];
  return (atai ~/ _keta[shumoku]) % 1000;
}

/// その年の日本人の4年生で、各種目の上位に入った選手を数える(保存は呼び出し側で行う)
/// [sortedSenshuData] は全選手(4年生と留学生の判定はここで行う)
void toukeiJouiKazoeru(
  KantokuData kantoku,
  List<SenshuData> sortedSenshuData,
) {
  if (!_tsukaeru(kantoku)) return;
  final List<SenshuData> nihonjin = [
    for (final SenshuData s in sortedSenshuData)
      if (s.gakunen == 4 && s.hirou != 1) s,
  ];
  for (int shumoku = 0; shumoku < _shumokuMei.length; shumoku++) {
    // 記録のない選手は並べない
    final List<SenshuData> jun = [
      for (final SenshuData s in nihonjin)
        if (s.time_bestkiroku.length > shumoku &&
            s.time_bestkiroku[shumoku] < TEISUU.DEFAULTTIME)
          s,
    ]..sort((a, b) => a.time_bestkiroku[shumoku].compareTo(b.time_bestkiroku[shumoku]));
    for (int kubun = 0; kubun < toukeiJouiNinzuu.length; kubun++) {
      final int n = toukeiJouiNinzuu[kubun] < jun.length
          ? toukeiJouiNinzuu[kubun]
          : jun.length;
      for (int j = 0; j < n; j++) {
        final int obi = toukeiJouiObi(jun[j].kiroku_nyuugakuji_5000);
        final int bangou = toukeiJouiIndex + kubun * toukeiJouiObiSuu + obi;
        final int ima = (kantoku.yobiint5[bangou] ~/ _keta[shumoku]) % 1000;
        if (ima >= 999) continue;
        kantoku.yobiint5[bangou] += _keta[shumoku];
      }
    }
  }
}

/// 統計データに出す文
/// [obiNinzuu] は帯ごとの人数(4年生卒業直前データの集計。帯の順に、種目ごとの人数の配列)
String toukeiJouiBun(KantokuData kantoku, List<List<int>> obiNinzuu) {
  if (!_tsukaeru(kantoku)) return "";
  String bun = "\n\n\n==学年の上位に入った人数==\n";
  bun += "毎年の卒業生(日本人の4年生)の中で、各種目の持ちタイムが上位10人・上位30人に入った人数を、"
      "入学時の5000mの記録ごとに数えたもの(かっこの中は、その入学時の記録の選手のうち、上位に入った割合)\n";
  // 1種目あたりの合計(年数×上位の人数になる)
  for (int kubun = 0; kubun < toukeiJouiNinzuu.length; kubun++) {
    int goukei = 0;
    for (int obi = 0; obi < toukeiJouiObiSuu; obi++) {
      goukei += toukeiJouiKazu(kantoku, kubun, obi, 0);
    }
    bun += "上位${toukeiJouiNinzuu[kubun]}人の合計 1種目あたり$goukei人\n";
  }
  for (int obi = 0; obi < toukeiJouiObiSuu; obi++) {
    bun += "\n";
    for (int kubun = 0; kubun < toukeiJouiNinzuu.length; kubun++) {
      final List<String> shumokuBun = [];
      for (int shumoku = 0; shumoku < _shumokuMei.length; shumoku++) {
        final int kazu = toukeiJouiKazu(kantoku, kubun, obi, shumoku);
        final int ninzuu =
            (obi < obiNinzuu.length && shumoku < obiNinzuu[obi].length)
            ? obiNinzuu[obi][shumoku]
            : 0;
        final String wariai = ninzuu > 0
            ? "(${(kazu * 100.0 / ninzuu).toStringAsFixed(1)}%)"
            : "";
        shumokuBun.add("${_shumokuMei[shumoku]} $kazu人$wariai");
      }
      bun +=
          "${toukeiJouiObiMei[obi]} 上位${toukeiJouiNinzuu[kubun]}人 ${shumokuBun.join('・')}\n";
    }
  }
  return bun;
}
