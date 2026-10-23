import 'package:flutter/material.dart';
import 'package:ekiden/screens/Modal_kukanhaiti2.dart';
import 'package:ekiden/screens/Modal_matrix.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/screens/Modal_aceHaichi.dart'
    show AceBamen, ModalAceHaichi, aceHaichiTaishou; // エースの配置(2.1.3)

// ------------------------------------------------------------
// よく使う画面を開く、目立つボタン(1.9.9)
// ・区間配置確認(水色・一覧のアイコン)と、今季タイム一覧表(オレンジ・表のアイコン)
// ・ほかの緑の下線のリンクより目立つ、枠とアイコン付きの丸いボタンにした
// ・各画面のリンクの列の一番上に、KakuninButtons で2つを横に並べて置く(入りきらなければ折り返す)
// ・2.1.3から、駅伝のレース前の画面(直前順位予想・当日変更・スタート前)とレースの指示の画面では、
//   エースの配置(ピンク・星のアイコン)も並べる
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

  /// 区間エントリーの画面か(2.1.2。今季タイム一覧表のメモから「メモどおり配置する」を選べる)
  final bool kukanEntry;

  /// エースの配置のボタンを出す画面(2.1.3。直前順位予想・当日変更・スタート前だけ。nullなら出さない。
  /// 駅伝(10月・11月・正月・カスタム)のときだけ出る。Modal_aceHaichi.dart)
  final AceBamen? aceBamen;
  const KakuninButtons({
    super.key,
    required this.targetUnivid,
    this.kukanHaiti = true,
    this.konkiTime = true,
    this.kukanEntry = false,
    this.aceBamen,
  });

  @override
  Widget build(BuildContext context) {
    if (!kukanHaiti && !konkiTime && aceBamen == null) return const SizedBox.shrink();
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
          if (konkiTime) KonkiTimeIchiranButton(targetUnivid: targetUnivid, kukanEntry: kukanEntry),
          if (aceBamen != null) AceHaichiButton(bamen: aceBamen!),
        ],
      ),
    );
  }
}

/// エースの配置を開くボタン(2.1.3。駅伝のときだけ出す。Modal_aceHaichi.dart)
class AceHaichiButton extends StatelessWidget {
  final AceBamen bamen;
  const AceHaichiButton({super.key, required this.bamen});

  @override
  Widget build(BuildContext context) {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').get('global_ghensuu');
    if (gh == null || !aceHaichiTaishou(gh.hyojiracebangou)) {
      return const SizedBox.shrink();
    }
    return MedatsuButton(
      label: 'エースの配置',
      icon: Icons.stars,
      iro: Colors.pinkAccent,
      barrierLabel: 'エースの配置',
      gamen: () => ModalAceHaichi(bamen: bamen),
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

  /// 区間エントリーの画面か(2.1.2。今季タイム一覧表のメモから「メモどおり配置する」を選べる)
  final bool kukanEntry;
  const KonkiTimeIchiranButton({super.key, required this.targetUnivid, this.kukanEntry = false});

  @override
  Widget build(BuildContext context) {
    return MedatsuButton(
      label: '今季タイム一覧表',
      icon: Icons.table_chart,
      iro: Colors.orangeAccent,
      barrierLabel: '今季タイム一覧表',
      gamen: () => ModalUnivSenshuMatrixView(targetUnivId: targetUnivid, kukanEntry: kukanEntry),
    );
  }
}

/// 枠とアイコン付きの丸いボタン(押すと[gamen]の画面を開く)
/// 選手画面の夏合宿の金特訓・銀特訓・金銀交換のボタンでも使う(1.9.9)。
/// 区間適性の見立て(紫。Modal_kukanTekisei.dart の KukanTekiseiLink)でも使う(2.1.1)
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
