import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart'; // HENSUUクラスがあるはずのインポート
import 'package:ekiden/kantoku_data.dart'; // KantokuDataクラスがあるはずのインポート (必要に応じて追加)

class ModalConditionSettings extends StatefulWidget {
  const ModalConditionSettings({super.key});

  @override
  State<ModalConditionSettings> createState() => _ModalConditionSettingsState();
}

class _ModalConditionSettingsState extends State<ModalConditionSettings> {
  // Hive.box() を使って、既に開いているBoxを取得
  final kantokuBox = Hive.box<KantokuData>('kantokuBox');
  // Boxからデータを読み込む (画面表示中は常に存在するものと仮定)
  late KantokuData kantoku;

  // 各設定値に対応するローカル状態
  late double _influenceValue; // yobiint2[2] (0-100)
  late double _peakingSuccessProb; // yobiint2[3] (50-100)
  late double _revivalProb; // yobiint2[4] (0-99)
  late double _suddenIllnessProb; // yobiint2[5] (0-20)

  // ▼ 追加する設定項目用のローカル状態
  late double _sectionIllnessProb; // yobiint2[6] (0-20)
  late double _guaranteedStability4th; // yobiint2[7] (1-90)
  late double _guaranteedStability3rd; // yobiint2[8] (1-90)
  late double _guaranteedStability2nd; // yobiint2[9] (1-90)
  // ▲ 追加する設定項目用のローカル状態

  // ▼ 新規追加する設定項目用のローカル状態 (yobiint2[10]以降)
  late bool _computerCondition100Switch; // yobiint2[10] (1=ON/0=OFF)
  late double _illnessTimePenalty; // yobiint2[11] (1-10) <- **新規追加**
  // ▲ 新規追加する設定項目用のローカル状態
  late bool _computerIllnessEnabled; // yobiint2[21] (1=ON/0=OFF)

  @override
  void initState() {
    super.initState();
    // 'KantokuData'というキーで単一のデータが保存されていると想定
    kantoku = kantokuBox.get('KantokuData') ?? KantokuData();

    // 画面表示用のローカル状態を初期化
    _influenceValue = kantoku.yobiint2[2].toDouble().clamp(0, 100);
    _peakingSuccessProb = kantoku.yobiint2[3].toDouble().clamp(0, 100);
    _revivalProb = kantoku.yobiint2[4].toDouble().clamp(0, 99);
    _suddenIllnessProb = kantoku.yobiint2[5].toDouble().clamp(0, 20);

    // ▼ 追加項目のローカル状態を初期化
    _sectionIllnessProb = kantoku.yobiint2[6].toDouble().clamp(0, 20);
    _guaranteedStability4th = kantoku.yobiint2[7].toDouble().clamp(1, 90);
    _guaranteedStability3rd = kantoku.yobiint2[8].toDouble().clamp(1, 90);
    _guaranteedStability2nd = kantoku.yobiint2[9].toDouble().clamp(1, 90);
    // ▲ 追加項目のローカル状態を初期化

    // ▼ 新規追加項目のローカル状態を初期化
    // yobiint2[10]が1の時ON（true）、0の時OFF（false）
    _computerCondition100Switch = kantoku.yobiint2[10] == 1;
    // yobiint2[11] 体調不良タイム悪化パーセント設定 (1-10)
    // 初期値が0などの異常値の場合はデフォルト値（例：5）を設定
    _illnessTimePenalty = kantoku.yobiint2[11].toDouble().clamp(1, 10);
    // ▲ 新規追加項目のローカル状態を初期化
    // yobiint2[21]が1の時ON（発生する）、0の時OFF（発生しない）
    _computerIllnessEnabled = kantoku.yobiint2[21] == 1;
  }

  /// コンピュータチームの体調不良発生設定 (`yobiint2[21]`) の値を変更し、Hiveに保存
  void _updateComputerIllnessEnabled(bool newValue) async {
    setState(() {
      _computerIllnessEnabled = newValue;
      kantoku.yobiint2[21] = newValue ? 1 : 0;
    });
    await kantoku.save();
  }

  /// タイム影響度 (`yobiint2[2]`) の値を変更し、Hiveに保存する関数
  void _updateInfluenceValue(double sliderValue) async {
    final int newValue = sliderValue.toInt().clamp(0, 100);
    setState(() {
      _influenceValue = newValue.toDouble();
      kantoku.yobiint2[2] = newValue;
      // 影響度が0になったら、他の設定値をデフォルトに戻す（任意）
      if (newValue == 0) {
        /*_peakingSuccessProb = 50.0;
        _revivalProb = 0.0;
        _suddenIllnessProb = 0.0;
        kantoku.yobiint2[3] = 80;
        kantoku.yobiint2[4] = 50;
        kantoku.yobiint2[5] = 1;*/
      } else {
        // yobiint2[3]-[5]のローカル状態もHiveに反映（操作がなくても保存を担保）
        //kantoku.yobiint2[3] = _peakingSuccessProb.toInt();
        //kantoku.yobiint2[4] = _revivalProb.toInt();
        //kantoku.yobiint2[5] = _suddenIllnessProb.toInt();
      }
    });
    await kantoku.save();
  }

  /// ピーキング成功確率 (`yobiint2[3]`) の値を変更し、Hiveに保存する関数
  void _updatePeakingSuccessProb(double sliderValue) async {
    final int newValue = sliderValue.toInt().clamp(0, 100);
    setState(() {
      _peakingSuccessProb = newValue.toDouble();
      kantoku.yobiint2[3] = newValue;
    });
    await kantoku.save();
  }

  /// 復活確率 (`yobiint2[4]`) の値を変更し、Hiveに保存する関数
  void _updateRevivalProb(double sliderValue) async {
    final int newValue = sliderValue.toInt().clamp(0, 99);
    setState(() {
      _revivalProb = newValue.toDouble();
      kantoku.yobiint2[4] = newValue;
    });
    await kantoku.save();
  }

  /// 当日突発的体調不良確率 (`yobiint2[5]`) の値を変更し、Hiveに保存する関数
  void _updateSuddenIllnessProb(double sliderValue) async {
    final int newValue = sliderValue.toInt().clamp(0, 20);
    setState(() {
      _suddenIllnessProb = newValue.toDouble();
      kantoku.yobiint2[5] = newValue;
    });
    await kantoku.save();
  }

  // ▼ 追加する設定項目用の更新関数

  /// 区間エントリー時体調不良確率 (`yobiint2[6]`) の値を変更し、Hiveに保存する関数
  void _updateSectionIllnessProb(double sliderValue) async {
    final int newValue = sliderValue.toInt().clamp(0, 20);
    setState(() {
      _sectionIllnessProb = newValue.toDouble();
      kantoku.yobiint2[6] = newValue;
    });
    await kantoku.save();
  }

  /// 4年生の安定感最低保証値 (`yobiint2[7]`) の値を変更し、Hiveに保存する関数
  void _updateGuaranteedStability4th(double sliderValue) async {
    final int newValue = sliderValue.toInt().clamp(1, 90);
    setState(() {
      _guaranteedStability4th = newValue.toDouble();
      kantoku.yobiint2[7] = newValue;
    });
    await kantoku.save();
  }

  /// 3年生の安定感最低保証値 (`yobiint2[8]`) の値を変更し、Hiveに保存する関数
  void _updateGuaranteedStability3rd(double sliderValue) async {
    final int newValue = sliderValue.toInt().clamp(1, 90);
    setState(() {
      _guaranteedStability3rd = newValue.toDouble();
      kantoku.yobiint2[8] = newValue;
    });
    await kantoku.save();
  }

  /// 2年生の安定感最低保証値 (`yobiint2[9]`) の値を変更し、Hiveに保存する関数
  void _updateGuaranteedStability2nd(double sliderValue) async {
    final int newValue = sliderValue.toInt().clamp(1, 90);
    setState(() {
      _guaranteedStability2nd = newValue.toDouble();
      kantoku.yobiint2[9] = newValue;
    });
    await kantoku.save();
  }

  // ▲ 追加する設定項目用の更新関数

  // ▼ 新規追加する設定項目用の更新関数

  /// コンピュータチームの調子常時100スイッチ (`yobiint2[10]`) の値を変更し、Hiveに保存する関数
  void _updateComputerConditionSwitch(bool newValue) async {
    setState(() {
      _computerCondition100Switch = newValue;
      // true=1 (ON), false=0 (OFF)
      kantoku.yobiint2[10] = newValue ? 1 : 0;
    });
    await kantoku.save();
  }

  /// **新規追加**: 体調不良タイム悪化パーセント設定 (`yobiint2[11]`) の値を変更し、Hiveに保存する関数
  void _updateIllnessTimePenalty(double sliderValue) async {
    // 1から10の範囲で整数値として保存
    final int newValue = sliderValue.toInt().clamp(1, 10);
    setState(() {
      _illnessTimePenalty = newValue.toDouble();
      kantoku.yobiint2[11] = newValue;
    });
    await kantoku.save();
  }
  // ▲ 新規追加する設定項目用の更新関数

  // 確率表示用のテキストを生成
  String _getProbabilityText(double value) {
    // 安定感設定 (yobiint2[7]-[9]) の場合は「%」を付けずに表示
    if ([
      _guaranteedStability4th,
      _guaranteedStability3rd,
      _guaranteedStability2nd,
    ].contains(value)) {
      return '現在の設定値: ${value.toInt()}';
    }
    // 体調不良タイム悪化パーセント設定 (yobiint2[11]) の場合
    if (value == _illnessTimePenalty) {
      return '現在の設定値: ${value.toInt()} (悪化度)';
    }

    return '現在の設定値: ${value.toInt()}%';
  }

  // 設定項目のウィジェットを生成
  Widget _buildSettingSlider({
    required String title,
    required String description,
    required double currentValue,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
    required String minLabel,
    required String maxLabel,
    Color activeColor = Colors.purple,
    bool isStabilitySetting = false, // 安定感設定かどうかのフラグ
    bool isIllnessPenaltySetting = false, // 体調不良悪化設定かどうかのフラグ
  }) {
    // スライダーのラベル表示を調整
    final String labelText = isStabilitySetting
        ? '${currentValue.toInt()}'
        : isIllnessPenaltySetting
        ? '${currentValue.toInt()} (悪化度)'
        : '${currentValue.toInt()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Text(
            description,
            style: TextStyle(
              color: HENSUU.textcolor.withOpacity(0.8),
              fontSize: HENSUU.fontsize_honbun - 2,
            ),
          ),
        ),

        // 現在の値表示
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            _getProbabilityText(currentValue),
            style: TextStyle(
              color: currentValue == min
                  ? Colors.greenAccent
                  : (currentValue < max ? Colors.yellow : Colors.redAccent),
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
                value: currentValue,
                min: min,
                max: max,
                divisions: divisions,
                label: labelText,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
                activeColor: activeColor,
                inactiveColor: Colors.grey.withOpacity(0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // minLabelをExpandedで囲み、利用可能なスペースを確保
                  Expanded(
                    // FittedBoxで、テキストがはみ出す場合に自動的に縮小されるようにする
                    child: FittedBox(
                      fit: BoxFit.scaleDown, // テキストが収まらない場合に縮小
                      alignment: Alignment.centerLeft, // 左寄せを維持
                      child: Text(
                        minLabel,
                        style: TextStyle(
                          color: HENSUU.textcolor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  // maxLabelもExpandedで囲み、スペースを確保
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown, // テキストが収まらない場合に縮小
                      alignment: Alignment.centerRight, // 右寄せを維持
                      child: Text(
                        // maxLabelの代わりに currentMaxLabel を使用している場合は、それに応じて修正してください
                        // (前の質問のコードでは maxLabel を使用)
                        maxLabel,
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

  // スイッチ設定項目のウィジェットを生成 (新規追加)
  Widget _buildSettingSwitch({
    required String title,
    required String description,
    required bool currentValue,
    required ValueChanged<bool> onChanged,
    Color activeColor = Colors.redAccent,
  }) {
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
          // スイッチ自体の背景色を調整したい場合は以下を使用 (今回はactiveColorのみ)
          // tileColor: Colors.blueGrey.withOpacity(0.05),
        ),
        // 現在の状態表示（任意）
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Text(
            currentValue ? '現在の設定: ON (難易度上昇)' : '現在の設定: OFF (通常補正)',
            style: TextStyle(
              color: currentValue ? Colors.redAccent : Colors.greenAccent,
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

  // スイッチ設定項目のウィジェットを生成 (新規追加)
  Widget _buildSettingSwitch_ComteamTaichoufuryou({
    required String title,
    required String description,
    required bool currentValue,
    required ValueChanged<bool> onChanged,
    Color activeColor = Colors.orange,
  }) {
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
          // スイッチ自体の背景色を調整したい場合は以下を使用 (今回はactiveColorのみ)
          // tileColor: Colors.blueGrey.withOpacity(0.05),
        ),
        // 現在の状態表示（任意）
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Text(
            currentValue ? '現在の設定: ON' : '現在の設定: OFF (初期値)',
            style: TextStyle(
              color: currentValue ? Colors.orange : Colors.greenAccent,
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
    // ValueListenableBuilderでHiveの変更を監視
    return ValueListenableBuilder<Box<KantokuData>>(
      valueListenable: kantokuBox.listenable(),
      builder: (context, box, _) {
        // データが存在することを前提とし、最新のデータを取得し直す（_influenceValueが更新されているので不要だが念のため）
        // kantoku = box.get('KantokuData') ?? KantokuData();

        // 調子補正の適用有無を判定
        final bool isInfluenceActive = _influenceValue.toInt() > 0;

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '🏃‍♂️調子変動システム設定',
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
                  // 全体設定の説明
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Colors.blueGrey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "この画面では、選手個々の調子の良し悪しが駅伝(駅伝予選は除く)でのタイムに与える影響や、調子を変動させる各種確率を設定します。調子や体調不良の影響を無効化する場合は、最初のスライダーを0%に設定してください。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),

                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),

                  // 1. 調子の良し悪しによるタイムへの影響度 (yobiint2[2]: 0-100)
                  _buildSettingSlider(
                    title: '調子のタイムへの影響度',
                    description:
                        '調子の良し悪しが駅伝(駅伝予選は除く)での走破タイムへ与える影響の大きさです。0%に設定すると、調子がタイムへ影響することはなくなり、安定感のパラメータも意味をなさなくなります。影響度の目安としては、最大値100に設定した場合で調子が1だと約10％ものタイム損、最大値100で調子が50だと約5％のタイム損、設定値50で調子が1だと約5％のタイム損、設定値50で調子が50だと約2.5％のタイム損になります。',
                    currentValue: _influenceValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (newValue) {
                      setState(() => _influenceValue = newValue);
                    },
                    onChangeEnd: _updateInfluenceValue,
                    minLabel: '0% (影響なし/無効化)',
                    maxLabel: '100% (最大影響)',
                    activeColor: Colors.redAccent,
                  ),

                  // 影響度が0%でない場合のみ表示する設定群
                  if (isInfluenceActive) ...[
                    // ▼ 新規追加項目: コンピュータチームの調子常時100スイッチ (yobiint2[10])
                    _buildSettingSwitch(
                      title: 'コンピュータチームの調子常時100スイッチ',
                      description:
                          'ONにすると、コンピュータのチームの選手は、以下の設定項目に関わらず常に**調子100**で出走します。その分ゲームの難易度が上昇します。OFFの場合、プレイヤーチームの選手と同じように、以下の設定項目に応じた調子変動がかかります。(常時100にしている場合には「コンピュータチームの体調不良発生スイッチ」の設定に関係なくコンピュータのチームには体調不良者は発生しません。)',
                      currentValue: _computerCondition100Switch,
                      onChanged: _updateComputerConditionSwitch,
                      activeColor: Colors.red, // 難易度上昇を示す赤系
                    ),

                    // ▲ 新規追加項目
                    _buildSettingSwitch_ComteamTaichoufuryou(
                      title: 'コンピュータチームの体調不良発生スイッチ',
                      description:
                          'ONにすると、プレイヤーチームと同様にコンピュータのチームの選手にも一定確率で体調不良が発生するようになります。ただ、コンピュータのチームは自動では当日変更してこないので、もし、このスイッチをONにする場合には、箱庭モードで、あなたが他大学の当日変更まで面倒をみる必要が出てくるかもしれません。',
                      currentValue: _computerIllnessEnabled,
                      onChanged: _updateComputerIllnessEnabled,
                      activeColor: Colors.orange,
                    ),

                    // ▼ **新規追加項目**: 体調不良タイム悪化パーセント設定 (yobiint2[11]: 1-10)
                    _buildSettingSlider(
                      title: '体調不良タイム悪化度設定',
                      description:
                          '体調不良の場合のタイム悪化割合を設定します。数値が大きいほどタイム悪化幅が大きくなります。悪化度1で約1％のタイム損、悪化度10で約10％のタイム損となります。',
                      currentValue: _illnessTimePenalty,
                      min: 1,
                      max: 10,
                      divisions: 9, // 1から10まで1刻み
                      onChanged: (newValue) {
                        setState(() => _illnessTimePenalty = newValue);
                      },
                      onChangeEnd: _updateIllnessTimePenalty,
                      minLabel: '1 (最小悪化)',
                      maxLabel: '10 (最大悪化)',
                      activeColor: Colors.red,
                      isIllnessPenaltySetting: true,
                    ),
                    // ▲ **新規追加項目**

                    // 2. 区間エントリー時ピーキング成功確率 (yobiint2[3]: 50-100)
                    _buildSettingSlider(
                      title: '区間エントリー時 ピーキング成功確率',
                      description:
                          '区間エントリーを決定する時点で、選手が最高の状態（調子100）に調整を成功させている確率です。ピーキングに失敗した場合、各選手の安定感を下限値とした乱数で調子が決定されます。',
                      currentValue: _peakingSuccessProb,
                      min: 0, // 50から
                      max: 100, // 100まで
                      divisions: 100, // 1%刻み
                      onChanged: (newValue) {
                        setState(() => _peakingSuccessProb = newValue);
                      },
                      onChangeEnd: _updatePeakingSuccessProb,
                      minLabel: '0% (全失敗)',
                      maxLabel: '100% (全成功)',
                      activeColor: Colors.blueAccent,
                    ),

                    // 5. 区間エントリー時体調不良確率設定 (yobiint2[6]: 0-20)
                    _buildSettingSlider(
                      title: '区間エントリー時 体調不良確率',
                      description:
                          '区間エントリー時に、選手が体調不良（調子に悪影響）になってしまう確率です。体調不良の場合、調子は各選手の安定感とは関係なく、一律でのタイム悪化となります。なお、この設定はプレイヤーのチームの選手のみに関係し、コンピュータのチームには体調不良者は出ません。',
                      currentValue: _sectionIllnessProb,
                      min: 0,
                      max: 20, // 20まで
                      divisions: 20, // 1%刻み
                      onChanged: (newValue) {
                        setState(() => _sectionIllnessProb = newValue);
                      },
                      onChangeEnd: _updateSectionIllnessProb,
                      minLabel: '0% (体調不良なし)',
                      maxLabel: '20% (高確率)',
                      activeColor: Colors.deepOrangeAccent,
                    ),

                    // 3. ピーキング失敗からの当日復活確率 (yobiint2[4]: 0-99)
                    _buildSettingSlider(
                      title: '当日復活確率',
                      description:
                          '体調不良やピーキングに失敗（調子100にならなかった）した選手が、大会当日に奇跡的に調子100に復活する確率です。',
                      currentValue: _revivalProb,
                      min: 0,
                      max: 99, // 99まで
                      divisions: 99, // 1%刻み
                      onChanged: (newValue) {
                        setState(() => _revivalProb = newValue);
                      },
                      onChangeEnd: _updateRevivalProb,
                      minLabel: '0% (復活なし)',
                      maxLabel: '99% (ほぼ復活)',
                      activeColor: Colors.green,
                    ),

                    // 4. 当日突発的体調不良確率 (yobiint2[5]: 0-20)
                    _buildSettingSlider(
                      title: '当日突発的体調不良確率',
                      description:
                          '大会当日に急な体調不良を起こし、調子が落ちてしまう確率です（ピーキング成功者も対象）。体調不良の場合、調子は各選手の安定感とは関係なく、一律でのタイム悪化となります。なお、この設定はプレイヤーのチームの選手のみに関係し、コンピュータのチームには体調不良者は出ません。',
                      currentValue: _suddenIllnessProb,
                      min: 0,
                      max: 20, // 20まで
                      divisions: 20, // 1%刻み
                      onChanged: (newValue) {
                        setState(() => _suddenIllnessProb = newValue);
                      },
                      onChangeEnd: _updateSuddenIllnessProb,
                      minLabel: '0% (体調不良なし)',
                      maxLabel: '20% (高確率)',
                      activeColor: Colors.orange,
                    ),

                    // ▼ 安定感 最低保証値設定
                    // 4年生の安定感最低保証値設定 (yobiint2[7]: 1-90)
                    _buildSettingSlider(
                      title: '4年生の安定感 最低保証値設定',
                      description:
                          '4年生の「安定感」パラメータの最低値を設定します（調子の最低保証値）。上級生ほど安定したパフォーマンスを発揮させるための設定です。',
                      currentValue: _guaranteedStability4th,
                      min: 1,
                      max: 90, // 90まで
                      divisions: 89, // 1刻み
                      onChanged: (newValue) {
                        setState(() => _guaranteedStability4th = newValue);
                      },
                      onChangeEnd: _updateGuaranteedStability4th,
                      minLabel: '1 (最低)',
                      maxLabel: '90 (最高保証)',
                      activeColor: Colors.purple,
                      isStabilitySetting: true,
                    ),

                    // 3年生の安定感最低保証値設定 (yobiint2[8]: 1-90)
                    _buildSettingSlider(
                      title: '3年生の安定感 最低保証値設定',
                      description: '3年生の「安定感」パラメータの最低値を設定します（調子の最低保証値）。',
                      currentValue: _guaranteedStability3rd,
                      min: 1,
                      max: 90, // 90まで
                      divisions: 89, // 1刻み
                      onChanged: (newValue) {
                        setState(() => _guaranteedStability3rd = newValue);
                      },
                      onChangeEnd: _updateGuaranteedStability3rd,
                      minLabel: '1 (最低)',
                      maxLabel: '90 (最高保証)',
                      activeColor: Colors.purple.shade300,
                      isStabilitySetting: true,
                    ),

                    // 2年生の安定感最低保証値設定 (yobiint2[9]: 1-90)
                    _buildSettingSlider(
                      title: '2年生の安定感 最低保証値設定',
                      description: '2年生の「安定感」パラメータの最低値を設定します（調子の最低保証値）。',
                      currentValue: _guaranteedStability2nd,
                      min: 1,
                      max: 90, // 90まで
                      divisions: 89, // 1刻み
                      onChanged: (newValue) {
                        setState(() => _guaranteedStability2nd = newValue);
                      },
                      onChangeEnd: _updateGuaranteedStability2nd,
                      minLabel: '1 (最低)',
                      maxLabel: '90 (最高保証)',
                      activeColor: Colors.purple.shade100,
                      isStabilitySetting: true,
                    ),
                    // ▲ 安定感 最低保証値設定
                  ],

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
      },
    );
  }
}
