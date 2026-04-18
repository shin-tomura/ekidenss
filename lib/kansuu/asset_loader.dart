import 'package:flutter/services.dart' show rootBundle; // rootBundle をインポート

/// 指定されたアセットファイルから行を読み込み、リストとして返します。
Future<List<String>> loadLinesFromAsset(String assetPath) async {
  try {
    // アセットファイルを文字列として読み込む
    String data = await rootBundle.loadString(assetPath);
    // 改行で分割し、空の行をフィルタリングして返す
    return data.split('\n').where((s) => s.trim().isNotEmpty).toList();
  } catch (e) {
    print('Error loading asset $assetPath: $e');
    return []; // エラー時は空のリストを返す
  }
}
