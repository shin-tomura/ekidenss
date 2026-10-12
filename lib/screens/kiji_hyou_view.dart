import 'package:flutter/material.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show KijiHyou;

// ------------------------------------------------------------
// 成績欄などの表(KijiHyou)を出す部品(1.9.8)
// ・記事の画面(kiji_screen.dart)の表を切り出したもの。選手画面・選手の詳細・卒業生画面の
//   三大駅伝と対校戦の成績の表でも使う
// ・横に長いときは横にスクロールする。高さは固定しない(文字を大きくしている人でもはみ出さないように)
// ------------------------------------------------------------

const Color _waku = Color(0xFF161616);
const Color _sen = Color(0xFF333333);
const Color _honbunIro = Color(0xFFDDDDDD);

class KijiHyouView extends StatelessWidget {
  final KijiHyou hyou;

  /// 上の余白(記事の本文の途中に置く表は狭くする)
  final double ue;

  const KijiHyouView(this.hyou, {super.key, this.ue = 24});

  @override
  Widget build(BuildContext context) {
    const TextStyle midashiStyle = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );
    const TextStyle mojiStyle = TextStyle(color: _honbunIro, fontSize: 13);
    Widget masu(String s, TextStyle st) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(s, style: st, softWrap: false),
    );
    return Padding(
      padding: EdgeInsets.only(top: ue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '【${hyou.title}】',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              border: const TableBorder(
                horizontalInside: BorderSide(color: _sen),
                top: BorderSide(color: _sen),
                bottom: BorderSide(color: _sen),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: _waku),
                  children: [for (final String s in hyou.retsu) masu(s, midashiStyle)],
                ),
                for (final List<String> g in hyou.gyou)
                  TableRow(
                    children: [
                      for (int i = 0; i < hyou.retsu.length; i++)
                        masu(i < g.length ? g[i] : '', mojiStyle),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
