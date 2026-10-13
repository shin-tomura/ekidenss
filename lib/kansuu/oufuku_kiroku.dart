import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/taikai_chouki.dart';

// ------------------------------------------------------------
// 正月駅伝の往路・復路の成績(2.0.0)
//
// 正月駅伝の往路(1〜5区)と復路(6〜10区)の、大学ごとの順位とタイムを、ほかの大会と同じ形で残す。
// ・置き場所は、もともと往路・復路のために取ってあった大会番号18(往路)・19(復路)の行
//   (UnivData の juni_race・time_race・taikaibetushutujoukaisuu・taikaibetusaikoujuni・
//   taikaibetujunibetukaisuu。constants.dart)。型も項目も変えない
// ・正月駅伝の区間数は10で変えられない(コース編集でも、コースのQRコードでも10のまま)ので、
//   往路は1〜5区、復路は6〜10区で決め打ちする
// ・復路のタイムは、ゴールの累計タイムから往路の累計タイムを引いたもの(復路は往路の差のままスタートする)
// ・順位は出場した大学の中で付ける(学連選抜はオープン参加なので入れない)
// ・正月駅伝の結果を記録するとき(KirokuKousin.dart)に一緒に記録する。往路優勝・復路優勝の
//   「○年ぶり」と連覇は、大会の長い記録(taikai_chouki.dart)で覚える
// ・2.0.0より前から遊んでいるデータは、記録を始める前の分がないので、記録を始めた年度
//   (choukiOufukuKaishi)を覚えておき、「初の往路優勝」「○度目」などと言い切らない
// ------------------------------------------------------------

/// 往路の区間数(往路は1〜5区)
const int ouroKukansuu = 5;

/// 正月駅伝の区間数(往路・復路に分けられるのは、この区間数のときだけ)
const int shougatsuKukansuu = 10;

/// 大学[u]の正月駅伝の往路の累計タイム(なければnull)
double? ouroTime(UnivData u) {
  if (u.time_taikai_total.length < ouroKukansuu) return null;
  final double t = u.time_taikai_total[ouroKukansuu - 1];
  if (t <= 0 || t >= TEISUU.DEFAULTTIME) return null;
  return t;
}

/// 大学[u]の正月駅伝の復路のタイム(ゴールの累計タイム−往路の累計タイム。なければnull)
double? fukuroTime(UnivData u, int kukansuu) {
  final double? o = ouroTime(u);
  if (o == null || kukansuu <= ouroKukansuu) return null;
  if (u.time_taikai_total.length < kukansuu) return null;
  final double t = u.time_taikai_total[kukansuu - 1];
  if (t <= 0 || t >= TEISUU.DEFAULTTIME) return null;
  return t - o;
}

/// 順位の記録をずらして、[0]を「出場なし」にする
void _zurasu(UnivData u, int race) {
  if (u.juni_race.length <= race || u.time_race.length <= race) return;
  final List<int> j = u.juni_race[race];
  final List<double> t = u.time_race[race];
  for (int i = j.length - 1; i > 0; i--) {
    j[i] = j[i - 1];
  }
  for (int i = t.length - 1; i > 0; i--) {
    t[i] = t[i - 1];
  }
  if (j.isNotEmpty) j[0] = TEISUU.DEFAULTJUNI;
  if (t.isNotEmpty) t[0] = TEISUU.DEFAULTTIME;
}

/// 大学[u]の大会[race]で、順位[juni](0が1位)・タイム[time]だったことを記録する
void _kaku(UnivData u, int race, int juni, double time) {
  if (u.juni_race.length <= race || u.juni_race[race].isEmpty) return;
  u.juni_race[race][0] = juni;
  if (u.time_race.length > race && u.time_race[race].isNotEmpty) {
    u.time_race[race][0] = time;
  }
  if (u.taikaibetushutujoukaisuu.length > race) {
    u.taikaibetushutujoukaisuu[race] += 1;
  }
  if (u.taikaibetusaikoujuni.length > race &&
      u.taikaibetusaikoujuni[race] > juni) {
    u.taikaibetusaikoujuni[race] = juni;
  }
  if (u.taikaibetujunibetukaisuu.length > race &&
      u.taikaibetujunibetukaisuu[race].length > juni) {
    u.taikaibetujunibetukaisuu[race][juni] += 1;
  }
}

/// 正月駅伝の結果を記録したあとに、往路・復路の成績を記録する(KirokuKousin.dart。保存もする)
Future<void> oufukuKirokuKousin(List<UnivData> univs, Ghensuu gh) async {
  if (gh.kukansuu_taikaigoto.length <= 2) return;
  final int ks = gh.kukansuu_taikaigoto[2];
  if (ks != shougatsuKukansuu) return;
  final int nendo = choukiNendo(gh);
  // 出場した大学(往路・復路のタイムがある大学)
  final List<UnivData> deta = [
    for (final UnivData u in univs)
      if (u.taikaientryflag.length > 2 &&
          u.taikaientryflag[2] == 1 &&
          fukuroTime(u, ks) != null)
        u,
  ];
  for (final UnivData u in univs) {
    _zurasu(u, ouroRace);
    _zurasu(u, fukuroRace);
  }
  final List<UnivData> ouroJun = List<UnivData>.of(deta)
    ..sort((a, b) {
      final int c = ouroTime(a)!.compareTo(ouroTime(b)!);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  final List<UnivData> fukuroJun = List<UnivData>.of(deta)
    ..sort((a, b) {
      final int c = fukuroTime(a, ks)!.compareTo(fukuroTime(b, ks)!);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
  for (int i = 0; i < ouroJun.length; i++) {
    _kaku(ouroJun[i], ouroRace, i, ouroTime(ouroJun[i])!);
  }
  for (int i = 0; i < fukuroJun.length; i++) {
    _kaku(fukuroJun[i], fukuroRace, i, fukuroTime(fukuroJun[i], ks)!);
  }
  for (final UnivData u in univs) {
    // 新しく始めたゲームの最初の正月駅伝なら、最初から全部記録している印を付ける
    choukiOufukuKaishiSettei(u);
    choukiKousin(u, ouroRace, nendo);
    choukiKousin(u, fukuroRace, nendo);
    // 2.0.0より前から遊んでいるデータで、記録を始めた年度の正月駅伝なら、
    // 前の年から続いているかもしれないので、連覇の数を「分からない」にする
    final int kaishi = choukiOufukuKaishi(u);
    if (kaishi > 1 && nendo == kaishi) {
      choukiRenzokuFumei(u, ouroRace, choukiYuushou);
      choukiRenzokuFumei(u, fukuroRace, choukiYuushou);
    }
    await u.save();
  }
}

/// 往路優勝・復路優勝の、記事に書くための事実(2.0.0)
class OufukuYuushou {
  /// 今回を含めた優勝の回数(記録を始めてからの数)
  final int kaisuu;

  /// 今回を含めた連覇の数(1は連覇でない。0は記録を始める前から続いているかもしれず、分からない)
  final int renzoku;

  /// 前回の優勝から何年ぶりか(連覇のときや、分からないときはnull)
  final int? buri;

  /// 最初の正月駅伝から全部記録しているか(falseなら「初」「○度目」と言い切らない)
  final bool zenbu;

  /// 前回の正月駅伝でも優勝していたか(連覇の数が分からなくても、連覇していることは言える)
  final bool zenkai;

  const OufukuYuushou(
    this.kaisuu,
    this.renzoku,
    this.buri,
    this.zenbu,
    this.zenkai,
  );

  /// 初めての優勝か(全部記録しているときだけtrue)
  bool get hatsu => zenbu && kaisuu <= 1;

  /// 連覇していて、数を言い切れないか(「連覇を伸ばした」とだけ書く)
  bool get renzokuFumei => renzoku == 0 && zenkai;
}

/// 大学[u]が今年の正月駅伝の[race](往路18・復路19)で優勝したときの事実
/// [kirokuZumi] 今年の正月駅伝がもう記録されているか(結果画面。レース中の往路のあとはfalse)
/// [nendo] 今年の正月駅伝の年度
OufukuYuushou oufukuYuushou(
  UnivData u,
  int race, {
  required bool kirokuZumi,
  required int nendo,
}) {
  final bool zenbu = choukiOufukuZenbu(u);
  final int tsuusan = choukiTsuusan(u, race, choukiYuushou);
  final int kaisuu = kirokuZumi ? tsuusan : tsuusan + 1;
  // 前回の正月駅伝の順位(今回をもう記録していれば[1]、まだなら[0])
  final int maeIdx = kirokuZumi ? 1 : 0;
  final bool zenkai = u.juni_race.length > race &&
      u.juni_race[race].length > maeIdx &&
      u.juni_race[race][maeIdx] == 0;
  final ChoukiKiroku? c = choukiYomu(u, race, choukiYuushou);
  if (c == null) {
    return OufukuYuushou(kaisuu, zenkai ? 0 : 1, null, zenbu, zenkai);
  }
  if (kirokuZumi) {
    // 今回の分まで記録してある(最後の年度が今回。合わなければ連覇も何年ぶりも書かない)
    if (c.saigo != nendo) {
      return OufukuYuushou(kaisuu, zenkai ? 0 : 1, null, zenbu, zenkai);
    }
    final int? buri = (c.renzoku == 1 && c.mae > 0) ? nendo - c.mae : null;
    return OufukuYuushou(kaisuu, c.renzoku, buri, zenbu, zenkai);
  }
  // まだ今回の分を記録していない(最後の年度は前回以前)
  if (zenkai) {
    return OufukuYuushou(
      kaisuu,
      c.renzoku == 0 ? 0 : c.renzoku + 1,
      null,
      zenbu,
      zenkai,
    );
  }
  final int? buri = (c.saigo > 0 && c.saigo < nendo) ? nendo - c.saigo : null;
  return OufukuYuushou(kaisuu, 1, buri, zenbu, zenkai);
}

/// 「2年ぶり3度目の」「3連覇の」「初の」などの言い方(往路優勝・復路優勝。[y] oufukuYuushou)
/// 全部記録していないときは、回数を書かず、言い切れる連覇と「○年ぶり」だけにする(何もなければ空)
String oufukuYuushouMoji(OufukuYuushou y) {
  if (y.hatsu) return '初の';
  if (y.renzoku >= 2) {
    return y.zenbu ? '${y.renzoku}年連続${y.kaisuu}度目の' : '${y.renzoku}年連続の';
  }
  if (y.renzoku == 1 && y.buri != null && y.buri! >= 2) {
    return y.zenbu ? '${y.buri}年ぶり${y.kaisuu}度目の' : '${y.buri}年ぶりの';
  }
  if (y.zenbu && y.renzoku != 0) return '${y.kaisuu}度目の';
  return '';
}
