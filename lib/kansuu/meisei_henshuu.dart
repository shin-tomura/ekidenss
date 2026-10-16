import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/meisei_rireki.dart'; // 名声の履歴(1.8.8)

// ------------------------------------------------------------
// 名声を編集する(2.0.3。名声の横並び設定の画面のグループの編集で使う。meisei_yokonarabi_settei.dart)
//
// 名声設定の画面(univ_screen.dart の ModalMeiseiHenkou)と同じ変え方にする:
// ・入力できるのは9〜(10万と、今の一番高い名声の大きいほう)
// ・10年分の合計をその値にし、年ごとの名声は10年に均等に分ける(端数は新しい年から1ずつ)
// ・名声の履歴に「名声を編集」と書く(年ごとの名声を作り直すので、内訳と合わなくなるため)
// ・名声の順位(meiseijuni)を付け直す(駅伝のあとや年度替わりと同じ並べ方。名声の高い順で、同じなら大学idの大きい順)
// (名声設定の画面は今のまま。この関数は使っていない)
// ------------------------------------------------------------

/// 入力できる名声の下限
const int meiseiHenshuuSaishou = 9;

/// 入力できる名声の上限の基本(今の一番高い名声がこれより高ければ、その値まで)
const int _saidaiKihon = 100000;

/// 入力できる名声の上限
int meiseiHenshuuSaidai(Iterable<UnivData> univs) {
  int saidai = _saidaiKihon;
  for (final UnivData u in univs) {
    saidai = max(saidai, u.meisei_total);
  }
  return saidai;
}

/// 大学[univ]の名声(10年分の合計)を[atai]にする(範囲の外なら何もしない)。
/// 年ごとの名声を作り直して保存し、名声の履歴に書き、名声の順位を付け直す
Future<void> meiseiHenshuu(UnivData univ, int atai) async {
  final Box<UnivData> box = Hive.box<UnivData>('univBox');
  if (atai < meiseiHenshuuSaishou || atai > meiseiHenshuuSaidai(box.values)) return;
  if (atai == univ.meisei_total) return;
  univ.meisei_total = atai;
  final int base = atai ~/ 10;
  final int amari = atai % 10;
  univ.meisei_yeargoto = List.generate(10, (int i) => i < amari ? base + 1 : base);
  await univ.save();
  await meiseiRirekiTsuika(univ.id, '名声を編集(10年分の合計を${atai}にした)', 0);
  await meiseiJuniTsukeNaoshi();
}

/// 名声の順位(meiseijuni。0が1位)を付け直す
/// (駅伝のあとや年度替わりと同じ並べ方。名声の高い順で、同じなら大学idの大きい順)
Future<void> meiseiJuniTsukeNaoshi() async {
  final Box<UnivData> box = Hive.box<UnivData>('univBox');
  final List<UnivData> jun = box.values.toList()
    ..sort((a, b) => (b.meisei_total * 100 + b.id).compareTo(a.meisei_total * 100 + a.id));
  for (int i = 0; i < jun.length; i++) {
    if (jun[i].meiseijuni != i) {
      jun[i].meiseijuni = i;
      await jun[i].save();
    }
  }
}
