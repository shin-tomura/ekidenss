import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';

// ------------------------------------------------------------
// 設定画面の説明の枠(1.9.8)
// ・見出しと最初の段落(何をする設定か)はいつも見せ、残りは「詳しい説明」をタップすると開く
// ・初めは閉じておき、設定のところまで長くスクロールしなくて済むようにする
// ・コンピュータ金銀使用・コンピュータスカウト・区間配置の方針の画面で使う
// ------------------------------------------------------------

class SetsumeiOritatami extends StatelessWidget {
  /// いつも見せる部分(見出しと最初の段落)
  final String youyaku;

  /// 「詳しい説明」を開くと出る部分
  final String shousai;

  const SetsumeiOritatami({
    super.key,
    required this.youyaku,
    required this.shousai,
  });

  @override
  Widget build(BuildContext context) {
    const TextStyle moji = TextStyle(
      color: HENSUU.textcolor,
      fontSize: HENSUU.fontsize_honbun,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(youyaku, style: moji, textAlign: TextAlign.left),
          // 開いたとき・閉じたときの区切り線を出さない
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: HENSUU.LinkColor,
              collapsedIconColor: HENSUU.LinkColor,
              title: const Text(
                '詳しい説明',
                style: TextStyle(
                  color: HENSUU.LinkColor,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
              children: [Text(shousai, style: moji, textAlign: TextAlign.left)],
            ),
          ),
        ],
      ),
    );
  }
}
