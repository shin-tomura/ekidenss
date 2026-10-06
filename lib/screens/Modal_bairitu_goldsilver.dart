import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/ghensuu.dart';
import 'package:ekiden/kansuu/kingin_wariai.dart'; // 難易度ごとの金銀支給量の割合(1.9.1)

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

  /// 難易度ごとの割合のスライダーを動かしている間の表示(難易度 → %)。離したら保存して消す(1.9.1)
  final Map<int, double> _ugokashiChuu = {};

  /// スライダーの色(鬼・難しい・普通・易しい)
  static const List<Color> _wariaiIro = [
    Colors.redAccent,
    Colors.orange,
    Colors.green,
    Colors.lightBlueAccent,
  ];

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

  /// 難易度ごとの割合(yobiint3[70]〜[73])を書き換えてHiveに保存する(1.9.1)
  /// [atai]は 難易度(0〜3) → 保存する値(kinginWariaiAtai で作った値)
  /// (変更をHiveに保存するために、List全体を更新)
  Future<void> _hozonWariai(Map<int, int> atai) async {
    final List<int> updatedYobiint3 = List.from(kantoku.yobiint3);
    for (final MapEntry<int, int> e in atai.entries) {
      final int index = kinginWariaiIndex + e.key;
      if (updatedYobiint3.length <= index) return;
      updatedYobiint3[index] = e.value;
    }
    setState(() {
      kantoku.yobiint3 = updatedYobiint3;
    });
    await kantoku.save();
  }

  /// 4つの難易度の割合を初期値(100%)に戻す
  Future<void> _wariaiShokitiNiModosu() async {
    _ugokashiChuu.clear();
    await _hozonWariai({for (int k = 0; k < 4; k++) k: 0});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('難易度ごとの割合を初期値(100%)に戻しました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 難易度1つ分の割合のスライダーと、割合を掛けたあとの支給量(1.9.1)
  /// スマホの文字を大きくしていても読めるように、1つの難易度を縦に並べる
  Widget _wariaiSlider({required int kazeflag, required int imaNanido}) {
    final double atai =
        _ugokashiChuu[kazeflag] ??
        kinginWariaiPercent(kantoku, kazeflag).toDouble();
    final int percent = atai.round();
    final int bai = _moneyMultiplier;
    // 割合を掛けたあとの量(四捨五入で1の位まで。kinginWariaiKakeru と同じ)
    int kakeru(int ryou) =>
        percent == 100 ? ryou : (ryou * percent + 50) ~/ 100;
    final List<int> hyou = kinginTeikiHyou[kazeflag];
    final int teikiSaitei = kakeru(hyou.last) * bai;
    final int teikiSaikou = kakeru(hyou.first) * bai;
    final int mokuhyouSaitei = kakeru(kinginMokuhyouSaiteiRyou) * bai;
    final int mokuhyouSaikou =
        kakeru(kinginMokuhyouIchiiRyou[kazeflag]) * bai;
    final String mei = kinginWariaiNanidoMei[kazeflag];
    final Color iro = _wariaiIro[kazeflag];
    final TextStyle setsumeiStyle = TextStyle(
      color: HENSUU.textcolor.withOpacity(0.8),
      fontSize: HENSUU.fontsize_honbun - 2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            kazeflag == imaNanido ? '「$mei」の割合(今の難易度)' : '「$mei」の割合',
            style: TextStyle(
              color: HENSUU.textcolor,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            percent == 100 ? '現在の設定値: 100% (初期値)' : '現在の設定値: $percent%',
            style: TextStyle(
              color: percent == 100 ? Colors.greenAccent : Colors.yellow,
              fontSize: HENSUU.fontsize_honbun,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            value: atai.clamp(
              kinginWariaiSaishou.toDouble(),
              kinginWariaiSaidai.toDouble(),
            ),
            min: kinginWariaiSaishou.toDouble(),
            max: kinginWariaiSaidai.toDouble(),
            divisions: (kinginWariaiSaidai - kinginWariaiSaishou) ~/ 10,
            label: '$percent%',
            onChanged: (v) {
              setState(() => _ugokashiChuu[kazeflag] = v);
            },
            onChangeEnd: (v) async {
              await _hozonWariai({kazeflag: kinginWariaiAtai(v.round())});
              if (!mounted) return;
              setState(() => _ugokashiChuu.remove(kazeflag));
            },
            activeColor: iro,
            inactiveColor: Colors.grey.withOpacity(0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('春の定期支給: $teikiSaitei〜$teikiSaikou', style: setsumeiStyle),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Text(
            '目標順位を達成したとき: $mokuhyouSaitei〜$mokuhyouSaikou'
            '(駅伝で目標1位を達成したときは${mokuhyouSaikou * 2})',
            style: setsumeiStyle,
          ),
        ),
        const Divider(color: Colors.grey),
        const SizedBox(height: 16),
      ],
    );
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
        // 今の難易度(難易度ごとの割合の見出しに「今の難易度」と付ける。1.9.1)
        final Box<Ghensuu> ghensuuBox = Hive.box<Ghensuu>('ghensuuBox');
        final int imaNanido = ghensuuBox.isNotEmpty
            ? (ghensuuBox.getAt(0)?.kazeflag ?? -1)
            : -1;
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

                  // 難易度ごとの割合(1.9.1。kingin_wariai.dart)
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
                      "【難易度ごとの割合】\n\n"
                      "大学画面の「難易度変更」の難易度ごとに、春の定期支給と、目標順位を達成したときの金銀の量を、10%〜500%の割合で変えられます。100%が初期値(今まで通り)です。\n\n"
                      "コンピュータの大学(「コンピュータ金銀使用」がONのとき)にも、支給レベルの難易度の割合が適用されます(「プレイヤーと同じ」は、プレイヤーの今の難易度の割合)。\n\n"
                      "下に出す量は、上の金銀支給量の倍率も掛けたあとの量です。難易度モードの「極」では目標順位を達成したときの金銀が、「天」ではすべての金銀が支給されません。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  for (int k = 0; k < 4; k++)
                    _wariaiSlider(kazeflag: k, imaNanido: imaNanido),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _wariaiShokitiNiModosu,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(200, 48),
                      padding: const EdgeInsets.all(12.0),
                    ),
                    child: Text(
                      '割合を初期値に戻す',
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
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
