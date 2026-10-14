import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/koukou.dart' show KoukouJouhou;

// ------------------------------------------------------------
// 監督の母校パイプ(2.0.1)
//
// 大学の監督(OB。KantokuData.rid[大学id])の出身校の新入生は、スカウトでその大学を選びやすくなる。
// 雰囲気作りが目的(現実でも、監督の母校から毎年のように選手が入る大学がある)。
// 監督が代わると母校も代わるので、監督の交代でスカウトの流れが変わる。
// 名門校から大学に来る新入生は毎年2人足らず(模擬計算。強豪校は1人足らず、ほかは0.3〜0.4人)なので、
// 効き目は、名門・強豪の出身の監督の大学にだけ少し出る程度
//
// ・効くのはコンピュータスカウトONのときだけ(OFFのときは、新入生の振り分けが出身校の決まる前なので効かない)。
//   プレイヤーの大学にも効く(監督の進言で、名門の出身のOBを監督にする楽しみ)
// ・効き目(その高校の新入生についてだけ。scout_com.dart):
//   ・争奪戦(声かけは最後の志望と同じ重み、全国一斉・交渉は名声の重み)・最後の志望・交渉の成功率で、
//     監督の大学を「名声N位並み」として扱う(もとの重みや名声のほうが大きければ、そのまま)
//   ・コンピュータの大学は、地区めぐり(声かけ)で今の地区に母校の後輩がいれば、要件を堅実(上位50%)まで
//     ゆるめて、優先して声をかける(ラウンドの結果の理由に「監督の母校の後輩」と出す)
//   ・変わり者(名声をあまり気にしない新入生)の争奪戦は、今まで通り等しい確率
//   ・地区めぐり(交渉)の成功率の下限には入れない(設定で選べない形なので)
// ・設定(説明画面の設定タブの「監督の母校パイプ設定」): なし・名声5位並み・名声3位並み・名声1位並み(初期値)
// ・画面: スカウトの画面の選手のカードに「○○大学の監督の母校」(高校の情報を表示しない設定のときと、
//   なし・OFFのときは出さない)、大学画面の監督の行の下に監督の出身校、高校名鑑の高校のページに
//   その高校出身の監督。4月5日の「期待のルーキー」(kiji_shinnyuusei.dart)に、監督の母校から入った新入生の段落
// ・1.9.5より前に卒業したOBには出身校がないので、起動時と読み込み時に、出身地と入学時の記録から
//   出身校だけを付ける(koukou.dart の koukouObFuyo。高校時代の実績は付けない)
// ・保存(KantokuData.yobiint3[84]): 強さのコード(0=名声1位並み(初期値)・1=なし・2=名声5位並み・3=名声3位並み)
// ------------------------------------------------------------

/// KantokuData.yobiint3 の使用番号: 監督の母校パイプの強さ
const int bokouPipeSetteiIndex = 84;

/// 強さの名前(コード0〜3。0が初期値)
const List<String> bokouPipeMei = ['名声1位並み', 'なし', '名声5位並み', '名声3位並み'];

/// 強さの、名声何位並みか(コードの順。0は効かない)
const List<int> _pipeJuni = [1, 0, 5, 3];

/// 強さのコードを画面に並べる順(なし・5位並み・3位並み・1位並み)
const List<int> bokouPipeNarabi = [1, 2, 3, 0];

/// 強さのコード: なし
const int bokouPipeNashiCode = 1;

int _setteiAtai(KantokuData k) =>
    k.yobiint3.length > bokouPipeSetteiIndex ? k.yobiint3[bokouPipeSetteiIndex] : 0;

/// 設定の値が正しいか(QRコードの読み込みで使う)
bool bokouPipeSetteiTadashii(int atai) => atai >= 0 && atai < _pipeJuni.length;

/// 強さのコード(正しくない値は0)
int bokouPipeCode(KantokuData k) {
  final int v = _setteiAtai(k);
  return bokouPipeSetteiTadashii(v) ? v : 0;
}

/// 設定を入れる(保存は呼び出し側で行う。QRコードの読み込みでも使う)
void bokouPipeSetteiIreru(KantokuData k, int code) {
  if (k.yobiint3.length <= bokouPipeSetteiIndex || !bokouPipeSetteiTadashii(code)) return;
  k.yobiint3[bokouPipeSetteiIndex] = code;
}

/// 監督の母校パイプを使わない設定か
bool bokouPipeNashi(KantokuData k) => bokouPipeCode(k) == bokouPipeNashiCode;

/// 監督の大学を、名声何位並みとして扱うか(0は使わない)
int bokouPipeJuni(KantokuData k) => _pipeJuni[bokouPipeCode(k)];

// ---------------- 監督と母校 ----------------

/// 今の監督1人(大学画面や高校名鑑で使う)
class BokouKantoku {
  /// 監督をしている大学
  final int univid;

  /// 出身校(高校の番号+1。0は分からない)
  final int koukou;

  /// 名前
  final String mei;

  /// 年齢
  final int nenrei;

  const BokouKantoku(this.univid, this.koukou, this.mei, this.nenrei);
}

/// 今の監督の一覧(大学idの順。監督のいない大学は入らない)。[nen] は今の年(年齢に使う)
List<BokouKantoku> bokouPipeKantokuIchiran(KantokuData k, int nen) {
  if (!Hive.isBoxOpen('retiredSenshuBox')) return const [];
  final Map<int, int> ridUniv = {}; // OBのid → 大学id
  for (int u = 0; u < TEISUU.UNIVSUU && u < k.rid.length; u++) {
    if (k.rid[u] > 0) ridUniv[k.rid[u]] = u;
  }
  if (ridUniv.isEmpty) return const [];
  final List<BokouKantoku> l = [];
  for (final Senshu_R_Data r in Hive.box<Senshu_R_Data>('retiredSenshuBox').values) {
    final int? u = ridUniv[r.id];
    if (u == null) continue;
    final int kou = r.hirou == 1 ? 0 : KoukouJouhou.yomu(r.samusataisei).koukou;
    l.add(BokouKantoku(u, kou, r.name, nen - r.sijiflag + 22));
  }
  l.sort((a, b) => a.univid.compareTo(b.univid));
  return l;
}

/// 大学ごとの監督の母校(大学id → 高校の番号+1。監督がいない大学と、母校が分からない大学は入らない)
Map<int, int> bokouPipeBokou(KantokuData k) {
  return {
    for (final BokouKantoku b in bokouPipeKantokuIchiran(k, 0))
      if (b.koukou > 0) b.univid: b.koukou,
  };
}

/// 新入生[s]の出身校(高校の番号+1。未設定と留学生は0)
int bokouPipeKoukou(SenshuData s) =>
    s.hirou == 1 ? 0 : KoukouJouhou.yomu(s.samusataisei).koukou;

/// 新入生[s]が監督の母校の後輩になる大学(大学idの順。なければ空)
List<int> bokouPipeUnivs(Map<int, int> bokou, SenshuData s) {
  final int kou = bokouPipeKoukou(s);
  if (kou <= 0) return const [];
  return [
    for (final MapEntry<int, int> e in bokou.entries)
      if (e.value == kou) e.key,
  ]..sort();
}

// ---------------- スカウトへの効き目 ----------------

/// スカウトの1回の計算で使う、監督の母校パイプ(scout_com.dart)
class BokouPipe {
  /// 大学id → 監督の母校(高校の番号+1)
  final Map<int, int> bokou;

  /// 監督の大学を、名声何位並みとして扱うか(0は効かない)
  final int juni;

  const BokouPipe(this.bokou, this.juni);

  /// 効かないもの
  static const BokouPipe nashi = BokouPipe({}, 0);

  /// 設定とOBのデータから作る(なしの設定のときや、母校の分かる監督がいないときは、効かないもの)
  static BokouPipe yomu(KantokuData? k) {
    if (k == null || bokouPipeNashi(k)) return nashi;
    final Map<int, int> m = bokouPipeBokou(k);
    if (m.isEmpty) return nashi;
    return BokouPipe(m, bokouPipeJuni(k));
  }

  /// 効かないか
  bool get kikanai => juni <= 0 || bokou.isEmpty;

  /// 新入生[s]が、大学[univid]の監督の母校の後輩か
  bool kouhai(int univid, SenshuData s) {
    if (kikanai) return false;
    final int? kou = bokou[univid];
    return kou != null && kou > 0 && kou == bokouPipeKoukou(s);
  }

  /// [narabi] の大きいほうから[juni]番目の値
  int _nBanme(List<int> narabi) {
    if (narabi.isEmpty) return 0;
    final List<int> jun = List<int>.of(narabi)..sort((a, b) => b.compareTo(a));
    return jun[min(juni, jun.length) - 1];
  }

  /// 争奪戦(声かけ)・最後の志望の重み([omomi] は大学idの位置の重み。shozokuChuusenOmomi)。
  /// 新入生[s]が大学[univid]の監督の母校の後輩なら、名声N位の大学の重みまで上げる
  int omomi(int univid, SenshuData s, List<int> omomi) {
    final int moto = (univid >= 0 && univid < omomi.length) ? omomi[univid] : 0;
    if (!kouhai(univid, s)) return moto;
    return max(moto, _nBanme(omomi));
  }

  /// 交渉の成功率と、争奪戦(全国一斉・交渉)で使う名声([moto] はもとの名声)。
  /// 新入生[s]が大学[univid]の監督の母校の後輩なら、名声N位の大学の名声まで上げる
  int meisei(int univid, SenshuData s, int moto, List<UnivData> univs) {
    if (!kouhai(univid, s)) return moto;
    return max(moto, _nBanme([for (final UnivData u in univs) u.meisei_total]));
  }
}
