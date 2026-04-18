import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスがあるはずのインポート
import 'package:ekiden/kantoku_data.dart'; // KantokuDataクラスがあるはずのインポート
import 'package:ekiden/univ_data.dart'; // UnivDataクラスがあるはずのインポート

// ------------------------------------------------
// 8種類の能力のインデックスと名前を定義
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
  //final String description;

  const AbilitySetting(this.type, this.label);
}

// 8種類の能力の定義リスト
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

// テスト時に表示したい能力 (ここで能力を限定)
const List<AbilityType> _TEST_ABILITIES = [
  AbilityType.nagakyoriNebari,
  AbilityType.spurtPower,
  AbilityType.noboriTekisei,
  AbilityType.kudariTekisei,
  AbilityType.upDownTaiouryoku,
  AbilityType.roadTekisei,
  AbilityType.paceHendoTaiouryoku,
];

// **********************************************
// ★ リリース時に全能力を表示したい場合はここを false に設定 ★
const bool _TEST_ABILITIES_ONLY = true;
// **********************************************

// ------------------------------------------------
// 大学別 能力実力発揮度設定画面
// ------------------------------------------------
class ModalUnivAbilitySettingView extends StatefulWidget {
  const ModalUnivAbilitySettingView({super.key});

  @override
  State<ModalUnivAbilitySettingView> createState() =>
      _ModalUnivAbilitySettingViewState();
}

class _ModalUnivAbilitySettingViewState
    extends State<ModalUnivAbilitySettingView> {
  final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
  final Box<KantokuData> kantokuBox = Hive.box<KantokuData>('kantokuBox');

  late int _targetUnivId;
  late String _univName;
  late KantokuData _kantoku;

  // Key: AbilityType, Value: 発揮度 (0-9) のローカル状態
  late Map<AbilityType, int> _currentAbilityValues;

  @override
  void initState() {
    super.initState();
    final Ghensuu? currentGhensuu = ghensuuBox.getAt(0);
    _targetUnivId = currentGhensuu?.hyojiunivnum ?? -1;

    // 大学名を取得
    final Box<UnivData> univdataBox = Hive.box<UnivData>('univBox');
    final UnivData? univ = univdataBox.get(_targetUnivId);
    _univName = univ?.name ?? '不明な大学';

    // KantokuDataを取得し、初期値を設定
    _kantoku = kantokuBox.get('KantokuData') ?? KantokuData();
    _currentAbilityValues = _extractAbilityValues(
      _kantoku.yobiint5[_targetUnivId],
    );
  }

  // ------------------------------------------------
  // データ圧縮・展開ロジック
  // ------------------------------------------------

  /// int型データから8種類の能力値 (0-9) を抽出
  Map<AbilityType, int> _extractAbilityValues(int compressedValue) {
    Map<AbilityType, int> values = {};
    for (int i = 0; i < 8; i++) {
      // i番目の能力のインデックス (0=長距離粘り, 1=スパート力, ...)
      final AbilityType type = AbilityType.values[i];
      // 4ビット (0-15) を抽出
      final int value = (compressedValue >> (i * 4)) & 0xF;
      // 0-9の範囲に限定して格納
      values[type] = value.clamp(0, 9);
    }
    return values;
  }

  /// 8種類の能力値 (0-9) をint型データに圧縮して返す
  int _compressAbilityValues(Map<AbilityType, int> values) {
    int compressedValue = 0;
    for (int i = 0; i < 8; i++) {
      final AbilityType type = AbilityType.values[i];
      // 値を取得し、0-9の範囲に強制
      final int value = values[type]?.clamp(0, 9) ?? 0;
      // 4ビットシフトしてORで結合
      compressedValue |= (value << (i * 4));
    }
    return compressedValue;
  }

  // ------------------------------------------------
  // UI更新・データ保存ロジック
  // ------------------------------------------------

  /// 特定の能力値を更新し、全体を再圧縮してHiveに保存する
  void _updateAbilityValue(AbilityType type, double sliderValue) async {
    final int newValue = sliderValue.toInt().clamp(0, 9);

    setState(() {
      _currentAbilityValues[type] = newValue;

      // 1. 全能力値から新しい圧縮値を作成
      final int newCompressedValue = _compressAbilityValues(
        _currentAbilityValues,
      );

      // 2. KantokuDataを更新
      _kantoku.yobiint5[_targetUnivId] = newCompressedValue;
    });

    // 3. Hiveに保存
    await _kantoku.save();
  }

  // ------------------------------------------------
  // UIコンポーネント
  // ------------------------------------------------

  // 実力発揮度のラベルを取得
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

  // 設定項目のウィジェットを生成
  Widget _buildAbilitySlider({
    required AbilityType type,
    required String title,
    required int currentValue,
  }) {
    // 0が最も良い設定なので、色を反転させる
    final Color activeColor = Color.lerp(
      Colors.green,
      Colors.red.shade700,
      currentValue / 9,
    )!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${title} 発揮度設定',
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 現在の値表示
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            '現在の発揮度: ${_getAbilityRankLabel(currentValue)}',
            style: TextStyle(
              color: currentValue == 0 ? Colors.greenAccent : activeColor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // スライダー本体
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: currentValue.toDouble(),
                min: 0,
                max: 9,
                divisions: 9, // 0から9の10段階
                label: currentValue.toString(),
                onChanged: (newValue) {
                  // スライダーを動かしている間はローカル状態のみ更新
                  setState(() {
                    _currentAbilityValues[type] = newValue.toInt();
                  });
                },
                onChangeEnd: (newValue) {
                  // スライダーを離したときにHiveに保存
                  _updateAbilityValue(type, newValue);
                },
                activeColor: activeColor,
                inactiveColor: Colors.grey.withOpacity(0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '0 (最大実力発揮)',
                        style: TextStyle(
                          color: HENSUU.textcolor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '9 (最小実力発揮)',
                        style: TextStyle(
                          color: HENSUU.textcolor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: Colors.grey),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 表示する能力リストを決定
    final List<AbilitySetting> displayAbilities = _TEST_ABILITIES_ONLY
        ? _ABILITY_SETTINGS
              .where((setting) => _TEST_ABILITIES.contains(setting.type))
              .toList()
        : _ABILITY_SETTINGS;

    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: Text(
          '$_univName 実力発揮度設定',
          style: const TextStyle(color: Colors.white, fontSize: 16),
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
                  "この画面では、$_univName大学の選手の各種能力ごとの実力発揮度を設定します。\n\n0が実力150%発揮(有利)、9が実力60%発揮(不利) です。数値を大きくするほど、その能力が必要な場面で実力を発揮しにくくなります。\nなお、留学生には適用されません。\n※100％を超える設定の場合、たとえば、フラットなコースよりアップダウンのある方がタイムが速くなってしまうなど、不自然な現象が発生する可能性があります。",
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),

              const Divider(color: Colors.grey),
              const SizedBox(height: 16),

              // 能力設定スライダー
              ...displayAbilities.map((setting) {
                return _buildAbilitySlider(
                  type: setting.type,
                  title: setting.label,
                  currentValue: _currentAbilityValues[setting.type] ?? 0,
                );
              }).toList(),

              const SizedBox(height: 16),
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
                  "閉じる",
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
