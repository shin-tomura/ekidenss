import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/kiroku.dart';
import 'package:ekiden/Shuudansou.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/riji_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/univ_gakuren_data.dart';

// ------------------------------------------------------------
// 処理中断対策(処理前スナップショットと自動巻き戻し)
//
// ・重い処理の直前に、全ゲームデータのBoxファイルをコピーしてスナップショットを取る
// ・「処理中」の目印ファイルを書く(スナップショットのコピーが終わってから書く)
// ・処理が最後まで終わったら目印ファイルを消す
// ・次の起動時(Boxを開く前)に目印ファイルが残っていれば、処理の途中で終了したと判断し、
//   スナップショットをBoxファイルに書き戻して「処理前の状態」に戻す
//   (gh.modeも処理前の値に戻るので、その処理がきれいな状態からやり直される)
// ・処理中に例外が出た場合は、目印ファイルを残したままエラー画面を表示し、
//   再起動を促す(再起動時に処理前の状態に戻る)
//
// 保存場所: アプリのドキュメントディレクトリ/shori_snapshot/
// (Hive.initFlutter() はドキュメントディレクトリにBoxファイルを置く)
// ------------------------------------------------------------
class ShoriGuard {
  /// スナップショットの対象にするBox(セーブスロットの対象と同じ)
  static const List<String> _boxNames = [
    'senshuBox',
    'univBox',
    'kirokuBox',
    'shuudansouBox',
    'skipBox',
    'albumBox',
    'retiredSenshuBox',
    'kantokuBox',
    'rijiBox',
    'gakurenSenshuBox',
    'gakurenUnivBox',
    'ghensuuBox',
  ];
  static const String _snapshotDirName = 'shori_snapshot';
  static const String _markFileName = 'shori_mark.json';

  /// 処理中にエラーが起きたときのメッセージ。nullでなければエラー画面を表示する
  static final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(
    null,
  );

  /// 起動時に巻き戻しを行った場合の処理名(再開画面のお知らせ用)
  static String? restoredLabel;

  /// 開いているBoxを、開いたときと同じ型で取得する(Hiveは型が違うとエラーになるため)
  static Box _openedBox(String name) {
    switch (name) {
      case 'ghensuuBox':
        return Hive.box<Ghensuu>(name);
      case 'senshuBox':
        return Hive.box<SenshuData>(name);
      case 'univBox':
        return Hive.box<UnivData>(name);
      case 'kirokuBox':
        return Hive.box<Kiroku>(name);
      case 'shuudansouBox':
        return Hive.box<Shuudansou>(name);
      case 'skipBox':
        return Hive.box<Skip>(name);
      case 'albumBox':
        return Hive.box<Album>(name);
      case 'retiredSenshuBox':
        return Hive.box<Senshu_R_Data>(name);
      case 'kantokuBox':
        return Hive.box<KantokuData>(name);
      case 'rijiBox':
        return Hive.box<RijiData>(name);
      case 'gakurenSenshuBox':
        return Hive.box<Senshu_Gakuren_Data>(name);
      case 'gakurenUnivBox':
        return Hive.box<UnivGakurenData>(name);
      default:
        return Hive.box(name);
    }
  }

  static Future<Directory> _snapshotDir() async {
    final Directory docDir = await getApplicationDocumentsDirectory();
    return Directory('${docDir.path}/$_snapshotDirName');
  }

  /// 重い処理の直前に呼ぶ(スナップショットを取り、処理中の目印を書く)
  static Future<void> begin(String label) async {
    final Directory snapDir = await _snapshotDir();
    if (!await snapDir.exists()) {
      await snapDir.create(recursive: true);
    }
    final List<String> fileNames = [];
    for (final String name in _boxNames) {
      if (!Hive.isBoxOpen(name)) continue;
      final Box box = _openedBox(name);
      await box.flush(); // 書き込み途中のデータをファイルに確定させる
      final String? path = box.path;
      if (path == null) continue;
      final String fileName = path.split(Platform.pathSeparator).last;
      await File(path).copy('${snapDir.path}/$fileName');
      fileNames.add(fileName);
    }
    // 目印はスナップショットのコピーがすべて終わってから書く
    final File mark = File('${snapDir.path}/$_markFileName');
    await mark.writeAsString(
      jsonEncode({'label': label, 'files': fileNames}),
      flush: true,
    );
  }

  /// 処理が最後まで終わったら呼ぶ(処理中の目印を消す)
  static Future<void> end() async {
    final Directory snapDir = await _snapshotDir();
    final File mark = File('${snapDir.path}/$_markFileName');
    if (await mark.exists()) {
      await mark.delete();
    }
  }

  /// 処理中に例外が出たときに呼ぶ(目印は残したまま、エラー画面を表示させる)
  static void reportError(String label, Object e) {
    print('ShoriGuard: 「$label」の処理中にエラー: $e');
    errorMessage.value = '「$label」の処理中にエラーが発生しました。\n\n$e';
  }

  /// 起動時、Boxを開く前に呼ぶ(処理の途中で終了していたら、処理前の状態に戻す)
  static Future<void> restoreIfInterrupted() async {
    try {
      final Directory snapDir = await _snapshotDir();
      final File mark = File('${snapDir.path}/$_markFileName');
      if (!await mark.exists()) return;

      final Map<String, dynamic> info =
          jsonDecode(await mark.readAsString()) as Map<String, dynamic>;
      final String label = (info['label'] as String?) ?? '不明な処理';
      final List<String> fileNames = ((info['files'] as List?) ?? [])
          .cast<String>();
      final Directory docDir = await getApplicationDocumentsDirectory();
      for (final String fileName in fileNames) {
        final File snap = File('${snapDir.path}/$fileName');
        if (await snap.exists()) {
          await snap.copy('${docDir.path}/$fileName');
        }
      }
      // 書き戻しが全部終わってから目印を消す(途中で終了しても次回やり直せる)
      await mark.delete();
      restoredLabel = label;
      print('ShoriGuard: 「$label」の途中で終了していたため、処理前の状態に戻しました');
    } catch (e) {
      print('ShoriGuard: 巻き戻しに失敗しました: $e');
    }
  }
}

/// 処理中にエラーが起きたときに表示する画面
class ShoriErrorScreen extends StatelessWidget {
  final String message;
  const ShoriErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    '処理中にエラーが発生しました',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'お手数ですが、アプリを一度終了してから、もう一度起動してください。\n'
                    '再起動すると、エラーが起きた処理の前の状態に自動で戻ります。',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    message,
                    textAlign: TextAlign.left,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
