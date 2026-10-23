import 'package:flutter/material.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show KijiHyou;

// ------------------------------------------------------------
// 成績欄などの表(KijiHyou)を出す部品(1.9.8)
// ・記事の画面(kiji_screen.dart)の表を切り出したもの。選手画面・選手の詳細・卒業生画面の
//   三大駅伝と対校戦の成績の表でも使う
// ・横に長いときは横にスクロールする。高さは固定しない(文字を大きくしている人でもはみ出さないように)
// ・2.1.3から、押せるマス(link。(行, 列)ごとに押したときの処理)を指定できる。押せるマスは、ほかのリンクと同じ
//   緑の下線の文字にし、マス全体を押せるようにする。指定しなければ今まで通り(エースの配置の選手の名前で使う)
// ------------------------------------------------------------

const Color _waku = Color(0xFF161616);
const Color _sen = Color(0xFF333333);
const Color _honbunIro = Color(0xFFDDDDDD);

class KijiHyouView extends StatelessWidget {
  final KijiHyou hyou;

  /// 上の余白(記事の本文の途中に置く表は狭くする)
  final double ue;

  /// 押せるマス((行, 列)。行は見出しの行を除いて0から。2.1.3)。nullなら押せるマスはない
  final Map<(int, int), VoidCallback>? link;

  const KijiHyouView(this.hyou, {super.key, this.ue = 24, this.link});

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
                for (int r = 0; r < hyou.gyou.length; r++)
                  TableRow(
                    children: [
                      for (int i = 0; i < hyou.retsu.length; i++)
                        _masuWidget(
                          masu,
                          i < hyou.gyou[r].length ? hyou.gyou[r][i] : '',
                          mojiStyle,
                          link?[(r, i)],
                        ),
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

/// 1つのマス([osu]があれば、緑の下線の文字にして、マス全体を押せるようにする。2.1.3)
Widget _masuWidget(
  Widget Function(String s, TextStyle st) masu,
  String s,
  TextStyle st,
  VoidCallback? osu,
) {
  if (osu == null) return masu(s, st);
  return InkWell(
    onTap: osu,
    child: masu(
      s,
      st.copyWith(
        color: _linkIro,
        decoration: TextDecoration.underline,
        decorationColor: _linkIro,
      ),
    ),
  );
}

/// 押せるマスの文字の色(ほかのリンクと同じ緑。HENSUU.LinkColor)
const Color _linkIro = Color.fromARGB(255, 0, 255, 0);
