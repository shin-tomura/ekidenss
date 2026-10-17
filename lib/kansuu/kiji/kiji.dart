import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart';
import 'package:ekiden/kansuu/kiji/kiji_yosen.dart';
import 'package:ekiden/kansuu/kiji/kiji_tenbou.dart';
import 'package:ekiden/kansuu/kiji/kiji_taikousen.dart';
import 'package:ekiden/kansuu/kiji/kiji_gakunai.dart';
import 'package:ekiden/kansuu/kiji/kiji_jikkyou.dart'; // 駅伝の実況「箱庭スポーツ中継」(1.9.4)
import 'package:ekiden/kansuu/kiji/kiji_nenkan.dart'; // 年間表彰と学内表彰(3月25日。1.9.4)
import 'package:ekiden/kansuu/kiji/kiji_gakuren.dart'; // 学連選抜通信(正月駅伝。1.9.7)
import 'package:ekiden/kansuu/kiji/kiji_ouro.dart'; // 正月駅伝の往路の記事(2.0.0)
import 'package:ekiden/kansuu/kiji/kiji_shinnyuusei.dart'; // 新入生の記事(4月5日。2.0.0)
import 'package:ekiden/kansuu/kiji/kiji_kyouka.dart'; // 強化プロジェクトの記事(4月5日。2.0.1)
import 'package:ekiden/kansuu/kiji/kiji_tt.dart'; // 夏のTT特集(8月25日。2.0.0)
import 'package:ekiden/kansuu/kiji/kiji_koukou_shinkou.dart'; // 高校の大会の記事(7月下旬・11月中旬・12月下旬。2.0.4)
import 'package:ekiden/kansuu/gakuren_text.dart' show gakurenKonnenAri;

export 'package:ekiden/kansuu/kiji/kiji_kihon.dart'
    show Kiji, KijiBlock, KijiBlockShurui, KijiHyou, kijiSiteMei;
export 'package:ekiden/kansuu/kiji/kiji_jikkyou.dart' show jikkyouSiteMei;
export 'package:ekiden/kansuu/kiji/kiji_tenbou.dart' show KijiYosouJin;
export 'package:ekiden/kansuu/kiji/kiji_gakuren.dart' show gakurenSiteMei;
export 'package:ekiden/kansuu/kiji/kiji_shinnyuusei.dart' show kijiShinnyuuseiKa;
export 'package:ekiden/kansuu/kiji/kiji_tt.dart' show kijiTtKa, ttSaishuuRace;
// スカウト前の高校の大会の記事(2.0.1。新入生のスカウトの画面で出す)
export 'package:ekiden/kansuu/kiji/kiji_koukou_taikai.dart' show kijiKoukouTaikaiKa, koukouTaikaiKiji;
// 高校の大会の記事(2.0.4。高校の大会の結果が出る日のお知らせと、高校名鑑から読む)
export 'package:ekiden/kansuu/kiji/kiji_koukou_shinkou.dart' show kijiKoukouShinkouKa;

// ------------------------------------------------------------
// ニュース記事(箱庭スポーツ)の入口(1.9.2)
// ・結果の記事: 結果画面(駅伝・予選・対校戦)の「ニュース記事」から開く
// ・展望の記事: 直前順位予想の画面の「展望記事」から開く
// ・スタート直前号: 目標順位の確認の画面の「スタート直前号」から開く(駅伝の1区のスタート前。
//   当日変更のあとの、実際に走る選手で書く)
// 記事は開くたびに今のデータから作る(保存はしない。年・大会で決まる乱数を使うので、
// 同じ場面なら何度開いても同じ記事になる)
// 記事づくりで思わぬデータに当たっても画面が止まらないよう、失敗したら記事なしにする
// 1.9.3から、自分の大学の学内メディア「○○スポーツ」の記事もある(kiji_gakunai.dart)。
// 駅伝の結果・展望・スタート直前号は同じカードから開き、記事の画面の上で切り替える。
// 正月駅伝の復路スタート直前号と、3月25日の卒業生特集は、学内メディアだけ。
// 3月25日には、箱庭スポーツの年間表彰と学内メディアの学内表彰もある(kiji_nenkan.dart。1.9.4)。
// 対校戦は、種目ごとの結果画面のカードから結果号だけを読める
// 1.9.4から、駅伝の実況「箱庭スポーツ中継」もある(kiji_jikkyou.dart)。レース画面(区間が終わるたびの
// 指示の画面)のカードと、結果画面の記事の画面の切り替えで読める
// 1.9.7から、正月駅伝では学連選抜を追う「学連選抜通信」もある(kiji_gakuren.dart)。展望号は学連選抜編成の
// 画面のカードと直前順位予想の展望記事の切り替え、区間ごとの速報はレース画面の実況のカードから開く記事の画面、
// 結果号と速報は結果画面の記事の画面の切り替えで読める
// 2.0.0から、4月5日の最新画面で、箱庭スポーツの「期待のルーキー」と学内メディアの「新入生紹介号」も読める
// (kiji_shinnyuusei.dart。新入生の世代全体と、自分の大学の新入生の記事)
// 2.0.0から、8月25日(夏のTTの最終日のロード10km)の結果画面で、箱庭スポーツの「夏のTT特集」と
// 学内メディアの「学内TT特集」も読める(kiji_tt.dart)
// 2.0.4から、高校の大会の結果が出る日(7月下旬の高校総体・11月中旬の都道府県予選と地区大会・12月下旬の
// 全国高校駅伝)のお知らせと、高校名鑑から、箱庭スポーツの高校の大会の記事も読める(kiji_koukou_shinkou.dart)
// ------------------------------------------------------------

/// 表示中の大会の結果の記事
List<Kiji> kijiKekkaIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomu(kekka: true);
    if (k == null) return [];
    final List<Kiji> list = k.ekiden
        ? ekidenKekkaKiji(k)
        : (k.taikousen ? taikousenKekkaKiji(k) : yosenKekkaKiji(k));
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 結果の記事を作れませんでした: $e\n$st');
    return [];
  }
}

/// 表示中の大会の展望の記事([yosou] 予想陣の予想。なければ空)
List<Kiji> kijiTenbouIchiran(List<KijiYosouJin> yosou) {
  try {
    final KijiKankyou? k = KijiKankyou.yomu();
    // 対校戦には展望の記事がない
    if (k == null || k.taikousen) return [];
    final List<Kiji> list = tenbouKiji(k, yosou);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 展望の記事を作れませんでした: $e\n$st');
    return [];
  }
}

/// 表示中の駅伝の実況(終わった区間の分。終わったばかりの区間が先頭。1.9.4)
/// 結果画面(mode 700)では大会が終わっているので、昨年の記録の見方を結果の記事と同じにする
List<Kiji> kijiJikkyouIchiran() {
  try {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null) return [];
    final bool owatta = gh.mode == 700;
    final KijiKankyou? k = KijiKankyou.yomu(kekka: owatta);
    if (k == null || !k.ekiden) return [];
    final List<Kiji> list = jikkyouKiji(k, owatta: owatta);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 実況を作れませんでした: $e\n$st');
    return [];
  }
}

/// 学内メディアの区間ごとの速報(1.9.7。自分の大学の選手を追う。終わったばかりの区間が先頭。
/// 結果画面(mode 700)では大会が終わっているので、昨年の記録の見方を結果の記事と同じにする)
List<Kiji> kijiGakunaiSokuhouIchiran() {
  try {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null) return [];
    final bool owatta = gh.mode == 700;
    final KijiKankyou? k = KijiKankyou.yomu(kekka: owatta);
    if (k == null || !k.ekiden) return [];
    final List<Kiji> list = gakunaiSokuhouKiji(k, owatta: owatta);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 学内メディアの速報を作れませんでした: $e\n$st');
    return [];
  }
}

/// レース画面の実況のカードに添える、区間ごとの速報の案内(1.9.7。読める速報がなければnull)
/// カードの見出しの予告と、記事の画面で最初に開くのは、いつも俯瞰した箱庭スポーツ中継にする
/// (自分のチームが見出しに載ったときの喜びが大きくなるように)。速報は記事の画面の上で切り替えて読む
String? kijiSokuhouAnnai() {
  final List<String> mei = [
    if (kijiGakunaiShutsujou() && kijiGakunaiSiteMei() != null) '学内メディア「${kijiGakunaiSiteMei()}」',
    if (_gakurenAri()) '「$gakurenSiteMei」',
  ];
  if (mei.isEmpty) return null;
  return '${mei.join('と')}の区間ごとの速報も、記事の画面の上で切り替えて読めます';
}

/// 正月駅伝の往路の記事(2.0.0。5区が終わったあとのレース画面と、6区のスタート前の目標順位の確認の画面から。
/// 結果画面の記事の一覧にも入る。kiji_ouro.dart)
/// 結果画面(mode 700)では大会が終わっていて、今年の往路の成績も記録してある
List<Kiji> kijiOuroIchiran() {
  try {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null) return [];
    final bool owatta = gh.mode == 700;
    final KijiKankyou? k = KijiKankyou.yomu(kekka: owatta);
    if (k == null || k.race != 2) return [];
    final List<Kiji> list = ouroKekkaKiji(k, kirokuZumi: owatta);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 往路の記事を作れませんでした: $e\n$st');
    return [];
  }
}

/// 表示中の大会のスタート直前号(当日変更のあと。駅伝だけ)
List<Kiji> kijiChokuzenIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomu();
    if (k == null || !k.ekiden) return [];
    final List<Kiji> list = tenbouKiji(k, const [], chokuzen: true);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] スタート直前号を作れませんでした: $e\n$st');
    return [];
  }
}

// ------------------------------------------------------------
// 学内メディア(○○スポーツ。1.9.3)
// ------------------------------------------------------------

// 次の3つは画面を描くたびに呼ぶので、全選手は読まず、全体の変数と自分の大学だけを見る

/// 自分の大学(なければnull)
UnivData? _jibunUniv() {
  final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
  if (gh == null) return null;
  for (final UnivData u in Hive.box<UnivData>('univBox').values) {
    if (u.id == gh.MYunivid) return u;
  }
  return null;
}

/// 自分の大学の学内メディアの名前(大学がなければnull)
String? kijiGakunaiSiteMei() {
  try {
    final UnivData? u = _jibunUniv();
    return u == null ? null : gakunaiSiteMei(u);
  } catch (e) {
    return null;
  }
}

/// 表示中の大会が、学内メディアの記事がある大会か
/// (10月・11月・正月・カスタム駅伝と、11月駅伝予選・正月駅伝予選。
/// [kekka] なら、結果号だけがある対校戦の3種目も入れる)
bool kijiGakunaiTaikai({bool kekka = false}) {
  try {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null) return false;
    final int race = gh.hyojiracebangou;
    return race >= 0 && race <= (kekka ? 8 : 5);
  } catch (e) {
    return false;
  }
}

/// 自分の大学が、表示中の大会に出場しているか(学内メディアだけのカードを出すかを決める)
bool kijiGakunaiShutsujou() {
  try {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    final UnivData? u = _jibunUniv();
    if (gh == null || u == null) return false;
    final int race = gh.hyojiracebangou;
    return race >= 0 &&
        u.taikaientryflag.length > race &&
        u.taikaientryflag[race] == 1;
  } catch (e) {
    return false;
  }
}

/// 入口のカードに添える、学内メディアの案内(駅伝と駅伝予選のときだけ。それ以外はnull)
/// [kekka] 結果画面のカード(対校戦の結果画面にも案内を出す)
/// [gakuren] 学連選抜通信の記事も切り替えに入るカード(直前順位予想の展望記事と結果画面)。
///   正月駅伝で今年の学連選抜がいれば、学連選抜通信のことも添える(1.9.7)
String? kijiGakunaiAnnai({bool kekka = false, bool gakuren = false}) {
  if (!kijiGakunaiTaikai(kekka: kekka)) return null;
  final String? site = kijiGakunaiSiteMei();
  if (site == null) return null;
  if (gakuren && _gakurenAri()) {
    return '学内メディア「$site」と「$gakurenSiteMei」の記事も、記事の画面の上で切り替えて読めます';
  }
  return '学内メディア「$site」の記事も、記事の画面の上で切り替えて読めます';
}

/// 表示中の大会が正月駅伝で、今年の学連選抜がいるか(1.9.7)
bool _gakurenAri() {
  try {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    return gh != null && gakurenKonnenAri(gh);
  } catch (e) {
    return false;
  }
}

/// 学内メディアの、表示中の駅伝・駅伝予選・対校戦の結果号
List<Kiji> kijiGakunaiKekkaIchiran() =>
    _gakunai('結果号', gakunaiKekkaKiji, kekka: true);

/// 学内メディアの、表示中の駅伝・駅伝予選の展望号
List<Kiji> kijiGakunaiTenbouIchiran() => _gakunai('展望号', gakunaiTenbouKiji);

/// 学内メディアの、表示中の駅伝のスタート直前号(1区のスタート前は当日変更号、
/// 正月駅伝の6区のスタート前は復路スタート直前号)
List<Kiji> kijiGakunaiChokuzenIchiran() => _gakunai(
  'スタート直前号',
  (k) => gakunaiChokuzenKiji(k, k.gh.nowracecalckukan),
);

/// 学内メディアの卒業生特集(3月25日。大会に関係ないので、正月駅伝を記事にする大会として読む)
List<Kiji> kijiGakunaiSotsugyouIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomuRace(2);
    if (k == null) return [];
    final List<Kiji> list = gakunaiSotsugyouKiji(k);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 卒業生特集を作れませんでした: $e\n$st');
    return [];
  }
}

/// 箱庭スポーツの年間表彰(3月25日。大会に関係ないので、正月駅伝を記事にする大会として読む。1.9.4)
List<Kiji> kijiNenkanIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomuRace(2, kekka: true);
    if (k == null) return [];
    final List<Kiji> list = nenkanHyoushouKiji(k);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 年間表彰を作れませんでした: $e\n$st');
    return [];
  }
}

/// 学内メディアの学内表彰(3月25日。1.9.4)
List<Kiji> kijiGakunaiHyoushouIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomuRace(2, kekka: true);
    if (k == null) return [];
    final List<Kiji> list = gakunaiHyoushouKiji(k);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 学内表彰を作れませんでした: $e\n$st');
    return [];
  }
}

/// 箱庭スポーツの「期待のルーキー」(4月5日。大会に関係ないので、正月駅伝を記事にする大会として読む。2.0.0)
List<Kiji> kijiShinnyuuseiIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomuRace(2);
    if (k == null) return [];
    // 強化プロジェクトが今年度始まっていれば、その記事を後ろに足す(2.0.1。kiji_kyouka.dart)
    // (先頭は期待のルーキーのまま。生成AIに渡すテキストの依頼文を新入生の記事にするため)
    final List<Kiji> list = [...shinnyuuseiKiji(k), ...kyoukaProjectKiji(k)];
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 期待のルーキーを作れませんでした: $e\n$st');
    return [];
  }
}

/// 学内メディアの「新入生紹介号」(4月5日。2.0.0)
List<Kiji> kijiGakunaiShinnyuuseiIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomuRace(2);
    if (k == null) return [];
    final List<Kiji> list = shinnyuuseiGakunaiKiji(k);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 新入生紹介号を作れませんでした: $e\n$st');
    return [];
  }
}

/// 箱庭スポーツの「夏のTT特集」(8月25日。大会に関係ないので、正月駅伝を記事にする大会として読む。2.0.0)
List<Kiji> kijiTtIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomuRace(2);
    if (k == null) return [];
    final List<Kiji> list = ttKiji(k);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 夏のTT特集を作れませんでした: $e\n$st');
    return [];
  }
}

/// 箱庭スポーツの高校の大会の記事(2.0.4。今年度の高校の大会の、出した大会の分だけ。新しい順)
List<Kiji> kijiKoukouShinkouIchiran() {
  try {
    final List<Kiji> list = koukouShinkouKiji();
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 高校の大会の記事を作れませんでした: $e\n$st');
    return [];
  }
}

/// 学内メディアの「学内TT特集」(8月25日。2.0.0)
List<Kiji> kijiGakunaiTtIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomuRace(2);
    if (k == null) return [];
    final List<Kiji> list = ttGakunaiKiji(k);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 学内TT特集を作れませんでした: $e\n$st');
    return [];
  }
}

// ------------------------------------------------------------
// 学連選抜通信(1.9.7。kiji_gakuren.dart。正月駅伝だけ)
// ------------------------------------------------------------

/// 学連選抜通信の展望号(学連選抜編成の画面と、直前順位予想の画面の展望記事)
List<Kiji> kijiGakurenTenbouIchiran() => _gakuren('展望号', gakurenTenbouKiji);

/// 学連選抜通信の結果号(結果画面)
List<Kiji> kijiGakurenKekkaIchiran() =>
    _gakuren('結果号', gakurenKekkaKiji, kekka: true);

/// 学連選抜通信の区間ごとの速報(終わったばかりの区間が先頭。結果画面(mode 700)では大会が終わっている)
List<Kiji> kijiGakurenSokuhouIchiran() {
  final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
  if (gh == null) return [];
  return _gakuren('速報', gakurenSokuhouKiji, kekka: gh.mode == 700);
}

List<Kiji> _gakuren(
  String mei,
  List<Kiji> Function(KijiKankyou k) tsukuru, {
  bool kekka = false,
}) {
  try {
    final KijiKankyou? k = KijiKankyou.yomu(kekka: kekka);
    if (k == null) return [];
    final List<Kiji> list = tsukuru(k);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 学連選抜通信の$meiを作れませんでした: $e\n$st');
    return [];
  }
}

/// [kekka] 結果号(大会のあと)のとき
List<Kiji> _gakunai(
  String mei,
  List<Kiji> Function(KijiKankyou k) tsukuru, {
  bool kekka = false,
}) {
  try {
    final KijiKankyou? k = KijiKankyou.yomu(kekka: kekka);
    if (k == null) return [];
    final List<Kiji> list = tsukuru(k);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 学内メディアの$meiを作れませんでした: $e\n$st');
    return [];
  }
}

/// デバッグのときは、作った記事をすべてログに出す(言い回しの確認用)
void _log(List<Kiji> list) {
  if (!kDebugMode) return;
  for (final Kiji kiji in list) {
    for (final String gyou in kiji.zenbun().split('\n')) {
      debugPrint('[ニュース記事] $gyou');
    }
    debugPrint('[ニュース記事] ----------------');
  }
}

/// 生成AIに記事を渡すときの依頼文
/// [gakunai] 学内メディアの記事のとき([site] はそのサイトの名前。1.9.3)
/// [sokuhou] 区間ごとの速報のとき(学内メディアと学連選抜通信。1.9.7)
/// [shinnyuusei] 新入生の記事のとき(箱庭スポーツの期待のルーキーと、学内メディアの新入生紹介号。2.0.0)
/// [tt] 夏のTT特集のとき(箱庭スポーツの夏のTT特集と、学内メディアの学内TT特集。2.0.0)
/// [scoutMae] スカウト前の高校の大会の記事のとき(箱庭スポーツの「スカウト解禁」。2.0.1)
/// [koukou] 高校の大会の記事のとき(高校総体・全国高校駅伝の予選と本大会と、地方版。2.0.4)
String kijiIraibun(
  bool kekka, {
  bool gakunai = false,
  String site = kijiSiteMei,
  bool sokuhou = false,
  bool shinnyuusei = false,
  bool tt = false,
  bool scoutMae = false,
  bool koukou = false,
}) {
  // 高校の大会の記事(2.0.4)。高校3年生の進学先はまだ決まっていないので、決めつけないように頼む
  if (koukou) {
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」の高校の大会の結果をもとにした、架空のスポーツニュースサイト'
        '「$site」の、高校の陸上の記事です。あなたはスポーツ紙の高校陸上担当のベテラン記者として、'
        '読みごたえのある記事に書き直してください。'
        '記事の時点では、高校3年生の進学先はまだ決まっていません。進学先や、どの大学に入るかは書き足さないでください。'
        '順位・タイム・選手名・高校名などの事実は変えないでください。'
        '選手の性格や勝負強さなど、記事に書かれていない特徴は付け足さないでください。'
        'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
  }
  // スカウト前の高校の大会の記事(2.0.1)。進学先はまだ決まっていないので、決めつけないように頼む
  if (scoutMae) {
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」の高校の大会の結果をもとにした、架空のスポーツニュースサイト'
        '「$kijiSiteMei」の、大学の新入生スカウトが始まる前の記事です。あなたはスポーツ紙の駅伝・陸上担当のベテラン記者として、'
        '読みごたえのある記事に書き直してください。'
        'この時点では、高校3年生の進学先はまだ決まっていません。進学先や、どの大学に入るかは決めつけないでください。'
        '順位・タイム・持ちタイム・選手名・高校名・大学名などの事実は変えないでください。'
        '選手の性格や勝負強さなど、記事に書かれていない特徴は付け足さないでください。'
        'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
  }
  // 夏のTT特集(2.0.0)。全体の順位は書かず、タイムで書いている記事なので、順位を足さないように頼む
  if (tt) {
    final String dare = gakunai
        ? '大学の陸上競技部を追う架空の学内メディア「$site」の、夏のタイムトライアルの特集です。あなたは陸上競技部を担当する学生記者として、'
            '部員の夏の頑張りが伝わる記事に書き直してください。'
        : '架空のスポーツニュースサイト「$kijiSiteMei」の、夏のタイムトライアルの特集です。あなたはスポーツ紙の駅伝・陸上担当のベテラン記者として、'
            '読みごたえのある記事に書き直してください。夏のタイムトライアルは、どの大学も同じコース・同じ条件で走っています。'
            '学生全体の中での順位(1位・最速など)は書き足さないでください。';
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」の夏のタイムトライアルの結果をもとにした、$dare'
        'タイム・選手名・大学名などの事実は変えないでください。'
        '選手の性格や能力など、記事に書かれていない特徴は付け足さないでください。'
        'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
  }
  // 新入生の記事(2.0.0)。高校の大会の結果に、選手の性質(勝負強さなど)を付け足さないように頼む
  // (高校の大会の計算には駅伝男・平常心を使っていないので、読み違えさせないため)
  if (shinnyuusei) {
    final String dare = gakunai
        ? '大学の陸上競技部を追う架空の学内メディア「$site」の新入生紹介の記事です。あなたは陸上競技部を担当する学生記者として、'
            '新しい仲間を温かく迎える記事に書き直してください。'
        : '架空のスポーツニュースサイト「$kijiSiteMei」の新入生特集の記事です。あなたはスポーツ紙の駅伝・陸上担当のベテラン記者として、'
            '読みごたえのある記事に書き直してください。';
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」の新入生のデータをもとにした、$dare'
        '持ちタイム・高校時代の実績・選手名・大学名・高校名などの事実は変えないでください。'
        '大学での活躍や伸び方は決めつけないでください。'
        '選手の性格や勝負強さなど、記事に書かれていない特徴は付け足さないでください。'
        'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
  }
  // 区間ごとの速報(1.9.7)
  if (sokuhou) {
    final String dare = site == gakurenSiteMei
        ? '学連選抜を追う架空の専門メディア「$site」の、区間ごとの速報です。あなたは学連選抜を担当する記者として、'
        : '大学の陸上競技部を追う架空の学内メディア「$site」の、区間ごとの速報です。あなたは陸上競技部を担当する学生記者として、';
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」のレースの途中経過をもとにした、$dare'
        '速報の臨場感を残した、選手に寄り添う記事に書き直してください。'
        '順位・タイム差・選手名・大学名などの事実は変えないでください。'
        'まだ走っていない区間の結果は決めつけないでください。'
        'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
  }
  // 学連選抜通信(1.9.7)
  if (site == gakurenSiteMei) {
    if (kekka) {
      return '以下は、駅伝ゲーム「箱庭小駅伝SS」の大会結果をもとにした、学連選抜を追う架空の専門メディア'
          '「$site」の記事です。あなたは学連選抜を担当する記者として、'
          'それぞれの大学の思いを背負って走った選手に寄り添う、読みごたえのある記事に書き直してください。'
          '順位(○位相当)・タイム・選手名・大学名などの事実は変えないでください。'
          'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
    }
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」のレース前のデータをもとにした、学連選抜を追う架空の専門メディア'
        '「$site」の展望記事です。あなたは学連選抜を担当する記者として、'
        'それぞれの大学の思いを背負って走る選手を応援したくなる記事に書き直してください。'
        'まだレースは行われていないので、結果を決めつけないでください。'
        '持ちタイム・区間・選手名・大学名などの事実は変えないでください。'
        'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
  }
  // 駅伝の実況(1.9.4)
  if (site == jikkyouSiteMei) {
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」のレースの途中経過をもとにした、架空のテレビ中継'
        '「$jikkyouSiteMei」の実況です。あなたは駅伝中継の実況アナウンサーと解説者になりきって、'
        'この実況をもとに、臨場感のある中継の文に書き直してください。'
        '実況と解説の掛け合いの形は残してください。'
        '順位・タイム差・選手名・大学名などの事実は変えないでください。'
        '選手の能力については、実況の中に書かれていること以外を決めつけないでください。'
        'コメントは実況の中のものだけを使い、新しい発言は作らないでください。\n\n';
  }
  if (gakunai) {
    if (kekka) {
      return '以下は、駅伝ゲーム「箱庭小駅伝SS」のデータをもとにした、大学の陸上競技部を追う架空の学内メディア'
          '「$site」の記事です。あなたは陸上競技部を担当する学生記者として、'
          '選手一人ひとりに寄り添う、温かく読みごたえのある記事に書き直してください。'
          '順位・タイム・選手名・大学名などの事実は変えないでください。'
          'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
    }
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」のレース前のデータをもとにした、大学の陸上競技部を追う架空の学内メディア'
        '「$site」の記事です。あなたは陸上競技部を担当する学生記者として、'
        '選手一人ひとりを応援したくなる、温かい記事に書き直してください。'
        'まだレースは行われていないので、結果を決めつけないでください。'
        '持ちタイム・区間・選手名・大学名などの事実は変えないでください。'
        'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
  }
  if (kekka) {
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」の大会結果をもとにした、架空のスポーツニュースサイト'
        '「$kijiSiteMei」の記事です。あなたはスポーツ紙の駅伝・陸上担当のベテラン記者として、'
        'この記事をもとに、読みごたえのある記事に書き直してください。'
        '順位・タイム・選手名・大学名などの事実は変えないでください。'
        'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
  }
  return '以下は、駅伝ゲーム「箱庭小駅伝SS」のレース前のデータをもとにした、架空のスポーツニュースサイト'
      '「$kijiSiteMei」の展望記事です。あなたはスポーツ紙の駅伝担当のベテラン記者として、'
      'この記事をもとに、レース当日の朝に読みたくなる展望記事に書き直してください。'
      'まだレースは行われていないので、結果を決めつけないでください。'
      '持ちタイム・区間・選手名・大学名などの事実は変えないでください。'
      'コメントは記事の中のものだけを使い、新しい発言は作らないでください。\n\n';
}
