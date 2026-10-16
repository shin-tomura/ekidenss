import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart'; // HENSUU
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/koukou.dart' show koukouProfileBunkatsu;
import 'package:ekiden/screens/Modal_koukouMeikan.dart'
    show koukouPageHirakuBan;

// ------------------------------------------------------------
// 出身地・趣味と、出身校・高校時代の文(2.0.1。選手画面・選手の詳細の小窓・卒業アルバムのOBの画面)
// ・1.9.5からは1つの文の塊だったが、出身校の行だけをリンクの色にして、押すと高校名鑑のその高校の
//   ページを開くようにした(大学画面の監督の出身校と同じ)
// ・行の間はあけず、今までと同じ見た目で並べる(場所を増やさない)
// ・表示しない設定のときと、出身校が分からない選手は、今まで通り出身地・趣味の文だけ
// ・2.0.3から、高校のページの卒業生から開いた小窓では [modoruBan] にその高校の番号を渡し、
//   出身校がその高校なら、新しく開かずに小窓を閉じて高校のページに戻る(何重にも重ならないように)
// ------------------------------------------------------------

class ShusshinKoukouBun extends StatelessWidget {
  const ShusshinKoukouBun({
    super.key,
    required this.shumi,
    required this.samusataisei,
    required this.hirou,
    required this.kantoku,
    this.modoruBan,
    this.style = const TextStyle(
      color: Colors.white,
      fontSize: HENSUU.fontsize_honbun,
    ),
  });

  /// 出身地・趣味の文(空のこともある)
  final String shumi;

  /// 選手の samusataisei(出身地・趣味・出身校が入っている)
  final int samusataisei;

  /// 留学生の印(1なら留学生)
  final int hirou;

  final KantokuData kantoku;

  /// この高校のページから開いた小窓なら、その高校の名簿の番号(2.0.3。なければnull)。
  /// 出身校がこの番号なら、押すと小窓を閉じてそのページに戻る
  final int? modoruBan;

  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final ({String koukou, String jidai, int ban})? b = koukouProfileBunkatsu(
      samusataisei,
      hirou,
      kantoku,
    );
    if (b == null) return Text(shumi, style: style);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shumi.isNotEmpty) Text(shumi, style: style),
        // 押すと高校名鑑のその高校のページを開く(名門校でなくても開ける)。
        // その高校のページから開いた小窓なら、小窓を閉じてそのページに戻る(2.0.3)
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (b.ban == modoruBan) {
              Navigator.of(context).pop();
            } else {
              koukouPageHirakuBan(context, b.ban);
            }
          },
          child: Text(
            b.koukou,
            style: style.copyWith(color: HENSUU.LinkColor),
          ),
        ),
        if (b.jidai.isNotEmpty) Text(b.jidai, style: style),
      ],
    );
  }
}
