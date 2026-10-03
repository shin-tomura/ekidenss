import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/gakuren_text.dart';
import 'package:ekiden/screens/Modal_matrix.dart';

/// 学連選抜のテキストをワンタッチでコピーするボタン(1.8.2)
/// 生成AIに渡して、実況や区間配置・指示の相談を楽しめるようにする。
/// 文は lib/kansuu/gakuren_text.dart で作る
class GakurenCopyButton extends StatelessWidget {
  /// true: 区間配置のテキスト、false: レース経過のテキスト
  final bool kukanHaiti;

  const GakurenCopyButton({super.key, this.kukanHaiti = false});

  Future<void> _copy(BuildContext context) async {
    final Ghensuu? gh = Hive.box<Ghensuu>('ghensuuBox').getAt(0);
    if (gh == null) return;
    final String text = kukanHaiti
        ? gakurenKukanHaitiText(gh)
        : gakurenRaceKeikaText(gh);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kukanHaiti ? '学連選抜の区間配置をコピーしました' : '学連選抜のレース経過をコピーしました',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _copy(context),
      icon: const Icon(Icons.copy, size: 18, color: HENSUU.LinkColor),
      label: Text(
        kukanHaiti ? '学連選抜の区間配置をコピー' : '学連選抜のレース経過をコピー',
        style: const TextStyle(
          color: HENSUU.LinkColor,
          fontSize: HENSUU.fontsize_honbun - 2,
        ),
      ),
    );
  }
}

/// 学連選抜の今季タイム一覧表を開くリンク(1.8.2)
/// 学連選抜のメンバーの今季の成績と能力の表。テキストでコピーして生成AIとの相談にも使える
class GakurenKonkiTimeLink extends StatelessWidget {
  const GakurenKonkiTimeLink({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.8),
          barrierDismissible: true,
          barrierLabel: '学連選抜の今季タイム一覧表',
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return const ModalUnivSenshuMatrixView(
              targetUnivId: -1,
              gakuren: true,
            );
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
        );
      },
      child: const Text(
        "学連選抜の今季タイム一覧表",
        style: TextStyle(
          color: HENSUU.LinkColor,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
