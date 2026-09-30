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
// ・一度エラーが出たら、再起動するまで次の処理を始めない(壊れかけの状態で撮り直さないため)
// ・目印がすでにある場合は撮り直さず、前のスナップショットを巻き戻し先として残す
// ・スナップショットが取れない場合(空き容量不足など)は、保護なしで処理を続ける
// ・コピーしたファイルは端末に確実に書き込んでから目印を書く・消す(電源断対策)
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

  /// 起動時の巻き戻しに失敗した場合のメッセージ(再開画面のお知らせ用)
  static String? restoreErrorMessage;

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

  /// コピーしたファイルを端末に確実に書き込む(電源断対策)
  static Future<void> _kakuteiKakikomi(String path) async {
    final RandomAccessFile raf = await File(path).open(mode: FileMode.append);
    try {
      await raf.flush();
    } finally {
      await raf.close();
    }
  }

  /// 重い処理の直前に呼ぶ(スナップショットを取り、処理中の目印を書く)
  static Future<void> begin(String label) async {
    // 一度エラーが出たら、再起動して処理前の状態に戻すまで次の処理を始めない
    // (壊れかけの状態でスナップショットを撮り直すと、正常な巻き戻し先が失われるため)
    if (errorMessage.value != null) {
      throw StateError('前の処理でエラーが発生したため、アプリの再起動が必要です');
    }
    bool markKakikomiChuu = false;
    try {
      final Directory snapDir = await _snapshotDir();
      if (!await snapDir.exists()) {
        await snapDir.create(recursive: true);
      }
      final File mark = File('${snapDir.path}/$_markFileName');
      // 目印がすでにある場合(起動時の巻き戻しに失敗した場合など)は撮り直さず、
      // 前のスナップショットを巻き戻し先として残す
      if (await mark.exists()) return;

      final List<String> fileNames = [];
      for (final String name in _boxNames) {
        if (!Hive.isBoxOpen(name)) continue;
        final Box box = _openedBox(name);
        await box.flush(); // 書き込み途中のデータをファイルに確定させる
        final String? path = box.path;
        if (path == null) continue;
        final String fileName = path.split(Platform.pathSeparator).last;
        final String snapPath = '${snapDir.path}/$fileName';
        await File(path).copy(snapPath);
        await _kakuteiKakikomi(snapPath);
        fileNames.add(fileName);
      }
      // 目印はスナップショットのコピーがすべて終わってから書く
      markKakikomiChuu = true;
      await mark.writeAsString(
        jsonEncode({'label': label, 'files': fileNames}),
        flush: true,
      );
    } catch (e) {
      // スナップショットが取れない場合(空き容量不足など)は、保護なしで処理を続ける
      // (1.7.7までと同じ動き。ここでエラー画面にすると、再起動しても先に進めなくなるため)
      print('ShoriGuard: 「$label」の処理前スナップショットを取れませんでした(保護なしで続行): $e');
      if (markKakikomiChuu) {
        // 目印の書き込み途中で失敗した場合は、中途半端な目印を消しておく
        try {
          final Directory snapDir = await _snapshotDir();
          final File mark = File('${snapDir.path}/$_markFileName');
          if (await mark.exists()) await mark.delete();
        } catch (_) {}
      }
    }
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
    // 最初のエラーの内容を表示し続ける(再起動までに続けて出たエラーでは上書きしない)
    if (errorMessage.value != null) return;
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
          final String boxPath = '${docDir.path}/$fileName';
          await snap.copy(boxPath);
          await _kakuteiKakikomi(boxPath);
        }
      }
      // 書き戻しが全部終わってから目印を消す(途中で終了しても次回やり直せる)
      await mark.delete();
      restoredLabel = label;
      print('ShoriGuard: 「$label」の途中で終了していたため、処理前の状態に戻しました');
    } catch (e) {
      // 目印は残るので、次の起動でもう一度巻き戻しを試みる
      print('ShoriGuard: 巻き戻しに失敗しました: $e');
      restoreErrorMessage = '$e';
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
