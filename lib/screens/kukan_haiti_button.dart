import 'package:flutter/material.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';

// ------------------------------------------------------------
// 区間配置確認を開くボタン(1.9.9)
// よく使う画面なので、ほかの緑の下線のリンクより目立つ、枠とアイコン付きのボタンにした。
// 区間配置確認のある画面(レース中・当日変更・目標順位の設定・直前順位予想・結果・他大学変更)で、
// リンクの列の一番上に置く
// ------------------------------------------------------------

class KukanHaitiKakuninButton extends StatelessWidget {
  /// 最初に表示する大学
  final int targetUnivid;
  const KukanHaitiKakuninButton({super.key, required this.targetUnivid});

  @override
  Widget build(BuildContext context) {
    // 横いっぱいに広がらないように、Rowで包んで中身の幅にする
    // (ListViewの中では真ん中、Columnの中ではColumnの寄せ方に合わせて置かれる。ほかのリンクと同じ)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: _button(context)),
        ],
      ),
    );
  }

  Widget _button(BuildContext context) {
    return OutlinedButton.icon(
        onPressed: () {
          showGeneralDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
            barrierDismissible: true, // 背景タップで閉じられるようにする
            barrierLabel: '区間配置確認', // アクセシビリティ用ラベル
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) {
              return ModalKukanHaitiView(targetUnivid: targetUnivid);
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              );
            },
          );
        },
        icon: const Icon(Icons.view_list, color: Colors.cyanAccent),
        label: const Text(
          '区間配置確認',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
    );
  }
}
