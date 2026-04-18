// data_comparer.dart (新規ファイル)

import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
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

// ここに、以前あなたが定義した _toJson ヘルパー関数を再利用します。
// ただし、全てのクラスをインポートする必要があるため、
// 今回は save_load_screen.dart の _toJson 関数をコピーし、
// Ghensuu, SenshuDataなどのクラスのインポートを追加する必要があります。

// 簡略化のため、ここでは _toJson を使用せずに、
// テストしたいオブジェクトを引数として受け取る汎用関数を定義します。

// -------------------------------------------------------------
// 【重要】
// この関数は、前のステップで定義したすべてのクラスの toJson() メソッドが
// 完全に機能していることを前提としています。
// -------------------------------------------------------------
// deepCompareData は Map<dynamic, dynamic> を受け取るように簡略化します。
bool deepCompareMap(Map<dynamic, dynamic> map1, Map<dynamic, dynamic> map2) {
  const DeepCollectionEquality equality = DeepCollectionEquality();
  return equality.equals(map1, map2);
}

// -------------------------------------------------------------
// 【Box全体を比較する汎用関数】
// Boxの名前とスロット番号を指定して、メインBoxとスロットBox全体を比較します。
// -------------------------------------------------------------
Future<bool> compareBoxContent(String boxName, int slotNumber) async {
  final String slotBoxName = boxName + '_SLOT$slotNumber';

  // メインBoxは開いているはずなので参照
  //final Box mainBox = Hive.box(boxName);
  final mainBox = await _openBoxWithType(boxName);

  // スロットBoxを開く
  final Box slotBox = await Hive.openBox(slotBoxName);

  try {
    if (mainBox.length != slotBox.length) {
      print(
        '❌ Box $boxName: サイズが異なります (${mainBox.length} vs ${slotBox.length})',
      );
      return false;
    }

    // 全キーをチェック
    for (var key in mainBox.keys) {
      final mainValue = mainBox.get(key);
      final slotValue = slotBox.get(key); // スロットにはJSON (Map) で保存されている

      if (slotValue is Map) {
        // --- ★ここを修正★ ---
        // 1. メインのオブジェクトを JSON (Map) に変換
        final Map<String, dynamic> mainJson = mainValue.toJson();

        // 2. スロットの Map を汎用 Map<dynamic, dynamic> にキャストして比較
        // CastMap や _Map などの内部型を回避するため、汎用Mapとして扱います
        final Map slotMap = slotValue as Map;

        // 3. Map 同士をディープ比較
        if (!deepCompareMap(mainJson, slotMap)) {
          print('❌ Box $boxName (キー: $key): 中身が一致しません (Object -> Map) ');
          return false;
        }
        // --- ★修正終わり★ ---
      } else {
        // Map ではない場合 (プリミティブな値など)
        if (mainValue != slotValue) {
          print('❌ Box $boxName (キー: $key): 中身が一致しません (プリミティブ)');
          return false;
        }
      }
    }

    print('✅ Box $boxName: 全てのデータが完全に一致しています。');
    return true;
  } finally {
    // スロットBoxは閉じます
    await slotBox.close();
  }
}
