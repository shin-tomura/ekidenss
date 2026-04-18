import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Hive Flutter パッケージ

// モデルのインポートパス
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';

// 定数クラスのインポート
import 'package:ekiden/constants.dart';

/// 大学名入力画面
/// Swiftのz0030FirstUnivnameinputViewに相当します。
class FirstUnivNameInputScreen extends StatefulWidget {
  const FirstUnivNameInputScreen({super.key});

  @override
  State<FirstUnivNameInputScreen> createState() =>
      _FirstUnivNameInputScreenState();
}

class _FirstUnivNameInputScreenState extends State<FirstUnivNameInputScreen> {
  // Hive Boxのインスタンスへの参照
  late Box<Ghensuu> _ghensuuBox;
  late Box<UnivData> _univdataBox;

  // データが割り当てられたかを追跡するフラグ
  bool _isDataAssigned = false;

  // テキストフィールドのコントローラ
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _text2Controller =
      TextEditingController(); // Swiftコードにはtext2が使われているため追加

  @override
  void initState() {
    super.initState();
    _assignHiveBoxes(); // アプリ起動時に開かれたBoxを割り当てる

    // テキストフィールドの変更を監視し、文字数制限を適用
    _textController.addListener(_limitTextLength);
  }

  @override
  void dispose() {
    _textController.removeListener(_limitTextLength);
    _textController.dispose();
    _text2Controller.dispose(); // コントローラを破棄
    super.dispose();
  }

  /// 既に開かれているHive Boxのインスタンスをフィールドに割り当てます。
  void _assignHiveBoxes() {
    try {
      _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      _univdataBox = Hive.box<UnivData>('univBox');

      setState(() {
        _isDataAssigned = true; // Boxの割り当て完了
      });

      // 初期値として現在の大学名を設定（編集のため）
      _setInitialText();
    } catch (e) {
      print(
        "Error assigning Hive Boxes in FirstUnivNameInputScreen: $e. Make sure they are opened in main.dart.",
      );
    }
  }

  /// テキストフィールドに現在の大学名を設定します。
  void _setInitialText() {
    if (_isDataAssigned && _ghensuuBox.isNotEmpty && _univdataBox.isNotEmpty) {
      final gh = _ghensuuBox.values.toList();
      final univdata = _univdataBox.values.toList();
      final sortedUnivData = _getSortedUnivData(univdata);

      if (gh.isNotEmpty &&
          gh[0].MYunivid >= 0 &&
          gh[0].MYunivid < sortedUnivData.length) {
        _textController.text = sortedUnivData[gh[0].MYunivid].name;
        _text2Controller.text =
            sortedUnivData[gh[0].MYunivid].name_tanshuku; // name_tanshukuも設定
      }
    }
  }

  /// テキストフィールドの文字数制限を適用します (最大20文字)
  void _limitTextLength() {
    if (_textController.text.length > 20) {
      _textController.text = _textController.text.substring(0, 20);
      // カーソルを末尾に移動
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
  }

  /// UnivDataのリストをID昇順にソートして返します。
  List<UnivData> _getSortedUnivData(List<UnivData> univDataList) {
    var sortedList = List<UnivData>.from(univDataList);
    sortedList.sort((a, b) => a.id.compareTo(b.id));
    return sortedList;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataAssigned) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ValueListenableBuilder<Box<Ghensuu>>(
      valueListenable: _ghensuuBox.listenable(),
      builder: (context, ghensuuBox, _) {
        final gh = ghensuuBox.values.toList();

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

        final univdata = _univdataBox.values.toList();
        final sortedUnivData = _getSortedUnivData(univdata);

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
          backgroundColor: HENSUU.backgroundcolor,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  "あなたの大学名入力",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun, // .font(.title)
                    //fontWeight: FontWeight.bold,
                    color: HENSUU.textcolor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "「大学」を除いて入力してください",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun,
                    color: HENSUU.textcolor,
                  ),
                ),
                Text(
                  "最大5文字までの入力を推奨",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun,
                    color: HENSUU.textcolor,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: "ここに入力",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // RoundedBorderTextFieldStyle に相当
                    ),
                    fillColor: Colors.white, // TextFieldの背景色を白に
                    filled: true,
                  ),
                  keyboardType: TextInputType.text, // .default
                  style: const TextStyle(color: Colors.black), // 文字色を黒に設定
                  // onChange の代わりに Controller の Listener で文字数制限を実装済み
                ),
                const SizedBox(height: 20), // Spacer の代わりに適切な SizedBox を入れる
                // Swiftコードに text2 があるため、TextField2 も追加
                // ただし、UI上のラベルはSwiftコードにないので、ここでは追加していません。
                // 必要であれば適宜追加してください。
                /*
                Text(
                  "短縮名入力（任意）",
                  style: TextStyle(fontSize: HENSUU.fontsize_honbun, color: HENSUU.textcolor),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _text2Controller,
                  decoration: InputDecoration(
                    hintText: "短縮名（例: 東大）",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.text,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                */

                // 決定ボタン
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () async {
                      // 現在の大学データオブジェクトを取得し、名前を更新
                      final UnivData currentUniv =
                          sortedUnivData[gh[0].MYunivid];
                      currentUniv.name = _textController.text;
                      //currentUniv.name_tanshuku =
                      // _text2Controller.text; // text2も更新

                      // 大学データを保存
                      await currentUniv.save(); // Hiveに永続化

                      // mode を設定し、Ghensuuオブジェクトを保存
                      gh[0].mode = 35; // 次の画面へ進むモード
                      await gh[0].save(); // 変更をHiveに永続化

                      print('「決定」ボタンが押されました。大学名とモードが保存されました。');
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
                    child: const Text("決定"),
                  ),
                ),
                const Spacer(),
                const Divider(color: HENSUU.textcolor),
              ],
            ),
          ),
        );
      },
    );
  }
}
