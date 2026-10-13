import 'package:flutter/material.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';
import 'package:ekiden/screens/Modal_matrix.dart';

// ------------------------------------------------------------
// よく使う画面を開く、目立つボタン(1.9.9)
// ・区間配置確認(水色・一覧のアイコン)と、今季タイム一覧表(オレンジ・表のアイコン)
// ・ほかの緑の下線のリンクより目立つ、枠とアイコン付きの丸いボタンにした
// ・各画面のリンクの列の一番上に、KakuninButtons で2つを横に並べて置く(入りきらなければ折り返す)
//   区間配置確認: レース中・当日変更・目標順位の設定・直前順位予想・結果・他大学変更
//   今季タイム一覧表: 上の画面と、大学画面・区間エントリー決定・出場メンバーを選ぶ画面と、
//   箱庭モードの他大学のエントリーの画面
// ------------------------------------------------------------

/// 区間配置確認と今季タイム一覧表のボタンを横に並べる(入りきらなければ折り返す)
/// [kukanHaiti]・[konkiTime]がfalseなら、そのボタンは出さない
class KakuninButtons extends StatelessWidget {
  /// 最初に表示する大学
  final int targetUnivid;
  final bool kukanHaiti;
  final bool konkiTime;
  const KakuninButtons({
    super.key,
    required this.targetUnivid,
    this.kukanHaiti = true,
    this.konkiTime = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!kukanHaiti && !konkiTime) return const SizedBox.shrink();
    // ListViewの中では真ん中、Columnの中ではColumnの寄せ方に合わせて置かれる(ほかのリンクと同じ)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          if (kukanHaiti) KukanHaitiKakuninButton(targetUnivid: targetUnivid),
          if (konkiTime) KonkiTimeIchiranButton(targetUnivid: targetUnivid),
        ],
      ),
    );
  }
}

/// 区間配置確認を開くボタン
class KukanHaitiKakuninButton extends StatelessWidget {
  /// 最初に表示する大学
  final int targetUnivid;
  const KukanHaitiKakuninButton({super.key, required this.targetUnivid});

  @override
  Widget build(BuildContext context) {
    return MedatsuButton(
      label: '区間配置確認',
      icon: Icons.view_list,
      iro: Colors.cyanAccent,
      barrierLabel: '区間配置確認',
      gamen: () => ModalKukanHaitiView(targetUnivid: targetUnivid),
    );
  }
}

/// 今季タイム一覧表を開くボタン(表の上のバーの大学名を押すと、ほかの大学に切り替えられる)
class KonkiTimeIchiranButton extends StatelessWidget {
  /// 最初に表示する大学
  final int targetUnivid;
  const KonkiTimeIchiranButton({super.key, required this.targetUnivid});

  @override
  Widget build(BuildContext context) {
    return MedatsuButton(
      label: '今季タイム一覧表',
      icon: Icons.table_chart,
      iro: Colors.orangeAccent,
      barrierLabel: '今季タイム一覧表',
      gamen: () => ModalUnivSenshuMatrixView(targetUnivId: targetUnivid),
    );
  }
}

/// 枠とアイコン付きの丸いボタン(押すと[gamen]の画面を開く)
/// 選手画面の夏合宿の金特訓・銀特訓・金銀交換のボタンでも使う(1.9.9)
class MedatsuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iro;
  final String barrierLabel;
  final Widget Function() gamen;
  const MedatsuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.iro,
    required this.barrierLabel,
    required this.gamen,
  });

  @override
  Widget build(BuildContext context) {
    // 横いっぱいに広がらないように、Rowで包んで中身の幅にする
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: OutlinedButton.icon(
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierColor: Colors.black.withOpacity(0.8), // モーダルの背景色
                barrierDismissible: true, // 背景タップで閉じられるようにする
                barrierLabel: barrierLabel, // アクセシビリティ用ラベル
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, animation, secondaryAnimation) => gamen(),
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
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
            icon: Icon(icon, color: iro),
            label: Text(
              label,
              style: TextStyle(color: iro, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: iro, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}
