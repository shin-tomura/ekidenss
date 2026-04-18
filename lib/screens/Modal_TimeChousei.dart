import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // 💡 HENSUUなどの定数用
import 'package:ekiden/kantoku_data.dart'; // 💡 KantokuDataクラス用
import 'package:ekiden/ghensuu.dart'; // 💡 Ghensuuクラス用 (区間数取得用)
import 'package:ekiden/univ_data.dart';

class ModalTimeAdjustmentSettings extends StatefulWidget {
  const ModalTimeAdjustmentSettings({super.key});

  @override
  State<ModalTimeAdjustmentSettings> createState() =>
      _ModalTimeAdjustmentSettingsState();
}

class _ModalTimeAdjustmentSettingsState
    extends State<ModalTimeAdjustmentSettings> {
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  final ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');

  late KantokuData kantoku;
  Ghensuu? currentGhensuu;

  final univDataBox = Hive.box<UnivData>('univBox');

  // 💡 初期化完了フラグ
  bool _isInitialized = false;

  // 区間タイム調整データのインデックスを格納するリスト (racebangou順)
  // [30-39]:10月, [40-49]:11月, [50-59]:正月, [80-89]:カスタム
  // racebangou 0, 1, 2, 5 に対応
  final List<int> _raceBaseIndices = [30, 40, 50, 80];
  final List<String> _raceNames = ['10月駅伝', '11月駅伝', '正月駅伝', 'カスタム駅伝'];
  final List<int> _raceBangou = [0, 1, 2, 5]; // racebangou

  @override
  void initState() {
    super.initState();
    // Hiveデータの初期化は同期的に行う
    kantoku = kantokuBox.get('KantokuData') ?? KantokuData();
    currentGhensuu = ghensuuBox.getAt(0);
    List<UnivData> sortedUnivData = univDataBox.values.toList();
    sortedUnivData.sort((a, b) => a.id.compareTo(b.id));
    _raceNames[3] = sortedUnivData[0].name_tanshuku;

    // 非同期の初期化処理を呼び出す
    _initializeSettings();
  }

  /// 非同期の初期化処理 (initStateから分離)
  void _initializeSettings() async {
    // データがない場合のチェック
    if (currentGhensuu == null) {
      setState(() {
        _isInitialized = true; // エラーだが初期化完了扱いにして画面表示へ
      });
      return;
    }

    setState(() {
      _isInitialized = true; // 初期化完了
    });
  }

  /// タイム調整値 (`yobiint5`の特定インデックス) の値を変更し、Hiveに保存する関数
  ///
  /// @param index yobiint5のインデックス (例: 60 for 全体, 30-39 for 10月区間)
  /// @param newDoubleValue スライダーから渡される値 (-10.0 to +10.0)
  void _updateTimeAdjustmentValue(int index, double newDoubleValue) async {
    // スライダーの値はdoubleで来るため、最も近い整数に丸める
    final int newValue = newDoubleValue.round();

    // 調整範囲外への設定を防ぐ (-10から+10)
    if (newValue < -20 || newValue > 20) return;

    // setStateで値を更新し、Hiveにも保存
    setState(() {
      kantoku.yobiint5[index] = newValue;
    });

    await kantoku.save();
  }

  /// タイム調整設定項目のスライダーウィジェットを生成
  Widget _buildTimeAdjustmentSlider({
    required String title,
    required int index, // kantoku.yobiint5のインデックス
  }) {
    // 現在の値を取得 (-10から+10)
    final int currentValue = kantoku.yobiint5[index];
    // 実際のパーセント調整値 (0.5%刻み)
    final double percentValue = currentValue.toDouble() / 2.0;

    // 値に応じた説明テキスト
    String effectDescription =
        '現在の調整: ${percentValue >= 0 ? '+' : ''}${percentValue.toStringAsFixed(1)}%';

    // 値に応じた色 (例: マイナス=赤, プラス=緑, 0=青)
    Color sliderColor;
    if (currentValue < 0) {
      sliderColor =
          Color.lerp(
            Colors.green[900],
            Colors.green[400],
            currentValue.abs() / 20.0,
          ) ??
          Colors.red;
    } else if (currentValue > 0) {
      sliderColor =
          Color.lerp(
            Colors.red[400],
            Colors.red[900],
            currentValue.abs() / 20.0,
          ) ??
          Colors.green;
    } else {
      sliderColor = Colors.blue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. タイトル行
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            title,
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 2. 現在の調整率行 (改行後の表示)
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Text(
            effectDescription,
            // 💡 ここでは左寄せ (start) にして、画面幅いっぱいに使います
            textAlign: TextAlign.left,
            style: TextStyle(
              color: sliderColor,
              fontSize: HENSUU.fontsize_honbun - 2, // タイトルより少し小さく
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 3. スライダー
        Slider(
          value: currentValue.toDouble(), // スライダーはdoubleを使用 (-10.0 to 10.0)
          min: -20,
          max: 20,
          divisions: 40, // -10から10まで21段階
          label: percentValue >= 0
              ? '+${percentValue.toStringAsFixed(1)}%'
              : '${percentValue.toStringAsFixed(1)}%',
          onChanged: (newValue) => _updateTimeAdjustmentValue(index, newValue),
          activeColor: sliderColor,
          inactiveColor: sliderColor.withOpacity(0.3),
        ),
        const Divider(color: Colors.grey),
      ],
    );
  }

  /// 駅伝ごとの区間別スライダーリストを生成
  List<Widget> _buildRaceSectionSliders() {
    if (currentGhensuu == null) return []; // データがない場合は空リストを返す

    List<Widget> widgets = [];
    int raceIndex = 0;

    // 10月(0), 11月(1), 正月(2), カスタム(5) の順に処理
    for (int racebangou in _raceBangou) {
      final String raceName = _raceNames[raceIndex];
      final int baseIndex = _raceBaseIndices[raceIndex];

      // 区間数の取得 (racebangouに対応するkukansuu_taikaigotoのインデックス)
      int kukanCount = 0;
      try {
        kukanCount = currentGhensuu!.kukansuu_taikaigoto[racebangou];
      } catch (e) {
        // インデックスエラー等の場合のフォールバック (例えば10区間とする)
        kukanCount = 10;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            '⏱️ ${raceName} 区間別タイム調整 (全${kukanCount}区間)',
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun + 2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );

      for (int kukan = 0; kukan < kukanCount; kukan++) {
        final int index = baseIndex + kukan; // 例: 10月1区は30+0=30
        widgets.add(
          _buildTimeAdjustmentSlider(title: '第${kukan + 1}区 調整', index: index),
        );
      }
      widgets.add(const SizedBox(height: 24));
      raceIndex++;
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    // 💡 初期化が完了するまでローディング表示、またはデータがない場合のエラー表示
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text(
            '⏱️ タイム調整設定',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: HENSUU.backgroundcolor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (currentGhensuu == null) {
      return Scaffold(
        backgroundColor: HENSUU.backgroundcolor,
        appBar: AppBar(
          title: const Text(
            '⏱️ タイム調整設定',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: HENSUU.backgroundcolor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('データがありません', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // ValueListenableBuilderでHiveの変更を監視し、画面に反映
    return ValueListenableBuilder<Box<KantokuData>>(
      valueListenable: kantokuBox.listenable(),
      builder: (context, box, _) {
        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '⏱️ タイム調整設定',
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
                  // 💡 説明文
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      "全てのタイムや、各駅伝の区間ごとのタイムを調整できます。調整値は -10.0%から+10.0%(0.5%刻み)で、マイナスがタイム良化、プラスがタイム悪化となります。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  // 1. 全体タイム調整 (yobiint5[60])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '🌎 全体タイム調整',
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun + 2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _buildTimeAdjustmentSlider(title: '全体タイム調整', index: 60),

                  const SizedBox(height: 32),

                  // 2. 駅伝ごとの区間タイム調整
                  ..._buildRaceSectionSliders(),

                  const SizedBox(height: 32),
                  // 💡 補足文
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 24.0),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      "※駅伝の各区間のタイム調整は、全体タイム調整+各区間のタイム調整になります。例えば、全体タイム調整が+3.0%で区間の調整が-2.0%の場合には+1.0%のタイム調整となります。\n\n長距離タイム抑制の補正よりも前に、このタイム調整による補正がかかります。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
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
