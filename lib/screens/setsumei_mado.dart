import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart'; // HENSUU
import 'package:ekiden/kansuu/shiyou_text.dart'
    show shiyouShushou, bokouPipeSetsumeiGyou;

// ------------------------------------------------------------
// 説明の窓と、それを開くリンク(2.0.1)
// ・説明の文は説明書と同じもの(shiyou_text.dart)を使う。設定に合わせた文になる
// ・主将とは: 大学画面の主将の行と、選手画面の主将の欄(仕組みは lib/kansuu/shushou.dart)
// ・母校パイプとは: 大学画面の監督の出身校の行と、高校名鑑の「この高校出身の大学の監督」
//   (説明書の「名声」の中の母校パイプの部分。仕組みは lib/kansuu/bokou_pipe.dart)
// ------------------------------------------------------------

/// 題[title]と文[gyou](1行に1つ)の説明の窓を開く
Future<void> setsumeiMadoHiraku(
  BuildContext context, {
  required String title,
  required List<String> gyou,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: const TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: Text(
          gyou.join('\n'),
          style: const TextStyle(color: Colors.black),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}

/// 説明の窓を開くリンク(文は押したときに作る。設定を変えたあとでも、今の設定の文になるように)
class SetsumeiLink extends StatelessWidget {
  const SetsumeiLink({
    super.key,
    required this.label,
    required this.title,
    required this.gyou,
    this.fontSize = HENSUU.fontsize_honbun,
  });

  /// リンクの文字(「主将とは」など)
  final String label;

  /// 説明の窓の題
  final String title;

  /// 説明の窓の文を作る
  final List<String> Function() gyou;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => setsumeiMadoHiraku(context, title: title, gyou: gyou()),
      child: Text(
        label,
        style: TextStyle(
          color: HENSUU.LinkColor,
          decoration: TextDecoration.underline,
          decorationColor: HENSUU.textcolor,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

List<String> _shushouGyou() => shiyouShushou(setsumeisho: true).gyou;

/// 「主将とは」のリンク(説明書の「主将」と同じ文)
class ShushouSetsumeiLink extends StatelessWidget {
  const ShushouSetsumeiLink({super.key});

  @override
  Widget build(BuildContext context) {
    return const SetsumeiLink(label: '主将とは', title: '主将', gyou: _shushouGyou);
  }
}

/// 「母校パイプとは」のリンク(説明書の「名声」の中の、監督の母校パイプの部分と同じ文)
class BokouPipeSetsumeiLink extends StatelessWidget {
  const BokouPipeSetsumeiLink({super.key, this.fontSize = HENSUU.fontsize_honbun});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SetsumeiLink(
      label: '母校パイプとは',
      title: '監督の母校パイプ',
      gyou: bokouPipeSetsumeiGyou,
      fontSize: fontSize,
    );
  }
}
