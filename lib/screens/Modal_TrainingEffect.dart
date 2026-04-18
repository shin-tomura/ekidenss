import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';

class ModalTrainingEffectSettings extends StatefulWidget {
  const ModalTrainingEffectSettings({super.key});

  @override
  State<ModalTrainingEffectSettings> createState() =>
      _ModalTrainingEffectSettingsState();
}

class _ModalTrainingEffectSettingsState
    extends State<ModalTrainingEffectSettings> {
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  late KantokuData kantoku;

  // 年間強化練習の効果レベル: 0 (無効) から 5 (最大効果)
  late int _trainingEffectLevel;

  // 💡 初期化完了フラグ
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
    final int storedValue = kantoku.yobiint2[16];
    int initialLevel;

    // 値が0から5の範囲内かチェック
    if (storedValue >= 0 && storedValue <= 5) {
      initialLevel = storedValue;
    } else {
      // 異常値の場合はデフォルト値の4を設定し、保存
      initialLevel = 4;
      kantoku.yobiint2[16] = initialLevel;
      // 💡 初期値が異常値の場合のみ保存処理を非同期で行う
      await kantoku.save();
    }

    // 初期化完了後に setState で全ての late 変数とフラグを更新
    setState(() {
      _trainingEffectLevel = initialLevel;
      _isInitialized = true; // 初期化完了
    });
  }

  /// 年間強化練習の効果レベル (`yobiint2[16]`) の値を変更し、Hiveに保存する関数
  void _updateTrainingEffectLevel(double newDoubleLevel) async {
    // スライダーの値はdoubleで来るため、整数に変換
    final int newLevel = newDoubleLevel.round();

    // 0から5の範囲外への設定を防ぐ (スライダーの設定で制御されるはずだが念のため)
    if (newLevel < 0 || newLevel > 5) return;

    // setStateで値を更新し、Hiveにも保存
    setState(() {
      _trainingEffectLevel = newLevel;
      kantoku.yobiint2[16] = newLevel;
    });

    await kantoku.save();
  }

  /// スライダー設定項目のウィジェットを生成
  Widget _buildTrainingEffectSlider() {
    // 効果レベルに応じた説明テキスト
    String effectDescription = _trainingEffectLevel == 0
        ? '現在の設定: 無効化 (0) - 年間強化練習の効果が無効になります。'
        : _trainingEffectLevel == 5
        ? '現在の設定: 最大効果 (5) - 年間強化練習の効果が最大になります。'
        : '現在の設定: レベル ($_trainingEffectLevel) - 標準的な効果です。';

    // 効果レベルに応じた色 (例: 0=赤, 5=緑)
    Color sliderColor =
        Color.lerp(Colors.red, Colors.green, _trainingEffectLevel / 5.0) ??
        Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            '効果レベルの調整',
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Slider(
          value: _trainingEffectLevel.toDouble(), // スライダーはdoubleを使用
          min: 0,
          max: 5,
          divisions: 5, // 0, 1, 2, 3, 4, 5 の6段階
          label: _trainingEffectLevel.toString(),
          onChanged: _updateTrainingEffectLevel,
          activeColor: sliderColor,
          inactiveColor: sliderColor.withOpacity(0.3),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 4.0,
            bottom: 8.0,
          ),
          child: Text(
            effectDescription,
            style: TextStyle(
              color: sliderColor,
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
    // 💡 初期化が完了するまでローディング表示
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text(
            '🏋️ 年間強化練習効果設定',
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
            title: const Text(
              '🏋️ 年間強化練習効果設定',
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
                  // 説明文のWidget
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Text(
                      "年間強化練習による能力アップ効果の大きさを設定します。\n\n0: 効果が無効化されます。\n1〜5: 数値が大きいほど、効果が大きくなります。5が最大効果です。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  // 年間強化練習効果設定スライダー
                  _buildTrainingEffectSlider(), // 👈 スライダーウィジェットを呼び出し

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
