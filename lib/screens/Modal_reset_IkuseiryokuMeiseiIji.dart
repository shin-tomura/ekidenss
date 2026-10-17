import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスをインポート
import 'package:ekiden/screens/reset_ichiran_gamen.dart'
    show resetIchiranGamenHiraku; // リセットで残るもの・戻るもの(2.0.3)

// ------------------------------------------------------------
// 「名声・育成力と設定を残してやり直す」の確認の画面(2.0.2までは「名声と育成力は維持しつつリセットしてやり直す」)
// ・はいを押すと mode を101010にし、main.dart の _runMode101010Processing でリセットする
// ・2.0.3から、何を残すかは lib/kansuu/reset_ichiran.dart の一覧で決める(ゲームの進み具合だけを消し、
//   名声・育成力・名声の横並びと、レースや育成などの設定、表示の好みは残す)。基本的にはこちらをおすすめする
// ・「残るもの・戻るものの一覧」から、一覧表の画面を開ける
// ------------------------------------------------------------

class ModalReset_IkuseiryokuMeiseiIji extends StatefulWidget {
  const ModalReset_IkuseiryokuMeiseiIji({super.key});

  @override
  State<ModalReset_IkuseiryokuMeiseiIji> createState() =>
      _ModalReset_IkuseiryokuMeiseiIji();
}

class _ModalReset_IkuseiryokuMeiseiIji
    extends State<ModalReset_IkuseiryokuMeiseiIji> {
  ButtonStyle get _botan => ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    minimumSize: const Size(200, 48),
    padding: const EdgeInsets.all(12.0),
  );

  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    const String title = '名声・育成力と設定を残してやり直す';

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text(title, style: TextStyle(color: Colors.white)),
              backgroundColor: HENSUU.backgroundcolor,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Text(
                'データがありません',
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        const TextStyle honbun = TextStyle(
          color: HENSUU.textcolor,
          fontSize: HENSUU.fontsize_honbun,
        );
        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
          appBar: AppBar(
            title: const Text(title, style: TextStyle(color: Colors.white)),
            backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
            foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
          ),
          // 文字を大きくしても、はみ出さずにスクロールできるようにする(2.0.3)
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // 中央寄せ
                children: <Widget>[
                  const Text(
                    '選手・記録・年月日などのゲームの進み具合を消して、1年目からやり直します。\n'
                    '名声・育成力・名声の横並びと、レースや育成などの設定、表示の好みはそのまま残ります。'
                    'アルバムも消去されます。\n'
                    '基本的には、こちらのリセットをおすすめします。',
                    style: honbun,
                    textAlign: TextAlign.center, // テキストを中央寄せ
                  ),
                  const SizedBox(height: 8),
                  // 残るもの・戻るものの一覧(reset_ichiran_gamen.dart)
                  TextButton(
                    onPressed: () => resetIchiranGamenHiraku(context),
                    child: const Text(
                      '残るもの・戻るものの一覧',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 255, 0),
                        decoration: TextDecoration.underline,
                        decorationColor: HENSUU.textcolor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('本当にやり直しますか？', style: honbun, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  // 「はい」ボタン
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        // UIを更新するためsetStateで囲む
                        currentGhensuu.mode = 101010;
                      });
                      await currentGhensuu.save(); // Hiveに保存
                      if (context.mounted) Navigator.pop(context); // モーダルを閉じる
                    },
                    style: _botan,
                    child: const Text(
                      'はい',
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32), // スペース
                  const Divider(color: Colors.grey), // Divider
                  const SizedBox(height: 32), // スペース
                  // 「いいえ、やっぱりリセットしません。」ボタン
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // モーダルを閉じる
                    },
                    style: _botan,
                    child: const Text(
                      'いいえ、やっぱりリセットしません。',
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
