// lib/screens/latest_screen.dart

import 'package:flutter/material.dart';
import 'package:ekiden/ghensuu.dart'; // Ghensuuモデルのインポート
import 'package:ekiden/constants.dart'; // 色の定数

// 各モードに対応するコンポーネントをインポート

import 'package:ekiden/screens/latest_screen_contents/mode0100_content.dart';
import 'package:ekiden/screens/latest_screen_contents/mode0300_content.dart';
import 'package:ekiden/screens/latest_screen_contents/mode0330_content.dart';
import 'package:ekiden/screens/latest_screen_contents/mode0350_content.dart';
import 'package:ekiden/screens/latest_screen_contents/mode0700_content.dart';
import 'package:ekiden/screens/latest_screen_contents/mode0150_content.dart';
import 'package:ekiden/screens/latest_screen_contents/mode1111_content.dart';
import 'package:ekiden/screens/latest_screen_contents/mode0280_content.dart';
import 'package:ekiden/screens/latest_screen_contents/mode0290.dart';

String _dayToString(int day) {
  switch (day) {
    case 5:
      return '上旬';
    case 15:
      return '中旬';
    case 25:
      return '下旬';
    default:
      return '';
  }
}

class LatestScreen extends StatelessWidget {
  final Ghensuu ghensuu;
  final VoidCallback? onAdvanceMode; // mode 200 用のコールバック

  const LatestScreen({
    super.key,
    required this.ghensuu, // Ghensuuオブジェクトを必須で受け取ります
    this.onAdvanceMode,
  });

  @override
  Widget build(BuildContext context) {
    // ghensuu.mode の値に基づいて、表示するウィジェットを切り替える
    Widget contentWidget;

    switch (ghensuu.mode) {
      case 100:
        // mode 100 の場合は、onAdvanceMode コールバックも渡す
        contentWidget = Mode0100Content(
          ghensuu: ghensuu,
          onAdvanceMode: onAdvanceMode,
        );
        break;
      case 150:
        // mode 100 の場合は、onAdvanceMode コールバックも渡す
        contentWidget = Mode0150Content(
          ghensuu: ghensuu,
          onAdvanceMode: onAdvanceMode,
        );
        break;
      case 280:
        // mode 100 の場合は、onAdvanceMode コールバックも渡す
        contentWidget = Mode0280Content(
          ghensuu: ghensuu,
          onAdvanceMode: onAdvanceMode,
        );
        break;
      case 290:
        // mode 100 の場合は、onAdvanceMode コールバックも渡す
        contentWidget = Mode0290Content(
          ghensuu: ghensuu,
          onAdvanceMode: onAdvanceMode,
        );
        break;
      case 343:
        // mode 100 の場合は、onAdvanceMode コールバックも渡す
        contentWidget = Mode0280Content(
          ghensuu: ghensuu,
          onAdvanceMode: onAdvanceMode,
        );
        break;
      case 1111:
        // mode 100 の場合は、onAdvanceMode コールバックも渡す
        contentWidget = Mode1111Content(
          ghensuu: ghensuu,
          onAdvanceMode: onAdvanceMode,
        );
        break;
      case 110:
        // mode 100 の場合は、onAdvanceMode コールバックも渡す
        contentWidget = Mode0100Content(
          ghensuu: ghensuu,
          onAdvanceMode: onAdvanceMode,
        );
        break;
      case 300:
        contentWidget = Mode0300Content(onAdvanceMode: onAdvanceMode);
        break;
      case 330:
        contentWidget = Mode0330Content(
          ghensuu: ghensuu,
          onAdvanceMode: onAdvanceMode,
        );
        break;
      case 350:
        contentWidget = Mode0350Content(onAdvanceMode: onAdvanceMode);
        break;
      case 700:
        contentWidget = Mode0700Content(
          ghensuu: ghensuu,
          onAdvanceMode: onAdvanceMode,
        );
        break;
      default:
        // 未定義のモードの場合のデフォルト表示
        /*contentWidget = Center(
          /*child: Text(
            '不明なモード: ${ghensuu.mode}',
            style: const TextStyle(color: Colors.red, fontSize: HENSUU.fontsize_honbun),
          ),*/
          child: Text(
            //'選手が走り込み中...mode=: ${ghensuu.mode}',
            '選手が走り込み中...',
            style: const TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
            ),
          ),
        );*/
        contentWidget = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 渦巻ぐるぐる表示
              CircularProgressIndicator(color: HENSUU.buttonColor),
              const SizedBox(height: 16),
              // 選手が走り込み中... のテキスト
              Text(
                '選手が走り込み中...\n\n走り終えたら腹筋${ghensuu.mode}回',
                style: TextStyle(
                  color: HENSUU.textcolor,
                  fontSize: HENSUU.fontsize_honbun,
                ),
              ),
            ],
          ),
        );
        break;
    }

    // 全てのモードで共通の背景色やパディングなどが必要ならここで設定
    /*return Scaffold(
      //backgroundColor: HENSUU.backgroundcolor, // HENSUUクラスから背景色を使用
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: contentWidget, // 選択されたコンテンツウィジェットを表示
      ),
    );*/
    // AppBarを生成するウィジェットを宣言
    final AppBar myAppBar;
    if (ghensuu.mode == 100 ||
        ghensuu.mode == 150 ||
        ghensuu.mode == 280 ||
        ghensuu.mode == 290 ||
        ghensuu.mode == 343 ||
        ghensuu.mode == 1111 ||
        ghensuu.mode == 110 ||
        ghensuu.mode == 300 ||
        ghensuu.mode == 330 ||
        ghensuu.mode == 350 ||
        ghensuu.mode == 700) {
      myAppBar = AppBar(
        backgroundColor: Colors.grey[900], // AppBarの背景色
        centerTitle: false, // leadingとtitleの配置を調整するためfalseに
        titleSpacing: 0.0, // leadingとtitleの間のスペースをなくす
        toolbarHeight: 20.0, // 例: 高さを80ピクセルに増やす
        // 左側に2つの文字列を縦に並べる
      );
    } else {
      myAppBar = AppBar(
        title: Text(
          'お待ちください(${ghensuu.year}年${ghensuu.month}月)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.grey[900], // AppBarの背景色
        centerTitle: true, // タイトルを中央に配置
      );
    }

    // 全てのモードで共通の背景色やパディングなどが必要ならここで設定
    return Scaffold(
      appBar: myAppBar, // 例: 高さを80ピクセルに増やす
      // 左側に2つの文字列を縦に並べる
      //backgroundColor: HENSUU.backgroundcolor, // HENSUUクラスから背景色を使用
      body: contentWidget, // 選択されたコンテンツウィジェットを表示
    );
  }
}
