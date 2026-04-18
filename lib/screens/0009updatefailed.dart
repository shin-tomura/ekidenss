import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';

/// OKボタンで次のモードに進む画面
///
/// ユーザーにメッセージを表示し、OKボタンを押すことで次のモードへ遷移します。
class updatefailedOKButtonScreen extends StatefulWidget {
  const updatefailedOKButtonScreen({super.key});

  @override
  State<updatefailedOKButtonScreen> createState() => _OKButtonScreenState();
}

class _OKButtonScreenState extends State<updatefailedOKButtonScreen> {
  // Hive Boxのインスタンス
  late Box<Ghensuu> _ghensuuBox;

  // データが割り当てられたかを追跡するフラグ
  bool _isDataAssigned = false;

  @override
  void initState() {
    super.initState();
    _assignHiveBoxes();
  }

  /// 既に開かれているHive Boxのインスタンスをフィールドに割り当てます。
  void _assignHiveBoxes() {
    try {
      _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      setState(() {
        _isDataAssigned = true;
      });
    } catch (e) {
      print(
        "Error assigning Hive Boxes in OKButtonScreen: $e. Make sure they are opened in main.dart.",
      );
    }
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
          return const Scaffold(
            body: Center(
              child: Text(
                "Ghensuuデータが見つかりません。アプリを再起動してください。",
                style: TextStyle(color: HENSUU.textcolor),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (gh[0].scoutChances == 9)
                    Text(
                      "データの互換性について\n\n"
                      "バージョン1.3.0以前(1.3.0を含む)からのアップデート、もしくはデータの破損のため、\nデータを読み込めませんでした。\n"
                      "申し訳ありませんが、データを初期化しました。\nご迷惑をおかけし申し訳ございません。",
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        color: HENSUU.textcolor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (gh[0].scoutChances == 7)
                    Text(
                      "インストール成功！",
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        color: HENSUU.textcolor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        gh[0].scoutChances = 3;
                        gh[0].mode = 10; // 次のモードへ遷移
                        await gh[0].save(); // 変更をHiveに永続化
                        print('0009画面で「OK」ボタンが押されました。モードが変更されました。');
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
                      child: const Text("OK"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
