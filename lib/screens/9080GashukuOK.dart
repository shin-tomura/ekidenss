import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart';

/// OKボタンで次のモードに進む画面
///
/// ユーザーにメッセージを表示し、OKボタンを押すことで次のモードへ遷移します。
class OKButtonScreen extends StatefulWidget {
  const OKButtonScreen({super.key});

  @override
  State<OKButtonScreen> createState() => _OKButtonScreenState();
}

class _OKButtonScreenState extends State<OKButtonScreen> {
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
                  const Text(
                    "夏合宿です！！\n\n選手画面下部の金特訓または銀特訓から各選手の個性を伸ばしましょう！\n\n金特訓と銀特訓はこの時期にしかできません。",
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
                        print('9080画面で「OK」ボタンが押されました。モードが変更されました。');
                        //gh[0].mode = 9100; // 次のモードへ遷移
                        gh[0].mode = 700; // 次のモードへ遷移
                        await gh[0].save(); // 変更をHiveに永続化
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
