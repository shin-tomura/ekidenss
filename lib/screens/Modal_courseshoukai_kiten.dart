import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスのために必要
import 'package:ekiden/screens/Modal_courseshoukai.dart'; // ModalCourseshoukaiViewのパスを適宜修正
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポートを追加
import 'package:ekiden/ghensuu.dart'; // Hive.box<Ghensuu>('ghensuuBox') が存在する場合を考慮

// 🚨 補足: Hive Boxは通常main()関数内で事前に開かれている必要がありますが、
// ここではHive.box()が成功することを前提とします。

class RaceCourseSelectionView extends StatelessWidget {
  const RaceCourseSelectionView({super.key});

  /// 駅伝選択ボタンを生成するウィジェット
  Widget _buildRaceButton(BuildContext context, String name, int racebangou) {
    // 💡 ボタンのスタイルを定義
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.indigo, // ボタンの背景色を濃い青に変更
      foregroundColor: Colors.white, // テキストやアイコンの色を白に変更
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // 角丸を大きく
      ),
      minimumSize: const Size(double.infinity, 56), // 幅いっぱいに広げ、高さを確保
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      elevation: 4, // 影をつける
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          // モーダルを表示するロジック
          showGeneralDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.8),
            barrierDismissible: true,
            barrierLabel: '駅伝コース紹介',
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) {
              return ModalCourseshoukaiView(racebangou: racebangou);
            },
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              );
            },
          );
        },
        style: buttonStyle, // 💡 スタイルを適用
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // テキストとアイコンを両端に配置
          children: [
            Text(
              '$name のコース紹介',
              style: TextStyle(
                fontSize: HENSUU.fontsize_honbun,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18), // 💡 視認性のためのアイコン追加
          ],
        ),
      ),
    );
  }

  // Hiveから大学名を取得し、レースオプションリストを構築するメソッド
  List<Map<String, dynamic>> _getRaceOptions() {
    // 1. HiveからUnivData Boxを開く
    // ※ Hive.box('univBox') が事前に開かれている必要があります
    final univDataBox = Hive.box<UnivData>('univBox');

    // 2. UnivDataをIDでソートして取得
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    // 3. racebangou=5 に使用する大学短縮名を取得
    String customRaceName = 'カスタム駅伝'; // デフォルト名
    if (sortedUnivData.isNotEmpty) {
      customRaceName = sortedUnivData[0].name_tanshuku;
    }

    // 4. 更新されたレースオプションリストを構築
    return [
      {'name': '10月駅伝', 'racebangou': 0},
      {'name': '11月駅伝', 'racebangou': 1},
      {'name': '正月駅伝', 'racebangou': 2},
      {'name': '11月駅伝予選', 'racebangou': 3},
      {'name': '正月駅伝予選', 'racebangou': 4},
      // ここを動的に取得した大学名に変更
      {'name': customRaceName, 'racebangou': 5},
    ];
  }

  @override
  Widget build(BuildContext context) {
    // buildメソッド内で動的なオプションリストを取得
    final List<Map<String, dynamic>> raceOptions = _getRaceOptions();

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('区間コース選択', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 子要素を幅いっぱいに広げる
            children: <Widget>[
              // 案内メッセージのコンテナ
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 24.0),
                decoration: BoxDecoration(
                  color: Colors.lightGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.lightGreen.withOpacity(0.3)),
                ),
                child: Text(
                  "コース紹介を確認したい駅伝または予選を選択してください。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),

              // 各駅伝の選択ボタン
              // 動的に構築した raceOptions を使用
              ...raceOptions.map((option) {
                return _buildRaceButton(
                  context,
                  option['name'] as String,
                  option['racebangou'] as int,
                );
              }).toList(),

              const SizedBox(height: 32),

              // 閉じる/戻るボタン
              // 💡 閉じるボタンのスタイルを修正
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700, // 💡 少し濃い目のグレーに変更
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // 他のボタンと角丸を統一
                  ),
                  minimumSize: const Size(double.infinity, 56), // 幅と高さを統一
                  padding: const EdgeInsets.all(16.0),
                ),
                child: Text(
                  "閉じる",
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
  }
}
