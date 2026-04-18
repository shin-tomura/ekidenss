import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Hive for data storage
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスをインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスをインポート
import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスをインポート

class UnivSelectionScreen extends StatelessWidget {
  const UnivSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hive Boxにアクセス
    final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
    final Box<UnivData> univBox = Hive.box<UnivData>('univBox');

    // ValueListenableBuilder を使用して、ghデータの変更を監視しUIを自動更新
    // univdataは通常この画面で変更されないため、ghensuuBoxの変更のみを監視し、
    // univBoxのデータは直接取得します。
    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final Ghensuu? currentGhensuu = ghensuuBox.get('global_ghensuu');

        // Ghensuuデータがまだ存在しない場合（通常はアプリ起動時に初期化されるべき）
        if (currentGhensuu == null) {
          // ローディング表示など、適切なエラーハンドリングまたは待機表示を実装
          return const Center(child: CircularProgressIndicator());
        }

        final Ghensuu gh = currentGhensuu;

        // sortedunivdata の準備 (SwiftUIのcomputed propertyに相当する処理)
        List<UnivData> sortedUnivdata = univBox.toMap().values.toList();
        sortedUnivdata.sort((a, b) => a.id.compareTo(b.id));

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
                    "大学選択",
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
                            "あなたが監督をする大学を選択してください。なお、上の方に表示されている大学の方が名声の初期値が高くなっていますので難易度は低めになりやすいです。ただ、ランダムの要素も多いので、絶対的な難易度ではないです。",
                            style: TextStyle(color: HENSUU.textcolor),
                            textAlign: TextAlign.center, // テキストを中央寄せ
                          ),
                          const SizedBox(height: 20), // 縦方向のスペース
                          // 大学選択ボタンを動的に生成
                          // TEISUU.UNIVSUU の数だけボタンを生成します。
                          ...List.generate(TEISUU.UNIVSUU, (number) {
                            // sortedUnivdata の長さが TEISUU.UNIVSUU より少ない場合の安全策
                            // （データが完全にロードされていない、または不足している場合を考慮）
                            if (number >= sortedUnivdata.length) {
                              return const SizedBox.shrink(); // 空のウィジェットを返す
                            }
                            final UnivData univ = sortedUnivdata[number];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  // ghオブジェクトの MYunivid と mode プロパティを更新
                                  gh.MYunivid = number;
                                  gh.mode = 25; // 大学選択後はモード25へ遷移
                                  await gh.save(); // HiveにGhensuuオブジェクトの変更を保存
                                  print(
                                    '大学選択: MYunivid=${gh.MYunivid}, mode=${gh.mode}',
                                  );

                                  // ここで直接画面遷移をトリガーするのではなく、
                                  // main.dart の MyApp ウィジェットで gh.mode の変更を検知し、
                                  // 適切な画面に自動遷移するように設計されています。
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
                                  univ.name,
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
