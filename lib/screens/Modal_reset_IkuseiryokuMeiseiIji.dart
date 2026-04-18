import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスをインポート

class ModalReset_IkuseiryokuMeiseiIji extends StatefulWidget {
  const ModalReset_IkuseiryokuMeiseiIji({super.key});

  @override
  State<ModalReset_IkuseiryokuMeiseiIji> createState() =>
      _ModalReset_IkuseiryokuMeiseiIji();
}

class _ModalReset_IkuseiryokuMeiseiIji
    extends State<ModalReset_IkuseiryokuMeiseiIji> {
  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('全リセット', style: TextStyle(color: Colors.white)),
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

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor, // Scaffold全体の背景色
          appBar: AppBar(
            title: const Text('全リセット', style: TextStyle(color: Colors.white)),
            backgroundColor: HENSUU.backgroundcolor, // AppBarの背景色
            foregroundColor: Colors.white, // AppBarのアイコンやテキストの色
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0), // SwiftUIの.padding()に相当
            child: Column(
              // SwiftUIのVStackに相当
              mainAxisAlignment: MainAxisAlignment.center, // 中央寄せ
              crossAxisAlignment: CrossAxisAlignment.center, // 中央寄せ
              children: <Widget>[
                Text(
                  "本当に名声と育成力以外は全てリセットしてやり直しますか？\nアルバムも消去されます。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                    //fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // テキストを中央寄せ
                ),
                const SizedBox(height: 32), // スペース
                // 「はい」ボタン
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      // UIを更新するためsetStateで囲む
                      currentGhensuu.mode = 101010; // gh[0].mode=10; に相当
                    });
                    await currentGhensuu.save(); // Hiveに保存
                    Navigator.pop(context); // モーダルを閉じる
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Swiftの.background(.green)
                    foregroundColor:
                        Colors.black, // Swiftの.foregroundColor(.black)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Swiftの.cornerRadius(8)
                    ),
                    minimumSize: const Size(
                      200,
                      48,
                    ), // Swiftの.frame(width: 200)とpadding()を考慮
                    padding: const EdgeInsets.all(12.0),
                  ),
                  child: Text(
                    "はい",
                    style: TextStyle(
                      fontSize: HENSUU.fontsize_honbun, // .font(.headline)に相当
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Swiftの.background(.green)
                    foregroundColor:
                        Colors.black, // Swiftの.foregroundColor(.black)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Swiftの.cornerRadius(8)
                    ),
                    minimumSize: const Size(
                      200,
                      48,
                    ), // Swiftの.frame(width: 200)とpadding()を考慮
                    padding: const EdgeInsets.all(12.0),
                  ),
                  child: Text(
                    "いいえ、やっぱりリセットしません。",
                    style: TextStyle(
                      fontSize: HENSUU.fontsize_honbun, // .font(.headline)に相当
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
