import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // HiveFlutterを使う場合はこちら
import 'package:ekiden/ghensuu.dart'; // Ghensuuクラスのパスを適宜修正
import 'package:ekiden/constants.dart'; // HENSUUクラスのパスを適宜修正
import 'package:ekiden/kantoku_data.dart';
// GhensuuBoxが開いていることを前提とします。
// アプリケーションの起動時にHive.openBox<Ghensuu>('ghensuuBox'); のように開いてください。

class GoldenAcquisitionView extends StatefulWidget {
  const GoldenAcquisitionView({super.key});

  @override
  State<GoldenAcquisitionView> createState() => _GoldenAcquisitionViewState();
}

class _GoldenAcquisitionViewState extends State<GoldenAcquisitionView> {
  // Hive BoxからGhensuuオブジェクトを取得します
  // Boxを直接参照するか、Providersなどで提供されるGhensuuオブジェクトを受け取る形にするのが良いでしょう。
  // ここではシンプルにBoxから取得します。
  late Box<Ghensuu> _ghensuuBox;
  Ghensuu? _ghensuu; // null許容型として初期化

  @override
  void initState() {
    super.initState();
    _ghensuuBox = Hive.box<Ghensuu>('ghensuuBox'); // Box名を指定
    _ghensuu = _ghensuuBox.getAt(0); // GhensuuはBoxに一つだけ存在すると仮定
    // もしBoxがまだ開かれていない場合は、ここでエラーになる可能性があります。
    // その場合は、アプリの起動時に確実にBoxが開かれるようにしてください。
  }

  @override
  Widget build(BuildContext context) {
    // _ghensuuがnullの場合はローディング表示などを行うことができます
    if (_ghensuu == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // gh[0] の代わりに _ghensuu を直接使用します
    final Ghensuu currentGhensuu = _ghensuu!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900], // AppBarの背景色
        centerTitle: false, // leadingとtitleの配置を調整するためfalseに
        titleSpacing: 0.0, // leadingとtitleの間のスペースをなくす
        toolbarHeight: 20.0, // 例: 高さを80ピクセルに増やす
        // 左側に2つの文字列を縦に並べる
      ),
      backgroundColor: HENSUU.backgroundcolor, // 背景色を設定
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Spacer(),
            const Divider(color: HENSUU.textcolor), // SwiftのDividerに対応
            Text(
              _getMessage(currentGhensuu),
              style: TextStyle(color: HENSUU.textcolor),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            const Divider(color: HENSUU.textcolor),
            _getAwardText(currentGhensuu),
            const Text(""), // Swiftの空のText()に対応
            const Text(""), // Swiftの空のText()に対応
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _handleOkButtonPress(currentGhensuu);
                });
                // 変更をHiveに保存
                await currentGhensuu.save(); // Ghensuuオブジェクトの変更を保存
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HENSUU.buttonColor, // 背景色
                foregroundColor: HENSUU.buttonTextColor, // テキスト色
                minimumSize: const Size(
                  200,
                  44,
                ), // frame(width: 200)とpadding()を考慮
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // cornerRadius
                ),
              ),
              child: const Text(
                "OK",
                style: TextStyle(
                  fontSize: HENSUU.fontsize_honbun,
                ), // largeTitleをfontSizeで指定
              ),
            ),
            const Spacer(),
            const Divider(color: HENSUU.textcolor),
          ],
        ),
      ),
    );
  }

  // SwiftのロジックをDartの関数に分割
  String _getMessage(Ghensuu ghensuu) {
    if (ghensuu.month == 4 && ghensuu.day == 5) {
      return "大学理事会からの今年度の支援金銀です。";
    } else if (ghensuu.last_goldenballkakutokusuu == 9) {
      return "大学当局が危機を感じて、支援をしてくれました！";
    } else {
      return "チーム目標順位クリア！！";
    }
  }

  Widget _getAwardText(Ghensuu ghensuu) {
    TextStyle baseStyle = TextStyle(color: HENSUU.textcolor);
    TextStyle titleStyle = TextStyle(
      fontSize: HENSUU.fontsize_honbun,
      color: HENSUU.textcolor,
    ); // .font(.title)に対応

    if (ghensuu.last_goldenballkakutokusuu == 9) {
      final kantokuBox = Hive.box<KantokuData>('kantokuBox');
      final KantokuData kantoku = kantokuBox.get('KantokuData')!;
      int temp = 20 * kantoku.yobiint2[12];
      return Text(
        "大学当局から 銀 ${temp} の支援を受けました。",
        style: titleStyle,
        textAlign: TextAlign.center,
      );
    } else {
      if (ghensuu.last_goldenballkakutokusuu > 0) {
        return Text(
          "金　${ghensuu.last_goldenballkakutokusuu}　獲得！",
          style: titleStyle,
          textAlign: TextAlign.center,
        );
      } else if (ghensuu.last_silverballkakutokusuu > 0) {
        return Text(
          "銀　${ghensuu.last_silverballkakutokusuu}　獲得！",
          style: titleStyle,
          textAlign: TextAlign.center,
        );
      } else {
        return Text("");
      }
    }
  }

  void _handleOkButtonPress(Ghensuu ghensuu) {
    if (ghensuu.month == 4 && ghensuu.day == 5) {
      ghensuu.last_goldenballkakutokusuu = 0;
      ghensuu.last_silverballkakutokusuu = 0;
      //ghensuu.scoutChances = 3;
      ghensuu.mode = 100;
      //ghensuu.mode = 9000;
    } else if (ghensuu.last_silverballkakutokusuu == 9) {
      ghensuu.last_goldenballkakutokusuu = 0;
      ghensuu.last_silverballkakutokusuu = 0;
      ghensuu.mode = 700;
    } else {
      ghensuu.last_goldenballkakutokusuu = 0;
      ghensuu.last_silverballkakutokusuu = 0;
      // nouryokumieruflag の全ての要素が1かどうかをチェック
      bool allNouryokuFlagsAreOne = true;
      for (int i = 0; i < 10; i++) {
        // Swiftコードの gh[0].nouryokumieruflag[9] までに合わせる
        if (ghensuu.nouryokumieruflag[i] != 1) {
          allNouryokuFlagsAreOne = false;
          break;
        }
      }

      if (allNouryokuFlagsAreOne) {
        ghensuu.mode = 700;
      } else {
        ghensuu.mode = 8890;
      }
    }
  }
}
