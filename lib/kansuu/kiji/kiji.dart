import 'package:flutter/foundation.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart';
import 'package:ekiden/kansuu/kiji/kiji_kekka.dart';
import 'package:ekiden/kansuu/kiji/kiji_yosen.dart';
import 'package:ekiden/kansuu/kiji/kiji_tenbou.dart';

export 'package:ekiden/kansuu/kiji/kiji_kihon.dart'
    show Kiji, KijiBlock, KijiBlockShurui, KijiHyou, kijiSiteMei;
export 'package:ekiden/kansuu/kiji/kiji_tenbou.dart' show KijiYosouJin;

// ------------------------------------------------------------
// ニュース記事(箱庭スポーツ)の入口(1.9.2)
// ・結果の記事: 結果画面(駅伝・予選)の「ニュース記事」から開く
// ・展望の記事: 直前順位予想の画面の「展望記事」から開く
// 記事は開くたびに今のデータから作る(保存はしない。年・大会で決まる乱数を使うので、
// 同じ場面なら何度開いても同じ記事になる)
// 記事づくりで思わぬデータに当たっても画面が止まらないよう、失敗したら記事なしにする
// ------------------------------------------------------------

/// 表示中の大会の結果の記事
List<Kiji> kijiKekkaIchiran() {
  try {
    final KijiKankyou? k = KijiKankyou.yomu();
    if (k == null) return [];
    final List<Kiji> list = k.ekiden ? ekidenKekkaKiji(k) : yosenKekkaKiji(k);
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
    if (k == null) return [];
    final List<Kiji> list = tenbouKiji(k, yosou);
    _log(list);
    return list;
  } catch (e, st) {
    debugPrint('[ニュース記事] 展望の記事を作れませんでした: $e\n$st');
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
String kijiIraibun(bool kekka) {
  if (kekka) {
    return '以下は、駅伝ゲーム「箱庭小駅伝SS」の大会結果をもとにした、架空のスポーツニュースサイト'
        '「$kijiSiteMei」の記事です。あなたはスポーツ紙の駅伝担当のベテラン記者として、'
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
