import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';

// ------------------------------------------------------------
// 大会の長い記録(2.0.0)
//
// 大学の大会ごとの順位は直近 TEISUU.KIROKUHOZONNENSUU 回分(UnivData.juni_race)しか残らないので、
// 「105年ぶりの優勝」「12連覇」のように、それより前にさかのぼる記事が書けなかった。
// そこで、出来事(優勝・本戦出場・シード権)ごとに、最後にあった年度・その前にあった年度・
// 続いている回数だけを覚える(何年遊んでもデータは増えない)。
// ・覚えるもの: 優勝は10月駅伝・11月駅伝・正月駅伝・カスタム駅伝・対校戦総合・正月駅伝の往路と復路、
//   本戦出場は三大駅伝、シード権は11月駅伝(8位以内)と正月駅伝(10位以内)
//   (往路・復路(大会番号18・19)の成績は、2.0.0から記録を始めた。oufuku_kiroku.dart)
// ・年度は4月から翌年3月まで(正月駅伝とカスタム駅伝は、前の年の10月駅伝と同じ年度)。
//   開かれない年のあるカスタム駅伝でも「○年ぶり」を年で数えられる。連続の回数は、開かれた回で数える
// ・保存場所は UnivData.taikaibetujunibetukaisuu[17](大会番号17はフルマラソンで、大学の順位がない
//   個人の大会なので、この行の順位別の回数は使っていない。30個、初期値0)。
//   型も項目も変えないので、今までのセーブデータもそのまま読める
//   [0]〜[4] 優勝(大会0・1・2・5・9)、[5]〜[7] 本戦出場(大会0・1・2)、[8]・[9] シード権(大会1・2)
//   [10]〜[14] 大会が最後に開かれた年度(大会0・1・2・5・9。順位の記録の[0]の大会の年度)
//   [15]・[16] 優勝(往路18・復路19)、[17]・[18] 最後に開かれた年度(往路18・復路19)
//   [19] 往路・復路の成績を記録し始めた年度(0は未設定。1なら最初の正月駅伝から全部ある。
//        2.0.0より前から遊んでいるデータは、2.0.0で最初に走る正月駅伝の年度)
//   [20]〜[28] 空き、[29] この大学で長い記録を使い始めた印(1)
// ・出来事の1つの番号に「最後の年度×10の10乗+その前の年度×10の5乗+連続の回数」を詰める(15桁まで)
//   ・最後の年度が0: その出来事がない、または記録を始める前のことで年度が分からない
//     (分からないときは、その前の年度の欄に「この年度以前」の年度を入れる)
//   ・その前の年度が0: その前がない、または分からない(全期間の回数で見分ける)
//   ・連続の回数が0: 記録を始める前から続いていて、数が分からない
// ・大会の結果を記録するとき(KirokuKousin.dart)に更新する。今までのセーブデータには、
//   直近の順位の記録から分かる分だけを入れる(choukiIkou。main.dart と save_load_screen.dart)
// ・記事(kiji_kihon.dart の saigoNoNen・renzokuChouki)と大学画面の「最後の優勝」で使う
// ------------------------------------------------------------

/// 置き場所の大会番号(UnivData.taikaibetujunibetukaisuu の行。17はフルマラソン)
const int choukiGyou = 17;

/// 出来事: 優勝
const int choukiYuushou = 0;

/// 出来事: 本戦出場
const int choukiShutsujou = 1;

/// 出来事: シード権
const int choukiSeed = 2;

/// 正月駅伝の往路・復路の大会番号(2.0.0。もともと往路・復路のために取ってあった番号。constants.dart)
const int ouroRace = 18;
const int fukuroRace = 19;

/// 覚える大会(10月駅伝・11月駅伝・正月駅伝・カスタム駅伝・対校戦総合・往路・復路)
const List<int> choukiRaceList = [0, 1, 2, 5, 9, ouroRace, fukuroRace];

const List<int> _dekigotoList = [choukiYuushou, choukiShutsujou, choukiSeed];

/// 使い始めた印の番号
const int _shirushi = 29;

/// 往路・復路の成績を記録し始めた年度の番号
const int _oufukuKaishi = 19;

/// 1つの値の桁(10の5乗)
const int _keta = 100000;

/// 出来事[dekigoto]を大会[race]で覚えている番号(覚えていなければ-1)
int _bangou(int race, int dekigoto) {
  switch (dekigoto) {
    case choukiYuushou:
      const Map<int, int> yuushou = {
        0: 0,
        1: 1,
        2: 2,
        5: 3,
        9: 4,
        ouroRace: 15,
        fukuroRace: 16,
      };
      return yuushou[race] ?? -1;
    case choukiShutsujou:
      return (race >= 0 && race <= 2) ? 5 + race : -1;
    case choukiSeed:
      return race == 1 ? 8 : (race == 2 ? 9 : -1);
    default:
      return -1;
  }
}

/// 大会[race]が最後に開かれた年度の番号(覚えていなければ-1)
int _kaisaiBangou(int race) {
  const Map<int, int> kaisai = {
    0: 10,
    1: 11,
    2: 12,
    5: 13,
    9: 14,
    ouroRace: 17,
    fukuroRace: 18,
  };
  return kaisai[race] ?? -1;
}

/// シード権の数(11月駅伝は8校、正月駅伝は10校。main.dart の4月5日の出場権の決まりと同じ)
int choukiSeedSuu(int race) => race == 1 ? 8 : (race == 2 ? 10 : 0);

/// 順位[juni](0が1位。出場していなければ TEISUU.DEFAULTJUNI)のとき、出来事[dekigoto]があったか
bool choukiAtta(int race, int dekigoto, int juni) {
  if (juni < 0 || juni >= TEISUU.DEFAULTJUNI) return false;
  switch (dekigoto) {
    case choukiYuushou:
      return juni == 0;
    case choukiShutsujou:
      return true;
    case choukiSeed:
      return juni < choukiSeedSuu(race);
    default:
      return false;
  }
}

/// 全期間で、大会[race]で出来事[dekigoto]があった回数
int choukiTsuusan(UnivData u, int race, int dekigoto) {
  if (race < 0) return 0;
  switch (dekigoto) {
    case choukiYuushou:
      if (u.taikaibetujunibetukaisuu.length <= race ||
          u.taikaibetujunibetukaisuu[race].isEmpty) {
        return 0;
      }
      return u.taikaibetujunibetukaisuu[race][0];
    case choukiShutsujou:
      if (u.taikaibetushutujoukaisuu.length <= race) return 0;
      return u.taikaibetushutujoukaisuu[race];
    case choukiSeed:
      if (u.taikaibetujunibetukaisuu.length <= race) return 0;
      int n = 0;
      final List<int> kaisuu = u.taikaibetujunibetukaisuu[race];
      for (int j = 0; j < choukiSeedSuu(race) && j < kaisuu.length; j++) {
        n += kaisuu[j];
      }
      return n;
    default:
      return 0;
  }
}

/// 覚えている出来事の記録
class ChoukiKiroku {
  /// 最後にあった年度(0はない、または分からない)
  final int saigo;

  /// その前にあった年度(0はない、または分からない)。
  /// [saigo]が0で分からないときは、「この年度以前」の年度
  final int mae;

  /// [saigo]の年度の大会で終わる連続の回数(0は分からない)
  final int renzoku;

  const ChoukiKiroku(this.saigo, this.mae, this.renzoku);
}

/// 置き場所の行(足りなければnull)
List<int>? _gyou(UnivData u) {
  if (u.taikaibetujunibetukaisuu.length <= choukiGyou) return null;
  final List<int> g = u.taikaibetujunibetukaisuu[choukiGyou];
  if (g.length <= _shirushi) return null;
  return g;
}

ChoukiKiroku _yomuAtai(int v) =>
    ChoukiKiroku(v ~/ (_keta * _keta), (v ~/ _keta) % _keta, v % _keta);

void _kaku(List<int> g, int b, int saigo, int mae, int renzoku) {
  int k(int x) => x < 0 ? 0 : (x >= _keta ? _keta - 1 : x);
  g[b] = k(saigo) * _keta * _keta + k(mae) * _keta + k(renzoku);
}

/// 大学[u]の、大会[race]の出来事[dekigoto]の記録(覚えていない大会や、まだ使い始めていないデータはnull)
ChoukiKiroku? choukiYomu(UnivData u, int race, int dekigoto) {
  final int b = _bangou(race, dekigoto);
  final List<int>? g = _gyou(u);
  if (b < 0 || g == null || g[_shirushi] != 1) return null;
  return _yomuAtai(g[b]);
}

/// 大会[race]が最後に開かれた年度(順位の記録の[0]の大会の年度。分からなければ0)
int choukiKaisaiNendo(UnivData u, int race) {
  final int b = _kaisaiBangou(race);
  final List<int>? g = _gyou(u);
  if (b < 0 || g == null || g[_shirushi] != 1) return 0;
  return g[b];
}

/// 今の年度(4月から翌年3月まで)
int choukiNendo(Ghensuu gh) => gh.month <= 3 ? gh.year - 1 : gh.year;

/// 往路・復路の成績を記録し始めた年度(0は未設定。1以下なら最初の正月駅伝から全部ある。2.0.0)
int choukiOufukuKaishi(UnivData u) {
  final List<int>? g = _gyou(u);
  if (g == null) return 0;
  return g[_oufukuKaishi];
}

/// 往路・復路の成績を、最初の正月駅伝から全部記録しているか(2.0.0より前から遊んでいるデータは
/// 記録を始める前の分がないので、「初の往路優勝」や「○度目」と言い切れない)
bool choukiOufukuZenbu(UnivData u) => choukiOufukuKaishi(u) <= 1;

/// 往路・復路の成績を記録し始めた年度が未設定なら、最初から全部記録しているとして1にする
/// (新しく始めたゲームの最初の正月駅伝。oufuku_kiroku.dart。保存は呼び出し側で行う)
void choukiOufukuKaishiSettei(UnivData u) {
  final List<int>? g = _gyou(u);
  if (g == null || g[_oufukuKaishi] != 0) return;
  g[_oufukuKaishi] = 1;
}

/// 出来事[dekigoto]の連続の回数を「分からない」にする(記録を始める前から続いているかもしれないとき。
/// 往路・復路を記録し始めた年度の正月駅伝で、出来事があった大学。保存は呼び出し側で行う)
void choukiRenzokuFumei(UnivData u, int race, int dekigoto) {
  final int b = _bangou(race, dekigoto);
  final List<int>? g = _gyou(u);
  if (b < 0 || g == null) return;
  final ChoukiKiroku k = _yomuAtai(g[b]);
  _kaku(g, b, k.saigo, k.mae, 0);
}

/// 大会[race]の結果を記録したあとに呼ぶ(KirokuKousin.dart。順位の記録をずらして[0]に今回の順位を
/// 入れたあと。[1]が前回の順位)。[nendo] 今回の大会の年度。保存は呼び出し側で行う
void choukiKousin(UnivData u, int race, int nendo) {
  final int kb = _kaisaiBangou(race);
  final List<int>? g = _gyou(u);
  if (kb < 0 || g == null || nendo <= 0) return;
  if (u.juni_race.length <= race || u.juni_race[race].isEmpty) return;
  // 新しく始めたゲームは、ここで使い始める(今までのセーブデータは、choukiIkou で印を付けてある)
  g[_shirushi] = 1;
  g[kb] = nendo;
  final int juni = u.juni_race[race][0];
  final int mae = u.juni_race[race].length > 1
      ? u.juni_race[race][1]
      : TEISUU.DEFAULTJUNI;
  for (final int d in _dekigotoList) {
    final int b = _bangou(race, d);
    if (b < 0 || !choukiAtta(race, d, juni)) continue;
    final ChoukiKiroku k = _yomuAtai(g[b]);
    if (k.saigo == nendo) continue; // この年度の分はもう記録した
    final int renzoku = choukiAtta(race, d, mae)
        ? (k.renzoku == 0 ? 0 : k.renzoku + 1)
        : 1;
    _kaku(g, b, nendo, k.saigo, renzoku);
  }
}

/// 大会[race]の今年度の回が、今の日付[gh]までに終わっているか(移行のときだけ使う。日程は main.dart)
/// 大会の日は、結果を記録したあとの画面(結果・金銀の獲得・スキップ中など)なら終わったとみなす
bool _konnendoOwatta(int race, Ghensuu gh) {
  // 大会の月と日(対校戦の総合は、最終種目のハーフの5月25日で決まる)
  const Map<int, List<int>> hiList = {
    9: [5, 25],
    0: [10, 5],
    1: [11, 5],
    2: [1, 5],
    5: [2, 25],
    ouroRace: [1, 5],
    fukuroRace: [1, 5],
  };
  final List<int>? hi = hiList[race];
  if (hi == null) return false;
  // 年度の中の月の順(4月が0、3月が11)
  int jun(int month) => month >= 4 ? month - 4 : month + 8;
  final int ima = jun(gh.month) * 100 + gh.day;
  final int taikai = jun(hi[0]) * 100 + hi[1];
  if (ima != taikai) return ima > taikai;
  return _owattaMode.contains(gh.mode);
}

/// 大会の結果を記録したあとの画面(結果・金銀の獲得・能力の見える化・夏合宿の案内・スキップ中)
const Set<int> _owattaMode = {700, 5555, 8888, 8890, 9080};

/// 対校戦の総合の順位の記録が、今年度の途中経過になっているか(5000mのあとから、ハーフの結果の前まで。
/// その間は[0]が今年度の途中の順位で、[1]が前年度の総合の順位。KirokuKousin.dart)
bool _taikousenTochuu(Ghensuu gh) {
  if (gh.month != 5) return false;
  if (gh.day == 5) return _owattaMode.contains(gh.mode);
  if (gh.day == 25) return !_owattaMode.contains(gh.mode);
  return gh.day > 5 && gh.day < 25;
}

/// 今までのセーブデータに、直近の順位の記録から分かる分を入れる(2.0.0)
/// 印のある大学(使い始めている大学)は何もしないので、何度呼んでもよい
/// (main.dart の起動のときと、save_load_screen.dart の読み込みのときに呼ぶ)
Future<void> choukiIkou(List<UnivData> univs, Ghensuu gh) async {
  final int nendoIma = choukiNendo(gh);
  // 大会ごとの、記録の一番新しい終わった回の位置(順位の記録の番号)と、その年度(まだ開かれていなければ0)
  final Map<int, int> hajime = {};
  final Map<int, int> kaisai = {};
  for (final int race in choukiRaceList) {
    final bool hirakareta = univs.any(
      (u) =>
          race < u.taikaibetushutujoukaisuu.length &&
          u.taikaibetushutujoukaisuu[race] > 0,
    );
    final bool tochuu = race == 9 && _taikousenTochuu(gh);
    hajime[race] = tochuu ? 1 : 0;
    kaisai[race] = !hirakareta
        ? 0
        : (tochuu
              ? nendoIma - 1
              : (_konnendoOwatta(race, gh) ? nendoIma : nendoIma - 1));
  }
  // 往路・復路の成績を記録し始める年度(正月駅伝がもう開かれていれば、次の正月駅伝から。
  // まだ一度も開かれていなければ、最初から全部記録できるので1)
  final int oufukuKaishi = kaisai[2]! > 0 ? kaisai[2]! + 1 : 1;
  for (final UnivData u in univs) {
    final List<int>? g = _gyou(u);
    if (g == null) continue;
    bool kawatta = false;
    // 往路・復路の記録開始年度(2.0.0。印とは別に見るので、往路・復路より前の2.0.0testで
    // 印を付けたデータにも入る)
    if (g[_oufukuKaishi] == 0) {
      g[_oufukuKaishi] = oufukuKaishi;
      kawatta = true;
    }
    if (g[_shirushi] == 1) {
      if (kawatta) await u.save();
      continue;
    }
    for (final int race in choukiRaceList) {
      final int k0 = kaisai[race]!;
      final int h = hajime[race]!;
      g[_kaisaiBangou(race)] = k0;
      if (k0 <= 0 || u.juni_race.length <= race) continue;
      final List<int> juni = u.juni_race[race];
      for (final int d in _dekigotoList) {
        final int b = _bangou(race, d);
        if (b < 0) continue;
        // 直近の記録で出来事があった回(新しい順。年度は、開かれなかった年のないものとして数える)
        final List<int> atta = [
          for (int i = h; i < juni.length; i++)
            if (choukiAtta(race, d, juni[i])) i,
        ];
        final int tsuusan = choukiTsuusan(u, race, d);
        if (atta.isEmpty) {
          // 記録より前にあったなら、年度は分からない(記録の一番古い回より前とだけ覚える)
          final int ijen = k0 - (juni.length - h);
          _kaku(g, b, 0, (tsuusan > 0 && ijen >= 1) ? ijen : 0, 0);
          continue;
        }
        int nendo(int i) {
          final int n = k0 - (i - h);
          return n < 1 ? 1 : n;
        }

        // 連続の回数(記録の一番古い回まで続いていて、それより前にもあったなら、分からない)
        int c = 0;
        for (int i = atta[0]; i < juni.length && choukiAtta(race, d, juni[i]); i++) {
          c++;
        }
        final bool fumei = atta[0] + c >= juni.length && tsuusan > c;
        _kaku(
          g,
          b,
          nendo(atta[0]),
          atta.length >= 2 ? nendo(atta[1]) : 0,
          fumei ? 0 : c,
        );
      }
    }
    g[_shirushi] = 1;
    await u.save();
  }
}
