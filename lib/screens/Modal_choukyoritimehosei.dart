import 'package:ekiden/kantoku_data.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスがあるはずのインポート
import 'package:ekiden/univ_data.dart'; // 実際のUnivDataクラスのインポートパス

class ModalPaceAdjustment extends StatefulWidget {
  const ModalPaceAdjustment({super.key});

  @override
  State<ModalPaceAdjustment> createState() => _ModalPaceAdjustmentState();
}

class _ModalPaceAdjustmentState extends State<ModalPaceAdjustment> {
  late Box<UnivData> _univDataBox;
  late Box<KantokuData> _kantokuBox; // KantokuDataを扱うためのBox

  // 長距離全体タイム抑制値 (yobiint2[13]) のための変数
  int _longDistanceTimeSuppressionValue = 0;
  // yobiint2[13]のインデックス
  static const int _suppressionValueIndex = 13;

  // 補正フラグの対象となるUnivDataのインデックスを 9 に設定
  final int _correctionFlagIndex = 9;

  @override
  void initState() {
    super.initState();
    _univDataBox = Hive.box<UnivData>('univBox');
    // Boxは既に開かれている前提で取得
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
    _loadSuppressionValue();
  }

  // KantokuDataから抑制値をロードする関数
  void _loadSuppressionValue() {
    // 'KantokuData'キーでKantokuDataインスタンスを取得
    final kantoku = _kantokuBox.get('KantokuData');

    if (kantoku != null && kantoku.yobiint2.length > _suppressionValueIndex) {
      setState(() {
        // yobiint2[13]の値を取得し、-18から50の範囲内に丸める
        _longDistanceTimeSuppressionValue =
            (kantoku.yobiint2[_suppressionValueIndex] as int).clamp(-18, 50);
      });
    } else {
      // データが存在しない、または初期化されていない場合の初期値設定
      _longDistanceTimeSuppressionValue = 35;
      _saveSuppressionValue(_longDistanceTimeSuppressionValue);
    }
  }

  // 抑制値をHiveに保存する関数
  void _saveSuppressionValue(int newValue) async {
    final kantoku = _kantokuBox.get('KantokuData');
    if (kantoku != null && kantoku.yobiint2.length > _suppressionValueIndex) {
      // 値を更新
      kantoku.yobiint2[_suppressionValueIndex] = newValue;
      // Hiveに保存
      await kantoku.save();
      // 状態の更新
      setState(() {
        _longDistanceTimeSuppressionValue = newValue;
      });
    } else {
      // エラー処理（KantokuDataが見つからない場合など）
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('KantokuDataの保存に失敗しました。')));
    }
  }

  // 補正フラグの文字列をトグルし、Hiveに保存する関数
  void _toggleCorrectionFlag(UnivData univData) async {
    // 現在の値を確認し、'1' (ON) と '0' (OFF) を切り替える
    final String currentFlag = univData.name_tanshuku;
    final String newFlag = currentFlag == '1' ? '0' : '1';

    setState(() {
      univData.name_tanshuku = newFlag;
    });

    // Hiveに保存
    await univData.save();
  }

  // フラグの現在の状態を判別する関数
  bool _isCorrectionEnabled(UnivData? univData) {
    if (univData == null) return false;
    // フラグが "1" なら補正ON
    return univData.name_tanshuku == '1';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<UnivData>>(
      valueListenable: _univDataBox.listenable(),
      builder: (context, univDataBox, _) {
        // ID順にソート
        List<UnivData> sortedUnivData = univDataBox.values.toList();
        sortedUnivData.sort((a, b) => a.id.compareTo(b.id));

        // 補正フラグを保持するUnivDataインスタンスを取得 (sortedUnivData[9])
        final UnivData? correctionUnivData =
            sortedUnivData.length > _correctionFlagIndex
            ? sortedUnivData[_correctionFlagIndex]
            : null;

        // フラグの状態
        final bool isEnabled = _isCorrectionEnabled(correctionUnivData);
        final String statusText = isEnabled
            ? 'ON (尖ったタイムを抑制)'
            : 'OFF (抑制を行わない)';
        final Color statusColor = isEnabled
            ? Colors.greenAccent
            : Colors.redAccent;

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '長距離タイム抑制補正設定',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: HENSUU.backgroundcolor,
            foregroundColor: Colors.white,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. 説明文のセクション
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      "この設定は、長距離のタイム全体または尖ったタイムの抑制を調整します。\n\n長距離タイム抑制補正 (ON/OFF): 尖った（非現実的に速い）タイムを抑制します。\n\n長距離全体タイム抑制値: 長距離のタイム全体を抑制する強さを設定します。値が大きいほど抑制が強くなります。値が小さいほど抑制が弱くなります。マイナスの値を大きくしていくと、不自然に長距離の方がタイムが速くなる現象が現れる可能性があります。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 2. 尖ったタイム抑制スイッチのセクション ---
                  const Text(
                    '長距離タイム抑制補正 (尖ったタイム)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (correctionUnivData == null)
                    const Center(
                      child: Text(
                        'UnivDataが見つかりません。',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '状態: ',
                          style: TextStyle(
                            color: HENSUU.textcolor,
                            fontSize: HENSUU.fontsize_honbun,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: HENSUU.fontsize_honbun,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                        Switch(
                          value: isEnabled,
                          onChanged: (_) {
                            _toggleCorrectionFlag(correctionUnivData);
                          },
                          activeColor: Colors.greenAccent,
                          inactiveThumbColor: Colors.grey,
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.grey),

                  // --- 3. 長距離全体タイム抑制値スライダーのセクション ---
                  const Text(
                    '長距離全体タイム抑制値 (-18〜50)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '設定値: ',
                        style: TextStyle(
                          color: HENSUU.textcolor,
                          fontSize: HENSUU.fontsize_honbun,
                        ),
                      ),
                      Text(
                        _longDistanceTimeSuppressionValue.toString(),
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: HENSUU.fontsize_honbun,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _longDistanceTimeSuppressionValue.toDouble(),
                          min: -18, // 最小値を-18に変更
                          max: 50,
                          divisions: 68, // -18から50までの整数ステップ数 (50 - (-18) = 68)
                          label: _longDistanceTimeSuppressionValue.toString(),
                          activeColor: Colors.amber,
                          inactiveColor: Colors.grey,
                          onChanged: (double newValue) {
                            _saveSuppressionValue(newValue.round());
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),
                  // 戻るボタン
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
                    ),
                    child: Text(
                      "戻る",
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
