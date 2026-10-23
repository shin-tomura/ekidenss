import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kansuu/univ_rekidai.dart';
import 'package:ekiden/kansuu/fushime.dart' show zendaigakuGakunaiHajimeNendo; // 全大学で学内記録を付け始めた年度
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show KijiHyou;
import 'package:ekiden/screens/kiji_hyou_view.dart'; // 表の部品
import 'package:ekiden/screens/kiroku_link.dart'; // 選手名のリンク

// ------------------------------------------------------------
// 大学画面の「この大学の歴代記録」の窓(2.1.4。中身は kansuu/univ_rekidai.dart)
// ・全体の歴代10位以内に入っている、表示している大学の個人記録と区間記録を、1つの表で出す(個人記録が先)
//   (チームの総合記録は、大学画面の各駅伝の欄に1行で出している)
// ・その下に、種目・区間ごとの学内記録の1位の表を出す(2.1.4から全大学で付ける。個人記録が先。1位が留学生なら日本人の1位も)。
//   2.1.3までのセーブデータのほかの大学は、付け始めた年度を添える。総監督をしている大学は、2位以下を記録画面で見られる
// ・選手名は、開ける選手(現役の選手・残っている卒業生)ならリンクにする(記録画面と同じ。kiroku_link.dart)
// ・表は横に長いときは横にスクロールし、窓の中は縦にスクロールする(文字を大きくしていてもはみ出さないように)
// ------------------------------------------------------------

/// 大学[u]の歴代記録の窓を開く
void univRekidaiHiraku(BuildContext context, UnivData u) {
  final Ghensuu? gh = Hive.isBoxOpen('ghensuuBox')
      ? Hive.box<Ghensuu>('ghensuuBox').get('global_ghensuu')
      : null;
  final List<UnivRekidaiGyou> l = gh == null ? const [] : univRekidaiIchiran(gh, u);
  final List<UnivGakunaiGyou> g = gh == null ? const [] : univGakunaiIchiran(gh, u);
  final bool jibun = gh != null && u.id == gh.MYunivid;
  final int hajime = gh == null ? 0 : zendaigakuGakunaiHajimeNendo(gh);
  final KirokuLinkJisho jisho = KirokuLinkJisho();
  final KijiHyou hyou = KijiHyou(
    '全体の歴代10位以内',
    ['種目・区間', 'タイム', '選手', '順位'],
    [
      for (final UnivRekidaiGyou x in l) [x.shumoku, x.time, x.senshu, x.juniMoji],
    ],
  );
  final KijiHyou gakunaiHyou = KijiHyou(
    '学内記録(1位)',
    ['種目・区間', 'タイム', '選手', '年'],
    [
      for (final UnivGakunaiGyou x in g) [x.shumoku, x.time, x.senshu, x.nen],
    ],
  );
  const TextStyle chuu = TextStyle(
    color: Colors.white,
    fontSize: HENSUU.fontsize_honbun - 2,
  );
  showDialog<void>(
    context: context,
    builder: (BuildContext c) {
      // 選手名のマスを押すと、その選手を開く(開けない選手は押せない)
      final Map<(int, int), VoidCallback> link = {
        for (int i = 0; i < l.length; i++)
          if (jisho.aru(l[i].bangou)) (i, 2): () => jisho.hiraku(c, l[i].bangou!),
      };
      final Map<(int, int), VoidCallback> gakunaiLink = {
        for (int i = 0; i < g.length; i++)
          if (jisho.aru(g[i].bangou)) (i, 2): () => jisho.hiraku(c, g[i].bangou!),
      };
      return AlertDialog(
        backgroundColor: HENSUU.backgroundcolor,
        title: Text(
          '${u.name}大学の歴代記録',
          style: const TextStyle(color: Colors.white, fontSize: HENSUU.fontsize_honbun),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '全体の歴代10位以内に入っている個人記録と区間記録です(日本人と留学生を合わせた並び)。',
                  style: chuu,
                ),
                const Text(
                  '同じ並びに何件もあるときは、一番上の記録を出し、ほかの件数を添えます。',
                  style: chuu,
                ),
                if (link.isNotEmpty || gakunaiLink.isNotEmpty)
                  const Text('選手名(緑の下線)を押すと、その選手を見られます。', style: chuu),
                if (l.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      '全体の歴代10位以内に入っている記録はありません。',
                      style: TextStyle(color: Colors.white, fontSize: HENSUU.fontsize_honbun),
                    ),
                  )
                else
                  KijiHyouView(hyou, ue: 8, link: link),
                // 学内記録の1位(2.1.4)
                const SizedBox(height: 20),
                if (g.isEmpty)
                  const Text(
                    '学内記録はまだありません。',
                    style: TextStyle(color: Colors.white, fontSize: HENSUU.fontsize_honbun),
                  )
                else
                  KijiHyouView(gakunaiHyou, ue: 0, link: gakunaiLink),
                if (!jibun && hajime > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('(学内記録は、$hajime年度から記録しています)', style: chuu),
                  ),
                if (jibun)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('2位以下は、記録画面の大学記録で見られます。', style: chuu),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text(
              '閉じる',
              style: TextStyle(color: HENSUU.LinkColor, fontSize: HENSUU.fontsize_honbun),
            ),
          ),
        ],
      );
    },
  );
}
