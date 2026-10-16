import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/taikai_chouki.dart';

// ------------------------------------------------------------
// 強化プロジェクト(2.0.1)
//
// 正月駅伝の優勝から遠ざかっている大学が、数年間だけスカウトに本腰を入れる出来事
// (自分の大学は、設定で選んだときだけ。初期値はコンピュータの大学だけ)。
// 2.0.1の開発中に、1校が何十年も正月駅伝を勝ち続ける形が目立ったため、挑戦者がときどき現れて
// 王者を脅かすように入れた(現実でも、創立100周年に向けた強化やクラウドファンディングなどがある)。
// 模擬計算(30年・名声2位並み・4年)では、30年で2回ほど起き、始めた大学の8割が数年で正月駅伝の
// 3位以内に入り、優勝まで届くのは半分弱だった。最多優勝の大学の回数はあまり変わらない
// (この模擬計算は、対象を名声15位までにしていたときのもの)。
//
// ・起き方: 年度替わり(4月5日の処理。RetireNewの前)に、設定の確率で抽選する(同時に1校まで)。
//   一度も正月駅伝が開かれていないとき(新しいゲームの1年目)は起きない
// ・対象: 名声の順位(年度替わりの前の名声の合計の順)が4位以下で、正月駅伝の最後の優勝から15年以上
//   たっているか、優勝がない大学から1校をくじで選ぶ(最後の優勝は大会の長い記録 taikai_chouki.dart で数える)。
//   開発中は名声15位までにしていたが、最底辺で遊んでいる人に「自分の大学には起きない」と思わせないように、
//   また下位の大学の下剋上の物語も生まれるように、下限をなくした(候補が増えるので、王者を脅かせる
//   中位の大学に回る回数は半分くらいになる)。説明には数字を書かない
// ・自分の大学: 設定で「選ばれる」にしたときだけ候補に入る(初期値は選ばれない)。選ばれやすさはほかの大学と同じ
//   (候補が25校ほどなので、年0.4%ほどのまれな出来事)。効き目もコンピュータの大学と同じ
//   (コンピュータスカウトOFFのときは、新入生の振り分けの重みだけ)
// ・効き目(期間中だけ。スカウトだけに効く):
//   ・新入生の振り分けの重み(shozokuChuusenOmomi。地区めぐり(声かけ)の争奪戦・最後の志望・
//     コンピュータスカウトOFFの振り分け・地区めぐりの成功率の下限)を、名声N位の大学の重みまで上げる
//   ・全国一斉・地区めぐり(交渉)の交渉の成功率と争奪戦で使う名声を、名声N位の大学の名声まで上げる
//   ・スカウトの性格が「自動」なら、大物狙いにする(scout_com.dart)
// ・設定(説明画面の設定タブの「強化プロジェクト設定」): 起こりやすさ・スカウトでの重み(名声何位並み)・期間・
//   自分の大学も選ばれるか。「なし」にすると、実行中のプロジェクトも効かなくなる
// ・記事: 始まった年の4月5日に、箱庭スポーツの記事(kiji_kyouka.dart。期待のルーキーと一緒に読める)。
//   理由の型は、創立○周年に向けて・クラウドファンディング・OB会と後援会の支援・名指導者の招へいの4つ。
//   目標は大学の状況で変える(正月駅伝初出場・○年ぶりの出場(本戦復帰)・悲願の初優勝・○年ぶりの優勝)。
//   創立○周年は、期間中に創立から25年ごとの区切り(50周年以上)が来るときだけ使う。
//   創立の年度は大学の番号から計算で決める(kyoukaSouritsuNendo。保存しない。同じ大学ならいつも同じ)ので、
//   同じ大学で2回目のプロジェクトが起きても、周年の数が合う。同じ大学で同じ型が続かないように、
//   大学ごとに前回の型を覚えておく
// ・画面(2.0.2から、強化されるスカウトが残っている間だけ出す。kyoukaProjectHyouji。期間は「○年3月のスカウトまで」
//   と書く。kyoukaKikanMoji): 大学画面に「強化プロジェクト中」。スカウト画面では、新入生の一覧の上の帯
//   (右端の×で消せる。そのスカウトが終わるまで消えたまま)と、最初に出るスカウト解禁の記事の上の
//   「スカウト強化中」の表示(9000Freshmankakutoku.dart)。始まった年は、スカウトの画面の最初(記事より前)に、
//   始動のお知らせのダイアログを一度だけ出す(スキップ中はスカウトの画面が出ないので出ない。kyouka_oshirase.dart)
// ・保存(KantokuData.yobiint3。新しいゲームでは0に戻る):
//   [80] 設定(起こりやすさ + 10×重み + 100×期間のコード + 1000×自分の大学も選ばれるか(0=選ばれない・1=選ばれる)。
//        どれも0が初期値)
//   [81] 実行中(最後)のプロジェクト((大学id+1) + 100×型 + 1000×始めた年度 + 10の8乗×終わる年度。0は一度もない)
//   [82]・[83] 大学ごとの前回の型(1大学1桁、[82]に大学0〜14・[83]に大学15〜29、大学id%15の位。0はまだない)
// ------------------------------------------------------------

/// KantokuData.yobiint3 の使用番号: 強化プロジェクトの設定
const int kyoukaSetteiIndex = 80;

/// KantokuData.yobiint3 の使用番号: 実行中(最後)の強化プロジェクト
const int kyoukaJoutaiIndex = 81;

/// KantokuData.yobiint3 の使用番号: 大学ごとの前回の型(大学0〜14)
const int kyoukaMaeKataIndex0 = 82;

/// KantokuData.yobiint3 の使用番号: 大学ごとの前回の型(大学15〜29)
const int kyoukaMaeKataIndex1 = 83;

// ---------------- 設定 ----------------

/// 起こりやすさの名前(コード0〜3。0が初期値)
const List<String> kyoukaOkoriyasusaMei = ['ふつう', 'なし', '少なめ', '多め'];

/// 起こりやすさの、毎年の確率(%)(コードの順)
const List<int> _okoriyasusaPct = [10, 0, 5, 20];

/// 起こりやすさのコードを画面に並べる順(なし・少なめ・ふつう・多め)
const List<int> kyoukaOkoriyasusaNarabi = [1, 2, 0, 3];

/// 起こりやすさのコード: なし
const int kyoukaOkoriyasusaNashi = 1;

/// スカウトでの重み(名声何位並みか)(コード0〜4。0が初期値の2位並み)
const List<int> _omomiJuni = [2, 1, 3, 4, 5];

/// 重みのコードを画面に並べる順(1位並み〜5位並み)
const List<int> kyoukaOmomiNarabi = [1, 0, 2, 3, 4];

/// 期間(年)(コード0〜4。0が初期値の4年)
const List<int> _kikanNen = [4, 2, 3, 5, 6];

/// 期間のコードを画面に並べる順(2年〜6年)
const List<int> kyoukaKikanNarabi = [1, 2, 0, 3, 4];

/// 起こりやすさの画面の名前(「ふつう(毎年10%)」など)
String kyoukaOkoriyasusaHyouji(int code) {
  final int c = (code >= 0 && code < _okoriyasusaPct.length) ? code : 0;
  if (c == kyoukaOkoriyasusaNashi) return kyoukaOkoriyasusaMei[c];
  return '${kyoukaOkoriyasusaMei[c]}(毎年${_okoriyasusaPct[c]}%)';
}

/// 重みの画面の名前(「名声2位並み」)
String kyoukaOmomiHyouji(int code) {
  final int c = (code >= 0 && code < _omomiJuni.length) ? code : 0;
  return '名声${_omomiJuni[c]}位並み';
}

/// 期間の画面の名前(「4年」)
String kyoukaKikanHyouji(int code) {
  final int c = (code >= 0 && code < _kikanNen.length) ? code : 0;
  return '${_kikanNen[c]}年';
}

int _setteiAtai(KantokuData k) =>
    k.yobiint3.length > kyoukaSetteiIndex ? k.yobiint3[kyoukaSetteiIndex] : 0;

/// 起こりやすさのコード(正しくない値は0)
int kyoukaOkoriyasusaCode(KantokuData k) {
  final int v = _setteiAtai(k);
  if (!kyoukaSetteiTadashii(v)) return 0;
  return v % 10;
}

/// 重みのコード(正しくない値は0)
int kyoukaOmomiCode(KantokuData k) {
  final int v = _setteiAtai(k);
  if (!kyoukaSetteiTadashii(v)) return 0;
  return (v ~/ 10) % 10;
}

/// 期間のコード(正しくない値は0)
int kyoukaKikanCode(KantokuData k) {
  final int v = _setteiAtai(k);
  if (!kyoukaSetteiTadashii(v)) return 0;
  return (v ~/ 100) % 10;
}

/// 設定の値が正しいか(QRコードの読み込みで使う)
bool kyoukaSetteiTadashii(int atai) =>
    atai >= 0 &&
    atai < 2000 &&
    atai % 10 < _okoriyasusaPct.length &&
    (atai ~/ 10) % 10 < _omomiJuni.length &&
    (atai ~/ 100) % 10 < _kikanNen.length;

/// 自分の大学も選ばれる設定か(初期値は選ばれない)
bool kyoukaJibunEraberu(KantokuData k) {
  final int v = _setteiAtai(k);
  if (!kyoukaSetteiTadashii(v)) return false;
  return v ~/ 1000 == 1;
}

/// 設定の値(QRコードの書き出しで使う)
int kyoukaSetteiAtai(KantokuData k) {
  final int v = _setteiAtai(k);
  return kyoukaSetteiTadashii(v) ? v : 0;
}

/// 設定を入れる(保存は呼び出し側で行う)
void kyoukaSetteiIreru(
  KantokuData k,
  int okoriyasusa,
  int omomi,
  int kikan,
  bool jibun,
) {
  if (k.yobiint3.length <= kyoukaSetteiIndex) return;
  final int v = okoriyasusa + 10 * omomi + 100 * kikan + (jibun ? 1000 : 0);
  if (!kyoukaSetteiTadashii(v)) return;
  k.yobiint3[kyoukaSetteiIndex] = v;
}

/// 設定の値をそのまま入れる(QRコードの読み込みで使う。保存は呼び出し側で行う)
void kyoukaSetteiAtaiIreru(KantokuData k, int atai) {
  if (k.yobiint3.length <= kyoukaSetteiIndex || !kyoukaSetteiTadashii(atai)) {
    return;
  }
  k.yobiint3[kyoukaSetteiIndex] = atai;
}

/// 強化プロジェクトを起こさない設定か
bool kyoukaNashi(KantokuData k) =>
    kyoukaOkoriyasusaCode(k) == kyoukaOkoriyasusaNashi;

/// 毎年の確率(%)
int kyoukaKakuritsu(KantokuData k) => _okoriyasusaPct[kyoukaOkoriyasusaCode(k)];

/// スカウトでの重みが、名声何位の大学と同じか
int kyoukaOmomiJuni(KantokuData k) => _omomiJuni[kyoukaOmomiCode(k)];

/// 期間(年)
int kyoukaKikanNen(KantokuData k) => _kikanNen[kyoukaKikanCode(k)];

// ---------------- 実行中のプロジェクト ----------------

/// 理由の型: 創立○周年に向けて
const int kyoukaKataShuunen = 1;

/// 理由の型: クラウドファンディング
const int kyoukaKataCrowd = 2;

/// 理由の型: OB会・後援会の支援
const int kyoukaKataOB = 3;

/// 理由の型: 名指導者を強化責任者に招へい
const int kyoukaKataShouhei = 4;

/// 強化プロジェクト1件
class KyoukaProject {
  /// 大学id
  final int univid;

  /// 理由の型(kyoukaKata〜)
  final int kata;

  /// 始めた年度
  final int hajime;

  /// 終わる年度(この年度のスカウトまで効く)
  final int owari;

  const KyoukaProject(this.univid, this.kata, this.hajime, this.owari);
}

const int _keta8 = 100000000;

/// 始動のお知らせのダイアログを、まだ出していないか(2.0.2。メモリだけ。抽選で始まったときに立て、
/// そのすぐあとのスカウトの画面で見たら下ろす。kyouka_oshirase.dart)
class KyoukaShidouOshirase {
  static bool dasu = false;
}

/// 最後(実行中)の強化プロジェクト(一度もなければnull)
KyoukaProject? kyoukaProjectSaigo(KantokuData k) {
  if (k.yobiint3.length <= kyoukaJoutaiIndex) return null;
  final int v = k.yobiint3[kyoukaJoutaiIndex];
  if (v <= 0) return null;
  final int univid = v % 100 - 1;
  final int kata = (v ~/ 100) % 10;
  final int hajime = (v ~/ 1000) % 100000;
  final int owari = v ~/ _keta8;
  if (univid < 0) return null;
  return KyoukaProject(univid, kata, hajime, owari);
}

/// 年度[nendo]に実行中の強化プロジェクト(なければnull。「なし」の設定のときもnull)
KyoukaProject? kyoukaProjectChuu(KantokuData k, int nendo) {
  if (kyoukaNashi(k)) return null;
  final KyoukaProject? p = kyoukaProjectSaigo(k);
  if (p == null || nendo < p.hajime || nendo > p.owari) return null;
  return p;
}

/// 画面に出す強化プロジェクト(2.0.2。強化されるスカウトが残っている間だけ。なければnull)
/// 強化するのはスカウトだけなので、最後のスカウト(終わる年度の3月のスカウト。中の日付は4月5日)が
/// 終わったら、画面からは消す。今の年度が終わる年度になったら、そのスカウトの画面(モード9000)の間だけ出す
/// (年度替わりの処理のすぐあとにスカウトの画面が出るので、ほかの画面では、もう最後のスカウトが終わっている)
KyoukaProject? kyoukaProjectHyouji(KantokuData k, Ghensuu gh) {
  final int nendo = choukiNendo(gh);
  final KyoukaProject? p = kyoukaProjectChuu(k, nendo);
  if (p == null) return null;
  if (nendo >= p.owari && gh.mode != 9000) return null;
  return p;
}

/// 画面に出す期間の書き方(2.0.2。「8年3月のスカウトまで」。最後のスカウトの最中は「今回のスカウトまで」)
/// プレイヤーには、スカウトは3月25日のあとの出来事に見えるので「3月」と書く(卒業の「8年3月」とそろえる。
/// 年は1月に変わるので、終わる年度の数字がそのまま、その3月の年になる)
String kyoukaKikanMoji(KyoukaProject p, Ghensuu gh) =>
    choukiNendo(gh) >= p.owari ? '今回のスカウトまで' : '${p.owari}年3月のスカウトまで';

/// 今の日付で実行中の強化プロジェクト(Hiveから読む。なければnull)
KyoukaProject? kyoukaProjectIma(Ghensuu gh) {
  final KantokuData? k = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
  if (k == null) return null;
  return kyoukaProjectChuu(k, choukiNendo(gh));
}

void _projectKaku(KantokuData k, KyoukaProject p) {
  if (k.yobiint3.length <= kyoukaJoutaiIndex) return;
  k.yobiint3[kyoukaJoutaiIndex] =
      (p.univid + 1) + 100 * p.kata + 1000 * p.hajime + _keta8 * p.owari;
}

int _juu(int n) {
  int v = 1;
  for (int i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}

/// 大学[univid]の前回の型(0はまだない)
int kyoukaMaeKata(KantokuData k, int univid) {
  final int idx = univid < 15 ? kyoukaMaeKataIndex0 : kyoukaMaeKataIndex1;
  if (univid < 0 || k.yobiint3.length <= idx) return 0;
  return (k.yobiint3[idx] ~/ _juu(univid % 15)) % 10;
}

void _maeKataKaku(KantokuData k, int univid, int kata) {
  final int idx = univid < 15 ? kyoukaMaeKataIndex0 : kyoukaMaeKataIndex1;
  if (univid < 0 || k.yobiint3.length <= idx) return;
  final int ketaAtai = _juu(univid % 15);
  final int ima = (k.yobiint3[idx] ~/ ketaAtai) % 10;
  k.yobiint3[idx] += (kata - ima) * ketaAtai;
}

// ---------------- 創立の年度と周年 ----------------

/// 大学[univid]の創立の年度(ゲームの1年度の時点で創立から40〜140年。大学の番号から決める。保存しない)
/// 記事には周年の数だけを書き、創立の年度そのものは書かない(マイナスの年度になりうるため)
int kyoukaSouritsuNendo(int univid) {
  final int h = ((univid + 11) * 2654435761) % 1000003;
  return 1 - (40 + h % 101);
}

/// 年度[hajime]〜[owari]の間に来る、創立から25年ごとの区切り(50周年以上)の年度(なければnull)
int? kyoukaShuunenNendo(int univid, int hajime, int owari) {
  final int souritsu = kyoukaSouritsuNendo(univid);
  for (int y = hajime; y <= owari; y++) {
    final int shuunen = y - souritsu;
    if (shuunen >= 50 && shuunen % 25 == 0) return y;
  }
  return null;
}

// ---------------- 抽選 ----------------

/// 大学[u]の正月駅伝の最後の優勝から、年度[nendo]まで何年か(優勝がなければ大きな数)
int kyoukaYuushouKaraNen(UnivData u, int nendo) {
  final ChoukiKiroku? c = choukiYomu(u, 2, choukiYuushou);
  if (c != null) {
    if (c.saigo > 0) return nendo - c.saigo;
    if (c.mae > 0) return nendo - c.mae; // 記録を始める前の優勝(この年度以前)
    return 9999;
  }
  // 大会の長い記録をまだ使い始めていなければ、直近の順位の記録から数える
  if (u.juni_race.length <= 2) return 9999;
  final int i = u.juni_race[2].indexOf(0);
  return i < 0 ? 9999 : i + 1;
}

/// 対象になる名声の順位(1始まり。この順位より下なら、最下位まで対象)
const int kyoukaJuniUe = 4;

/// 正月駅伝の最後の優勝から、何年以上たっている大学が対象か
const int kyoukaBuri = 15;

/// 年度替わり(4月5日の処理。RetireNewの前)に、強化プロジェクトを始めるかを抽選する(保存もする)
/// 始めたらtrue
Future<bool> kyoukaProjectChuusen({
  required Ghensuu gh,
  required List<UnivData> sortedUnivData,
  Random? random,
}) async {
  final KantokuData? k = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
  if (k == null || kyoukaNashi(k)) return false;
  final int nendo = choukiNendo(gh);
  final KyoukaProject? mae = kyoukaProjectSaigo(k);
  // 実行中、またはこの年度に始めたものがあれば何もしない
  if (mae != null && nendo <= mae.owari) return false;
  // 一度も正月駅伝が開かれていなければ起きない
  final bool hirakareta = sortedUnivData.any(
    (u) =>
        u.taikaibetushutujoukaisuu.length > 2 &&
        u.taikaibetushutujoukaisuu[2] > 0,
  );
  if (!hirakareta) return false;
  final Random r = random ?? Random();
  if (r.nextInt(100) >= kyoukaKakuritsu(k)) return false;

  // 名声の順位(名声の合計が高い順、同じなら大学idの大きい順。RetireNew の名声順位と同じ並べ方)
  final List<UnivData> jun = List<UnivData>.of(sortedUnivData)
    ..sort(
      (a, b) =>
          (b.meisei_total * 100 + b.id).compareTo(a.meisei_total * 100 + a.id),
    );
  final bool jibunEraberu = kyoukaJibunEraberu(k);
  final List<UnivData> kouho = [];
  for (int i = kyoukaJuniUe - 1; i < jun.length; i++) {
    final UnivData u = jun[i];
    // 自分の大学は、設定で「選ばれる」にしたときだけ(選ばれやすさはほかの大学と同じ)
    if (u.id == gh.MYunivid && !jibunEraberu) continue;
    if (kyoukaYuushouKaraNen(u, nendo) < kyoukaBuri) continue;
    kouho.add(u);
  }
  if (kouho.isEmpty) return false;
  final UnivData u = kouho[r.nextInt(kouho.length)];
  final int owari = nendo + kyoukaKikanNen(k) - 1;

  // 理由の型(創立○周年は、期間中に区切りの周年が来るときだけ。前回と同じ型は避ける)
  final int maeKata = kyoukaMaeKata(k, u.id);
  final List<int> kata = [
    if (kyoukaShuunenNendo(u.id, nendo, owari) != null) kyoukaKataShuunen,
    kyoukaKataCrowd,
    kyoukaKataOB,
    kyoukaKataShouhei,
  ];
  final List<int> nokori = kata.where((x) => x != maeKata).toList();
  final List<int> erabu = nokori.isEmpty ? kata : nokori;
  final int k1 = erabu[r.nextInt(erabu.length)];

  _projectKaku(k, KyoukaProject(u.id, k1, nendo, owari));
  _maeKataKaku(k, u.id, k1);
  await k.save();
  // このあとのスカウトの画面の最初に、始動のお知らせのダイアログを一度だけ出す(2.0.2。kyouka_oshirase.dart)
  KyoukaShidouOshirase.dasu = true;
  return true;
}

// ---------------- スカウトへの効き目 ----------------

/// 新入生の振り分けの重み(大学idの位置。shozokuChuusenOmomi)のうち、強化プロジェクト中の大学の重みを、
/// 名声N位の大学の重み(重みの大きいほうからN番目)まで上げる
void kyoukaOmomiHosei(List<int> omomi, Ghensuu gh) {
  final KantokuData? k = Hive.box<KantokuData>('kantokuBox').get('KantokuData');
  if (k == null) return;
  final KyoukaProject? p = kyoukaProjectChuu(k, choukiNendo(gh));
  if (p == null || p.univid < 0 || p.univid >= omomi.length) return;
  final List<int> jun = List<int>.of(omomi)..sort((a, b) => b.compareTo(a));
  final int n = min(kyoukaOmomiJuni(k), jun.length);
  if (n <= 0) return;
  final int mokuhyou = jun[n - 1];
  if (omomi[p.univid] < mokuhyou) omomi[p.univid] = mokuhyou;
}

/// コンピュータスカウトの交渉の成功率と、全国一斉・地区めぐり(交渉)の争奪戦で使う名声のうち、
/// 強化プロジェクト中の大学の名声(名声N位の大学の名声まで上げたもの)。大学id → 名声(その大学だけ)
Map<int, int> kyoukaScoutMeiseiHosei(
  List<UnivData> univs,
  KantokuData? k,
  Ghensuu gh,
) => kyoukaScoutMeiseiHoseiNendo(univs, k, choukiNendo(gh));

/// kyoukaScoutMeiseiHosei の、年度[nendo]を渡す形(Ghensuuのない、プレイヤーの成功率の計算で使う)
Map<int, int> kyoukaScoutMeiseiHoseiNendo(
  List<UnivData> univs,
  KantokuData? k,
  int nendo,
) {
  if (k == null) return const {};
  final KyoukaProject? p = kyoukaProjectChuu(k, nendo);
  if (p == null) return const {};
  UnivData? u;
  for (final UnivData x in univs) {
    if (x.id == p.univid) u = x;
  }
  if (u == null) return const {};
  final List<int> jun = univs.map((x) => x.meisei_total).toList()
    ..sort((a, b) => b.compareTo(a));
  final int n = min(kyoukaOmomiJuni(k), jun.length);
  if (n <= 0) return const {};
  return {u.id: max(u.meisei_total, jun[n - 1])};
}
