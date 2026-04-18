import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';

class ModalMoneySettings extends StatefulWidget {
  const ModalMoneySettings({super.key});

  @override
  State<ModalMoneySettings> createState() => _ModalMoneySettingsState();
}

class _ModalMoneySettingsState extends State<ModalMoneySettings> {
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  late KantokuData kantoku;

  // 1: 等倍 (難易度UP), 2: 2倍 (初期値/通常)
  late int _moneyMultiplier;

  // true: 2倍, false: 1倍
  late bool _isDoubleMoney;

  // 💡 修正点 1: 初期化完了フラグを追加
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // kantokuの初期化は同期的に行う
    kantoku = kantokuBox.get('KantokuData') ?? KantokuData();

    // 非同期の初期化処理を呼び出す
    _initializeSettings();
  }

  /// 非同期の初期化処理 (initStateから分離)
  void _initializeSettings() async {
    final int storedValue = kantoku.yobiint2[12];
    int initialMultiplier;

    if (storedValue == 1 || storedValue == 2) {
      initialMultiplier = storedValue;
    } else {
      // 異常値の場合はデフォルト値の2を設定し、保存
      initialMultiplier = 2;
      kantoku.yobiint2[12] = initialMultiplier;
      await kantoku.save();
    }

    // 💡 修正点 2: 初期化完了後に setState で全ての late 変数とフラグを更新
    setState(() {
      _moneyMultiplier = initialMultiplier;
      _isDoubleMoney = (initialMultiplier == 2);
      _isInitialized = true; // 初期化完了
    });
  }

  /// 金銀支給量の倍率 (`yobiint2[12]`) の値を変更し、Hiveに保存する関数
  void _updateMoneyMultiplier(bool isDouble) async {
    final int newMultiplier = isDouble ? 2 : 1;

    setState(() {
      _isDoubleMoney = isDouble;
      _moneyMultiplier = newMultiplier;
      kantoku.yobiint2[12] = newMultiplier;
    });

    await kantoku.save();
  }

  /// スイッチ設定項目のウィジェットを生成 (省略)
  Widget _buildMoneySwitch({
    required String title,
    required String description,
    required bool currentValue,
    required ValueChanged<bool> onChanged,
    Color activeColor = Colors.green,
    Color inactiveColor = Colors.red,
  }) {
    // ... (省略: 前回のコードと同様) ...
    final String settingText = currentValue
        ? '現在の設定: 2倍 (通常)'
        : '現在の設定: 1倍/等倍 (難易度UP)';

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
    // 💡 修正点 3: 初期化が完了するまでローディング表示
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text(
            '💰 金銀支給量設定',
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
        // ... (以下は前回のコードと同様) ...
        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '💰 金銀支給量設定 (Sと比較)',
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
                  // 説明文のWidget (省略)
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
                      "この設定は、前作（S）と比較した、ゲーム内での金銀（ゲーム内通貨）の獲得量を切り替えることができます。\n\n**ON (2倍)**: 前作と比較して金銀の獲得量が**2倍**になります。資源が豊富になり、ゲーム難易度が下がります。\n**OFF (1倍/等倍)**: 前作と同じ、金銀の獲得量が**等倍**になります。難易度が上昇します。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  // 金銀支給量設定スイッチ
                  _buildMoneySwitch(
                    title: '金銀支給量を2倍にする',
                    description:
                        'ONにすると前作Sと比較して金銀の獲得量が2倍になります。難易度を上げたい場合はOFFにしてください。',
                    currentValue: _isDoubleMoney, // 👈 初期化済みの変数にアクセス
                    onChanged: _updateMoneyMultiplier,
                    activeColor: Colors.green,
                    inactiveColor: Colors.red,
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
