import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // HiveFlutterを使う場合はこちら
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのパスを適宜修正
import 'package:ekiden/constants.dart'; // HENSUUクラスのパスを適宜修正

class AbilityVisibilityView extends StatefulWidget {
  const AbilityVisibilityView({super.key});

  @override
  State<AbilityVisibilityView> createState() => _AbilityVisibilityViewState();
}

class _AbilityVisibilityViewState extends State<AbilityVisibilityView> {
  late Box<Ghensuu> _ghensuuBox;
  Ghensuu? _ghensuu;

  // 能力の名前リスト (Swiftコードのコメントアウトされた対応する能力名を参考に)
  final List<String> abilityNames = [
    "駅伝男",
    "平常心",
    "長距離粘り",
    "スパート力",
    "カリスマ",
    "登り適性",
    "下り適性",
    "アップダウン対応力",
    "ロード適性", // この能力はSwiftコードに直接記載されていませんが、nouryokumieruflag[8]に対応すると仮定
    "ペース変動対応力", // この能力はSwiftコードに直接記載されていませんが、nouryokumieruflag[9]に対応すると仮定
  ];

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    _ghensuu = _ghensuuBox.getAt(0);
    // Boxが確実に開かれていることを確認してください
  }

  @override
  Widget build(BuildContext context) {
    if (_ghensuu == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Ghensuu currentGhensuu = _ghensuu!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // AppBarの背景色
        centerTitle: false, // leadingとtitleの配置を調整するためfalseに
        titleSpacing: 0.0, // leadingとtitleの間のスペースをなくす
        toolbarHeight: 20.0, // 例: 高さを80ピクセルに増やす
        // 左側に2つの文字列を縦に並べる
      ),
      backgroundColor: HENSUU.backgroundcolor, // 背景色
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "見える化したい能力を選択してください。",
              style: TextStyle(
                color: HENSUU.textcolor,
                fontSize: HENSUU.fontsize_honbun,
              ),
              textAlign: TextAlign.center,
            ),
            //const Spacer(),
            const Divider(color: HENSUU.textcolor),
            Expanded(
              // ScrollViewをExpandedで囲むことで、残りのスペースを埋める
              child: SingleChildScrollView(
                // SwiftのScrollView + LazyVStack に対応
                child: Column(
                  children:
                      List.generate(abilityNames.length, (index) {
                            if (currentGhensuu.nouryokumieruflag[index] == 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    // TextウィジェットをExpandedで囲む
                                    Expanded(
                                      child: Text(
                                        abilityNames[index],
                                        style: TextStyle(
                                          color: HENSUU.textcolor,
                                        ),
                                        overflow: TextOverflow
                                            .ellipsis, // 長すぎるテキストを省略
                                        maxLines: 1, // テキストを1行に制限
                                      ),
                                    ),
                                    // Spacer() は不要になります。Expandedが残りのスペースを埋めるため
                                    // const Spacer(),
                                    _buildVisibilityButton(
                                      currentGhensuu,
                                      index,
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink(); // 条件を満たさない場合は何も表示しない
                          })
                          .where((widget) => widget != const SizedBox.shrink())
                          .toList(), // 空のSizedBoxをフィルタリング
                ),
              ),
            ),
            //const Spacer(),
            // 「無視(見える化しない)」ボタン
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  currentGhensuu.mode = 700; // modeを変更
                });
                await currentGhensuu.save(); // 変更を保存
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Swiftの.blueに対応
                foregroundColor: Colors.black, // Swiftの.blackに対応
                minimumSize: const Size(
                  100,
                  44,
                ), // frame(width: 100)とpadding()を考慮
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // cornerRadius
                ),
              ),
              child: const Text(
                "無視(見える化しない)",
                style: TextStyle(
                  fontSize: HENSUU.fontsize_honbun,
                ), // headlineに対応
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(color: HENSUU.textcolor),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityButton(Ghensuu ghensuu, int index) {
    return ElevatedButton(
      onPressed: () async {
        setState(() {
          ghensuu.nouryokumieruflag[index] = 1; // 該当のフラグを1に設定
          ghensuu.mode = 700; // modeを変更
        });
        await ghensuu.save(); // 変更を保存
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Swiftの.greenに対応
        foregroundColor: Colors.black, // Swiftの.blackに対応
        minimumSize: const Size(100, 44), // frame(width: 100)とpadding()を考慮
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // cornerRadius
        ),
      ),
      child: const Text(
        "見える化",
        style: TextStyle(fontSize: HENSUU.fontsize_honbun), // headlineに対応
        textAlign: TextAlign.center,
      ),
    );
  }
}
