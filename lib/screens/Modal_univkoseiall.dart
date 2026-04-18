import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // TEISUU, HENSUUクラスがあるはずのインポート
import 'package:ekiden/kantoku_data.dart'; // KantokuDataクラスがあるはずのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスがあるはずのインポート

// ------------------------------------------------
// 8種類の能力のインデックスと名前を定義 (参考コードから再掲)
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

class AbilitySetting {
  final AbilityType type;
  final String label;

  const AbilitySetting(this.type, this.label);
}

// 8種類の能力の定義リスト (参考コードから再掲)
const List<AbilitySetting> _ABILITY_SETTINGS = [
  AbilitySetting(AbilityType.nagakyoriNebari, '長距離粘り'),
  AbilitySetting(AbilityType.spurtPower, 'スパート力'),
  AbilitySetting(AbilityType.charisma, 'カリスマ'),
  AbilitySetting(AbilityType.noboriTekisei, '登り適性'),
  AbilitySetting(AbilityType.kudariTekisei, '下り適性'),
  AbilitySetting(AbilityType.upDownTaiouryoku, 'アップダウン対応力'),
  AbilitySetting(AbilityType.roadTekisei, 'ロード適性'),
  AbilitySetting(AbilityType.paceHendoTaiouryoku, 'ペース変動対応力'),
];

// 一斉変更対象とする能力 (カリスマ以外)
const List<AbilityType> _BULK_CHANGE_ABILITIES = [
  AbilityType.nagakyoriNebari,
  AbilityType.spurtPower,
  // AbilityType.charisma, // カリスマは除外
  AbilityType.noboriTekisei,
  AbilityType.kudariTekisei,
  AbilityType.upDownTaiouryoku,
  AbilityType.roadTekisei,
  AbilityType.paceHendoTaiouryoku,
];

// 一斉変更用の能力設定リスト
final List<AbilitySetting> _BULK_CHANGE_ABILITY_SETTINGS = _ABILITY_SETTINGS
    .where((setting) => _BULK_CHANGE_ABILITIES.contains(setting.type))
    .toList();

// 実力発揮度の選択肢 (0-9)
final List<int> _ABILITY_VALUES = List.generate(10, (i) => i);

// ------------------------------------------------
// 全大学 能力実力発揮度一斉設定画面
// ------------------------------------------------
class ModalAllUnivAbilityBulkSettingView extends StatefulWidget {
  const ModalAllUnivAbilityBulkSettingView({super.key});

  @override
  State<ModalAllUnivAbilityBulkSettingView> createState() =>
      _ModalAllUnivAbilityBulkSettingViewState();
}

class _ModalAllUnivAbilityBulkSettingViewState
    extends State<ModalAllUnivAbilityBulkSettingView> {
  final Box<KantokuData> kantokuBox = Hive.box<KantokuData>('kantokuBox');

  // 選択された能力 (初期値は長距離粘り)
  AbilityType _selectedAbilityType = AbilityType.nagakyoriNebari;
  // 選択された実力発揮度 (初期値は5: 実力100%発揮)
  int _selectedAbilityValue = 5;

  @override
  void initState() {
    super.initState();
    // ドロップダウンの初期値が設定リストに含まれているか確認
    if (!_BULK_CHANGE_ABILITIES.contains(_selectedAbilityType)) {
      _selectedAbilityType = _BULK_CHANGE_ABILITY_SETTINGS.first.type;
    }
  }

  // ------------------------------------------------
  // データ圧縮・展開ロジック (参考コードから再掲)
  // ------------------------------------------------

  /// int型データから8種類の能力値 (0-9) を抽出
  // (今回は使用しないが、念のため残す)
  Map<AbilityType, int> _extractAbilityValues(int compressedValue) {
    Map<AbilityType, int> values = {};
    for (int i = 0; i < 8; i++) {
      final AbilityType type = AbilityType.values[i];
      final int value = (compressedValue >> (i * 4)) & 0xF;
      values[type] = value.clamp(0, 9);
    }
    return values;
  }

  /// 8種類の能力値 (0-9) をint型データに圧縮して返す
  int _compressAbilityValues(Map<AbilityType, int> values) {
    int compressedValue = 0;
    for (int i = 0; i < 8; i++) {
      final AbilityType type = AbilityType.values[i];
      final int value = values[type]?.clamp(0, 9) ?? 0;
      compressedValue |= (value << (i * 4));
    }
    return compressedValue;
  }

  // ------------------------------------------------
  // 一斉変更ロジック
  // ------------------------------------------------

  /// 全大学を対象に、選択された能力の実力発揮度を一斉に変更する
  void _applyBulkChange() async {
    // 1. KantokuDataを取得
    final KantokuData? kantoku = kantokuBox.get('KantokuData');
    if (kantoku == null) {
      _showResultDialog('エラー', '設定データが見つかりませんでした。', Colors.red);
      return;
    }

    final int targetAbilityIndex = _selectedAbilityType.index;
    final int newValue = _selectedAbilityValue;
    int updateCount = 0;

    // 2. 全大学（0からTEISUU.UNIVSUU-1）に対してループ
    for (int i = 0; i < TEISUU.UNIVSUU; i++) {
      int currentCompressedValue = kantoku.yobiint5[i];

      // 3. 既存の圧縮データから、対象能力以外の値を抽出・保持
      Map<AbilityType, int> currentValues = _extractAbilityValues(
        currentCompressedValue,
      );

      // 4. 対象能力の値を新しい値に更新
      // 値を更新するのは、対象能力がカリスマ以外かつ0-9の範囲内であることを前提とする
      if (currentValues[_selectedAbilityType] != newValue) {
        currentValues[_selectedAbilityType] = newValue;

        // 5. 更新後の全能力値から新しい圧縮値を作成
        final int newCompressedValue = _compressAbilityValues(currentValues);

        // 6. KantokuDataを更新
        kantoku.yobiint5[i] = newCompressedValue;
        updateCount++;
      }
    }

    // 7. Hiveに保存
    await kantoku.save();

    // 8. 結果メッセージを表示
    final String abilityLabel = _BULK_CHANGE_ABILITY_SETTINGS
        .firstWhere((s) => s.type == _selectedAbilityType)
        .label;
    final String resultMessage =
        //'全${TEISUU.UNIVSUU}大学のうち、${updateCount}大学の「${abilityLabel}」の実力発揮度を\n「${_getAbilityRankLabel(newValue)}」\nに一斉変更しました。';
        '${updateCount}大学の「${abilityLabel}」の実力発揮度を\n「${_getAbilityRankLabel(newValue)}」\nに一斉変更しました。';
    _showResultDialog('完了', resultMessage, Colors.green);
  }

  // ------------------------------------------------
  // UIコンポーネント
  // ------------------------------------------------

  // 実力発揮度のラベルを取得 (参考コードから再掲)
  String _getAbilityRankLabel(int value) {
    switch (value) {
      case 0:
        return '0 (実力150%発揮)';
      case 1:
        return '1 (実力140%発揮)';
      case 2:
        return '2 (実力130%発揮)';
      case 3:
        return '3 (実力120%発揮)';
      case 4:
        return '4 (実力110%発揮)';
      case 5:
        return '5 (実力100%発揮)';
      case 6:
        return '6 (実力90%発揮)';
      case 7:
        return '7 (実力80%発揮)';
      case 8:
        return '8 (実力70%発揮)';
      case 9:
        return '9 (実力60%発揮)';
      default:
        return '---';
    }
  }

  /// 確認ダイアログの表示
  void _showConfirmDialog() {
    final String abilityLabel = _BULK_CHANGE_ABILITY_SETTINGS
        .firstWhere((s) => s.type == _selectedAbilityType)
        .label;
    final String targetValueLabel = _getAbilityRankLabel(_selectedAbilityValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('一斉変更の確認'),
          content: Text(
            '本当に全${TEISUU.UNIVSUU}大学の「${abilityLabel}」の実力発揮度を\n「${targetValueLabel}」\nに一斉変更してもよろしいですか？\nこの操作は元に戻せません。',
            style: TextStyle(color: const Color.fromARGB(255, 6, 6, 6)),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('一斉変更を実行', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // 確認ダイアログを閉じる
                _applyBulkChange(); // 変更を実行
              },
            ),
          ],
        );
      },
    );
  }

  /// 処理結果ダイアログの表示
  void _showResultDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: color)),
          content: Text(
            message,
            style: TextStyle(color: const Color.fromARGB(255, 6, 6, 6)),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('閉じる'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {}); // UIを再描画して最新の状態を反映
              },
            ),
          ],
        );
      },
    );
  }

  // ドロップダウンリストのウィジェットを生成
  Widget _buildDropdown<T>({
    required String title,
    required T value,
    required List<T> items,
    required String Function(T) displayLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: HENSUU.backgroundcolor,
              style: TextStyle(
                color: HENSUU.textcolor,
                fontSize: HENSUU.fontsize_honbun,
              ),
              items: items.map<DropdownMenuItem<T>>((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(displayLabel(item)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '全大学 実力発揮度一斉設定',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // 設定の説明
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
                ),
                child: Text(
                  "この画面では、選択した能力値について、全${TEISUU.UNIVSUU}大学の選手の実力発揮度を一律で設定します。\n\n0が実力150%発揮(有利)、9が実力60%発揮(不利) です。\nなお、留学生には適用されません。\n※100％を超える設定の場合、たとえば、フラットなコースよりアップダウンのある方がタイムが速くなってしまうなど、不自然な現象が発生する可能性があります。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),

              const Divider(color: Colors.grey),
              const SizedBox(height: 16),

              // 1. 能力値の選択ドロップダウン
              _buildDropdown<AbilityType>(
                title: '【STEP 1】一斉変更したい能力値を選ぶ',
                value: _selectedAbilityType,
                items: _BULK_CHANGE_ABILITY_SETTINGS
                    .map((s) => s.type)
                    .toList(),
                displayLabel: (type) =>
                    _ABILITY_SETTINGS.firstWhere((s) => s.type == type).label,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedAbilityType = newValue;
                    });
                  }
                },
              ),

              // 2. 実力発揮度の選択ドロップダウン
              _buildDropdown<int>(
                title: '【STEP 2】一斉変更後の実力発揮度を選ぶ',
                value: _selectedAbilityValue,
                items: _ABILITY_VALUES,
                displayLabel: (value) => _getAbilityRankLabel(value),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedAbilityValue = newValue;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // 3. 一斉変更ボタン
              ElevatedButton(
                onPressed: _showConfirmDialog, // 確認メッセージを経由
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 60),
                  padding: const EdgeInsets.all(16.0),
                ),
                child: Text(
                  "【STEP 3】全大学一斉 実力発揮度変更(ここを押す)",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun + 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Colors.grey),
              const SizedBox(height: 24),

              // 閉じるボタン
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(200, 48),
                  padding: const EdgeInsets.all(12.0),
                ),
                child: Text(
                  "画面を閉じる",
                  style: TextStyle(
                    fontSize: HENSUU.fontsize_honbun,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
