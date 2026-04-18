import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Hive for data storage
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/constants.dart'; // HENSUUクラスなどをインポート

class NanidoSelectionScreen extends StatelessWidget {
  const NanidoSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

    // ValueListenableBuilder を使用して、ghデータの変更を監視しUIを自動更新
    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, box, _) {
        // gh[0] に相当する Ghensuu オブジェクトを取得
        Ghensuu? currentGhensuu = box.get('global_ghensuu');

        // nullチェック後の使用
        // currentGhensuuがnullの場合、アプリの初期化シーケンスに問題がある可能性があります。
        // ここでは便宜上 ! を使いますが、より堅牢なアプリではローディング表示などを検討してください。
        final Ghensuu gh = currentGhensuu!;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.grey[900], // AppBarの背景色
            centerTitle: false, // leadingとtitleの配置を調整するためfalseに
            titleSpacing: 0.0, // leadingとtitleの間のスペースをなくす
            toolbarHeight: 20.0, // 例: 高さを80ピクセルに増やす
            // 左側に2つの文字列を縦に並べる
          ),
          backgroundColor: HENSUU.backgroundcolor, // 画面全体を黒にする
          // SafeArea をbodyの直下に配置することで、ノッチやステータスバーとの干渉を防ぎます
          body: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: HENSUU.backgroundcolor, // 背景色を constants.dart から取得
              child: Column(
                children: <Widget>[
                  Text(
                    "難易度選択",
                    style: TextStyle(
                      fontSize: HENSUU.fontsize_honbun,
                      //fontWeight: FontWeight.bold,
                      color: HENSUU.textcolor, // 文字色を constants.dart から取得
                    ),
                  ),
                  Expanded(
                    // SingleChildScrollView でコンテンツが画面からはみ出た場合にスクロール可能にする
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          Text(
                            "年度ごとの定期的な理事会からの支援や目標順位達成の際の獲得金銀量が変わってきます。\n後からでも、大学画面の下の方のリンクから変更できます。",
                            style: TextStyle(color: HENSUU.textcolor),
                            textAlign: TextAlign.center, // テキストを中央寄せ
                          ),
                          const SizedBox(height: 20), // 縦方向のスペース
                          // 難易度選択ボタンを動的に生成
                          ...List.generate(4, (number) {
                            String difficultyText;
                            if (number == 0) {
                              difficultyText = "鬼";
                            } else if (number == 1) {
                              difficultyText = "難しい";
                            } else if (number == 2) {
                              difficultyText = "普通";
                            } else {
                              // number == 3
                              difficultyText = "易しい";
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  // ghオブジェクトの kazeflag と mode プロパティを更新
                                  gh.kazeflag = number;
                                  gh.mode = 20; // 難易度選択後はモード20（大学選択）へ
                                  await gh.save(); // HiveにGhensuuオブジェクトの変更を保存
                                  print(
                                    '難易度設定: kazeflag=${gh.kazeflag}, mode=${gh.mode}',
                                  );

                                  // ここで直接画面遷移をトリガーするのではなく、
                                  // main.dart の MyApp ウィジェットで gh.mode の変更を検知し、
                                  // 適切な画面 (UnivSelectionScreen) に自動遷移するように設計されています。
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green, // ボタンの背景色
                                  foregroundColor: Colors.black, // ボタンのテキスト色
                                  minimumSize: const Size(200, 48), // ボタンの最小サイズ
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      8,
                                    ), // ボタンの角丸
                                  ),
                                ),
                                child: Text(
                                  difficultyText,
                                  style: const TextStyle(
                                    fontSize: HENSUU.fontsize_honbun,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  // 最下部の区切り線
                  const Divider(color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
