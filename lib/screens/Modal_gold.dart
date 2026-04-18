import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスをインポート

import 'package:ekiden/constants.dart'; // TEISUUク

class ModalTokkunGold extends StatefulWidget {
  const ModalTokkunGold({super.key});

  @override
  State<ModalTokkunGold> createState() => _ModalTokkunGoldState();
}

class _ModalTokkunGoldState extends State<ModalTokkunGold> {
  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<SenshuData> senshudataBox = Hive.box<SenshuData>('senshuBox');

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);

        if (currentGhensuu == null) {
          return Scaffold(
            backgroundColor: HENSUU.backgroundcolor,
            appBar: AppBar(
              title: const Text('金特訓', style: TextStyle(color: Colors.white)),
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

        return ValueListenableBuilder<Box<SenshuData>>(
          valueListenable: senshudataBox.listenable(),
          builder: (context, senshudataBox, _) {
            final List<SenshuData> allSenshuData = senshudataBox.values
                .toList();

            // unividが特定のものだけ抽出 (univfilteredsenshudata)
            final List<SenshuData> univFilteredSenshuData = allSenshuData
                .where((s) => s.univid == currentGhensuu.MYunivid)
                .toList();

            // gakunenjununivfilteredsenshudata
            final List<SenshuData> gakunenJunUnivFilteredSenshuData =
                univFilteredSenshuData
                    .toList() // 新しいリストを作成してソート
                  ..sort((a, b) {
                    // 学年を降順で比較 (b.gakunen と a.gakunen を比較)
                    int gakunenCompare = b.gakunen.compareTo(a.gakunen);
                    if (gakunenCompare != 0) {
                      return gakunenCompare; // 学年が異なる場合はその結果を返す
                    }
                    // 学年が同じ場合は、IDを昇順で比較 (a.id と b.id を比較)
                    return a.id.compareTo(b.id);
                  });
            // 編集対象の選手
            SenshuData? targetSenshu;
            if (currentGhensuu.hyojisenshunum >= 0 &&
                currentGhensuu.hyojisenshunum <
                    gakunenJunUnivFilteredSenshuData.length) {
              targetSenshu =
                  gakunenJunUnivFilteredSenshuData[currentGhensuu
                      .hyojisenshunum];
            }

            // targetSenshu が null の場合も考慮
            if (targetSenshu == null) {
              return Scaffold(
                backgroundColor: HENSUU.backgroundcolor,
                appBar: AppBar(
                  title: const Text(
                    '金特訓',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: HENSUU.backgroundcolor,
                  foregroundColor: Colors.white,
                ),
                body: Center(
                  child: Text(
                    '選手データが見つかりません',
                    style: TextStyle(color: HENSUU.textcolor),
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: HENSUU.backgroundcolor,
              appBar: AppBar(
                title: const Text('金特訓', style: TextStyle(color: Colors.white)),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Column(
                // SwiftUIのVStackに相当
                children: <Widget>[
                  Text(
                    "${targetSenshu.name}(${targetSenshu.gakunen}) に金特訓をする 残${currentGhensuu.goldenballsuu}",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      //fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Spacer() の代わりに Expanded を使ってスペースを確保
                  // Expanded(child: SizedBox.shrink()), // 上部のSpacer
                  const Divider(color: Colors.grey),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        // LazyVStackに相当
                        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                        children: <Widget>[
                          const SizedBox(height: 16), // 要素間のスペース
                          // 駅伝男 (Konjou)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[0] == 1)
                                Text(
                                  "駅伝男 ${targetSenshu.konjou}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "駅伝男",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              // Spacer() の代わりに RowのmainAxisAlignment.spaceBetween
                              // ボタン
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.goldenballsuu >= 10 &&
                                        targetSenshu.konjou <= 89)
                                    ? () async {
                                        // setState を呼び出してUIを更新
                                        setState(() {
                                          currentGhensuu.goldenballsuu -= 10;
                                          targetSenshu!.konjou += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.goldenballsuu >= 10 &&
                                          targetSenshu.konjou <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(
                                    100,
                                    48,
                                  ), // Swiftの.frame(width: 100)とpadding()を考慮
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU
                                        .fontsize_honbun, // .font(.headline)に相当
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 平常心 (Heijousin)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[1] == 1)
                                Text(
                                  "平常心 ${targetSenshu.heijousin}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "平常心",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              // Spacer() の代わりに RowのmainAxisAlignment.spaceBetween
                              // ボタン
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.goldenballsuu >= 10 &&
                                        targetSenshu.heijousin <= 89)
                                    ? () async {
                                        // setState を呼び出してUIを更新
                                        setState(() {
                                          currentGhensuu.goldenballsuu -= 10;
                                          targetSenshu!.heijousin += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.goldenballsuu >= 10 &&
                                          targetSenshu.heijousin <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(
                                    100,
                                    48,
                                  ), // Swiftの.frame(width: 100)とpadding()を考慮
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU
                                        .fontsize_honbun, // .font(.headline)に相当
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 安定感 (anteikan)
                          /*Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "安定感 ${targetSenshu.anteikan}",
                                style: TextStyle(
                                  color: HENSUU.textcolor,
                                  fontSize: HENSUU.fontsize_honbun,
                                ),
                              ),
                              // Spacer() の代わりに RowのmainAxisAlignment.spaceBetween
                              // ボタン
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.goldenballsuu >= 10 &&
                                        targetSenshu.anteikan <= 89)
                                    ? () async {
                                        // setState を呼び出してUIを更新
                                        setState(() {
                                          currentGhensuu.goldenballsuu -= 10;
                                          targetSenshu!.anteikan += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.goldenballsuu >= 10 &&
                                          targetSenshu.anteikan <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(
                                    100,
                                    48,
                                  ), // Swiftの.frame(width: 100)とpadding()を考慮
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU
                                        .fontsize_honbun, // .font(.headline)に相当
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),*/
                          // 注意書きテキスト
                          Text(
                            "※能力値が90以上の場合には、それ以上は能力値を上げられない仕様です。",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun! * 0.8, // 少し小さめに
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // SwiftのSpacer() に相当するが、ここでは画面下部の余白は不要なため省略
                  // 必要であれば SizedBox(height: ...) を追加
                  const Divider(color: Colors.grey),

                  // 戻るボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Swiftのコメントアウトされた部分のロジックをDartで実装する場合
                        // if (targetSenshu.konjou > 99) {
                        //   targetSenshu.konjou = 99;
                        // }
                        // if (targetSenshu.heijousin > 99) {
                        //   targetSenshu.heijousin = 99;
                        // }
                        // await targetSenshu.save(); // 変更を保存

                        // try? modelContext.save() に相当
                        // Hiveは変更をすぐに保存するため、明示的なsaveは不要な場合もありますが、
                        // 念のためここでも保存を呼び出します。
                        await currentGhensuu.save();
                        await targetSenshu!.save();

                        Navigator.pop(context); // モーダルを閉じる
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(200, 48),
                        padding: const EdgeInsets.all(12.0),
                      ),
                      child: Text(
                        "戻る",
                        style: TextStyle(
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
