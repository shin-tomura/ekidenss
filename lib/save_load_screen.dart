import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/univ_data.dart';
import 'package:ekiden/senshu_data.dart';
import 'package:ekiden/kiroku.dart';
import 'package:ekiden/Shuudansou.dart';
import 'package:ekiden/skip.dart';
import 'package:ekiden/album.dart';
import 'package:ekiden/senshu_r_data.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/riji_data.dart';
import 'package:ekiden/senshu_gakuren_data.dart';
import 'package:ekiden/univ_gakuren_data.dart';
import 'package:ekiden/data_comparer.dart';
import 'dart:math'; // Randomクラスを使用するため
import 'package:ekiden/kansuu/univkosei.dart';
import 'package:ekiden/kansuu/ChartPanelSenshu.dart';
import 'package:ekiden/kansuu/ChartPanelUniv.dart';
//import 'dart:io';
//import 'package:path_provider/path_provider.dart';

// ********** セーブスロットで使用するBoxのリスト **********
const List<String> kActiveBoxNames = [
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
// *******************************************************
// ********** Box名と型クラスの対応表 **********
// このMapは主に getActiveBox の型ヒントとして機能します
final Map<String, Type> kBoxTypes = {
  'senshuBox': SenshuData,
  'univBox': UnivData,
  'kirokuBox': Kiroku,
  'shuudansouBox': Shuudansou,
  'skipBox': Skip,
  'albumBox': Album,
  'retiredSenshuBox': Senshu_R_Data,
  'kantokuBox': KantokuData,
  'rijiBox': RijiData,
  'gakurenSenshuBox': Senshu_Gakuren_Data,
  'gakurenUnivBox': UnivGakurenData,
  'ghensuuBox': Ghensuu,
};
// ********************************************

const String kMetaBoxName = 'saveSlotsMetaBox';
const int kTotalSlots = 5;

// スロット番号からスロット用Boxの接尾辞を生成
String _getSlotBoxSuffix(int slotNumber) => '_SLOT$slotNumber';

// Box名とスロット番号からスロットBox名を取得
String _getSlotBoxName(String baseBoxName, int slotNumber) {
  return baseBoxName + _getSlotBoxSuffix(slotNumber);
}

// ----------------------------------------------------------------------
// ★★★ 汎用的な Box 取得ヘルパー関数 ★★★
// ----------------------------------------------------------------------

// save_load_screen.dart 内の getActiveBox 関数をこれに置き換えてください。
// 型チェックを削除し、純粋に開かれたBoxを正しい型で返します。
dynamic getActiveBox(String boxName) {
  final type = kBoxTypes[boxName];
  // main.dartで開かれているBoxを、その型で参照する
  if (type == Ghensuu) return Hive.box<Ghensuu>(boxName);
  if (type == SenshuData) return Hive.box<SenshuData>(boxName);
  if (type == UnivData) return Hive.box<UnivData>(boxName);
  if (type == Kiroku) return Hive.box<Kiroku>(boxName);
  if (type == Shuudansou) return Hive.box<Shuudansou>(boxName);
  if (type == Skip) return Hive.box<Skip>(boxName);
  if (type == Album) return Hive.box<Album>(boxName);
  if (type == Senshu_R_Data) return Hive.box<Senshu_R_Data>(boxName);
  if (type == KantokuData) return Hive.box<KantokuData>(boxName);
  if (type == RijiData) return Hive.box<RijiData>(boxName);
  if (type == Senshu_Gakuren_Data)
    return Hive.box<Senshu_Gakuren_Data>(boxName);
  if (type == UnivGakurenData) return Hive.box<UnivGakurenData>(boxName);

  return Hive.box<dynamic>(boxName);
}

// 型指定でBoxを非同期で開くヘルパー（再利用可能）
Future<Box> _openBoxWithType(String boxName) async {
  final type = kBoxTypes[boxName];
  if (type == Ghensuu) return await Hive.openBox<Ghensuu>(boxName);
  if (type == SenshuData) return await Hive.openBox<SenshuData>(boxName);
  if (type == UnivData) return await Hive.openBox<UnivData>(boxName);
  if (type == Kiroku) return await Hive.openBox<Kiroku>(boxName);
  if (type == Shuudansou) return await Hive.openBox<Shuudansou>(boxName);
  if (type == Skip) return await Hive.openBox<Skip>(boxName);
  if (type == Album) return await Hive.openBox<Album>(boxName);
  if (type == Senshu_R_Data) return await Hive.openBox<Senshu_R_Data>(boxName);
  if (type == KantokuData) return await Hive.openBox<KantokuData>(boxName);
  if (type == RijiData) return await Hive.openBox<RijiData>(boxName);
  if (type == Senshu_Gakuren_Data)
    return await Hive.openBox<Senshu_Gakuren_Data>(boxName);
  if (type == UnivGakurenData)
    return await Hive.openBox<UnivGakurenData>(boxName);

  return await Hive.openBox<dynamic>(boxName);
}

// JSON変換ヘルパー: HiveObject を Map に変換 (toJson()使用)
Map<String, dynamic>? _toJson(dynamic value, Type type) {
  if (value == null) return null;
  if (type == Ghensuu) return (value as Ghensuu).toJson();
  if (type == SenshuData) return (value as SenshuData).toJson();
  if (type == UnivData) return (value as UnivData).toJson();
  if (type == Kiroku) return (value as Kiroku).toJson();
  if (type == Shuudansou) return (value as Shuudansou).toJson();
  if (type == Skip) return (value as Skip).toJson();
  if (type == Album) return (value as Album).toJson();
  if (type == Senshu_R_Data) return (value as Senshu_R_Data).toJson();
  if (type == KantokuData) return (value as KantokuData).toJson();
  if (type == RijiData) return (value as RijiData).toJson();
  if (type == Senshu_Gakuren_Data)
    return (value as Senshu_Gakuren_Data).toJson();
  if (type == UnivGakurenData) return (value as UnivGakurenData).toJson();
  return null; // 非HiveObjectの場合
}

// JSON変換ヘルパー: Map から新しい HiveObject インスタンスを作成 (fromJson使用)
dynamic _fromJson(Map<String, dynamic> jsonData, Type type) {
  if (type == Ghensuu) return Ghensuu.fromJson(jsonData);
  if (type == SenshuData) return SenshuData.fromJson(jsonData);
  if (type == UnivData) return UnivData.fromJson(jsonData);
  if (type == Kiroku) return Kiroku.fromJson(jsonData);
  if (type == Shuudansou) return Shuudansou.fromJson(jsonData);
  if (type == Skip) return Skip.fromJson(jsonData);
  if (type == Album) return Album.fromJson(jsonData);
  if (type == Senshu_R_Data) return Senshu_R_Data.fromJson(jsonData);
  if (type == KantokuData) return KantokuData.fromJson(jsonData);
  if (type == RijiData) return RijiData.fromJson(jsonData);
  if (type == Senshu_Gakuren_Data)
    return Senshu_Gakuren_Data.fromJson(jsonData);
  if (type == UnivGakurenData) return UnivGakurenData.fromJson(jsonData);
  return jsonData; // 非HiveObjectの場合
}

// 各スロットの情報を保持するクラス (セーブ/ロード画面表示用)
class SlotData {
  final int slotNumber;
  final String title;
  final bool isUsed;
  final String date;
  final int year;
  final int month;
  final int day; // ★★★ 修正箇所 1: day を追加 ★★★

  SlotData({
    required this.slotNumber,
    this.title = 'Empty Slot',
    this.isUsed = false,
    this.date = '---',
    this.year = 0,
    this.month = 0,
    this.day = 0, // ★★★ 修正箇所 1: day の初期値を追加 ★★★
  });
}

class SaveLoadScreen extends StatefulWidget {
  final bool hozonmosuruflag;
  const SaveLoadScreen({super.key, required this.hozonmosuruflag});

  @override
  State<SaveLoadScreen> createState() => _SaveLoadScreenState();
}

class _SaveLoadScreenState extends State<SaveLoadScreen> {
  bool _isProcessing = false; // ★ NEW: 処理中フラグ

  final List<SlotData> _slots = List.generate(
    kTotalSlots,
    (index) => SlotData(slotNumber: index + 1),
  );
  Box<Map<dynamic, dynamic>>? _metaBox;

  @override
  void initState() {
    super.initState();
    try {
      _metaBox = Hive.box<Map<dynamic, dynamic>>(kMetaBoxName);
      _loadSlotData();
    } catch (e) {
      print("Hive Box error during init: $e");
    }
  }

  // ----------------------------------------------------------------------
  // ★★★ NEW: テスト機能 ★★★
  // ----------------------------------------------------------------------

  Future<void> _runDataVerification(int slotNumber) async {
    _showSnackbar('スロット $slotNumber と現在のデータの照合を開始します...', isError: false);
    bool allMatch = true;

    try {
      for (var boxName in kActiveBoxNames) {
        final isMatch = await compareBoxContent(
          boxName,
          slotNumber,
        ); // 上記の関数を呼び出し

        if (!isMatch) {
          allMatch = false;
          // console/ログには詳細が出ているので、ここでは簡潔に通知
          print('--- 照合結果: $boxName は不一致です ---');
        }
      }

      if (allMatch) {
        _showSnackbar(
          '🎉 全データがスロット $slotNumber のデータと完全に一致しました！',
          isError: false,
        );
      } else {
        _showSnackbar(
          '⚠️ データの一部がスロット $slotNumber のデータと一致しませんでした。ログを確認してください。',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackbar('照合中に深刻なエラーが発生しました: $e', isError: true);
      print('照合エラー: $e');
    }
  }

  void _loadSlotData() {
    if (_metaBox == null) return;
    for (int i = 0; i < kTotalSlots; i++) {
      final slotNum = i + 1;
      final meta = _metaBox!.get(slotNum) as Map<dynamic, dynamic>?;

      if (meta != null && (meta['isUsed'] == true || meta['isUsed'] == 1)) {
        final String univName = meta['univName']?.toString() ?? 'プレイヤー大学';
        final int currentYear = (meta['year'] as int?) ?? 0;
        final String dateString = meta['date']?.toString() ?? '日付不明';
        final int currentMonth = (meta['month'] as int?) ?? 0;
        final int currentDay =
            (meta['day'] as int?) ?? 0; // ★★★ 修正箇所 4A: day を読み込み ★★★

        _slots[i] = SlotData(
          slotNumber: slotNum,
          isUsed: true,
          title: univName,
          date: dateString,
          year: currentYear,
          month: currentMonth,
          day: currentDay, // ★★★ 修正箇所 4A: day を渡す ★★★
        );
      } else {
        _slots[i] = SlotData(slotNumber: slotNum);
      }
    }
    setState(() {});
  }

  // ★★★ NEW: 確認ダイアログの表示関数 ★★★
  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: Text(title, style: TextStyle(color: Colors.white)),
              content: Text(content, style: TextStyle(color: Colors.white70)),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // キャンセル
                  child: Text('キャンセル', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true), // OK
                  child: Text('OK', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // 保存処理 (確認ダイアログ経由)
  Future<void> _handleExportToSlot(int targetSlot) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true); // 処理開始
    try {
      final bool confirm = await _showConfirmationDialog(
        'データを保存します',
        'スロット $targetSlot のデータが上書きされます。よろしいですか？',
      );
      if (confirm) {
        await _exportToSlot(targetSlot);
      } else {
        //_showSnackbar('保存をキャンセルしました。', isError: false);
      }
    } finally {
      // 処理の成功・失敗に関わらずフラグをリセット
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // 読み込み処理 (確認ダイアログ経由)
  Future<void> _handleImportFromSlot(int targetSlot) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true); // 処理開始
    try {
      final bool confirm = await _showConfirmationDialog(
        'データを読み込みます',
        '現在のプレイデータは破棄され、スロット $targetSlot のデータに上書きされます。よろしいですか？',
      );
      if (confirm) {
        await _importFromSlot(targetSlot);
      } else {
        //_showSnackbar('読み込みをキャンセルしました。', isError: false);
      }
    } finally {
      // 処理の成功・失敗に関わらずフラグをリセット
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
  // ★★★ END: 確認ダイアログの表示関数 ★★★

  Future<void> _exportToSlot(int targetSlot) async {
    try {
      print('---- [START] データコピーフェーズ ----');
      for (var boxName in kActiveBoxNames) {
        final slotBoxName = _getSlotBoxName(boxName, targetSlot);

        // スロットBoxをクリーンアップ
        if (Hive.isBoxOpen(slotBoxName)) {
          await Hive.box(slotBoxName).close();
        }
        if (await Hive.boxExists(slotBoxName)) {
          await Hive.deleteBoxFromDisk(slotBoxName);
        }

        // スロットBoxを開く（dynamicで）
        final slotBox = await Hive.openBox(slotBoxName);

        // メインBoxを参照（開いたまま）
        print('コピー処理: $boxName - メインBox参照');
        final mainBox = getActiveBox(boxName);
        if (!mainBox.isOpen) {
          throw Exception('メインBox $boxName が開いていません');
        }
        print('コピー処理: $boxName - メインBox参照成功');

        // データコピー（JSON経由で新しいインスタンス）
        await slotBox.clear();
        final type = kBoxTypes[boxName];
        for (var key in mainBox.keys) {
          final value = mainBox.get(key);
          final jsonData = _toJson(value, type!);
          if (jsonData != null) {
            await slotBox.put(key, jsonData); // Mapとして保存
          } else {
            await slotBox.put(key, value);
          }
        }

        // スロットBoxを閉じる（保存）
        await slotBox.close();
        print('コピー処理: $boxName - 完了');
      }
      print('---- [END] データコピーフェーズ ----');

      // ★★★ 修正箇所: ここに遅延を挿入 ★★★
      //await Future.delayed(const Duration(seconds: 5)); // 3秒間処理を停止

      // メタデータ更新
      await _updateMetaData(targetSlot);
      Future.microtask(() {
        _loadSlotData();
        _showSnackbar('スロット $targetSlot に保存しました！ 💾');
      });
    } catch (e) {
      _showSnackbar('保存に失敗しました: $e', isError: true);
      print('保存失敗 (データコピー): $e');
    }
  }

  // 指定スロットからデータを読み込み (データコピー方式)
  Future<void> _importFromSlot(int targetSlot) async {
    try {
      if (!_slots[targetSlot - 1].isUsed) {
        _showSnackbar('スロット $targetSlot にデータがありません。', isError: true);
        return;
      }

      // =======================================================
      // データ読み込み＆上書きフェーズ
      // =======================================================

      print('---- [START] データ読み込み＆上書きフェーズ (Boxは閉じない) ----');
      for (var boxName in kActiveBoxNames) {
        final slotBoxName = _getSlotBoxName(boxName, targetSlot);
        print('通過1 ${boxName}');
        // スロット Box を開く
        final slotBox = await Hive.openBox(slotBoxName);
        print('通過2 ${boxName}');
        // メイン Box を開いている参照として取得
        final type = kBoxTypes[boxName];
        print('通過3 ${boxName}');

        print('通過4 ${boxName}');
        // メイン Box を開く（すでに開いている可能性もあるが、_openBoxWithTypeは安全に処理する）
        final mainBox = await _openBoxWithType(boxName);

        print('通過5 ${boxName}');
        // データコピー（上書き）
        await mainBox.clear(); // メインBoxの中身をクリア
        print('通過6 ${boxName}');
        for (var key in slotBox.keys) {
          final rawData = slotBox.get(key);

          // JSONデータからオブジェクトへ復元（前回の修正ロジックを維持）
          if (rawData is Map) {
            final Map<String, dynamic> stringMap = rawData
                .cast<String, dynamic>();
            final newValue = _fromJson(stringMap, type!);
            await mainBox.put(key, newValue); // 開いているBoxにデータを書き込む
          } else {
            await mainBox.put(key, rawData);
          }
        }

        // スロットBoxは閉じる
        await slotBox.close();
        print('上書き処理: $boxName - 完了');
      }
      print('---- [END] データ読み込み＆上書きフェーズ ----');

      // ★★★ 修正箇所: ここに遅延を挿入 ★★★
      //await Future.delayed(const Duration(seconds: 5)); // 3秒間処理を停止

      _loadSlotData();

      // 大学データリストをソート（駅伝成績表示で使用）
      final univDataBox = Hive.box<UnivData>('univBox');
      List<UnivData> sortedUnivData = univDataBox.values.toList();
      sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 1660 ||
            checkversionValue > 999999999) {
          // Hive.box() を使って、既に開いているBoxを取得
          final albumBox = Hive.box<Album>('albumBox');
          // Boxからデータを読み込む
          final Album album = albumBox.get('AlbumData')!;
          album.tourokusuu_total = 30; //コンピュータチームの最適解区間配置確率
          await album.save();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 1730 ||
            checkversionValue > 999999999) {
          sortedUnivData[9].name_tanshuku = "0"; //10000mを超える距離のタイム補正ONなら"1"
          await sortedUnivData[9].save();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 1760 ||
            checkversionValue > 999999999) {
          sortedUnivData[8].name_tanshuku = ""; //総監督の成績
          await sortedUnivData[8].save();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 1790 ||
            checkversionValue > 999999999) {
          final kantokuBox = Hive.box<KantokuData>('kantokuBox');
          final KantokuData? kantoku = kantokuBox.get('KantokuData')!;
          kantoku!.yobiint2[2] = 25;
          kantoku.yobiint2[3] = 80;
          kantoku.yobiint2[4] = 50;
          kantoku.yobiint2[5] = 1;
          kantoku.yobiint2[6] = 1;
          kantoku.yobiint2[7] = 90;
          kantoku.yobiint2[8] = 50;
          kantoku.yobiint2[9] = 30;
          kantoku.yobiint2[10] = 0;
          kantoku.yobiint2[11] = 10;
          await kantoku.save();
          final senshuDataBox = Hive.box<SenshuData>('senshuBox');
          List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
          sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
          for (int i = 0; i < sortedSenshuData.length; i++) {
            sortedSenshuData[i].chousi = 100;
            await sortedSenshuData[i].save();
          }
          final Random random = Random();
          for (var senshu in sortedSenshuData) {
            if (senshu.gakunen == 4) {
              if (senshu.anteikan < kantoku.yobiint2[7]) {
                senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[7];
                await senshu.save();
              }
            }
            if (senshu.gakunen == 3) {
              if (senshu.anteikan < kantoku.yobiint2[8]) {
                senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[8];
                await senshu.save();
              }
            }
            if (senshu.gakunen == 2) {
              if (senshu.anteikan < kantoku.yobiint2[9]) {
                senshu.anteikan = random.nextInt(6) + kantoku.yobiint2[9];
                await senshu.save();
              }
            }
          }
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21001 ||
            checkversionValue > 999999999) {
          sortedUnivData[9].name_tanshuku = "1"; //長距離タイム抑制ON
          await sortedUnivData[9].save();
          final kantokuBox = Hive.box<KantokuData>('kantokuBox');
          final KantokuData kantoku = kantokuBox.get('KantokuData')!;
          kantoku.yobiint2[13] = 35; //長距離タイム全体抑制値
          await kantoku.save();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21004 ||
            checkversionValue > 999999999) {
          final senshuDataBox = Hive.box<SenshuData>('senshuBox');
          List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
          sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
          final Random random = Random();
          for (var senshu in sortedSenshuData) {
            ////出身地+趣味
            int targetHobbyIndex = random.nextInt(
              HobbyDatabase.allHobbies.length,
            );
            // 都道府県: 27番目の要素 ("大阪府"と想定) -> インデックス 26
            int targetPrefectureIndex = random.nextInt(
              LocationDatabase.allPrefectures.length,
            );
            // ⭐ パック（格納）
            final int combinedIndex = PackedIndexHelper.packIndices(
              hobbyIndex: targetHobbyIndex,
              prefectureIndex: targetPrefectureIndex,
            );
            senshu.samusataisei = combinedIndex;
            await senshu.save();
          }
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21090 ||
            checkversionValue > 999999999) {
          final Box<KantokuData> kantokuBox = Hive.box<KantokuData>(
            'kantokuBox',
          );
          for (int i_univ = 0; i_univ < TEISUU.UNIVSUU; i_univ++) {
            await resetAbilityTo100Percent(i_univ, kantokuBox);
          }
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21110 ||
            checkversionValue > 999999999) {
          sortedUnivData[10].name_tanshuku = ""; //駅伝結果要約表示用
          await sortedUnivData[10].save();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21120 ||
            checkversionValue > 999999999) {
          final senshuDataBox = Hive.box<SenshuData>('senshuBox');
          List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
          sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
          for (var senshu in sortedSenshuData) {
            senshu.kaifukuryoku = 0;
            await senshu.save();
          }
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21140 ||
            checkversionValue > 999999999) {
          final kantokuBox = Hive.box<KantokuData>('kantokuBox');
          final KantokuData kantoku = kantokuBox.get('KantokuData')!;
          kantoku.yobiint2[16] = 4; //強化練習強度
          await kantoku.save();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21180 ||
            checkversionValue > 999999999) {
          final senshuDataBox = Hive.box<SenshuData>('senshuBox');
          List<SenshuData> sortedSenshuData = senshuDataBox.values.toList();
          sortedSenshuData.sort((a, b) => a.id.compareTo(b.id));
          for (var senshu in sortedSenshuData) {
            if (senshu.kaifukuryoku < 0 || senshu.kaifukuryoku > 5) {
              senshu.kaifukuryoku = 0;
              await senshu.save();
            }
          }
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21240 ||
            checkversionValue > 999999999) {
          final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
          final Ghensuu gh = ghensuuBox.getAt(0)!;
          gh.nouryokumieruflag[0] = 1;
          gh.nouryokumieruflag[1] = 1;
          await gh.save();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21540 ||
            checkversionValue > 999999999) {
          await updateAllSenshuChartdata_atusataisei();
          await refreshAllUnivAnalysisData();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21621 ||
            checkversionValue > 999999999) {
          sortedUnivData[12].name_tanshuku = ""; //統計データ表示用
          await sortedUnivData[12].save();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21661 ||
            checkversionValue > 999999999) {
          sortedUnivData[13].name_tanshuku = ""; //メモ用
          await sortedUnivData[13].save();
        }
      }

      {
        //バージョンアップに伴い付け足す処理を書く
        final checkversionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
        if (checkversionValue == null ||
            checkversionValue < 21690 ||
            checkversionValue > 999999999) {
          sortedUnivData[14].name_tanshuku = ""; //メモ用
          sortedUnivData[15].name_tanshuku = ""; //メモ用
          sortedUnivData[16].name_tanshuku = ""; //メモ用
          sortedUnivData[17].name_tanshuku = ""; //メモ用
          await sortedUnivData[14].save();
          await sortedUnivData[15].save();
          await sortedUnivData[16].save();
          await sortedUnivData[17].save();
        }
      }

      //1.4.3からバージョン番号保存することにした(この処理は一連の処理の中で1番最後にすること)
      //mainの中にもあるので、そちらも変更すること！
      final versionValue = int.tryParse(sortedUnivData[7].name_tanshuku);
      if (versionValue == null ||
          versionValue < 21760 ||
          versionValue > 999999999) {
        sortedUnivData[7].name_tanshuku = "21760"; //バージョン番号
        await sortedUnivData[7].save();
      }

      _showSnackbar('スロット $targetSlot から読み込みました！ ✅');
      // UIの再描画と画面操作を、システム処理が完全に安定するまで遅延させる
    } catch (e) {
      _showSnackbar('読み込みに失敗しました: $e', isError: true);
      print('読み込み失敗 (データコピー): $e');
    }
  }

  // dynamic Boxでクローズするヘルパー（型エラー回避）
  Future<void> _closeBoxDynamic(String boxName) async {
    try {
      final box = Hive.box(boxName); // dynamicで取得
      if (box.isOpen) {
        await box.close();
        print('クローズ成功: $boxName');
      }
    } catch (e) {
      print('クローズエラー ($boxName): $e');
    }
  }

  // 現在の年を取得（Ghensuuから） - getActiveBox使用で型安全
  int _getCurrentYear() {
    try {
      final Box<Ghensuu>? ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      if (ghensuuBox == null || !ghensuuBox.isOpen || ghensuuBox.length == 0)
        return 0;
      final ghensuu = ghensuuBox.getAt(0);
      return ghensuu?.year ?? 0;
    } catch (e) {
      print('年取得エラー: $e');
      return 0;
    }
  }

  // 現在の月を取得（Ghensuuから） - getActiveBox使用で型安全
  int _getCurrentMonth() {
    try {
      final Box<Ghensuu>? ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      if (ghensuuBox == null || !ghensuuBox.isOpen || ghensuuBox.length == 0)
        return 0;
      final ghensuu = ghensuuBox.getAt(0);
      return ghensuu?.month ?? 0;
    } catch (e) {
      print('月取得エラー: $e');
      return 0;
    }
  }

  int _getCurrentDay() {
    try {
      final Box<Ghensuu>? ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      if (ghensuuBox == null || !ghensuuBox.isOpen || ghensuuBox.length == 0)
        return 0;
      final ghensuu = ghensuuBox.getAt(0);
      return ghensuu?.day ?? 0;
    } catch (e) {
      print('日取得エラー: $e');
      return 0;
    }
  }

  String _getDayPhase(int day) {
    if (day == 0) return '';
    if (day <= 10) return '上旬';
    if (day <= 20) return '中旬';
    return '下旬';
  }

  // 現在の大学名を取得（UnivDataから） - getActiveBox使用で型安全
  String _getCurrentUnivName() {
    try {
      final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
      if (univdataBox == null || !univdataBox.isOpen || univdataBox.length == 0)
        return 'プレイヤー大学';
      final List<UnivData> idJunUnivData = univdataBox.values.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final Box<Ghensuu>? ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
      if (ghensuuBox == null ||
          !ghensuuBox.isOpen ||
          ghensuuBox.length == 0 ||
          idJunUnivData.isEmpty) {
        return 'プレイヤー大学';
      }
      final ghensuu = ghensuuBox.getAt(0);
      if (ghensuu != null &&
          ghensuu.MYunivid >= 0 &&
          ghensuu.MYunivid < idJunUnivData.length) {
        return idJunUnivData[ghensuu.MYunivid].name;
      }
      return 'プレイヤー大学';
    } catch (e) {
      print('大学名取得エラー: $e');
      return 'プレイヤー大学';
    }
  }

  // メタデータを更新
  Future<void> _updateMetaData(int slotNum) async {
    if (_metaBox == null) return;
    final metaData = {
      'isUsed': true,
      'date': DateTime.now().toString().substring(0, 16),
      'year': _getCurrentYear(),
      'month': _getCurrentMonth(),
      'day': _getCurrentDay(), // ★★★ 修正箇所 4B: day を保存 ★★★
      'univName': _getCurrentUnivName(),
    };
    await _metaBox!.put(slotNum, metaData);
  }

  // スナックバー表示ヘルパー
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // スロットカードウィジェット（保存/読み込みモード）
  Widget _buildSlotCard(SlotData slot, bool isExportMode) {
    final String statusText = slot.isUsed ? 'データあり' : '空きスロット';
    final Color statusColor = slot.isUsed ? Colors.blueGrey : Colors.green;

    const TextStyle whiteTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
    );
    const TextStyle whiteSmallTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
    );

    // ★★★ 修正箇所 5: 月/日の表示を上旬/中旬/下旬に変更 ★★★
    final String dateDisplay = slot.isUsed && slot.month != 0
        ? '${slot.month}月${_getDayPhase(slot.day)}' // monthと_getDayPhase()を使用
        : '';

    return Card(
      color: Colors.black,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: const BorderSide(color: Colors.white12, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'スロット ${slot.slotNumber}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 16),
            Text(
              slot.isUsed ? '大学名: ${slot.title}' : '---',
              style: whiteTextStyle,
            ),
            const SizedBox(height: 4),
            Text(
              slot.isUsed
                  ? '${slot.year}年 ${dateDisplay != '' ? '$dateDisplay' : ''}'
                  : '---',
              style: whiteSmallTextStyle,
            ),
            const SizedBox(height: 4),
            Text(
              slot.isUsed ? '更新日: ${slot.date}' : '---',
              style: whiteSmallTextStyle,
            ),
            const SizedBox(height: 16),
            // ★ 保存・読み込みボタン (ハンドラを新しい確認経由の関数に変更) ★
            // ★ 修正後の保存・読み込みボタン (排他制御を追加) ★
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isProcessing // ★ 修正: 処理中は null (無効化) にする
                        ? null
                        : isExportMode
                        ? () => _handleExportToSlot(slot.slotNumber)
                        : slot.isUsed
                        ? () => _handleImportFromSlot(slot.slotNumber)
                        : null, // データがない場合は無効化
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExportMode
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade700,
                      disabledForegroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(isExportMode ? '保存' : '読み込み'),
                  ),
                ),
              ],
            ),
            /*Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isExportMode
                        ? () =>
                              _handleExportToSlot(slot.slotNumber) // NEW
                        : slot.isUsed
                        ? () =>
                              _handleImportFromSlot(slot.slotNumber) // NEW
                        : null, // データがない場合は無効化
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExportMode
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade700,
                      disabledForegroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(isExportMode ? '保存' : '読み込み'),
                  ),
                ),
              ],
            ),*/

            // ★ 照合ボタン ★
            /*if (slot.isUsed) // データがあるスロットのみ照合可能
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _runDataVerification(slot.slotNumber),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('現在のデータと照合'),
                      ),
                    ),
                  ],
                ),
              ),*/
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ★ 保存機能を有効にするかどうかの判定フラグ
    // 実際の実装に合わせて、引数やクラス変数から取得してください
    //final bool isSaveEnabled = _checkIfSaveEnabled();

    return PopScope(
      canPop: !_isProcessing,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          _showSnackbar('保存・読み込み処理中です。完了までお待ちください。', isError: true);
        }
      },
      child: DefaultTabController(
        // ★ タブの数を動的に変更
        length: widget.hozonmosuruflag ? 2 : 1,
        child: AbsorbPointer(
          absorbing: _isProcessing,
          child: Scaffold(
            appBar: AppBar(
              // ★ 保存不可ならタイトルを「読み込み」に固定
              title: Text(
                widget.hozonmosuruflag ? '保存 / 読み込み' : '読み込み',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.black,
              // ★ 保存不可の場合は TabBar を表示しない
              bottom: widget.hozonmosuruflag
                  ? const TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.yellow,
                      labelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(text: '保存'),
                        Tab(text: '読み込み'),
                      ],
                    )
                  : null,
            ),
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  // 1. メインコンテンツ
                  TabBarView(
                    // ★ 保存不可の場合は「読み込み画面」のみをリストに入れる
                    children: [
                      if (widget.hozonmosuruflag)
                        // 保存画面
                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            16.0,
                            16.0,
                            80.0,
                          ),
                          child: Column(
                            children: _slots
                                .map((slot) => _buildSlotCard(slot, true))
                                .toList(),
                          ),
                        ),
                      // 読み込み画面（常に表示）
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          16.0,
                          16.0,
                          16.0,
                          80.0,
                        ),
                        child: Column(
                          children: _slots
                              .map((slot) => _buildSlotCard(slot, false))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  // 2. ローディングオーバーレイ (処理中のみ表示)
                  if (_isProcessing)
                    Positioned.fill(
                      child: Container(color: Colors.black.withOpacity(0.8)),
                    ),
                  if (_isProcessing)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.yellow,
                        ),
                        strokeWidth: 5.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /*@override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('保存 / 読み込み', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.yellow,
            labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: '保存'),
              Tab(text: '読み込み'),
            ],
          ),
        ),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: TabBarView(
            children: [
              // 保存画面
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
                child: Column(
                  children: _slots
                      .map((slot) => _buildSlotCard(slot, true))
                      .toList(),
                ),
              ),
              // 読み込み画面
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
                child: Column(
                  children: _slots
                      .map((slot) => _buildSlotCard(slot, false))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }*/
}
