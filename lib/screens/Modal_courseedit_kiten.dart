import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスのために必要
import 'package:ekiden/univ_data.dart'; // UnivDataクラスのインポート
import 'package:ekiden/screens/Modal_courseedit.dart'; // 編集画面のパスを適宜修正

class RaceCourseEditSelectionView extends StatelessWidget {
  const RaceCourseEditSelectionView({super.key});

  /// コース編集モーダルを表示する関数
  void _showCourseEditModal(BuildContext context, int racebangou) {
    showModalBottomSheet(
      context: context,
      //isScrollControlled: true, // モーダルを全画面近くまで広げる
      builder: (BuildContext context) {
        // ModalCourseEditView2 を呼び出す
        return ModalCourseEditView2(racebangou: racebangou);
      },
    );
  }

  /// Hiveから大学名を取得し、編集オプションリストを構築するメソッド
  List<Map<String, dynamic>> _getRaceOptions() {
    // 1. UnivData Boxを開く (※事前に Hive.init() と Boxの登録・開放が必要です)
    final univDataBox = Hive.box<UnivData>('univBox');

    // 2. UnivDataをIDでソートして取得
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

    // 3. racebangou=5 に使用する大学短縮名を取得
    String customRaceName = 'カスタム駅伝'; // デフォルト名
    if (sortedUnivData.isNotEmpty) {
      customRaceName = sortedUnivData[0].name_tanshuku;
    }

    // 4. 編集対象のレースオプションリストを構築 (0, 1, 2, 5 のみ)
    return [
      {'name': '10月駅伝', 'racebangou': 0},
      {'name': '11月駅伝', 'racebangou': 1},
      {'name': '正月駅伝', 'racebangou': 2},
      {'name': customRaceName, 'racebangou': 5},
    ];
  }

  /// 駅伝編集ボタンを生成するウィジェット
  Widget _buildEditButton(BuildContext context, String name, int racebangou) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 9, 100, 2), // ボタンの背景色を濃い青に変更
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
              return ModalCourseEditView2(racebangou: racebangou);
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
              '$name のコース編集',
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

  @override
  Widget build(BuildContext context) {
    // buildメソッド内で動的なオプションリストを取得
    final List<Map<String, dynamic>> raceOptions = _getRaceOptions();

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text('区間コース編集対象選択', style: TextStyle(color: Colors.white)),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 子要素を幅いっぱいに広げる
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 24.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  "編集したい駅伝コースを選択してください。予選のコースは編集できません。なお、カスタム駅伝はカスタム駅伝設定から区間数の変更もできます。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),

              // 各駅伝の選択ボタン
              ...raceOptions.map((option) {
                return _buildEditButton(
                  context,
                  option['name'] as String,
                  option['racebangou'] as int,
                );
              }).toList(),

              const SizedBox(height: 32),

              // 閉じる/戻るボタン
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(200, 48),
                  padding: const EdgeInsets.all(12.0),
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
