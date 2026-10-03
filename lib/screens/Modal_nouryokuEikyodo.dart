import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ekiden/kantoku_data.dart';
import 'package:ekiden/constants.dart'; // HENSUU
import 'package:ekiden/kansuu/nouryoku_eikyodo.dart';

/// 能力のタイムへの影響度設定の画面(1.8.2)
/// 長距離粘り・スパート力・登り適性・下り適性・アップダウン対応力・ロード適性・ペース変動対応力の
/// 差がタイムに効く大きさ(全大学共通)。KantokuData.yobiint2[68]〜[74]
/// (0なら100%(初期値)、1〜31なら(値−1)×10%)。計算は nouryoku_eikyodo.dart
class ModalNouryokuEikyodo extends StatefulWidget {
  const ModalNouryokuEikyodo({super.key});

  @override
  State<ModalNouryokuEikyodo> createState() => _ModalNouryokuEikyodoState();
}

/// 設定する能力1つ分の表示内容
class _Koumoku {
  final int index;
  final String mei;
  final String setsumei;
  final Color iro;
  const _Koumoku(this.index, this.mei, this.setsumei, this.iro);
}

class _ModalNouryokuEikyodoState extends State<ModalNouryokuEikyodo> {
  late Box<KantokuData> _kantokuBox;

  /// スライダーを動かしている間の表示(番号 → %)。離したら保存して消す
  final Map<int, double> _ugokashiChuu = {};

  static const List<_Koumoku> _koumoku = [
    _Koumoku(
      nouryokuEikyodoNebariIndex,
      '長距離粘り',
      '15kmを超える区間で、距離が長いほど大きく効きます(15km以下の区間では効きません)。',
      Colors.redAccent,
    ),
    _Koumoku(
      nouryokuEikyodoSpurtIndex,
      'スパート力',
      'すべての区間で、距離に関係なく同じ大きさで効きます。',
      Colors.orange,
    ),
    _Koumoku(
      nouryokuEikyodoNoboriIndex,
      '登り適性',
      '上り坂のある区間で、坂が急で長いほど大きく効きます。',
      Colors.brown,
    ),
    _Koumoku(
      nouryokuEikyodoKudariIndex,
      '下り適性',
      '下り坂のある区間で、坂が急で長いほど大きく効きます。',
      Colors.cyan,
    ),
    _Koumoku(
      nouryokuEikyodoUpdownIndex,
      'アップダウン対応力',
      '登りと下りの切り替えが多い区間で効きます。',
      Colors.green,
    ),
    _Koumoku(
      nouryokuEikyodoRoadIndex,
      'ロード適性',
      '駅伝の2区以降で効きます(2区・3区と正月駅伝予選では半分)。1区と11月駅伝予選は集団で走るので効きません。',
      Colors.lightBlueAccent,
    ),
    _Koumoku(
      nouryokuEikyodoPaceIndex,
      'ペース変動対応力',
      '駅伝の1区と11月駅伝予選で効きます(2区・3区と正月駅伝予選では半分)。4区以降では効きません。',
      Colors.purpleAccent,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _kantokuBox = Hive.box<KantokuData>('kantokuBox');
  }

  // yobiint2を書き換えてHiveに保存する(変更をHiveに保存するために、List全体を更新)
  Future<void> _hozon(KantokuData kantoku, Map<int, int> atai) async {
    final List<int> updatedYobiint2 = List.from(kantoku.yobiint2);
    for (final MapEntry<int, int> e in atai.entries) {
      if (updatedYobiint2.length <= e.key) return;
      updatedYobiint2[e.key] = e.value;
    }
    setState(() {
      kantoku.yobiint2 = updatedYobiint2;
    });
    await kantoku.save();
  }

  // 7つとも初期値(100%)に戻す
  Future<void> _shokitiNiModosu(KantokuData kantoku) async {
    _ugokashiChuu.clear();
    await _hozon(kantoku, {for (final _Koumoku k in _koumoku) k.index: 0});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('能力のタイムへの影響度を初期値(100%)に戻しました'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<KantokuData>>(
      valueListenable: _kantokuBox.listenable(keys: ['KantokuData']),
      builder: (context, box, _) {
        if (!box.containsKey('KantokuData')) {
          return Scaffold(
            appBar: AppBar(title: const Text('能力のタイムへの影響度設定')),
            body: const Center(child: Text('設定データがありません')),
          );
        }
        final KantokuData kantoku = box.get('KantokuData')!;

        return Scaffold(
          backgroundColor: HENSUU.backgroundcolor,
          appBar: AppBar(
            title: const Text(
              '能力のタイムへの影響度設定',
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
                      "この画面では、選手の各能力の差が、駅伝と駅伝予選でのタイムにどのくらい効くかを設定します(全大学共通)。\n\n"
                      "能力50を基準に、能力の差によるタイムの差を広げたり縮めたりします。100%が初期値(今まで通り)です。0%にすると、その能力の差ではタイムに差がつかなくなり(全員が能力50と同じ扱い)、200%にすると差が2倍になります。基準が能力50なので、平均的なタイムの水準はほとんど変わりません。\n\n"
                      "記録会などのタイム(持ちタイム)には関係しません。試走タイムと、試走タイムを使うところ(コンピュータの大学の最適解区間配置や当日変更、「指示ごとの損得予測」など)には反映されます。スカウト方針が「自動」のコンピュータの大学は、新入生の能力を評価するときの重みにも、この影響度を掛けます。\n\n"
                      "大学の個性(実力発揮度)は、大学ごとに能力の値そのものを増減する設定で、この設定とは別に働きます(大学の個性で増減した能力の値に、この影響度がかかります)。",
                      style: TextStyle(
                        color: HENSUU.textcolor,
                        fontSize: HENSUU.fontsize_honbun,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  const SizedBox(height: 16),
                  for (final _Koumoku k in _koumoku)
                    _eikyodoSlider(kantoku: kantoku, koumoku: k),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _shokitiNiModosu(kantoku),
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
                      '初期値に戻す',
                      style: TextStyle(
                        fontSize: HENSUU.fontsize_honbun,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

  /// 能力1つ分のスライダー(0%〜300%、10%刻み)
  Widget _eikyodoSlider({
    required KantokuData kantoku,
    required _Koumoku koumoku,
  }) {
    final int index = koumoku.index;
    final double atai =
        _ugokashiChuu[index] ??
        nouryokuEikyodoPercent(kantoku, index).toDouble();
    final int percent = atai.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${koumoku.mei}の影響度',
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
            koumoku.setsumei,
            style: TextStyle(
              color: HENSUU.textcolor.withOpacity(0.8),
              fontSize: HENSUU.fontsize_honbun - 2,
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
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Slider(
                value: atai.clamp(0.0, nouryokuEikyodoSaidai.toDouble()),
                min: 0,
                max: nouryokuEikyodoSaidai.toDouble(),
                divisions: nouryokuEikyodoSaidai ~/ 10,
                label: '$percent%',
                onChanged: (v) {
                  setState(() => _ugokashiChuu[index] = v);
                },
                onChangeEnd: (v) async {
                  await _hozon(kantoku, {index: nouryokuEikyodoAtai(v.round())});
                  if (!mounted) return;
                  setState(() => _ugokashiChuu.remove(index));
                },
                activeColor: koumoku.iro,
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
                        '0% (差がつかない)',
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
                        '$nouryokuEikyodoSaidai% (差が3倍)',
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
}
