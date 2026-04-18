import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Hive Flutter パッケージ

// モデルのインポートパス
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';

// 定数クラスのインポート
import 'package:ekiden/constants.dart';

/// 大学名称確認画面
/// Swiftのz0035FirstunivnamekakuninViewに相当します。
class FirstUnivNameConfirmationScreen extends StatefulWidget {
  const FirstUnivNameConfirmationScreen({super.key});

  @override
  State<FirstUnivNameConfirmationScreen> createState() =>
      _FirstUnivNameConfirmationScreenState();
}

class _FirstUnivNameConfirmationScreenState
    extends State<FirstUnivNameConfirmationScreen> {
  // 既に開かれているHive Boxのインスタンスへの参照
  late Box<Ghensuu> _ghensuuBox;
  late Box<UnivData> _univdataBox;

  // データが割り当てられたかを追跡するフラグ
  bool _isDataAssigned = false;

  @override
  void initState() {
    super.initState();
    _assignHiveBoxes(); // アプリ起動時に開かれたBoxを割り当てる
  }

  /// 既に開かれているHive Boxのインスタンスをフィールドに割り当てます。
  /// Hive Boxは通常、アプリのメイン関数で一度開かれ、共有されます。
  void _assignHiveBoxes() {
    try {
      _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      _univdataBox = Hive.box<UnivData>('univBox'); // Box名を 'univBox' に合わせる

      setState(() {
        _isDataAssigned = true; // Boxの割り当て完了
      });
    } catch (e) {
      // Boxがまだ開かれていない場合のエラーハンドリング
      print(
        "Error assigning Hive Boxes in FirstUnivNameConfirmationScreen: $e. Make sure they are opened in main.dart.",
      );
      // 必要に応じてユーザーにエラーを通知するUIを表示
    }
  }

  /// UnivDataのリストをID昇順にソートして返します。
  List<UnivData> _getSortedUnivData(List<UnivData> univDataList) {
    // 元のリストを変更しないようにコピーを作成
    var sortedList = List<UnivData>.from(univDataList);
    sortedList.sort((a, b) => a.id.compareTo(b.id));
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    // Boxがまだ割り当てられていない場合は、ローディング表示
    if (!_isDataAssigned) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // GhensuuBoxの変更をリッスンし、UIを自動更新
    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: _ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final gh = ghensuuBox.values.toList();

        // Ghensuuデータがない場合のエラーハンドリング
        if (gh.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text("エラー")),
            body: const Center(
              child: Text(
                "Ghensuuデータが見つかりません。アプリを再起動してください。",
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        // UnivDataはbuildメソッド内で常に最新のBoxから取得
        final univdata = _univdataBox.values.toList();
        final sortedUnivData = _getSortedUnivData(univdata);

        // gh[0].MYunivid が有効なインデックス範囲内にあるか確認
        if (gh[0].MYunivid < 0 || gh[0].MYunivid >= sortedUnivData.length) {
          return Scaffold(
            appBar: AppBar(title: const Text("エラー")),
            body: Center(
              child: Text(
                "無効な大学IDです: ${gh[0].MYunivid}。データを確認してください。",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // UIの構築
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.grey[900], // AppBarの背景色
            centerTitle: false, // leadingとtitleの配置を調整するためfalseに
            titleSpacing: 0.0, // leadingとtitleの間のスペースをなくす
            toolbarHeight: 20.0, // 例: 高さを80ピクセルに増やす
            // 左側に2つの文字列を縦に並べる
          ),
          backgroundColor:
              HENSUU.backgroundcolor, // SwiftのHENSUU.backgroundcolor
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 中央揃え
              children: [
                const Spacer(), // 上部の余白
                const Text(
                  "確認",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun, // Swiftの.font(.title)に相当
                    //fontWeight: FontWeight.bold,
                    color: HENSUU.textcolor,
                  ),
                ),
                const SizedBox(height: 30), // スペーサー
                const Text(
                  "あなたが監督をする大学の名称は",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun,
                    color: HENSUU.textcolor,
                  ),
                ),
                Text(
                  sortedUnivData[gh[0].MYunivid].name, // gh[0].MYunivid を使用
                  style: const TextStyle(
                    fontSize:
                        HENSUU.fontsize_honbun, // Swiftの.font(.largeTitle)に相当
                    fontWeight: FontWeight.w900,
                    color: HENSUU.textcolor,
                  ),
                ),
                // 略称部分はSwiftコードでコメントアウトされているため、ここでもコメントアウト
                /*
                const SizedBox(height: 10),
                const Text(
                  "略称は",
                  style: TextStyle(fontSize: HENSUU.fontsize_honbun, color: HENSUU.textcolor),
                ),
                Text(
                  sortedUnivData[gh[0].MYunivid].name_tanshuku,
                  style: const TextStyle(
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.w900,
                    color: HENSUU.textcolor,
                  ),
                ),
                */
                const SizedBox(height: 10),
                const Text(
                  "でよろしいですか？",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun,
                    color: HENSUU.textcolor,
                  ),
                ),
                const SizedBox(height: 50), // スペーサー
                // はいボタン
                SizedBox(
                  width: 200, // Swiftの.frame(width: 200)に相当
                  child: ElevatedButton(
                    onPressed: () async {
                      // mode を設定し、Ghensuuオブジェクトを保存
                      gh[0].mode = 100; // 次の画面へ進むモード
                      await gh[0].save(); // 変更をHiveに永続化

                      print('「はい」ボタンが押されました。モードが100に設定されました。');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          HENSUU.buttonColor, // Swiftの.background(.green)
                      foregroundColor: HENSUU
                          .buttonTextColor, // Swiftの.foregroundColor(.black)
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // Swiftの.cornerRadius(8)
                      ),
                      minimumSize: const Size(
                        double.infinity,
                        0,
                      ), // Swiftの.frame(maxWidth: .infinity)
                      textStyle: const TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                      ), // Swiftの.font(.largeTitle)
                    ),
                    child: const Text("はい"),
                  ),
                ),
                const SizedBox(height: 20), // ボタン間のスペース
                // いいえボタン
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () async {
                      // mode を設定し、Ghensuuオブジェクトを保存
                      gh[0].mode = 30; // 大学名入力画面に戻るモード
                      await gh[0].save(); // 変更をHiveに永続化

                      print('「いいえ」ボタンが押されました。モードが30に設定されました。');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HENSUU.buttonColor,
                      foregroundColor: HENSUU.buttonTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 0),
                      textStyle: const TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                    ),
                    child: const Text("いいえ"),
                  ),
                ),
                const Spacer(), // 下部の余白
                const Divider(color: HENSUU.textcolor), // SwiftのDivider()
              ],
            ),
          ),
        );
      },
    );
  }
}
