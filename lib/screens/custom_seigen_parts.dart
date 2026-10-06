import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kansuu/custom_seigen.dart';

// ------------------------------------------------------------
// カスタム駅伝の出場制限の画面の部品(1.9.1。決まりは lib/kansuu/custom_seigen.dart)
// ・補った選手のお知らせの枠(一次エントリー・全大学確認・区間エントリーの画面の一番上)
// ・一次エントリーの画面で、選手名の後ろに付ける「出場制限」「補える」
// ------------------------------------------------------------

/// 出場制限で補った選手のお知らせの枠([bun]は customHojuuOshirase の文)
class CustomSeigenOshiraseBox extends StatelessWidget {
  final String bun;
  const CustomSeigenOshiraseBox({super.key, required this.bun});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: Text(
        bun,
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: HENSUU.fontsize_honbun,
        ),
      ),
    );
  }
}

/// 一次エントリーの画面で選手名の後ろに付ける文
/// (出場制限をかけていないときは空。出場できない選手は「出場制限」、補う候補は「補える」)
String customSeigenHyouji(CustomEntryJoukyou? joukyou, SenshuData s) {
  if (joukyou == null) return '';
  if (joukyou.shutsujouKa.any((d) => d.id == s.id)) return '';
  if (joukyou.hojuuKouho(s)) return ' 補える';
  return ' 出場制限';
}
