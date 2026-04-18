import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // 💡 参照元にあるが、ここでは定義がないためコメントアウト/適宜修正
import 'package:ekiden/kantoku_data.dart'; // 💡 参照元にあるが、ここでは定義がないためコメントアウト/適宜修正

class ModalRaceTimeSettings extends StatefulWidget {
  const ModalRaceTimeSettings({super.key});

  @override
  State<ModalRaceTimeSettings> createState() => _ModalRaceTimeSettingsState();
}

class _ModalRaceTimeSettingsState extends State<ModalRaceTimeSettings> {
  // 💡 修正点 1: ボックス名とデータ型は参照元と同様
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  late KantokuData kantoku;

  // 💡 修正点 2: 記録会時期の設定値 (0 または 1)
  // 0: 11月〜12月 (デフォルト/通常), 1: 9月 (時期早め)
  late int _raceTimeSetting;

  // 💡 修正点 3: スイッチの状態 (true: 9月, false: 11月〜12月)
  late bool _isEarlyRaceTime;

  // 初期化完了フラグ
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    kantoku = kantokuBox.get('KantokuData') ?? KantokuData();
    _initializeSettings();
  }

  /// 非同期の初期化処理
  void _initializeSettings() async {
    // 💡 修正点 4: 使用するインデックスを `14` に変更
    final int storedValue = kantoku.yobiint2[14];
    int initialSetting;

    if (storedValue == 0 || storedValue == 1) {
      initialSetting = storedValue;
    } else {
      // 異常値の場合はデフォルト値の 0 を設定し、保存
      initialSetting = 0;
      kantoku.yobiint2[14] = initialSetting;
      await kantoku.save();
    }

    setState(() {
      _raceTimeSetting = initialSetting;
      // 💡 修正点 5: `_isEarlyRaceTime` は `1` の場合に `true` (9月開催)
      _isEarlyRaceTime = (initialSetting == 1);
      _isInitialized = true; // 初期化完了
    });
  }

  /// 記録会の時期設定 (`yobiint2[14]`) の値を変更し、Hiveに保存する関数
  void _updateRaceTimeSetting(bool isEarly) async {
    // 💡 修正点 6: `true` なら `1` (9月)、`false` なら `0` (11月〜12月)
    final int newSetting = isEarly ? 1 : 0;

    setState(() {
      _isEarlyRaceTime = isEarly;
      _raceTimeSetting = newSetting;
      kantoku.yobiint2[14] = newSetting;
    });

    await kantoku.save();
  }

  /// スイッチ設定項目のウィジェットを生成 (表示内容を記録会設定用に変更)
  Widget _buildRaceTimeSwitch({
    required String title,
    required String description,
    required bool currentValue,
    required ValueChanged<bool> onChanged,
    Color activeColor = Colors.orange, // 9月開催 (早期)
    Color inactiveColor = Colors.blue, // 11月〜12月開催 (通常)
  }) {
    // 💡 修正点 7: 表示テキストを記録会時期の設定内容に変更
    final String settingText = currentValue
        ? '現在の設定: 9月開催 (早期)'
        : '現在の設定: 11月〜12月開催 (通常)';

    final Color textColor = currentValue ? activeColor : inactiveColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(
            title,
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            description,
            style: TextStyle(
              color: HENSUU.textcolor.withOpacity(0.8),
              fontSize: HENSUU.fontsize_honbun - 2,
            ),
          ),
          value: currentValue,
          onChanged: onChanged,
          activeColor: activeColor,
          inactiveThumbColor: inactiveColor,
          inactiveTrackColor: inactiveColor.withOpacity(0.5),
          tileColor: Colors.blueGrey.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 4.0,
            bottom: 8.0,
          ),
          child: Text(
            settingText,
            style: TextStyle(
              color: textColor,
              fontSize: HENSUU.fontsize_honbun - 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(color: Colors.grey),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 初期化が完了するまでローディング表示
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          // 💡 修正点 8: タイトルを記録会設定に変更
          title: const Text(
            '📅 記録会時期設定',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: HENSUU.backgroundcolor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ValueListenableBuilderでHiveの変更を監視
    return ValueListenableBuilder<Box<KantokuData>>(
      valueListenable: kantokuBox.listenable(),
      builder: (context, box, _) {
        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            // 💡 修正点 9: タイトルを記録会設定に変更
            title: const Text(
              '📅 記録会時期設定',
              style: TextStyle(color: Colors.white),
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
                  // 💡 修正点 10: 説明文を記録会設定の内容に変更
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.lightGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.lightGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "記録会（市民ハーフ・1万m・5千m）の開催時期を切り替えることができます。\n\nON (9月開催): 記録会を9月に行います。\nOFF (11月〜12月開催): 記録会を11月〜12月に行います。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  // 記録会時期設定スイッチ
                  _buildRaceTimeSwitch(
                    title: '記録会の時期を設定',
                    description: 'ONにすると記録会が9月に開催されます。OFFにすると11月〜12月に開催されます。',
                    currentValue: _isEarlyRaceTime,
                    onChanged: _updateRaceTimeSetting,
                    activeColor: Colors.orange,
                    inactiveColor: Colors.blue,
                  ),

                  const SizedBox(height: 32),

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
      },
    );
  }
}
