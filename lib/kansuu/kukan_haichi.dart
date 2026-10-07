import 'dart:math'; // pow
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/konki_best.dart'; // 持ちタイム(今季ベスト。なければ自己ベスト)
import 'package:ekiden/kansuu/nouryoku_eikyodo.dart'; // 能力のタイムへの影響度
import 'package:ekiden/kansuu/mokuhyou_hosei.dart'; // 目標順位を下回ったときの悪化の強さ

// ------------------------------------------------------------
// 駅伝の区間配置(最適解区間配置を使わないやり方。1.9.1で作り直した。EntryCalc.dart から使う)
//
// 1.9.0までは、区間の特徴の点数で決めた順に、持ちタイムと坂の適性の点数が一番高い選手を
// 当てはめていた(坂の適性が実際のタイムへの効き目より重く、年間強化練習と経験補正も見ていなかった)。
//
// ■ 見積もり区間タイム(秒)
// ・持ちタイム(今季ベスト。なければ自己ベスト)を、区間の距離に近い種目から選ぶ
//   (15km超はハーフ→1万→5000m、7.5km超は1万→5000m→ハーフ、それ以外は5000m→1万→ハーフ)。
//   区間の距離に一番近い種目の記録がなく、ほかの種目で代えたときは1%遅く見る
// ・持ちタイムから、その種目のレースで効いていた能力の分(長距離粘り・スパート力、
//   ハーフはロード適性、5000m・1万はペース変動対応力)を除いてから、区間の距離に合わせ
//   (距離の比の1.06乗)、区間で効く能力の分をレースの計算(RaceCalc.dart)と同じ式で足す
//   (登り・下り・アップダウン・経験補正・ロード適性・ペース変動対応力・長距離粘り・スパート力)。
//   能力には年間強化練習の上乗せを足し、駅伝の分には能力のタイムへの影響度の設定も掛ける。
//   大学の個性(実力発揮度)と調子は見ない
// ・1区は集団走の仕組みを入れる。集団のペースの見込みは、出場する大学ごとの
//   「1区の一番速い見積もり」の真ん中の値。見込みより速い選手と、1%以内遅い選手は差を半分に、
//   1〜3%遅い選手はそのまま、3%より遅い選手は2.5%悪く見る(RaceCalc.dart の集団走と同じ)
//
// ■ 決める順番
// ・残りの区間ごとに、残りの選手の中で一番速い見積もりと二番目の見積もりの差を出し、
//   差に区間の重みを掛けた値が一番大きい区間から、一番速い選手を当てはめる(毎回計算し直す)
// ・区間の重みは、大学ごとの「区間配置の方針」で決める(下の kukanOmomi)
//
// ■ 区間配置の方針(大学ごと。大学画面の「区間配置の方針」で設定)
// ・KantokuData.yobiint2[80]に大学0〜14、[81]に大学15〜29を、1大学1桁で詰める(大学id%15の位)
//   0標準(初期値)・1なし・2弱め・3強め・4とても強め・5後半重視
// ・前半重視(標準〜とても強め): 1区の重みを「1+0.5×倍率×目標順位を下回ったときの悪化の強さ」にして、
//   最終区の1.0まで同じ幅で下げる(倍率は 標準1・なし0・弱め0.5・強め2・とても強め3)。
//   悪化の強さが100%なら、標準で1区1.5倍、とても強めで2.5倍。悪化の強さが0%なら前半重視しない
// ・後半重視: 1区1.0倍から最終区1.25倍まで上げる(悪化の強さに関係なし)
// ・プレイヤーの大学の方針は、区間エントリーの初期案に使う。学連選抜はいつも標準
// ・最適解区間配置を使う大学(コンピュータの大学で、最適解区間配置確率による)には効かない
// ------------------------------------------------------------

/// KantokuData.yobiint2 の使用番号: 大学ごとの区間配置の方針(1大学1桁)
const int kukanHaichiHoushinIndex0 = 80; // 大学0〜14
const int kukanHaichiHoushinIndex1 = 81; // 大学15〜29
const int kukanHaichiHoushinKetasuu = 15; // 1つに格納する大学数

/// 区間配置の方針の名前(番号0〜5)。0(標準)が初期値
const List<String> kukanHaichiHoushinMei = [
  '標準',
  'なし',
  '弱め',
  '強め',
  'とても強め',
  '後半重視',
];

/// 画面のプルダウンに並べる順(前半重視の弱い順: 後半重視・なし・弱め・標準・強め・とても強め)
/// 画面には倍率を出さない(見てもピンとこないため。倍率はこのファイルの先頭のコメントだけ)
const List<int> kukanHaichiHoushinNarabi = [5, 1, 2, 0, 3, 4];

const int _houshinKouhan = 5;

/// 前半重視の倍率(番号0〜4。後半重視は別)
const List<double> _zenhanBairitsu = [1.0, 0.0, 0.5, 2.0, 3.0];

int _juu(int n) {
  int v = 1;
  for (int i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}

/// 大学の区間配置の方針(0〜5)
int kukanHaichiHoushin(KantokuData kantoku, int univid) {
  if (univid < 0 || univid >= TEISUU.UNIVSUU) return 0;
  final int idx = univid < kukanHaichiHoushinKetasuu
      ? kukanHaichiHoushinIndex0
      : kukanHaichiHoushinIndex1;
  if (kantoku.yobiint2.length <= idx) return 0;
  final int v = kantoku.yobiint2[idx];
  if (v < 0) return 0;
  final int code = (v ~/ _juu(univid % kukanHaichiHoushinKetasuu)) % 10;
  return code < kukanHaichiHoushinMei.length ? code : 0;
}

/// 大学の区間配置の方針を書き換える(yobiint2 のリストを直接書き換える。保存は呼び出し側)
void kukanHaichiHoushinSettei(List<int> yobiint2, int univid, int code) {
  if (univid < 0 || univid >= TEISUU.UNIVSUU) return;
  if (code < 0 || code >= kukanHaichiHoushinMei.length) return;
  final int idx = univid < kukanHaichiHoushinKetasuu
      ? kukanHaichiHoushinIndex0
      : kukanHaichiHoushinIndex1;
  if (yobiint2.length <= idx) return;
  final int keta = _juu(univid % kukanHaichiHoushinKetasuu);
  int v = yobiint2[idx];
  if (v < 0) v = 0;
  final int ima = (v ~/ keta) % 10;
  yobiint2[idx] = v + (code - ima) * keta;
}

/// yobiint2[80]・[81]に保存する値として正しいか(QRコードの読み込みで使う)
bool kukanHaichiHoushinAtaiTadashii(int v) {
  if (v < 0) return false;
  int x = v;
  for (int i = 0; i < kukanHaichiHoushinKetasuu; i++) {
    if (x % 10 >= kukanHaichiHoushinMei.length) return false;
    x ~/= 10;
  }
  return x == 0;
}

/// 区間ごとの重み(差がつく区間から決めるときに、見積もりの差に掛ける)
List<double> kukanOmomi(KantokuData kantoku, int houshin, int kukansuu) {
  final List<double> w = List.filled(kukansuu, 1.0);
  if (kukansuu <= 0) return w;
  final int saigo = kukansuu - 1;
  if (houshin == _houshinKouhan) {
    for (int i = 0; i < kukansuu; i++) {
      w[i] = saigo == 0 ? 1.0 : 1.0 + 0.25 * i / saigo;
    }
    return w;
  }
  final double bairitsu = (houshin >= 0 && houshin < _zenhanBairitsu.length)
      ? _zenhanBairitsu[houshin]
      : 1.0;
  final double tsuyosa =
      hoseiTsuyosaPercent(kantoku, hoseiTsuyosaShitamawariIndex) / 100.0;
  final double haba = 0.5 * bairitsu * tsuyosa;
  for (int i = 0; i < kukansuu; i++) {
    w[i] = saigo == 0 ? 1.0 + haba : 1.0 + haba * (saigo - i) / saigo;
  }
  return w;
}

/// 見積もりに使う選手の情報(SenshuData と Senshu_Gakuren_Data の両方から作る)
class KukanSenshu {
  final List<double> mochi; // [5000m, 1万, ハーフ]の持ちタイム(記録なしは DEFAULTTIME)
  final int nebari;
  final int spurt;
  final int nobori;
  final int kudari;
  final int updown;
  final int road;
  final int pace;
  final int menu; // 年間強化練習のメニュー(kaifukuryoku)
  final int gakunen;
  final List<List<int>> entrykukan; // 経験補正用(entrykukan_race)

  const KukanSenshu({
    required this.mochi,
    required this.nebari,
    required this.spurt,
    required this.nobori,
    required this.kudari,
    required this.updown,
    required this.road,
    required this.pace,
    required this.menu,
    required this.gakunen,
    required this.entrykukan,
  });

  factory KukanSenshu.fromSenshu(SenshuData s) => KukanSenshu(
    mochi: [for (int i = 0; i < 3; i++) hikakuMochiTime(s, i)],
    nebari: s.choukyorinebari,
    spurt: s.spurtryoku,
    nobori: s.noboritekisei,
    kudari: s.kudaritekisei,
    updown: s.noborikudarikirikaenouryoku,
    road: s.tandokusou,
    pace: s.paceagesagetaiouryoku,
    menu: s.kaifukuryoku,
    gakunen: s.gakunen,
    entrykukan: s.entrykukan_race,
  );

  factory KukanSenshu.fromGakuren(Senshu_Gakuren_Data g) => KukanSenshu(
    mochi: [for (int i = 0; i < 3; i++) hikakuMochiTimeGakuren(g, i)],
    nebari: g.choukyorinebari,
    spurt: g.spurtryoku,
    nobori: g.noboritekisei,
    kudari: g.kudaritekisei,
    updown: g.noborikudarikirikaenouryoku,
    road: g.tandokusou,
    pace: g.paceagesagetaiouryoku,
    menu: g.kaifukuryoku,
    gakunen: g.gakunen,
    entrykukan: g.entrykukan_race,
  );
}

/// 持ちタイムの種目の距離(5000m・1万・ハーフ)
const List<double> _kirokuKyori = [5000.0, 10000.0, 21097.5];

/// 記録がまったくない選手の見積もり(どの区間でも最後に回る)
const double _kirokuNashiTime = 9999999.0;

/// 見積もりの条件(大会ごとに1回作る)
class KukanMitsumoriJouken {
  final Ghensuu gh;
  final int racebangou;
  final NouryokuEikyodo eikyodo;
  final int kyoudo; // 年間強化練習の強さ(KantokuData.yobiint2[16])
  KukanMitsumoriJouken(this.gh, this.racebangou, KantokuData kantoku)
    : eikyodo = NouryokuEikyodo.fromKantoku(kantoku),
      kyoudo = kantoku.yobiint2.length > 16 ? kantoku.yobiint2[16] : 4;
}

/// 年間強化練習の上乗せ(RaceCalc.dart と同じ量)
/// 並びは [長距離粘り, スパート力, 登り, 下り, アップダウン, ロード, ペース変動]
List<int> _uwanose(int menu, int kyoudo) {
  final List<int> u = List.filled(7, 0);
  switch (menu) {
    case 0: // バランス
      for (int i = 0; i < 7; i++) {
        u[i] = kyoudo;
      }
      break;
    case 1: // スピード
      u[1] = kyoudo * 7 ~/ 2;
      u[6] = kyoudo * 7 ~/ 2;
      break;
    case 2: // 距離走
      u[0] = kyoudo * 4 ~/ 2;
      u[5] = kyoudo * 4 ~/ 2;
      break;
    case 3: // 登り
      u[2] = kyoudo * 7;
      break;
    case 4: // 下り
      u[3] = kyoudo * 7;
      break;
    case 5: // アップダウン
      u[4] = kyoudo * 7;
      break;
  }
  return u;
}

/// 長距離粘りで増えるタイム(ChoukyoriNebariHoseitime.dart と同じ式。全体の抑制値は見ない)
double _nebariTime(double kyori, double nebari) {
  if (kyori <= 15000.0) return 0.0;
  return (kyori - 14999.999) /
      100.0 *
      (TEISUU.MAXTIMEHOSEI_CHOUKYORINEBARI_PER100m / 98.0) *
      (117.0 - nebari);
}

/// スパート力で変わるタイム(SpurtRyokuHoseitime.dart と同じ式。マイナスで速くなる)
double _spurtTime(double spurt) {
  return 8.0 * (TEISUU.MAXTIMEHOSEI_SPURTRYOKU_PER100m / 98.0) * spurt;
}

/// 選手が区間[k]を走ったときの見積もりタイム(秒。1区の集団走は入れない)
double kukanMitsumoriTime(KukanSenshu s, int k, KukanMitsumoriJouken j) {
  final Ghensuu gh = j.gh;
  final int r = j.racebangou;
  double atai(List<List<double>> list) =>
      (r < list.length && k < list[r].length) ? list[r][k] : 0.0;
  final double kyori = atai(gh.kyori_taikai_kukangoto);
  if (kyori <= 0.0) return _kirokuNashiTime;

  // 持ちタイムの種目(区間の距離に近い順)
  final List<int> jun = kyori > 15000.0
      ? [2, 1, 0]
      : (kyori > 7500.0 ? [1, 0, 2] : [0, 1, 2]);
  int shu = -1;
  for (final int i in jun) {
    if (i < s.mochi.length && s.mochi[i] < TEISUU.DEFAULTTIME) {
      shu = i;
      break;
    }
  }
  if (shu < 0) return _kirokuNashiTime;

  // 能力(年間強化練習の上乗せを足す)
  final List<int> u = _uwanose(s.menu, j.kyoudo);
  final double nebari = (s.nebari + u[0]).toDouble();
  final double spurt = (s.spurt + u[1]).toDouble();
  final double nobori = (s.nobori + u[2]).toDouble();
  final double kudari = (s.kudari + u[3]).toDouble();
  final double updown = (s.updown + u[4]).toDouble();
  final double road = (s.road + u[5]).toDouble();
  final double pace = (s.pace + u[6]).toDouble();

  // 持ちタイムから、その種目のレースで効いていた能力の分を除く
  // (記録会・インカレには能力のタイムへの影響度はかからない。ハーフはロード適性、
  //  5000m・1万はペース変動対応力が効く。RaceCalc.dart と同じ)
  final double kirokuKyori = _kirokuKyori[shu];
  final double frKiroku = shu == 2 ? (100.0 - road) * 0.0003 : 0.0;
  final double fpKiroku = shu == 2 ? 0.0 : (100.0 - pace) * 0.0003;
  final double moto =
      (s.mochi[shu] - _nebariTime(kirokuKyori, nebari) - _spurtTime(spurt)) /
      ((1.0 + frKiroku) * (1.0 + fpKiroku));

  // 区間の距離に合わせる
  double t = moto * pow(kyori / kirokuKyori, 1.06).toDouble();

  // 区間で効く能力の分(駅伝は能力のタイムへの影響度をかける)
  final NouryokuEikyodo e = j.eikyodo;
  double eff(double x, double eikyodo) => 50.0 + eikyodo * (x - 50.0);
  // 登り・下り・アップダウン(速さに掛かる)
  final double hNobori =
      atai(gh.kyoriwariainobori_taikai_kukangoto) *
      atai(gh.heikinkoubainobori_taikai_kukangoto);
  final double hKudari =
      atai(gh.kyoriwariaikudari_taikai_kukangoto) *
      atai(gh.heikinkoubaikudari_taikai_kukangoto);
  final List<List<int>> kirikaeList =
      gh.noborikudarikirikaekaisuu_taikai_kukangoto;
  final int kirikae = (r < kirikaeList.length && k < kirikaeList[r].length)
      ? kirikaeList[r][k]
      : 0;
  final double hoseiNobori =
      -(0.044 - 0.00017 * eff(nobori, e.nobori) * TEISUU.CHOUSEI_NOBORI) *
      (hNobori / 0.01);
  final double hoseiKudari =
      (0.00965 + 0.00018 * eff(kudari, e.kudari) * TEISUU.CHOUSEI_KUDARI) *
      (-hKudari / 0.01);
  final double hoseiKirikae =
      -TEISUU.CHOUSEI_KIRIKAE * kirikae * (135.0 - eff(updown, e.updown));
  final double sokudo = 1.0 + hoseiNobori + hoseiKudari + hoseiKirikae;
  if (sokudo > 0.1) t = t / sokudo;
  // 経験補正(同じ区間を走った回数×0.3%。chousi_keiken_hosei.dart と同じ)
  if ((r >= 0 && r <= 2) || r == 5) {
    double keiken = 0.0;
    for (int g = s.gakunen - 1; g >= 1; g--) {
      if (r < s.entrykukan.length && g - 1 < s.entrykukan[r].length) {
        final int entry = s.entrykukan[r][g - 1];
        if (entry >= 0 && entry == k) keiken -= 0.003;
      }
    }
    t += t * keiken;
  }
  // ロード適性・ペース変動対応力(効く区間と割合は RaceCalc.dart と同じ)
  double roadWariai = 1.0;
  double paceWariai = 0.0;
  if ((r != 4 && k == 0) || r == 3) {
    roadWariai = 0.0;
    paceWariai = 1.0;
  } else if (r == 4 || (k >= 1 && k <= 2)) {
    roadWariai = 0.5;
    paceWariai = 0.5;
  }
  t += t * (100.0 - eff(road, e.road)) * 0.0003 * roadWariai;
  t += t * (100.0 - eff(pace, e.pace)) * 0.0003 * paceWariai;
  // 長距離粘り・スパート力
  t += _nebariTime(kyori, eff(nebari, e.nebari));
  t += _spurtTime(eff(spurt, e.spurt));
  // 区間の距離に一番近い種目の記録がなかったときは、1%遅く見る
  if (shu != jun[0]) t *= 1.01;
  return t;
}

/// 1区の集団走を入れた見積もり(RaceCalc.dart の集団走と同じ考え方。[pace]は集団のペースの見込み)
double ikkuShuudanMitsumori(double t, double pace) {
  if (pace <= 0.0 || t >= _kirokuNashiTime) return t;
  if (t < pace) return (pace + t) / 2.0; // 集団より速い: 差が半分
  if (t <= pace * 1.01) return (pace + t) / 2.0; // 1%以内遅い: 差が半分
  if (t <= pace * 1.03) return t; // 1〜3%遅い: そのまま
  return t * 1.025; // 3%より遅い: 大失速
}

/// 1区で集団走になる大会か(駅伝の1区。11月駅伝予選は区間配置を使わない)
bool _ikkuShuudan(int racebangou) =>
    (racebangou >= 0 && racebangou <= 2) || racebangou == 5;

/// 集団のペースの見込み(出場する大学ごとの「1区の一番速い見積もり」の真ん中の値)
double ikkuShuudanPace(
  List<List<KukanSenshu>> daigakuGotoKouho,
  KukanMitsumoriJouken j,
) {
  final List<double> ichiban = [];
  for (final List<KukanSenshu> kouho in daigakuGotoKouho) {
    double best = _kirokuNashiTime;
    for (final KukanSenshu s in kouho) {
      final double t = kukanMitsumoriTime(s, 0, j);
      if (t < best) best = t;
    }
    if (best < _kirokuNashiTime) ichiban.add(best);
  }
  if (ichiban.isEmpty) return 0.0;
  ichiban.sort();
  final int n = ichiban.length;
  return n.isOdd
      ? ichiban[n ~/ 2]
      : (ichiban[n ~/ 2 - 1] + ichiban[n ~/ 2]) / 2.0;
}

/// 候補の選手の、区間ごとの見積もり([選手][区間])。1区は集団走を入れる
List<List<double>> kukanMitsumoriHyou(
  List<KukanSenshu> kouho,
  KukanMitsumoriJouken j,
  double ikkuPace,
) {
  final int kukansuu = j.gh.kukansuu_taikaigoto[j.racebangou];
  return [
    for (final KukanSenshu s in kouho)
      [
        for (int k = 0; k < kukansuu; k++)
          (k == 0 && _ikkuShuudan(j.racebangou))
              ? ikkuShuudanMitsumori(kukanMitsumoriTime(s, k, j), ikkuPace)
              : kukanMitsumoriTime(s, k, j),
      ],
  ];
}

/// 差がつく区間から順に選手を決める
/// [mitsumori] は[選手][区間]の見積もり、[omomi] は区間の重み
/// 戻り値の1つ目は区間ごとの選手の番号(mitsumoriの添字。選手が足りない区間は-1)、
/// 2つ目は区間を決めた順(区間の番号)
(List<int>, List<int>) sagaTsukuJunHaichi(
  List<List<double>> mitsumori,
  List<double> omomi,
) {
  final int kukansuu = omomi.length;
  final int senshusuu = mitsumori.length;
  final List<int> kekka = List.filled(kukansuu, -1);
  final List<int> junban = [];
  final Set<int> tsukatta = {};
  while (junban.length < kukansuu && tsukatta.length < senshusuu) {
    int kimeruKukan = -1;
    int kimeruSenshu = -1;
    double saidaiSa = -1.0;
    for (int k = 0; k < kukansuu; k++) {
      if (kekka[k] >= 0) continue;
      double ichiban = double.infinity;
      double niban = double.infinity;
      int ichibanSenshu = -1;
      for (int i = 0; i < senshusuu; i++) {
        if (tsukatta.contains(i)) continue;
        final double t = k < mitsumori[i].length
            ? mitsumori[i][k]
            : _kirokuNashiTime;
        if (t < ichiban) {
          niban = ichiban;
          ichiban = t;
          ichibanSenshu = i;
        } else if (t < niban) {
          niban = t;
        }
      }
      if (ichibanSenshu < 0) continue;
      // 残りが1人なら、その区間を先に決める
      final double sa = (niban == double.infinity ? 1.0e12 : niban - ichiban) *
          omomi[k];
      if (sa > saidaiSa) {
        saidaiSa = sa;
        kimeruKukan = k;
        kimeruSenshu = ichibanSenshu;
      }
    }
    if (kimeruKukan < 0) break;
    kekka[kimeruKukan] = kimeruSenshu;
    junban.add(kimeruKukan);
    tsukatta.add(kimeruSenshu);
  }
  return (kekka, junban);
}

/// 通常の区間配置(出場する全大学。最適解区間配置を使わないやり方)
/// 区間エントリーの値は、呼び出す前に、走れる選手は-1、エントリー外は-2にしておくこと。
/// 戻り値は、プレイヤーの大学で区間を決めた順(プレイヤーの大学が出場しなければ空)
Future<List<int>> kukanHaichiZenDaigaku({
  required int racebangou,
  required Ghensuu gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
  required KantokuData kantoku,
  Future<void> Function()? kyuukei, // 画面が固まらないように、ときどき休む処理
}) async {
  final KukanMitsumoriJouken j = KukanMitsumoriJouken(
    gh,
    racebangou,
    kantoku,
  );
  final int kukansuu = gh.kukansuu_taikaigoto[racebangou];
  // 大学ごとの候補(-2はエントリー外なので除く)
  final Map<int, List<SenshuData>> kouho = {};
  for (final UnivData u in sortedUnivData) {
    if (u.taikaientryflag.length > racebangou &&
        u.taikaientryflag[racebangou] == 1) {
      kouho[u.id] = sortedSenshuData
          .where(
            (s) =>
                s.univid == u.id &&
                s.entrykukan_race[racebangou][s.gakunen - 1] >= -1,
          )
          .toList();
    }
  }
  final Map<int, List<KukanSenshu>> kouhoJouhou = {
    for (final MapEntry<int, List<SenshuData>> e in kouho.entries)
      e.key: [for (final SenshuData s in e.value) KukanSenshu.fromSenshu(s)],
  };
  final double ikkuPace = _ikkuShuudan(racebangou)
      ? ikkuShuudanPace(kouhoJouhou.values.toList(), j)
      : 0.0;

  List<int> myJunban = [];
  for (final MapEntry<int, List<SenshuData>> e in kouho.entries) {
    if (kyuukei != null) await kyuukei();
    final int univid = e.key;
    final List<SenshuData> senshu = e.value;
    final List<List<double>> mitsumori = kukanMitsumoriHyou(
      kouhoJouhou[univid]!,
      j,
      ikkuPace,
    );
    final List<double> omomi = kukanOmomi(
      kantoku,
      kukanHaichiHoushin(kantoku, univid),
      kukansuu,
    );
    final haichi = sagaTsukuJunHaichi(mitsumori, omomi);
    final List<int> kekka = haichi.$1;
    if (univid == gh.MYunivid) myJunban = haichi.$2;
    for (int k = 0; k < kukansuu; k++) {
      final int i = kekka[k];
      if (i < 0) continue;
      final SenshuData s = senshu[i];
      s.entrykukan_race[racebangou][s.gakunen - 1] = k;
      await s.save();
    }
  }
  return myJunban;
}

/// 学連選抜の区間配置(正月駅伝。方針はいつも標準。集団のペースの見込みは大学と同じ)
Future<void> kukanHaichiGakuren({
  required Ghensuu gh,
  required List<UnivData> sortedUnivData,
  required List<SenshuData> sortedSenshuData,
  required List<Senshu_Gakuren_Data> gakurenSenshu,
  required KantokuData kantoku,
}) async {
  const int racebangou = 2;
  final KukanMitsumoriJouken j = KukanMitsumoriJouken(
    gh,
    racebangou,
    kantoku,
  );
  final int kukansuu = gh.kukansuu_taikaigoto[racebangou];
  // 集団のペースの見込み(出場する大学の候補から。学連選抜も1チームとして入れる)
  final List<List<KukanSenshu>> daigakuGoto = [];
  for (final UnivData u in sortedUnivData) {
    if (u.taikaientryflag.length > racebangou &&
        u.taikaientryflag[racebangou] == 1) {
      daigakuGoto.add([
        for (final SenshuData s in sortedSenshuData)
          if (s.univid == u.id &&
              s.entrykukan_race[racebangou][s.gakunen - 1] >= -1)
            KukanSenshu.fromSenshu(s),
      ]);
    }
  }
  final List<KukanSenshu> kouho = [
    for (final Senshu_Gakuren_Data g in gakurenSenshu)
      KukanSenshu.fromGakuren(g),
  ];
  daigakuGoto.add(kouho);
  final double ikkuPace = ikkuShuudanPace(daigakuGoto, j);
  final List<List<double>> mitsumori = kukanMitsumoriHyou(kouho, j, ikkuPace);
  final List<double> omomi = kukanOmomi(kantoku, 0, kukansuu);
  final List<int> kekka = sagaTsukuJunHaichi(mitsumori, omomi).$1;
  for (int k = 0; k < kukansuu; k++) {
    final int i = kekka[k];
    if (i < 0) continue;
    final Senshu_Gakuren_Data g = gakurenSenshu[i];
    g.entrykukan_race[racebangou][g.gakunen - 1] = k;
    await g.save();
  }
}
