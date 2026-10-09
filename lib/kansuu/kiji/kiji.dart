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

export 'package:ekiden/kansuu/kiji/kiji_kihon.dart'
    show Kiji, KijiBlock, KijiBlockShurui, KijiHyou, kijiSiteMei;
export 'package:ekiden/kansuu/kiji/kiji_jikkyou.dart' show jikkyouSiteMei;
export 'package:ekiden/kansuu/kiji/kiji_tenbou.dart' show KijiYosouJin;

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
String? kijiGakunaiAnnai({bool kekka = false}) {
  if (!kijiGakunaiTaikai(kekka: kekka)) return null;
  final String? site = kijiGakunaiSiteMei();
  return site == null ? null : '学内メディア「$site」の記事も、記事の画面の上で切り替えて読めます';
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
String kijiIraibun(bool kekka, {bool gakunai = false, String site = kijiSiteMei}) {
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
