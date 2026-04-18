import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

// ----------------------------------------------------------------------
// 1. ロジック担当：ShareExporter クラス
// ----------------------------------------------------------------------
class ShareExporter {
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

  static const String _metaBoxName = 'saveSlotsMetaBox';

  static String _getSlotBoxName(String baseBoxName, int slotNumber) =>
      '${baseBoxName}_SLOT$slotNumber';

  /// 【内部用】データを圧縮してバイト列を生成
  static Future<List<int>?> _createCompressedData(int slotNumber) async {
    try {
      final archive = Archive();
      for (String baseName in _boxNames) {
        final slotBoxName = _getSlotBoxName(baseName, slotNumber);

        final bool wasOpen = Hive.isBoxOpen(slotBoxName);
        final Box box = wasOpen
            ? Hive.box(slotBoxName)
            : await Hive.openBox(slotBoxName);

        if (box.isNotEmpty) {
          // 保存時はMap<dynamic, dynamic>をMap<String, dynamic>に変換してJSON化
          final jsonString = jsonEncode(_convertMap(box.toMap()));
          final bytes = utf8.encode(jsonString);
          archive.addFile(ArchiveFile('$baseName.json', bytes.length, bytes));
        }

        if (!wasOpen) {
          await box.close();
        }
      }
      final tarData = TarEncoder().encode(archive);
      return GZipEncoder().encode(tarData);
    } catch (e) {
      debugPrint('Compression Error: $e');
      return null;
    }
  }

  /// 【出力実行】OSの共有シートを呼び出す
  static Future<void> shareFile(int slotNumber, List<int> data) async {
    final tempDir = await getTemporaryDirectory();
    final meta = getSlotMeta(slotNumber);
    String univName = meta?['univName'] ?? 'ekiden';
    // ★追加: ファイル名に使えない文字（/ \ : * ? " < > |）を _ に置換して安全にする
    univName = univName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    // ★変更箇所: 現在日時からタイムスタンプ文字列を作成 (例: 20260131_2005)
    final now = DateTime.now();
    final timeStamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    // ★変更箇所: 大学名 + タイムスタンプ + 拡張子
    final fileName = '${univName}_$timeStamp.ekidenSS';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(data);

    await Share.shareXFiles([
      XFile(filePath),
    ], text: '箱庭小駅伝SSの世界データ「$univName」を共有します！');
  }

  /// 【入力実行】ファイルを選択して展開する
  static Future<bool> importFromFile(int targetSlot) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.single.path == null) return false;

      final bytes = await File(result.files.single.path!).readAsBytes();
      final archive = TarDecoder().decodeBytes(
        GZipDecoder().decodeBytes(bytes),
      );

      // メタデータ更新用の一時変数
      int? importedYear;
      int? importedMonth;
      int? importedDay;
      String importedUnivName = '外部データ';
      int? myUnivId;
      Map<dynamic, dynamic>? univMapTemp;

      for (var file in archive) {
        if (file.isFile) {
          final baseName = file.name.replaceAll('.json', '');
          final slotBoxName = _getSlotBoxName(baseName, targetSlot);
          final content = utf8.decode(file.content as List<int>);

          final dynamic rawJson = jsonDecode(content);

          // ★修正ポイント: 型キャストエラーを防ぐため、安全にMap<String, dynamic>へ変換
          final Map<String, dynamic> dataMap =
              _fixJsonTypes(rawJson) as Map<String, dynamic>;

          final bool wasOpen = Hive.isBoxOpen(slotBoxName);
          final Box box = wasOpen
              ? Hive.box(slotBoxName)
              : await Hive.openBox(slotBoxName);

          await box.clear();
          for (var entry in dataMap.entries) {
            // キーを適切な型(int/String)に戻して保存
            final key = _restoreKey(entry.key);
            await box.put(key, entry.value);
          }

          if (baseName == 'ghensuuBox') {
            // JSONキーはStringになっているため '0' でアクセスを試みる
            final ghensuuData =
                dataMap['0'] ??
                (dataMap.isNotEmpty ? dataMap.values.first : null);
            if (ghensuuData != null && ghensuuData is Map) {
              importedYear = ghensuuData['year'];
              importedMonth = ghensuuData['month'];
              importedDay = ghensuuData['day'];
              myUnivId = ghensuuData['MYunivid'];
            }
          }
          if (baseName == 'univBox') {
            univMapTemp = dataMap.map((k, v) => MapEntry(_restoreKey(k), v));
          }

          if (!wasOpen) {
            await box.close();
          }
        }
      }

      if (myUnivId != null && univMapTemp != null) {
        final myUniv = univMapTemp[myUnivId];
        if (myUniv != null && myUniv is Map && myUniv['name'] != null) {
          importedUnivName = myUniv['name'];
        }
      }

      final metaBox = await Hive.openBox<Map<dynamic, dynamic>>(_metaBoxName);
      final metaData = {
        'isUsed': true,
        'date': DateTime.now().toString().substring(0, 16),
        'year': importedYear ?? 0,
        'month': importedMonth ?? 0,
        'day': importedDay ?? 0,
        'univName': importedUnivName,
      };
      await metaBox.put(targetSlot, metaData);

      return true;
    } catch (e) {
      debugPrint('Import Error: $e');
      return false;
    }
  }

  // ★修正: JSONの型を厳格に修正する関数（Map<String, dynamic>を保証）
  static dynamic _fixJsonTypes(dynamic item) {
    if (item is List) {
      final List<dynamic> fixedList = item
          .map((e) => _fixJsonTypes(e))
          .toList();
      if (fixedList.isEmpty) return fixedList;
      if (fixedList.every((e) => e is int)) return fixedList.cast<int>();
      if (fixedList.every((e) => e is double)) return fixedList.cast<double>();
      if (fixedList.every((e) => e is String)) return fixedList.cast<String>();
      return fixedList;
    }

    if (item is Map) {
      // ★ここが重要: 明示的に Map<String, dynamic> を生成して返す
      final Map<String, dynamic> fixedMap = {};
      item.forEach((key, value) {
        fixedMap[key.toString()] = _fixJsonTypes(value);
      });
      return fixedMap;
    }

    return item;
  }

  static dynamic _convertMap(dynamic item) {
    if (item is Map)
      return item.map(
        (key, value) => MapEntry(key.toString(), _convertMap(value)),
      );
    if (item is List) return item.map(_convertMap).toList();
    return item;
  }

  static dynamic _restoreKey(String key) => int.tryParse(key) ?? key;

  static Map<dynamic, dynamic>? getSlotMeta(int slotNumber) {
    if (!Hive.isBoxOpen(_metaBoxName)) return null;
    return Hive.box<Map<dynamic, dynamic>>(_metaBoxName).get(slotNumber);
  }

  static bool isSlotUsed(int slotNumber) {
    final meta = getSlotMeta(slotNumber);
    return meta != null && (meta['isUsed'] == true || meta['isUsed'] == 1);
  }

  static String _dayPhase(dynamic day) {
    if (day is! int) return '';
    if (day == 0) return '';
    if (day <= 10) return '上旬';
    if (day <= 20) return '中旬';
    return '下旬';
  }
}

// ----------------------------------------------------------------------
// 2. 画面担当：ShareWorldScreen ウィジェット
// ----------------------------------------------------------------------
class ShareWorldScreen extends StatefulWidget {
  const ShareWorldScreen({super.key});
  @override
  State<ShareWorldScreen> createState() => _ShareWorldScreenState();
}

class _ShareWorldScreenState extends State<ShareWorldScreen> {
  int? _selectedSlot;
  bool _isProcessing = false;

  /// 出力前確認ダイアログ
  Future<void> _handleExport() async {
    if (_selectedSlot == null) return;

    if (!ShareExporter.isSlotUsed(_selectedSlot!)) {
      _showSimpleSnackBar('空きスロットのデータは出力できません。');
      return;
    }

    setState(() => _isProcessing = true);
    final data = await ShareExporter._createCompressedData(_selectedSlot!);
    setState(() => _isProcessing = false);

    if (data == null) {
      _showSimpleSnackBar('データの圧縮に失敗しました。');
      return;
    }

    final double kbSize = data.length / 1024;
    final String sizeText = kbSize > 1024
        ? '${(kbSize / 1024).toStringAsFixed(2)} MB'
        : '${kbSize.toStringAsFixed(2)} KB';

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('世界データの出力', style: TextStyle(color: Colors.white)),
        content: Text(
          'スロット $_selectedSlot のデータを書き出します。\n\n推定ファイルサイズ: $sizeText\n\n共有メニューを開いてもよろしいですか？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '共有する',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ShareExporter.shareFile(_selectedSlot!, data);
    }
  }

  /// 入力前確認ダイアログ
  Future<void> _handleImport() async {
    if (_selectedSlot == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('データの読み込み', style: TextStyle(color: Colors.red)),
        content: Text(
          'スロット $_selectedSlot のデータは「完全に破棄」され、選択したファイルの内容で上書きされます。\n\n本当によろしいですか？',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '上書き読み込み',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      // import処理を実行
      final success = await ShareExporter.importFromFile(_selectedSlot!);

      setState(() {
        _isProcessing = false;
        // リロードが必要ならここで選択解除など
      });

      _showSimpleSnackBar(
        success
            ? '世界データの保存スロットへの読み込みが完了しました！\nセーブデータ画面を確認してください。'
            : '読み込みがキャンセルされたか、失敗しました。',
      );
    }
  }

  void _showSimpleSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bool canExport =
        _selectedSlot != null &&
        !_isProcessing &&
        ShareExporter.isSlotUsed(_selectedSlot!);

    final bool canImport = _selectedSlot != null && !_isProcessing;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('世界データの共有', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('1. 出力：自分の世界をファイルで送る'),
                const SizedBox(height: 10),
                _buildSlotSelector(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: canExport ? _handleExport : null,
                  icon: const Icon(Icons.share),
                  label: const Text('サイズを確認して共有'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[800],
                    disabledForegroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(color: Colors.white24),
                const SizedBox(height: 20),
                _buildSectionTitle('2. 入力：受け取ったファイルを保存スロットに読み込む'),
                const SizedBox(height: 10),
                const Text(
                  '※上書きする先のスロットを上記で選択してください',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: canImport ? _handleImport : null,
                  icon: const Icon(Icons.file_open),
                  label: const Text('ファイルを選択して保存スロットに読み込む'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[900],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[800],
                    disabledForegroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
                // ★★★ 追加箇所: ここから ★★★
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    '本機能はゲームデータをテキスト形式でやり取りするものであり、プログラムを実行するものではありません。\n\n安心してお使いいただけますが、信頼できる相手からのデータ受け取りを推奨します（改造データによるゲーム動作の不具合を防ぐため）。',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 20),
                // ★★★ 追加箇所: ここまで ★★★
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.yellow),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSlotSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: List.generate(5, (index) {
          final slotNum = index + 1;
          final meta = ShareExporter.getSlotMeta(slotNum);
          final isUsed =
              meta != null && (meta['isUsed'] == true || meta['isUsed'] == 1);
          return RadioListTile<int>(
            title: Text(
              'スロット $slotNum ${isUsed ? "[${meta['univName']}]" : "(空き)"}',
              style: TextStyle(color: isUsed ? Colors.white : Colors.white38),
            ),
            subtitle: isUsed
                ? Text(
                    '${meta['year']}年 ${meta['month']}月${meta['day'] != null ? ShareExporter._dayPhase(meta['day']) : ''} / ${meta['date']}',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  )
                : null,
            value: slotNum,
            groupValue: _selectedSlot,
            onChanged: (val) => setState(() => _selectedSlot = val),
            activeColor: Colors.yellow,
          );
        }),
      ),
    );
  }
}
