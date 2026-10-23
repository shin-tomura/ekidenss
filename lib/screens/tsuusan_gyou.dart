import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/tsuusan.dart';
import 'package:ekiden/kansuu/kiji/kiji_kihon.dart' show KijiHyou;
import 'package:ekiden/screens/kiji_hyou_view.dart'; // 表(記事の表と同じ見た目)

// ------------------------------------------------------------
// 選手画面の「通算」の行と「歴代記録」の表(2.1.4。中身は kansuu/tsuusan.dart)
// ・選手画面・選手の詳細の小窓・卒業生の画面の、三大駅伝と対校戦の成績の表のすぐ上に出す
// ・通算は1行の Text にして、文字を大きくしていても折り返せるようにする(横に並べない)
// ・歴代記録の表は、記事の表と同じ見た目(KijiHyouView。横にはみ出すときは横にスクロールする)
// ・記録と選手は通算の番号で結びつける(2.1.4)。番号のない記録(2.1.4より前に出た記録)が並びに残っているあいだは、
//   表の下(表がなければ通算の行の下)に、そのことを1行で書く
// ・出すことがなければ何も出さない
// ------------------------------------------------------------

class TsuusanGyou extends StatelessWidget {
  const TsuusanGyou(this.sozai, {super.key});

  final TsuusanSozai sozai;

  @override
  Widget build(BuildContext context) {
    final List<String> gyou = tsuusanGyou(sozai);
    final ({KijiHyou? hyou, bool furuiAri}) r = rekidaiHyou(sozai);
    final KijiHyou? hyou = r.hyou;
    if (gyou.isEmpty && hyou == null && !r.furuiAri) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final String g in gyou)
            Text(
              g,
              style: const TextStyle(
                color: Colors.white,
                fontSize: HENSUU.fontsize_honbun,
              ),
            ),
          if (hyou != null) KijiHyouView(hyou, ue: gyou.isEmpty ? 0 : 8),
          if (r.furuiAri)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '※2.1.4より前に出た記録は、選手と結びつけられないため、この表には出ません。',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
