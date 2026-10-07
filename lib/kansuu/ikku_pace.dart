import 'dart:math';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/TrialTime.dart';
import 'package:ekiden/kansuu/chousi_keiken_hosei.dart';
import 'package:ekiden/kansuu/time_date.dart';

// ------------------------------------------------------------
// 駅伝の1区の集団のペースの予想と結果(1.9.2)
//
// ■ 集団走の決まり(RaceCalc.dart と同じ)
// ・1区を走る大学の選手のうち、飛び出さなかった選手それぞれに「カリスマ+その日の勢い
//   (0〜幅の乱数)」を出し、一番高い選手(同じなら選手idの小さい選手)の、その日のタイムが
//   集団のペースになる(勢いの幅は集団走設定。下の「集団を引っ張る選手の決め方」)
// ・学連選抜の選手はペースを作らない(集団のペースの影響は受ける)
// ・ほかの選手は、自分の本来のタイムと比べて、集団のほうが遅いとタイム損、1%以内速いと少し得、
//   1〜3%速いと損得なし、3%より速いと大失速(2.5%悪化)
//
// ■ 予想(ikkuPaceYosou)
// ・各選手の見込みタイムは、濁しなしの試走タイム(経験補正込み)×調子補正
//   (本番の集団走の直前のタイムとの違いは、基本のタイムの±0.1%の揺れだけ)
// ・他大学の選手の飛び出しは見ない(画面で見せていないため)。自分の大学の選手は、
//   「スタート直後に飛び出す」を選んでいるときだけ飛び出す前提にする
// ・予想ペースは±0.5%ぼかす。ぼかし方は年と大会で決め、どの画面でも、
//   1区の計算のときの答え合わせでも同じ値にする
// ・見出し(スローペース〜ハイペース)は、集団のペースを、ペースを作る選手以外の
//   見込みタイムの真ん中と比べて決める
// ・集団を引っ張りそうな選手(本命)はカリスマが一番高い選手。本命とのカリスマの差が
//   勢いの幅より小さい選手を、最大2人まで「ほかに引っ張るかもしれない選手」(対抗)として出す
// ・出す画面: 直前順位予想・当日変更・目標順位の確認(当日変更のあと)・1区の指示の画面
//
// ■ 結果(KantokuData.yobiint4[60]〜[66]。1区の計算のときに RaceCalc.dart で保存し、
//   2区の指示の画面で出す)
//   [60] どの大会の結果か(年*100+大会番号*10+1。0ならなし)
//   [61] 集団を引っ張った選手のid+1(0ならなし)
//   [62] 集団のペース(1区のタイムに換算した秒×10)
//   [63] 実際の見出しの番号+1
//   [64] 1区の指示の画面と同じ予想の見出しの番号+1(予想できなかったときは0)
//   [65] その予想で集団を引っ張りそうだった選手のid+1
//   [66] 1区を走った選手の人数(集団のペースが遅くタイム損 + 少し得×100 + 損得なし×10000
//        + 大失速×1000000 + 飛び出し×100000000。学連選抜の選手も RaceCalc_gakuren.dart で足す)
// ------------------------------------------------------------

/// 1区の集団のペースの予想と結果を出す大会か(駅伝。11月駅伝予選は出さない)
bool ikkuPaceTaishou(int racebangou) =>
    (racebangou >= 0 && racebangou <= 2) || racebangou == 5;

// ------------------------------------------------------------
// 集団を引っ張る選手の決め方(1.9.2。駅伝の1区と11月駅伝予選の各組。RaceCalc.dart で使う)
// ・飛び出さなかった選手それぞれに「カリスマ+その日の勢い(0〜幅の乱数)」を出し、
//   一番高い選手が引っ張る。カリスマの差が幅以上あれば、必ずカリスマの高い選手が引っ張る
// ・幅は説明画面の設定タブの「集団走設定」で選ぶ(KantokuData.yobiint2[84])
//   0普通(初期値。幅10)・1なし(幅0。1.9.1までと同じく、いつもカリスマが一番高い選手)・
//   2小さい(幅5)・3大きい(幅20)
// ------------------------------------------------------------

/// 集団走設定(その日の勢いの大きさ)の保存先
const int shuudanIkioiIndex = 84;

/// 集団走設定の名前(番号は保存する値)
const List<String> shuudanIkioiMei = ['普通', 'なし', '小さい', '大きい'];

/// 集団走設定を画面に並べる順(なし・小さい・普通・大きい)
const List<int> shuudanIkioiNarabi = [1, 2, 0, 3];

// 集団走設定ごとの勢いの幅(カリスマに足す乱数の最大)
const List<int> _ikioiHaba = [10, 0, 5, 20];

/// 集団走設定の値として正しいか(QRコードの読み込みで使う)
bool shuudanIkioiAtaiTadashii(int v) => v >= 0 && v < _ikioiHaba.length;

/// 今の集団走設定(保存されていない・範囲外なら0=普通)
int shuudanIkioiSettei(KantokuData kantoku) {
  if (kantoku.yobiint2.length <= shuudanIkioiIndex) return 0;
  final int v = kantoku.yobiint2[shuudanIkioiIndex];
  return shuudanIkioiAtaiTadashii(v) ? v : 0;
}

/// 今の集団走設定の勢いの幅
int shuudanIkioiHaba(KantokuData kantoku) =>
    _ikioiHaba[shuudanIkioiSettei(kantoku)];

/// 集団走設定を保存する
Future<void> shuudanIkioiHozon(KantokuData kantoku, int v) async {
  if (kantoku.yobiint2.length <= shuudanIkioiIndex) return;
  if (!shuudanIkioiAtaiTadashii(v)) return;
  kantoku.yobiint2[shuudanIkioiIndex] = v;
  await kantoku.save();
}

/// 集団を引っ張る選手を決める点(カリスマ+その日の勢い)。幅が0なら乱数を使わない
double shuudanHipparuTen(int karisuma, int haba, Random random) {
  if (haba <= 0) return karisuma.toDouble();
  return karisuma + random.nextDouble() * haba;
}

/// ペースの見出し(番号は ikkuPaceMidashi の戻り値)
const List<String> ikkuPaceMidashiMoji = [
  'スローペース',
  'ややスロー',
  '平均的なペース',
  'ややハイ',
  'ハイペース',
];

// 見出しの境目(集団のペースが、ほかの選手の見込みタイムの真ん中より何割速いか遅いか)
const double _sakaiChiisai = 0.005; // これより差が小さければ平均的なペース
const double _sakaiOokii = 0.015; // これ以上ならスローペース・ハイペース

// 予想ペースのぼかしの幅(±0.5%。試走タイムの濁しと同じ幅)
const double _bokashiHaba = 0.005;

/// 集団のペース[pace]と、ほかの選手の見込みタイムの真ん中[mannaka]から、見出しの番号を出す
int ikkuPaceMidashi(double pace, double mannaka) {
  if (mannaka <= 0.0) return 2;
  final double r = pace / mannaka - 1.0; // 正なら集団のペースのほうが遅い
  if (r >= _sakaiOokii) return 0;
  if (r >= _sakaiChiisai) return 1;
  if (r > -_sakaiChiisai) return 2;
  if (r > -_sakaiOokii) return 3;
  return 4;
}

/// 値の真ん中(偶数個なら真ん中の2つの平均。空なら0)
double ikkuMannaka(List<double> atai) {
  if (atai.isEmpty) return 0.0;
  final List<double> narabi = List<double>.from(atai)..sort();
  final int n = narabi.length;
  return n.isOdd
      ? narabi[n ~/ 2]
      : (narabi[n ~/ 2 - 1] + narabi[n ~/ 2]) / 2.0;
}

/// 予想ペースのぼかしの倍率(年と大会で決まる)
/// 画面を開くたびに変わらず、1区の計算のときの答え合わせでも同じ値になるよう、
/// 乱数ではなく式で出す(掛け算が2の53乗を超えない式なので、Web版でも同じ値になる)
double ikkuPaceBokashiBairitsu(int year, int racebangou) {
  const int m = 2147483647;
  int x = (year * 131 + racebangou * 17 + 7) % m;
  if (x <= 0) x = 1;
  for (int i = 0; i < 5; i++) {
    x = (x * 48271) % m;
  }
  final double u = x / m; // 0〜1
  return 1.0 + (u * 2.0 - 1.0) * _bokashiHaba;
}

/// 集団のペースとの相性(RaceCalc.dart の集団走の補正の分け方と同じ)
enum IkkuAishou {
  /// 集団を引っ張る(集団のペースによる損得なし)
  hipparu,

  /// 集団のペースが遅い(タイム損)
  osokuSon,

  /// 集団のペースが少し速い(少しタイム得)
  sukoshiToku,

  /// 集団のペースが速めだが付いていける(損得なし)
  sonTokuNashi,

  /// 集団のペースが速すぎる(大失速)
  daiShissoku,

  /// スタート直後に飛び出す(集団に入らない)
  tobidashi,
}

/// 自分の本来のタイム[jibun]と集団のペース[pace]から相性を出す(RaceCalc.dart と同じ境目)
IkkuAishou ikkuAishou(double jibun, double pace) {
  if (jibun < pace) return IkkuAishou.osokuSon;
  if (jibun == pace) return IkkuAishou.sonTokuNashi;
  if (pace * 1.01 > jibun) return IkkuAishou.sukoshiToku;
  if (pace * 1.03 > jibun) return IkkuAishou.sonTokuNashi;
  return IkkuAishou.daiShissoku;
}

/// 予想の画面で出す相性の文
String ikkuAishouYosouMoji(IkkuAishou a) {
  switch (a) {
    case IkkuAishou.hipparu:
      return '集団を引っ張る見込み(集団のペースによる損得はなし)';
    case IkkuAishou.osokuSon:
      return '集団のペースが遅く、タイム損の見込み';
    case IkkuAishou.sukoshiToku:
      return '集団のペースが少し速く、少しタイム得の見込み';
    case IkkuAishou.sonTokuNashi:
      return '集団のペースが速めだが、大失速はしない見込み(損得なし)';
    case IkkuAishou.daiShissoku:
      return '集団のペースが速すぎて、大失速のおそれ';
    case IkkuAishou.tobidashi:
      return 'スタート直後に飛び出すので、集団のペースの影響を受けない';
  }
}

/// 結果の人数の並びの番号(集団を引っ張った選手は数えないのでnull)
int? ikkuKazuBangou(IkkuAishou a) {
  switch (a) {
    case IkkuAishou.osokuSon:
      return 0;
    case IkkuAishou.sukoshiToku:
      return 1;
    case IkkuAishou.sonTokuNashi:
      return 2;
    case IkkuAishou.daiShissoku:
      return 3;
    case IkkuAishou.tobidashi:
      return 4;
    case IkkuAishou.hipparu:
      return null;
  }
}

/// 結果の人数の種類の数(遅くて損・少し得・損得なし・大失速・飛び出し)
const int ikkuKazuShuruisuu = 5;

/// 1区のタイム[time]を「1時間02分40秒」(1時間未満は「15分20秒」)の形にする
String ikkuTimeMoji(double time) {
  return time >= 3600.0
      ? TimeDate.timeToJikanFunByouString(time)
      : TimeDate.timeToFunByouString(time);
}

/// 「1区(21.3km)を1時間02分40秒前後(1km 2分56秒)」の形(「前後」は[atoMoji]で付ける)
String ikkuPaceMoji(
  Ghensuu gh,
  int racebangou,
  double time, {
  String atoMoji = '',
}) {
  double kyori = 0.0;
  if (racebangou < gh.kyori_taikai_kukangoto.length &&
      gh.kyori_taikai_kukangoto[racebangou].isNotEmpty) {
    kyori = gh.kyori_taikai_kukangoto[racebangou][0];
  }
  if (kyori <= 0.0) return '1区を${ikkuTimeMoji(time)}$atoMoji';
  final String km = (kyori / 1000.0).toStringAsFixed(1);
  final String kmPace = TimeDate.timeToFunByouString(time / (kyori / 1000.0));
  return '1区(${km}km)を${ikkuTimeMoji(time)}$atoMoji(1km $kmPace)';
}

/// 選手が1区の区間エントリーに入っているか
bool _ikkuEntry(SenshuData s, int racebangou) {
  if (racebangou >= s.entrykukan_race.length) return false;
  final int g = s.gakunen - 1;
  if (g < 0 || g >= s.entrykukan_race[racebangou].length) return false;
  return s.entrykukan_race[racebangou][g] == 0;
}

/// 選手が1区を走ったときの、集団走の補正の前の見込みタイム(秒)
/// 濁しなしの試走タイム(経験補正込み)に、[chousiIreru]なら調子補正を掛ける。
/// 学連選抜の選手は、元の選手のデータ([senshuId]は同じ)で出して、学連選抜の選手の調子[chousi]を使う
double ikkuMikomiTime({
  required int senshuId,
  required int chousi,
  required Ghensuu gh,
  required int racebangou,
  required List<SenshuData> sortedSenshu,
  required List<UnivData> sortedUniv,
  required KantokuData kantoku,
  bool chousiIreru = true,
}) {
  double t = trialTimeKeisan(
    senshuId,
    0,
    gh,
    sortedSenshu,
    sortedUniv,
    kantoku,
    nigosu: false,
    keikenHosei: true,
    racebangou: racebangou,
  );
  if (chousiIreru) t *= chousiHoseiBairitsuAtai(chousi, kantoku);
  return t;
}

/// 1区の集団のペースの予想
class IkkuPaceYosou {
  /// 集団を引っ張りそうな選手
  final SenshuData pacemaker;

  /// 予想ペース(1区のタイムに換算した秒。ぼかし込み)
  final double pace;

  /// 見出しの番号(ikkuPaceMidashiMoji)
  final int midashi;

  /// 1区を走る大学の選手の見込みタイム(選手id→秒。集団走の補正の前)
  final Map<int, double> mikomi;

  /// 飛び出す前提にした選手のid
  final Set<int> tobidasu;

  /// ほかに引っ張るかもしれない選手(その日の勢いで本命と入れ替わることがある選手。最大2人)
  final List<IkkuTaikou> taikou;

  const IkkuPaceYosou({
    required this.pacemaker,
    required this.pace,
    required this.midashi,
    required this.mikomi,
    required this.tobidasu,
    this.taikou = const [],
  });

  /// 大学の選手の相性
  IkkuAishou aishou(int senshuId) {
    if (tobidasu.contains(senshuId)) return IkkuAishou.tobidashi;
    if (senshuId == pacemaker.id) return IkkuAishou.hipparu;
    final double? t = mikomi[senshuId];
    if (t == null) return IkkuAishou.sonTokuNashi;
    return ikkuAishou(t, pace);
  }
}

/// 1区の集団のペースの予想(1区を走る選手がいないときなどはnull)
/// [sortedSenshu]・[sortedUniv] は id 順(並びの番号が id と同じ)
/// [chousiIreru] 調子を入れるか(直前順位予想は、このあと当日の調子を決めるので入れない)
/// [tobidasuSenshu] 飛び出す前提にする選手のid(自分の大学の選手で「スタート直後に飛び出す」を選んでいるとき)
/// [irekae] 1区の区間エントリーの選手のid→代わりに走らせる選手のid(当日変更の画面で選んでいる交代。1.9.2)
IkkuPaceYosou? ikkuPaceYosou({
  required Ghensuu gh,
  required int racebangou,
  required List<SenshuData> sortedSenshu,
  required List<UnivData> sortedUniv,
  required KantokuData kantoku,
  bool chousiIreru = true,
  Set<int> tobidasuSenshu = const {},
  Map<int, int> irekae = const {},
}) {
  if (!ikkuPaceTaishou(racebangou)) return null;

  // 1区を走る大学の選手(当日変更の画面で選んでいる交代を入れる)
  final List<SenshuData> ikku = [];
  for (int i = 0; i < sortedSenshu.length; i++) {
    final SenshuData s = sortedSenshu[i];
    if (s.id != i) continue; // 試走タイムの計算は、並びの番号と選手idが同じことが前提
    if (!_ikkuEntry(s, racebangou)) continue;
    final int? saki = irekae[s.id];
    if (saki != null && saki != s.id) {
      if (saki >= 0 &&
          saki < sortedSenshu.length &&
          sortedSenshu[saki].id == saki) {
        ikku.add(sortedSenshu[saki]);
      }
      continue;
    }
    ikku.add(s);
  }
  // 集団を引っ張る選手は、選手idの小さい順に見て決める(RaceCalc.dart と同じ)
  ikku.sort((a, b) => a.id.compareTo(b.id));

  final Map<int, double> mikomi = {};
  SenshuData? pacemaker;
  int maxKarisuma = -1;
  for (final SenshuData s in ikku) {
    mikomi[s.id] = ikkuMikomiTime(
      senshuId: s.id,
      chousi: s.chousi,
      gh: gh,
      racebangou: racebangou,
      sortedSenshu: sortedSenshu,
      sortedUniv: sortedUniv,
      kantoku: kantoku,
      chousiIreru: chousiIreru,
    );
    // 集団を引っ張りそうな選手(本命。その日の勢いを入れないときに引っ張る、カリスマが
    // 一番高い選手。同じなら選手idの小さい選手。RaceCalc.dart で勢いが「なし」のときと同じ)
    if (tobidasuSenshu.contains(s.id)) continue;
    if (s.karisuma > maxKarisuma) {
      maxKarisuma = s.karisuma;
      pacemaker = s;
    }
  }
  final SenshuData? pm = pacemaker;
  if (pm == null) return null;

  final double bokashi = ikkuPaceBokashiBairitsu(gh.year, racebangou);
  // [hipparu]が引っ張ったときの予想(ペースと見出し)
  IkkuTaikou hipparuToki(SenshuData hipparu) {
    final double p = mikomi[hipparu.id]! * bokashi;
    final List<double> hoka = [
      for (final MapEntry<int, double> e in mikomi.entries)
        if (e.key != hipparu.id && !tobidasuSenshu.contains(e.key)) e.value,
    ];
    return IkkuTaikou(
      senshu: hipparu,
      pace: p,
      midashi: ikkuPaceMidashi(p, ikkuMannaka(hoka)),
    );
  }

  final IkkuTaikou honmei = hipparuToki(pm);

  // ほかに引っ張るかもしれない選手(本命とのカリスマの差が勢いの幅より小さい選手。
  // カリスマの高い順に最大2人。勢いが「なし」ならいない)
  final int haba = shuudanIkioiHaba(kantoku);
  final List<SenshuData> taikouKouho = [
    for (final SenshuData s in ikku)
      if (s.id != pm.id &&
          !tobidasuSenshu.contains(s.id) &&
          pm.karisuma - s.karisuma < haba)
        s,
  ];
  taikouKouho.sort((a, b) {
    final int c = b.karisuma.compareTo(a.karisuma);
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  final List<IkkuTaikou> taikou = [
    for (final SenshuData s in taikouKouho.take(2)) hipparuToki(s),
  ];

  return IkkuPaceYosou(
    pacemaker: pm,
    pace: honmei.pace,
    midashi: honmei.midashi,
    mikomi: mikomi,
    tobidasu: tobidasuSenshu,
    taikou: taikou,
  );
}

/// 選手が集団を引っ張ったときの予想(ほかに引っ張るかもしれない選手(対抗)と、本命の計算に使う)
class IkkuTaikou {
  final SenshuData senshu;

  /// その選手が引っ張ったときの予想ペース(ぼかし込み)
  final double pace;

  /// その選手が引っ張ったときの見出しの番号
  final int midashi;

  const IkkuTaikou({
    required this.senshu,
    required this.pace,
    required this.midashi,
  });
}

/// 自分の大学の1区の選手のうち、「スタート直後に飛び出す」の指示が付いている選手のid
/// (1区の計算のときの答え合わせ用。画面では選んでいる指示から決める)
Set<int> ikkuJibunTobidasuSenshu(
  int myUnivId,
  int racebangou,
  List<SenshuData> sortedSenshu,
) {
  return {
    for (final SenshuData s in sortedSenshu)
      if (s.univid == myUnivId && _ikkuEntry(s, racebangou) && s.sijiflag == 1)
        s.id,
  };
}

/// 他大学の1区の当日変更(「○○(外れた選手→入った選手)」の並び)
List<String> ikkuToujitsuHenkouMoji({
  required Ghensuu gh,
  required int racebangou,
  required List<SenshuData> sortedSenshu,
  required List<UnivData> sortedUniv,
}) {
  final List<String> kekka = [];
  for (final UnivData univ in sortedUniv) {
    if (univ.id == gh.MYunivid) continue;
    SenshuData? deta; // 当日変更で1区から外れた選手(区間エントリーが-(100+0))
    SenshuData? haitta; // 1区を走る選手
    for (final SenshuData s in sortedSenshu) {
      if (s.univid != univ.id) continue;
      if (racebangou >= s.entrykukan_race.length) continue;
      final int g = s.gakunen - 1;
      if (g < 0 || g >= s.entrykukan_race[racebangou].length) continue;
      final int entry = s.entrykukan_race[racebangou][g];
      if (entry == -100) deta = s;
      if (entry == 0) haitta = s;
    }
    if (deta != null && haitta != null) {
      kekka.add('${univ.name}(${deta.name}→${haitta.name})');
    }
  }
  return kekka;
}

// ------------------------------------------------------------
// 結果の保存と読み込み
// ------------------------------------------------------------

const int _kekkaIndex = 60; // KantokuData.yobiint4[60]〜[66]
const int _kekkaSuu = 7;

/// どの大会の結果かを表す値(0は「なし」に使うので、必ず1以上になる形)
int ikkuPaceKekkaCode(int year, int racebangou) =>
    year * 100 + racebangou * 10 + 1;

/// 1区の結果を保存する(RaceCalc.dart の集団走の補正のあとで呼ぶ。保存(save)は呼ぶ側で行う)
/// [kazu] は ikkuKazuBangou の並び(大学の選手の分)
void ikkuPaceKekkaHozon(
  KantokuData kantoku, {
  required int year,
  required int racebangou,
  required int? pacemakerId,
  required double pace,
  required double mannaka,
  required List<int> kazu,
  required IkkuPaceYosou? yosou,
}) {
  if (kantoku.yobiint4.length < _kekkaIndex + _kekkaSuu) return;
  int kazuAtai = 0;
  int keta = 1;
  for (int i = 0; i < ikkuKazuShuruisuu; i++) {
    final int n = i < kazu.length ? kazu[i].clamp(0, 99).toInt() : 0;
    kazuAtai += n * keta;
    keta *= 100;
  }
  kantoku.yobiint4[_kekkaIndex] = ikkuPaceKekkaCode(year, racebangou);
  kantoku.yobiint4[_kekkaIndex + 1] = pacemakerId == null ? 0 : pacemakerId + 1;
  kantoku.yobiint4[_kekkaIndex + 2] = (pace * 10.0).round();
  kantoku.yobiint4[_kekkaIndex + 3] = ikkuPaceMidashi(pace, mannaka) + 1;
  kantoku.yobiint4[_kekkaIndex + 4] = yosou == null ? 0 : yosou.midashi + 1;
  kantoku.yobiint4[_kekkaIndex + 5] = yosou == null
      ? 0
      : yosou.pacemaker.id + 1;
  kantoku.yobiint4[_kekkaIndex + 6] = kazuAtai;
}

/// 結果の人数に1人足す(学連選抜の選手の分。RaceCalc_gakuren.dart から呼ぶ。保存は呼ぶ側で行う)
/// 同じ大会の結果が保存されていないときは何もしない
void ikkuPaceKekkaKazuTasu(
  KantokuData kantoku,
  int year,
  int racebangou,
  IkkuAishou a,
) {
  if (kantoku.yobiint4.length < _kekkaIndex + _kekkaSuu) return;
  if (kantoku.yobiint4[_kekkaIndex] != ikkuPaceKekkaCode(year, racebangou)) {
    return;
  }
  final int? bangou = ikkuKazuBangou(a);
  if (bangou == null) return;
  int keta = 1;
  for (int i = 0; i < bangou; i++) {
    keta *= 100;
  }
  final int ima = (kantoku.yobiint4[_kekkaIndex + 6] ~/ keta) % 100;
  if (ima >= 99) return;
  kantoku.yobiint4[_kekkaIndex + 6] += keta;
}

/// 保存した1区の結果
class IkkuPaceKekka {
  /// 集団を引っ張った選手のid(いなければnull)
  final int? pacemakerId;

  /// 集団のペース(1区のタイムに換算した秒)
  final double pace;

  /// 実際の見出しの番号
  final int midashi;

  /// 1区の指示の画面と同じ予想の見出しの番号(なければnull)
  final int? yosouMidashi;

  /// その予想で集団を引っ張りそうだった選手のid(なければnull)
  final int? yosouPacemakerId;

  /// 人数(ikkuKazuBangou の並び)
  final List<int> kazu;

  const IkkuPaceKekka({
    required this.pacemakerId,
    required this.pace,
    required this.midashi,
    required this.yosouMidashi,
    required this.yosouPacemakerId,
    required this.kazu,
  });
}

/// 表示中の大会の1区の結果を読む(保存されていないときや、別の大会の結果のときはnull)
IkkuPaceKekka? ikkuPaceKekkaYomu(KantokuData kantoku, Ghensuu gh) {
  final int race = gh.hyojiracebangou;
  if (!ikkuPaceTaishou(race)) return null;
  if (kantoku.yobiint4.length < _kekkaIndex + _kekkaSuu) return null;
  final List<int> y = kantoku.yobiint4;
  if (y[_kekkaIndex] != ikkuPaceKekkaCode(gh.year, race)) return null;
  final int midashi = y[_kekkaIndex + 3] - 1;
  if (midashi < 0 || midashi >= ikkuPaceMidashiMoji.length) return null;
  final int yosou = y[_kekkaIndex + 4] - 1;
  final List<int> kazu = [];
  int atai = y[_kekkaIndex + 6];
  for (int i = 0; i < ikkuKazuShuruisuu; i++) {
    kazu.add(atai % 100);
    atai ~/= 100;
  }
  return IkkuPaceKekka(
    pacemakerId: y[_kekkaIndex + 1] > 0 ? y[_kekkaIndex + 1] - 1 : null,
    pace: y[_kekkaIndex + 2] / 10.0,
    midashi: midashi,
    yosouMidashi: (yosou >= 0 && yosou < ikkuPaceMidashiMoji.length)
        ? yosou
        : null,
    yosouPacemakerId: y[_kekkaIndex + 5] > 0 ? y[_kekkaIndex + 5] - 1 : null,
    kazu: kazu,
  );
}

/// レースの説明文から、集団走と飛び出しの行だけを取り出す(結果の枠で、選手ごとの結果に使う)
List<String> ikkuSetsumeiGyou(String racesetumei) {
  return racesetumei
      .split('\n')
      .where((g) => g.contains('集団のペース') || g.contains('飛び出し'))
      .toList();
}
