import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/reset_ichiran.dart';

// ------------------------------------------------------------
// 「リセットで残るもの・戻るもの」の一覧表の画面(2.0.3)
// 説明画面の設定タブの一番上と、2つのリセットの確認の画面から開く。
// 中身は lib/kansuu/reset_ichiran.dart の一覧から作る(設定を足して一覧に1行書けば、ここにも出る)。
// ・見出しは設定タブの見出しの順(resetMidashiJun)。行ごとに、2つのリセットで残るか戻るかを出す
// ・スマホで文字を大きくしても横にはみ出さないように、表ではなく、名前の下に2つの札を並べる
// ・開発中のビルドだけ、一覧に載っていない予備の番号があれば、一番上に赤字で出す(書き忘れの見張り)
// ------------------------------------------------------------

/// 一覧表の画面を開く
Future<void> resetIchiranGamenHiraku(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => const ResetIchiranGamen()),
  );
}

class ResetIchiranGamen extends StatelessWidget {
  const ResetIchiranGamen({super.key});

  static const TextStyle _honbun = TextStyle(color: HENSUU.textcolor, fontSize: HENSUU.fontsize_honbun);

  /// 札の文字と色(残る・戻る・選び直す)
  static (String, Color) _fuda(ResetBunrui b, {required bool zenbu}) {
    if (b == ResetBunrui.erabinaoshi) return ('選び直す', Colors.lightBlueAccent);
    return resetNokosu(b, zenbu: zenbu)
        ? ('残る', Colors.lightGreenAccent)
        : ('戻る', Colors.orangeAccent);
  }

  Widget _fudaWidget(String reset, ResetBunrui b, {required bool zenbu}) {
    final (String moji, Color iro) = _fuda(b, zenbu: zenbu);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: iro),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$reset: $moji',
        style: TextStyle(color: iro, fontSize: HENSUU.fontsize_honbun - 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<ResetKoumoku> ichiran = resetIchiran();
    final List<String> mitouroku = kDebugMode ? resetMitourokuBangou() : const [];
    final TextStyle hosoku = TextStyle(
      color: HENSUU.textcolor.withOpacity(0.7),
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('リセットで残るもの・戻るもの', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (mitouroku.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '(開発用)reset_ichiran.dart の一覧に載っていない予備の番号があります: ${mitouroku.join('、')}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: HENSUU.fontsize_honbun),
                ),
              ),
            const Text(
              '設定タブの2つのリセットで、何が残り、何が初期値に戻るかの一覧です。',
              style: _honbun,
            ),
            const SizedBox(height: 8),
            const Text(
              '・「名声・育成力と設定を残してやり直す」(おすすめ): 選手・記録・年月日などのゲームの進み具合だけを消して、1年目からやり直します。'
              '名声・育成力・名声の横並びと、レースや育成などの設定は残ります。',
              style: _honbun,
            ),
            const SizedBox(height: 4),
            const Text(
              '・「全てリセットしてやり直す」: 名声・育成力と設定も初期値に戻します。本当に初期値に戻したいときだけ選んでください。',
              style: _honbun,
            ),
            const SizedBox(height: 4),
            const Text(
              '・どちらのリセットでも、表示の好み・大学名・メモなどは残り、アルバム(卒業したOB)は消えます。'
              '難易度と総監督をする大学は、リセットのあとに選び直します。',
              style: _honbun,
            ),
            for (final String midashi in resetMidashiJun) ...[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 4),
                child: Text(
                  midashi,
                  style: const TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun + 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.grey, height: 8),
              for (final ResetKoumoku k in ichiran)
                if (k.midashi == midashi)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(k.mei, style: _honbun.copyWith(fontWeight: FontWeight.bold)),
                        if (k.hosoku.isNotEmpty) Text(k.hosoku, style: hosoku),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _fudaWidget('設定を残すリセット', k.bunrui, zenbu: false),
                            _fudaWidget('全てリセット', k.bunrui, zenbu: true),
                          ],
                        ),
                      ],
                    ),
                  ),
            ],
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
