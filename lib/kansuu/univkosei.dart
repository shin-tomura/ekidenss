import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart';
// 必要に応じて他のクラスもインポート（この例ではKantokuDataのみを使用）

// ------------------------------------------------
// 8種類の能力のインデックスを定義
// ------------------------------------------------
enum AbilityType {
  nagakyoriNebari, // 0: 長距離粘り
  spurtPower, // 1: スパート力
  charisma, // 2: カリスマ
  noboriTekisei, // 3: 登り適性
  kudariTekisei, // 4: 下り適性
  upDownTaiouryoku, // 5: アップダウン対応力
  roadTekisei, // 6: ロード適性
  paceHendoTaiouryoku, // 7: ペース変動対応力
}

/// 指定された大学IDの実力発揮度（0-9）を抽出する関数
///
/// @param universityId 対象の大学ID (currentGhensuu.hyojiunivnumなど)
/// @return Key: AbilityType, Value: 実力発揮度(0-9) のマップ
Map<AbilityType, int> getAbilitySettingsForUniv(int universityId) {
  // Hive Boxを取得
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final KantokuData? kantoku = kantokuBox.get('KantokuData');

  if (kantoku == null ||
      universityId < 0 ||
      universityId >= kantoku.yobiint5.length) {
    // データがない、または不正な大学IDの場合は、デフォルト値（例：すべて0）を返す
    return {for (var type in AbilityType.values) type: 0};
  }

  // 対象大学の圧縮された値を取得
  final int compressedValue = kantoku.yobiint5[universityId];

  Map<AbilityType, int> values = {};

  // 8種類の能力をループ処理
  for (int i = 0; i < 8; i++) {
    // i番目の能力のインデックス (0=長距離粘り, 1=スパート力, ...)
    final AbilityType type = AbilityType.values[i];

    // 圧縮値からi番目の能力（4ビット）を抽出
    // 1. (compressedValue >> (i * 4)): 目的の4ビットを最下位にシフト
    // 2. & 0xF: ビットマスク(0b1111)で下位4ビットのみを抽出
    final int value = (compressedValue >> (i * 4)) & 0xF;

    // 0-9の範囲に限定して格納 (不正なデータが入っていた場合の安全策)
    values[type] = value.clamp(0, 9);
  }

  return values;
}

// kantoku_data.dart, AbilityType, KantokuData, Box<KantokuData> が利用可能であることを前提とする

/// 指定された大学ID (univid) の全能力の実力発揮度を5 (実力100%発揮) にリセットし、保存する関数。
///
/// @param univid 対象の大学ID
/// @param kantokuBox HiveのKantokuDataを格納するBox
Future<void> resetAbilityTo100Percent(
  int univid,
  Box<KantokuData> kantokuBox,
) async {
  // 実力発揮度「5」は「実力100%発揮」に相当します。
  const int targetValue = 5;

  // 1. すべての能力をtargetValueに設定したMapを作成
  Map<AbilityType, int> resetValues = {};
  for (final type in AbilityType.values) {
    // 8種類の能力すべてに「5」を設定
    resetValues[type] = targetValue;
  }

  // 2. 8種類の能力値 (5, 5, 5, ...) をint型データに圧縮
  // このロジックは、提供されたコード内の _compressAbilityValues と同じ原理に基づきます。
  int compressedValue = 0;
  for (int i = 0; i < AbilityType.values.length; i++) {
    // AbilityTypeのインデックス i (0〜7)
    final int value = resetValues[AbilityType.values[i]] ?? targetValue; // 5を格納
    // 4ビットシフトしてORで結合: (5 << 0*4) | (5 << 1*4) | ... | (5 << 7*4)
    compressedValue |= (value << (i * 4));
  }

  // 3. KantokuDataを取得し、更新
  KantokuData? kantoku = kantokuBox.get('KantokuData');
  if (kantoku == null) {
    // データがない場合は新しいインスタンスを作成（要件によるが、ここではデータを保持するため）
    // 実際にKantokuDataがどのような初期化を想定しているかにより調整が必要です。
    kantoku = KantokuData();
  }

  // unividに対応するデータを更新
  // yobiint5はList<int>として定義されていると想定されます。
  // 必要に応じてListのサイズをunivid+1まで拡張する処理が必要かもしれません。
  // (提供されたコードではこのリスト拡張ロジックが省略されているため、ここではリストのアクセスに成功すると仮定します)
  if (univid >= 0 && univid < TEISUU.UNIVSUU) {
    kantoku.yobiint5[univid] = compressedValue;
  } else {
    // yobiint5のサイズ不足など、エラー処理
    print('Error: Invalid univid or yobiint5 list size is insufficient.');
    return;
  }

  // 4. Hiveに保存
  await kantoku.save();

  print('Univ ID $univid の能力実力発揮度を全て $targetValue (100%) にリセットしました。');
  print(
    '格納された圧縮値: $compressedValue (Hex: ${compressedValue.toRadixString(16)})',
  );
}
