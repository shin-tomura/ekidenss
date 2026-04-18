import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Flutter環境でのHive初期化に必要

void main() async {
  // Flutterのウィジェットバインディングが初期化されていることを確認
  // Hive.initFlutter() を使うために、これは必須です。
  // ただし、今回はこのファイル自体を「Flutterプロジェクトの一部として」実行するので、
  // main.dartからこのmain関数を呼び出す形を取るため、main.dart側で処理されます。
  // もしこのファイルをスタンドアロンのDartスクリプトとして実行するなら必要。

  print('Hive初期化中...');
  await Hive.initFlutter(); // Flutterアプリ環境でHiveを初期化
  print('Hive初期化完了。');

  print('Boxオープン中...');
  var box = await Hive.openBox('testBox'); // 'testBox'という名前のBoxを開く
  print('Boxオープン完了。');

  // データを保存
  print('データ保存中...');
  await box.put('myKey', 'Hello Hive!'); // キー: 'myKey', 値: 'Hello Hive!'
  print('データ保存完了。');

  // データを読み込み
  print('データ読み込み中...');
  String? value = box.get('myKey');
  print('読み込んだ値: $value');

  // 別のデータを保存・更新
  await box.put('counter', 100);
  print('カウンターを保存: ${box.get('counter')}');
  await box.put('counter', 200);
  print('カウンターを更新: ${box.get('counter')}');

  // Boxを閉じる
  print('Boxクローズ中...');
  await box.close();
  print('Boxクローズ完了。');
}
