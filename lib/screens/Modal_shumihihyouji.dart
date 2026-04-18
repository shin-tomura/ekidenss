import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // 💡 参照元にあるが、ここでは定義がないためコメントアウト/適宜修正
import 'package:ekiden/kantoku_data.dart'; // 💡 参照元にあるが、ここでは定義がないためコメントアウト/適宜修正

// クラス名を変更: 記録会設定 $\rightarrow$ 趣味表示設定
class ModalHobbyDisplaySettings extends StatefulWidget {
  const ModalHobbyDisplaySettings({super.key});

  @override
  State<ModalHobbyDisplaySettings> createState() =>
      _ModalHobbyDisplaySettingsState();
}

// ステートクラス名を変更
class _ModalHobbyDisplaySettingsState extends State<ModalHobbyDisplaySettings> {
  // ボックス名とデータ型は参照元と同様
  // 💡 実際の Hive の初期化が必要です。ここでは仮の型を使用
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  late KantokuData kantoku;

  // 💡 変更点 1: 趣味表示設定値 (0: 表示, 1: 非表示)
  late int _hobbyDisplaySetting;

  // 💡 変更点 2: スイッチの状態 (true: 非表示, false: 表示)
  // kantoku.yobiint2[15]が1だと非表示(true)、0だと表示(false)
  late bool _isHobbyHidden;

  // 初期化完了フラグ
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 💡 実際のデータ取得。null の場合はデフォルト値を返す
    kantoku = kantokuBox.get('KantokuData') ?? KantokuData();
    _initializeSettings();
  }

  /// 非同期の初期化処理
  void _initializeSettings() async {
    // 💡 変更点 3: 使用するインデックスを `15` に変更
    final int storedValue = kantoku.yobiint2[15];
    int initialSetting;

    // 設定値のバリデーション (0 または 1 のみ)
    if (storedValue == 0 || storedValue == 1) {
      initialSetting = storedValue;
    } else {
      // 異常値の場合はデフォルト値の 0 (表示) を設定し、保存
      initialSetting = 0;
      kantoku.yobiint2[15] = initialSetting;
      await kantoku.save();
    }

    setState(() {
      _hobbyDisplaySetting = initialSetting;
      // 💡 変更点 4: `_isHobbyHidden` は `1` の場合に `true` (非表示)
      _isHobbyHidden = (initialSetting == 1);
      _isInitialized = true; // 初期化完了
    });
  }

  /// 趣味表示設定 (`yobiint2[15]`) の値を変更し、Hiveに保存する関数
  void _updateHobbyDisplaySetting(bool isHidden) async {
    // 💡 変更点 5: `true` なら `1` (非表示)、`false` なら `0` (表示)
    final int newSetting = isHidden ? 1 : 0;

    setState(() {
      _isHobbyHidden = isHidden;
      _hobbyDisplaySetting = newSetting;
      kantoku.yobiint2[15] = newSetting;
    });

    await kantoku.save();
  }

  /// スイッチ設定項目のウィジェットを生成 (表示内容を趣味表示設定用に変更)
  Widget _buildHobbyDisplaySwitch({
    required String title,
    required String description,
    required bool currentValue,
    required ValueChanged<bool> onChanged,
    Color activeColor = Colors.red, // 非表示 (目立たせる)
    Color inactiveColor = Colors.green, // 表示 (通常)
  }) {
    // 💡 変更点 6: 表示テキストを趣味表示設定の内容に変更
    final String settingText = currentValue ? '現在の設定: 非表示' : '現在の設定: 表示';

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
          // 💡 変更点 7: タイトルを趣味表示設定に変更
          title: const Text(
            '🎭 趣味非表示設定',
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
            // 💡 変更点 8: タイトルを趣味表示設定に変更
            title: const Text(
              '🎭 趣味非表示設定',
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
                  // 💡 変更点 9: 説明文を趣味表示設定の内容に変更
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.lightBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "選手プロフィール画面での趣味の表示・非表示を切り替えることができます。\n\nON (非表示): 趣味の情報を画面に表示しません。\nOFF (表示): 趣味の情報を画面に表示します。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  // 趣味表示設定スイッチ
                  _buildHobbyDisplaySwitch(
                    title: '趣味の表示・非表示を切り替え',
                    description: 'ONにすると選手プロフィール画面で趣味が非表示になります。',
                    currentValue: _isHobbyHidden,
                    onChanged: _updateHobbyDisplaySetting,
                    activeColor: Colors.red, // 非表示
                    inactiveColor: Colors.green, // 表示
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
