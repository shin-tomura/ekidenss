import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/senshu_data.dart'; // SenshuDataクラスをインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUUク

class ModalTokkunSilver extends StatefulWidget {
  const ModalTokkunSilver({super.key});

  @override
  State<ModalTokkunSilver> createState() => _ModalTokkunSilverState();
}

class _ModalTokkunSilverState extends State<ModalTokkunSilver> {
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
              title: const Text('銀特訓', style: TextStyle(color: Colors.white)),
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
                    '銀特訓',
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
                title: const Text('銀特訓', style: TextStyle(color: Colors.white)),
                backgroundColor: HENSUU.backgroundcolor,
                foregroundColor: Colors.white,
              ),
              body: Column(
                // SwiftUIのVStackに相当
                children: <Widget>[
                  Text(
                    "${targetSenshu.name}(${targetSenshu.gakunen}) に銀特訓をする 残${currentGhensuu.silverballsuu}",
                    style: TextStyle(
                      color: HENSUU.textcolor,
                      fontSize: HENSUU.fontsize_honbun,
                      //fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(color: Colors.grey),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        // LazyVStackに相当
                        crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                        children: <Widget>[
                          // 長距離粘り (choukyorinebari)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[2] == 1)
                                Text(
                                  "長距離粘り ${targetSenshu.choukyorinebari}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "長距離粘り",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.choukyorinebari <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.choukyorinebari += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.choukyorinebari <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // スパート力 (spurtryoku)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[3] == 1)
                                Text(
                                  "スパート力 ${targetSenshu.spurtryoku}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "スパート力",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.spurtryoku <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.spurtryoku += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.spurtryoku <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // カリスマ (karisuma)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[4] == 1)
                                Text(
                                  "カリスマ ${targetSenshu.karisuma}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "カリスマ",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.karisuma <= 99)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.karisuma += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.karisuma <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 登り適性 (noboritekisei)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[5] == 1)
                                Text(
                                  "登り適性 ${targetSenshu.noboritekisei}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "登り適性",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.noboritekisei <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.noboritekisei += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.noboritekisei <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 下り適性 (kudaritekisei)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[6] == 1)
                                Text(
                                  "下り適性 ${targetSenshu.kudaritekisei}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "下り適性",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.kudaritekisei <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.kudaritekisei += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.kudaritekisei <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // アップダウン対応力 (noborikudarikirikaenouryoku)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // テキストをExpandedで囲むことで、残りのスペースを柔軟に利用させる
                              Expanded(
                                child:
                                    // ★ここを三項演算子に変更します
                                    currentGhensuu.nouryokumieruflag[7] == 1
                                    ? Text(
                                        "アップダウン対応力 ${targetSenshu.noborikudarikirikaenouryoku}",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // 長すぎるテキストを省略
                                        maxLines: 1,
                                      )
                                    : Text(
                                        "アップダウン対応力",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // 長すぎるテキストを省略
                                        maxLines: 1,
                                      ),
                              ), // Expandedの閉じタグ
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu
                                                .noborikudarikirikaenouryoku <=
                                            89)
                                    ? () async {
                                        // ここは元のコードのまま
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!
                                                  .noborikudarikirikaenouryoku +=
                                              10;
                                        });
                                        await currentGhensuu.save();
                                        await targetSenshu!.save();
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu
                                                  .noborikudarikirikaenouryoku <=
                                              89)
                                      ? Colors.green
                                      : Colors.grey,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // ロード適性 (tandokusou)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentGhensuu.nouryokumieruflag[8] == 1)
                                Text(
                                  "ロード適性 ${targetSenshu.tandokusou}",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                )
                              else
                                Text(
                                  "ロード適性",
                                  style: TextStyle(
                                    color: HENSUU.textcolor,
                                    fontSize: HENSUU.fontsize_honbun,
                                  ),
                                ),
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.tandokusou <= 89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.tandokusou += 10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.tandokusou <= 89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(100, 48),
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // ペース変動対応力 (paceagesagetaiouryoku)
                          Row(
                            // SwiftUIのHStackに相当
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // テキストをExpandedで囲むことで、残りのスペースを柔軟に利用させる
                              Expanded(
                                child: // ★ここが変更点：if文で直接ウィジェットを返す
                                currentGhensuu.nouryokumieruflag[9] == 1
                                    ? Text(
                                        "ペース変動対応力 ${targetSenshu.paceagesagetaiouryoku}",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // 長すぎるテキストを省略
                                        maxLines: 1,
                                      )
                                    : Text(
                                        "ペース変動対応力",
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                          fontSize: HENSUU.fontsize_honbun,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // 長すぎるテキストを省略
                                        maxLines: 1,
                                      ),
                              ), // Expandedの閉じタグ
                              ElevatedButton(
                                onPressed:
                                    (currentGhensuu.silverballsuu >= 10 &&
                                        targetSenshu.paceagesagetaiouryoku <=
                                            89)
                                    ? () async {
                                        setState(() {
                                          currentGhensuu.silverballsuu -= 10;
                                          targetSenshu!.paceagesagetaiouryoku +=
                                              10;
                                        });
                                        await currentGhensuu.save(); // Hiveに保存
                                        await targetSenshu!.save(); // Hiveに保存
                                      }
                                    : null, // 条件を満たさない場合はボタンを無効化
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      (currentGhensuu.silverballsuu >= 10 &&
                                          targetSenshu.paceagesagetaiouryoku <=
                                              89)
                                      ? Colors.green
                                      : Colors.grey, // 無効時はグレー
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(
                                    100,
                                    48,
                                  ), // ボタンの最小サイズを保持
                                  padding: const EdgeInsets.all(12.0),
                                ),
                                child: Text(
                                  "10up",
                                  style: TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16), // 要素間のスペース
                          // 注意書きテキスト
                          Text(
                            "※能力値が90以上の場合には、それ以上は能力値を上げられない仕様です。（カリスマは除く）",
                            style: TextStyle(
                              color: HENSUU.textcolor,
                              fontSize: HENSUU.fontsize_honbun! * 0.8, // 少し小さめに
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: Colors.grey),

                  // 戻るボタン
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        // Swiftのコメントアウトされた部分のロジックをDartで実装する場合
                        // if (targetSenshu.choukyorinebari > 99) {
                        //   targetSenshu.choukyorinebari = 99;
                        // }
                        // if (targetSenshu.spurtryoku > 99) {
                        //   targetSenshu.spurtryoku = 99;
                        // }
                        // if (targetSenshu.karisuma > 99) {
                        //   targetSenshu.karisuma = 99;
                        // }
                        // if (targetSenshu.noboritekisei > 99) {
                        //   targetSenshu.noboritekisei = 99;
                        // }
                        // if (targetSenshu.kudaritekisei > 99) {
                        //   targetSenshu.kudaritekisei = 99;
                        // }
                        // if (targetSenshu.noborikudarikirikaenouryoku > 99) {
                        //   targetSenshu.noborikudarikirikaenouryoku = 99;
                        // }
                        // if (targetSenshu.tandokusou > 99) {
                        //   targetSenshu.tandokusou = 99;
                        // }
                        // if (targetSenshu.paceagesagetaiouryoku > 99) {
                        //   targetSenshu.paceagesagetaiouryoku = 99;
                        // }
                        // await targetSenshu.save(); // 変更を保存

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
