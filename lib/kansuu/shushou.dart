import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/taikai_chouki.dart' show choukiNendo;
import 'package:ekiden/kansuu/mokuhyou_hosei.dart' show HoseiTsuyosa;

// ------------------------------------------------------------
// 主将(2.0.1)
//
// ・どの大学にも、3年生か4年生の中から1人、主将がいる(学連選抜にはいない)
// ・主将の特典: 駅伝の2区以降で、指示なしで走るとき、目標順位による補正
//   (下回ったときの前半突っ込みの悪化と、上回ったときのほっと一息)がかからない(RaceCalc.dart)。
//   前半突っ込み・前半抑えの指示を出したときは、ほかの選手と同じく指示の成否による補正がかかる。
//   学連選抜の選手として走るときは特典なし(RaceCalc_gakuren.dart は変えていない)
// ・主将の特典は、設定(「目標順位・指示の補正設定」の画面)でなしにできる。なしでも主将は決まる
// ・年度の初め(4月の年度替わりの処理。main.dart のモード2000)に、全大学の主将を決める
//   ・前の年度の主将が、続けて同じ大学の4年生にいれば(3年生で主将だった選手)、続けて主将にする
//   ・それ以外は自動で決める(下の shushouJidou)。あなたの大学も、最初は同じ決め方
//   ・この版より前のセーブデータや新しいゲームは、起動時・セーブデータの読み込み時・新しいゲームを
//     始めたとき・駅伝の区間エントリーのときに、まだ決めていなければ決める(shushouJunbi)
// ・自動の決め方(コンピュータの大学):
//   3・4年生のうち、留学生を除き、コンピュータの大学が指示を出さない選手
//   (駅伝男84以下=前半突っ込み・飛び出しをしない、平常心79以下=前半抑えをしない。
//    EntryCalc.dart・ToujituHenkou_com.dart の指示の決め方と合わせる)の中で、
//   ロード1万の自己ベストが一番速い選手。記録がなければハーフ→1万→5000m→入学時の5000mの順で比べる
//   (前の種目の記録がある選手が上)。条件に合う選手がいなければ、留学生を除く3・4年生、
//   それもいなければ3・4年生全員から同じ順で選ぶ
// ・あなたの大学は、選手画面で3・4年生を主将にできる(9月下旬まで。10月からは年度の終わりまで代えられない)
//   4月上旬の最新画面の「新入生が入りました！」の下に、決まった主将を出す(shushouKetteiBun)
// ・主将の特典があるとき(目標順位による補正が両方0%のときは除く)は、コンピュータの区間配置で主将を
//   特典が生きない区間(1区と、正月駅伝の6区。shushouSakeruKukan)に置かない
//   (kukan_haichi.dart・EntryCalc.dart の最適解区間配置・ToujituHenkou_com.dart・
//   1区のペース予想 ikku_pace.dart)。あなたの大学の区間エントリーの初期案も同じ。
//   ほかに手がないとき(選手が足りない、体調不良の交代で補欠が主将しかいない)はその区間に入ることがある
//   (入っても、特典が生きないだけで、おかしな状態ではない)
//   正月駅伝の6区は、往路のゴールで目標順位の判定を「ちょうど」に戻すので(RaceCalc.dart)、
//   目標順位による補正がかからない(6区も置かないようにしたのは2.0.1の開発中)
//
// KantokuData.yobiint4 の使用番号
//   [67]〜[72] 大学ごとの主将の選手id+1(1大学3桁、1つの番号に5大学。[67]に大学0〜4・[68]に大学5〜9…、
//              下の位から大学id%5番目の3桁。0は未定)
//   [73] 主将を決めた年度(0は未定。今の年度と違えば、決め直す)
//   [74] 主将の特典(0=あり(初期値)・1=なし)
// ------------------------------------------------------------

/// KantokuData.yobiint4 の使用番号: 大学ごとの主将の選手id+1([67]〜[72])
const int shushouIdIndex0 = 67;

/// 1つの番号に入れる大学の数
const int _shushouDaigakuSuu = 5;

/// KantokuData.yobiint4 の使用番号: 主将を決めた年度
const int shushouNendoIndex = 73;

/// KantokuData.yobiint4 の使用番号: 主将の特典(0=あり(初期値)・1=なし)
const int shushouTokutenIndex = 74;

/// コンピュータの大学が前半突っ込み・飛び出しの指示を出さない駅伝男の上限(85以上で出す)
const int shushouKonjouJougen = 84;

/// コンピュータの大学が前半抑えの指示を出さない平常心の上限(80以上で出す)
const int shushouHeijousinJougen = 79;

/// 主将を1区(と正月駅伝の6区)に置かないために、区間配置の計算で主将のその区間の見積もりに足す秒
/// (大きな値だが、無限大にはしない。ほかに手がないときはその区間に入れられるように)
const double shushouIkkuFuri = 1.0e6;

/// 補正の説明(SenshuData.string_racesetumei)に書く、主将なので目標順位の補正がかからなかったことの行の頭
/// (「目標順位下回って」で始めない。記事が焦りと読み違えないように)
const String shushouHoseiNashiMidashi = '主将のため目標順位の補正なし';

/// 画面の指示の結果の欄に出す文
const String shushouHoseiNashiKekka = '主将のため、目標順位による補正なし';

/// 主将の印(選手名の学年のかっこの中に足す)
const String shushouShirushiMoji = '・主将';

/// 今のゲームの変数(まだなければnull)
Ghensuu? _ghensuuIma() {
  final Box<Ghensuu> box = Hive.box<Ghensuu>('ghensuuBox');
  return box.isEmpty ? null : box.getAt(0);
}

int _ketaBai(int n) {
  int v = 1;
  for (int i = 0; i < n; i++) {
    v *= 1000;
  }
  return v;
}

/// 保存してある大学[univid]の主将の選手id(未定ならnull)
int? _hozonId(KantokuData k, int univid) {
  if (univid < 0) return null;
  final int b = shushouIdIndex0 + univid ~/ _shushouDaigakuSuu;
  if (k.yobiint4.length <= b) return null;
  final int v =
      (k.yobiint4[b] ~/ _ketaBai(univid % _shushouDaigakuSuu)) % 1000;
  return v == 0 ? null : v - 1;
}

/// 大学[univid]の主将の選手idを保存する(nullなら未定。保存(save)は呼び出し側で行う)
void _hozonIdIreru(KantokuData k, int univid, int? id) {
  if (univid < 0) return;
  final int b = shushouIdIndex0 + univid ~/ _shushouDaigakuSuu;
  if (k.yobiint4.length <= b) return;
  final int bai = _ketaBai(univid % _shushouDaigakuSuu);
  final int mae = (k.yobiint4[b] ~/ bai) % 1000;
  int atarashii = id == null ? 0 : id + 1;
  if (atarashii < 0 || atarashii > 999) atarashii = 0;
  k.yobiint4[b] = k.yobiint4[b] - mae * bai + atarashii * bai;
}

/// 年度[nendo]の主将を決めてあるか
bool shushouKimatteiru(KantokuData k, int nendo) =>
    k.yobiint4.length > shushouNendoIndex &&
    k.yobiint4[shushouNendoIndex] == nendo;

/// 主将の特典があるか(設定。監督のデータが読めなければ初期値の「あり」)
bool shushouTokutenAri(KantokuData? k) =>
    k == null ||
    k.yobiint4.length <= shushouTokutenIndex ||
    k.yobiint4[shushouTokutenIndex] == 0;

/// 主将の特典の設定を変える(保存(save)は呼び出し側で行う)
void shushouTokutenIreru(KantokuData k, bool ari) {
  if (k.yobiint4.length <= shushouTokutenIndex) return;
  k.yobiint4[shushouTokutenIndex] = ari ? 0 : 1;
}

/// 主将の特典の設定の値として正しいか(QRコードの読み込みで使う)
bool shushouTokutenAtaiTadashii(int v) => v == 0 || v == 1;

/// 主将の特典の設定の値(QRコードで使う)
int shushouTokutenAtai(KantokuData k) =>
    k.yobiint4.length > shushouTokutenIndex
    ? k.yobiint4[shushouTokutenIndex]
    : 0;

/// 主将になれる選手か(3年生か4年生)
bool shushouNareru(SenshuData s) => s.gakunen == 3 || s.gakunen == 4;

/// 自動で選ぶときの「一番走りそう」の物差し(小さいほど上)
/// ロード1万の自己ベスト → ハーフ → 1万 → 5000m → 入学時の5000m の順に、記録のある種目で比べる
(int, double) _hashirisouJun(SenshuData s) {
  const List<int> shumoku = [6, 2, 1, 0]; // ロード1万・ハーフ・1万・5000m
  for (int i = 0; i < shumoku.length; i++) {
    final int b = shumoku[i];
    if (s.time_bestkiroku.length > b) {
      final double t = s.time_bestkiroku[b];
      if (t > 0 && t < TEISUU.DEFAULTTIME) return (i, t);
    }
  }
  return (shumoku.length, s.kiroku_nyuugakuji_5000);
}

int _hashirisouHikaku(SenshuData a, SenshuData b) {
  final (int, double) x = _hashirisouJun(a);
  final (int, double) y = _hashirisouJun(b);
  if (x.$1 != y.$1) return x.$1.compareTo(y.$1);
  final int c = x.$2.compareTo(y.$2);
  return c != 0 ? c : a.id.compareTo(b.id);
}

/// 大学の選手[team]から、自動で主将を選ぶ(3・4年生がいなければnull)
SenshuData? shushouJidou(Iterable<SenshuData> team) {
  final List<SenshuData> jouge = team.where(shushouNareru).toList();
  if (jouge.isEmpty) return null;
  List<SenshuData> kouho = jouge
      .where(
        (s) =>
            s.hirou != 1 &&
            s.konjou <= shushouKonjouJougen &&
            s.heijousin <= shushouHeijousinJougen,
      )
      .toList();
  if (kouho.isEmpty) kouho = jouge.where((s) => s.hirou != 1).toList();
  if (kouho.isEmpty) kouho = jouge;
  kouho.sort(_hashirisouHikaku);
  return kouho.first;
}

/// 大学ごとの主将の選手id(大学id → 選手id)
/// 今の年度の主将を決めてあれば、保存してある選手(その大学の3・4年生でなくなっていれば自動)。
/// まだ決めていなければ、自動で選んだ選手(保存はしない)
Map<int, int> shushouIchiran(
  KantokuData? k,
  Ghensuu gh,
  Iterable<SenshuData> senshu,
) {
  final bool kimatta = k != null && shushouKimatteiru(k, choukiNendo(gh));
  final Map<int, SenshuData> byId = {};
  final Map<int, List<SenshuData>> goto = {};
  for (final SenshuData s in senshu) {
    byId[s.id] = s;
    (goto[s.univid] ??= []).add(s);
  }
  final Map<int, int> kekka = {};
  for (final MapEntry<int, List<SenshuData>> e in goto.entries) {
    final int u = e.key;
    if (u < 0 || u >= TEISUU.UNIVSUU) continue;
    SenshuData? c;
    if (k != null && kimatta) {
      final int? id = _hozonId(k, u);
      final SenshuData? s = id == null ? null : byId[id];
      if (s != null && s.univid == u && shushouNareru(s)) c = s;
    }
    c ??= shushouJidou(e.value);
    if (c != null) kekka[u] = c.id;
  }
  return kekka;
}

/// 大学[univid]の主将の選手id(いなければnull)
int? shushouIdUniv(
  KantokuData? k,
  Ghensuu gh,
  Iterable<SenshuData> senshu,
  int univid,
) {
  return shushouIchiran(k, gh, senshu.where((s) => s.univid == univid))[univid];
}

/// 今のデータで、大学ごとの主将の選手id(画面やテキストで使う。データが読めなければ空)
Map<int, int> shushouIchiranIma() {
  final Ghensuu? gh = _ghensuuIma();
  if (gh == null) return {};
  final KantokuData? k = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  return shushouIchiran(k, gh, Hive.box<SenshuData>('senshuBox').values);
}

/// 今のデータで、選手[s]が主将か
bool shushouKaIma(SenshuData s) {
  final Ghensuu? gh = _ghensuuIma();
  if (gh == null || !shushouNareru(s)) return false;
  final KantokuData? k = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  return shushouIdUniv(
        k,
        gh,
        Hive.box<SenshuData>('senshuBox').values,
        s.univid,
      ) ==
      s.id;
}

/// 選手名の学年のかっこの中に足す印(主将なら「・主将」、そうでなければ空)
String shushouShirushi(SenshuData s) =>
    shushouKaIma(s) ? shushouShirushiMoji : '';

/// 主将の特典がかかる選手id(特典なしの設定なら空。RaceCalc.dart で使う)
Set<int> shushouTokutenIds(
  KantokuData k,
  Ghensuu gh,
  Iterable<SenshuData> senshu,
) {
  if (!shushouTokutenAri(k)) return {};
  return shushouIchiran(k, gh, senshu).values.toSet();
}

/// 今のデータで、選手[s]に主将の特典がかかるか(指示ごとの損得予測・指示の画面で使う)
bool shushouTokutenKikuIma(SenshuData s) {
  final KantokuData? k = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  return shushouTokutenAri(k) && shushouKaIma(s);
}

/// 主将を置かない区間か(主将の特典が生きない区間。1区と、正月駅伝の6区)
/// [racebangou] 大会番号(2が正月駅伝)、[kukan] 区間(0が1区)
bool shushouSakeruKukan(int racebangou, int kukan) =>
    kukan == 0 || (racebangou == 2 && kukan == 5);

/// 区間配置で1区(と正月駅伝の6区)に置かない主将の選手id
/// (主将の特典がないときと、目標順位による補正が両方0%で特典が意味を持たないときは空)
Set<int> shushouIkkuSakeruIds(
  KantokuData k,
  Ghensuu gh,
  Iterable<SenshuData> senshu,
) {
  if (!shushouTokutenAri(k)) return {};
  final HoseiTsuyosa t = HoseiTsuyosa.fromKantoku(k);
  if (t.shitamawari <= 0 && t.hitoiki <= 0) return {};
  return shushouIchiran(k, gh, senshu).values.toSet();
}

/// 1区(と正月駅伝の6区)の交代の候補[kouho]から主将を外す(主将をその区間に置かない)
/// [taichouFuryou] 体調不良の走者の交代なら、主将しか候補がいないときは主将を残す
/// (体調不良の選手を走らせるよりは良いので)
List<SenshuData> shushouIkkuNozoku(
  List<SenshuData> kouho,
  Set<int> shushouIds, {
  bool taichouFuryou = false,
}) {
  if (shushouIds.isEmpty) return kouho;
  final List<SenshuData> nokori = kouho
      .where((s) => !shushouIds.contains(s.id))
      .toList();
  if (nokori.isEmpty && taichouFuryou) return kouho;
  return nokori;
}

/// 補正の説明から、主将なので目標順位の補正がかからなかった選手か(走ったあとの画面とテキストで使う)
bool shushouHoseiNashiDatta(SenshuData s) =>
    s.string_racesetumei.contains(shushouHoseiNashiMidashi);

/// 主将を代えられる時期か(4月〜9月。10月からは年度の終わりまで代えられない)
bool shushouHenkouDekiru(Ghensuu gh) => gh.month >= 4 && gh.month <= 9;

/// 全大学の主将を決めて保存する(年度の初めと、まだ決めていないとき)
/// 前の年度の主将が、続けて同じ大学の4年生にいれば(3年生で主将だった選手)、続けて主将にする。
/// それ以外は自動で決める
Future<void> shushouKimeru({Ghensuu? gh}) async {
  final Ghensuu? g = gh ?? _ghensuuIma();
  final KantokuData? k = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (g == null || k == null || k.yobiint4.length <= shushouTokutenIndex) {
    return;
  }
  final int nendo = choukiNendo(g);
  final int mae = k.yobiint4[shushouNendoIndex];
  // 前の年度(か、年度替わりの処理の前に今の年度で決めていた)の主将を引き継げるか
  final bool hikitsugu = mae > 0 && (mae == nendo - 1 || mae == nendo);
  final Map<int, SenshuData> byId = {};
  final Map<int, List<SenshuData>> goto = {};
  for (final SenshuData s in Hive.box<SenshuData>('senshuBox').values) {
    byId[s.id] = s;
    (goto[s.univid] ??= []).add(s);
  }
  // 選手のデータがまだないとき(最初の起動など)は決めない
  if (byId.isEmpty) return;
  for (int u = 0; u < TEISUU.UNIVSUU; u++) {
    final List<SenshuData>? team = goto[u];
    SenshuData? c;
    if (team != null) {
      if (hikitsugu) {
        final int? id = _hozonId(k, u);
        final SenshuData? s = id == null ? null : byId[id];
        if (s != null && s.univid == u && s.gakunen == 4) c = s;
      }
      c ??= shushouJidou(team);
    }
    _hozonIdIreru(k, u, c?.id);
  }
  k.yobiint4[shushouNendoIndex] = nendo;
  await k.save();
}

/// 今の年度の主将をまだ決めていなければ決める
Future<void> shushouJunbi({Ghensuu? gh}) async {
  final Ghensuu? g = gh ?? _ghensuuIma();
  final KantokuData? k = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (g == null || k == null) return;
  // 年度替わりの処理の前(モード2000)は、学年がまだ前の年度のままなので決めない
  // (このあとの年度替わりの処理で決める)
  if (g.mode == 2000) return;
  if (shushouKimatteiru(k, choukiNendo(g))) return;
  await shushouKimeru(gh: g);
}

/// 4月上旬の最新画面に出す、あなたの大学の主将が決まったことの文(主将がいなければ空。mode0100_content.dart)
String shushouKetteiBun(KantokuData? k, Ghensuu gh) {
  final Iterable<SenshuData> senshu = Hive.box<SenshuData>('senshuBox').values;
  final int? id = shushouIdUniv(k, gh, senshu, gh.MYunivid);
  if (id == null) return '';
  for (final SenshuData s in senshu) {
    if (s.id == id) {
      return '主将は${s.name}(${s.gakunen}年)に決まりました。9月下旬までは、選手画面で代えられます。';
    }
  }
  return '';
}

/// あなたの大学の選手[s]を主将にする(代えられない時期や、3・4年生でなければfalse)
Future<bool> shushouNinmei(SenshuData s, Ghensuu gh) async {
  if (!shushouNareru(s) || !shushouHenkouDekiru(gh)) return false;
  if (s.univid != gh.MYunivid) return false;
  await shushouJunbi(gh: gh);
  final KantokuData? k = Hive.box<KantokuData>(
    'kantokuBox',
  ).get('KantokuData');
  if (k == null) return false;
  _hozonIdIreru(k, s.univid, s.id);
  await k.save();
  return true;
}
