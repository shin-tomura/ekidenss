import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart'; // HENSUU
import 'package:ekiden/kansuu/shiyou_text.dart' show shiyouShushou;

// ------------------------------------------------------------
// 主将の説明(2.0.1。大学画面の主将の行と、選手画面の主将の欄に置く「主将とは」のリンク)
// ・説明の文は、説明書タブの「主将」の見出しと同じ(shiyou_text.dart の shiyouShushou)。
//   主将の特典の設定や、目標順位の補正の強さに合わせた文になる
// ・仕組みは lib/kansuu/shushou.dart
// ------------------------------------------------------------

/// 主将の説明の窓を開く
Future<void> shushouSetsumeiHiraku(BuildContext context) {
  final String bun = shiyouShushou(setsumeisho: true).gyou.join('\n');
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('主将', style: TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: Text(bun, style: const TextStyle(color: Colors.black)),
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

/// 「主将とは」のリンク(押すと主将の説明の窓を開く)
class ShushouSetsumeiLink extends StatelessWidget {
  const ShushouSetsumeiLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => shushouSetsumeiHiraku(context),
      child: Text(
        '主将とは',
        style: TextStyle(
          color: HENSUU.LinkColor,
          decoration: TextDecoration.underline,
          decorationColor: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
    );
  }
}
