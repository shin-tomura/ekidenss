import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスをインポート
import 'package:ekiden/screens/reset_ichiran_gamen.dart'
    show resetIchiranGamenHiraku, resetSaiKakunin; // リセット・ロード・QRで残るもの・変わるもの(2.0.3)。もう一度確かめるダイアログ(2.0.4)
import 'package:ekiden/kansuu/reset_ichiran.dart'
    show nokosuResetMeiseiShokikaMode; // 名声は初期値に戻すときのモード(2.1.1)

// ------------------------------------------------------------
// 「名声・育成力と設定を残してやり直す」の確認の画面(2.0.2までは「名声と育成力は維持しつつリセットしてやり直す」)
// ・はいを押すと mode を101010にし、main.dart の _runMode101010Processing でリセットする
// ・2.0.3から、何を残すかは lib/kansuu/reset_ichiran.dart の一覧で決める(ゲームの進み具合だけを消し、
//   名声・育成力・名声の横並びと、レースや育成などの設定、表示の好みは残す)。基本的にはこちらをおすすめする
// ・「残るもの・戻るものの一覧」から、一覧表の画面を開ける
// ・2.0.4から、はいを押したあとに、もう一度確かめるダイアログを出す(reset_ichiran_gamen.dart の resetSaiKakunin)
// ・2.1.1から、「名声は初期値に戻す」を選べる(毎回チェックなしから始める)。選んだときは mode を101011にし、
//   同じリセットで、名声と名声の履歴だけ新しいゲームと同じにする(育成力と設定は残す。起動したときの画面の
//   新規ゲーム(99First.dart)にも同じチェックがある)
// ------------------------------------------------------------

class ModalReset_IkuseiryokuMeiseiIji extends StatefulWidget {
  const ModalReset_IkuseiryokuMeiseiIji({super.key});

  @override
  State<ModalReset_IkuseiryokuMeiseiIji> createState() =>
      _ModalReset_IkuseiryokuMeiseiIji();
}

class _ModalReset_IkuseiryokuMeiseiIji
    extends State<ModalReset_IkuseiryokuMeiseiIji> {
  // 「名声は初期値に戻す」を選んでいるか(2.1.1。毎回チェックなしから始める)
  bool _meiseiShokika = false;

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
                  Text(
                    '選手・記録・年月日などのゲームの進み具合を消して、1年目からやり直します。\n'
                    '${_meiseiShokika ? '名声は初期値に戻します。育成力' : '名声・育成力'}'
                    '・名声の横並びと、レースや育成などの設定、表示の好みはそのまま残ります。'
                    'アルバムも消去されます。\n'
                    '基本的には、こちらのリセットをおすすめします。',
                    style: honbun,
                    textAlign: TextAlign.center, // テキストを中央寄せ
                  ),
                  const SizedBox(height: 8),
                  // 名声は初期値に戻す(2.1.1。文が長くても折り返すように、CheckboxListTile にする)
                  CheckboxListTile(
                    value: _meiseiShokika,
                    onChanged: (bool? v) {
                      setState(() {
                        _meiseiShokika = v ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: Colors.green,
                    side: const BorderSide(color: Colors.white70),
                    title: const Text('名声は初期値に戻す', style: honbun),
                    subtitle: const Text(
                      '新しいゲームと同じ名声にします(大学を選ぶ画面の並びで上の大学ほど高い)。名声の内訳も消えます。',
                      style: TextStyle(color: Colors.white70),
                    ),
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
                      // もう一度確かめる(2.0.4。やめたら、この画面に戻る)
                      if (!await resetSaiKakunin(
                        context,
                        zenbu: false,
                        meiseiShokika: _meiseiShokika,
                      )) {
                        return;
                      }
                      if (!context.mounted) return;
                      setState(() {
                        // UIを更新するためsetStateで囲む
                        // (名声は初期値に戻すときは101011。2.1.1)
                        currentGhensuu.mode = _meiseiShokika
                            ? nokosuResetMeiseiShokikaMode
                            : 101010;
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
