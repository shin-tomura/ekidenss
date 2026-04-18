import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Hive Flutter パッケージ

// モデルとユーティリティ関数のパスをアプリ名に合わせて調整してください
// 修正されたインポートパス
import 'package:ekiden/ghensuu.dart'; // lib/ghensuu.dart にあることを想定
import 'package:ekiden/senshu_data.dart'; // lib/senshu_data.dart にあることを想定
import 'package:ekiden/univ_data.dart'; // lib/univ_data.dart にあることを想定
import 'package:ekiden/kansuu/kojinBestKirokuJuniKettei.dart'; // lib/kansuu/kojinBestKirokuJuniKettei.dart にあることを想定
import 'package:ekiden/constants.dart';
import 'package:ekiden/kansuu/ChartPanelSenshu.dart';
import 'package:ekiden/kansuu/ChartPanelUniv.dart';

/// 大学選択確認画面
/// Swiftのz0025UnivsentakukakuninViewに相当します。
class UnivSelectionConfirmationScreen extends StatefulWidget {
  const UnivSelectionConfirmationScreen({super.key});

  @override
  State<UnivSelectionConfirmationScreen> createState() =>
      _UnivSelectionConfirmationScreenState();
}

class _UnivSelectionConfirmationScreenState
    extends State<UnivSelectionConfirmationScreen> {
  // 既に開かれているHive Boxのインスタンスへの参照
  late Box<Ghensuu> _ghensuuBox;
  late Box<UnivData> _univdataBox;
  late Box<SenshuData> _senshudataBox;

  // データが割り当てられたかを追跡するフラグ
  bool _isDataAssigned = false;
  bool _isLoading = false;
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
      _univdataBox = Hive.box<UnivData>('univBox');
      _senshudataBox = Hive.box<SenshuData>('senshuBox');

      setState(() {
        _isDataAssigned = true; // Boxの割り当て完了
      });
    } catch (e) {
      // Boxがまだ開かれていない場合のエラーハンドリング
      // 通常、main()関数で確実に開かれているはずですが、念のため
      print(
        "Error assigning Hive Boxes: $e. Make sure they are opened in main.dart.",
      );
      // エラーメッセージを表示するか、リトライを促すUIを表示することもできます
    }
  }

  /// SenshuDataのリストをID昇順にソートして返します。
  List<SenshuData> _getSortedSenshuData(List<SenshuData> senshuDataList) {
    // 元のリストを変更しないようにコピーを作成
    var sortedList = List<SenshuData>.from(senshuDataList);
    sortedList.sort((a, b) => a.id.compareTo(b.id));
    return sortedList;
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
              ), // HENSUU.textcolor を使用
            ),
          );
        }

        // UnivDataとSenshuDataは、それぞれのBoxから現在の値を取得
        final univdata = _univdataBox.values.toList();
        final senshudata = _senshudataBox.values.toList();

        // ID順にソートされたデータリストを作成
        final sortedSenshuData = _getSortedSenshuData(senshudata);
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
          backgroundColor: HENSUU.backgroundcolor, // HENSUU.backgroundcolor を使用
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 中央揃え
              children: [
                const Spacer(), // 上部の余白
                const Text(
                  "選択確認",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun, // Swiftの.font(.title)に相当
                    //fontWeight: FontWeight.bold,
                    color: HENSUU.textcolor, // HENSUU.textcolor を使用
                  ),
                ),
                const SizedBox(height: 30), // スペーサー
                const Text(
                  "あなたが監督をする大学は",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun,
                    color: HENSUU.textcolor,
                  ), // HENSUU.textcolor を使用
                ),
                Text(
                  sortedUnivData[gh[0].MYunivid].name, // gh[0].MYunivid を使用
                  style: const TextStyle(
                    fontSize:
                        HENSUU.fontsize_honbun, // Swiftの.font(.largeTitle)に相当
                    fontWeight: FontWeight.w900,
                    color: HENSUU.textcolor, // HENSUU.textcolor を使用
                  ),
                ),
                const Text(
                  "でよろしいですか？",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun,
                    color: HENSUU.textcolor,
                  ), // HENSUU.textcolor を使用
                ),
                const SizedBox(height: 50), // スペーサー
                // はいボタン
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() {
                              _isLoading = true; // 2. ローディング開始
                            });

                            // 1. まず、kojinBestKirokuJuniKettei関数を実行
                            kojinBestKirokuJuniKettei(0, gh, sortedSenshuData);

                            // 2. Ghensuuオブジェクトのhyojiunivnumを更新
                            gh[0].hyojiunivnum = gh[0].MYunivid;
                            // ここではまだ mode は変更しない！

                            // 3. GhensuuオブジェクトとSenshuDataの変更を先に全て保存
                            // await を使うことで、この保存処理が完了するまで次の行へは進まないことが保証されます。
                            //await gh[0]
                            //    .save(); // Ghensuuのhyojiunivnum変更をディスクに保存

                            // kojinBestKirokuJuniKettei関数で変更されたSenshuDataも保存
                            for (var senshu in sortedSenshuData) {
                              await senshu.save(); // 各SenshuDataの変更をディスクに保存
                            }

                            await updateAllSenshuChartdata_atusataisei();
                            await refreshAllUnivAnalysisData();

                            // 4. 全ての save() が完了した後に、画面遷移をトリガーする mode を変更し、それを保存する
                            // これで、他の場所で mode の変更を監視していても、データ保存が完了した後に遷移が始まります。
                            gh[0].mode = 27;
                            await gh[0].save(); // modeの変更をディスクに保存 (必須)

                            // もし明示的な画面遷移を行う場合は、上記の gh[0].save() の後に記述します。
                            // 例: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NextScreenBasedOnMode27()));

                            print(
                              '「はい」ボタンが押されました。順位計算とデータ保存が完了し、モード変更も保存されました。',
                            );
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.green, // テキスト色に合わせる
                              strokeWidth: 3.0,
                            ),
                          )
                        : const Text("はい"),
                  ),
                ),
                const SizedBox(height: 20), // ボタン間のスペース
                // いいえボタン
                SizedBox(
                  width: 200, // Swiftの.frame(width: 200)に相当
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            // モードを設定し、Ghensuuオブジェクトを保存
                            gh[0].mode = 20; // 例: 前の画面に戻るモード
                            await gh[0].save(); // 変更をHiveに永続化

                            // ここに画面遷移などの次のアクションを追加できます
                            print('「いいえ」ボタンが押されました。モードが変更されました。');
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text("いいえ"),
                  ),
                ),
                const Spacer(), // 下部の余白
                const Divider(color: HENSUU.textcolor), // HENSUU.textcolor を使用
              ],
            ),
          ),
        );
      },
    );
  }
}
