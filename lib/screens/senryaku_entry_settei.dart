import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/constants.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/kansuu/ToujituHenkou_com.dart' show senryakuKakurituIndex;

// ------------------------------------------------------------
// 説明画面の設定タブの「戦略的エントリー確率設定」(1.9.4)
// コンピュータの大学が戦略的エントリー(主力を補欠に温存し、当日変更で起用する作戦)を
// とる確率を選ぶ。1.9.3までは「調子関連設定」の画面の一番下にあった
// (保存先は KantokuData.yobiint2[34]。0〜100で、0が初期値(しない)。
//  戦略的エントリーと当日の起用は lib/kansuu/ToujituHenkou_com.dart)
// ------------------------------------------------------------

class ModalSenryakuEntrySettei extends StatefulWidget {
  const ModalSenryakuEntrySettei({super.key});

  @override
  State<ModalSenryakuEntrySettei> createState() =>
      _ModalSenryakuEntrySetteiState();
}

class _ModalSenryakuEntrySetteiState extends State<ModalSenryakuEntrySettei> {
  final Box<KantokuData> _kantokuBox = Hive.box<KantokuData>('kantokuBox');
  KantokuData? _kantoku;
  double _kakuritu = 0; // スライダーの値(0〜100)

  @override
  void initState() {
    super.initState();
    _kantoku = _kantokuBox.get('KantokuData');
    final KantokuData? k = _kantoku;
    _kakuritu =
        (k != null && k.yobiint2.length > senryakuKakurituIndex
                ? k.yobiint2[senryakuKakurituIndex]
                : 0)
            .toDouble()
            .clamp(0, 100);
  }

  // 戦略的エントリー確率を保存する
  Future<void> _hozon(double sliderValue) async {
    final KantokuData? k = _kantoku;
    if (k == null || k.yobiint2.length <= senryakuKakurituIndex) return;
    final int atai = sliderValue.round().clamp(0, 100);
    setState(() {
      _kakuritu = atai.toDouble();
    });
    k.yobiint2[senryakuKakurituIndex] = atai;
    await k.save();
  }

  @override
  Widget build(BuildContext context) {
    final int ima = _kakuritu.round();
    return Scaffold(
      backgroundColor: HENSUU.backgroundcolor,
      appBar: AppBar(
        title: const Text(
          '戦略的エントリー確率設定',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: HENSUU.backgroundcolor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                ),
                child: const Text(
                  'コンピュータの大学が、どの区間でも走れる主力選手をいったん補欠に登録しておき、'
                  '大会当日の当日変更で起用する作戦(戦略的エントリー)をとる確率です。\n\n'
                  '・大学ごと・大会ごとにくじを引きます。\n'
                  '・温存する人数は、10月駅伝1人、11月駅伝2人、正月駅伝3人です。'
                  'カスタム駅伝は区間数に応じて1〜3人です。\n'
                  '・大会当日は、試走タイムにその日の調子を入れた見込みで、'
                  'タイムが一番縮まる区間にエースを起用します(元の区間とは限りません)。\n'
                  '・体調不良の選手の交代を先に行うので、交代できる人数を使い切ると、'
                  'エースを起用しないこともあります。\n'
                  '・最適解区間配置確率設定とは別のくじで、最適解区間配置で組んだ大学にもかかります。\n'
                  '・プレイヤーの大学には関係ありません。\n'
                  '・0%(初期値)のときは、戦略的エントリーを行いません。',
                  style: TextStyle(
                    color: HENSUU.textcolor,
                    fontSize: HENSUU.fontsize_honbun,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '現在の確率: $ima%',
                style: TextStyle(
                  color: ima == 0
                      ? Colors.greenAccent
                      : (ima < 100 ? Colors.yellow : Colors.redAccent),
                  fontSize: HENSUU.fontsize_honbun,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: _kakuritu,
                min: 0,
                max: 100,
                divisions: 10, // 10%刻み
                label: '$ima%',
                onChanged: (double atai) {
                  setState(() => _kakuritu = atai);
                },
                onChangeEnd: _hozon,
                activeColor: Colors.teal,
                inactiveColor: Colors.grey.withOpacity(0.5),
              ),
              // 左端・右端の説明(文字を大きくしていても横にはみ出さないよう、
              // 左右に半分ずつの幅を割り当てて、入りきらなければ折り返す)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '0% (しない)',
                      style: TextStyle(
                        color: HENSUU.textcolor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '100% (毎回)',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: HENSUU.textcolor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
                child: const Text(
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
